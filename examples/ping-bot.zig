const std = @import("std");
const discord = @import("discord");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var memory = discord.Rest.MemoryTransport.init(allocator, .{
        .status = 200,
        .body = "{\"id\":\"1\",\"content\":\"pong\"}",
        .headers = &.{.{ .name = "X-RateLimit-Remaining", .value = "4" }},
    });
    defer memory.deinit();

    var client = discord.Client.init(allocator, .{
        .token = "Bot example-token",
        .intents = discord.Intents.defaultNonPrivileged(),
        .transport = memory.transport(),
    });
    defer client.deinit();

    const channel_id = discord.Snowflake.init(123456789012345678);
    const result = try client.sendMessage(channel_id, discord.Types.CreateMessage.init("pong"));

    std.debug.print("status={d} body={s}\n", .{ result.status, result.body });
}
