const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Types = @import("../../models/types.zig");
const Gateway = @import("../../gateway/protocol.zig");

const Root = @import("../cache.zig");
const Cache = Root.Cache;

test "cache lists common guild and channel collections" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    const author = Types.User{ .id = Snowflake.init(30), .username = "bot" };
    try cache.putGuild(.{ .id = Snowflake.init(10), .name = "Guild" });
    try cache.putGuild(.{ .id = Snowflake.init(11), .name = "Other" });
    try cache.putChannel(.{ .id = Snowflake.init(20), .type = .guild_text, .guild_id = Snowflake.init(10), .name = "general" });
    try cache.putChannel(.{ .id = Snowflake.init(21), .type = .dm, .name = "dm" });
    try cache.putChannel(.{ .id = Snowflake.init(22), .type = .public_thread, .guild_id = Snowflake.init(10), .parent_id = Snowflake.init(20), .name = "debug" });
    try cache.putChannel(.{ .id = Snowflake.init(23), .type = .private_thread, .guild_id = Snowflake.init(10), .parent_id = Snowflake.init(21), .name = "private" });
    try cache.putMember(Snowflake.init(10), .{ .user = author, .nick = "ziggy", .roles = &.{Snowflake.init(40)} });
    try cache.putRole(Snowflake.init(10), .{ .id = Snowflake.init(40), .name = "Helper", .permissions = 8 });
    try cache.putEmoji(Snowflake.init(10), .{ .id = Snowflake.init(60), .name = "zig", .user = author, .animated = true });
    try cache.putEmoji(Snowflake.init(11), .{ .id = Snowflake.init(61), .name = "ship" });
    try cache.putSticker(Snowflake.init(10), .{ .id = Snowflake.init(70), .name = "ziggy", .description = "mascot", .tags = "zig", .type = .guild, .format_type = .png, .user = author });
    try cache.putSticker(Snowflake.init(11), .{ .id = Snowflake.init(71), .name = "ship", .tags = "ship", .type = .guild, .format_type = .gif });
    try cache.putScheduledEvent(.{
        .id = Snowflake.init(80),
        .guild_id = Snowflake.init(10),
        .channel_id = Snowflake.init(20),
        .name = "Launch",
        .scheduled_start_time = "2026-06-02T10:00:00.000Z",
        .privacy_level = .guild_only,
        .status = .scheduled,
        .entity_type = .stage_instance,
    });
    try cache.putScheduledEvent(.{
        .id = Snowflake.init(81),
        .guild_id = Snowflake.init(11),
        .channel_id = Snowflake.init(22),
        .name = "Other",
        .scheduled_start_time = "2026-06-03T10:00:00.000Z",
        .privacy_level = .guild_only,
        .status = .scheduled,
        .entity_type = .voice,
    });
    try cache.putStageInstance(.{
        .id = Snowflake.init(90),
        .guild_id = Snowflake.init(10),
        .channel_id = Snowflake.init(20),
        .topic = "Launch stage",
        .privacy_level = .guild_only,
        .guild_scheduled_event_id = Snowflake.init(80),
    });
    try cache.putStageInstance(.{
        .id = Snowflake.init(91),
        .guild_id = Snowflake.init(11),
        .channel_id = Snowflake.init(22),
        .topic = "Other stage",
    });
    try cache.putInvite(.{ .code = "launch", .guild_id = Snowflake.init(10), .channel_id = Snowflake.init(20) });
    try cache.putInvite(.{ .code = "general", .guild_id = Snowflake.init(10), .channel_id = Snowflake.init(21) });
    try cache.putInvite(.{ .code = "other", .guild_id = Snowflake.init(11), .channel_id = Snowflake.init(22) });
    try cache.putPresence(.{ .guild_id = Snowflake.init(10), .user_id = Snowflake.init(30), .status = "online", .activities_count = 2 });
    try cache.putPresence(.{ .guild_id = Snowflake.init(11), .user_id = Snowflake.init(31), .status = "idle" });
    try cache.putVoiceState(.{
        .guild_id = Snowflake.init(10),
        .channel_id = Snowflake.init(20),
        .user_id = Snowflake.init(30),
        .session_id = "voice-session",
        .self_mute = true,
    });
    try cache.putVoiceState(.{
        .guild_id = Snowflake.init(11),
        .channel_id = Snowflake.init(22),
        .user_id = Snowflake.init(31),
        .session_id = "other-session",
    });
    try cache.putMessage(.{ .id = Snowflake.init(50), .channel_id = Snowflake.init(20), .guild_id = Snowflake.init(10), .author = author, .content = "one" });
    try cache.putMessage(.{ .id = Snowflake.init(51), .channel_id = Snowflake.init(21), .author = author, .content = "two" });
    try cache.putMessage(.{ .id = Snowflake.init(52), .channel_id = Snowflake.init(20), .guild_id = Snowflake.init(10), .author = author, .content = "three" });

    const users = try cache.listUsers(std.testing.allocator);
    defer std.testing.allocator.free(users);
    try std.testing.expectEqual(@as(usize, 1), users.len);
    try std.testing.expectEqualStrings("bot", users[0].username);

    const guilds = try cache.listGuilds(std.testing.allocator);
    defer std.testing.allocator.free(guilds);
    try std.testing.expectEqual(@as(usize, 2), guilds.len);

    const all_channels = try cache.listChannels(std.testing.allocator);
    defer std.testing.allocator.free(all_channels);
    try std.testing.expectEqual(@as(usize, 4), all_channels.len);

    var saw_dm = false;
    for (all_channels) |channel| {
        if (channel.id.value == 21 and channel.type == .dm) saw_dm = true;
    }
    try std.testing.expect(saw_dm);

    const top_level_channels = try cache.listTopLevelChannels(std.testing.allocator);
    defer std.testing.allocator.free(top_level_channels);
    try std.testing.expectEqual(@as(usize, 2), top_level_channels.len);
    var saw_general = false;
    saw_dm = false;
    for (top_level_channels) |channel| {
        if (std.mem.eql(u8, channel.name.?, "general")) saw_general = channel.type == .guild_text;
        if (std.mem.eql(u8, channel.name.?, "dm")) saw_dm = channel.type == .dm;
    }
    try std.testing.expect(saw_general);
    try std.testing.expect(saw_dm);

    const channels = try cache.listGuildChannels(std.testing.allocator, Snowflake.init(10));
    defer std.testing.allocator.free(channels);
    try std.testing.expectEqual(@as(usize, 1), channels.len);
    try std.testing.expectEqual(Types.ChannelType.guild_text, channels[0].type);
    try std.testing.expectEqualStrings("general", channels[0].name.?);

    const threads = try cache.listChannelThreads(std.testing.allocator, Snowflake.init(20));
    defer std.testing.allocator.free(threads);
    try std.testing.expectEqual(@as(usize, 1), threads.len);
    try std.testing.expectEqual(Types.ChannelType.public_thread, threads[0].type);
    try std.testing.expectEqualStrings("debug", threads[0].name.?);

    const guild_threads = try cache.listGuildThreads(std.testing.allocator, Snowflake.init(10));
    defer std.testing.allocator.free(guild_threads);
    try std.testing.expectEqual(@as(usize, 2), guild_threads.len);
    var saw_debug_thread = false;
    var saw_private_thread = false;
    for (guild_threads) |thread| {
        if (std.mem.eql(u8, thread.name.?, "debug")) saw_debug_thread = thread.type == .public_thread;
        if (std.mem.eql(u8, thread.name.?, "private")) saw_private_thread = thread.type == .private_thread;
    }
    try std.testing.expect(saw_debug_thread);
    try std.testing.expect(saw_private_thread);

    const members = try cache.listGuildMembers(std.testing.allocator, Snowflake.init(10));
    defer std.testing.allocator.free(members);
    try std.testing.expectEqual(@as(usize, 1), members.len);
    try std.testing.expectEqualStrings("ziggy", members[0].nick.?);
    try std.testing.expectEqualStrings("bot", members[0].user.?.username);

    const all_members = try cache.listMembers(std.testing.allocator);
    defer std.testing.allocator.free(all_members);
    try std.testing.expectEqual(@as(usize, 1), all_members.len);
    try std.testing.expectEqual(@as(u64, 10), all_members[0].guild_id.value);
    try std.testing.expectEqualStrings("ziggy", all_members[0].member.nick.?);
    try std.testing.expectEqualStrings("bot", all_members[0].member.user.?.username);

    const roles = try cache.listGuildRoles(std.testing.allocator, Snowflake.init(10));
    defer std.testing.allocator.free(roles);
    try std.testing.expectEqual(@as(usize, 1), roles.len);
    try std.testing.expectEqualStrings("Helper", roles[0].name);

    const all_roles = try cache.listRoles(std.testing.allocator);
    defer std.testing.allocator.free(all_roles);
    try std.testing.expectEqual(@as(usize, 1), all_roles.len);
    try std.testing.expectEqualStrings("Helper", all_roles[0].name);

    const emojis = try cache.listGuildEmojis(std.testing.allocator, Snowflake.init(10));
    defer std.testing.allocator.free(emojis);
    try std.testing.expectEqual(@as(usize, 1), emojis.len);
    try std.testing.expectEqualStrings("zig", emojis[0].name.?);
    try std.testing.expect(emojis[0].animated);
    try std.testing.expectEqualStrings("bot", emojis[0].user.?.username);

    const all_emojis = try cache.listEmojis(std.testing.allocator);
    defer std.testing.allocator.free(all_emojis);
    try std.testing.expectEqual(@as(usize, 2), all_emojis.len);

    const stickers = try cache.listGuildStickers(std.testing.allocator, Snowflake.init(10));
    defer std.testing.allocator.free(stickers);
    try std.testing.expectEqual(@as(usize, 1), stickers.len);
    try std.testing.expectEqualStrings("ziggy", stickers[0].name);
    try std.testing.expectEqualStrings("mascot", stickers[0].description.?);
    try std.testing.expectEqual(Types.StickerFormatType.png, stickers[0].format_type);
    try std.testing.expectEqualStrings("bot", stickers[0].user.?.username);

    const all_stickers = try cache.listStickers(std.testing.allocator);
    defer std.testing.allocator.free(all_stickers);
    try std.testing.expectEqual(@as(usize, 2), all_stickers.len);

    const events = try cache.listGuildScheduledEvents(std.testing.allocator, Snowflake.init(10));
    defer std.testing.allocator.free(events);
    try std.testing.expectEqual(@as(usize, 1), events.len);
    try std.testing.expectEqualStrings("Launch", events[0].name);
    try std.testing.expectEqual(@as(u64, 20), events[0].channel_id.?.value);
    try std.testing.expectEqual(Types.GuildScheduledEventEntityType.stage_instance, events[0].entity_type);

    const all_events = try cache.listScheduledEvents(std.testing.allocator);
    defer std.testing.allocator.free(all_events);
    try std.testing.expectEqual(@as(usize, 2), all_events.len);

    const stage_instances = try cache.listGuildStageInstances(std.testing.allocator, Snowflake.init(10));
    defer std.testing.allocator.free(stage_instances);
    try std.testing.expectEqual(@as(usize, 1), stage_instances.len);
    try std.testing.expectEqualStrings("Launch stage", stage_instances[0].topic);
    try std.testing.expectEqual(@as(u64, 20), stage_instances[0].channel_id.value);
    try std.testing.expectEqual(@as(u64, 80), stage_instances[0].guild_scheduled_event_id.?.value);

    const all_stage_instances = try cache.listStageInstances(std.testing.allocator);
    defer std.testing.allocator.free(all_stage_instances);
    try std.testing.expectEqual(@as(usize, 2), all_stage_instances.len);

    const guild_invites = try cache.listGuildInvites(std.testing.allocator, Snowflake.init(10));
    defer std.testing.allocator.free(guild_invites);
    try std.testing.expectEqual(@as(usize, 2), guild_invites.len);

    const all_invites = try cache.listInvites(std.testing.allocator);
    defer std.testing.allocator.free(all_invites);
    try std.testing.expectEqual(@as(usize, 3), all_invites.len);

    const channel_invites = try cache.listChannelInvites(std.testing.allocator, Snowflake.init(20));
    defer std.testing.allocator.free(channel_invites);
    try std.testing.expectEqual(@as(usize, 1), channel_invites.len);
    try std.testing.expectEqualStrings("launch", channel_invites[0].code);

    const all_presences = try cache.listPresences(std.testing.allocator);
    defer std.testing.allocator.free(all_presences);
    try std.testing.expectEqual(@as(usize, 2), all_presences.len);

    const presences = try cache.listGuildPresences(std.testing.allocator, Snowflake.init(10));
    defer std.testing.allocator.free(presences);
    try std.testing.expectEqual(@as(usize, 1), presences.len);
    try std.testing.expectEqualStrings("online", presences[0].status);
    try std.testing.expectEqual(@as(usize, 2), presences[0].activities_count);

    const all_voice_states = try cache.listVoiceStates(std.testing.allocator);
    defer std.testing.allocator.free(all_voice_states);
    try std.testing.expectEqual(@as(usize, 2), all_voice_states.len);

    const voice_states = try cache.listGuildVoiceStates(std.testing.allocator, Snowflake.init(10));
    defer std.testing.allocator.free(voice_states);
    try std.testing.expectEqual(@as(usize, 1), voice_states.len);
    try std.testing.expectEqualStrings("voice-session", voice_states[0].session_id);
    try std.testing.expect(voice_states[0].self_mute);
    try std.testing.expectEqualStrings("ziggy", voice_states[0].member.?.nick.?);

    const messages = try cache.listChannelMessages(std.testing.allocator, Snowflake.init(20));
    defer std.testing.allocator.free(messages);
    try std.testing.expectEqual(@as(usize, 2), messages.len);
    try std.testing.expectEqualStrings("one", messages[0].content);
    try std.testing.expectEqualStrings("three", messages[1].content);

    const all_messages = try cache.listMessages(std.testing.allocator);
    defer std.testing.allocator.free(all_messages);
    try std.testing.expectEqual(@as(usize, 3), all_messages.len);
    try std.testing.expectEqualStrings("one", all_messages[0].content);
    try std.testing.expectEqualStrings("two", all_messages[1].content);
    try std.testing.expectEqualStrings("three", all_messages[2].content);

    const guild_messages = try cache.listGuildMessages(std.testing.allocator, Snowflake.init(10));
    defer std.testing.allocator.free(guild_messages);
    try std.testing.expectEqual(@as(usize, 2), guild_messages.len);
    try std.testing.expectEqualStrings("one", guild_messages[0].content);
    try std.testing.expectEqualStrings("three", guild_messages[1].content);
}

test "cache stores guild create channels and members" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var dispatch = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"GUILD_CREATE\",\"d\":{\"id\":\"10\",\"name\":\"Guild\",\"icon\":\"guild_icon\",\"banner\":\"guild_banner\",\"owner_id\":\"99\",\"description\":\"Project guild\",\"afk_channel_id\":\"21\",\"afk_timeout\":300,\"system_channel_id\":\"22\",\"rules_channel_id\":\"23\",\"public_updates_channel_id\":\"24\",\"safety_alerts_channel_id\":\"25\",\"features\":[\"COMMUNITY\",\"NEWS\"],\"preferred_locale\":\"en-US\",\"verification_level\":2,\"default_message_notifications\":1,\"explicit_content_filter\":1,\"mfa_level\":1,\"nsfw_level\":2,\"max_presences\":1000,\"max_members\":5000,\"premium_tier\":3,\"premium_subscription_count\":7,\"premium_progress_bar_enabled\":true,\"approximate_member_count\":100,\"approximate_presence_count\":25,\"channels\":[{\"id\":\"20\",\"type\":0,\"name\":\"general\"}],\"threads\":[{\"id\":\"21\",\"type\":11,\"parent_id\":\"20\",\"name\":\"debug-thread\",\"thread_metadata\":{\"archived\":false,\"auto_archive_duration\":1440,\"archive_timestamp\":\"2026-06-02T00:00:00.000Z\",\"locked\":false}}],\"members\":[{\"user\":{\"id\":\"30\",\"username\":\"member\"},\"nick\":\"ziggy\",\"avatar\":\"member_avatar\",\"roles\":[\"40\"],\"joined_at\":\"2026-06-02T00:00:00.000Z\",\"premium_since\":\"2026-06-03T00:00:00.000Z\",\"deaf\":true,\"mute\":false,\"pending\":true,\"communication_disabled_until\":\"2026-06-04T00:00:00.000Z\"}],\"roles\":[{\"id\":\"40\",\"name\":\"Helper\",\"color\":123,\"hoist\":true,\"permissions\":\"8\",\"mentionable\":true}],\"emojis\":[{\"id\":\"50\",\"name\":\"zig\",\"roles\":[\"40\"],\"user\":{\"id\":\"31\",\"username\":\"artist\"},\"require_colons\":true,\"managed\":false,\"animated\":true,\"available\":true}],\"stage_instances\":[{\"id\":\"60\",\"guild_id\":\"10\",\"channel_id\":\"20\",\"topic\":\"Launch stage\",\"privacy_level\":2,\"discoverable_disabled\":true,\"guild_scheduled_event_id\":\"70\"}],\"presences\":[{\"guild_id\":\"10\",\"user\":{\"id\":\"30\"},\"status\":\"online\",\"activities\":[{\"name\":\"zig\",\"type\":0}]},{\"guild_id\":\"10\",\"user\":{\"id\":\"32\"},\"status\":\"offline\",\"activities\":[]}],\"voice_states\":[{\"guild_id\":\"10\",\"channel_id\":\"20\",\"user_id\":\"33\",\"member\":{\"user\":{\"id\":\"33\",\"username\":\"speaker\"},\"roles\":[]},\"session_id\":\"voice-session\",\"deaf\":false,\"mute\":false,\"self_deaf\":false,\"self_mute\":true,\"self_video\":true,\"suppress\":false}]}}",
    );
    defer dispatch.deinit();

    try cache.applyDispatch(dispatch);

    const guild = cache.getGuild(Snowflake.init(10)).?;
    try std.testing.expectEqualStrings("Guild", guild.name);
    try std.testing.expectEqualStrings("guild_icon", guild.icon.?);
    try std.testing.expectEqualStrings("guild_banner", guild.banner.?);
    try std.testing.expectEqual(@as(u64, 99), guild.owner_id.?.value);
    try std.testing.expectEqualStrings("Project guild", guild.description.?);
    try std.testing.expectEqual(@as(u64, 21), guild.afk_channel_id.?.value);
    try std.testing.expectEqual(@as(u32, 300), guild.afk_timeout.?);
    try std.testing.expectEqual(@as(u64, 22), guild.system_channel_id.?.value);
    try std.testing.expectEqual(@as(u64, 23), guild.rules_channel_id.?.value);
    try std.testing.expectEqual(@as(u64, 24), guild.public_updates_channel_id.?.value);
    try std.testing.expectEqual(@as(u64, 25), guild.safety_alerts_channel_id.?.value);
    try std.testing.expectEqual(@as(usize, 2), guild.features.len);
    try std.testing.expectEqualStrings("COMMUNITY", guild.features[0]);
    try std.testing.expectEqualStrings("NEWS", guild.features[1]);
    try std.testing.expectEqualStrings("en-US", guild.preferred_locale.?);
    try std.testing.expectEqual(@as(u8, 2), guild.verification_level.?);
    try std.testing.expectEqual(@as(u8, 1), guild.default_message_notifications.?);
    try std.testing.expectEqual(@as(u8, 1), guild.explicit_content_filter.?);
    try std.testing.expectEqual(@as(u8, 1), guild.mfa_level.?);
    try std.testing.expectEqual(@as(u8, 2), guild.nsfw_level.?);
    try std.testing.expectEqual(@as(u32, 1000), guild.max_presences.?);
    try std.testing.expectEqual(@as(u32, 5000), guild.max_members.?);
    try std.testing.expectEqual(@as(u8, 3), guild.premium_tier.?);
    try std.testing.expectEqual(@as(u32, 7), guild.premium_subscription_count.?);
    try std.testing.expect(guild.premium_progress_bar_enabled.?);
    try std.testing.expectEqual(@as(u32, 100), guild.approximate_member_count.?);
    try std.testing.expectEqual(@as(u32, 25), guild.approximate_presence_count.?);
    const channel = cache.getChannel(Snowflake.init(20)).?;
    try std.testing.expectEqual(Types.ChannelType.guild_text, channel.type);
    try std.testing.expectEqualStrings("general", channel.name.?);
    const thread = cache.getChannel(Snowflake.init(21)).?;
    try std.testing.expectEqual(Types.ChannelType.public_thread, thread.type);
    try std.testing.expectEqual(@as(u64, 10), thread.guild_id.?.value);
    try std.testing.expectEqual(@as(u64, 20), thread.parent_id.?.value);
    try std.testing.expectEqualStrings("debug-thread", thread.name.?);
    try std.testing.expect(!thread.thread_metadata.?.archived);
    const threads = try cache.listChannelThreads(std.testing.allocator, Snowflake.init(20));
    defer std.testing.allocator.free(threads);
    try std.testing.expectEqual(@as(usize, 1), threads.len);
    try std.testing.expectEqual(@as(u64, 21), threads[0].id.value);
    try std.testing.expectEqualStrings("member", cache.getUser(Snowflake.init(30)).?.username);
    const member = cache.getMember(Snowflake.init(10), Snowflake.init(30)).?;
    try std.testing.expectEqualStrings("ziggy", member.nick.?);
    try std.testing.expectEqualStrings("member_avatar", member.avatar.?);
    try std.testing.expectEqual(@as(usize, 1), member.roles.len);
    try std.testing.expectEqual(@as(u64, 40), member.roles[0].value);
    try std.testing.expectEqualStrings("2026-06-02T00:00:00.000Z", member.joined_at.?);
    try std.testing.expectEqualStrings("2026-06-03T00:00:00.000Z", member.premium_since.?);
    try std.testing.expect(member.deaf);
    try std.testing.expect(!member.mute);
    try std.testing.expect(member.pending);
    try std.testing.expectEqualStrings("2026-06-04T00:00:00.000Z", member.communication_disabled_until.?);
    const role = cache.getRole(Snowflake.init(10), Snowflake.init(40)).?;
    try std.testing.expectEqualStrings("Helper", role.name);
    try std.testing.expectEqual(@as(u64, 8), role.permissions);
    const emoji = cache.getEmoji(Snowflake.init(10), Snowflake.init(50)).?;
    try std.testing.expectEqualStrings("zig", emoji.name.?);
    try std.testing.expectEqual(@as(usize, 1), emoji.roles.len);
    try std.testing.expectEqual(@as(u64, 40), emoji.roles[0].value);
    try std.testing.expectEqualStrings("artist", emoji.user.?.username);
    try std.testing.expect(emoji.require_colons);
    try std.testing.expect(emoji.animated);
    const stage_instance = cache.getStageInstance(Snowflake.init(10), Snowflake.init(60)).?;
    try std.testing.expectEqual(@as(u64, 20), stage_instance.channel_id.value);
    try std.testing.expectEqualStrings("Launch stage", stage_instance.topic);
    try std.testing.expect(stage_instance.discoverable_disabled);
    try std.testing.expectEqual(@as(u64, 70), stage_instance.guild_scheduled_event_id.?.value);
    const presence = cache.getPresence(Snowflake.init(10), Snowflake.init(30)).?;
    try std.testing.expectEqualStrings("online", presence.status);
    try std.testing.expectEqual(@as(usize, 1), presence.activities_count);
    try std.testing.expect(cache.getPresence(Snowflake.init(10), Snowflake.init(32)) == null);
    const voice_state = cache.getVoiceState(Snowflake.init(10), Snowflake.init(33)).?;
    try std.testing.expectEqual(@as(u64, 20), voice_state.channel_id.?.value);
    try std.testing.expectEqualStrings("voice-session", voice_state.session_id);
    try std.testing.expect(voice_state.self_mute);
    try std.testing.expect(voice_state.self_video);
    try std.testing.expectEqualStrings("speaker", voice_state.member.?.user.?.username);
}
