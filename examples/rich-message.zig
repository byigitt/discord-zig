const std = @import("std");
const discord = @import("discord");

/// Offline example: build a rich message (content + embed + buttons + a select
/// menu), validate the component layout, and print the exact JSON the library
/// would POST. No token or network required.
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const fields = [_]discord.Types.EmbedField{
        discord.Types.EmbedField.init("Language", "Zig"),
        discord.Types.EmbedField.init("Dependencies", "none"),
    };
    const embeds = [_]discord.Types.Embed{
        discord.Types.Embed.init()
            .withTitle("discord.zig")
            .withDescription("A dependency-light Discord library.")
            .withColor(discord.Colors.blurple)
            .withFields(&fields),
    };
    try embeds[0].validate();

    // Buttons share one action row; a select menu occupies its own row.
    const buttons = [_]discord.Interactions.Component{
        .{ .button = discord.Interactions.Button.primary("confirm", "Confirm") },
        .{ .button = discord.Interactions.Button.link("https://ziglang.org", "Zig") },
    };
    const options = [_]discord.Interactions.SelectOption{
        discord.Interactions.SelectOption.init("Red", "red"),
        discord.Interactions.SelectOption.init("Green", "green"),
    };
    const select_row = [_]discord.Interactions.Component{
        .{ .string_select = discord.Interactions.StringSelect.init("color", &options) },
    };
    const components = [_]discord.Interactions.Component{
        discord.Interactions.Component.actionRow(&buttons),
        discord.Interactions.Component.actionRow(&select_row),
    };

    const message = discord.Types.CreateMessage.init("Welcome to discord.zig!")
        .withEmbeds(&embeds)
        .withComponents(&components);
    try message.validate();

    var out = std.Io.Writer.Allocating.init(allocator);
    defer out.deinit();
    try message.writeJson(&out.writer);

    std.debug.print("POST /channels/{{channel_id}}/messages body:\n{s}\n", .{out.written()});
}
