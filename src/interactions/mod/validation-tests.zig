const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Json = @import("../../core/json.zig");

const Root = @import("../mod.zig");
const Locale = Root.Locale;
const Localization = Root.Localization;
const ParsedInteraction = Root.ParsedInteraction;
const CommandRoute = Root.CommandRoute;
const InteractionRouter = Root.InteractionRouter;
const parsedHandler = Root.parsedHandler;
const middlewareHandler = Root.middlewareHandler;
const parseInteraction = Root.parseInteraction;
const ApplicationCommand = Root.ApplicationCommand;

test "resolved typed channel and member views" {
    var context = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"Move\",\"type\":1,\"resolved\":{\"channels\":{\"20\":{\"id\":\"20\",\"name\":\"general\",\"type\":0,\"permissions\":\"1024\",\"parent_id\":\"19\"}},\"members\":{\"42\":{\"nick\":\"Adabot\",\"joined_at\":\"2024-01-01T00:00:00.000Z\",\"pending\":false,\"permissions\":\"2048\",\"roles\":[\"7\",\"8\"]}}}}}",
    );
    defer context.deinit();
    const resolved = context.data.?.resolved;

    const channel = (try resolved.resolvedChannel(Snowflake.init(20))).?;
    try std.testing.expectEqualStrings("general", channel.name.?);
    try std.testing.expectEqual(@as(u8, 0), channel.type);
    try std.testing.expectEqual(@as(?u64, 1024), channel.permissions);
    try std.testing.expectEqual(@as(u64, 19), channel.parent_id.?.value);
    try std.testing.expect((try resolved.resolvedChannel(Snowflake.init(99))) == null);

    const member = (try resolved.resolvedMember(Snowflake.init(42))).?;
    try std.testing.expectEqualStrings("Adabot", member.nick.?);
    try std.testing.expectEqualStrings("2024-01-01T00:00:00.000Z", member.joined_at.?);
    try std.testing.expectEqual(@as(?u64, 2048), member.permissions);
    try std.testing.expectEqual(@as(usize, 2), member.roleCount());
    try std.testing.expectEqual(@as(u64, 7), (try member.roleAt(0)).?.value);
    try std.testing.expectEqual(@as(u64, 8), (try member.roleAt(1)).?.value);
    try std.testing.expect((try member.roleAt(2)) == null);
}

test "resolved typed attachment and message views" {
    var context = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"Inspect\",\"type\":3,\"target_id\":\"88\",\"resolved\":{\"messages\":{\"88\":{\"id\":\"88\",\"channel_id\":\"20\",\"author\":{\"id\":\"40\",\"username\":\"poster\"},\"content\":\"hello\",\"timestamp\":\"2026-01-01T00:00:00.000Z\",\"pinned\":true,\"type\":0,\"attachments\":[{\"id\":\"77\",\"filename\":\"a.png\",\"size\":2048,\"url\":\"https://cdn/a.png\",\"width\":100,\"height\":50}],\"embeds\":[{\"title\":\"x\"}]}},\"attachments\":{\"77\":{\"id\":\"77\",\"filename\":\"a.png\",\"size\":2048,\"url\":\"https://cdn/a.png\",\"content_type\":\"image/png\",\"width\":100,\"height\":50}}}}}",
    );
    defer context.deinit();
    const data = context.data.?;
    const resolved = data.resolved;

    const message = (try resolved.resolvedMessage(Snowflake.init(88))).?;
    try std.testing.expectEqual(@as(u64, 20), message.channel_id.?.value);
    try std.testing.expectEqual(@as(u64, 40), message.author_id.?.value);
    try std.testing.expectEqualStrings("hello", message.content.?);
    try std.testing.expect(message.pinned);
    try std.testing.expectEqual(@as(usize, 1), message.attachment_count);
    try std.testing.expectEqual(@as(usize, 1), message.embed_count);

    const attachment = (try resolved.resolvedAttachment(Snowflake.init(77))).?;
    try std.testing.expectEqualStrings("a.png", attachment.filename);
    try std.testing.expectEqual(@as(u64, 2048), attachment.size);
    try std.testing.expectEqualStrings("image/png", attachment.content_type.?);
    try std.testing.expectEqual(@as(?u32, 100), attachment.width);
    try std.testing.expectEqual(@as(?u32, 50), attachment.height);

    try std.testing.expect(data.targetMessage() != null);
    try std.testing.expect((try resolved.resolvedAttachment(Snowflake.init(99))) == null);
}

test "interaction router per-route guard gates the handler" {
    const State = struct {
        handled: usize = 0,
        guard_calls: usize = 0,
        allow: bool = true,

        pub fn guard(self: *@This(), interaction: *const ParsedInteraction) !bool {
            _ = interaction;
            self.guard_calls += 1;
            return self.allow;
        }

        pub fn onPing(self: *@This(), interaction: *const ParsedInteraction) !void {
            _ = interaction;
            self.handled += 1;
        }
    };

    var state = State{};
    const commands = [_]CommandRoute{
        .{ .name = "ping", .handler = parsedHandler(&state, State.onPing), .guard = middlewareHandler(&state, State.guard) },
    };
    const router = InteractionRouter{ .commands = &commands };
    const payload = "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"ping\",\"type\":1}}";

    // Guard allows -> handler runs.
    var allowed = try parseInteraction(std.testing.allocator, payload);
    defer allowed.deinit();
    try std.testing.expect(try router.dispatch(&allowed));
    try std.testing.expectEqual(@as(usize, 1), state.handled);
    try std.testing.expectEqual(@as(usize, 1), state.guard_calls);

    // Guard rejects -> handler skipped, dispatch still reports handled.
    state.allow = false;
    var blocked = try parseInteraction(std.testing.allocator, payload);
    defer blocked.deinit();
    try std.testing.expect(try router.dispatch(&blocked));
    try std.testing.expectEqual(@as(usize, 1), state.handled);
    try std.testing.expectEqual(@as(usize, 2), state.guard_calls);
}

test "typed locale codes build localization entries" {
    try std.testing.expectEqualStrings("en-US", Locale.english_us.code());
    try std.testing.expectEqualStrings("pt-BR", Locale.portuguese_brazil.code());
    try std.testing.expectEqualStrings("es-419", Locale.spanish_latam.code());

    const entry = Localization.of(.turkish, "yay");
    try std.testing.expectEqualStrings("tr", entry.locale);
    try std.testing.expectEqualStrings("yay", entry.value);

    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();
    const locales = [_]Localization{
        Localization.of(.english_us, "publish"),
        Localization.of(.turkish, "yayinla"),
    };
    try ApplicationCommand.chatInput("publish", "Publish").withNameLocalizations(&locales).writeJson(&out.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"publish\",\"description\":\"Publish\",\"type\":1,\"name_localizations\":{\"en-US\":\"publish\",\"tr\":\"yayinla\"}}",
        out.written(),
    );
}
