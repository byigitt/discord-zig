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

test "cache stores message create dispatch" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var dispatch = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"MESSAGE_CREATE\",\"d\":{\"id\":\"10\",\"channel_id\":\"20\",\"guild_id\":\"30\",\"message_reference\":{\"type\":0,\"message_id\":\"8\",\"channel_id\":\"20\",\"guild_id\":\"30\"},\"referenced_message\":{\"id\":\"8\",\"channel_id\":\"20\",\"content\":\"source\",\"author\":{\"id\":\"40\",\"username\":\"bot\"}},\"message_snapshots\":[{\"message\":{\"type\":0,\"content\":\"forwarded text\",\"timestamp\":\"2026-06-01T23:59:00.000Z\",\"edited_timestamp\":null,\"flags\":16384,\"mentions\":[{\"id\":\"95\",\"username\":\"snapshot_user\"}],\"mention_roles\":[\"96\"],\"embeds\":[{\"title\":\"Snapshot\"}],\"attachments\":[{\"id\":\"97\",\"filename\":\"snapshot.txt\",\"content_type\":\"text/plain\",\"size\":5,\"url\":\"https://cdn.example/snapshot.txt\",\"proxy_url\":\"https://proxy.example/snapshot.txt\"}],\"components\":[{\"type\":1,\"components\":[{\"type\":2,\"style\":1,\"custom_id\":\"snapshot_button\",\"label\":\"Open\"}]}]}}],\"thread\":{\"id\":\"44\",\"guild_id\":\"30\",\"type\":11,\"name\":\"message-thread\",\"parent_id\":\"20\",\"position\":2,\"rate_limit_per_user\":5},\"call\":{\"participants\":[\"40\",\"41\"],\"ended_timestamp\":null},\"role_subscription_data\":{\"role_subscription_listing_id\":\"72\",\"tier_name\":\"Founders\",\"total_months_subscribed\":14,\"is_renewal\":true},\"shared_client_theme\":{\"colors\":[\"5865F2\",\"E558F2\"],\"gradient_angle\":45,\"base_mix\":58,\"base_theme\":1},\"webhook_id\":\"70\",\"application_id\":\"80\",\"application\":{\"id\":\"80\",\"name\":\"helper app\",\"icon\":\"app_icon\",\"description\":\"message app\",\"bot_public\":false,\"bot_require_code_grant\":true,\"bot\":{\"id\":\"92\",\"username\":\"app_bot\"},\"owner\":{\"id\":\"93\",\"username\":\"app_owner\"},\"verify_key\":\"verify\",\"guild_id\":\"30\",\"flags\":64,\"approximate_guild_count\":7,\"approximate_user_install_count\":11,\"interactions_endpoint_url\":\"https://example.com/interactions\",\"role_connections_verification_url\":\"https://example.com/roles\",\"event_webhooks_url\":\"https://example.com/events\",\"event_webhooks_status\":2,\"event_webhooks_types\":[\"APPLICATION_AUTHORIZED\"],\"tags\":[\"utility\",\"zig\"],\"custom_install_url\":\"https://example.com/install\"},\"activity\":{\"type\":1,\"party_id\":\"party-42\"},\"interaction_metadata\":{\"id\":\"81\",\"type\":2,\"user\":{\"id\":\"82\",\"username\":\"commander\"},\"original_response_message_id\":\"10\",\"target_user\":{\"id\":\"83\",\"username\":\"target\"},\"target_message_id\":\"84\"},\"type\":0,\"nonce\":\"client-123\",\"content\":\"pong\",\"timestamp\":\"2026-06-02T00:00:00.000000+00:00\",\"edited_timestamp\":null,\"tts\":true,\"mention_everyone\":true,\"pinned\":false,\"position\":5,\"flags\":64,\"author\":{\"id\":\"40\",\"username\":\"bot\",\"avatar\":\"user_avatar\",\"banner\":\"user_banner\",\"bot\":true,\"system\":false,\"mfa_enabled\":true,\"accent_color\":5793266,\"locale\":\"en-US\",\"verified\":true,\"email\":\"bot@example.com\",\"flags\":64,\"public_flags\":131072},\"member\":{\"nick\":\"zig bot\",\"avatar\":\"member_avatar\",\"roles\":[\"42\"],\"joined_at\":\"2026-06-01T00:00:00.000Z\",\"premium_since\":\"2026-06-02T00:00:00.000Z\",\"deaf\":false,\"mute\":true,\"pending\":false,\"communication_disabled_until\":\"2026-06-03T00:00:00.000Z\",\"flags\":1,\"permissions\":\"2048\"},\"mentions\":[{\"id\":\"41\",\"username\":\"alice\",\"global_name\":\"Alice\",\"avatar\":\"alice_avatar\"}],\"mention_roles\":[\"42\"],\"mention_channels\":[{\"id\":\"43\",\"guild_id\":\"30\",\"type\":0,\"name\":\"general\"}],\"embeds\":[{\"title\":\"Status\",\"description\":\"All green\",\"url\":\"https://example.com\",\"timestamp\":\"2026-06-02T00:00:00.000Z\",\"color\":5793266,\"footer\":{\"text\":\"v0.1\",\"icon_url\":\"https://example.com/footer.png\"},\"image\":{\"url\":\"https://example.com/image.png\"},\"thumbnail\":{\"url\":\"https://example.com/thumb.png\"},\"author\":{\"name\":\"Deploys\",\"url\":\"https://example.com/deploys\",\"icon_url\":\"https://example.com/author.png\"},\"fields\":[{\"name\":\"Runtime\",\"value\":\"Zig\",\"inline\":true}]}],\"attachments\":[{\"id\":\"50\",\"filename\":\"report.txt\",\"description\":\"daily report\",\"content_type\":\"text/plain\",\"size\":12,\"url\":\"https://cdn.example/report.txt\",\"proxy_url\":\"https://proxy.example/report.txt\",\"height\":null,\"width\":null,\"ephemeral\":true}],\"sticker_items\":[{\"id\":\"60\",\"name\":\"ziggy\",\"format_type\":1}],\"stickers\":[{\"id\":\"90\",\"name\":\"full_ziggy\",\"description\":\"full sticker\",\"tags\":\"zig\",\"type\":2,\"format_type\":1,\"available\":true,\"guild_id\":\"30\",\"user\":{\"id\":\"91\",\"username\":\"sticker_artist\"},\"sort_value\":4}],\"components\":[{\"type\":1,\"components\":[{\"type\":2,\"style\":3,\"custom_id\":\"confirm\",\"label\":\"Confirm\",\"disabled\":true}]}],\"poll\":{\"question\":{\"text\":\"Runtime?\"},\"answers\":[{\"answer_id\":1,\"poll_media\":{\"text\":\"Zig\",\"emoji\":{\"name\":\"⚡\"}}}],\"expiry\":\"2026-06-03T00:00:00.000Z\",\"allow_multiselect\":true,\"layout_type\":1,\"results\":{\"is_finalized\":false,\"answer_counts\":[{\"id\":1,\"count\":3,\"me_voted\":true}]}},\"reactions\":[{\"count\":2,\"count_details\":{\"burst\":1,\"normal\":1},\"me\":true,\"me_burst\":true,\"burst_colors\":[\"#5865F2\",\"#E558F2\"],\"emoji\":{\"id\":null,\"name\":\"👍\"}}]}}",
    );
    defer dispatch.deinit();

    try cache.applyDispatch(dispatch);

    const message = cache.getMessage(Snowflake.init(10)).?;
    try std.testing.expectEqual(@as(u64, 20), message.channel_id.value);
    try std.testing.expectEqual(Types.MessageReferenceType.default, message.message_reference.?.type.?);
    try std.testing.expectEqual(@as(u64, 8), message.message_reference.?.message_id.?.value);
    try std.testing.expectEqual(@as(u64, 20), message.message_reference.?.channel_id.?.value);
    try std.testing.expectEqual(@as(u64, 30), message.message_reference.?.guild_id.?.value);
    try std.testing.expectEqual(@as(u64, 8), message.referenced_message_id.?.value);
    try std.testing.expectEqual(@as(usize, 1), message.message_snapshots.len);
    try std.testing.expectEqualStrings("forwarded text", message.message_snapshots[0].content);
    try std.testing.expectEqualStrings("2026-06-01T23:59:00.000Z", message.message_snapshots[0].timestamp.?);
    try std.testing.expect(message.message_snapshots[0].edited_timestamp == null);
    try std.testing.expectEqual(@as(u32, 16384), message.message_snapshots[0].flags.?);
    try std.testing.expectEqualStrings("snapshot_user", message.message_snapshots[0].mentions[0].username);
    try std.testing.expectEqual(@as(u64, 96), message.message_snapshots[0].mention_roles[0].value);
    try std.testing.expectEqualStrings("Snapshot", message.message_snapshots[0].embeds[0].title.?);
    try std.testing.expectEqualStrings("snapshot.txt", message.message_snapshots[0].attachments[0].filename);
    try std.testing.expectEqualStrings("snapshot_button", message.message_snapshots[0].components[0].action_row[0].button.custom_id.?);
    try std.testing.expectEqualStrings("snapshot_user", cache.getUser(Snowflake.init(95)).?.username);
    try std.testing.expectEqual(@as(u64, 44), message.thread.?.id.value);
    try std.testing.expectEqual(Types.ChannelType.public_thread, message.thread.?.type);
    try std.testing.expectEqualStrings("message-thread", message.thread.?.name.?);
    try std.testing.expectEqual(@as(u64, 20), message.thread.?.parent_id.?.value);
    try std.testing.expectEqualStrings("message-thread", cache.getChannel(Snowflake.init(44)).?.name.?);
    try std.testing.expectEqual(@as(usize, 2), message.call.?.participants.len);
    try std.testing.expectEqual(@as(u64, 40), message.call.?.participants[0].value);
    try std.testing.expect(message.call.?.ended_timestamp == null);
    try std.testing.expectEqual(@as(u64, 72), message.role_subscription_data.?.role_subscription_listing_id.value);
    try std.testing.expectEqualStrings("Founders", message.role_subscription_data.?.tier_name);
    try std.testing.expectEqual(@as(u32, 14), message.role_subscription_data.?.total_months_subscribed);
    try std.testing.expect(message.role_subscription_data.?.is_renewal);
    try std.testing.expectEqual(@as(usize, 2), message.shared_client_theme.?.colors.len);
    try std.testing.expectEqualStrings("5865F2", message.shared_client_theme.?.colors[0]);
    try std.testing.expectEqual(@as(u16, 45), message.shared_client_theme.?.gradient_angle);
    try std.testing.expectEqual(@as(u8, 58), message.shared_client_theme.?.base_mix);
    try std.testing.expectEqual(Types.SharedClientThemeBase.dark, message.shared_client_theme.?.base_theme.?);
    try std.testing.expectEqual(@as(u64, 70), message.webhook_id.?.value);
    try std.testing.expectEqual(@as(u64, 80), message.application_id.?.value);
    try std.testing.expectEqualStrings("helper app", message.application.?.name);
    try std.testing.expectEqualStrings("app_icon", message.application.?.icon.?);
    try std.testing.expectEqualStrings("message app", message.application.?.description);
    try std.testing.expect(!message.application.?.bot_public);
    try std.testing.expect(message.application.?.bot_require_code_grant);
    try std.testing.expectEqualStrings("app_bot", message.application.?.bot.?.username);
    try std.testing.expectEqualStrings("app_owner", message.application.?.owner.?.username);
    try std.testing.expectEqualStrings("verify", message.application.?.verify_key);
    try std.testing.expectEqual(@as(u64, 30), message.application.?.guild_id.?.value);
    try std.testing.expectEqual(@as(u32, 64), message.application.?.flags.?);
    try std.testing.expectEqual(@as(u32, 7), message.application.?.approximate_guild_count.?);
    try std.testing.expectEqual(@as(u32, 11), message.application.?.approximate_user_install_count.?);
    try std.testing.expectEqualStrings("https://example.com/interactions", message.application.?.interactions_endpoint_url.?);
    try std.testing.expectEqualStrings("https://example.com/roles", message.application.?.role_connections_verification_url.?);
    try std.testing.expectEqualStrings("https://example.com/events", message.application.?.event_webhooks_url.?);
    try std.testing.expectEqual(Types.ApplicationEventWebhookStatus.enabled, message.application.?.event_webhooks_status.?);
    try std.testing.expectEqualStrings("APPLICATION_AUTHORIZED", message.application.?.event_webhooks_types[0]);
    try std.testing.expectEqualStrings("utility", message.application.?.tags[0]);
    try std.testing.expectEqualStrings("https://example.com/install", message.application.?.custom_install_url.?);
    try std.testing.expectEqualStrings("app_bot", cache.getUser(Snowflake.init(92)).?.username);
    try std.testing.expectEqualStrings("app_owner", cache.getUser(Snowflake.init(93)).?.username);
    try std.testing.expectEqual(Types.MessageActivityType.join, message.activity.?.type);
    try std.testing.expectEqualStrings("party-42", message.activity.?.party_id.?);
    try std.testing.expectEqual(@as(u64, 81), message.interaction_metadata.?.id.value);
    try std.testing.expectEqual(Interactions.InteractionType.application_command, message.interaction_metadata.?.type);
    try std.testing.expectEqualStrings("commander", message.interaction_metadata.?.user.username);
    try std.testing.expectEqual(@as(u64, 10), message.interaction_metadata.?.original_response_message_id.?.value);
    try std.testing.expectEqualStrings("target", message.interaction_metadata.?.target_user.?.username);
    try std.testing.expectEqual(@as(u64, 84), message.interaction_metadata.?.target_message_id.?.value);
    try std.testing.expectEqualStrings("commander", cache.getUser(Snowflake.init(82)).?.username);
    try std.testing.expectEqual(@as(u8, 0), message.type);
    try std.testing.expectEqualStrings("client-123", message.nonce.?);
    try std.testing.expectEqualStrings("pong", message.content);
    try std.testing.expect(message.edited_timestamp == null);
    try std.testing.expect(message.tts);
    try std.testing.expect(message.mention_everyone);
    try std.testing.expect(!message.pinned);
    try std.testing.expectEqual(@as(i32, 5), message.position.?);
    try std.testing.expectEqual(@as(u32, 64), message.flags.?);
    try std.testing.expectEqual(@as(usize, 1), message.mentions.len);
    try std.testing.expectEqualStrings("alice", message.mentions[0].username);
    try std.testing.expectEqualStrings("Alice", message.mentions[0].global_name.?);
    try std.testing.expectEqual(@as(usize, 1), message.mention_roles.len);
    try std.testing.expectEqual(@as(u64, 42), message.mention_roles[0].value);
    try std.testing.expectEqual(@as(usize, 1), message.mention_channels.len);
    try std.testing.expectEqual(@as(u64, 43), message.mention_channels[0].id.value);
    try std.testing.expectEqualStrings("general", message.mention_channels[0].name.?);
    try std.testing.expectEqual(@as(usize, 1), message.embeds.len);
    try std.testing.expectEqualStrings("Status", message.embeds[0].title.?);
    try std.testing.expectEqualStrings("All green", message.embeds[0].description.?);
    try std.testing.expectEqualStrings("https://example.com", message.embeds[0].url.?);
    try std.testing.expectEqual(@as(u24, 5793266), message.embeds[0].color.?);
    try std.testing.expectEqualStrings("v0.1", message.embeds[0].footer.?.text);
    try std.testing.expectEqualStrings("https://example.com/image.png", message.embeds[0].image.?.url);
    try std.testing.expectEqualStrings("https://example.com/thumb.png", message.embeds[0].thumbnail.?.url);
    try std.testing.expectEqualStrings("Deploys", message.embeds[0].author.?.name);
    try std.testing.expectEqual(@as(usize, 1), message.embeds[0].fields.len);
    try std.testing.expectEqualStrings("Runtime", message.embeds[0].fields[0].name);
    try std.testing.expect(message.embeds[0].fields[0].is_inline);
    try std.testing.expectEqualStrings("bot", message.author.?.username);
    try std.testing.expectEqualStrings("user_avatar", message.author.?.avatar.?);
    const cached_author = cache.getUser(Snowflake.init(40)).?;
    try std.testing.expectEqualStrings("user_banner", cached_author.banner.?);
    try std.testing.expect(cached_author.mfa_enabled.?);
    try std.testing.expectEqual(@as(u32, 5793266), cached_author.accent_color.?);
    try std.testing.expectEqualStrings("en-US", cached_author.locale.?);
    try std.testing.expect(cached_author.verified.?);
    try std.testing.expectEqualStrings("bot@example.com", cached_author.email.?);
    try std.testing.expectEqual(@as(u32, 64), cached_author.flags.?);
    try std.testing.expectEqual(@as(u32, 131072), cached_author.public_flags.?);
    try std.testing.expectEqualStrings("zig bot", message.member.?.nick.?);
    try std.testing.expectEqualStrings("member_avatar", message.member.?.avatar.?);
    try std.testing.expectEqualStrings("bot", message.member.?.user.?.username);
    try std.testing.expectEqual(@as(u64, 42), message.member.?.roles[0].value);
    try std.testing.expectEqualStrings("2026-06-02T00:00:00.000Z", message.member.?.premium_since.?);
    try std.testing.expect(message.member.?.mute);
    try std.testing.expectEqualStrings("2026-06-03T00:00:00.000Z", message.member.?.communication_disabled_until.?);
    try std.testing.expectEqual(@as(u64, 1), message.member.?.flags);
    try std.testing.expectEqual(@as(u64, 2048), message.member.?.permissions);
    try std.testing.expectEqualStrings("zig bot", cache.getMember(Snowflake.init(30), Snowflake.init(40)).?.nick.?);
    try std.testing.expectEqual(@as(usize, 1), message.attachments.len);
    try std.testing.expectEqual(@as(u64, 50), message.attachments[0].id.value);
    try std.testing.expectEqualStrings("report.txt", message.attachments[0].filename);
    try std.testing.expectEqualStrings("daily report", message.attachments[0].description.?);
    try std.testing.expectEqualStrings("text/plain", message.attachments[0].content_type.?);
    try std.testing.expectEqual(@as(u64, 12), message.attachments[0].size);
    try std.testing.expect(message.attachments[0].ephemeral);
    try std.testing.expectEqual(@as(usize, 1), message.sticker_items.len);
    try std.testing.expectEqual(@as(u64, 60), message.sticker_items[0].id.value);
    try std.testing.expectEqualStrings("ziggy", message.sticker_items[0].name);
    try std.testing.expectEqual(Types.StickerFormatType.png, message.sticker_items[0].format_type);
    try std.testing.expectEqual(@as(usize, 1), message.stickers.len);
    try std.testing.expectEqualStrings("full_ziggy", message.stickers[0].name);
    try std.testing.expectEqualStrings("full sticker", message.stickers[0].description.?);
    try std.testing.expectEqualStrings("zig", message.stickers[0].tags);
    try std.testing.expectEqual(Types.StickerType.guild, message.stickers[0].type);
    try std.testing.expectEqual(@as(u64, 30), message.stickers[0].guild_id.?.value);
    try std.testing.expectEqualStrings("sticker_artist", message.stickers[0].user.?.username);
    try std.testing.expectEqualStrings("sticker_artist", cache.getUser(Snowflake.init(91)).?.username);
    try std.testing.expectEqual(@as(usize, 1), message.components.len);
    const create_row = message.components[0].action_row;
    try std.testing.expectEqual(@as(usize, 1), create_row.len);
    const create_button = create_row[0].button;
    try std.testing.expectEqual(Interactions.ButtonStyle.success, create_button.style);
    try std.testing.expectEqualStrings("confirm", create_button.custom_id.?);
    try std.testing.expectEqualStrings("Confirm", create_button.label.?);
    try std.testing.expect(create_button.disabled);
    try std.testing.expectEqualStrings("Runtime?", message.poll.?.question.text.?);
    try std.testing.expectEqual(@as(usize, 1), message.poll.?.answers.len);
    try std.testing.expectEqual(@as(u32, 1), message.poll.?.answers[0].answer_id);
    try std.testing.expectEqualStrings("Zig", message.poll.?.answers[0].poll_media.text.?);
    try std.testing.expectEqualStrings("⚡", message.poll.?.answers[0].poll_media.emoji.?.name.?);
    try std.testing.expectEqualStrings("2026-06-03T00:00:00.000Z", message.poll.?.expiry.?);
    try std.testing.expect(message.poll.?.allow_multiselect);
    try std.testing.expectEqual(@as(u8, 1), message.poll.?.layout_type.?);
    try std.testing.expectEqual(@as(u32, 3), message.poll.?.results.?.answer_counts[0].count);
    try std.testing.expect(message.poll.?.results.?.answer_counts[0].me_voted);
    try std.testing.expectEqual(@as(usize, 1), message.reactions.len);
    try std.testing.expectEqual(@as(u32, 2), message.reactions[0].count);
    try std.testing.expectEqual(@as(u32, 1), message.reactions[0].count_details.burst);
    try std.testing.expectEqual(@as(u32, 1), message.reactions[0].count_details.normal);
    try std.testing.expectEqualStrings("👍", message.reactions[0].emoji.name.?);
    try std.testing.expect(message.reactions[0].me);
    try std.testing.expect(message.reactions[0].me_burst);
    try std.testing.expectEqual(@as(usize, 2), message.reactions[0].burst_colors.len);
    try std.testing.expectEqualStrings("#5865F2", message.reactions[0].burst_colors[0]);
    try std.testing.expectEqualStrings("#E558F2", message.reactions[0].burst_colors[1]);
}

test "cache handles user update dispatch" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    try cache.putUser(.{ .id = Snowflake.init(40), .username = "old" });

    var dispatch = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"USER_UPDATE\",\"d\":{\"id\":\"40\",\"username\":\"new\",\"global_name\":\"Zig Bot\",\"avatar\":\"new_avatar\",\"banner\":\"new_banner\",\"bot\":true,\"system\":true,\"mfa_enabled\":true,\"accent_color\":1122867,\"locale\":\"tr\",\"verified\":true,\"email\":null,\"flags\":256,\"public_flags\":512}}",
    );
    defer dispatch.deinit();

    try cache.applyDispatch(dispatch);

    const user = cache.getUser(Snowflake.init(40)).?;
    try std.testing.expectEqualStrings("new", user.username);
    try std.testing.expectEqualStrings("Zig Bot", user.global_name.?);
    try std.testing.expectEqualStrings("new_avatar", user.avatar.?);
    try std.testing.expectEqualStrings("new_banner", user.banner.?);
    try std.testing.expect(user.bot);
    try std.testing.expect(user.system);
    try std.testing.expect(user.mfa_enabled.?);
    try std.testing.expectEqual(@as(u32, 1122867), user.accent_color.?);
    try std.testing.expectEqualStrings("tr", user.locale.?);
    try std.testing.expect(user.verified.?);
    try std.testing.expect(user.email == null);
    try std.testing.expectEqual(@as(u32, 256), user.flags.?);
    try std.testing.expectEqual(@as(u32, 512), user.public_flags.?);
}

test "cache handles presence update dispatch" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var online = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"PRESENCE_UPDATE\",\"d\":{\"guild_id\":\"10\",\"user\":{\"id\":\"40\"},\"status\":\"idle\",\"activities\":[{\"name\":\"zig\",\"type\":0}]}}",
    );
    defer online.deinit();
    try cache.applyDispatch(online);

    const presence = cache.getPresence(Snowflake.init(10), Snowflake.init(40)).?;
    try std.testing.expectEqualStrings("idle", presence.status);
    try std.testing.expectEqual(@as(usize, 1), presence.activities_count);

    var offline = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"PRESENCE_UPDATE\",\"d\":{\"guild_id\":\"10\",\"user\":{\"id\":\"40\"},\"status\":\"offline\",\"activities\":[]}}",
    );
    defer offline.deinit();
    try cache.applyDispatch(offline);

    try std.testing.expect(cache.getPresence(Snowflake.init(10), Snowflake.init(40)) == null);
}

test "cache handles voice state update dispatch" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var join = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"VOICE_STATE_UPDATE\",\"d\":{\"guild_id\":\"10\",\"channel_id\":\"20\",\"user_id\":\"40\",\"member\":{\"user\":{\"id\":\"40\",\"username\":\"speaker\"},\"roles\":[]},\"session_id\":\"voice-session\",\"deaf\":false,\"mute\":false,\"self_deaf\":true,\"self_mute\":false,\"self_video\":true,\"suppress\":false}}",
    );
    defer join.deinit();
    try cache.applyDispatch(join);

    const voice_state = cache.getVoiceState(Snowflake.init(10), Snowflake.init(40)).?;
    try std.testing.expectEqual(@as(u64, 20), voice_state.channel_id.?.value);
    try std.testing.expectEqualStrings("voice-session", voice_state.session_id);
    try std.testing.expect(voice_state.self_deaf);
    try std.testing.expect(voice_state.self_video);
    try std.testing.expectEqualStrings("speaker", voice_state.member.?.user.?.username);

    var leave = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"VOICE_STATE_UPDATE\",\"d\":{\"guild_id\":\"10\",\"channel_id\":null,\"user_id\":\"40\",\"session_id\":\"voice-session\",\"deaf\":false,\"mute\":false,\"self_deaf\":false,\"self_mute\":false,\"self_video\":false,\"suppress\":false}}",
    );
    defer leave.deinit();
    try cache.applyDispatch(leave);

    try std.testing.expect(cache.getVoiceState(Snowflake.init(10), Snowflake.init(40)) == null);

    try cache.putVoiceState(.{
        .guild_id = Snowflake.init(10),
        .channel_id = Snowflake.init(20),
        .user_id = Snowflake.init(41),
        .member = .{
            .user = .{ .id = Snowflake.init(41), .username = "direct-speaker" },
            .nick = "direct nick",
            .roles = &.{Snowflake.init(50)},
        },
        .session_id = "direct-session",
    });

    const direct_voice_state = cache.getVoiceState(Snowflake.init(10), Snowflake.init(41)).?;
    try std.testing.expectEqualStrings("direct-session", direct_voice_state.session_id);
    try std.testing.expectEqualStrings("direct nick", direct_voice_state.member.?.nick.?);
    try std.testing.expectEqual(@as(u64, 50), direct_voice_state.member.?.roles[0].value);
    try std.testing.expectEqualStrings("direct-speaker", cache.getUser(Snowflake.init(41)).?.username);
}
