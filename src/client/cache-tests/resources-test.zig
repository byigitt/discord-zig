const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Types = @import("../../models/types.zig");
const Gateway = @import("../../gateway/protocol.zig");

const Root = @import("../cache.zig");
const Cache = Root.Cache;
const roleKey = Root.roleKey;

test "cache handles guild update and delete dispatches" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var create = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"GUILD_CREATE\",\"d\":{\"id\":\"10\",\"name\":\"Guild\",\"channels\":[{\"id\":\"20\",\"type\":0,\"guild_id\":\"10\",\"name\":\"general\"}],\"members\":[{\"user\":{\"id\":\"30\",\"username\":\"member\"},\"roles\":[]}],\"roles\":[{\"id\":\"40\",\"name\":\"Helper\",\"permissions\":\"0\"}],\"stickers\":[{\"id\":\"50\",\"name\":\"zig\",\"description\":\"mascot\",\"tags\":\"zig\",\"type\":2,\"format_type\":1,\"guild_id\":\"10\"}],\"guild_scheduled_events\":[{\"id\":\"60\",\"guild_id\":\"10\",\"channel_id\":\"20\",\"name\":\"Launch\",\"scheduled_start_time\":\"2026-06-02T10:00:00.000Z\",\"privacy_level\":2,\"status\":1,\"entity_type\":2}]}}",
    );
    defer create.deinit();
    try cache.applyDispatch(create);

    const author = Types.User{ .id = Snowflake.init(30), .username = "member" };
    try cache.putMessage(.{ .id = Snowflake.init(70), .channel_id = Snowflake.init(20), .guild_id = Snowflake.init(10), .author = author, .content = "cached channel" });
    try cache.putMessage(.{ .id = Snowflake.init(71), .channel_id = Snowflake.init(21), .guild_id = Snowflake.init(10), .author = author, .content = "uncached channel" });
    try cache.putMessage(.{ .id = Snowflake.init(72), .channel_id = Snowflake.init(22), .author = author, .content = "dm" });

    var update = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"GUILD_UPDATE\",\"d\":{\"id\":\"10\",\"name\":\"Renamed\",\"icon\":\"renamed_icon\",\"banner\":\"renamed_banner\",\"owner_id\":\"99\",\"description\":null,\"afk_channel_id\":null,\"afk_timeout\":60,\"system_channel_id\":null,\"rules_channel_id\":null,\"public_updates_channel_id\":null,\"safety_alerts_channel_id\":null,\"features\":[\"COMMUNITY\"],\"preferred_locale\":\"tr\",\"verification_level\":1,\"default_message_notifications\":0,\"explicit_content_filter\":2,\"mfa_level\":0,\"nsfw_level\":1,\"max_presences\":2000,\"max_members\":6000,\"premium_tier\":2,\"premium_subscription_count\":5,\"premium_progress_bar_enabled\":false,\"approximate_member_count\":90,\"approximate_presence_count\":20}}",
    );
    defer update.deinit();
    try cache.applyDispatch(update);

    const renamed = cache.getGuild(Snowflake.init(10)).?;
    try std.testing.expectEqualStrings("Renamed", renamed.name);
    try std.testing.expectEqualStrings("renamed_icon", renamed.icon.?);
    try std.testing.expectEqualStrings("renamed_banner", renamed.banner.?);
    try std.testing.expect(renamed.description == null);
    try std.testing.expect(renamed.afk_channel_id == null);
    try std.testing.expectEqual(@as(u32, 60), renamed.afk_timeout.?);
    try std.testing.expect(renamed.system_channel_id == null);
    try std.testing.expect(renamed.rules_channel_id == null);
    try std.testing.expect(renamed.public_updates_channel_id == null);
    try std.testing.expect(renamed.safety_alerts_channel_id == null);
    try std.testing.expectEqual(@as(usize, 1), renamed.features.len);
    try std.testing.expectEqualStrings("COMMUNITY", renamed.features[0]);
    try std.testing.expectEqualStrings("tr", renamed.preferred_locale.?);
    try std.testing.expectEqual(@as(u8, 1), renamed.verification_level.?);
    try std.testing.expectEqual(@as(u8, 0), renamed.default_message_notifications.?);
    try std.testing.expectEqual(@as(u8, 2), renamed.explicit_content_filter.?);
    try std.testing.expectEqual(@as(u8, 0), renamed.mfa_level.?);
    try std.testing.expectEqual(@as(u8, 1), renamed.nsfw_level.?);
    try std.testing.expectEqual(@as(u32, 2000), renamed.max_presences.?);
    try std.testing.expectEqual(@as(u32, 6000), renamed.max_members.?);
    try std.testing.expectEqual(@as(u8, 2), renamed.premium_tier.?);
    try std.testing.expectEqual(@as(u32, 5), renamed.premium_subscription_count.?);
    try std.testing.expect(!renamed.premium_progress_bar_enabled.?);
    try std.testing.expectEqual(@as(u32, 90), renamed.approximate_member_count.?);
    try std.testing.expectEqual(@as(u32, 20), renamed.approximate_presence_count.?);

    var unavailable = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"GUILD_DELETE\",\"d\":{\"id\":\"10\",\"unavailable\":true}}",
    );
    defer unavailable.deinit();
    try cache.applyDispatch(unavailable);

    try std.testing.expect(cache.getGuild(Snowflake.init(10)) != null);
    try std.testing.expect(cache.getChannel(Snowflake.init(20)) != null);
    try std.testing.expect(cache.getMember(Snowflake.init(10), Snowflake.init(30)) != null);
    try std.testing.expect(cache.getRole(Snowflake.init(10), Snowflake.init(40)) != null);
    try std.testing.expect(cache.getSticker(Snowflake.init(10), Snowflake.init(50)) != null);
    try std.testing.expect(cache.getScheduledEvent(Snowflake.init(10), Snowflake.init(60)) != null);
    try std.testing.expect(cache.getMessage(Snowflake.init(70)) != null);

    var delete = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":4,\"t\":\"GUILD_DELETE\",\"d\":{\"id\":\"10\",\"unavailable\":false}}",
    );
    defer delete.deinit();
    try cache.applyDispatch(delete);

    try std.testing.expect(cache.getGuild(Snowflake.init(10)) == null);
    try std.testing.expect(cache.getChannel(Snowflake.init(20)) == null);
    try std.testing.expect(cache.getMember(Snowflake.init(10), Snowflake.init(30)) == null);
    try std.testing.expect(cache.getRole(Snowflake.init(10), Snowflake.init(40)) == null);
    try std.testing.expect(cache.getSticker(Snowflake.init(10), Snowflake.init(50)) == null);
    try std.testing.expect(cache.getScheduledEvent(Snowflake.init(10), Snowflake.init(60)) == null);
    try std.testing.expect(cache.getMessage(Snowflake.init(70)) == null);
    try std.testing.expect(cache.getMessage(Snowflake.init(71)) == null);
    try std.testing.expect(cache.getMessage(Snowflake.init(72)) != null);
    try std.testing.expectEqual(@as(usize, 1), cache.messageCount());
}

test "cache handles guild role create update and delete dispatches" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var create = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"GUILD_ROLE_CREATE\",\"d\":{\"guild_id\":\"10\",\"role\":{\"id\":\"40\",\"name\":\"Helper\",\"color\":1,\"colors\":{\"primary_color\":5793266,\"secondary_color\":15030514,\"tertiary_color\":null},\"hoist\":false,\"icon\":\"role_icon\",\"unicode_emoji\":\"⚡\",\"position\":3,\"permissions\":\"8\",\"managed\":true,\"mentionable\":false,\"tags\":{\"bot_id\":\"50\",\"integration_id\":\"60\",\"premium_subscriber\":null,\"subscription_listing_id\":\"70\",\"available_for_purchase\":null,\"guild_connections\":null},\"flags\":2}}}",
    );
    defer create.deinit();
    try cache.applyDispatch(create);

    const created = cache.getRole(Snowflake.init(10), Snowflake.init(40)).?;
    try std.testing.expectEqualStrings("Helper", created.name);
    try std.testing.expectEqual(@as(u24, 5793266), created.colors.?.primary_color);
    try std.testing.expectEqual(@as(u24, 0xE558F2), created.colors.?.secondary_color.?);
    try std.testing.expect(created.colors.?.tertiary_color == null);
    try std.testing.expectEqualStrings("role_icon", created.icon.?);
    try std.testing.expectEqualStrings("⚡", created.unicode_emoji.?);
    try std.testing.expectEqual(@as(i32, 3), created.position);
    try std.testing.expect(created.managed);
    try std.testing.expectEqual(@as(u64, 50), created.tags.?.bot_id.?.value);
    try std.testing.expectEqual(@as(u64, 60), created.tags.?.integration_id.?.value);
    try std.testing.expect(created.tags.?.premium_subscriber);
    try std.testing.expectEqual(@as(u64, 70), created.tags.?.subscription_listing_id.?.value);
    try std.testing.expect(created.tags.?.available_for_purchase);
    try std.testing.expect(created.tags.?.guild_connections);
    try std.testing.expectEqual(@as(u64, 2), created.flags.?);

    var update = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"GUILD_ROLE_UPDATE\",\"d\":{\"guild_id\":\"10\",\"role\":{\"id\":\"40\",\"name\":\"Admin\",\"color\":2,\"colors\":{\"primary_color\":11127295,\"secondary_color\":16759788,\"tertiary_color\":16761760},\"hoist\":true,\"icon\":null,\"unicode_emoji\":null,\"position\":4,\"permissions\":\"16\",\"managed\":false,\"mentionable\":true,\"tags\":{},\"flags\":4}}}",
    );
    defer update.deinit();
    try cache.applyDispatch(update);

    const updated = cache.getRole(Snowflake.init(10), Snowflake.init(40)).?;
    try std.testing.expectEqualStrings("Admin", updated.name);
    try std.testing.expectEqual(@as(u24, 11127295), updated.colors.?.primary_color);
    try std.testing.expectEqual(@as(u24, 16759788), updated.colors.?.secondary_color.?);
    try std.testing.expectEqual(@as(u24, 16761760), updated.colors.?.tertiary_color.?);
    try std.testing.expectEqual(@as(u64, 16), updated.permissions);
    try std.testing.expect(updated.icon == null);
    try std.testing.expect(updated.unicode_emoji == null);
    try std.testing.expectEqual(@as(i32, 4), updated.position);
    try std.testing.expect(!updated.managed);
    try std.testing.expect(updated.mentionable);
    try std.testing.expect(updated.tags.?.bot_id == null);
    try std.testing.expect(!updated.tags.?.premium_subscriber);
    try std.testing.expectEqual(@as(u64, 4), updated.flags.?);

    try cache.putMember(Snowflake.init(10), .{
        .user = .{ .id = Snowflake.init(30), .username = "member" },
        .roles = &.{ Snowflake.init(40), Snowflake.init(41) },
    });

    var delete = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"GUILD_ROLE_DELETE\",\"d\":{\"guild_id\":\"10\",\"role_id\":\"40\"}}",
    );
    defer delete.deinit();
    try cache.applyDispatch(delete);

    try std.testing.expect(cache.getRole(Snowflake.init(10), Snowflake.init(40)) == null);
    const member = cache.getMember(Snowflake.init(10), Snowflake.init(30)).?;
    try std.testing.expectEqual(@as(usize, 1), member.roles.len);
    try std.testing.expectEqual(@as(u64, 41), member.roles[0].value);
}

test "cache handles guild emojis update dispatch" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var first = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"GUILD_EMOJIS_UPDATE\",\"d\":{\"guild_id\":\"10\",\"emojis\":[{\"id\":\"20\",\"name\":\"zig\",\"roles\":[\"30\"],\"user\":{\"id\":\"40\",\"username\":\"artist\"},\"require_colons\":true,\"managed\":false,\"animated\":true,\"available\":true}]}}",
    );
    defer first.deinit();
    try cache.applyDispatch(first);

    const emoji = cache.getEmoji(Snowflake.init(10), Snowflake.init(20)).?;
    try std.testing.expectEqualStrings("zig", emoji.name.?);
    try std.testing.expectEqual(@as(u64, 30), emoji.roles[0].value);
    try std.testing.expectEqualStrings("artist", emoji.user.?.username);
    try std.testing.expect(emoji.require_colons);
    try std.testing.expect(emoji.animated);

    var second = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"GUILD_EMOJIS_UPDATE\",\"d\":{\"guild_id\":\"10\",\"emojis\":[]}}",
    );
    defer second.deinit();
    try cache.applyDispatch(second);

    try std.testing.expect(cache.getEmoji(Snowflake.init(10), Snowflake.init(20)) == null);
}

test "cache handles guild stickers update dispatch" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var first = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"GUILD_STICKERS_UPDATE\",\"d\":{\"guild_id\":\"10\",\"stickers\":[{\"id\":\"20\",\"name\":\"zig\",\"description\":\"mascot\",\"tags\":\"zig,lang\",\"type\":2,\"format_type\":1,\"available\":true,\"guild_id\":\"10\",\"user\":{\"id\":\"40\",\"username\":\"artist\"},\"sort_value\":3}]}}",
    );
    defer first.deinit();
    try cache.applyDispatch(first);

    const sticker = cache.getSticker(Snowflake.init(10), Snowflake.init(20)).?;
    try std.testing.expectEqualStrings("zig", sticker.name);
    try std.testing.expectEqualStrings("mascot", sticker.description.?);
    try std.testing.expectEqualStrings("zig,lang", sticker.tags);
    try std.testing.expectEqual(Types.StickerType.guild, sticker.type);
    try std.testing.expectEqual(Types.StickerFormatType.png, sticker.format_type);
    try std.testing.expectEqualStrings("artist", sticker.user.?.username);
    try std.testing.expectEqual(@as(u32, 3), sticker.sort_value.?);

    var second = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"GUILD_STICKERS_UPDATE\",\"d\":{\"guild_id\":\"10\",\"stickers\":[]}}",
    );
    defer second.deinit();
    try cache.applyDispatch(second);

    try std.testing.expect(cache.getSticker(Snowflake.init(10), Snowflake.init(20)) == null);
}

test "cache handles guild scheduled event create update and delete dispatches" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var create = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"GUILD_SCHEDULED_EVENT_CREATE\",\"d\":{\"id\":\"20\",\"guild_id\":\"10\",\"channel_id\":\"30\",\"creator_id\":\"40\",\"name\":\"Launch\",\"description\":\"Ship discord.zig\",\"scheduled_start_time\":\"2026-06-02T10:00:00.000Z\",\"scheduled_end_time\":\"2026-06-02T12:00:00.000Z\",\"privacy_level\":2,\"status\":1,\"entity_type\":2,\"entity_id\":null,\"user_count\":5}}",
    );
    defer create.deinit();
    try cache.applyDispatch(create);

    const created = cache.getScheduledEvent(Snowflake.init(10), Snowflake.init(20)).?;
    try std.testing.expectEqualStrings("Launch", created.name);
    try std.testing.expectEqualStrings("Ship discord.zig", created.description.?);
    try std.testing.expectEqual(@as(u64, 30), created.channel_id.?.value);
    try std.testing.expectEqual(Types.GuildScheduledEventStatus.scheduled, created.status);
    try std.testing.expectEqual(Types.GuildScheduledEventEntityType.voice, created.entity_type);
    try std.testing.expectEqual(@as(u32, 5), created.user_count.?);

    var update = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"GUILD_SCHEDULED_EVENT_UPDATE\",\"d\":{\"id\":\"20\",\"guild_id\":\"10\",\"channel_id\":null,\"creator_id\":\"40\",\"name\":\"Meetup\",\"description\":null,\"scheduled_start_time\":\"2026-06-02T13:00:00.000Z\",\"scheduled_end_time\":null,\"privacy_level\":2,\"status\":2,\"entity_type\":3,\"entity_id\":\"50\",\"user_count\":7}}",
    );
    defer update.deinit();
    try cache.applyDispatch(update);

    const updated = cache.getScheduledEvent(Snowflake.init(10), Snowflake.init(20)).?;
    try std.testing.expectEqualStrings("Meetup", updated.name);
    try std.testing.expect(updated.description == null);
    try std.testing.expect(updated.channel_id == null);
    try std.testing.expectEqual(Types.GuildScheduledEventStatus.active, updated.status);
    try std.testing.expectEqual(Types.GuildScheduledEventEntityType.external, updated.entity_type);
    try std.testing.expectEqual(@as(u64, 50), updated.entity_id.?.value);
    try std.testing.expectEqual(@as(u32, 7), updated.user_count.?);

    var user_add = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"GUILD_SCHEDULED_EVENT_USER_ADD\",\"d\":{\"guild_scheduled_event_id\":\"20\",\"user_id\":\"70\",\"guild_id\":\"10\"}}",
    );
    defer user_add.deinit();
    try cache.applyDispatch(user_add);

    try std.testing.expectEqual(@as(u32, 8), cache.getScheduledEvent(Snowflake.init(10), Snowflake.init(20)).?.user_count.?);

    var user_remove = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":4,\"t\":\"GUILD_SCHEDULED_EVENT_USER_REMOVE\",\"d\":{\"guild_scheduled_event_id\":\"20\",\"user_id\":\"70\",\"guild_id\":\"10\"}}",
    );
    defer user_remove.deinit();
    try cache.applyDispatch(user_remove);

    try std.testing.expectEqual(@as(u32, 7), cache.getScheduledEvent(Snowflake.init(10), Snowflake.init(20)).?.user_count.?);

    try cache.putScheduledEvent(.{
        .id = Snowflake.init(21),
        .guild_id = Snowflake.init(10),
        .name = "Unknown count",
        .scheduled_start_time = "2026-06-02T15:00:00.000Z",
        .privacy_level = .guild_only,
        .status = .scheduled,
        .entity_type = .external,
    });

    var unknown_count_add = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":5,\"t\":\"GUILD_SCHEDULED_EVENT_USER_ADD\",\"d\":{\"guild_scheduled_event_id\":\"21\",\"user_id\":\"71\",\"guild_id\":\"10\"}}",
    );
    defer unknown_count_add.deinit();
    try cache.applyDispatch(unknown_count_add);

    try std.testing.expect(cache.getScheduledEvent(Snowflake.init(10), Snowflake.init(21)).?.user_count == null);

    var zero_count_remove = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":6,\"t\":\"GUILD_SCHEDULED_EVENT_USER_REMOVE\",\"d\":{\"guild_scheduled_event_id\":\"20\",\"user_id\":\"72\",\"guild_id\":\"10\"}}",
    );
    defer zero_count_remove.deinit();
    cache.scheduled_events.getPtr(roleKey(Snowflake.init(10), Snowflake.init(20))).?.user_count = 0;
    try cache.applyDispatch(zero_count_remove);

    try std.testing.expectEqual(@as(u32, 0), cache.getScheduledEvent(Snowflake.init(10), Snowflake.init(20)).?.user_count.?);

    var delete = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":7,\"t\":\"GUILD_SCHEDULED_EVENT_DELETE\",\"d\":{\"id\":\"20\",\"guild_id\":\"10\",\"channel_id\":null,\"creator_id\":\"40\",\"name\":\"Meetup\",\"description\":null,\"scheduled_start_time\":\"2026-06-02T13:00:00.000Z\",\"scheduled_end_time\":null,\"privacy_level\":2,\"status\":4,\"entity_type\":3,\"entity_id\":\"50\"}}",
    );
    defer delete.deinit();
    try cache.applyDispatch(delete);

    try std.testing.expect(cache.getScheduledEvent(Snowflake.init(10), Snowflake.init(20)) == null);
}

test "cache handles stage instance create update and delete dispatches" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var create = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"STAGE_INSTANCE_CREATE\",\"d\":{\"id\":\"20\",\"guild_id\":\"10\",\"channel_id\":\"30\",\"topic\":\"Live Q&A\",\"privacy_level\":2,\"discoverable_disabled\":true,\"guild_scheduled_event_id\":\"40\"}}",
    );
    defer create.deinit();
    try cache.applyDispatch(create);

    const created = cache.getStageInstance(Snowflake.init(10), Snowflake.init(20)).?;
    try std.testing.expectEqualStrings("Live Q&A", created.topic);
    try std.testing.expectEqual(@as(u64, 30), created.channel_id.value);
    try std.testing.expectEqual(Types.StageInstancePrivacyLevel.guild_only, created.privacy_level);
    try std.testing.expect(created.discoverable_disabled);
    try std.testing.expectEqual(@as(u64, 40), created.guild_scheduled_event_id.?.value);

    var update = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"STAGE_INSTANCE_UPDATE\",\"d\":{\"id\":\"20\",\"guild_id\":\"10\",\"channel_id\":\"30\",\"topic\":\"Aftershow\",\"privacy_level\":1,\"discoverable_disabled\":false,\"guild_scheduled_event_id\":null}}",
    );
    defer update.deinit();
    try cache.applyDispatch(update);

    const updated = cache.getStageInstance(Snowflake.init(10), Snowflake.init(20)).?;
    try std.testing.expectEqualStrings("Aftershow", updated.topic);
    try std.testing.expectEqual(Types.StageInstancePrivacyLevel.public, updated.privacy_level);
    try std.testing.expect(!updated.discoverable_disabled);
    try std.testing.expect(updated.guild_scheduled_event_id == null);

    var delete = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"STAGE_INSTANCE_DELETE\",\"d\":{\"id\":\"20\",\"guild_id\":\"10\",\"channel_id\":\"30\",\"topic\":\"Aftershow\",\"privacy_level\":1,\"discoverable_disabled\":false,\"guild_scheduled_event_id\":null}}",
    );
    defer delete.deinit();
    try cache.applyDispatch(delete);

    try std.testing.expect(cache.getStageInstance(Snowflake.init(10), Snowflake.init(20)) == null);
}
