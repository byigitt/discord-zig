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

test "cache hydrates current user from ready and updates it" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var ready = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"READY\",\"d\":{\"session_id\":\"abc\",\"user\":{\"id\":\"40\",\"username\":\"zigbot\",\"global_name\":\"Zig Bot\",\"bot\":true}}}",
    );
    defer ready.deinit();
    try cache.applyDispatch(ready);

    try std.testing.expectEqual(@as(u64, 40), cache.current_user_id.?.value);
    try std.testing.expectEqualStrings("zigbot", cache.getCurrentUser().?.username);
    try std.testing.expect(cache.getCurrentUser().?.bot);

    var update = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"USER_UPDATE\",\"d\":{\"id\":\"40\",\"username\":\"renamed\",\"global_name\":\"Renamed Bot\",\"bot\":true}}",
    );
    defer update.deinit();
    try cache.applyDispatch(update);

    try std.testing.expectEqualStrings("renamed", cache.getCurrentUser().?.username);
    try std.testing.expectEqualStrings("Renamed Bot", cache.getCurrentUser().?.global_name.?);
}

test "cache hydrates current application from ready" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var ready = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"READY\",\"d\":{\"session_id\":\"abc\",\"application\":{\"id\":\"80\",\"name\":\"discord.zig\",\"flags\":64}}}",
    );
    defer ready.deinit();
    try cache.applyDispatch(ready);

    try std.testing.expectEqual(@as(u64, 80), cache.getCurrentApplication().?.id.value);
    try std.testing.expectEqualStrings("discord.zig", cache.getCurrentApplication().?.name);
    try std.testing.expectEqual(@as(u32, 64), cache.getCurrentApplication().?.flags.?);

    var replacement = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"READY\",\"d\":{\"session_id\":\"def\",\"application\":{\"id\":\"81\",\"name\":\"renamed app\",\"description\":\"Updated\",\"event_webhooks_types\":[\"APPLICATION_AUTHORIZED\"]}}}",
    );
    defer replacement.deinit();
    try cache.applyDispatch(replacement);

    try std.testing.expectEqual(@as(u64, 81), cache.getCurrentApplication().?.id.value);
    try std.testing.expectEqualStrings("renamed app", cache.getCurrentApplication().?.name);
    try std.testing.expectEqualStrings("Updated", cache.getCurrentApplication().?.description);
    try std.testing.expectEqualStrings("APPLICATION_AUTHORIZED", cache.getCurrentApplication().?.event_webhooks_types[0]);
}

test "cache stats report collection sizes without list allocation" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var ready = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"READY\",\"d\":{\"session_id\":\"abc\",\"user\":{\"id\":\"1\",\"username\":\"bot\"},\"application\":{\"id\":\"2\",\"name\":\"app\"}}}",
    );
    defer ready.deinit();
    try cache.applyDispatch(ready);

    var guild = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"GUILD_CREATE\",\"d\":{\"id\":\"10\",\"name\":\"Guild\",\"channels\":[{\"id\":\"20\",\"type\":0,\"name\":\"general\"}],\"threads\":[{\"id\":\"21\",\"type\":11,\"parent_id\":\"20\",\"name\":\"thread\"}],\"members\":[{\"user\":{\"id\":\"30\",\"username\":\"member\"},\"roles\":[]}],\"roles\":[{\"id\":\"40\",\"name\":\"Role\",\"permissions\":\"0\"}],\"emojis\":[{\"id\":\"50\",\"name\":\"zig\"}],\"stickers\":[{\"id\":\"60\",\"name\":\"sticker\",\"description\":null,\"tags\":\"zig\",\"type\":2,\"format_type\":1}],\"guild_scheduled_events\":[{\"id\":\"70\",\"guild_id\":\"10\",\"name\":\"Launch\",\"scheduled_start_time\":\"2026-06-02T10:00:00.000Z\",\"privacy_level\":2,\"status\":1,\"entity_type\":3}],\"stage_instances\":[{\"id\":\"80\",\"guild_id\":\"10\",\"channel_id\":\"20\",\"topic\":\"Stage\",\"privacy_level\":2}],\"presences\":[{\"guild_id\":\"10\",\"user\":{\"id\":\"30\"},\"status\":\"online\",\"activities\":[]}],\"voice_states\":[{\"guild_id\":\"10\",\"channel_id\":\"20\",\"user_id\":\"30\",\"session_id\":\"voice\",\"deaf\":false,\"mute\":false,\"self_deaf\":false,\"self_mute\":false,\"self_video\":false,\"suppress\":false}]}}",
    );
    defer guild.deinit();
    try cache.applyDispatch(guild);

    var message = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"MESSAGE_CREATE\",\"d\":{\"id\":\"90\",\"channel_id\":\"20\",\"guild_id\":\"10\",\"content\":\"pong\",\"author\":{\"id\":\"1\",\"username\":\"bot\"}}}",
    );
    defer message.deinit();
    try cache.applyDispatch(message);

    var invite = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":4,\"t\":\"INVITE_CREATE\",\"d\":{\"code\":\"abc\",\"guild_id\":\"10\",\"channel_id\":\"20\"}}",
    );
    defer invite.deinit();
    try cache.applyDispatch(invite);

    const stats = cache.stats();
    try std.testing.expect(stats.current_user);
    try std.testing.expect(stats.current_application);
    try std.testing.expectEqual(@as(usize, 2), stats.users);
    try std.testing.expectEqual(@as(usize, 1), stats.guilds);
    try std.testing.expectEqual(@as(usize, 2), stats.channels);
    try std.testing.expectEqual(@as(usize, 1), stats.members);
    try std.testing.expectEqual(@as(usize, 1), stats.roles);
    try std.testing.expectEqual(@as(usize, 1), stats.emojis);
    try std.testing.expectEqual(@as(usize, 1), stats.stickers);
    try std.testing.expectEqual(@as(usize, 1), stats.scheduled_events);
    try std.testing.expectEqual(@as(usize, 1), stats.stage_instances);
    try std.testing.expectEqual(@as(usize, 1), stats.presences);
    try std.testing.expectEqual(@as(usize, 1), stats.voice_states);
    try std.testing.expectEqual(@as(usize, 1), stats.messages);
    try std.testing.expectEqual(@as(usize, 1), stats.invites);

    const guild_stats = cache.guildStats(Snowflake.init(10));
    try std.testing.expectEqual(@as(usize, 1), guild_stats.channels);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.threads);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.members);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.roles);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.emojis);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.stickers);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.scheduled_events);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.stage_instances);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.presences);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.voice_states);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.messages);
    try std.testing.expectEqual(@as(usize, 1), guild_stats.invites);

    const channel_stats = cache.channelStats(Snowflake.init(20));
    try std.testing.expectEqual(@as(usize, 1), channel_stats.threads);
    try std.testing.expectEqual(@as(usize, 1), channel_stats.invites);
    try std.testing.expectEqual(@as(usize, 1), channel_stats.voice_states);
    try std.testing.expectEqual(@as(usize, 1), channel_stats.messages);

    try std.testing.expect(cache.hasCurrentUser());
    try std.testing.expect(cache.hasCurrentApplication());
    try std.testing.expectEqual(@as(u64, 1), cache.currentUserId().?.value);
    try std.testing.expectEqual(@as(u64, 2), cache.currentApplicationId().?.value);
    try std.testing.expect(cache.hasUser(Snowflake.init(1)));
    try std.testing.expect(cache.hasGuild(Snowflake.init(10)));
    try std.testing.expect(cache.hasChannel(Snowflake.init(20)));
    try std.testing.expect(cache.hasChannel(Snowflake.init(21)));
    try std.testing.expect(cache.hasMember(Snowflake.init(10), Snowflake.init(30)));
    try std.testing.expect(cache.hasRole(Snowflake.init(10), Snowflake.init(40)));
    try std.testing.expect(cache.hasEmoji(Snowflake.init(10), Snowflake.init(50)));
    try std.testing.expect(cache.hasSticker(Snowflake.init(10), Snowflake.init(60)));
    try std.testing.expect(cache.hasScheduledEvent(Snowflake.init(10), Snowflake.init(70)));
    try std.testing.expect(cache.hasStageInstance(Snowflake.init(10), Snowflake.init(80)));
    try std.testing.expect(cache.hasPresence(Snowflake.init(10), Snowflake.init(30)));
    try std.testing.expect(cache.hasVoiceState(Snowflake.init(10), Snowflake.init(30)));
    try std.testing.expect(cache.hasMessage(Snowflake.init(90)));
    try std.testing.expect(cache.hasInvite("abc"));
    try std.testing.expect(!cache.hasMessage(Snowflake.init(91)));
    try std.testing.expect(!cache.hasInvite("missing"));

    cache.removeMessage(Snowflake.init(90));
    try std.testing.expect(!cache.hasMessage(Snowflake.init(90)));
    try std.testing.expectEqual(@as(usize, 0), cache.stats().messages);

    cache.removeInvite("abc");
    try std.testing.expect(!cache.hasInvite("abc"));
    try std.testing.expectEqual(@as(usize, 0), cache.stats().invites);

    cache.removeUser(Snowflake.init(1));
    try std.testing.expect(!cache.hasUser(Snowflake.init(1)));
    try std.testing.expect(!cache.hasCurrentUser());
    try std.testing.expect(cache.currentUserId() == null);

    cache.removeCurrentApplication();
    try std.testing.expect(!cache.hasCurrentApplication());
    try std.testing.expect(cache.currentApplicationId() == null);

    cache.clear();
    const cleared_stats = cache.stats();
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.users);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.guilds);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.channels);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.members);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.roles);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.emojis);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.stickers);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.scheduled_events);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.stage_instances);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.presences);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.voice_states);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.messages);
    try std.testing.expectEqual(@as(usize, 0), cleared_stats.invites);
}
