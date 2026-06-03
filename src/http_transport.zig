const std = @import("std");
const Rest = @import("rest.zig");
const Routes = @import("routes.zig");

pub const HttpTransport = struct {
    allocator: std.mem.Allocator,
    client: std.http.Client,
    max_body_size: usize = 16 * 1024 * 1024,

    pub fn init(allocator: std.mem.Allocator) HttpTransport {
        return .{
            .allocator = allocator,
            .client = .{
                .allocator = allocator,
                .io = std.Io.Threaded.global_single_threaded.io(),
            },
        };
    }

    pub fn deinit(self: *HttpTransport) void {
        self.client.deinit();
    }

    pub fn transport(self: *HttpTransport) Rest.Transport {
        return .{ .ptr = self, .sendFn = send };
    }

    fn send(ptr: *anyopaque, allocator: std.mem.Allocator, request: Rest.Request) !Rest.Response {
        _ = allocator;
        const self: *HttpTransport = @ptrCast(@alignCast(ptr));

        const uri = try std.Uri.parse(request.url);
        const content_type_header: std.http.Client.Request.Headers.Value = if (request.content_type) |content_type|
            .{ .override = content_type }
        else
            .omit;
        // NOTE: std.http.Client only emits `extra_headers` on the request line;
        // `privileged_headers` are never written (they only control redirect
        // stripping). The Authorization header therefore MUST live in
        // `extra_headers`, or Discord rejects every request with 401.
        const user_agent = "discord.zig (https://github.com/baris/discord-zig, 0.1)";
        const authorized_headers = [_]std.http.Header{
            .{ .name = "Authorization", .value = request.token },
            .{ .name = "User-Agent", .value = user_agent },
        };
        const anonymous_headers = [_]std.http.Header{
            .{ .name = "User-Agent", .value = user_agent },
        };
        const extra_headers: []const std.http.Header = if (request.token.len == 0)
            &anonymous_headers
        else
            &authorized_headers;

        var http_request = try self.client.request(toHttpMethod(request.method), uri, .{
            .redirect_behavior = .unhandled,
            // Use a fresh connection per request: a pooled keep-alive connection
            // can go stale across long gaps (e.g. while the gateway is active),
            // and reusing a half-closed socket blocks indefinitely on read.
            .keep_alive = false,
            .headers = .{
                .authorization = .omit,
                .user_agent = .omit,
                .content_type = content_type_header,
                // std.http.Client does not decompress responses, so request
                // identity encoding instead of the default gzip/deflate/zstd.
                .accept_encoding = .omit,
            },
            .extra_headers = extra_headers,
        });
        defer http_request.deinit();

        if (request.body_stream) |stream| {
            http_request.transfer_encoding = .{ .content_length = stream.content_length };
            var body_buffer: [8192]u8 = .{0} ** 8192;
            var body_writer = try http_request.sendBodyUnflushed(&body_buffer);
            try stream.writeTo(&body_writer.writer);
            try body_writer.end();
            // The body writer flushes its own buffer, but the connection-level
            // (TLS) buffer must also be flushed or the request never lands.
            try http_request.connection.?.flush();
        } else if (request.body) |body| {
            http_request.transfer_encoding = .{ .content_length = body.len };
            var body_buffer: [8192]u8 = .{0} ** 8192;
            var body_writer = try http_request.sendBodyUnflushed(&body_buffer);
            try body_writer.writer.writeAll(body);
            try body_writer.end();
            try http_request.connection.?.flush();
        } else {
            try http_request.sendBodiless();
        }

        var response = try http_request.receiveHead(&.{});
        const status = response.head.status;
        const response_headers = try copyHeaders(self.allocator, response.head);
        errdefer freeHeaders(self.allocator, response_headers);

        var transfer_buffer: [8192]u8 = .{0} ** 8192;
        const body_reader = response.reader(&transfer_buffer);
        const body = try body_reader.allocRemaining(self.allocator, .limited(self.max_body_size));
        errdefer self.allocator.free(body);

        return .{
            .status = @intFromEnum(status),
            .body = body,
            .headers = response_headers,
        };
    }
};

pub fn responseDeinit(allocator: std.mem.Allocator, response: Rest.Response) void {
    allocator.free(response.body);
    freeHeaders(allocator, response.headers);
}

fn toHttpMethod(method: Routes.Method) std.http.Method {
    return switch (method) {
        .GET => .GET,
        .POST => .POST,
        .PUT => .PUT,
        .PATCH => .PATCH,
        .DELETE => .DELETE,
    };
}

fn copyHeaders(allocator: std.mem.Allocator, head: std.http.Client.Response.Head) ![]Rest.Header {
    var copied = std.array_list.Managed(Rest.Header).init(allocator);
    errdefer {
        for (copied.items) |header| {
            allocator.free(header.name);
            allocator.free(header.value);
        }
        copied.deinit();
    }

    var it = head.iterateHeaders();
    while (it.next()) |entry| {
        const name = try allocator.dupe(u8, entry.name);
        errdefer allocator.free(name);
        const value = try allocator.dupe(u8, entry.value);
        errdefer allocator.free(value);
        try copied.append(.{ .name = name, .value = value });
    }

    return copied.toOwnedSlice();
}

fn freeHeaders(allocator: std.mem.Allocator, headers: []const Rest.Header) void {
    for (headers) |header| {
        allocator.free(header.name);
        allocator.free(header.value);
    }
    allocator.free(headers);
}

test "method mapping" {
    try std.testing.expectEqual(std.http.Method.POST, toHttpMethod(.POST));
}
