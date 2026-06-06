const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Json = @import("../../core/json.zig");

const Root = @import("../types.zig");
const User = Root.User;
const StringPair = Root.StringPair;
const ApplicationRoleConnectionMetadata = Root.ApplicationRoleConnectionMetadata;
const UpdateApplicationRoleConnectionMetadataRecords = Root.UpdateApplicationRoleConnectionMetadataRecords;
const ApplicationEventWebhookType = Root.ApplicationEventWebhookType;
const ApplicationEventWebhookPayloadType = Root.ApplicationEventWebhookPayloadType;
const ApplicationEventWebhookPayload = Root.ApplicationEventWebhookPayload;
const ListEntitlements = Root.ListEntitlements;
const CreateTestEntitlement = Root.CreateTestEntitlement;
const ListSkuSubscriptions = Root.ListSkuSubscriptions;
const ApplicationInstallParams = Root.ApplicationInstallParams;
const ListGuildScheduledEvents = Root.ListGuildScheduledEvents;
const GetGuildScheduledEvent = Root.GetGuildScheduledEvent;
const ListGuildScheduledEventUsers = Root.ListGuildScheduledEventUsers;
const GuildMember = Root.GuildMember;
const CreateGuildScheduledEvent = Root.CreateGuildScheduledEvent;
const EditGuildScheduledEvent = Root.EditGuildScheduledEvent;
const CreateStageInstance = Root.CreateStageInstance;
const EditStageInstance = Root.EditStageInstance;
const EditCurrentUserVoiceState = Root.EditCurrentUserVoiceState;
const EditUserVoiceState = Root.EditUserVoiceState;
const EditCurrentApplication = Root.EditCurrentApplication;
const OAuth2TokenRequest = Root.OAuth2TokenRequest;
const OAuth2TokenRevocation = Root.OAuth2TokenRevocation;
const ListAuditLog = Root.ListAuditLog;
const ListCurrentUserGuilds = Root.ListCurrentUserGuilds;
const GetGuild = Root.GetGuild;
const ListGuildBans = Root.ListGuildBans;
const ListGuildMembers = Root.ListGuildMembers;
const GetGuildPruneCount = Root.GetGuildPruneCount;
const BeginGuildPrune = Root.BeginGuildPrune;
const SearchGuildMembers = Root.SearchGuildMembers;
const UpdateApplicationRoleConnection = Root.UpdateApplicationRoleConnection;
const CreateMessage = Root.CreateMessage;
const ListMessages = Root.ListMessages;
const ListReactions = Root.ListReactions;
const ListPollAnswerVoters = Root.ListPollAnswerVoters;
const ListArchivedThreads = Root.ListArchivedThreads;
const ListThreadMembers = Root.ListThreadMembers;

pub fn writeSnowflakeCommaList(ids: []const Snowflake, writer: anytype) !void {
    for (ids, 0..) |id, index| {
        if (index != 0) try writer.writeByte(',');
        try writer.print("{d}", .{id.value});
    }
}

pub fn writeOptionalStringField(writer: anytype, needs_comma: *bool, comptime field: []const u8, value: ?[]const u8) !void {
    if (value) |text| {
        try writeComma(writer, needs_comma);
        try writer.print("\"{s}\":", .{field});
        try Json.writeString(text, writer);
    }
}

pub fn writeNullableStringField(
    writer: anytype,
    needs_comma: *bool,
    comptime field: []const u8,
    value: ?[]const u8,
    clear: bool,
) !void {
    if (clear) {
        try writeComma(writer, needs_comma);
        try writer.print("\"{s}\":null", .{field});
    } else {
        try writeOptionalStringField(writer, needs_comma, field, value);
    }
}

pub fn writeNullableSnowflakeField(
    writer: anytype,
    needs_comma: *bool,
    comptime field: []const u8,
    value: ?Snowflake,
    clear: bool,
) !void {
    if (clear) {
        try writeComma(writer, needs_comma);
        try writer.print("\"{s}\":null", .{field});
    } else if (value) |snowflake| {
        try writeComma(writer, needs_comma);
        try writer.print("\"{s}\":\"{d}\"", .{ field, snowflake.value });
    }
}

pub fn writeOptionalIntegerField(writer: anytype, needs_comma: *bool, comptime field: []const u8, value: anytype) !void {
    if (value) |integer| {
        try writeComma(writer, needs_comma);
        try writer.print("\"{s}\":{d}", .{ field, integer });
    }
}

pub fn writeOptionalFloatField(writer: anytype, needs_comma: *bool, comptime field: []const u8, value: ?f64) !void {
    if (value) |float| {
        try writeComma(writer, needs_comma);
        try writer.print("\"{s}\":{d}", .{ field, float });
    }
}

pub fn writeOptionalBoolField(writer: anytype, needs_comma: *bool, comptime field: []const u8, value: ?bool) !void {
    if (value) |enabled| {
        try writeComma(writer, needs_comma);
        try writer.print("\"{s}\":", .{field});
        try writer.writeAll(if (enabled) "true" else "false");
    }
}

pub fn writeSnowflakeQueryParam(writer: anytype, needs_ampersand: *bool, comptime field: []const u8, value: Snowflake) !void {
    try writeQuerySeparator(writer, needs_ampersand);
    try writer.print("{s}={d}", .{ field, value.value });
}

pub fn writeStringQueryParam(writer: anytype, needs_ampersand: *bool, comptime field: []const u8, value: []const u8) !void {
    try writeQuerySeparator(writer, needs_ampersand);
    try writer.print("{s}=", .{field});
    try writeQueryStringValue(value, writer);
}

pub fn writeOptionalStringQueryParam(
    writer: anytype,
    needs_ampersand: *bool,
    comptime field: []const u8,
    value: ?[]const u8,
) !void {
    if (value) |present| try writeStringQueryParam(writer, needs_ampersand, field, present);
}

pub fn writeOptionalBoolQueryParam(writer: anytype, needs_ampersand: *bool, comptime field: []const u8, value: ?bool) !void {
    if (value) |enabled| {
        try writeQuerySeparator(writer, needs_ampersand);
        try writer.print("{s}=", .{field});
        try writer.writeAll(if (enabled) "true" else "false");
    }
}

pub fn writeQueryStringValue(value: []const u8, writer: anytype) !void {
    const hex = "0123456789ABCDEF";
    for (value) |byte| {
        const safe = (byte >= 'A' and byte <= 'Z') or
            (byte >= 'a' and byte <= 'z') or
            (byte >= '0' and byte <= '9') or
            byte == '-' or byte == '_' or byte == '.' or byte == '~';
        if (safe) {
            try writer.writeByte(byte);
        } else {
            try writer.writeByte('%');
            try writer.writeByte(hex[byte >> 4]);
            try writer.writeByte(hex[byte & 0x0f]);
        }
    }
}

pub fn writeQuerySeparator(writer: anytype, needs_ampersand: *bool) !void {
    if (needs_ampersand.*) try writer.writeByte('&');
    needs_ampersand.* = true;
}

pub fn writeComma(writer: anytype, needs_comma: *bool) !void {
    if (needs_comma.*) try writer.writeByte(',');
    needs_comma.* = true;
}

test "create message JSON escapes content" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try (CreateMessage{ .content = "hello \"zig\"" }).writeJson(&out.writer);
    try std.testing.expectEqualStrings("{\"content\":\"hello \\\"zig\\\"\"}", out.written());
}

test "list audit log query writes filters in stable order" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try ListAuditLog.init()
        .forUser(Snowflake.init(10))
        .withActionType(72)
        .beforeEntry(Snowflake.init(30))
        .afterEntry(Snowflake.init(20))
        .withLimit(50)
        .writeQuery(&out.writer);

    try std.testing.expectEqualStrings(
        "user_id=10&action_type=72&before=30&after=20&limit=50",
        out.written(),
    );
}

test "user and guild member display helpers prefer Discord display names" {
    const legacy_user = User{
        .id = Snowflake.init(10),
        .username = "zig",
        .discriminator = "1337",
        .global_name = "Zig Bot",
    };
    try std.testing.expectEqualStrings("Zig Bot", legacy_user.displayName());

    const legacy_tag = try legacy_user.tag(std.testing.allocator);
    defer std.testing.allocator.free(legacy_tag);
    try std.testing.expectEqualStrings("zig#1337", legacy_tag);

    const migrated_user = User{
        .id = Snowflake.init(11),
        .username = "baris",
        .discriminator = "0",
    };
    try std.testing.expectEqualStrings("baris", migrated_user.displayName());

    const migrated_tag = try migrated_user.tag(std.testing.allocator);
    defer std.testing.allocator.free(migrated_tag);
    try std.testing.expectEqualStrings("baris", migrated_tag);

    try std.testing.expectEqualStrings(
        "mod",
        (GuildMember{ .user = migrated_user, .nick = "mod" }).displayName().?,
    );
    try std.testing.expectEqualStrings("baris", (GuildMember{ .user = migrated_user }).displayName().?);
    try std.testing.expect((GuildMember{}).displayName() == null);
}

test "list current user guilds query writes pagination and counts" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try ListCurrentUserGuilds.init()
        .beforeGuild(Snowflake.init(30))
        .afterGuild(Snowflake.init(20))
        .withLimit(100)
        .withCounts(true)
        .writeQuery(&out.writer);

    try std.testing.expectEqualStrings(
        "before=30&after=20&limit=100&with_counts=true",
        out.written(),
    );
}

test "get guild query writes counts flag" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try GetGuild.init().withCounts(true).writeQuery(&out.writer);

    try std.testing.expectEqualStrings("with_counts=true", out.written());
}

test "list guild bans query writes pagination filters" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try ListGuildBans.init()
        .beforeUser(Snowflake.init(30))
        .afterUser(Snowflake.init(20))
        .withLimit(100)
        .writeQuery(&out.writer);

    try std.testing.expectEqualStrings("before=30&after=20&limit=100", out.written());
}

test "guild member queries write pagination and search filters" {
    var list = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer list.deinit();

    try ListGuildMembers.init()
        .withLimit(100)
        .afterMember(Snowflake.init(20))
        .writeQuery(&list.writer);
    try std.testing.expectEqualStrings("limit=100&after=20", list.written());

    var search = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer search.deinit();

    try SearchGuildMembers.init("baris dev")
        .withLimit(25)
        .writeQuery(&search.writer);
    try std.testing.expectEqualStrings("query=baris%20dev&limit=25", search.written());
}

test "guild prune query and JSON include days roles and count flag" {
    const roles = [_]Snowflake{ Snowflake.init(10), Snowflake.init(20) };

    var query = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer query.deinit();

    try GetGuildPruneCount.init()
        .withDays(14)
        .withRoles(&roles)
        .writeQuery(&query.writer);
    try std.testing.expectEqualStrings("days=14&include_roles=10,20", query.written());

    var body = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer body.deinit();

    try BeginGuildPrune.init()
        .withDays(14)
        .computeCount(false)
        .withRoles(&roles)
        .writeJson(&body.writer);
    try std.testing.expectEqualStrings(
        "{\"days\":14,\"compute_prune_count\":false,\"include_roles\":[\"10\",\"20\"]}",
        body.written(),
    );
}

test "guild scheduled event queries write counts users and pagination" {
    var list = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer list.deinit();

    try ListGuildScheduledEvents.init().withUserCount(true).writeQuery(&list.writer);
    try std.testing.expectEqualStrings("with_user_count=true", list.written());

    var get = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer get.deinit();

    try GetGuildScheduledEvent.init().withUserCount(false).writeQuery(&get.writer);
    try std.testing.expectEqualStrings("with_user_count=false", get.written());

    var users = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer users.deinit();

    try ListGuildScheduledEventUsers.init()
        .withLimit(50)
        .withMember(true)
        .beforeUser(Snowflake.init(30))
        .afterUser(Snowflake.init(20))
        .writeQuery(&users.writer);
    try std.testing.expectEqualStrings("limit=50&with_member=true&before=30&after=20", users.written());
}

test "guild scheduled event JSON supports create edit and null clears" {
    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();

    try CreateGuildScheduledEvent.init("Launch", "2026-06-02T10:00:00.000Z", .voice)
        .withChannel(Snowflake.init(20))
        .withDescription("Ship discord.zig")
        .writeJson(&create.writer);
    try std.testing.expectEqualStrings(
        "{\"channel_id\":\"20\",\"name\":\"Launch\",\"privacy_level\":2,\"scheduled_start_time\":\"2026-06-02T10:00:00.000Z\",\"description\":\"Ship discord.zig\",\"entity_type\":2}",
        create.written(),
    );

    var external = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer external.deinit();

    try CreateGuildScheduledEvent.init("Meetup", "2026-06-02T10:00:00.000Z", .external)
        .withMetadata(.{ .location = "Istanbul" })
        .withEndTime("2026-06-02T12:00:00.000Z")
        .writeJson(&external.writer);
    try std.testing.expectEqualStrings(
        "{\"entity_metadata\":{\"location\":\"Istanbul\"},\"name\":\"Meetup\",\"privacy_level\":2,\"scheduled_start_time\":\"2026-06-02T10:00:00.000Z\",\"scheduled_end_time\":\"2026-06-02T12:00:00.000Z\",\"entity_type\":3}",
        external.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    try EditGuildScheduledEvent.init()
        .clearChannel()
        .withMetadata(.{ .location = "Remote" })
        .withEntityType(.external)
        .withStatus(.active)
        .clearDescription()
        .writeJson(&edit.writer);
    try std.testing.expectEqualStrings(
        "{\"channel_id\":null,\"entity_metadata\":{\"location\":\"Remote\"},\"description\":null,\"entity_type\":3,\"status\":2}",
        edit.written(),
    );
}

test "stage instance JSON supports create and edit payloads" {
    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();

    try CreateStageInstance.init(Snowflake.init(20), "Live Q&A")
        .withPrivacyLevel(.guild_only)
        .sendStartNotification(true)
        .withScheduledEvent(Snowflake.init(30))
        .writeJson(&create.writer);
    try std.testing.expectEqualStrings(
        "{\"channel_id\":\"20\",\"topic\":\"Live Q&A\",\"privacy_level\":2,\"send_start_notification\":true,\"guild_scheduled_event_id\":\"30\"}",
        create.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    try EditStageInstance.init()
        .withTopic("Aftershow")
        .withPrivacyLevel(.guild_only)
        .writeJson(&edit.writer);
    try std.testing.expectEqualStrings(
        "{\"topic\":\"Aftershow\",\"privacy_level\":2}",
        edit.written(),
    );
}

test "voice state JSON supports current user and moderator updates" {
    var current = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer current.deinit();

    try EditCurrentUserVoiceState.init()
        .withChannel(Snowflake.init(20))
        .suppressState(false)
        .requestToSpeakAt("2026-06-02T10:00:00.000Z")
        .writeJson(&current.writer);
    try std.testing.expectEqualStrings(
        "{\"channel_id\":\"20\",\"suppress\":false,\"request_to_speak_timestamp\":\"2026-06-02T10:00:00.000Z\"}",
        current.written(),
    );

    var clear = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear.deinit();

    try EditCurrentUserVoiceState.init().clearRequestToSpeak().writeJson(&clear.writer);
    try std.testing.expectEqualStrings("{\"request_to_speak_timestamp\":null}", clear.written());

    var user = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer user.deinit();

    try EditUserVoiceState.init()
        .withChannel(Snowflake.init(20))
        .suppressState(true)
        .writeJson(&user.writer);
    try std.testing.expectEqualStrings("{\"channel_id\":\"20\",\"suppress\":true}", user.written());
}

test "application role connection JSON writes platform fields and metadata" {
    const metadata = [_]StringPair{
        .{ .key = "level", .value = "42" },
        .{ .key = "rank", .value = "diamond" },
    };

    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try UpdateApplicationRoleConnection.init()
        .withPlatformName("zig league")
        .withPlatformUsername("baris")
        .withMetadata(&metadata)
        .writeJson(&out.writer);
    try std.testing.expectEqualStrings(
        "{\"platform_name\":\"zig league\",\"platform_username\":\"baris\",\"metadata\":{\"level\":\"42\",\"rank\":\"diamond\"}}",
        out.written(),
    );
}

test "application role connection metadata records JSON writes array payload" {
    const name_localizations = [_]StringPair{
        .{ .key = "tr", .value = "Seviye" },
    };
    const description_localizations = [_]StringPair{
        .{ .key = "tr", .value = "Oyuncu seviyesi" },
    };
    const records = [_]ApplicationRoleConnectionMetadata{
        .{
            .type = .integer_greater_than_or_equal,
            .key = "level",
            .name = "Level",
            .name_localizations = &name_localizations,
            .description = "Player level",
            .description_localizations = &description_localizations,
        },
        .{
            .type = .boolean_equal,
            .key = "verified",
            .name = "Verified",
            .description = "Account verified",
        },
    };

    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try (UpdateApplicationRoleConnectionMetadataRecords{ .records = &records }).writeJson(&out.writer);
    try std.testing.expectEqualStrings(
        "[{\"type\":2,\"key\":\"level\",\"name\":\"Level\",\"name_localizations\":{\"tr\":\"Seviye\"},\"description\":\"Player level\",\"description_localizations\":{\"tr\":\"Oyuncu seviyesi\"}},{\"type\":7,\"key\":\"verified\",\"name\":\"Verified\",\"description\":\"Account verified\"}]",
        out.written(),
    );
}

test "current application JSON supports install params metadata and clears" {
    var install = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer install.deinit();

    try (ApplicationInstallParams{
        .scopes = &.{ "bot", "applications.commands" },
        .permissions = "2048",
    }).writeJson(&install.writer);
    try std.testing.expectEqualStrings(
        "{\"scopes\":[\"bot\",\"applications.commands\"],\"permissions\":\"2048\"}",
        install.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    try EditCurrentApplication.init()
        .withCustomInstallUrl("https://example.com/install")
        .withDescription("Fast Zig bot")
        .withInstallParams(.{
            .scopes = &.{ "bot", "applications.commands" },
            .permissions = "2048",
        })
        .withFlags(524288)
        .withTags(&.{ "zig", "bot" })
        .withEventWebhooksUrl("https://example.com/events")
        .withEventWebhooksStatus(.enabled)
        .withEventWebhookTypes(&.{ApplicationEventWebhookType.application_authorized.value()})
        .writeJson(&edit.writer);
    try std.testing.expectEqualStrings(
        "{\"custom_install_url\":\"https://example.com/install\",\"description\":\"Fast Zig bot\",\"install_params\":{\"scopes\":[\"bot\",\"applications.commands\"],\"permissions\":\"2048\"},\"flags\":524288,\"tags\":[\"zig\",\"bot\"],\"event_webhooks_url\":\"https://example.com/events\",\"event_webhooks_status\":2,\"event_webhooks_types\":[\"APPLICATION_AUTHORIZED\"]}",
        edit.written(),
    );

    var clear = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear.deinit();

    try EditCurrentApplication.init()
        .clearIcon()
        .clearCoverImage()
        .withInteractionsEndpointUrl("https://example.com/interactions")
        .writeJson(&clear.writer);
    try std.testing.expectEqualStrings(
        "{\"icon\":null,\"cover_image\":null,\"interactions_endpoint_url\":\"https://example.com/interactions\"}",
        clear.written(),
    );
}

test "application event webhook types expose documented values" {
    try std.testing.expectEqualStrings(
        "APPLICATION_AUTHORIZED",
        ApplicationEventWebhookType.application_authorized.value(),
    );
    try std.testing.expectEqualStrings(
        "APPLICATION_DEAUTHORIZED",
        ApplicationEventWebhookType.application_deauthorized.value(),
    );
    try std.testing.expectEqualStrings(
        "ENTITLEMENT_CREATE",
        ApplicationEventWebhookType.entitlement_create.value(),
    );
    try std.testing.expectEqualStrings(
        "LOBBY_MESSAGE_DELETE",
        ApplicationEventWebhookType.lobby_message_delete.value(),
    );
    try std.testing.expectEqual(
        ApplicationEventWebhookType.game_direct_message_update,
        ApplicationEventWebhookType.fromValue("GAME_DIRECT_MESSAGE_UPDATE").?,
    );
    try std.testing.expectEqual(null, ApplicationEventWebhookType.fromValue("UNKNOWN_EVENT"));

    const payload = ApplicationEventWebhookPayload{
        .version = 1,
        .application_id = Snowflake{ .value = 42 },
        .type = .event,
        .event = .{
            .type = .application_authorized,
            .timestamp = "2026-06-03T12:00:00.000000",
        },
    };
    try std.testing.expectEqual(ApplicationEventWebhookPayloadType.event, payload.type);
    try std.testing.expectEqual(ApplicationEventWebhookType.application_authorized, payload.event.?.type);
}

test "OAuth2 token forms percent encode fields" {
    var exchange = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer exchange.deinit();

    try OAuth2TokenRequest.authorizationCode("code value")
        .withRedirectUri("https://example.com/callback path")
        .withClientId("10")
        .withClientSecret("secret/value")
        .withScope("identify guilds.join")
        .withCodeVerifier("pkce verifier")
        .writeForm(&exchange.writer);
    try std.testing.expectEqualStrings(
        "grant_type=authorization_code&code=code%20value&redirect_uri=https%3A%2F%2Fexample.com%2Fcallback%20path&client_id=10&client_secret=secret%2Fvalue&scope=identify%20guilds.join&code_verifier=pkce%20verifier",
        exchange.written(),
    );

    var revoke = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer revoke.deinit();

    try OAuth2TokenRevocation.init("refresh token")
        .withTokenTypeHint("refresh_token")
        .withClientId("10")
        .writeForm(&revoke.writer);
    try std.testing.expectEqualStrings(
        "token=refresh%20token&token_type_hint=refresh_token&client_id=10",
        revoke.written(),
    );
}

test "monetization queries and test entitlement JSON" {
    var entitlements = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer entitlements.deinit();

    try ListEntitlements.init()
        .forUser(Snowflake.init(10))
        .withSkus(&.{ Snowflake.init(20), Snowflake.init(30) })
        .beforeEntitlement(Snowflake.init(40))
        .afterEntitlement(Snowflake.init(50))
        .withLimit(25)
        .forGuild(Snowflake.init(60))
        .excludeEnded(true)
        .excludeDeleted(false)
        .writeQuery(&entitlements.writer);
    try std.testing.expectEqualStrings(
        "user_id=10&sku_ids=20,30&before=40&after=50&limit=25&guild_id=60&exclude_ended=true&exclude_deleted=false",
        entitlements.written(),
    );

    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();

    try CreateTestEntitlement.init(Snowflake.init(20), Snowflake.init(30), .guild).writeJson(&create.writer);
    try std.testing.expectEqualStrings(
        "{\"sku_id\":\"20\",\"owner_id\":\"30\",\"owner_type\":1}",
        create.written(),
    );

    var subscriptions = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer subscriptions.deinit();

    try ListSkuSubscriptions.init()
        .beforeSubscription(Snowflake.init(10))
        .afterSubscription(Snowflake.init(20))
        .withLimit(50)
        .forUser(Snowflake.init(30))
        .writeQuery(&subscriptions.writer);
    try std.testing.expectEqualStrings(
        "before=10&after=20&limit=50&user_id=30",
        subscriptions.written(),
    );
}

test "list messages query writes snowflake filters and limit" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    var options = ListMessages.beforeMessage(Snowflake.init(20)).withLimit(50);
    options.after = Snowflake.init(10);
    try options.writeQuery(&out.writer);

    try std.testing.expectEqualStrings("before=20&after=10&limit=50", out.written());
}

test "list reactions query writes after and limit" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try ListReactions.afterUser(Snowflake.init(10))
        .withLimit(25)
        .withType(.burst)
        .writeQuery(&out.writer);
    try std.testing.expectEqualStrings("after=10&limit=25&type=1", out.written());
}

test "list poll answer voters query writes after and limit" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try ListPollAnswerVoters.afterUser(Snowflake.init(10))
        .withLimit(25)
        .writeQuery(&out.writer);

    try std.testing.expectEqualStrings("after=10&limit=25", out.written());
}

test "list archived threads query percent encodes timestamp" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try ListArchivedThreads.beforeTimestamp("2026-06-02T10:00:00.000Z")
        .withLimit(50)
        .writeQuery(&out.writer);

    try std.testing.expectEqualStrings("before=2026-06-02T10%3A00%3A00.000Z&limit=50", out.written());
}

test "list thread members query writes pagination and member expansion" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try ListThreadMembers.init()
        .withMemberExpansion(true)
        .afterMember(Snowflake.init(10))
        .withLimit(100)
        .writeQuery(&out.writer);

    try std.testing.expectEqualStrings("with_member=true&after=10&limit=100", out.written());
}
