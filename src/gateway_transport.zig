const std = @import("std");
const GatewaySession = @import("gateway_session.zig");
const WebSocket = @import("websocket.zig");

pub const ConnectOptions = struct {
    url: []const u8 = "wss://gateway.discord.gg/?v=10&encoding=json",
    user_agent: []const u8 = "discord.zig",
};

pub const Transport = struct {
    allocator: std.mem.Allocator,
    http_client: std.http.Client,
    connection: ?*std.http.Client.Connection = null,
    host: []u8 = "",
    websocket_key: []u8 = "",
    closed: bool = true,

    pub fn init(allocator: std.mem.Allocator) Transport {
        return .{
            .allocator = allocator,
            .http_client = .{
                .allocator = allocator,
                .io = std.Io.Threaded.global_single_threaded.io(),
            },
        };
    }

    pub fn deinit(self: *Transport) void {
        self.close();
        self.http_client.deinit();
    }

    pub fn connect(self: *Transport, options: ConnectOptions) !void {
        self.close();

        const uri = try std.Uri.parse(options.url);
        if (!std.mem.eql(u8, uri.scheme, "wss")) return error.UnsupportedGatewayScheme;

        var host_name_buffer: [std.Io.net.HostName.max_len]u8 = .{0} ** std.Io.net.HostName.max_len;
        const host_name = try uri.getHost(&host_name_buffer);
        self.host = try self.allocator.dupe(u8, host_name.bytes);
        errdefer {
            self.allocator.free(self.host);
            self.host = "";
        }

        self.websocket_key = try makeWebSocketKey(self.allocator, self.http_client.io);
        errdefer {
            self.allocator.free(self.websocket_key);
            self.websocket_key = "";
        }

        const headers = [_]std.http.Header{
            .{ .name = "Upgrade", .value = "websocket" },
            .{ .name = "Sec-WebSocket-Key", .value = self.websocket_key },
            .{ .name = "Sec-WebSocket-Version", .value = "13" },
            .{ .name = "User-Agent", .value = options.user_agent },
        };

        var request = try self.http_client.request(.GET, uri, .{
            .redirect_behavior = .unhandled,
            .keep_alive = false,
            .headers = .{
                .connection = .{ .override = "Upgrade" },
                .accept_encoding = .omit,
                .user_agent = .omit,
            },
            .extra_headers = &headers,
        });
        defer request.deinit();

        try request.sendBodiless();
        const response = try request.receiveHead(&.{});
        if (response.head.status != .switching_protocols) return error.InvalidHandshakeStatus;
        try validateResponseHead(response.head, self.websocket_key);

        self.connection = request.connection.?;
        request.connection = null;
        self.closed = false;
    }

    pub fn close(self: *Transport) void {
        if (self.connection) |connection| {
            if (!self.closed) {
                var mask_key: [4]u8 = .{ 0, 0, 0, 0 };
                self.http_client.io.random(&mask_key);
                WebSocket.writeCloseFrame(.{ .code = 1000, .reason = "client close" }, mask_key, connection.writer()) catch {};
                connection.flush() catch {};
            }
            connection.closing = true;
            self.http_client.connection_pool.release(connection, self.http_client.io);
            self.connection = null;
        }
        if (self.host.len != 0) {
            self.allocator.free(self.host);
            self.host = "";
        }
        if (self.websocket_key.len != 0) {
            self.allocator.free(self.websocket_key);
            self.websocket_key = "";
        }
        self.closed = true;
    }

    pub fn sessionTransport(self: *Transport) GatewaySession.Transport {
        return .{ .ptr = self, .sendTextFn = sendText, .recvTextFn = recvText };
    }

    fn sendText(ptr: *anyopaque, payload: []const u8) !void {
        const self: *Transport = @ptrCast(@alignCast(ptr));
        const connection = self.connection orelse return error.NotConnected;
        var mask_key: [4]u8 = .{ 0, 0, 0, 0 };
        self.http_client.io.random(&mask_key);
        try WebSocket.writeTextFrame(payload, mask_key, connection.writer());
        try connection.flush();
    }

    fn recvText(ptr: *anyopaque, allocator: std.mem.Allocator) !?[]u8 {
        const self: *Transport = @ptrCast(@alignCast(ptr));
        const connection = self.connection orelse return error.NotConnected;

        while (true) {
            const frame = try readFrame(allocator, connection.reader());
            errdefer WebSocket.frameDeinit(allocator, frame);

            switch (frame.opcode) {
                .text => return @constCast(frame.payload),
                .ping => {
                    var mask_key: [4]u8 = .{ 0, 0, 0, 0 };
                    self.http_client.io.random(&mask_key);
                    try WebSocket.writePongFrame(frame.payload, mask_key, connection.writer());
                    try connection.flush();
                    WebSocket.frameDeinit(allocator, frame);
                },
                .pong => WebSocket.frameDeinit(allocator, frame),
                .close => {
                    var mask_key: [4]u8 = .{ 0, 0, 0, 0 };
                    self.http_client.io.random(&mask_key);
                    WebSocket.writeCloseFrame(.{}, mask_key, connection.writer()) catch {};
                    connection.flush() catch {};
                    WebSocket.frameDeinit(allocator, frame);
                    self.closed = true;
                    return null;
                },
                else => {
                    WebSocket.frameDeinit(allocator, frame);
                    return error.UnsupportedOpcode;
                },
            }
        }
    }
};

fn makeWebSocketKey(allocator: std.mem.Allocator, io: std.Io) ![]u8 {
    var nonce: [16]u8 = .{0} ** 16;
    io.random(&nonce);

    const encoded_len = std.base64.standard.Encoder.calcSize(nonce.len);
    const encoded = try allocator.alloc(u8, encoded_len);
    errdefer allocator.free(encoded);
    _ = std.base64.standard.Encoder.encode(encoded, &nonce);
    return encoded;
}

fn validateResponseHead(head: std.http.Client.Response.Head, key: []const u8) !void {
    var saw_upgrade = false;
    var saw_connection = false;
    var accept_value: ?[]const u8 = null;

    var iterator = head.iterateHeaders();
    while (iterator.next()) |header| {
        if (std.ascii.eqlIgnoreCase(header.name, "Upgrade") and std.ascii.eqlIgnoreCase(header.value, "websocket")) {
            saw_upgrade = true;
        } else if (std.ascii.eqlIgnoreCase(header.name, "Connection") and containsHeaderToken(header.value, "upgrade")) {
            saw_connection = true;
        } else if (std.ascii.eqlIgnoreCase(header.name, "Sec-WebSocket-Accept")) {
            accept_value = header.value;
        }
    }

    if (!saw_upgrade or !saw_connection) return error.InvalidHandshakeHeaders;
    var expected_buffer: [28]u8 = .{0} ** 28;
    const expected = try expectedAcceptInto(&expected_buffer, key);
    if (accept_value == null or !std.mem.eql(u8, accept_value.?, expected)) {
        return error.InvalidHandshakeAccept;
    }
}

fn expectedAcceptInto(buffer: []u8, key: []const u8) ![]const u8 {
    const magic = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
    var sha1 = std.crypto.hash.Sha1.init(.{});
    sha1.update(key);
    sha1.update(magic);
    var digest: [std.crypto.hash.Sha1.digest_length]u8 = .{0} ** std.crypto.hash.Sha1.digest_length;
    sha1.final(&digest);

    const encoded_len = std.base64.standard.Encoder.calcSize(digest.len);
    if (buffer.len < encoded_len) return error.NoSpaceLeft;
    return std.base64.standard.Encoder.encode(buffer[0..encoded_len], &digest);
}

fn containsHeaderToken(value: []const u8, token: []const u8) bool {
    var parts = std.mem.splitScalar(u8, value, ',');
    while (parts.next()) |part| {
        if (std.ascii.eqlIgnoreCase(std.mem.trim(u8, part, " \t"), token)) return true;
    }
    return false;
}

fn readFrame(allocator: std.mem.Allocator, reader: *std.Io.Reader) !WebSocket.Frame {
    var header: [2]u8 = .{ 0, 0 };
    try reader.readSliceAll(&header);

    const first = header[0];
    const second = header[1];
    const masked = (second & 0x80) != 0;
    var payload_len: u64 = second & 0x7f;

    if (payload_len == 126) {
        var extended: [2]u8 = .{ 0, 0 };
        try reader.readSliceAll(&extended);
        payload_len = (@as(u64, extended[0]) << 8) | extended[1];
    } else if (payload_len == 127) {
        var extended: [8]u8 = .{0} ** 8;
        try reader.readSliceAll(&extended);
        payload_len = 0;
        for (extended) |byte| payload_len = (payload_len << 8) | byte;
    }

    var mask_key: [4]u8 = .{ 0, 0, 0, 0 };
    if (masked) try reader.readSliceAll(&mask_key);
    if (payload_len > std.math.maxInt(usize)) return error.FrameTooLarge;

    const len: usize = @intCast(payload_len);
    const payload = try allocator.alloc(u8, len);
    errdefer allocator.free(payload);
    try reader.readSliceAll(payload);

    if (masked) {
        for (payload, 0..) |*byte, index| {
            byte.* ^= mask_key[index % 4];
        }
    }

    return .{
        .fin = (first & 0x80) != 0,
        .opcode = switch (first & 0x0f) {
            0x0 => .continuation,
            0x1 => .text,
            0x2 => .binary,
            0x8 => .close,
            0x9 => .ping,
            0xA => .pong,
            else => return error.UnsupportedOpcode,
        },
        .payload = payload,
    };
}

test "websocket key and accept validator agree with RFC sample" {
    var buffer: [28]u8 = .{0} ** 28;
    const accept = try expectedAcceptInto(&buffer, "dGhlIHNhbXBsZSBub25jZQ==");
    try std.testing.expectEqualStrings("s3pPLMBiTxaQ9kYGzzhZRbK+xOo=", accept);
}

test "transport exposes gateway session interface" {
    var gateway_transport = Transport.init(std.testing.allocator);
    defer gateway_transport.deinit();

    const session_transport = gateway_transport.sessionTransport();
    try std.testing.expect(session_transport.ptr == @as(*anyopaque, @ptrCast(&gateway_transport)));
}
