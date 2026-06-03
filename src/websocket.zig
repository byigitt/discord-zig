const std = @import("std");

pub const Opcode = enum(u4) {
    continuation = 0x0,
    text = 0x1,
    binary = 0x2,
    close = 0x8,
    ping = 0x9,
    pong = 0xA,
};

pub const Frame = struct {
    fin: bool,
    opcode: Opcode,
    payload: []const u8,
};

pub const CloseInfo = struct {
    code: ?u16 = null,
    reason: []const u8 = "",
};

pub fn writeClientHandshakeRequest(
    host: []const u8,
    path_and_query: []const u8,
    key: []const u8,
    writer: anytype,
) !void {
    try writer.print("GET {s} HTTP/1.1\r\n", .{path_and_query});
    try writer.print("Host: {s}\r\n", .{host});
    try writer.writeAll("Upgrade: websocket\r\n");
    try writer.writeAll("Connection: Upgrade\r\n");
    try writer.print("Sec-WebSocket-Key: {s}\r\n", .{key});
    try writer.writeAll("Sec-WebSocket-Version: 13\r\n");
    try writer.writeAll("\r\n");
}

pub fn expectedAccept(allocator: std.mem.Allocator, key: []const u8) ![]u8 {
    const magic = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
    var sha1 = std.crypto.hash.Sha1.init(.{});
    sha1.update(key);
    sha1.update(magic);
    var digest: [std.crypto.hash.Sha1.digest_length]u8 = .{0} ** std.crypto.hash.Sha1.digest_length;
    sha1.final(&digest);

    const encoded_len = std.base64.standard.Encoder.calcSize(digest.len);
    const encoded = try allocator.alloc(u8, encoded_len);
    errdefer allocator.free(encoded);
    _ = std.base64.standard.Encoder.encode(encoded, &digest);
    return encoded;
}

pub fn validateHandshakeResponse(allocator: std.mem.Allocator, response: []const u8, key: []const u8) !void {
    var lines = std.mem.splitSequence(u8, response, "\r\n");
    const status = lines.next() orelse return error.InvalidHandshake;
    if (!std.mem.startsWith(u8, status, "HTTP/1.1 101") and !std.mem.startsWith(u8, status, "HTTP/1.0 101")) {
        return error.InvalidHandshakeStatus;
    }

    var saw_upgrade = false;
    var saw_connection = false;
    var accept_value: ?[]const u8 = null;
    while (lines.next()) |line| {
        if (line.len == 0) break;
        const colon = std.mem.indexOfScalar(u8, line, ':') orelse continue;
        const name = std.mem.trim(u8, line[0..colon], " \t");
        const value = std.mem.trim(u8, line[colon + 1 ..], " \t");

        if (std.ascii.eqlIgnoreCase(name, "Upgrade") and std.ascii.eqlIgnoreCase(value, "websocket")) {
            saw_upgrade = true;
        } else if (std.ascii.eqlIgnoreCase(name, "Connection") and containsHeaderToken(value, "upgrade")) {
            saw_connection = true;
        } else if (std.ascii.eqlIgnoreCase(name, "Sec-WebSocket-Accept")) {
            accept_value = value;
        }
    }

    if (!saw_upgrade or !saw_connection) return error.InvalidHandshakeHeaders;
    const expected = try expectedAccept(allocator, key);
    defer allocator.free(expected);
    if (accept_value == null or !std.mem.eql(u8, accept_value.?, expected)) {
        return error.InvalidHandshakeAccept;
    }
}

pub fn writeTextFrame(payload: []const u8, mask_key: [4]u8, writer: anytype) !void {
    try writeClientFrame(.text, payload, mask_key, writer);
}

pub fn writePingFrame(payload: []const u8, mask_key: [4]u8, writer: anytype) !void {
    if (payload.len > 125) return error.ControlFrameTooLarge;
    try writeClientFrame(.ping, payload, mask_key, writer);
}

pub fn writePongFrame(payload: []const u8, mask_key: [4]u8, writer: anytype) !void {
    if (payload.len > 125) return error.ControlFrameTooLarge;
    try writeClientFrame(.pong, payload, mask_key, writer);
}

pub fn writeCloseFrame(info: CloseInfo, mask_key: [4]u8, writer: anytype) !void {
    var payload: [125]u8 = .{0} ** 125;
    var len: usize = 0;
    if (info.code) |code| {
        payload[0] = @intCast((code >> 8) & 0xff);
        payload[1] = @intCast(code & 0xff);
        len = 2;
        if (info.reason.len > payload.len - len) return error.ControlFrameTooLarge;
        @memcpy(payload[len .. len + info.reason.len], info.reason);
        len += info.reason.len;
    }
    try writeClientFrame(.close, payload[0..len], mask_key, writer);
}

pub fn writeClientFrame(opcode: Opcode, payload: []const u8, mask_key: [4]u8, writer: anytype) !void {
    try writer.writeByte(0x80 | @as(u8, @intFromEnum(opcode)));
    try writeLength(payload.len, true, writer);
    try writer.writeAll(&mask_key);
    for (payload, 0..) |byte, index| {
        try writer.writeByte(byte ^ mask_key[index % 4]);
    }
}

pub fn decodeCloseInfo(frame: Frame) !CloseInfo {
    if (frame.opcode != .close) return error.NotCloseFrame;
    if (frame.payload.len == 0) return .{};
    if (frame.payload.len == 1) return error.InvalidCloseFrame;

    const code = (@as(u16, frame.payload[0]) << 8) | frame.payload[1];
    return .{ .code = code, .reason = frame.payload[2..] };
}

pub fn decodeFrame(allocator: std.mem.Allocator, bytes: []const u8) !Frame {
    if (bytes.len < 2) return error.IncompleteFrame;

    const first = bytes[0];
    const second = bytes[1];
    const fin = (first & 0x80) != 0;
    const opcode = opcodeFromInt(first & 0x0f) orelse return error.UnsupportedOpcode;
    const masked = (second & 0x80) != 0;

    var index: usize = 2;
    var length: u64 = second & 0x7f;
    if (length == 126) {
        if (bytes.len < index + 2) return error.IncompleteFrame;
        length = (@as(u64, bytes[index]) << 8) | bytes[index + 1];
        index += 2;
    } else if (length == 127) {
        if (bytes.len < index + 8) return error.IncompleteFrame;
        length = 0;
        for (bytes[index .. index + 8]) |byte| {
            length = (length << 8) | byte;
        }
        index += 8;
    }

    var mask_key: [4]u8 = .{ 0, 0, 0, 0 };
    if (masked) {
        if (bytes.len < index + 4) return error.IncompleteFrame;
        @memcpy(&mask_key, bytes[index .. index + 4]);
        index += 4;
    }

    if (length > std.math.maxInt(usize)) return error.FrameTooLarge;
    const payload_len: usize = @intCast(length);
    if (bytes.len < index + payload_len) return error.IncompleteFrame;

    const payload = try allocator.alloc(u8, payload_len);
    errdefer allocator.free(payload);
    for (bytes[index .. index + payload_len], 0..) |byte, payload_index| {
        payload[payload_index] = if (masked) byte ^ mask_key[payload_index % 4] else byte;
    }

    return .{ .fin = fin, .opcode = opcode, .payload = payload };
}

pub fn decodeFramePrefix(allocator: std.mem.Allocator, bytes: []const u8) !struct { frame: Frame, consumed: usize } {
    if (bytes.len < 2) return error.IncompleteFrame;

    const second = bytes[1];
    const masked = (second & 0x80) != 0;
    var index: usize = 2;
    var length: u64 = second & 0x7f;
    if (length == 126) {
        if (bytes.len < index + 2) return error.IncompleteFrame;
        length = (@as(u64, bytes[index]) << 8) | bytes[index + 1];
        index += 2;
    } else if (length == 127) {
        if (bytes.len < index + 8) return error.IncompleteFrame;
        length = 0;
        for (bytes[index .. index + 8]) |byte| length = (length << 8) | byte;
        index += 8;
    }

    if (masked) index += 4;
    if (length > std.math.maxInt(usize)) return error.FrameTooLarge;
    const payload_len: usize = @intCast(length);
    const consumed = index + payload_len;
    if (bytes.len < consumed) return error.IncompleteFrame;

    return .{ .frame = try decodeFrame(allocator, bytes[0..consumed]), .consumed = consumed };
}

pub fn frameDeinit(allocator: std.mem.Allocator, frame: Frame) void {
    allocator.free(frame.payload);
}

fn containsHeaderToken(value: []const u8, token: []const u8) bool {
    var parts = std.mem.splitScalar(u8, value, ',');
    while (parts.next()) |part| {
        if (std.ascii.eqlIgnoreCase(std.mem.trim(u8, part, " \t"), token)) return true;
    }
    return false;
}

fn writeLength(length: usize, masked: bool, writer: anytype) !void {
    const mask_bit: u8 = if (masked) 0x80 else 0x00;
    if (length <= 125) {
        try writer.writeByte(mask_bit | @as(u8, @intCast(length)));
    } else if (length <= std.math.maxInt(u16)) {
        try writer.writeByte(mask_bit | 126);
        try writer.writeByte(@intCast((length >> 8) & 0xff));
        try writer.writeByte(@intCast(length & 0xff));
    } else {
        try writer.writeByte(mask_bit | 127);
        var shift: i32 = 56;
        while (shift >= 0) : (shift -= 8) {
            try writer.writeByte(@intCast((length >> @intCast(shift)) & 0xff));
        }
    }
}

fn opcodeFromInt(value: u8) ?Opcode {
    return switch (value) {
        0x0 => .continuation,
        0x1 => .text,
        0x2 => .binary,
        0x8 => .close,
        0x9 => .ping,
        0xA => .pong,
        else => null,
    };
}

test "handshake request and accept value" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try writeClientHandshakeRequest(
        "gateway.discord.gg",
        "/?v=10&encoding=json",
        "dGhlIHNhbXBsZSBub25jZQ==",
        &out.writer,
    );
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "Upgrade: websocket\r\n") != null);

    const accept = try expectedAccept(std.testing.allocator, "dGhlIHNhbXBsZSBub25jZQ==");
    defer std.testing.allocator.free(accept);
    try std.testing.expectEqualStrings("s3pPLMBiTxaQ9kYGzzhZRbK+xOo=", accept);
}

test "validate handshake response" {
    try validateHandshakeResponse(
        std.testing.allocator,
        "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: keep-alive, Upgrade\r\nSec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=\r\n\r\n",
        "dGhlIHNhbXBsZSBub25jZQ==",
    );
}

test "client text frame masks payload" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try writeTextFrame("hello", .{ 1, 2, 3, 4 }, &out.writer);

    try std.testing.expectEqual(@as(u8, 0x81), out.written()[0]);
    try std.testing.expectEqual(@as(u8, 0x85), out.written()[1]);
    try std.testing.expectEqualSlices(u8, &.{ 1, 2, 3, 4 }, out.written()[2..6]);
    try std.testing.expectEqual(@as(u8, 'h' ^ 1), out.written()[6]);
}

test "decode unmasked text frame" {
    const bytes = [_]u8{ 0x81, 0x05, 'h', 'e', 'l', 'l', 'o' };
    const frame = try decodeFrame(std.testing.allocator, &bytes);
    defer frameDeinit(std.testing.allocator, frame);

    try std.testing.expect(frame.fin);
    try std.testing.expectEqual(Opcode.text, frame.opcode);
    try std.testing.expectEqualStrings("hello", frame.payload);
}

test "control frames and close info" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try writePingFrame("?", .{ 1, 2, 3, 4 }, &out.writer);
    try std.testing.expectEqual(@as(u8, 0x89), out.written()[0]);

    out.writer.end = 0;
    try writeCloseFrame(.{ .code = 1000, .reason = "bye" }, .{ 0, 0, 0, 0 }, &out.writer);
    try std.testing.expectEqual(@as(u8, 0x88), out.written()[0]);

    const server_close = [_]u8{ 0x88, 0x05, 0x03, 0xe8, 'b', 'y', 'e' };
    const frame = try decodeFrame(std.testing.allocator, &server_close);
    defer frameDeinit(std.testing.allocator, frame);
    const info = try decodeCloseInfo(frame);
    try std.testing.expectEqual(@as(?u16, 1000), info.code);
    try std.testing.expectEqualStrings("bye", info.reason);
}

test "decode frame prefix reports consumed bytes" {
    const bytes = [_]u8{ 0x81, 0x02, 'o', 'k', 0x81, 0x02, 'n', 'o' };
    const decoded = try decodeFramePrefix(std.testing.allocator, &bytes);
    defer frameDeinit(std.testing.allocator, decoded.frame);

    try std.testing.expectEqual(@as(usize, 4), decoded.consumed);
    try std.testing.expectEqualStrings("ok", decoded.frame.payload);
}
