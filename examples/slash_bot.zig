const std = @import("std");
const discord = @import("discord");

/// Holds bot state and answers the `/ping` slash command. The interaction
/// router calls `onPing` whenever a matching command interaction arrives.
const Bot = struct {
    replies: usize = 0,

    fn onPing(self: *Bot, interaction: *const discord.Interactions.ParsedInteraction) !void {
        _ = interaction;
        self.replies += 1;
    }
};

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 1. Define a slash command and validate it against Discord's limits before
    //    registering it. Install/integration types make it user-installable.
    const command = discord.Interactions.ApplicationCommand
        .chatInput("ping", "Replies with pong")
        .withIntegrationTypes(&.{ .guild_install, .user_install })
        .withContexts(&.{ .guild, .bot_dm });
    try command.validate();

    // 2. Wire an interaction router: command interactions named "ping" go to the
    //    typed handler above.
    var bot = Bot{};
    const routes = [_]discord.Interactions.CommandRoute{
        .{ .name = "ping", .handler = discord.Interactions.parsedHandler(&bot, Bot.onPing) },
    };
    const router = discord.Interactions.InteractionRouter{ .commands = &routes };

    // 3. Parse an incoming interaction payload and dispatch it through the router.
    var interaction = try discord.Interactions.parseInteraction(
        allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\"," ++
            "\"data\":{\"id\":\"10\",\"name\":\"ping\",\"type\":1}}",
    );
    defer interaction.deinit();
    const handled = try router.dispatch(&interaction);

    // 4. Build the ephemeral reply the handler would send, plus an embed that
    //    uses the Discord color palette.
    var response = std.Io.Writer.Allocating.init(allocator);
    defer response.deinit();
    try discord.Interactions.InteractionResponse
        .message("pong")
        .ephemeralState(true)
        .writeJson(&response.writer);

    const embed = discord.Types.Embed.init()
        .withTitle("Pong!")
        .withColor(discord.Colors.blurple);

    std.debug.print(
        "command={s} handled={} replies={d} response={s} embed_color={d}\n",
        .{ command.name, handled, bot.replies, response.written(), embed.color.? },
    );
}
