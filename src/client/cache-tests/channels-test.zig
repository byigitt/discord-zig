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

test "cache handles invite create delete and channel cleanup dispatches" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var create = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"INVITE_CREATE\",\"d\":{\"code\":\"abc123\",\"guild_id\":\"10\",\"channel_id\":\"20\"}}",
    );
    defer create.deinit();
    try cache.applyDispatch(create);

    const invite = cache.getInvite("abc123").?;
    try std.testing.expectEqualStrings("abc123", invite.code);
    try std.testing.expectEqual(@as(u64, 10), invite.guild_id.?.value);
    try std.testing.expectEqual(@as(u64, 20), invite.channel_id.?.value);

    var channel_delete = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"CHANNEL_DELETE\",\"d\":{\"id\":\"20\",\"type\":0,\"guild_id\":\"10\",\"name\":\"general\"}}",
    );
    defer channel_delete.deinit();
    try cache.applyDispatch(channel_delete);

    try std.testing.expect(cache.getInvite("abc123") == null);

    var recreate = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"INVITE_CREATE\",\"d\":{\"code\":\"abc123\",\"guild_id\":\"10\",\"channel_id\":\"30\"}}",
    );
    defer recreate.deinit();
    try cache.applyDispatch(recreate);

    var delete = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":4,\"t\":\"INVITE_DELETE\",\"d\":{\"code\":\"abc123\",\"guild_id\":\"10\",\"channel_id\":\"30\"}}",
    );
    defer delete.deinit();
    try cache.applyDispatch(delete);

    try std.testing.expect(cache.getInvite("abc123") == null);
}

test "cache handles guild member add update and remove dispatches" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    try cache.putGuild(.{ .id = Snowflake.init(10), .name = "Guild", .approximate_member_count = 5 });
    try cache.putGuild(.{ .id = Snowflake.init(11), .name = "Unknown count" });

    var add = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"GUILD_MEMBER_ADD\",\"d\":{\"guild_id\":\"10\",\"user\":{\"id\":\"30\",\"username\":\"member\"},\"nick\":\"old\",\"roles\":[\"40\"],\"joined_at\":\"2026-06-02T00:00:00.000Z\",\"flags\":4,\"permissions\":\"8192\"}}",
    );
    defer add.deinit();
    try cache.applyDispatch(add);

    const added = cache.getMember(Snowflake.init(10), Snowflake.init(30)).?;
    try std.testing.expectEqualStrings("old", added.nick.?);
    try std.testing.expectEqual(@as(u64, 4), added.flags);
    try std.testing.expectEqual(@as(u64, 8192), added.permissions);
    try std.testing.expectEqual(@as(u32, 6), cache.getGuild(Snowflake.init(10)).?.approximate_member_count.?);

    var unknown_count_add = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"GUILD_MEMBER_ADD\",\"d\":{\"guild_id\":\"11\",\"user\":{\"id\":\"31\",\"username\":\"unknown\"},\"roles\":[]}}",
    );
    defer unknown_count_add.deinit();
    try cache.applyDispatch(unknown_count_add);

    try std.testing.expect(cache.getGuild(Snowflake.init(11)).?.approximate_member_count == null);

    var update = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"GUILD_MEMBER_UPDATE\",\"d\":{\"guild_id\":\"10\",\"user\":{\"id\":\"30\",\"username\":\"member\"},\"nick\":\"new\",\"avatar\":\"updated_avatar\",\"roles\":[\"40\",\"50\"],\"joined_at\":\"2026-06-02T00:00:00.000Z\",\"premium_since\":null,\"deaf\":false,\"mute\":true,\"pending\":false,\"communication_disabled_until\":\"2026-06-05T00:00:00.000Z\",\"flags\":8,\"permissions\":16384}}",
    );
    defer update.deinit();
    try cache.applyDispatch(update);

    const updated = cache.getMember(Snowflake.init(10), Snowflake.init(30)).?;
    try std.testing.expectEqualStrings("new", updated.nick.?);
    try std.testing.expectEqualStrings("updated_avatar", updated.avatar.?);
    try std.testing.expectEqual(@as(usize, 2), updated.roles.len);
    try std.testing.expectEqual(@as(u64, 50), updated.roles[1].value);
    try std.testing.expect(updated.premium_since == null);
    try std.testing.expect(!updated.deaf);
    try std.testing.expect(updated.mute);
    try std.testing.expect(!updated.pending);
    try std.testing.expectEqualStrings("2026-06-05T00:00:00.000Z", updated.communication_disabled_until.?);
    try std.testing.expectEqual(@as(u64, 8), updated.flags);
    try std.testing.expectEqual(@as(u64, 16384), updated.permissions);
    try std.testing.expectEqual(@as(u32, 6), cache.getGuild(Snowflake.init(10)).?.approximate_member_count.?);

    try cache.putPresence(.{ .guild_id = Snowflake.init(10), .user_id = Snowflake.init(30), .status = "online" });
    try cache.putVoiceState(.{
        .guild_id = Snowflake.init(10),
        .channel_id = Snowflake.init(20),
        .user_id = Snowflake.init(30),
        .session_id = "voice-session",
    });

    var remove = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":4,\"t\":\"GUILD_MEMBER_REMOVE\",\"d\":{\"guild_id\":\"10\",\"user\":{\"id\":\"30\",\"username\":\"member\"}}}",
    );
    defer remove.deinit();
    try cache.applyDispatch(remove);

    try std.testing.expect(cache.getMember(Snowflake.init(10), Snowflake.init(30)) == null);
    try std.testing.expect(cache.getPresence(Snowflake.init(10), Snowflake.init(30)) == null);
    try std.testing.expect(cache.getVoiceState(Snowflake.init(10), Snowflake.init(30)) == null);
    try std.testing.expect(cache.getUser(Snowflake.init(30)) != null);
    try std.testing.expectEqual(@as(u32, 5), cache.getGuild(Snowflake.init(10)).?.approximate_member_count.?);

    cache.guilds.getPtr(Snowflake.init(10).value).?.approximate_member_count = 0;
    var zero_count_remove = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":5,\"t\":\"GUILD_MEMBER_REMOVE\",\"d\":{\"guild_id\":\"10\",\"user\":{\"id\":\"32\",\"username\":\"zero\"}}}",
    );
    defer zero_count_remove.deinit();
    try cache.applyDispatch(zero_count_remove);

    try std.testing.expectEqual(@as(u32, 0), cache.getGuild(Snowflake.init(10)).?.approximate_member_count.?);
}

test "cache handles channel create update and delete dispatches" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var create = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"CHANNEL_CREATE\",\"d\":{\"id\":\"20\",\"type\":15,\"guild_id\":\"10\",\"name\":\"general\",\"topic\":\"Project chat\",\"status\":\"Standup\",\"voice_start_time\":1780000000,\"last_message_id\":\"100\",\"last_pin_timestamp\":\"2026-06-02T00:00:00.000Z\",\"parent_id\":\"30\",\"owner_id\":\"40\",\"application_id\":\"50\",\"position\":2,\"nsfw\":true,\"rate_limit_per_user\":5,\"bitrate\":64000,\"user_limit\":25,\"rtc_region\":\"europe\",\"video_quality_mode\":2,\"message_count\":12,\"member_count\":4,\"managed\":true,\"flags\":16,\"permission_overwrites\":[{\"id\":\"90\",\"type\":0,\"allow\":\"1024\",\"deny\":\"2048\"},{\"id\":\"91\",\"type\":1,\"allow\":4096,\"deny\":8192}],\"available_tags\":[{\"id\":\"70\",\"name\":\"Help\",\"moderated\":true,\"emoji_id\":\"80\",\"emoji_name\":null},{\"id\":\"71\",\"name\":\"Ship\",\"moderated\":false,\"emoji_id\":null,\"emoji_name\":\"🚀\"}],\"default_reaction_emoji\":{\"emoji_id\":null,\"emoji_name\":\"👋\"},\"default_thread_rate_limit_per_user\":30,\"default_sort_order\":1,\"default_forum_layout\":2}}",
    );
    defer create.deinit();
    try cache.applyDispatch(create);

    const created = cache.getChannel(Snowflake.init(20)).?;
    try std.testing.expectEqual(Types.ChannelType.guild_forum, created.type);
    try std.testing.expectEqual(@as(u64, 10), created.guild_id.?.value);
    try std.testing.expectEqualStrings("general", created.name.?);
    try std.testing.expectEqualStrings("Project chat", created.topic.?);
    try std.testing.expectEqualStrings("Standup", created.status.?);
    try std.testing.expectEqual(@as(i64, 1780000000), created.voice_start_time.?);
    try std.testing.expectEqual(@as(u64, 100), created.last_message_id.?.value);
    try std.testing.expectEqualStrings("2026-06-02T00:00:00.000Z", created.last_pin_timestamp.?);
    try std.testing.expectEqual(@as(u64, 30), created.parent_id.?.value);
    try std.testing.expectEqual(@as(u64, 40), created.owner_id.?.value);
    try std.testing.expectEqual(@as(u64, 50), created.application_id.?.value);
    try std.testing.expectEqual(@as(i32, 2), created.position.?);
    try std.testing.expect(created.nsfw);
    try std.testing.expectEqual(@as(u16, 5), created.rate_limit_per_user.?);
    try std.testing.expectEqual(@as(u32, 64000), created.bitrate.?);
    try std.testing.expectEqual(@as(u16, 25), created.user_limit.?);
    try std.testing.expectEqualStrings("europe", created.rtc_region.?);
    try std.testing.expectEqual(@as(u8, 2), created.video_quality_mode.?);
    try std.testing.expectEqual(@as(u32, 12), created.message_count.?);
    try std.testing.expectEqual(@as(u32, 4), created.member_count.?);
    try std.testing.expect(created.managed);
    try std.testing.expectEqual(Types.ChannelFlags.require_tag, created.flags.?);
    try std.testing.expectEqual(@as(usize, 2), created.permission_overwrites.len);
    try std.testing.expectEqual(@as(u64, 90), created.permission_overwrites[0].id.value);
    try std.testing.expectEqual(Types.PermissionOverwriteType.role, created.permission_overwrites[0].type);
    try std.testing.expectEqual(@as(u64, 1024), created.permission_overwrites[0].allow);
    try std.testing.expectEqual(@as(u64, 2048), created.permission_overwrites[0].deny);
    try std.testing.expectEqual(@as(u64, 91), created.permission_overwrites[1].id.value);
    try std.testing.expectEqual(Types.PermissionOverwriteType.member, created.permission_overwrites[1].type);
    try std.testing.expectEqual(@as(u64, 4096), created.permission_overwrites[1].allow);
    try std.testing.expectEqual(@as(u64, 8192), created.permission_overwrites[1].deny);
    try std.testing.expectEqual(@as(usize, 2), created.available_tags.len);
    try std.testing.expectEqual(@as(u64, 70), created.available_tags[0].id.value);
    try std.testing.expectEqualStrings("Help", created.available_tags[0].name);
    try std.testing.expect(created.available_tags[0].moderated);
    try std.testing.expectEqual(@as(u64, 80), created.available_tags[0].emoji_id.?.value);
    try std.testing.expect(created.available_tags[0].emoji_name == null);
    try std.testing.expectEqual(@as(u64, 71), created.available_tags[1].id.value);
    try std.testing.expectEqualStrings("Ship", created.available_tags[1].name);
    try std.testing.expect(!created.available_tags[1].moderated);
    try std.testing.expect(created.available_tags[1].emoji_id == null);
    try std.testing.expectEqualStrings("🚀", created.available_tags[1].emoji_name.?);
    try std.testing.expect(created.default_reaction_emoji.?.emoji_id == null);
    try std.testing.expectEqualStrings("👋", created.default_reaction_emoji.?.emoji_name.?);
    try std.testing.expectEqual(@as(u16, 30), created.default_thread_rate_limit_per_user.?);
    try std.testing.expectEqual(Types.ChannelSortOrder.creation_date, created.default_sort_order.?);
    try std.testing.expectEqual(Types.ForumLayout.gallery_view, created.default_forum_layout.?);

    var update = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"CHANNEL_UPDATE\",\"d\":{\"id\":\"20\",\"type\":15,\"guild_id\":\"10\",\"name\":\"announcements\",\"topic\":null,\"status\":null,\"voice_start_time\":null,\"last_message_id\":null,\"last_pin_timestamp\":null,\"parent_id\":null,\"owner_id\":null,\"application_id\":null,\"position\":3,\"nsfw\":false,\"rate_limit_per_user\":0,\"bitrate\":96000,\"user_limit\":0,\"rtc_region\":null,\"video_quality_mode\":1,\"message_count\":13,\"member_count\":5,\"managed\":false,\"flags\":32768,\"permission_overwrites\":[],\"available_tags\":[],\"default_reaction_emoji\":{\"emoji_id\":\"81\",\"emoji_name\":null},\"default_thread_rate_limit_per_user\":0,\"default_sort_order\":0,\"default_forum_layout\":1}}",
    );
    defer update.deinit();
    try cache.applyDispatch(update);

    const updated = cache.getChannel(Snowflake.init(20)).?;
    try std.testing.expectEqualStrings("announcements", updated.name.?);
    try std.testing.expect(updated.topic == null);
    try std.testing.expect(updated.status == null);
    try std.testing.expect(updated.voice_start_time == null);
    try std.testing.expect(updated.last_message_id == null);
    try std.testing.expect(updated.last_pin_timestamp == null);
    try std.testing.expect(updated.parent_id == null);
    try std.testing.expect(updated.owner_id == null);
    try std.testing.expect(updated.application_id == null);
    try std.testing.expectEqual(@as(i32, 3), updated.position.?);
    try std.testing.expect(!updated.nsfw);
    try std.testing.expectEqual(@as(u16, 0), updated.rate_limit_per_user.?);
    try std.testing.expectEqual(@as(u32, 96000), updated.bitrate.?);
    try std.testing.expectEqual(@as(u16, 0), updated.user_limit.?);
    try std.testing.expect(updated.rtc_region == null);
    try std.testing.expectEqual(@as(u8, 1), updated.video_quality_mode.?);
    try std.testing.expectEqual(@as(u32, 13), updated.message_count.?);
    try std.testing.expectEqual(@as(u32, 5), updated.member_count.?);
    try std.testing.expect(!updated.managed);
    try std.testing.expectEqual(Types.ChannelFlags.hide_media_download_options, updated.flags.?);
    try std.testing.expectEqual(@as(usize, 0), updated.permission_overwrites.len);
    try std.testing.expectEqual(@as(usize, 0), updated.available_tags.len);
    try std.testing.expectEqual(@as(u64, 81), updated.default_reaction_emoji.?.emoji_id.?.value);
    try std.testing.expect(updated.default_reaction_emoji.?.emoji_name == null);
    try std.testing.expectEqual(@as(u16, 0), updated.default_thread_rate_limit_per_user.?);
    try std.testing.expectEqual(Types.ChannelSortOrder.latest_activity, updated.default_sort_order.?);
    try std.testing.expectEqual(Types.ForumLayout.list_view, updated.default_forum_layout.?);

    try cache.putChannel(.{ .id = Snowflake.init(30), .type = .public_thread, .guild_id = Snowflake.init(10), .parent_id = Snowflake.init(20), .name = "child-thread" });
    try cache.putChannel(.{ .id = Snowflake.init(31), .type = .public_thread, .guild_id = Snowflake.init(10), .parent_id = Snowflake.init(21), .name = "other-thread" });
    try cache.putMessage(.{ .id = Snowflake.init(200), .channel_id = Snowflake.init(20), .author = .{ .id = Snowflake.init(40), .username = "bot" }, .content = "parent" });
    try cache.putMessage(.{ .id = Snowflake.init(201), .channel_id = Snowflake.init(30), .author = .{ .id = Snowflake.init(40), .username = "bot" }, .content = "child" });
    try cache.putMessage(.{ .id = Snowflake.init(202), .channel_id = Snowflake.init(31), .author = .{ .id = Snowflake.init(40), .username = "bot" }, .content = "other" });
    try cache.putVoiceState(.{
        .guild_id = Snowflake.init(10),
        .channel_id = Snowflake.init(20),
        .user_id = Snowflake.init(40),
        .session_id = "parent-voice",
    });
    try cache.putVoiceState(.{
        .guild_id = Snowflake.init(10),
        .channel_id = Snowflake.init(30),
        .user_id = Snowflake.init(41),
        .session_id = "thread-voice",
    });
    try cache.putVoiceState(.{
        .guild_id = Snowflake.init(10),
        .channel_id = Snowflake.init(31),
        .user_id = Snowflake.init(42),
        .session_id = "other-voice",
    });

    var delete = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"CHANNEL_DELETE\",\"d\":{\"id\":\"20\",\"type\":0,\"guild_id\":\"10\",\"name\":\"announcements\"}}",
    );
    defer delete.deinit();
    try cache.applyDispatch(delete);

    try std.testing.expect(cache.getChannel(Snowflake.init(20)) == null);
    try std.testing.expect(cache.getChannel(Snowflake.init(30)) == null);
    try std.testing.expect(cache.getChannel(Snowflake.init(31)) != null);
    try std.testing.expect(cache.getMessage(Snowflake.init(200)) == null);
    try std.testing.expect(cache.getMessage(Snowflake.init(201)) == null);
    try std.testing.expect(cache.getMessage(Snowflake.init(202)) != null);
    try std.testing.expectEqual(@as(usize, 1), cache.messageCount());
    try std.testing.expect(cache.getVoiceState(Snowflake.init(10), Snowflake.init(40)) == null);
    try std.testing.expect(cache.getVoiceState(Snowflake.init(10), Snowflake.init(41)) == null);
    try std.testing.expectEqualStrings(
        "other-voice",
        cache.getVoiceState(Snowflake.init(10), Snowflake.init(42)).?.session_id,
    );

    const deleted_channel_messages = try cache.listChannelMessages(std.testing.allocator, Snowflake.init(20));
    defer std.testing.allocator.free(deleted_channel_messages);
    try std.testing.expectEqual(@as(usize, 0), deleted_channel_messages.len);

    const kept_thread_messages = try cache.listChannelMessages(std.testing.allocator, Snowflake.init(31));
    defer std.testing.allocator.free(kept_thread_messages);
    try std.testing.expectEqual(@as(usize, 1), kept_thread_messages.len);
    try std.testing.expectEqualStrings("other", kept_thread_messages[0].content);
}

test "cache updates channel pin timestamp dispatch" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    try cache.putChannel(.{ .id = Snowflake.init(20), .type = .guild_text, .guild_id = Snowflake.init(10), .name = "general" });

    var set_pins = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"CHANNEL_PINS_UPDATE\",\"d\":{\"guild_id\":\"10\",\"channel_id\":\"20\",\"last_pin_timestamp\":\"2026-06-02T00:00:00.000Z\"}}",
    );
    defer set_pins.deinit();
    try cache.applyDispatch(set_pins);

    try std.testing.expectEqualStrings(
        "2026-06-02T00:00:00.000Z",
        cache.getChannel(Snowflake.init(20)).?.last_pin_timestamp.?,
    );

    var clear_pins = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"CHANNEL_PINS_UPDATE\",\"d\":{\"guild_id\":\"10\",\"channel_id\":\"20\",\"last_pin_timestamp\":null}}",
    );
    defer clear_pins.deinit();
    try cache.applyDispatch(clear_pins);

    try std.testing.expect(cache.getChannel(Snowflake.init(20)).?.last_pin_timestamp == null);

    var unknown_channel = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"CHANNEL_PINS_UPDATE\",\"d\":{\"guild_id\":\"10\",\"channel_id\":\"21\",\"last_pin_timestamp\":\"2026-06-02T01:00:00.000Z\"}}",
    );
    defer unknown_channel.deinit();
    try cache.applyDispatch(unknown_channel);

    try std.testing.expect(cache.getChannel(Snowflake.init(21)) == null);
}
