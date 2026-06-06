const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Types = @import("../../models/types.zig");
const Gateway = @import("../../gateway/protocol.zig");
const Interactions = @import("../../interactions/mod.zig");

const Root = @import("../cache.zig");
const Cache = Root.Cache;

test "cache updates and deletes message dispatches" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var create = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"MESSAGE_CREATE\",\"d\":{\"id\":\"10\",\"channel_id\":\"20\",\"guild_id\":\"30\",\"message_reference\":{\"message_id\":\"8\",\"channel_id\":\"20\",\"guild_id\":\"30\"},\"referenced_message\":{\"id\":\"8\",\"channel_id\":\"20\",\"content\":\"source\",\"author\":{\"id\":\"40\",\"username\":\"bot\"}},\"thread\":{\"id\":\"47\",\"guild_id\":\"30\",\"type\":11,\"name\":\"original-thread\",\"parent_id\":\"20\"},\"type\":0,\"content\":\"pong\",\"timestamp\":\"2026-06-02T00:00:00.000000+00:00\",\"edited_timestamp\":null,\"tts\":false,\"mention_everyone\":false,\"pinned\":false,\"flags\":0,\"author\":{\"id\":\"40\",\"username\":\"bot\",\"bot\":true},\"mentions\":[{\"id\":\"41\",\"username\":\"alice\"}],\"mention_roles\":[\"42\"],\"mention_channels\":[{\"id\":\"43\",\"guild_id\":\"30\",\"type\":0,\"name\":\"general\"}],\"embeds\":[{\"title\":\"Original\"}],\"attachments\":[{\"id\":\"50\",\"filename\":\"report.txt\",\"content_type\":\"text/plain\",\"size\":12,\"url\":\"https://cdn.example/report.txt\",\"proxy_url\":\"https://proxy.example/report.txt\"}],\"sticker_items\":[{\"id\":\"60\",\"name\":\"ziggy\",\"format_type\":1}],\"components\":[{\"type\":1,\"components\":[{\"type\":2,\"style\":1,\"custom_id\":\"confirm\",\"label\":\"Confirm\"}]}],\"reactions\":[{\"count\":1,\"emoji\":{\"id\":null,\"name\":\"👍\"}}]}}",
    );
    defer create.deinit();
    try cache.applyDispatch(create);

    var update = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"MESSAGE_UPDATE\",\"d\":{\"id\":\"10\",\"channel_id\":\"20\",\"message_reference\":{\"message_id\":\"9\",\"channel_id\":\"20\",\"guild_id\":\"30\"},\"referenced_message\":null,\"thread\":{\"id\":\"48\",\"guild_id\":\"30\",\"type\":12,\"name\":\"edited-thread\",\"parent_id\":\"20\",\"rate_limit_per_user\":10},\"call\":{\"participants\":[\"40\"],\"ended_timestamp\":\"2026-06-02T01:30:00.000Z\"},\"role_subscription_data\":{\"role_subscription_listing_id\":\"73\",\"tier_name\":\"Supporter\",\"total_months_subscribed\":15,\"is_renewal\":false},\"shared_client_theme\":{\"colors\":[\"111111\"],\"gradient_angle\":90,\"base_mix\":40,\"base_theme\":2},\"application_id\":\"81\",\"application\":{\"id\":\"81\",\"name\":\"updated app\",\"description\":\"updated message app\",\"bot\":{\"id\":\"94\",\"username\":\"updated_app_bot\"},\"event_webhooks_types\":[],\"tags\":[\"updated\"]},\"activity\":null,\"interaction_metadata\":{\"id\":\"85\",\"type\":3,\"user\":{\"id\":\"86\",\"username\":\"clicker\"},\"original_response_message_id\":\"10\",\"interacted_message_id\":\"87\"},\"type\":19,\"nonce\":987654321,\"content\":\"edited\",\"edited_timestamp\":\"2026-06-02T01:00:00.000000+00:00\",\"tts\":true,\"mention_everyone\":true,\"pinned\":true,\"position\":6,\"flags\":4,\"member\":{\"nick\":\"edited nick\",\"roles\":[\"45\"],\"joined_at\":\"2026-06-01T00:00:00.000Z\",\"deaf\":true,\"mute\":false,\"flags\":2,\"permissions\":4096},\"mentions\":[{\"id\":\"44\",\"username\":\"bob\"}],\"mention_roles\":[\"45\"],\"mention_channels\":[{\"id\":\"46\",\"guild_id\":\"30\",\"type\":0,\"name\":\"updates\"}],\"embeds\":[{\"title\":\"Edited\",\"fields\":[{\"name\":\"State\",\"value\":\"done\"}]}],\"attachments\":[{\"id\":\"51\",\"filename\":\"edited.png\",\"content_type\":\"image/png\",\"size\":20,\"url\":\"https://cdn.example/edited.png\",\"proxy_url\":\"https://proxy.example/edited.png\",\"height\":64,\"width\":128}],\"sticker_items\":[{\"id\":\"61\",\"name\":\"updated\",\"format_type\":4}],\"stickers\":[{\"id\":\"92\",\"name\":\"updated_full\",\"description\":null,\"tags\":\"ship\",\"type\":2,\"format_type\":4,\"available\":false,\"guild_id\":\"30\"}],\"components\":[{\"type\":1,\"components\":[{\"type\":3,\"custom_id\":\"choice\",\"placeholder\":\"Pick\",\"min_values\":1,\"max_values\":1,\"options\":[{\"label\":\"One\",\"value\":\"1\",\"description\":\"First\",\"default\":true}]}]},{\"type\":1,\"components\":[{\"type\":5,\"custom_id\":\"users\",\"placeholder\":\"Pick users\",\"min_values\":1,\"max_values\":2}]},{\"type\":1,\"components\":[{\"type\":6,\"custom_id\":\"roles\",\"disabled\":true}]},{\"type\":1,\"components\":[{\"type\":7,\"custom_id\":\"mentionables\"}]},{\"type\":1,\"components\":[{\"type\":8,\"custom_id\":\"channels\",\"channel_types\":[0,11]}]}],\"poll\":{\"question\":{\"text\":\"Edited poll\"},\"answers\":[],\"expiry\":null,\"allow_multiselect\":false,\"layout_type\":1,\"results\":{\"is_finalized\":true,\"answer_counts\":[]}}}}",
    );
    defer update.deinit();
    try cache.applyDispatch(update);

    const updated = cache.getMessage(Snowflake.init(10)).?;
    try std.testing.expectEqualStrings("edited", updated.content);
    try std.testing.expectEqual(@as(u64, 9), updated.message_reference.?.message_id.?.value);
    try std.testing.expect(updated.referenced_message_id == null);
    try std.testing.expectEqual(@as(u64, 48), updated.thread.?.id.value);
    try std.testing.expectEqual(Types.ChannelType.private_thread, updated.thread.?.type);
    try std.testing.expectEqualStrings("edited-thread", updated.thread.?.name.?);
    try std.testing.expectEqual(@as(u16, 10), updated.thread.?.rate_limit_per_user.?);
    try std.testing.expectEqualStrings("edited-thread", cache.getChannel(Snowflake.init(48)).?.name.?);
    try std.testing.expectEqual(@as(usize, 1), updated.call.?.participants.len);
    try std.testing.expectEqual(@as(u64, 40), updated.call.?.participants[0].value);
    try std.testing.expectEqualStrings("2026-06-02T01:30:00.000Z", updated.call.?.ended_timestamp.?);
    try std.testing.expectEqual(@as(u64, 73), updated.role_subscription_data.?.role_subscription_listing_id.value);
    try std.testing.expectEqualStrings("Supporter", updated.role_subscription_data.?.tier_name);
    try std.testing.expectEqual(@as(u32, 15), updated.role_subscription_data.?.total_months_subscribed);
    try std.testing.expect(!updated.role_subscription_data.?.is_renewal);
    try std.testing.expectEqual(@as(usize, 1), updated.shared_client_theme.?.colors.len);
    try std.testing.expectEqualStrings("111111", updated.shared_client_theme.?.colors[0]);
    try std.testing.expectEqual(@as(u16, 90), updated.shared_client_theme.?.gradient_angle);
    try std.testing.expectEqual(@as(u8, 40), updated.shared_client_theme.?.base_mix);
    try std.testing.expectEqual(Types.SharedClientThemeBase.light, updated.shared_client_theme.?.base_theme.?);
    try std.testing.expectEqual(@as(u64, 81), updated.application_id.?.value);
    try std.testing.expectEqualStrings("updated app", updated.application.?.name);
    try std.testing.expectEqualStrings("updated message app", updated.application.?.description);
    try std.testing.expectEqualStrings("updated_app_bot", updated.application.?.bot.?.username);
    try std.testing.expectEqual(@as(usize, 0), updated.application.?.event_webhooks_types.len);
    try std.testing.expectEqualStrings("updated", updated.application.?.tags[0]);
    try std.testing.expectEqualStrings("updated_app_bot", cache.getUser(Snowflake.init(94)).?.username);
    try std.testing.expect(updated.activity == null);
    try std.testing.expectEqual(@as(u64, 85), updated.interaction_metadata.?.id.value);
    try std.testing.expectEqual(Interactions.InteractionType.message_component, updated.interaction_metadata.?.type);
    try std.testing.expectEqualStrings("clicker", updated.interaction_metadata.?.user.username);
    try std.testing.expectEqual(@as(u64, 87), updated.interaction_metadata.?.interacted_message_id.?.value);
    try std.testing.expectEqualStrings("clicker", cache.getUser(Snowflake.init(86)).?.username);
    try std.testing.expectEqual(@as(u8, 19), updated.type);
    try std.testing.expectEqualStrings("987654321", updated.nonce.?);
    try std.testing.expectEqualStrings("2026-06-02T01:00:00.000000+00:00", updated.edited_timestamp.?);
    try std.testing.expect(updated.tts);
    try std.testing.expect(updated.mention_everyone);
    try std.testing.expect(updated.pinned);
    try std.testing.expectEqual(@as(i32, 6), updated.position.?);
    try std.testing.expectEqual(@as(u32, 4), updated.flags.?);
    try std.testing.expectEqualStrings("bob", updated.mentions[0].username);
    try std.testing.expectEqual(@as(u64, 45), updated.mention_roles[0].value);
    try std.testing.expectEqualStrings("updates", updated.mention_channels[0].name.?);
    try std.testing.expectEqual(@as(usize, 1), updated.embeds.len);
    try std.testing.expectEqualStrings("Edited", updated.embeds[0].title.?);
    try std.testing.expectEqualStrings("State", updated.embeds[0].fields[0].name);
    try std.testing.expectEqualStrings("done", updated.embeds[0].fields[0].value);
    try std.testing.expectEqualStrings("bot", updated.author.?.username);
    try std.testing.expectEqualStrings("edited nick", updated.member.?.nick.?);
    try std.testing.expectEqualStrings("bot", updated.member.?.user.?.username);
    try std.testing.expectEqual(@as(u64, 45), updated.member.?.roles[0].value);
    try std.testing.expect(updated.member.?.deaf);
    try std.testing.expect(!updated.member.?.mute);
    try std.testing.expectEqual(@as(u64, 2), updated.member.?.flags);
    try std.testing.expectEqual(@as(u64, 4096), updated.member.?.permissions);
    try std.testing.expectEqualStrings("edited nick", cache.getMember(Snowflake.init(30), Snowflake.init(40)).?.nick.?);
    try std.testing.expectEqual(@as(usize, 1), updated.attachments.len);
    try std.testing.expectEqual(@as(u64, 51), updated.attachments[0].id.value);
    try std.testing.expectEqualStrings("edited.png", updated.attachments[0].filename);
    try std.testing.expectEqualStrings("image/png", updated.attachments[0].content_type.?);
    try std.testing.expectEqual(@as(u32, 64), updated.attachments[0].height.?);
    try std.testing.expectEqual(@as(u32, 128), updated.attachments[0].width.?);
    try std.testing.expectEqual(@as(usize, 1), updated.sticker_items.len);
    try std.testing.expectEqualStrings("updated", updated.sticker_items[0].name);
    try std.testing.expectEqual(Types.StickerFormatType.gif, updated.sticker_items[0].format_type);
    try std.testing.expectEqual(@as(usize, 1), updated.stickers.len);
    try std.testing.expectEqualStrings("updated_full", updated.stickers[0].name);
    try std.testing.expect(updated.stickers[0].description == null);
    try std.testing.expectEqualStrings("ship", updated.stickers[0].tags);
    try std.testing.expectEqual(Types.StickerFormatType.gif, updated.stickers[0].format_type);
    try std.testing.expect(!updated.stickers[0].available);
    const update_select = updated.components[0].action_row[0].string_select;
    try std.testing.expectEqualStrings("choice", update_select.custom_id);
    try std.testing.expectEqualStrings("Pick", update_select.placeholder.?);
    try std.testing.expectEqual(@as(u8, 1), update_select.min_values.?);
    try std.testing.expectEqual(@as(usize, 1), update_select.options.len);
    try std.testing.expectEqualStrings("One", update_select.options[0].label);
    try std.testing.expect(update_select.options[0].default);
    const user_select = updated.components[1].action_row[0].user_select;
    try std.testing.expectEqual(Interactions.ComponentType.user_select, user_select.type);
    try std.testing.expectEqualStrings("users", user_select.custom_id);
    try std.testing.expectEqualStrings("Pick users", user_select.placeholder.?);
    try std.testing.expectEqual(@as(u8, 2), user_select.max_values.?);
    const role_select = updated.components[2].action_row[0].role_select;
    try std.testing.expectEqualStrings("roles", role_select.custom_id);
    try std.testing.expect(role_select.disabled);
    const mentionable_select = updated.components[3].action_row[0].mentionable_select;
    try std.testing.expectEqualStrings("mentionables", mentionable_select.custom_id);
    const channel_select = updated.components[4].action_row[0].channel_select;
    try std.testing.expectEqualStrings("channels", channel_select.custom_id);
    try std.testing.expectEqual(@as(usize, 2), channel_select.channel_types.len);
    try std.testing.expectEqual(@as(u8, 0), channel_select.channel_types[0]);
    try std.testing.expectEqual(@as(u8, 11), channel_select.channel_types[1]);
    try std.testing.expectEqualStrings("Edited poll", updated.poll.?.question.text.?);
    try std.testing.expectEqual(@as(usize, 0), updated.poll.?.answers.len);
    try std.testing.expect(updated.poll.?.expiry == null);
    try std.testing.expect(!updated.poll.?.allow_multiselect);
    try std.testing.expect(updated.poll.?.results.?.is_finalized);
    try std.testing.expectEqual(@as(usize, 1), updated.reactions.len);
    try std.testing.expectEqual(@as(u32, 1), updated.reactions[0].count);

    var delete = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"MESSAGE_DELETE\",\"d\":{\"id\":\"10\",\"channel_id\":\"20\"}}",
    );
    defer delete.deinit();
    try cache.applyDispatch(delete);

    try std.testing.expect(cache.getMessage(Snowflake.init(10)) == null);
    try std.testing.expectEqual(@as(usize, 0), cache.messageCount());
}

test "cache updates message reaction dispatches" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var create = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"MESSAGE_CREATE\",\"d\":{\"id\":\"10\",\"channel_id\":\"20\",\"content\":\"pong\",\"author\":{\"id\":\"40\",\"username\":\"bot\"},\"reactions\":[{\"count\":1,\"emoji\":{\"id\":null,\"name\":\"👍\"}}]}}",
    );
    defer create.deinit();
    try cache.applyDispatch(create);

    var add_existing = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"MESSAGE_REACTION_ADD\",\"d\":{\"user_id\":\"50\",\"channel_id\":\"20\",\"message_id\":\"10\",\"emoji\":{\"id\":null,\"name\":\"👍\"}}}",
    );
    defer add_existing.deinit();
    try cache.applyDispatch(add_existing);

    var add_custom = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"MESSAGE_REACTION_ADD\",\"d\":{\"user_id\":\"51\",\"channel_id\":\"20\",\"message_id\":\"10\",\"emoji\":{\"id\":\"60\",\"name\":\"zig\",\"animated\":true}}}",
    );
    defer add_custom.deinit();
    try cache.applyDispatch(add_custom);

    var reacted = cache.getMessage(Snowflake.init(10)).?;
    try std.testing.expectEqual(@as(usize, 2), reacted.reactions.len);
    try std.testing.expectEqual(@as(u32, 2), reacted.reactions[0].count);
    try std.testing.expectEqualStrings("👍", reacted.reactions[0].emoji.name.?);
    try std.testing.expectEqual(@as(u64, 60), reacted.reactions[1].emoji.id.?.value);
    try std.testing.expectEqual(@as(u32, 1), reacted.reactions[1].count);
    try std.testing.expect(reacted.reactions[1].emoji.animated);

    var remove_existing = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":4,\"t\":\"MESSAGE_REACTION_REMOVE\",\"d\":{\"user_id\":\"50\",\"channel_id\":\"20\",\"message_id\":\"10\",\"emoji\":{\"id\":null,\"name\":\"👍\"}}}",
    );
    defer remove_existing.deinit();
    try cache.applyDispatch(remove_existing);

    reacted = cache.getMessage(Snowflake.init(10)).?;
    try std.testing.expectEqual(@as(u32, 1), reacted.reactions[0].count);

    var remove_custom = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":5,\"t\":\"MESSAGE_REACTION_REMOVE_EMOJI\",\"d\":{\"channel_id\":\"20\",\"message_id\":\"10\",\"emoji\":{\"id\":\"60\",\"name\":\"zig\",\"animated\":true}}}",
    );
    defer remove_custom.deinit();
    try cache.applyDispatch(remove_custom);

    reacted = cache.getMessage(Snowflake.init(10)).?;
    try std.testing.expectEqual(@as(usize, 1), reacted.reactions.len);
    try std.testing.expectEqualStrings("👍", reacted.reactions[0].emoji.name.?);

    var remove_all = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":6,\"t\":\"MESSAGE_REACTION_REMOVE_ALL\",\"d\":{\"channel_id\":\"20\",\"message_id\":\"10\"}}",
    );
    defer remove_all.deinit();
    try cache.applyDispatch(remove_all);

    try std.testing.expectEqual(@as(usize, 0), cache.getMessage(Snowflake.init(10)).?.reactions.len);
}

test "cache handles bulk message delete dispatch" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    const author = Types.User{ .id = Snowflake.init(99), .username = "bot" };
    try cache.putMessage(.{ .id = Snowflake.init(1), .channel_id = Snowflake.init(10), .author = author, .content = "one" });
    try cache.putMessage(.{ .id = Snowflake.init(2), .channel_id = Snowflake.init(10), .author = author, .content = "two" });
    try cache.putMessage(.{ .id = Snowflake.init(3), .channel_id = Snowflake.init(10), .author = author, .content = "three" });

    var dispatch = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":4,\"t\":\"MESSAGE_DELETE_BULK\",\"d\":{\"ids\":[\"1\",\"3\"],\"channel_id\":\"10\"}}",
    );
    defer dispatch.deinit();
    try cache.applyDispatch(dispatch);

    try std.testing.expect(cache.getMessage(Snowflake.init(1)) == null);
    try std.testing.expect(cache.getMessage(Snowflake.init(2)) != null);
    try std.testing.expect(cache.getMessage(Snowflake.init(3)) == null);
    try std.testing.expectEqual(@as(usize, 1), cache.messageCount());
}
