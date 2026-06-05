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

pub fn Methods(comptime Cache: type) type {
    return struct {
        pub fn listGuildMembers(self: *Cache, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.GuildMember {
            var members = std.array_list.Managed(Types.GuildMember).init(allocator);
            errdefer members.deinit();

            var iterator = self.members.valueIterator();
            while (iterator.next()) |owned| {
                if (owned.guild_id.value == guild_id.value) try members.append(owned.view(self.getUser(owned.user_id)));
            }
            return members.toOwnedSlice();
        }

        pub fn listMembers(self: *Cache, allocator: std.mem.Allocator) ![]Types.CachedGuildMember {
            var members = std.array_list.Managed(Types.CachedGuildMember).init(allocator);
            errdefer members.deinit();

            var iterator = self.members.valueIterator();
            while (iterator.next()) |owned| {
                try members.append(.{
                    .guild_id = owned.guild_id,
                    .member = owned.view(self.getUser(owned.user_id)),
                });
            }
            return members.toOwnedSlice();
        }

        pub fn listGuildRoles(self: *Cache, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Role {
            var roles = std.array_list.Managed(Types.Role).init(allocator);
            errdefer roles.deinit();

            var iterator = self.roles.valueIterator();
            while (iterator.next()) |owned| {
                if (owned.guild_id.value == guild_id.value) try roles.append(owned.view());
            }
            return roles.toOwnedSlice();
        }

        pub fn listRoles(self: *Cache, allocator: std.mem.Allocator) ![]Types.Role {
            var roles = std.array_list.Managed(Types.Role).init(allocator);
            errdefer roles.deinit();

            var iterator = self.roles.valueIterator();
            while (iterator.next()) |owned| try roles.append(owned.view());
            return roles.toOwnedSlice();
        }

        pub fn listGuildEmojis(self: *Cache, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Emoji {
            var emojis = std.array_list.Managed(Types.Emoji).init(allocator);
            errdefer emojis.deinit();

            var iterator = self.emojis.valueIterator();
            while (iterator.next()) |owned| {
                if (owned.guild_id.value == guild_id.value) try emojis.append(owned.view(if (owned.user_id) |user_id| self.getUser(user_id) else null));
            }
            return emojis.toOwnedSlice();
        }

        pub fn listEmojis(self: *Cache, allocator: std.mem.Allocator) ![]Types.Emoji {
            var emojis = std.array_list.Managed(Types.Emoji).init(allocator);
            errdefer emojis.deinit();

            var iterator = self.emojis.valueIterator();
            while (iterator.next()) |owned| try emojis.append(owned.view(if (owned.user_id) |user_id| self.getUser(user_id) else null));
            return emojis.toOwnedSlice();
        }

        pub fn listGuildStickers(self: *Cache, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Sticker {
            var stickers = std.array_list.Managed(Types.Sticker).init(allocator);
            errdefer stickers.deinit();

            var iterator = self.stickers.valueIterator();
            while (iterator.next()) |owned| {
                if (owned.guild_id.value == guild_id.value) try stickers.append(owned.view(if (owned.user_id) |user_id| self.getUser(user_id) else null));
            }
            return stickers.toOwnedSlice();
        }

        pub fn listStickers(self: *Cache, allocator: std.mem.Allocator) ![]Types.Sticker {
            var stickers = std.array_list.Managed(Types.Sticker).init(allocator);
            errdefer stickers.deinit();

            var iterator = self.stickers.valueIterator();
            while (iterator.next()) |owned| try stickers.append(owned.view(if (owned.user_id) |user_id| self.getUser(user_id) else null));
            return stickers.toOwnedSlice();
        }

        pub fn listGuildScheduledEvents(
            self: *Cache,
            allocator: std.mem.Allocator,
            guild_id: Snowflake,
        ) ![]Types.GuildScheduledEvent {
            var events = std.array_list.Managed(Types.GuildScheduledEvent).init(allocator);
            errdefer events.deinit();

            var iterator = self.scheduled_events.valueIterator();
            while (iterator.next()) |owned| {
                if (owned.guild_id.value == guild_id.value) try events.append(owned.view());
            }
            return events.toOwnedSlice();
        }

        pub fn listScheduledEvents(self: *Cache, allocator: std.mem.Allocator) ![]Types.GuildScheduledEvent {
            var events = std.array_list.Managed(Types.GuildScheduledEvent).init(allocator);
            errdefer events.deinit();

            var iterator = self.scheduled_events.valueIterator();
            while (iterator.next()) |owned| try events.append(owned.view());
            return events.toOwnedSlice();
        }

        pub fn listGuildStageInstances(
            self: *Cache,
            allocator: std.mem.Allocator,
            guild_id: Snowflake,
        ) ![]Types.StageInstance {
            var stage_instances = std.array_list.Managed(Types.StageInstance).init(allocator);
            errdefer stage_instances.deinit();

            var iterator = self.stage_instances.valueIterator();
            while (iterator.next()) |owned| {
                if (owned.guild_id.value == guild_id.value) try stage_instances.append(owned.view());
            }
            return stage_instances.toOwnedSlice();
        }

        pub fn listStageInstances(self: *Cache, allocator: std.mem.Allocator) ![]Types.StageInstance {
            var stage_instances = std.array_list.Managed(Types.StageInstance).init(allocator);
            errdefer stage_instances.deinit();

            var iterator = self.stage_instances.valueIterator();
            while (iterator.next()) |owned| try stage_instances.append(owned.view());
            return stage_instances.toOwnedSlice();
        }

        pub fn listGuildInvites(self: *Cache, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Invite {
            var invites = std.array_list.Managed(Types.Invite).init(allocator);
            errdefer invites.deinit();

            var iterator = self.invites.valueIterator();
            while (iterator.next()) |owned| {
                const invite_guild_id = owned.guild_id orelse continue;
                if (invite_guild_id.value == guild_id.value) try invites.append(owned.view());
            }
            return invites.toOwnedSlice();
        }

        pub fn listInvites(self: *Cache, allocator: std.mem.Allocator) ![]Types.Invite {
            var invites = std.array_list.Managed(Types.Invite).init(allocator);
            errdefer invites.deinit();

            var iterator = self.invites.valueIterator();
            while (iterator.next()) |owned| try invites.append(owned.view());
            return invites.toOwnedSlice();
        }

        pub fn listChannelInvites(self: *Cache, allocator: std.mem.Allocator, channel_id: Snowflake) ![]Types.Invite {
            var invites = std.array_list.Managed(Types.Invite).init(allocator);
            errdefer invites.deinit();

            var iterator = self.invites.valueIterator();
            while (iterator.next()) |owned| {
                const invite_channel_id = owned.channel_id orelse continue;
                if (invite_channel_id.value == channel_id.value) try invites.append(owned.view());
            }
            return invites.toOwnedSlice();
        }

        pub fn listPresences(self: *Cache, allocator: std.mem.Allocator) ![]Types.Presence {
            var presences = std.array_list.Managed(Types.Presence).init(allocator);
            errdefer presences.deinit();

            var iterator = self.presences.valueIterator();
            while (iterator.next()) |owned| try presences.append(owned.view());
            return presences.toOwnedSlice();
        }

        pub fn listGuildPresences(self: *Cache, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Presence {
            var presences = std.array_list.Managed(Types.Presence).init(allocator);
            errdefer presences.deinit();

            var iterator = self.presences.valueIterator();
            while (iterator.next()) |owned| {
                if (owned.guild_id.value == guild_id.value) try presences.append(owned.view());
            }
            return presences.toOwnedSlice();
        }

        pub fn listVoiceStates(self: *Cache, allocator: std.mem.Allocator) ![]Types.VoiceState {
            var voice_states = std.array_list.Managed(Types.VoiceState).init(allocator);
            errdefer voice_states.deinit();

            var iterator = self.voice_states.valueIterator();
            while (iterator.next()) |owned| try voice_states.append(owned.view(self.getMember(owned.guild_id, owned.user_id)));
            return voice_states.toOwnedSlice();
        }

        pub fn listGuildVoiceStates(self: *Cache, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.VoiceState {
            var voice_states = std.array_list.Managed(Types.VoiceState).init(allocator);
            errdefer voice_states.deinit();

            var iterator = self.voice_states.valueIterator();
            while (iterator.next()) |owned| {
                if (owned.guild_id.value == guild_id.value) try voice_states.append(owned.view(self.getMember(guild_id, owned.user_id)));
            }
            return voice_states.toOwnedSlice();
        }

        pub fn listChannelMessages(self: *Cache, allocator: std.mem.Allocator, channel_id: Snowflake) ![]Types.Message {
            var messages = std.array_list.Managed(Types.Message).init(allocator);
            errdefer messages.deinit();

            for (self.message_order.items) |message_id| {
                const owned = self.messages.get(message_id) orelse continue;
                if (owned.channel_id.value == channel_id.value) try messages.append(owned.view(self.getUser(owned.author_id)));
            }
            return messages.toOwnedSlice();
        }

        pub fn listMessages(self: *Cache, allocator: std.mem.Allocator) ![]Types.Message {
            var messages = std.array_list.Managed(Types.Message).init(allocator);
            errdefer messages.deinit();

            for (self.message_order.items) |message_id| {
                const owned = self.messages.get(message_id) orelse continue;
                try messages.append(owned.view(self.getUser(owned.author_id)));
            }
            return messages.toOwnedSlice();
        }

        pub fn listGuildMessages(self: *Cache, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Message {
            var messages = std.array_list.Managed(Types.Message).init(allocator);
            errdefer messages.deinit();

            for (self.message_order.items) |message_id| {
                const owned = self.messages.get(message_id) orelse continue;
                const message_guild_id = owned.guild_id orelse continue;
                if (message_guild_id.value == guild_id.value) try messages.append(owned.view(self.getUser(owned.author_id)));
            }
            return messages.toOwnedSlice();
        }

        pub fn putUser(self: *Cache, user: Types.User) !void {
            if (!self.policy.users) return;
            var owned = try OwnedUser.copy(self.allocator, user);
            errdefer owned.deinit(self.allocator);
            try replaceOwned(OwnedUser, &self.users, self.allocator, user.id.value, owned);
        }

        pub fn putCurrentUser(self: *Cache, user: Types.User) !void {
            try self.putUser(user);
            if (self.policy.users) self.current_user_id = user.id;
        }

        pub fn removeUser(self: *Cache, id: Snowflake) void {
            if (self.users.fetchRemove(id.value)) |old| old.value.deinit(self.allocator);
            if (self.current_user_id) |current_id| {
                if (current_id.value == id.value) self.current_user_id = null;
            }
        }

        pub fn putCurrentApplication(self: *Cache, application: Types.Application) !void {
            const owned = try copyApplication(self.allocator, application);
            if (self.current_application) |old| deinitApplication(old, self.allocator);
            self.current_application = owned;
        }

        pub fn removeCurrentApplication(self: *Cache) void {
            if (self.current_application) |application| deinitApplication(application, self.allocator);
            self.current_application = null;
        }

        pub fn putGuild(self: *Cache, guild: Types.Guild) !void {
            if (!self.policy.guilds) return;
            var owned = try OwnedGuild.copy(self.allocator, guild);
            errdefer owned.deinit(self.allocator);
            try replaceOwned(OwnedGuild, &self.guilds, self.allocator, guild.id.value, owned);
        }

        pub fn removeGuild(self: *Cache, id: Snowflake) void {
            if (self.guilds.fetchRemove(id.value)) |old| old.value.deinit(self.allocator);
            self.removeGuildChannels(id);
            self.removeGuildMessages(id);
            self.removeGuildMembers(id);
            self.removeGuildRoles(id);
            self.removeGuildEmojis(id);
            self.removeGuildStickers(id);
            self.removeGuildScheduledEvents(id);
            self.removeGuildStageInstances(id);
            self.removeGuildInvites(id);
            self.removeGuildPresences(id);
            self.removeGuildVoiceStates(id);
        }

        pub fn putChannel(self: *Cache, channel: Types.Channel) !void {
            if (!self.policy.channels) return;
            var owned = try OwnedChannel.copy(self.allocator, channel);
            errdefer owned.deinit(self.allocator);
            try replaceOwned(OwnedChannel, &self.channels, self.allocator, channel.id.value, owned);
        }

        pub fn removeChannel(self: *Cache, id: Snowflake) void {
            if (self.channels.fetchRemove(id.value)) |old| old.value.deinit(self.allocator);
            self.removeChildThreads(id);
            self.removeChannelMessages(id);
            self.removeChannelVoiceStates(id);
            self.removeChannelInvites(id);
        }

        pub fn putMember(self: *Cache, guild_id: Snowflake, member: Types.GuildMember) !void {
            if (member.user) |user| try self.putUser(user);
            if (!self.policy.members) return;
            const user = member.user orelse return error.MissingField;
            var owned = try OwnedGuildMember.copy(self.allocator, guild_id, member);
            errdefer owned.deinit(self.allocator);
            try replaceOwned(OwnedGuildMember, &self.members, self.allocator, memberKey(guild_id, user.id), owned);
        }

        pub fn removeMember(self: *Cache, guild_id: Snowflake, user_id: Snowflake) void {
            if (self.members.fetchRemove(memberKey(guild_id, user_id))) |old| old.value.deinit(self.allocator);
            self.removePresence(guild_id, user_id);
            self.removeVoiceState(guild_id, user_id);
        }

        pub fn putRole(self: *Cache, guild_id: Snowflake, role: Types.Role) !void {
            if (!self.policy.roles) return;
            var owned = try OwnedRole.copy(self.allocator, guild_id, role);
            errdefer owned.deinit(self.allocator);
            try replaceOwned(OwnedRole, &self.roles, self.allocator, roleKey(guild_id, role.id), owned);
        }

        pub fn removeRole(self: *Cache, guild_id: Snowflake, role_id: Snowflake) void {
            if (self.roles.fetchRemove(roleKey(guild_id, role_id))) |old| old.value.deinit(self.allocator);
            self.removeRoleFromMembers(guild_id, role_id);
        }

        pub fn putEmoji(self: *Cache, guild_id: Snowflake, emoji: Types.Emoji) !void {
            if (emoji.user) |user| try self.putUser(user);
            if (!self.policy.emojis) return;
            const emoji_id = emoji.id orelse return error.MissingField;
            var owned = try OwnedEmoji.copy(self.allocator, guild_id, emoji);
            errdefer owned.deinit(self.allocator);
            try replaceOwned(OwnedEmoji, &self.emojis, self.allocator, roleKey(guild_id, emoji_id), owned);
        }

        pub fn removeEmoji(self: *Cache, guild_id: Snowflake, emoji_id: Snowflake) void {
            if (self.emojis.fetchRemove(roleKey(guild_id, emoji_id))) |old| old.value.deinit(self.allocator);
        }

        pub fn putSticker(self: *Cache, guild_id: Snowflake, sticker: Types.Sticker) !void {
            if (sticker.user) |user| try self.putUser(user);
            if (!self.policy.stickers) return;
            var owned = try OwnedSticker.copy(self.allocator, guild_id, sticker);
            errdefer owned.deinit(self.allocator);
            try replaceOwned(OwnedSticker, &self.stickers, self.allocator, roleKey(guild_id, sticker.id), owned);
        }

        pub fn removeSticker(self: *Cache, guild_id: Snowflake, sticker_id: Snowflake) void {
            if (self.stickers.fetchRemove(roleKey(guild_id, sticker_id))) |old| old.value.deinit(self.allocator);
        }

        pub fn putScheduledEvent(self: *Cache, event: Types.GuildScheduledEvent) !void {
            if (!self.policy.scheduled_events) return;
            var owned = try OwnedScheduledEvent.copy(self.allocator, event);
            errdefer owned.deinit(self.allocator);
            try replaceOwned(OwnedScheduledEvent, &self.scheduled_events, self.allocator, roleKey(event.guild_id, event.id), owned);
        }

        pub fn removeScheduledEvent(self: *Cache, guild_id: Snowflake, event_id: Snowflake) void {
            if (self.scheduled_events.fetchRemove(roleKey(guild_id, event_id))) |old| old.value.deinit(self.allocator);
        }

        pub fn putStageInstance(self: *Cache, stage_instance: Types.StageInstance) !void {
            if (!self.policy.stage_instances) return;
            var owned = try OwnedStageInstance.copy(self.allocator, stage_instance);
            errdefer owned.deinit(self.allocator);
            try replaceOwned(OwnedStageInstance, &self.stage_instances, self.allocator, roleKey(stage_instance.guild_id, stage_instance.id), owned);
        }

        pub fn removeStageInstance(self: *Cache, guild_id: Snowflake, stage_instance_id: Snowflake) void {
            if (self.stage_instances.fetchRemove(roleKey(guild_id, stage_instance_id))) |old| old.value.deinit(self.allocator);
        }

        pub fn putInvite(self: *Cache, invite: Types.Invite) !void {
            if (!self.policy.invites) return;
            if (self.invites.fetchRemove(invite.code)) |old| old.value.deinit(self.allocator);
            var owned = try OwnedInvite.copy(self.allocator, invite);
            errdefer owned.deinit(self.allocator);
            try self.invites.put(owned.code, owned);
        }

        pub fn removeInvite(self: *Cache, code: []const u8) void {
            if (self.invites.fetchRemove(code)) |old| old.value.deinit(self.allocator);
        }

        pub fn putPresence(self: *Cache, presence: Types.Presence) !void {
            if (!self.policy.presences) return;
            const guild_id = presence.guild_id orelse return error.MissingField;
            var owned = try OwnedPresence.copy(self.allocator, presence);
            errdefer owned.deinit(self.allocator);
            try replaceOwned(OwnedPresence, &self.presences, self.allocator, memberKey(guild_id, presence.user_id), owned);
        }

        pub fn removePresence(self: *Cache, guild_id: Snowflake, user_id: Snowflake) void {
            if (self.presences.fetchRemove(memberKey(guild_id, user_id))) |old| old.value.deinit(self.allocator);
        }

        pub fn putVoiceState(self: *Cache, voice_state: Types.VoiceState) !void {
            const guild_id = voice_state.guild_id orelse return error.MissingField;
            if (voice_state.member) |member| if (member.user != null) try self.putMember(guild_id, member);
            if (!self.policy.voice_states) return;
            var owned = try OwnedVoiceState.copy(self.allocator, voice_state);
            errdefer owned.deinit(self.allocator);
            try replaceOwned(OwnedVoiceState, &self.voice_states, self.allocator, memberKey(guild_id, voice_state.user_id), owned);
        }

        pub fn removeVoiceState(self: *Cache, guild_id: Snowflake, user_id: Snowflake) void {
            if (self.voice_states.fetchRemove(memberKey(guild_id, user_id))) |old| old.value.deinit(self.allocator);
        }

        pub fn putMessage(self: *Cache, message: Types.Message) !void {
            if (!self.policy.messages) {
                try self.putMessageAssociations(message);
                return;
            }
            var owned = try OwnedMessage.copy(self.allocator, message);
            errdefer owned.deinit(self.allocator);
            const existed = self.messages.contains(message.id.value);
            try replaceOwned(OwnedMessage, &self.messages, self.allocator, message.id.value, owned);
            if (!existed) try self.message_order.append(message.id.value);
            try self.enforceMessageLimit();
            try self.putMessageAssociations(message);
        }

        pub fn putMessageAssociations(self: *Cache, message: Types.Message) !void {
            if (message.author) |author| try self.putUser(author);
            if (message.member) |member| if (member.user != null) {
                if (message.guild_id) |guild_id| try self.putMember(guild_id, member);
            };
            if (message.interaction_metadata) |metadata| {
                try self.putUser(metadata.user);
                if (metadata.target_user) |user| try self.putUser(user);
            }
            if (message.application) |application| {
                if (application.bot) |bot| try self.putUser(bot);
                if (application.owner) |owner| try self.putUser(owner);
            }
            for (message.stickers) |sticker| {
                if (sticker.user) |user| try self.putUser(user);
            }
            for (message.message_snapshots) |snapshot| {
                for (snapshot.mentions) |user| try self.putUser(user);
            }
            if (message.thread) |thread| try self.putChannel(thread);
        }

        pub fn clearMessages(self: *Cache) void {
            clearOwnedMap(&self.messages, self.allocator);
            self.messages = std.AutoHashMap(u64, OwnedMessage).init(self.allocator);
            self.message_order.clearRetainingCapacity();
        }

        pub fn removeMessage(self: *Cache, id: Snowflake) void {
            if (self.messages.fetchRemove(id.value)) |old| old.value.deinit(self.allocator);
            self.removeMessageOrder(id.value);
        }

        pub fn messageCount(self: *Cache) usize {
            return self.messages.count();
        }

        pub fn removeGuildChannels(self: *Cache, guild_id: Snowflake) void {
            var ids = std.array_list.Managed(u64).init(self.allocator);
            defer ids.deinit();

            var iterator = self.channels.iterator();
            while (iterator.next()) |entry| {
                if (entry.value_ptr.guild_id) |channel_guild_id| {
                    if (channel_guild_id.value == guild_id.value) ids.append(entry.key_ptr.*) catch return;
                }
            }

            for (ids.items) |id| self.removeChannel(Snowflake.init(id));
        }

        pub fn removeChildThreads(self: *Cache, parent_channel_id: Snowflake) void {
            var ids = std.array_list.Managed(u64).init(self.allocator);
            defer ids.deinit();

            var iterator = self.channels.iterator();
            while (iterator.next()) |entry| {
                if (!channelTypeIsThread(entry.value_ptr.type)) continue;
                const parent_id = entry.value_ptr.parent_id orelse continue;
                if (parent_id.value == parent_channel_id.value) ids.append(entry.key_ptr.*) catch return;
            }

            for (ids.items) |id| self.removeChannel(Snowflake.init(id));
        }
    };
}
