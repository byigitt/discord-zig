const std = @import("std");
const Api = @import("../../core/api.zig");
const Routes = @import("../routes.zig");
const Types = @import("../../models/types.zig");
const Interactions = @import("../../interactions/mod.zig");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;

const Root = @import("../client.zig");
const Client = Root.Client;
const MemoryTransport = Root.MemoryTransport;

test "REST user guild and channel helpers use expected routes" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.getGateway();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/gateway", memory.last_request.?.url);

    _ = try client.getGatewayBot();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bot test", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/gateway/bot", memory.last_request.?.url);

    _ = try client.getCurrentApplication();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/@me", memory.last_request.?.url);

    _ = try client.getCurrentBotApplication();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bot test", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/oauth2/applications/@me", memory.last_request.?.url);

    _ = try client.editCurrentApplication(Types.EditCurrentApplication.init()
        .withDescription("Fast Zig bot")
        .withTags(&.{ "zig", "bot" })
        .clearIcon());
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"description\":\"Fast Zig bot\",\"icon\":null,\"tags\":[\"zig\",\"bot\"]}",
        memory.last_request.?.body.?,
    );

    _ = try client.listApplicationSkus(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/skus", memory.last_request.?.url);

    _ = try client.listApplicationRoleConnectionMetadataRecords(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/role-connections/metadata",
        memory.last_request.?.url,
    );

    const metadata_records = [_]Types.ApplicationRoleConnectionMetadata{
        Types.ApplicationRoleConnectionMetadata.init(.integer_greater_than_or_equal, "level", "Level", "Player level"),
    };
    _ = try client.updateApplicationRoleConnectionMetadataRecords(
        Snowflake.init(10),
        Types.UpdateApplicationRoleConnectionMetadataRecords.init(&metadata_records),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/role-connections/metadata",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "[{\"type\":2,\"key\":\"level\",\"name\":\"Level\",\"description\":\"Player level\"}]",
        memory.last_request.?.body.?,
    );

    _ = try client.listEntitlements(
        Snowflake.init(10),
        Types.ListEntitlements.init()
            .forUser(Snowflake.init(20))
            .withSkus(&.{Snowflake.init(30)})
            .withLimit(25)
            .excludeDeleted(false),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/applications/10/entitlements?user_id=20&sku_ids=30&limit=25&exclude_deleted=false",
        memory.last_request.?.url,
    );

    _ = try client.getEntitlement(Snowflake.init(10), Snowflake.init(40));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/entitlements/40", memory.last_request.?.url);

    _ = try client.consumeEntitlement(Snowflake.init(10), Snowflake.init(40));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/entitlements/40/consume", memory.last_request.?.url);
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.createTestEntitlement(
        Snowflake.init(10),
        Types.CreateTestEntitlement.init(Snowflake.init(30), Snowflake.init(50), .user),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/entitlements", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"sku_id\":\"30\",\"owner_id\":\"50\",\"owner_type\":2}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteTestEntitlement(Snowflake.init(10), Snowflake.init(40));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/applications/10/entitlements/40", memory.last_request.?.url);

    _ = try client.listSkuSubscriptions(
        Snowflake.init(30),
        Types.ListSkuSubscriptions.init()
            .forUser(Snowflake.init(20))
            .withLimit(50),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/skus/30/subscriptions?limit=50&user_id=20",
        memory.last_request.?.url,
    );

    _ = try client.getSkuSubscription(Snowflake.init(30), Snowflake.init(60));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/skus/30/subscriptions/60", memory.last_request.?.url);

    _ = try client.listGuildIntegrations(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/integrations", memory.last_request.?.url);

    _ = try client.deleteGuildIntegration(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/integrations/20", memory.last_request.?.url);

    _ = try client.getCurrentUser();
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);

    _ = try client.editCurrentUser(
        Types.EditCurrentUser.init()
            .withUsername("zigbot")
            .clearBanner(),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"username\":\"zigbot\",\"banner\":null}", memory.last_request.?.body.?);

    _ = try client.createDmChannel(Snowflake.init(40));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/channels", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"recipient_id\":\"40\"}", memory.last_request.?.body.?);

    _ = try client.listCurrentUserGuilds(.{
        .after = Snowflake.init(20),
        .limit = 50,
        .with_counts = true,
    });
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/users/@me/guilds?after=20&limit=50&with_counts=true",
        memory.last_request.?.url,
    );

    _ = try client.getCurrentUserGuildMember(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/guilds/10/member", memory.last_request.?.url);

    _ = try client.listCurrentUserConnections();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/users/@me/connections", memory.last_request.?.url);

    _ = try client.getCurrentAuthorization("Bearer user-token");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/oauth2/@me", memory.last_request.?.url);

    _ = try client.exchangeOAuth2Token("Basic client-secret", Types.OAuth2TokenRequest.authorizationCode("code value")
        .withRedirectUri("https://example.com/callback"));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Basic client-secret", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/oauth2/token", memory.last_request.?.url);
    try std.testing.expectEqualStrings("application/x-www-form-urlencoded", memory.last_request.?.content_type.?);
    try std.testing.expectEqualStrings(
        "grant_type=authorization_code&code=code%20value&redirect_uri=https%3A%2F%2Fexample.com%2Fcallback",
        memory.last_request.?.body.?,
    );

    _ = try client.revokeOAuth2Token(
        "Basic client-secret",
        Types.OAuth2TokenRevocation.init("refresh token").withTokenTypeHint("refresh_token"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Basic client-secret", memory.last_request.?.token);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/oauth2/token/revoke", memory.last_request.?.url);
    try std.testing.expectEqualStrings("application/x-www-form-urlencoded", memory.last_request.?.content_type.?);
    try std.testing.expectEqualStrings(
        "token=refresh%20token&token_type_hint=refresh_token",
        memory.last_request.?.body.?,
    );

    _ = try client.getCurrentUserApplicationRoleConnection("Bearer user-token", Snowflake.init(99));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/users/@me/applications/99/role-connection",
        memory.last_request.?.url,
    );

    _ = try client.updateCurrentUserApplicationRoleConnection(
        "Bearer user-token",
        Snowflake.init(99),
        Types.UpdateApplicationRoleConnection.init()
            .withPlatformName("zig league")
            .withMetadata(&.{.{ .key = "level", .value = "42" }}),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "{\"platform_name\":\"zig league\",\"metadata\":{\"level\":\"42\"}}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteCurrentUserApplicationRoleConnection("Bearer user-token", Snowflake.init(99));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("Bearer user-token", memory.last_request.?.token);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/users/@me/applications/99/role-connection",
        memory.last_request.?.url,
    );

    _ = try client.leaveGuild(Snowflake.init(10));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/users/@me/guilds/10",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.getGuild(Snowflake.init(10));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10", memory.last_request.?.url);

    _ = try client.getGuildWithOptions(Snowflake.init(10), Types.GetGuild.init().withCounts(true));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10?with_counts=true",
        memory.last_request.?.url,
    );

    _ = try client.getGuildPreview(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/preview", memory.last_request.?.url);

    _ = try client.editGuild(
        Snowflake.init(10),
        Types.EditGuild.init()
            .withName("zig guild")
            .clearIcon()
            .withSafetyAlertsChannel(Snowflake.init(30)),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"zig guild\",\"icon\":null,\"safety_alerts_channel_id\":\"30\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.listAutoModerationRules(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/auto-moderation/rules",
        memory.last_request.?.url,
    );

    _ = try client.getAutoModerationRule(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/auto-moderation/rules/20",
        memory.last_request.?.url,
    );

    _ = try client.createAutoModerationRule(Snowflake.init(10), Types.CreateAutoModerationRule.init(
        "keyword guard",
        .keyword,
        &.{Types.AutoModerationAction.blockMessage("Please reword that")},
    )
        .withTriggerMetadata(Types.AutoModerationTriggerMetadata.init().withKeywordFilter(&.{"cat*"}))
        .enabledState(true));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/auto-moderation/rules",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"keyword guard\",\"event_type\":1,\"trigger_type\":1,\"trigger_metadata\":{\"keyword_filter\":[\"cat*\"]},\"actions\":[{\"type\":1,\"metadata\":{\"custom_message\":\"Please reword that\"}}],\"enabled\":true}",
        memory.last_request.?.body.?,
    );

    _ = try client.editAutoModerationRule(Snowflake.init(10), Snowflake.init(20), Types.EditAutoModerationRule.init()
        .enabledState(false)
        .withActions(&.{Types.AutoModerationAction.timeout(60)})
        .withExemptChannels(&.{Snowflake.init(30)}));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/auto-moderation/rules/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"actions\":[{\"type\":3,\"metadata\":{\"duration_seconds\":60}}],\"enabled\":false,\"exempt_channels\":[\"30\"]}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteAutoModerationRule(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/auto-moderation/rules/20",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);

    _ = try client.getGuildTemplate("abc 123");
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/templates/abc%20123", memory.last_request.?.url);

    _ = try client.listGuildTemplates(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/templates", memory.last_request.?.url);

    _ = try client.createGuildTemplate(
        Snowflake.init(10),
        Types.CreateGuildTemplate.init("starter").withDescription("Project starter"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/templates", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"starter\",\"description\":\"Project starter\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.syncGuildTemplate(Snowflake.init(10), "abc 123");
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/templates/abc%20123", memory.last_request.?.url);

    _ = try client.editGuildTemplate(
        Snowflake.init(10),
        "abc 123",
        Types.EditGuildTemplate.init().withDescription("Updated"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/templates/abc%20123", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"description\":\"Updated\"}", memory.last_request.?.body.?);

    _ = try client.deleteGuildTemplate(Snowflake.init(10), "abc 123");
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/templates/abc%20123", memory.last_request.?.url);

    _ = try client.getGuildWidgetSettings(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/widget", memory.last_request.?.url);

    _ = try client.editGuildWidgetSettings(
        Snowflake.init(10),
        Types.EditGuildWidgetSettings.init()
            .enabledState(true)
            .withChannel(Snowflake.init(20)),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/widget", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"enabled\":true,\"channel_id\":\"20\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.getGuildWidget(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/widget.json", memory.last_request.?.url);

    _ = try client.getGuildWidgetImage(Snowflake.init(10), Types.GetGuildWidgetImage.init());
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/widget.png", memory.last_request.?.url);

    _ = try client.getGuildWidgetImage(Snowflake.init(10), Types.GetGuildWidgetImage.init().withStyle(.banner3));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/widget.png?style=banner3", memory.last_request.?.url);

    _ = try client.getGuildWelcomeScreen(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/welcome-screen", memory.last_request.?.url);

    const welcome_channels = [_]Types.WelcomeScreenChannel{
        Types.WelcomeScreenChannel.init(Snowflake.init(20), "Read rules")
            .withEmojiName("wave"),
    };
    _ = try client.editGuildWelcomeScreen(
        Snowflake.init(10),
        Types.EditWelcomeScreen.init()
            .enabledState(true)
            .withChannels(&welcome_channels)
            .withDescription("Start here"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/welcome-screen", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"enabled\":true,\"welcome_channels\":[{\"channel_id\":\"20\",\"description\":\"Read rules\",\"emoji_name\":\"wave\"}],\"description\":\"Start here\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.getGuildOnboarding(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/onboarding", memory.last_request.?.url);

    _ = try client.editGuildOnboarding(
        Snowflake.init(10),
        Types.EditGuildOnboarding.init()
            .withDefaultChannels(&.{ Snowflake.init(20), Snowflake.init(21) })
            .enabledState(true)
            .withMode(.onboarding_default),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/onboarding", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"default_channel_ids\":[\"20\",\"21\"],\"enabled\":true,\"mode\":0}",
        memory.last_request.?.body.?,
    );

    _ = try client.editGuildIncidentActions(
        Snowflake.init(10),
        Types.EditGuildIncidentActions.init()
            .disableInvitesUntil("2026-06-03T12:00:00.000Z")
            .clearDmsDisabledUntil(),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/incident-actions", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"invites_disabled_until\":\"2026-06-03T12:00:00.000Z\",\"dms_disabled_until\":null}",
        memory.last_request.?.body.?,
    );

    _ = try client.getGuildVanityUrl(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/vanity-url", memory.last_request.?.url);

    _ = try client.listGuildScheduledEvents(Snowflake.init(10), Types.ListGuildScheduledEvents.init().withUserCount(true));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/scheduled-events?with_user_count=true",
        memory.last_request.?.url,
    );

    _ = try client.createGuildScheduledEvent(
        Snowflake.init(10),
        Types.CreateGuildScheduledEvent.init("Launch", "2026-06-02T10:00:00.000Z", .voice)
            .withChannel(Snowflake.init(40)),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/scheduled-events", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"channel_id\":\"40\",\"name\":\"Launch\",\"privacy_level\":2,\"scheduled_start_time\":\"2026-06-02T10:00:00.000Z\",\"entity_type\":2}",
        memory.last_request.?.body.?,
    );

    _ = try client.getGuildScheduledEvent(Snowflake.init(10), Snowflake.init(20), Types.GetGuildScheduledEvent.init().withUserCount(false));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/scheduled-events/20?with_user_count=false",
        memory.last_request.?.url,
    );

    _ = try client.editGuildScheduledEvent(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.EditGuildScheduledEvent.init()
            .withStatus(.active)
            .clearDescription(),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/scheduled-events/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"description\":null,\"status\":2}", memory.last_request.?.body.?);

    _ = try client.listGuildScheduledEventUsers(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.ListGuildScheduledEventUsers.init()
            .withLimit(25)
            .withMember(true)
            .afterUser(Snowflake.init(30)),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/scheduled-events/20/users?limit=25&with_member=true&after=30",
        memory.last_request.?.url,
    );

    _ = try client.deleteGuildScheduledEvent(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/scheduled-events/20", memory.last_request.?.url);

    _ = try client.listGuildAuditLog(
        Snowflake.init(10),
        Types.ListAuditLog.init()
            .forUser(Snowflake.init(20))
            .withActionType(72)
            .afterEntry(Snowflake.init(30))
            .withLimit(10),
    );
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/audit-logs?user_id=20&action_type=72&after=30&limit=10",
        memory.last_request.?.url,
    );

    _ = try client.listGuildAuditLog(Snowflake.init(10), Types.ListAuditLog.init());
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/audit-logs", memory.last_request.?.url);

    _ = try client.listGuildChannels(Snowflake.init(10));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/channels", memory.last_request.?.url);

    _ = try client.getGuildMember(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/members/20", memory.last_request.?.url);

    _ = try client.getChannel(Snowflake.init(30));
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/30", memory.last_request.?.url);
}
