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
const Cache = Root.Cache;
const ClientOptions = Root.ClientOptions;
const SetActivityOptions = Root.SetActivityOptions;
const Client = Root.Client;
const GatewayStep = Root.GatewayStep;
const GatewayStartMode = Root.GatewayStartMode;
const ReconnectBackoff = Root.ReconnectBackoff;
const GatewayRunner = Root.GatewayRunner;
const noTransportValue = Root.noTransportValue;
const noTransportSend = Root.noTransportSend;

test "client user and application conveniences hit REST routes" {
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
    _ = try client.setCurrentUserBanner("data:image/png;base64,DDDD");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"banner\":\"data:image/png;base64,DDDD\"}", memory.last_request.?.body.?);

    _ = try client.clearCurrentUserBanner();
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"banner\":null}", memory.last_request.?.body.?);

    _ = try client.editMe(Types.EditCurrentUser.init().withUsername("aliasbot"));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"username\":\"aliasbot\"}", memory.last_request.?.body.?);

    _ = try client.createDmChannel(Snowflake.init(30));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/channels", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"recipient_id\":\"30\"}", memory.last_request.?.body.?);

    _ = try client.createDm(Snowflake.init(30));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/channels", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"recipient_id\":\"30\"}", memory.last_request.?.body.?);

    _ = try client.createDM(Snowflake.init(30));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/channels", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"recipient_id\":\"30\"}", memory.last_request.?.body.?);

    _ = try client.listCurrentUserGuilds(Types.ListCurrentUserGuilds.init().withLimit(25).withCounts(false));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/users/@me/guilds?limit=25&with_counts=false",
        memory.last_request.?.url,
    );

    _ = try client.fetchCurrentUserGuilds(Types.ListCurrentUserGuilds.init().withLimit(25).withCounts(false));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/users/@me/guilds?limit=25&with_counts=false",
        memory.last_request.?.url,
    );

    _ = try client.getCurrentUserGuildMember(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/guilds/10/member", memory.last_request.?.url);

    _ = try client.fetchCurrentUserGuildMember(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/guilds/10/member", memory.last_request.?.url);

    _ = try client.fetchMeGuildMember(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/guilds/10/member", memory.last_request.?.url);

    _ = try client.listCurrentUserConnections();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/connections", memory.last_request.?.url);

    _ = try client.fetchCurrentUserConnections();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/connections", memory.last_request.?.url);

    _ = try client.getCurrentAuthorization("Bearer user-token");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/oauth2/@me", memory.last_request.?.url);

    _ = try client.fetchCurrentAuthorization("Bearer user-token");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/oauth2/@me", memory.last_request.?.url);

    _ = try client.exchangeOAuth2Token("Basic client-secret", Types.OAuth2TokenRequest.refreshToken("refresh token"));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Basic client-secret", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/oauth2/token", memory.last_request.?.url);
    try std.testing.expectEqualStrings("application/x-www-form-urlencoded", memory.last_request.?.content_type.?);
    try std.testing.expectEqualStrings(
        "grant_type=refresh_token&refresh_token=refresh%20token",
        memory.last_request.?.body.?,
    );

    _ = try client.revokeOAuth2Token("Basic client-secret", Types.OAuth2TokenRevocation.init("access token"));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Basic client-secret", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/oauth2/token/revoke", memory.last_request.?.url);
    try std.testing.expectEqualStrings("application/x-www-form-urlencoded", memory.last_request.?.content_type.?);
    try std.testing.expectEqualStrings("token=access%20token", memory.last_request.?.body.?);

    _ = try client.getCurrentUserApplicationRoleConnection("Bearer user-token", Snowflake.init(99));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/users/@me/applications/99/role-connection",
        memory.last_request.?.url,
    );

    _ = try client.fetchCurrentUserApplicationRoleConnection("Bearer user-token", Snowflake.init(99));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/users/@me/applications/99/role-connection",
        memory.last_request.?.url,
    );

    _ = try client.setCurrentUserApplicationRoleConnection(
        "Bearer user-token",
        Snowflake.init(99),
        Types.UpdateApplicationRoleConnection.init().withPlatformUsername("baris"),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings("{\"platform_username\":\"baris\"}", memory.last_request.?.body.?);

    _ = try client.deleteCurrentUserApplicationRoleConnection("Bearer user-token", Snowflake.init(99));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/users/@me/applications/99/role-connection",
        memory.last_request.?.url,
    );

    _ = try client.leaveGuild(Snowflake.init(10));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/guilds/10", memory.last_request.?.url);

    _ = try client.getGuild(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10", memory.last_request.?.url);

    _ = try client.fetchGuild(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10", memory.last_request.?.url);

    _ = try client.getGuildWithOptions(Snowflake.init(10), Types.GetGuild.init().withCounts(true));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10?with_counts=true", memory.last_request.?.url);

    _ = try client.fetchGuildWithOptions(Snowflake.init(10), Types.GetGuild.init().withCounts(true));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10?with_counts=true", memory.last_request.?.url);

    _ = try client.getGuildPreview(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/preview", memory.last_request.?.url);

    _ = try client.fetchGuildPreview(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/preview", memory.last_request.?.url);

    _ = try client.editGuild(
        Snowflake.init(10),
        Types.EditGuild.init()
            .withDescription("Zig community")
            .clearBanner(),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"banner\":null,\"description\":\"Zig community\"}", memory.last_request.?.body.?);

    _ = try client.getChannel(Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/30", memory.last_request.?.url);

    _ = try client.fetchChannel(Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/30", memory.last_request.?.url);

    _ = try client.fetchGuildTemplate("abc 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/templates/abc%20123", memory.last_request.?.url);

    _ = try client.fetchGuildTemplates(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/templates", memory.last_request.?.url);

    _ = try client.createGuildTemplate(Snowflake.init(10), Types.CreateGuildTemplate.init("starter"));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/templates", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"starter\"}", memory.last_request.?.body.?);

    _ = try client.deleteGuildTemplate(Snowflake.init(10), "abc 123");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/templates/abc%20123", memory.last_request.?.url);

    _ = try client.fetchGuildWidgetSettings(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/widget", memory.last_request.?.url);

    _ = try client.editGuildWidgetSettings(
        Snowflake.init(10),
        Types.EditGuildWidgetSettings.init().clearChannel(),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/widget", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"channel_id\":null}", memory.last_request.?.body.?);

    _ = try client.fetchGuildWidget(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/widget.json", memory.last_request.?.url);

    _ = try client.getGuildWidgetImage(Snowflake.init(10), Types.GetGuildWidgetImage.init().withStyle(.banner1));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/widget.png?style=banner1", memory.last_request.?.url);

    _ = try client.fetchGuildWidgetImage(Snowflake.init(10), Types.GetGuildWidgetImage.init());
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/widget.png", memory.last_request.?.url);

    _ = try client.fetchGuildWelcomeScreen(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/welcome-screen", memory.last_request.?.url);

    _ = try client.editGuildWelcomeScreen(
        Snowflake.init(10),
        Types.EditWelcomeScreen.init()
            .enabledState(false)
            .clearDescription(),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/welcome-screen", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"enabled\":false,\"description\":null}", memory.last_request.?.body.?);

    _ = try client.getGuildOnboarding(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/onboarding", memory.last_request.?.url);

    _ = try client.fetchGuildOnboarding(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/onboarding", memory.last_request.?.url);

    _ = try client.editGuildOnboarding(
        Snowflake.init(10),
        Types.EditGuildOnboarding.init().enabledState(false),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/onboarding", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"enabled\":false}", memory.last_request.?.body.?);

    _ = try client.setGuildOnboarding(
        Snowflake.init(10),
        Types.EditGuildOnboarding.init().withMode(.onboarding_advanced),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/onboarding", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"mode\":1}", memory.last_request.?.body.?);

    _ = try client.editGuildIncidentActions(
        Snowflake.init(10),
        Types.EditGuildIncidentActions.init().clearInvitesDisabledUntil(),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/incident-actions", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"invites_disabled_until\":null}", memory.last_request.?.body.?);

    _ = try client.setGuildIncidentActions(
        Snowflake.init(10),
        Types.EditGuildIncidentActions.init().clearDmsDisabledUntil(),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/incident-actions", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"dms_disabled_until\":null}", memory.last_request.?.body.?);

    _ = try client.getGuildVanityUrl(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/vanity-url", memory.last_request.?.url);

    _ = try client.fetchGuildVanityUrl(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/vanity-url", memory.last_request.?.url);

    _ = try client.fetchGuildScheduledEvents(Snowflake.init(10), Types.ListGuildScheduledEvents.init().withUserCount(true));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/scheduled-events?with_user_count=true",
        memory.last_request.?.url,
    );

    _ = try client.fetchGuildScheduledEvent(Snowflake.init(10), Snowflake.init(20), Types.GetGuildScheduledEvent.init().withUserCount(true));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/scheduled-events/20?with_user_count=true",
        memory.last_request.?.url,
    );

    _ = try client.createGuildScheduledEvent(
        Snowflake.init(10),
        Types.CreateGuildScheduledEvent.init("Meetup", "2026-06-02T10:00:00.000Z", .external)
            .withMetadata(Types.GuildScheduledEventEntityMetadata.withLocation("Istanbul"))
            .withEndTime("2026-06-02T12:00:00.000Z"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/scheduled-events", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"entity_metadata\":{\"location\":\"Istanbul\"},\"name\":\"Meetup\",\"privacy_level\":2,\"scheduled_start_time\":\"2026-06-02T10:00:00.000Z\",\"scheduled_end_time\":\"2026-06-02T12:00:00.000Z\",\"entity_type\":3}",
        memory.last_request.?.body.?,
    );
}
