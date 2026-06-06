const std = @import("std");
const Intents = @import("../../../core/intents.zig");
const Rest = @import("../../../rest/client.zig");
const HttpTransport = @import("../../../rest/http-transport.zig").HttpTransport;
const Events = @import("../../../gateway/events.zig");
const Gateway = @import("../../../gateway/protocol.zig");
const GatewaySession = @import("../../../gateway/session.zig");
const CacheModule = @import("../../cache.zig");
const Interactions = @import("../../../interactions/mod.zig");
const Types = @import("../../../models/types.zig");
const Snowflake = @import("../../../core/snowflake.zig").Snowflake;
const Root = @import("../../client.zig");
const Client = Root.Client;

test "client pin and thread conveniences hit REST routes" {
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
    _ = try client.createGuildBan(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.CreateGuildBan.init().deleteMessagesFor(3600),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bans/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"delete_message_seconds\":3600}", memory.last_request.?.body.?);

    _ = try client.ban(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.CreateGuildBan.init().deleteMessagesFor(60),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bans/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"delete_message_seconds\":60}", memory.last_request.?.body.?);

    _ = try client.banUser(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bans/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{}", memory.last_request.?.body.?);

    _ = try client.banUserDeletingMessagesFor(Snowflake.init(10), Snowflake.init(20), 120);
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bans/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"delete_message_seconds\":120}", memory.last_request.?.body.?);

    const bulk_user_ids = [_]Snowflake{ Snowflake.init(20), Snowflake.init(30) };
    _ = try client.bulkGuildBan(Snowflake.init(10), Types.BulkGuildBan.init(&bulk_user_ids).deleteMessagesFor(120));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bulk-ban", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"user_ids\":[\"20\",\"30\"],\"delete_message_seconds\":120}",
        memory.last_request.?.body.?,
    );

    _ = try client.bulkBan(Snowflake.init(10), Types.BulkGuildBan.init(&bulk_user_ids));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bulk-ban", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"user_ids\":[\"20\",\"30\"]}", memory.last_request.?.body.?);

    _ = try client.bulkBanUsers(Snowflake.init(10), &bulk_user_ids);
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bulk-ban", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"user_ids\":[\"20\",\"30\"]}", memory.last_request.?.body.?);

    _ = try client.bulkBanUsersDeletingMessagesFor(Snowflake.init(10), &bulk_user_ids, 180);
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bulk-ban", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"user_ids\":[\"20\",\"30\"],\"delete_message_seconds\":180}",
        memory.last_request.?.body.?,
    );

    _ = try client.removeGuildBan(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bans/20", memory.last_request.?.url);

    _ = try client.unban(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/bans/20", memory.last_request.?.url);

    _ = try client.listGuildMembers(Snowflake.init(10), Types.ListGuildMembers.init().withLimit(50));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/members?limit=50",
        memory.last_request.?.url,
    );

    _ = try client.fetchMembers(Snowflake.init(10), Types.ListGuildMembers.init().withLimit(50));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/members?limit=50",
        memory.last_request.?.url,
    );

    _ = try client.searchGuildMembers(
        Snowflake.init(10),
        Types.SearchGuildMembers.init("helper bot").withLimit(10),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/members/search?query=helper%20bot&limit=10",
        memory.last_request.?.url,
    );

    _ = try client.searchMembers(
        Snowflake.init(10),
        Types.SearchGuildMembers.init("helper bot").withLimit(10),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/members/search?query=helper%20bot&limit=10",
        memory.last_request.?.url,
    );

    _ = try client.getGuildMember(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);

    _ = try client.fetchMember(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);

    const member_roles = [_]Snowflake{Snowflake.init(30)};
    _ = try client.addGuildMember(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.AddGuildMember.init("oauth-access")
            .withNick("helper")
            .withRoles(&member_roles)
            .deafState(true),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"access_token\":\"oauth-access\",\"nick\":\"helper\",\"roles\":[\"30\"],\"deaf\":true}",
        memory.last_request.?.body.?,
    );

    _ = try client.editCurrentGuildMember(
        Snowflake.init(10),
        Types.EditCurrentGuildMember.init()
            .clearNick()
            .withBio("Built with Zig"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"nick\":null,\"bio\":\"Built with Zig\"}", memory.last_request.?.body.?);

    _ = try client.setCurrentGuildMemberNick(Snowflake.init(10), "ziggy");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"nick\":\"ziggy\"}", memory.last_request.?.body.?);

    _ = try client.clearCurrentGuildMemberNick(Snowflake.init(10));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"nick\":null}", memory.last_request.?.body.?);

    _ = try client.setCurrentGuildMemberAvatar(Snowflake.init(10), "data:image/png;base64,AAAA");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"avatar\":\"data:image/png;base64,AAAA\"}", memory.last_request.?.body.?);

    _ = try client.clearCurrentGuildMemberAvatar(Snowflake.init(10));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"avatar\":null}", memory.last_request.?.body.?);

    _ = try client.setCurrentGuildMemberBanner(Snowflake.init(10), "data:image/png;base64,BBBB");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"banner\":\"data:image/png;base64,BBBB\"}", memory.last_request.?.body.?);

    _ = try client.clearCurrentGuildMemberBanner(Snowflake.init(10));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"banner\":null}", memory.last_request.?.body.?);

    _ = try client.setCurrentGuildMemberBio(Snowflake.init(10), "Built with Zig");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"bio\":\"Built with Zig\"}", memory.last_request.?.body.?);

    _ = try client.clearCurrentGuildMemberBio(Snowflake.init(10));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"bio\":null}", memory.last_request.?.body.?);

    _ = try client.editCurrentUserNick(Snowflake.init(10), Types.EditCurrentUserNick.init().withNick("ziggy"));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me/nick", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"nick\":\"ziggy\"}", memory.last_request.?.body.?);

    _ = try client.setCurrentUserNick(Snowflake.init(10), null);
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me/nick", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"nick\":null}", memory.last_request.?.body.?);

    _ = try client.setNickname(Snowflake.init(10), "zig");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/@me/nick", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"nick\":\"zig\"}", memory.last_request.?.body.?);

    _ = try client.editGuildMember(Snowflake.init(10), Snowflake.init(20), Types.EditGuildMember.init().withNick("helper"));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"nick\":\"helper\"}", memory.last_request.?.body.?);

    _ = try client.setMemberNickname(Snowflake.init(10), Snowflake.init(20), "helper-2");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"nick\":\"helper-2\"}", memory.last_request.?.body.?);

    _ = try client.setMemberRoles(Snowflake.init(10), Snowflake.init(20), &.{ Snowflake.init(30), Snowflake.init(31) });
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"roles\":[\"30\",\"31\"]}", memory.last_request.?.body.?);

    _ = try client.muteMember(Snowflake.init(10), Snowflake.init(20), true);
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"mute\":true}", memory.last_request.?.body.?);

    _ = try client.deafenMember(Snowflake.init(10), Snowflake.init(20), true);
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"deaf\":true}", memory.last_request.?.body.?);

    _ = try client.moveMemberToVoiceChannel(Snowflake.init(10), Snowflake.init(20), Snowflake.init(40));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"channel_id\":\"40\"}", memory.last_request.?.body.?);

    _ = try client.timeoutMember(Snowflake.init(10), Snowflake.init(20), "2026-06-02T10:00:00.000Z");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"communication_disabled_until\":\"2026-06-02T10:00:00.000Z\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.clearMemberTimeout(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"communication_disabled_until\":null}", memory.last_request.?.body.?);

    _ = try client.kick(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);

    _ = try client.addGuildMemberRole(Snowflake.init(10), Snowflake.init(20), Snowflake.init(30));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20/roles/30", memory.last_request.?.url);

    _ = try client.addRole(Snowflake.init(10), Snowflake.init(20), Snowflake.init(30));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20/roles/30", memory.last_request.?.url);

    _ = try client.removeGuildMemberRole(Snowflake.init(10), Snowflake.init(20), Snowflake.init(30));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20/roles/30", memory.last_request.?.url);

    _ = try client.removeRole(Snowflake.init(10), Snowflake.init(20), Snowflake.init(30));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20/roles/30", memory.last_request.?.url);

    _ = try client.listGuildChannels(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/channels", memory.last_request.?.url);

    _ = try client.fetchGuildChannels(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/channels", memory.last_request.?.url);

    _ = try client.createGuildChannel(
        Snowflake.init(10),
        Types.CreateGuildChannel.init("general")
            .withType(.guild_forum)
            .withFlags(Types.ChannelFlags.require_tag)
            .withAvailableTags(&.{Types.WriteForumTag.init("Help").moderatedState(true)})
            .withDefaultReactionEmoji(Types.DefaultReactionEmoji.name("👋"))
            .withDefaultThreadRateLimit(5)
            .withDefaultSortOrder(.creation_date),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/channels", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"general\",\"type\":15,\"flags\":16,\"available_tags\":[{\"name\":\"Help\",\"moderated\":true}],\"default_reaction_emoji\":{\"emoji_name\":\"👋\"},\"default_thread_rate_limit_per_user\":5,\"default_sort_order\":1}",
        memory.last_request.?.body.?,
    );

    const channel_positions = [_]Types.GuildChannelPosition{
        Types.GuildChannelPosition.init(Snowflake.init(20))
            .withPosition(4)
            .lockPermissions(true),
    };
    _ = try client.editGuildChannelPositions(Snowflake.init(10), &channel_positions);
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/channels", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "[{\"id\":\"20\",\"position\":4,\"lock_permissions\":true}]",
        memory.last_request.?.body.?,
    );

    _ = try client.setGuildChannelPositions(Snowflake.init(10), &channel_positions);
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/channels", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "[{\"id\":\"20\",\"position\":4,\"lock_permissions\":true}]",
        memory.last_request.?.body.?,
    );
}
