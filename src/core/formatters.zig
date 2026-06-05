const std = @import("std");
const Snowflake = @import("snowflake.zig").Snowflake;

/// Markdown text-styling and channel-navigation helpers modeled on
/// discord.js `@discordjs/formatters`. Every builder follows the project
/// convention `pub fn name(allocator, ...) ![]u8` and returns a freshly
/// allocated, caller-owned string built with `std.fmt.allocPrint`.
///
/// Mention/timestamp builders that already live in `mentions.zig` are NOT
/// duplicated here; this module only covers markdown TEXT STYLING plus the
/// extended slash-command navigation forms that `mentions.zig` lacks.
/// Heading level for the typed `headingLevel` convenience builder. The numeric
/// tag mirrors the Markdown heading depth so it cannot represent an invalid
/// level.
pub const HeadingLevel = enum(u8) {
    h1 = 1,
    h2 = 2,
    h3 = 3,
};
pub const TimestampStyle = enum(u8) {
    short_time = 't',
    long_time = 'T',
    short_date = 'd',
    long_date = 'D',
    short_datetime = 'f',
    long_datetime = 'F',
    relative = 'R',
};

pub fn bold(allocator: std.mem.Allocator, content: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "**{s}**", .{content});
}

pub fn italic(allocator: std.mem.Allocator, content: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "_{s}_", .{content});
}

pub fn underline(allocator: std.mem.Allocator, content: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "__{s}__", .{content});
}

pub fn strikethrough(allocator: std.mem.Allocator, content: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "~~{s}~~", .{content});
}

pub fn spoiler(allocator: std.mem.Allocator, content: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "||{s}||", .{content});
}

pub fn inlineCode(allocator: std.mem.Allocator, content: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "`{s}`", .{content});
}

/// Fenced code block with no language tag. The leading/trailing newlines match
/// the `@discordjs/formatters` `codeBlock` output.
pub fn codeBlock(allocator: std.mem.Allocator, content: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "```\n{s}\n```", .{content});
}

/// Fenced code block tagged with a syntax-highlighting language.
pub fn codeBlockLang(allocator: std.mem.Allocator, language: []const u8, content: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "```{s}\n{s}\n```", .{ language, content });
}

pub fn quote(allocator: std.mem.Allocator, content: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "> {s}", .{content});
}

pub fn blockQuote(allocator: std.mem.Allocator, content: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, ">>> {s}", .{content});
}

pub fn subtext(allocator: std.mem.Allocator, content: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "-# {s}", .{content});
}

pub fn hyperlink(allocator: std.mem.Allocator, label: []const u8, url: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "[{s}]({s})", .{ label, url });
}

pub fn hyperlinkTitled(allocator: std.mem.Allocator, label: []const u8, url: []const u8, title: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "[{s}]({s} \"{s}\")", .{ label, url, title });
}
/// Wraps a URL in angle brackets so Discord does not render an embed preview.
pub fn hideLinkEmbed(allocator: std.mem.Allocator, url: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "<{s}>", .{url});
}

/// Markdown heading with a `level` of 1, 2, or 3. Returns
/// `error.InvalidHeadingLevel` for any other value.
pub fn heading(allocator: std.mem.Allocator, level: u8, content: []const u8) ![]u8 {
    const prefix = switch (level) {
        1 => "# ",
        2 => "## ",
        3 => "### ",
        else => return error.InvalidHeadingLevel,
    };
    return std.fmt.allocPrint(allocator, "{s}{s}", .{ prefix, content });
}

/// Typed heading builder that cannot fail on level selection because
/// `HeadingLevel` only encodes valid depths.
pub fn headingLevel(allocator: std.mem.Allocator, level: HeadingLevel, content: []const u8) ![]u8 {
    return heading(allocator, @intFromEnum(level), content);
}

pub fn bulletPoint(allocator: std.mem.Allocator, content: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "- {s}", .{content});
}

pub fn numberedPoint(allocator: std.mem.Allocator, number: u32, content: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "{d}. {s}", .{ number, content });
}

/// Clickable slash-command mention: `</name:id>`. Discord renders this as a
/// link that, when clicked, pre-fills the command.
pub fn slashCommandMention(allocator: std.mem.Allocator, name: []const u8, command_id: Snowflake) ![]u8 {
    if (name.len == 0) return error.InvalidCommandName;
    return std.fmt.allocPrint(allocator, "</{s}:{d}>", .{ name, command_id.value });
}

/// Clickable subcommand (or subcommand-group) slash-command mention:
/// `</name sub:id>`.
pub fn slashCommandMentionSub(allocator: std.mem.Allocator, name: []const u8, sub: []const u8, command_id: Snowflake) ![]u8 {
    if (name.len == 0) return error.InvalidCommandName;
    if (sub.len == 0) return error.InvalidCommandName;
    return std.fmt.allocPrint(allocator, "</{s} {s}:{d}>", .{ name, sub, command_id.value });
}

/// Clickable slash-command mention with explicit subcommand group and subcommand:
/// `</name group sub:id>`.
pub fn chatInputApplicationCommandMention(
    allocator: std.mem.Allocator,
    name: []const u8,
    group: []const u8,
    subcommand: []const u8,
    command_id: Snowflake,
) ![]u8 {
    if (name.len == 0 or group.len == 0 or subcommand.len == 0) return error.InvalidCommandName;
    return std.fmt.allocPrint(allocator, "</{s} {s} {s}:{d}>", .{ name, group, subcommand, command_id.value });
}

pub fn time(allocator: std.mem.Allocator, unix_seconds: u64, style: ?TimestampStyle) ![]u8 {
    if (style) |timestamp_style| {
        return std.fmt.allocPrint(allocator, "<t:{d}:{c}>", .{ unix_seconds, @intFromEnum(timestamp_style) });
    }
    return std.fmt.allocPrint(allocator, "<t:{d}>", .{unix_seconds});
}

pub fn timestamp(allocator: std.mem.Allocator, unix_seconds: u64, style: ?TimestampStyle) ![]u8 {
    return time(allocator, unix_seconds, style);
}

/// Multi-item unordered list: each item on its own `- ` line.
pub fn unorderedList(allocator: std.mem.Allocator, items: []const []const u8) ![]u8 {
    var out = std.array_list.Managed(u8).init(allocator);
    errdefer out.deinit();
    for (items, 0..) |item, index| {
        if (index != 0) try out.append('\n');
        try out.appendSlice("- ");
        try out.appendSlice(item);
    }
    return out.toOwnedSlice();
}

/// Multi-item ordered list numbered from `start`, one `N. ` item per line.
pub fn orderedList(allocator: std.mem.Allocator, items: []const []const u8, start: u32) ![]u8 {
    var out = std.array_list.Managed(u8).init(allocator);
    errdefer out.deinit();
    var number = start;
    var buffer = [_]u8{0} ** 16;
    for (items, 0..) |item, index| {
        if (index != 0) try out.append('\n');
        const prefix = try std.fmt.bufPrint(&buffer, "{d}. ", .{number});
        try out.appendSlice(prefix);
        try out.appendSlice(item);
        number += 1;
    }
    return out.toOwnedSlice();
}

/// Escapes the inline Markdown control characters (`\ * _ ~ ` |`) so user text
/// renders literally instead of being interpreted as formatting.
pub fn escapeMarkdown(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    var out = std.array_list.Managed(u8).init(allocator);
    errdefer out.deinit();
    for (text) |char| {
        switch (char) {
            '\\', '*', '_', '~', '`', '|' => try out.append('\\'),
            else => {},
        }
        try out.append(char);
    }
    return out.toOwnedSlice();
}

pub fn escapeBold(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    return escapeOnly(allocator, text, '*');
}

pub fn escapeItalic(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    return escapeOnly(allocator, text, '_');
}

pub fn escapeUnderline(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    return escapeOnly(allocator, text, '_');
}

pub fn escapeStrikethrough(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    return escapeOnly(allocator, text, '~');
}

pub fn escapeSpoiler(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    return escapeOnly(allocator, text, '|');
}

fn escapeOnly(allocator: std.mem.Allocator, text: []const u8, marker: u8) ![]u8 {
    var out = std.array_list.Managed(u8).init(allocator);
    errdefer out.deinit();
    for (text) |char| {
        if (char == '\\' or char == marker) try out.append('\\');
        try out.append(char);
    }
    return out.toOwnedSlice();
}

test "styling helpers produce exact markdown" {
    const b = try bold(std.testing.allocator, "hi");
    defer std.testing.allocator.free(b);
    try std.testing.expectEqualStrings("**hi**", b);

    const i = try italic(std.testing.allocator, "hi");
    defer std.testing.allocator.free(i);
    try std.testing.expectEqualStrings("_hi_", i);

    const u = try underline(std.testing.allocator, "hi");
    defer std.testing.allocator.free(u);
    try std.testing.expectEqualStrings("__hi__", u);

    const s = try strikethrough(std.testing.allocator, "hi");
    defer std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("~~hi~~", s);

    const sp = try spoiler(std.testing.allocator, "hi");
    defer std.testing.allocator.free(sp);
    try std.testing.expectEqualStrings("||hi||", sp);

    const ic = try inlineCode(std.testing.allocator, "hi");
    defer std.testing.allocator.free(ic);
    try std.testing.expectEqualStrings("`hi`", ic);

    const q = try quote(std.testing.allocator, "hi");
    defer std.testing.allocator.free(q);
    try std.testing.expectEqualStrings("> hi", q);

    const bq = try blockQuote(std.testing.allocator, "hi");
    defer std.testing.allocator.free(bq);
    try std.testing.expectEqualStrings(">>> hi", bq);

    const st = try subtext(std.testing.allocator, "hi");
    defer std.testing.allocator.free(st);
    try std.testing.expectEqualStrings("-# hi", st);

    const bp = try bulletPoint(std.testing.allocator, "hi");
    defer std.testing.allocator.free(bp);
    try std.testing.expectEqualStrings("- hi", bp);

    const np = try numberedPoint(std.testing.allocator, 3, "hi");
    defer std.testing.allocator.free(np);
    try std.testing.expectEqualStrings("3. hi", np);
}

test "code blocks render fences and language tags" {
    const cb = try codeBlock(std.testing.allocator, "let x = 1;");
    defer std.testing.allocator.free(cb);
    try std.testing.expectEqualStrings("```\nlet x = 1;\n```", cb);

    const cbl = try codeBlockLang(std.testing.allocator, "zig", "const x = 1;");
    defer std.testing.allocator.free(cbl);
    try std.testing.expectEqualStrings("```zig\nconst x = 1;\n```", cbl);
}

test "hyperlink helpers build markdown links" {
    const link = try hyperlink(std.testing.allocator, "Discord", "https://discord.com");
    defer std.testing.allocator.free(link);
    try std.testing.expectEqualStrings("[Discord](https://discord.com)", link);

    const titled = try hyperlinkTitled(std.testing.allocator, "Discord", "https://discord.com", "Home");
    defer std.testing.allocator.free(titled);
    try std.testing.expectEqualStrings("[Discord](https://discord.com \"Home\")", titled);

    const hidden = try hideLinkEmbed(std.testing.allocator, "https://example.com");
    defer std.testing.allocator.free(hidden);
    try std.testing.expectEqualStrings("<https://example.com>", hidden);
}

test "heading respects level and rejects out-of-range" {
    const h1 = try heading(std.testing.allocator, 1, "Title");
    defer std.testing.allocator.free(h1);
    try std.testing.expectEqualStrings("# Title", h1);

    const h2 = try heading(std.testing.allocator, 2, "Title");
    defer std.testing.allocator.free(h2);
    try std.testing.expectEqualStrings("## Title", h2);

    const h3 = try heading(std.testing.allocator, 3, "Title");
    defer std.testing.allocator.free(h3);
    try std.testing.expectEqualStrings("### Title", h3);

    try std.testing.expectError(error.InvalidHeadingLevel, heading(std.testing.allocator, 0, "Title"));
    try std.testing.expectError(error.InvalidHeadingLevel, heading(std.testing.allocator, 4, "Title"));

    const typed = try headingLevel(std.testing.allocator, .h2, "Typed");
    defer std.testing.allocator.free(typed);
    try std.testing.expectEqualStrings("## Typed", typed);
}

test "slash command mentions build navigation tokens" {
    const cmd = try slashCommandMention(std.testing.allocator, "ban", Snowflake.init(123));
    defer std.testing.allocator.free(cmd);
    try std.testing.expectEqualStrings("</ban:123>", cmd);

    const sub = try slashCommandMentionSub(std.testing.allocator, "config", "set", Snowflake.init(456));
    defer std.testing.allocator.free(sub);
    try std.testing.expectEqualStrings("</config set:456>", sub);

    const grouped = try chatInputApplicationCommandMention(std.testing.allocator, "config", "role", "set", Snowflake.init(789));
    defer std.testing.allocator.free(grouped);
    try std.testing.expectEqualStrings("</config role set:789>", grouped);

    const ts = try timestamp(std.testing.allocator, 1_717_350_000, .relative);
    defer std.testing.allocator.free(ts);
    try std.testing.expectEqualStrings("<t:1717350000:R>", ts);

    try std.testing.expectError(error.InvalidCommandName, slashCommandMention(std.testing.allocator, "", Snowflake.init(1)));
    try std.testing.expectError(error.InvalidCommandName, slashCommandMentionSub(std.testing.allocator, "config", "", Snowflake.init(1)));
}

test "list and escape helpers build multi-item markdown" {
    const items = [_][]const u8{ "first", "second", "third" };

    const ul = try unorderedList(std.testing.allocator, &items);
    defer std.testing.allocator.free(ul);
    try std.testing.expectEqualStrings("- first\n- second\n- third", ul);

    const ol = try orderedList(std.testing.allocator, &items, 1);
    defer std.testing.allocator.free(ol);
    try std.testing.expectEqualStrings("1. first\n2. second\n3. third", ol);

    const ol_offset = try orderedList(std.testing.allocator, &items, 9);
    defer std.testing.allocator.free(ol_offset);
    try std.testing.expectEqualStrings("9. first\n10. second\n11. third", ol_offset);

    const empty = try unorderedList(std.testing.allocator, &.{});
    defer std.testing.allocator.free(empty);
    try std.testing.expectEqualStrings("", empty);

    const escaped = try escapeMarkdown(std.testing.allocator, "a*b_c~d`e|f\\g");
    defer std.testing.allocator.free(escaped);
    try std.testing.expectEqualStrings("a\\*b\\_c\\~d\\`e\\|f\\\\g", escaped);

    const bold_escaped = try escapeBold(std.testing.allocator, "a*b\\c");
    defer std.testing.allocator.free(bold_escaped);
    try std.testing.expectEqualStrings("a\\*b\\\\c", bold_escaped);
}
