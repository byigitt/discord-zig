const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Types = @import("../../models/types.zig");
const Gateway = @import("../../gateway/protocol.zig");
const Interactions = @import("../../interactions/mod.zig");
const Permissions = @import("../../core/permissions.zig");
const Collection = @import("../../core/collection.zig").Collection;

const Root = @import("../cache.zig");
const CachePolicy = Root.CachePolicy;
const CacheStats = Root.CacheStats;
const GuildCacheStats = Root.GuildCacheStats;
const ChannelCacheStats = Root.ChannelCacheStats;
const Cache = Root.Cache;
const OwnedUser = Root.OwnedUser;
const OwnedGuild = Root.OwnedGuild;
const OwnedChannel = Root.OwnedChannel;
const OwnedGuildMember = Root.OwnedGuildMember;
const OwnedRole = Root.OwnedRole;
const OwnedEmoji = Root.OwnedEmoji;
const OwnedSticker = Root.OwnedSticker;
const OwnedScheduledEvent = Root.OwnedScheduledEvent;
const OwnedStageInstance = Root.OwnedStageInstance;
const OwnedInvite = Root.OwnedInvite;
const OwnedPresence = Root.OwnedPresence;
const OwnedVoiceState = Root.OwnedVoiceState;
const OwnedMessage = Root.OwnedMessage;
const copyAttachments = Root.copyAttachments;
const copyAttachment = Root.copyAttachment;
const deinitAttachments = Root.deinitAttachments;
const copyMessageSnapshots = Root.copyMessageSnapshots;
const copyMessageSnapshot = Root.copyMessageSnapshot;
const deinitMessageSnapshots = Root.deinitMessageSnapshots;
const deinitMessageSnapshot = Root.deinitMessageSnapshot;
const copyMessageStickerItems = Root.copyMessageStickerItems;
const deinitMessageStickerItems = Root.deinitMessageStickerItems;
const copyStickers = Root.copyStickers;
const copySticker = Root.copySticker;
const deinitStickers = Root.deinitStickers;
const deinitSticker = Root.deinitSticker;
const copyComponents = Root.copyComponents;
const copyComponent = Root.copyComponent;
const copyButton = Root.copyButton;
const copyStringSelect = Root.copyStringSelect;
const copyAutoSelect = Root.copyAutoSelect;
const copyTextInput = Root.copyTextInput;
const copyTextDisplay = Root.copyTextDisplay;
const copyUnfurledMedia = Root.copyUnfurledMedia;
const copyThumbnail = Root.copyThumbnail;
const copySection = Root.copySection;
const copyMediaGallery = Root.copyMediaGallery;
const copyFileComponent = Root.copyFileComponent;
const copyContainer = Root.copyContainer;
const copySelectOptions = Root.copySelectOptions;
const deinitComponents = Root.deinitComponents;
const deinitComponent = Root.deinitComponent;
const deinitSelectOptions = Root.deinitSelectOptions;
const deinitThumbnail = Root.deinitThumbnail;
const deinitMediaGalleryItem = Root.deinitMediaGalleryItem;
const copyMessagePoll = Root.copyMessagePoll;
const copyMessagePollMedia = Root.copyMessagePollMedia;
const copyPollEmoji = Root.copyPollEmoji;
const copyMessagePollAnswers = Root.copyMessagePollAnswers;
const copyMessagePollResults = Root.copyMessagePollResults;
const deinitMessagePoll = Root.deinitMessagePoll;
const deinitMessagePollAnswers = Root.deinitMessagePollAnswers;
const deinitMessagePollMedia = Root.deinitMessagePollMedia;
const copyMessageCall = Root.copyMessageCall;
const deinitMessageCall = Root.deinitMessageCall;
const copyRoleSubscriptionData = Root.copyRoleSubscriptionData;
const deinitRoleSubscriptionData = Root.deinitRoleSubscriptionData;
const copySharedClientTheme = Root.copySharedClientTheme;
const deinitSharedClientTheme = Root.deinitSharedClientTheme;
const copyMessageActivity = Root.copyMessageActivity;
const deinitMessageActivity = Root.deinitMessageActivity;
const copyMessageInteractionMetadata = Root.copyMessageInteractionMetadata;
const deinitMessageInteractionMetadata = Root.deinitMessageInteractionMetadata;
const copyGuildMember = Root.copyGuildMember;
const deinitGuildMember = Root.deinitGuildMember;
const copyUsers = Root.copyUsers;
const copyUser = Root.copyUser;
const deinitUsers = Root.deinitUsers;
const deinitUser = Root.deinitUser;
const copyApplication = Root.copyApplication;
const deinitApplication = Root.deinitApplication;
const copyChannels = Root.copyChannels;
const copyChannel = Root.copyChannel;
const copyDefaultReactionEmoji = Root.copyDefaultReactionEmoji;
const copyForumTags = Root.copyForumTags;
const copyForumTag = Root.copyForumTag;
const copyThreadMetadata = Root.copyThreadMetadata;
const deinitChannels = Root.deinitChannels;
const deinitChannel = Root.deinitChannel;
const deinitDefaultReactionEmoji = Root.deinitDefaultReactionEmoji;
const deinitForumTags = Root.deinitForumTags;
const deinitThreadMetadata = Root.deinitThreadMetadata;
const copyEmbeds = Root.copyEmbeds;
const copyEmbed = Root.copyEmbed;
const copyEmbedFooter = Root.copyEmbedFooter;
const copyEmbedMedia = Root.copyEmbedMedia;
const copyEmbedAuthor = Root.copyEmbedAuthor;
const copyEmbedFields = Root.copyEmbedFields;
const deinitEmbeds = Root.deinitEmbeds;
const deinitEmbed = Root.deinitEmbed;
const deinitEmbedFooter = Root.deinitEmbedFooter;
const deinitEmbedMedia = Root.deinitEmbedMedia;
const deinitEmbedAuthor = Root.deinitEmbedAuthor;
const deinitEmbedField = Root.deinitEmbedField;
const copyReactions = Root.copyReactions;
const copyReaction = Root.copyReaction;
const copyReactionEmoji = Root.copyReactionEmoji;
const deinitReactions = Root.deinitReactions;
const deinitReactionEmoji = Root.deinitReactionEmoji;
const incrementReaction = Root.incrementReaction;
const decrementReaction = Root.decrementReaction;
const removeReactionEmoji = Root.removeReactionEmoji;
const removeReactionAt = Root.removeReactionAt;
const reactionEmojiEql = Root.reactionEmojiEql;
const memberKey = Root.memberKey;
const roleKey = Root.roleKey;
const replaceOwned = Root.replaceOwned;
const clearOwnedMap = Root.clearOwnedMap;
const clearOwnedMapRetainingCapacity = Root.clearOwnedMapRetainingCapacity;
const userFromJson = Root.userFromJson;
const applicationFromJson = Root.applicationFromJson;
const deinitParsedApplication = Root.deinitParsedApplication;
const teamFromJson = Root.teamFromJson;
const teamMembersFromJson = Root.teamMembersFromJson;
const teamMemberFromJson = Root.teamMemberFromJson;
const membershipStateFromInt = Root.membershipStateFromInt;
const deinitParsedTeam = Root.deinitParsedTeam;
const copyTeam = Root.copyTeam;
const copyTeamMember = Root.copyTeamMember;
const deinitTeam = Root.deinitTeam;
const deinitTeamMember = Root.deinitTeamMember;
const applicationEventWebhookStatusFromInt = Root.applicationEventWebhookStatusFromInt;
const channelFromJson = Root.channelFromJson;
const deinitParsedChannel = Root.deinitParsedChannel;
const deinitParsedChannels = Root.deinitParsedChannels;
const threadMetadataFromJson = Root.threadMetadataFromJson;
const permissionOverwriteArrayFromJson = Root.permissionOverwriteArrayFromJson;
const permissionOverwriteFromJson = Root.permissionOverwriteFromJson;
const forumTagArrayFromJson = Root.forumTagArrayFromJson;
const forumTagFromJson = Root.forumTagFromJson;
const nullableDefaultReactionEmojiFromJson = Root.nullableDefaultReactionEmojiFromJson;
const nullableChannelSortOrderFromJson = Root.nullableChannelSortOrderFromJson;
const nullableForumLayoutFromJson = Root.nullableForumLayoutFromJson;
const permissionOverwriteTypeFromInt = Root.permissionOverwriteTypeFromInt;
const deinitParsedForumTags = Root.deinitParsedForumTags;
const channelTypeFromInt = Root.channelTypeFromInt;
const channelTypeIsThread = Root.channelTypeIsThread;
const roleFromJson = Root.roleFromJson;
const roleColorsFromJson = Root.roleColorsFromJson;
const roleTagsFromJson = Root.roleTagsFromJson;
const emojiFromJson = Root.emojiFromJson;
const stickerFromJson = Root.stickerFromJson;
const stickerFromJsonOptionalFallback = Root.stickerFromJsonOptionalFallback;
const stickerArrayFromJson = Root.stickerArrayFromJson;
const stickerTypeFromInt = Root.stickerTypeFromInt;
const stickerFormatTypeFromInt = Root.stickerFormatTypeFromInt;
const scheduledEventFromJson = Root.scheduledEventFromJson;
const scheduledEventPrivacyLevelFromInt = Root.scheduledEventPrivacyLevelFromInt;
const scheduledEventEntityTypeFromInt = Root.scheduledEventEntityTypeFromInt;
const scheduledEventStatusFromInt = Root.scheduledEventStatusFromInt;
const stageInstanceFromJson = Root.stageInstanceFromJson;
const stageInstancePrivacyLevelFromInt = Root.stageInstancePrivacyLevelFromInt;
const inviteFromJson = Root.inviteFromJson;
const presenceFromJson = Root.presenceFromJson;
const voiceStateFromJson = Root.voiceStateFromJson;
const messageReferenceFromJson = Root.messageReferenceFromJson;
const messageReferenceTypeFromInt = Root.messageReferenceTypeFromInt;
const referencedMessageIdFromJson = Root.referencedMessageIdFromJson;
const messageSnapshotArrayFromJson = Root.messageSnapshotArrayFromJson;
const messageSnapshotFromJson = Root.messageSnapshotFromJson;
const deinitParsedMessageSnapshots = Root.deinitParsedMessageSnapshots;
const memberFromJson = Root.memberFromJson;
const roleArrayFromJson = Root.roleArrayFromJson;
const userArrayFromJson = Root.userArrayFromJson;
const channelArrayFromJson = Root.channelArrayFromJson;
const stringArrayFromJson = Root.stringArrayFromJson;
const copyStringArray = Root.copyStringArray;
const deinitStringArray = Root.deinitStringArray;
const deinitConstStringArray = Root.deinitConstStringArray;
const attachmentArrayFromJson = Root.attachmentArrayFromJson;
const messageStickerItemArrayFromJson = Root.messageStickerItemArrayFromJson;
const messageStickerItemFromJson = Root.messageStickerItemFromJson;
const componentArrayFromJson = Root.componentArrayFromJson;
const componentFromJson = Root.componentFromJson;
const buttonFromJson = Root.buttonFromJson;
const stringSelectFromJson = Root.stringSelectFromJson;
const autoSelectFromJson = Root.autoSelectFromJson;
const u8ArrayFromJson = Root.u8ArrayFromJson;
const selectOptionArrayFromJson = Root.selectOptionArrayFromJson;
const selectOptionFromJson = Root.selectOptionFromJson;
const deinitParsedComponents = Root.deinitParsedComponents;
const deinitParsedComponentArray = Root.deinitParsedComponentArray;
const buttonStyleFromInt = Root.buttonStyleFromInt;
const messagePollFromJson = Root.messagePollFromJson;
const messageInteractionMetadataFromJson = Root.messageInteractionMetadataFromJson;
const messageCallFromJson = Root.messageCallFromJson;
const deinitParsedMessageCall = Root.deinitParsedMessageCall;
const nullableRoleSubscriptionDataFromJson = Root.nullableRoleSubscriptionDataFromJson;
const sharedClientThemeFromJson = Root.sharedClientThemeFromJson;
const deinitParsedSharedClientTheme = Root.deinitParsedSharedClientTheme;
const nullableSharedClientThemeBaseFromJson = Root.nullableSharedClientThemeBaseFromJson;
const nullableMessageActivityFromJson = Root.nullableMessageActivityFromJson;
const messageActivityTypeFromInt = Root.messageActivityTypeFromInt;
const interactionTypeFromInt = Root.interactionTypeFromInt;
const messagePollMediaFromJson = Root.messagePollMediaFromJson;
const pollEmojiFromJson = Root.pollEmojiFromJson;
const messagePollAnswerArrayFromJson = Root.messagePollAnswerArrayFromJson;
const messagePollAnswerFromJson = Root.messagePollAnswerFromJson;
const messagePollResultsFromJson = Root.messagePollResultsFromJson;
const messagePollAnswerCountArrayFromJson = Root.messagePollAnswerCountArrayFromJson;
const messagePollAnswerCountFromJson = Root.messagePollAnswerCountFromJson;
const deinitParsedMessagePoll = Root.deinitParsedMessagePoll;
const embedArrayFromJson = Root.embedArrayFromJson;
const deinitParsedEmbeds = Root.deinitParsedEmbeds;
const embedFromJson = Root.embedFromJson;
const embedFooterFromJson = Root.embedFooterFromJson;
const embedMediaFromJson = Root.embedMediaFromJson;
const embedAuthorFromJson = Root.embedAuthorFromJson;
const embedFieldArrayFromJson = Root.embedFieldArrayFromJson;
const embedFieldFromJson = Root.embedFieldFromJson;
const attachmentFromJson = Root.attachmentFromJson;
const reactionArrayFromJson = Root.reactionArrayFromJson;
const reactionFromJson = Root.reactionFromJson;
const reactionCountDetailsFromJson = Root.reactionCountDetailsFromJson;
const deinitParsedReactions = Root.deinitParsedReactions;
const deinitParsedReactionFields = Root.deinitParsedReactionFields;
const ReactionEvent = Root.ReactionEvent;
const reactionEventFromJson = Root.reactionEventFromJson;
const reactionEmojiFromJson = Root.reactionEmojiFromJson;
const requireObject = Root.requireObject;
const requireArray = Root.requireArray;
const snowflakeField = Root.snowflakeField;
const snowflakeValue = Root.snowflakeValue;
const nullableSnowflakeValue = Root.nullableSnowflakeValue;
const permissionsValue = Root.permissionsValue;
const stringField = Root.stringField;
const intField = Root.intField;
const intValue = Root.intValue;
const nullableIntValue = Root.nullableIntValue;
const nullableU24Value = Root.nullableU24Value;
const ParsedMessageNonce = Root.ParsedMessageNonce;
const messageNonceFromJson = Root.messageNonceFromJson;
const optionalU32Value = Root.optionalU32Value;
const optionalU8Value = Root.optionalU8Value;
const stringValue = Root.stringValue;
const optionalStringValue = Root.optionalStringValue;
const boolValue = Root.boolValue;
const optionalBoolValue = Root.optionalBoolValue;
const nestedIdValue = Root.nestedIdValue;

test "cache updates voice channel info dispatches" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    try cache.putChannel(.{
        .id = Snowflake.init(20),
        .type = .guild_voice,
        .guild_id = Snowflake.init(10),
        .name = "voice",
    });
    try cache.putChannel(.{
        .id = Snowflake.init(21),
        .type = .guild_voice,
        .guild_id = Snowflake.init(10),
        .name = "voice-2",
    });

    var info = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"CHANNEL_INFO\",\"d\":{\"guild_id\":\"10\",\"channels\":[{\"id\":\"20\",\"status\":\"Planning\",\"voice_start_time\":1780000000},{\"id\":\"21\",\"voice_start_time\":1780000100},{\"id\":\"22\",\"status\":\"Unknown\"}]}}",
    );
    defer info.deinit();
    try cache.applyDispatch(info);

    const first = cache.getChannel(Snowflake.init(20)).?;
    try std.testing.expectEqualStrings("Planning", first.status.?);
    try std.testing.expectEqual(@as(i64, 1780000000), first.voice_start_time.?);

    const second = cache.getChannel(Snowflake.init(21)).?;
    try std.testing.expect(second.status == null);
    try std.testing.expectEqual(@as(i64, 1780000100), second.voice_start_time.?);
    try std.testing.expect(cache.getChannel(Snowflake.init(22)) == null);

    var status_update = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"VOICE_CHANNEL_STATUS_UPDATE\",\"d\":{\"id\":\"20\",\"guild_id\":\"10\",\"status\":null}}",
    );
    defer status_update.deinit();
    try cache.applyDispatch(status_update);
    try std.testing.expect(cache.getChannel(Snowflake.init(20)).?.status == null);
    try std.testing.expectEqual(@as(i64, 1780000000), cache.getChannel(Snowflake.init(20)).?.voice_start_time.?);

    var start_time_update = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"VOICE_CHANNEL_START_TIME_UPDATE\",\"d\":{\"id\":\"20\",\"guild_id\":\"10\",\"voice_start_time\":null}}",
    );
    defer start_time_update.deinit();
    try cache.applyDispatch(start_time_update);
    try std.testing.expect(cache.getChannel(Snowflake.init(20)).?.voice_start_time == null);

    var unknown = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":4,\"t\":\"VOICE_CHANNEL_STATUS_UPDATE\",\"d\":{\"id\":\"22\",\"guild_id\":\"10\",\"status\":\"Ignored\"}}",
    );
    defer unknown.deinit();
    try cache.applyDispatch(unknown);
    try std.testing.expect(cache.getChannel(Snowflake.init(22)) == null);
}

test "cache handles thread create update and delete dispatches" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var create = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"THREAD_CREATE\",\"d\":{\"id\":\"30\",\"type\":11,\"guild_id\":\"10\",\"name\":\"debug\",\"parent_id\":\"20\",\"rate_limit_per_user\":10,\"thread_metadata\":{\"archived\":false,\"auto_archive_duration\":1440,\"archive_timestamp\":\"2026-06-02T00:00:00.000Z\",\"locked\":false,\"invitable\":true,\"create_timestamp\":\"2026-06-01T00:00:00.000Z\"},\"applied_tags\":[\"40\",\"50\"]}}",
    );
    defer create.deinit();
    try cache.applyDispatch(create);

    const created = cache.getChannel(Snowflake.init(30)).?;
    try std.testing.expectEqual(Types.ChannelType.public_thread, created.type);
    try std.testing.expectEqualStrings("debug", created.name.?);
    try std.testing.expectEqual(@as(u64, 20), created.parent_id.?.value);
    try std.testing.expectEqual(@as(u16, 10), created.rate_limit_per_user.?);
    try std.testing.expect(!created.thread_metadata.?.archived);
    try std.testing.expectEqual(@as(u16, 1440), created.thread_metadata.?.auto_archive_duration);
    try std.testing.expectEqualStrings("2026-06-02T00:00:00.000Z", created.thread_metadata.?.archive_timestamp.?);
    try std.testing.expect(!created.thread_metadata.?.locked);
    try std.testing.expect(created.thread_metadata.?.invitable.?);
    try std.testing.expectEqualStrings("2026-06-01T00:00:00.000Z", created.thread_metadata.?.create_timestamp.?);
    try std.testing.expectEqual(@as(usize, 2), created.applied_tags.len);
    try std.testing.expectEqual(@as(u64, 40), created.applied_tags[0].value);
    try std.testing.expectEqual(@as(u64, 50), created.applied_tags[1].value);

    var update = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"THREAD_UPDATE\",\"d\":{\"id\":\"30\",\"type\":11,\"guild_id\":\"10\",\"name\":\"debug-renamed\",\"thread_metadata\":{\"archived\":true,\"auto_archive_duration\":60,\"archive_timestamp\":\"2026-06-02T01:00:00.000Z\",\"locked\":true},\"applied_tags\":[]}}",
    );
    defer update.deinit();
    try cache.applyDispatch(update);

    const updated_thread = cache.getChannel(Snowflake.init(30)).?;
    try std.testing.expectEqualStrings("debug-renamed", updated_thread.name.?);
    try std.testing.expect(updated_thread.thread_metadata.?.archived);
    try std.testing.expectEqual(@as(u16, 60), updated_thread.thread_metadata.?.auto_archive_duration);
    try std.testing.expectEqualStrings("2026-06-02T01:00:00.000Z", updated_thread.thread_metadata.?.archive_timestamp.?);
    try std.testing.expect(updated_thread.thread_metadata.?.locked);
    try std.testing.expect(updated_thread.thread_metadata.?.invitable == null);
    try std.testing.expectEqual(@as(usize, 0), updated_thread.applied_tags.len);

    var delete = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"THREAD_DELETE\",\"d\":{\"id\":\"30\",\"type\":11,\"guild_id\":\"10\",\"name\":\"debug-renamed\"}}",
    );
    defer delete.deinit();
    try cache.applyDispatch(delete);

    try std.testing.expect(cache.getChannel(Snowflake.init(30)) == null);
}

test "cache applies thread list sync scope" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    try cache.putChannel(.{ .id = Snowflake.init(30), .type = .public_thread, .guild_id = Snowflake.init(10), .parent_id = Snowflake.init(20), .name = "stale" });
    try cache.putChannel(.{ .id = Snowflake.init(31), .type = .private_thread, .guild_id = Snowflake.init(10), .parent_id = Snowflake.init(21), .name = "keep-other-parent" });
    try cache.putChannel(.{ .id = Snowflake.init(32), .type = .announcement_thread, .guild_id = Snowflake.init(11), .parent_id = Snowflake.init(20), .name = "keep-other-guild" });

    var sync = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"THREAD_LIST_SYNC\",\"d\":{\"guild_id\":\"10\",\"channel_ids\":[\"20\"],\"threads\":[{\"id\":\"33\",\"type\":11,\"parent_id\":\"20\",\"name\":\"fresh\",\"thread_metadata\":{\"archived\":false,\"auto_archive_duration\":1440,\"archive_timestamp\":\"2026-06-02T00:00:00.000Z\",\"locked\":false}}],\"members\":[]}}",
    );
    defer sync.deinit();
    try cache.applyDispatch(sync);

    try std.testing.expect(cache.getChannel(Snowflake.init(30)) == null);
    try std.testing.expect(cache.getChannel(Snowflake.init(31)) != null);
    try std.testing.expect(cache.getChannel(Snowflake.init(32)) != null);

    const fresh = cache.getChannel(Snowflake.init(33)).?;
    try std.testing.expectEqual(Types.ChannelType.public_thread, fresh.type);
    try std.testing.expectEqual(@as(u64, 10), fresh.guild_id.?.value);
    try std.testing.expectEqual(@as(u64, 20), fresh.parent_id.?.value);
    try std.testing.expectEqualStrings("fresh", fresh.name.?);

    const parent_threads = try cache.listChannelThreads(std.testing.allocator, Snowflake.init(20));
    defer std.testing.allocator.free(parent_threads);
    try std.testing.expectEqual(@as(usize, 2), parent_threads.len);
}

test "cache updates thread member count dispatch" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    try cache.putChannel(.{ .id = Snowflake.init(30), .type = .public_thread, .guild_id = Snowflake.init(10), .parent_id = Snowflake.init(20), .name = "thread", .member_count = 2 });
    try cache.putChannel(.{ .id = Snowflake.init(40), .type = .guild_text, .guild_id = Snowflake.init(10), .name = "text", .member_count = 7 });

    var update = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"THREAD_MEMBERS_UPDATE\",\"d\":{\"id\":\"30\",\"guild_id\":\"10\",\"member_count\":5,\"added_members\":[],\"removed_member_ids\":[]}}",
    );
    defer update.deinit();
    try cache.applyDispatch(update);

    try std.testing.expectEqual(@as(u32, 5), cache.getChannel(Snowflake.init(30)).?.member_count.?);

    var non_thread_update = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"THREAD_MEMBERS_UPDATE\",\"d\":{\"id\":\"40\",\"guild_id\":\"10\",\"member_count\":1,\"added_members\":[],\"removed_member_ids\":[]}}",
    );
    defer non_thread_update.deinit();
    try cache.applyDispatch(non_thread_update);

    try std.testing.expectEqual(@as(u32, 7), cache.getChannel(Snowflake.init(40)).?.member_count.?);
}

test "cache evicts oldest messages by policy" {
    var cache = Cache.initWithPolicy(std.testing.allocator, .{ .max_messages = 2 });
    defer cache.deinit();

    const author = Types.User{ .id = Snowflake.init(99), .username = "bot" };
    try cache.putMessage(.{ .id = Snowflake.init(1), .channel_id = Snowflake.init(10), .author = author, .content = "one" });
    try cache.putMessage(.{ .id = Snowflake.init(2), .channel_id = Snowflake.init(10), .author = author, .content = "two" });
    try cache.putMessage(.{ .id = Snowflake.init(3), .channel_id = Snowflake.init(10), .author = author, .content = "three" });

    try std.testing.expectEqual(@as(usize, 2), cache.messageCount());
    try std.testing.expect(cache.getMessage(Snowflake.init(1)) == null);
    try std.testing.expect(cache.getMessage(Snowflake.init(2)) != null);
    try std.testing.expect(cache.getMessage(Snowflake.init(3)) != null);
}

test "cache can disable message storage while keeping users" {
    var cache = Cache.initWithPolicy(std.testing.allocator, .noMessages());
    defer cache.deinit();

    const author = Types.User{ .id = Snowflake.init(99), .username = "bot" };
    try cache.putMessage(.{ .id = Snowflake.init(1), .channel_id = Snowflake.init(10), .author = author, .content = "one" });

    try std.testing.expectEqual(@as(usize, 0), cache.messageCount());
    try std.testing.expect(cache.getMessage(Snowflake.init(1)) == null);
    try std.testing.expect(cache.getUser(Snowflake.init(99)) != null);
}

test "cache sweeps messages older than the configured max age" {
    var cache = Cache.initWithPolicy(std.testing.allocator, .{ .message_sweep_max_age_ms = 60_000 });
    defer cache.deinit();

    const author = Types.User{ .id = Snowflake.init(99), .username = "bot" };
    const now: u64 = 1_700_000_000_000;
    const stale_id = (try Snowflake.fromTimestampMillis(now - 120_000)).value;
    const fresh_id = (try Snowflake.fromTimestampMillis(now - 10_000)).value;

    try cache.putMessage(.{ .id = Snowflake.init(stale_id), .channel_id = Snowflake.init(10), .author = author, .content = "old" });
    try cache.putMessage(.{ .id = Snowflake.init(fresh_id), .channel_id = Snowflake.init(10), .author = author, .content = "new" });
    try std.testing.expectEqual(@as(usize, 2), cache.messageCount());

    try std.testing.expectEqual(@as(usize, 1), cache.sweep(now));
    try std.testing.expectEqual(@as(usize, 1), cache.messageCount());
    try std.testing.expect(cache.getMessage(Snowflake.init(stale_id)) == null);
    try std.testing.expect(cache.getMessage(Snowflake.init(fresh_id)) != null);

    // Direct cutoff sweep removes everything created before the cutoff.
    try std.testing.expectEqual(@as(usize, 1), cache.sweepMessagesBefore(now));
    try std.testing.expectEqual(@as(usize, 0), cache.messageCount());

    // Without a configured sweeper, sweep is a no-op.
    var unconfigured = Cache.init(std.testing.allocator);
    defer unconfigured.deinit();
    try unconfigured.putMessage(.{ .id = Snowflake.init(stale_id), .channel_id = Snowflake.init(10), .author = author, .content = "old" });
    try std.testing.expectEqual(@as(usize, 0), unconfigured.sweep(now));
    try std.testing.expectEqual(@as(usize, 1), unconfigured.messageCount());
}

test "cache parses extended invite metadata" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var dispatch = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"INVITE_CREATE\",\"d\":{\"code\":\"abc123\",\"type\":0,\"guild_id\":\"30\",\"channel_id\":\"20\",\"inviter\":{\"id\":\"40\",\"username\":\"host\"},\"target_type\":2,\"target_application\":{\"id\":\"50\"},\"approximate_member_count\":120,\"expires_at\":\"2026-07-01T00:00:00.000Z\",\"uses\":3,\"max_uses\":10,\"max_age\":3600,\"temporary\":true,\"created_at\":\"2026-06-01T00:00:00.000Z\"}}",
    );
    defer dispatch.deinit();
    try cache.applyDispatch(dispatch);

    const invite = cache.getInvite("abc123").?;
    try std.testing.expectEqual(@as(?u8, 0), invite.type);
    try std.testing.expectEqual(@as(u64, 30), invite.guild_id.?.value);
    try std.testing.expectEqual(@as(u64, 40), invite.inviter_id.?.value);
    try std.testing.expectEqual(@as(?u8, 2), invite.target_type);
    try std.testing.expectEqual(@as(u64, 50), invite.target_application_id.?.value);
    try std.testing.expectEqual(@as(?u32, 120), invite.approximate_member_count);
    try std.testing.expectEqualStrings("2026-07-01T00:00:00.000Z", invite.expires_at.?);
    try std.testing.expectEqual(@as(?u32, 3), invite.uses);
    try std.testing.expectEqual(@as(?u32, 10), invite.max_uses);
    try std.testing.expectEqual(@as(?u32, 3600), invite.max_age);
    try std.testing.expectEqual(@as(?bool, true), invite.temporary);
    try std.testing.expectEqualStrings("2026-06-01T00:00:00.000Z", invite.created_at.?);
}

test "cache parses application team from ready" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var ready = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"READY\",\"d\":{\"session_id\":\"abc\",\"application\":{\"id\":\"80\",\"name\":\"app\",\"team\":{\"id\":\"500\",\"name\":\"Core Team\",\"icon\":\"teamicon\",\"owner_user_id\":\"40\",\"members\":[{\"membership_state\":2,\"team_id\":\"500\",\"role\":\"admin\",\"user\":{\"id\":\"40\",\"username\":\"ada\"}}]}}}}",
    );
    defer ready.deinit();
    try cache.applyDispatch(ready);

    const team = cache.getCurrentApplication().?.team.?;
    try std.testing.expectEqual(@as(u64, 500), team.id.value);
    try std.testing.expectEqualStrings("Core Team", team.name);
    try std.testing.expectEqualStrings("teamicon", team.icon.?);
    try std.testing.expectEqual(@as(u64, 40), team.owner_user_id.value);
    try std.testing.expectEqual(@as(usize, 1), team.members.len);
    try std.testing.expectEqual(Types.MembershipState.accepted, team.members[0].membership_state);
    try std.testing.expectEqualStrings("admin", team.members[0].role.?);
    try std.testing.expectEqualStrings("ada", team.members[0].user.username);
}

test "cache exposes discord.js-style collections" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    try cache.putGuild(.{ .id = Snowflake.init(1), .name = "Alpha" });
    try cache.putGuild(.{ .id = Snowflake.init(2), .name = "Beta" });

    var guilds = try cache.collectGuilds(std.testing.allocator);
    defer guilds.deinit();
    try std.testing.expectEqual(@as(usize, 2), guilds.size());
    try std.testing.expect(guilds.has(1));
    try std.testing.expect(guilds.has(2));
    try std.testing.expectEqualStrings("Alpha", guilds.get(1).?.name);

    const Finder = struct {
        fn isBeta(_: void, _: u64, guild: Types.Guild) bool {
            return std.mem.eql(u8, guild.name, "Beta");
        }
    };
    try std.testing.expectEqual(@as(u64, 2), guilds.findKey({}, Finder.isBeta).?);

    var channels = try cache.collectChannels(std.testing.allocator);
    defer channels.deinit();
    try std.testing.expect(channels.isEmpty());
}

test "cache collects users and roles into collections" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    try cache.putUser(.{ .id = Snowflake.init(10), .username = "ada" });
    try cache.putUser(.{ .id = Snowflake.init(11), .username = "linus" });
    try cache.putRole(Snowflake.init(1), .{ .id = Snowflake.init(100), .name = "Admin" });
    try cache.putRole(Snowflake.init(1), .{ .id = Snowflake.init(101), .name = "Mod" });

    var users = try cache.collectUsers(std.testing.allocator);
    defer users.deinit();
    try std.testing.expectEqual(@as(usize, 2), users.size());
    try std.testing.expectEqualStrings("ada", users.get(10).?.username);

    var roles = try cache.collectRoles(std.testing.allocator);
    defer roles.deinit();
    try std.testing.expectEqual(@as(usize, 2), roles.size());
    try std.testing.expectEqualStrings("Admin", roles.get(100).?.name);
}
