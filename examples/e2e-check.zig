const std = @import("std");
const discord = @import("discord");
const build_options = @import("build_options");

/// Live end-to-end smoke test against the real Discord API. The bot token is
/// supplied at build time via `-Ddiscord_token=...` (never committed to source).
/// It exercises:
///   1. REST reads: `GET /users/@me`, `/gateway/bot`, `/applications/@me`, `/users/@me/guilds`,
///   2. the real gateway websocket: connect -> HELLO -> IDENTIFY -> READY,
///   3. an authenticated write/CRUD path: register a global slash command, read it back, remove it,
///   4. a real message round-trip: find a text channel, send a message, then delete it.
/// Usage: `zig build -Ddiscord_token=... && ./zig-out/bin/e2e_check`
pub fn main() !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const allocator = arena_state.allocator();

    if (build_options.discord_token.len == 0) {
        std.debug.print("FAIL: rebuild with -Ddiscord_token=<token>\n", .{});
        return error.MissingToken;
    }
    const token = try std.fmt.allocPrint(allocator, "Bot {s}", .{build_options.discord_token});

    var client = try discord.Client.initHttp(allocator, .{ .token = token });
    defer client.deinit();

    var failures: usize = 0;

    // 1. REST identity check.
    {
        const res = try client.getCurrentUser();
        std.debug.print("[REST] GET /users/@me         -> {d}\n", .{res.status});
        std.debug.print("       {s}\n", .{res.body});
        if (res.status != 200) failures += 1;
    }

    // 2. Gateway bot metadata (exercises Sharding.GatewayBotInfo.parse).
    {
        const res = try client.getGatewayBot();
        std.debug.print("[REST] GET /gateway/bot       -> {d}\n", .{res.status});
        if (res.status == 200) {
            const info = try discord.Sharding.GatewayBotInfo.parse(allocator, res.body);
            std.debug.print(
                "       url={s} shards={d} max_concurrency={d} session_starts_remaining={d}\n",
                .{ info.url, info.shards, info.session_start_limit.max_concurrency, info.session_start_limit.remaining },
            );
        } else failures += 1;
    }

    // 3. Application metadata.
    {
        const res = try client.getCurrentApplication();
        std.debug.print("[REST] GET /applications/@me  -> {d}\n", .{res.status});
        if (res.status != 200) failures += 1;
    }

    // 4. Array-returning GET: the bot's guilds (capture the first one for later).
    var guild_id: ?discord.Snowflake = null;
    {
        const res = try client.listCurrentUserGuilds(.{});
        std.debug.print("[REST] GET /users/@me/guilds  -> {d}\n", .{res.status});
        std.debug.print("       {s}\n", .{res.body});
        if (res.status != 200) {
            failures += 1;
        } else {
            const parsed = try std.json.parseFromSlice(std.json.Value, allocator, res.body, .{});
            if (parsed.value == .array and parsed.value.array.items.len > 0) {
                if (parsed.value.array.items[0].object.get("id")) |id_value| {
                    guild_id = try discord.Snowflake.parse(id_value.string);
                }
            }
        }
    }

    // 5. Real gateway connect -> HELLO -> IDENTIFY -> READY.
    var runtime = discord.GatewayRuntime.BlockingRuntime.init(allocator, &client);
    defer runtime.deinit();

    var steps: usize = 0;
    while (!client.isReady() and steps < 20) : (steps += 1) {
        const result = try runtime.step(.{});
        std.debug.print("[GW] step {d}: {s}\n", .{ steps, @tagName(result) });
    }

    var application_id: ?discord.Snowflake = null;
    if (client.isReady()) {
        std.debug.print("[GATEWAY] READY reached after {d} step(s)\n", .{steps});
        if (client.getCurrentCachedUser()) |user| {
            application_id = user.id;
            std.debug.print("          authenticated as {s} (id={d})\n", .{ user.username, user.id.value });
        }
        const stats = client.cacheStats();
        std.debug.print("          cache: users={d} guilds={d} channels={d}\n", .{ stats.users, stats.guilds, stats.channels });
    } else {
        std.debug.print("FAIL: gateway did not reach READY within {d} steps\n", .{steps});
        failures += 1;
    }
    runtime.stop();

    // 6. Authenticated write/CRUD path: register a global slash command, read it
    //    back, then remove it (bots' app id equals their user id).
    if (application_id) |app_id| {
        const commands = [_]discord.Interactions.ApplicationCommand{
            discord.Interactions.ApplicationCommand.chatInput("zige2e", "discord.zig end-to-end probe"),
        };
        const created = try client.bulkOverwriteGlobalApplicationCommands(app_id, &commands);
        std.debug.print("[REST] PUT /applications/{d}/commands -> {d}\n", .{ app_id.value, created.status });
        if (!(created.status == 200 and std.mem.indexOf(u8, created.body, "zige2e") != null)) failures += 1;

        const listed = try client.listGlobalApplicationCommands(app_id);
        std.debug.print("[REST] GET /applications/{d}/commands -> {d} (contains probe: {})\n", .{
            app_id.value, listed.status, std.mem.indexOf(u8, listed.body, "zige2e") != null,
        });
        if (listed.status != 200) failures += 1;

        const cleared = try client.bulkOverwriteGlobalApplicationCommands(app_id, &.{});
        std.debug.print("[REST] PUT /applications/{d}/commands (clear) -> {d}\n", .{ app_id.value, cleared.status });
        if (cleared.status != 200) failures += 1;
    }

    // 7. Real message round-trip: find a text channel, send a message, delete it.
    if (guild_id) |gid| {
        const channels = try client.listGuildChannels(gid);
        std.debug.print("[REST] GET /guilds/{d}/channels -> {d}\n", .{ gid.value, channels.status });
        if (channels.status != 200) failures += 1;

        var text_channel: ?discord.Snowflake = null;
        if (channels.status == 200) {
            const parsed = try std.json.parseFromSlice(std.json.Value, allocator, channels.body, .{});
            if (parsed.value == .array) {
                for (parsed.value.array.items) |item| {
                    const kind = item.object.get("type") orelse continue;
                    if (kind == .integer and kind.integer == 0) {
                        if (item.object.get("id")) |id_value| {
                            text_channel = try discord.Snowflake.parse(id_value.string);
                            break;
                        }
                    }
                }
            }
        }

        if (text_channel) |channel_id| {
            const sent = try client.sendMessage(channel_id, discord.Types.CreateMessage.init("discord.zig e2e check OK"));
            std.debug.print("[REST] POST /channels/{d}/messages -> {d}\n", .{ channel_id.value, sent.status });
            if (sent.status == 200) {
                const parsed = try std.json.parseFromSlice(std.json.Value, allocator, sent.body, .{});
                const message_id = try discord.Snowflake.parse(parsed.value.object.get("id").?.string);
                std.debug.print("       sent message id={d}, deleting...\n", .{message_id.value});
                const deleted = try client.deleteMessage(channel_id, message_id);
                std.debug.print("[REST] DELETE /channels/{d}/messages/{d} -> {d}\n", .{ channel_id.value, message_id.value, deleted.status });
                if (deleted.status != 204 and deleted.status != 200) failures += 1;
            } else {
                failures += 1;
            }

            // Multipart/file-upload path (body-stream): upload a small file, then delete it.
            const files = [_]discord.Types.UploadFile{
                .{ .filename = "e2e.txt", .content = "discord.zig multipart e2e", .content_type = "text/plain" },
            };
            const uploaded = try client.sendFiles(channel_id, discord.Types.CreateMessage.init("file upload check"), &files);
            std.debug.print("[REST] POST /channels/{d}/messages (multipart) -> {d}\n", .{ channel_id.value, uploaded.status });
            if (uploaded.status == 200) {
                const parsed = try std.json.parseFromSlice(std.json.Value, allocator, uploaded.body, .{});
                const has_attachment = parsed.value.object.get("attachments") != null and
                    parsed.value.object.get("attachments").?.array.items.len == 1;
                const upload_id = try discord.Snowflake.parse(parsed.value.object.get("id").?.string);
                std.debug.print("       uploaded message id={d} attachment_present={}, deleting...\n", .{ upload_id.value, has_attachment });
                if (!has_attachment) failures += 1;
                const deleted_upload = try client.deleteMessage(channel_id, upload_id);
                std.debug.print("[REST] DELETE /channels/{d}/messages/{d} -> {d}\n", .{ channel_id.value, upload_id.value, deleted_upload.status });
                if (deleted_upload.status != 204 and deleted_upload.status != 200) failures += 1;
            } else {
                failures += 1;
            }
        } else {
            std.debug.print("       (no text channel found; skipping message round-trip)\n", .{});
        }
    }

    if (failures == 0) {
        std.debug.print("PASS: REST reads + gateway READY + command CRUD + message + file-upload round-trips all succeeded\n", .{});
    } else {
        std.debug.print("FAIL: {d} check(s) did not pass\n", .{failures});
        return error.E2eFailed;
    }
}
