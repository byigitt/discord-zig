const std = @import("std");
const Intents = @import("../../core/intents.zig");
const Rest = @import("../../rest/client.zig");
const HttpTransport = @import("../../rest/http-transport.zig").HttpTransport;
const Events = @import("../../gateway/events.zig");
const Gateway = @import("../../gateway/protocol.zig");
const GatewaySession = @import("../../gateway/session.zig");
const CacheModule = @import("../cache.zig");
const Interactions = @import("../../interactions/mod.zig");
const Types = @import("../../models/types.zig");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Root = @import("../client.zig");
const Client = Root.Client;

test "client file send aliases delegate to multipart REST" {
    var memory = Rest.MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
        .transport = memory.transport(),
    });
    defer client.deinit();

    const memory_files = [_]Types.UploadFile{
        Types.UploadFile.init("hello.txt", "hello").withContentType("text/plain"),
    };

    _ = try client.sendMessageWithFiles(Snowflake.init(10), Types.CreateMessage.init("with file"), &memory_files);
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages", memory.last_request.?.url);
    try std.testing.expectEqualStrings("multipart/form-data; boundary=discord-zig-boundary", memory.last_request.?.content_type.?);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "name=\"files[0]\"; filename=\"hello.txt\"") != null);

    _ = try client.sendWithFiles(Snowflake.init(10), Types.CreateMessage.init("with file alias"), &memory_files);
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/messages", memory.last_request.?.url);
    try std.testing.expectEqualStrings("multipart/form-data; boundary=discord-zig-boundary", memory.last_request.?.content_type.?);

    const io = std.Io.Threaded.global_single_threaded.io();
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(io, .{ .sub_path = "stream.txt", .data = "hello from disk" });

    var path_buffer: [128]u8 = .{0} ** 128;
    const path = try std.fmt.bufPrint(&path_buffer, ".zig-cache/tmp/{s}/stream.txt", .{tmp.sub_path});
    const path_files = [_]Types.UploadFilePath{
        Types.UploadFilePath.init("stream.txt", path).withContentType("text/plain"),
    };

    _ = try client.sendMessageWithFilePaths(Snowflake.init(10), Types.CreateMessage.init("streamed file"), &path_files);
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("multipart/form-data; boundary=discord-zig-boundary", memory.last_request.?.content_type.?);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "hello from disk\r\n") != null);

    _ = try client.sendWithFilePaths(Snowflake.init(10), Types.CreateMessage.init("streamed file alias"), &path_files);
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("multipart/form-data; boundary=discord-zig-boundary", memory.last_request.?.content_type.?);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "\"attachments\":[{\"id\":\"0\",\"filename\":\"stream.txt\"}]") != null);
}
