const std = @import("std");
const discord = @import("discord");

/// Minimal live bot: connects to the gateway and replies "pong" whenever it
/// sees the message "!ping".
///
/// Reading message text requires the privileged MESSAGE CONTENT intent, which
/// must also be enabled for the bot in the Discord Developer Portal.
///
/// Run with:
///   DISCORD_TOKEN=your-bot-token zig build
///   DISCORD_TOKEN=your-bot-token ./zig-out/bin/echo_bot
pub fn main(init: std.process.Init) !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    const allocator = gpa.allocator();

    const raw_token = std.process.Environ.getPosix(init.minimal.environ, "DISCORD_TOKEN") orelse {
        std.debug.print("set DISCORD_TOKEN to run the echo bot\n", .{});
        return error.MissingToken;
    };
    const token = try std.fmt.allocPrint(allocator, "Bot {s}", .{raw_token});

    var client = try discord.Client.initHttp(allocator, .{
        .token = token,
        .intents = discord.Intents.defaultNonPrivileged() | discord.Intents.message_content,
    });
    defer client.deinit();

    client.onMessageCreate(discord.Events.rawHandler(&client, onMessage));

    std.debug.print("connecting to the gateway...\n", .{});
    try discord.GatewayRuntime.login(allocator, &client, .{});
}

fn onMessage(client: *discord.Client, dispatch: discord.Gateway.ParsedDispatch) !void {
    const data = switch (dispatch.data) {
        .object => |object| object,
        else => return,
    };

    // Ignore messages from bots (including ourselves) so we never reply to a reply.
    if (data.get("author")) |author| {
        if (author == .object) {
            if (author.object.get("bot")) |bot| {
                if (bot == .bool and bot.bool) return;
            }
        }
    }

    const content = if (data.get("content")) |value|
        (if (value == .string) value.string else "")
    else
        "";
    if (!std.mem.eql(u8, content, "!ping")) return;

    const channel_id = try discord.Snowflake.parse(data.get("channel_id").?.string);
    const response = try client.sendMessage(channel_id, discord.Types.CreateMessage.init("pong"));
    defer discord.Http.responseDeinit(client.allocator, response);
    std.debug.print("replied to !ping in channel {d} (status {d})\n", .{ channel_id.value, response.status });
}
