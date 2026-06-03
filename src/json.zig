const std = @import("std");

pub fn writeString(value: []const u8, writer: anytype) !void {
    try writer.writeByte('"');
    for (value) |byte| {
        switch (byte) {
            '"' => try writer.writeAll("\\\""),
            '\\' => try writer.writeAll("\\\\"),
            '\n' => try writer.writeAll("\\n"),
            '\r' => try writer.writeAll("\\r"),
            '\t' => try writer.writeAll("\\t"),
            0x08 => try writer.writeAll("\\b"),
            0x0c => try writer.writeAll("\\f"),
            0x00...0x07, 0x0b, 0x0e...0x1f => try writeControlEscape(byte, writer),
            else => try writer.writeByte(byte),
        }
    }
    try writer.writeByte('"');
}

/// Counts Unicode code points in `value`, matching how Discord measures the
/// length of user-facing strings against its documented character limits.
pub fn codepointLen(value: []const u8) error{InvalidUtf8}!usize {
    var count: usize = 0;
    var index: usize = 0;
    while (index < value.len) {
        const seq_len = std.unicode.utf8ByteSequenceLength(value[index]) catch return error.InvalidUtf8;
        if (index + seq_len > value.len) return error.InvalidUtf8;
        index += seq_len;
        count += 1;
    }
    return count;
}

fn writeControlEscape(byte: u8, writer: anytype) !void {
    const hex = "0123456789abcdef";
    try writer.writeAll("\\u00");
    try writer.writeByte(hex[byte >> 4]);
    try writer.writeByte(hex[byte & 0x0f]);
}

test "writeString escapes JSON control characters" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try writeString("a\"b\nc", &out.writer);
    try std.testing.expectEqualStrings("\"a\\\"b\\nc\"", out.written());
}
