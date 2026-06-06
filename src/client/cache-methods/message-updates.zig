const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Types = @import("../../models/types.zig");
const Gateway = @import("../../gateway/protocol.zig");
const Interactions = @import("../../interactions/mod.zig");
const Permissions = @import("../../core/permissions.zig");
const Collection = @import("../../core/collection.zig").Collection;

const Root = @import("../cache.zig");
const OwnedChannel = Root.OwnedChannel;
const copyAttachments = Root.copyAttachments;
const deinitAttachments = Root.deinitAttachments;
const copyMessageSnapshots = Root.copyMessageSnapshots;
const deinitMessageSnapshots = Root.deinitMessageSnapshots;
const copyMessageStickerItems = Root.copyMessageStickerItems;
const deinitMessageStickerItems = Root.deinitMessageStickerItems;
const copyStickers = Root.copyStickers;
const deinitStickers = Root.deinitStickers;
const copyComponents = Root.copyComponents;
const deinitComponents = Root.deinitComponents;
const copyMessagePoll = Root.copyMessagePoll;
const deinitMessagePoll = Root.deinitMessagePoll;
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
const deinitUsers = Root.deinitUsers;
const copyApplication = Root.copyApplication;
const deinitApplication = Root.deinitApplication;
const copyChannels = Root.copyChannels;
const copyChannel = Root.copyChannel;
const deinitChannels = Root.deinitChannels;
const deinitChannel = Root.deinitChannel;
const copyEmbeds = Root.copyEmbeds;
const deinitEmbeds = Root.deinitEmbeds;
const copyReactions = Root.copyReactions;
const deinitReactions = Root.deinitReactions;
const incrementReaction = Root.incrementReaction;
const decrementReaction = Root.decrementReaction;
const removeReactionEmoji = Root.removeReactionEmoji;
const roleKey = Root.roleKey;
const userFromJson = Root.userFromJson;
const applicationFromJson = Root.applicationFromJson;
const deinitParsedApplication = Root.deinitParsedApplication;
const channelFromJson = Root.channelFromJson;
const deinitParsedChannel = Root.deinitParsedChannel;
const deinitParsedChannels = Root.deinitParsedChannels;
const channelTypeIsThread = Root.channelTypeIsThread;
const roleFromJson = Root.roleFromJson;
const emojiFromJson = Root.emojiFromJson;
const stickerFromJson = Root.stickerFromJson;
const stickerArrayFromJson = Root.stickerArrayFromJson;
const scheduledEventFromJson = Root.scheduledEventFromJson;
const stageInstanceFromJson = Root.stageInstanceFromJson;
const inviteFromJson = Root.inviteFromJson;
const messageReferenceFromJson = Root.messageReferenceFromJson;
const referencedMessageIdFromJson = Root.referencedMessageIdFromJson;
const messageSnapshotArrayFromJson = Root.messageSnapshotArrayFromJson;
const deinitParsedMessageSnapshots = Root.deinitParsedMessageSnapshots;
const memberFromJson = Root.memberFromJson;
const roleArrayFromJson = Root.roleArrayFromJson;
const userArrayFromJson = Root.userArrayFromJson;
const channelArrayFromJson = Root.channelArrayFromJson;
const attachmentArrayFromJson = Root.attachmentArrayFromJson;
const messageStickerItemArrayFromJson = Root.messageStickerItemArrayFromJson;
const componentArrayFromJson = Root.componentArrayFromJson;
const deinitParsedComponentArray = Root.deinitParsedComponentArray;
const messagePollFromJson = Root.messagePollFromJson;
const messageInteractionMetadataFromJson = Root.messageInteractionMetadataFromJson;
const messageCallFromJson = Root.messageCallFromJson;
const deinitParsedMessageCall = Root.deinitParsedMessageCall;
const nullableRoleSubscriptionDataFromJson = Root.nullableRoleSubscriptionDataFromJson;
const sharedClientThemeFromJson = Root.sharedClientThemeFromJson;
const deinitParsedSharedClientTheme = Root.deinitParsedSharedClientTheme;
const nullableMessageActivityFromJson = Root.nullableMessageActivityFromJson;
const deinitParsedMessagePoll = Root.deinitParsedMessagePoll;
const embedArrayFromJson = Root.embedArrayFromJson;
const deinitParsedEmbeds = Root.deinitParsedEmbeds;
const reactionArrayFromJson = Root.reactionArrayFromJson;
const deinitParsedReactions = Root.deinitParsedReactions;
const reactionEventFromJson = Root.reactionEventFromJson;
const reactionEmojiFromJson = Root.reactionEmojiFromJson;
const requireObject = Root.requireObject;
const requireArray = Root.requireArray;
const snowflakeField = Root.snowflakeField;
const snowflakeValue = Root.snowflakeValue;
const nullableSnowflakeValue = Root.nullableSnowflakeValue;
const stringField = Root.stringField;
const intField = Root.intField;
const intValue = Root.intValue;
const nullableIntValue = Root.nullableIntValue;
const messageNonceFromJson = Root.messageNonceFromJson;
const stringValue = Root.stringValue;
const optionalStringValue = Root.optionalStringValue;
const boolValue = Root.boolValue;

pub fn Methods(comptime Cache: type) type {
    return struct {
        pub fn updateMessageFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            const id = try snowflakeField(object, "id");
            if (object.get("author") != null) {
                try self.putMessageFromJson(data);
                return;
            }

            var old = self.messages.get(id.value) orelse return;
            const content = if (object.get("content")) |value| try stringValue(value) else old.content;
            var member = if (object.get("member")) |value| try memberFromJson(self.allocator, value) else old.member;
            defer if (object.get("member") != null) {
                if (member) |value| self.allocator.free(value.roles);
            };
            if (object.get("member") != null) {
                if (member) |*value| {
                    if (value.user == null) value.user = self.getUser(old.author_id);
                }
            }
            const channel_id = if (object.get("channel_id")) |value| try snowflakeValue(value) else old.channel_id;
            const guild_id = if (object.get("guild_id")) |value| try snowflakeValue(value) else old.guild_id;
            const timestamp = if (object.get("timestamp")) |value| try stringValue(value) else old.timestamp;
            const edited_timestamp = if (object.get("edited_timestamp")) |value| try optionalStringValue(value) else old.edited_timestamp;
            const attachments = if (object.get("attachments")) |value| try attachmentArrayFromJson(self.allocator, value) else old.attachments;
            defer if (object.get("attachments") != null) self.allocator.free(attachments);
            const reactions = if (object.get("reactions")) |value| try reactionArrayFromJson(self.allocator, value) else old.reactions;
            defer if (object.get("reactions") != null) deinitParsedReactions(reactions, self.allocator);
            const embeds = if (object.get("embeds")) |value| try embedArrayFromJson(self.allocator, value) else old.embeds;
            defer if (object.get("embeds") != null) deinitParsedEmbeds(embeds, self.allocator);
            const mentions = if (object.get("mentions")) |value| try userArrayFromJson(self.allocator, value) else old.mentions;
            defer if (object.get("mentions") != null) self.allocator.free(mentions);
            const mention_roles = if (object.get("mention_roles")) |value| try roleArrayFromJson(self.allocator, value) else old.mention_roles;
            defer if (object.get("mention_roles") != null) self.allocator.free(mention_roles);
            const mention_channels = if (object.get("mention_channels")) |value| try channelArrayFromJson(self.allocator, value, null) else old.mention_channels;
            defer if (object.get("mention_channels") != null) deinitParsedChannels(mention_channels, self.allocator);
            const message_snapshots = if (object.get("message_snapshots")) |value| try messageSnapshotArrayFromJson(self.allocator, value) else old.message_snapshots;
            defer if (object.get("message_snapshots") != null) deinitParsedMessageSnapshots(message_snapshots, self.allocator);
            const sticker_items = if (object.get("sticker_items")) |value| try messageStickerItemArrayFromJson(self.allocator, value) else old.sticker_items;
            defer if (object.get("sticker_items") != null) self.allocator.free(sticker_items);
            const stickers = if (object.get("stickers")) |value| try stickerArrayFromJson(self.allocator, value, guild_id) else old.stickers;
            defer if (object.get("stickers") != null) self.allocator.free(stickers);
            const components = if (object.get("components")) |value| try componentArrayFromJson(self.allocator, value) else old.components;
            defer if (object.get("components") != null) deinitParsedComponentArray(components, self.allocator);
            const call = if (object.get("call")) |value| try messageCallFromJson(self.allocator, value) else old.call;
            defer if (object.get("call") != null) deinitParsedMessageCall(call, self.allocator);
            const role_subscription_data = if (object.get("role_subscription_data")) |value| try nullableRoleSubscriptionDataFromJson(value) else old.role_subscription_data;
            const shared_client_theme = if (object.get("shared_client_theme")) |value| try sharedClientThemeFromJson(self.allocator, value) else old.shared_client_theme;
            defer if (object.get("shared_client_theme") != null) deinitParsedSharedClientTheme(shared_client_theme, self.allocator);
            const poll = if (object.get("poll")) |value| try messagePollFromJson(self.allocator, value) else old.poll;
            defer if (object.get("poll") != null) deinitParsedMessagePoll(poll, self.allocator);
            const thread = if (object.get("thread")) |value| try channelFromJson(self.allocator, value, guild_id) else old.thread;
            defer if (object.get("thread") != null) {
                if (thread) |value| deinitParsedChannel(value, self.allocator);
            };
            const nonce = if (object.get("nonce")) |value| try messageNonceFromJson(self.allocator, value) else null;
            defer if (nonce) |value| value.deinit(self.allocator);
            const message_nonce = if (nonce) |value| value.value else old.nonce;
            const message_reference = if (object.get("message_reference")) |value| try messageReferenceFromJson(value) else old.message_reference;
            const referenced_message_id = if (object.get("referenced_message")) |value| try referencedMessageIdFromJson(value) else old.referenced_message_id;
            const webhook_id = if (object.get("webhook_id")) |value| try nullableSnowflakeValue(value) else old.webhook_id;
            const application_id = if (object.get("application_id")) |value| try nullableSnowflakeValue(value) else old.application_id;
            const application = if (object.get("application")) |value| try applicationFromJson(self.allocator, value) else old.application;
            defer if (object.get("application") != null) deinitParsedApplication(application, self.allocator);
            const activity = if (object.get("activity")) |value| try nullableMessageActivityFromJson(value) else old.activity;
            const interaction_metadata = if (object.get("interaction_metadata")) |value| try messageInteractionMetadataFromJson(value) else old.interaction_metadata;
            const message_type = if (object.get("type")) |value| @as(u8, @intCast(try intValue(value))) else old.type;
            const tts = if (object.get("tts")) |value| try boolValue(value) else old.tts;
            const mention_everyone = if (object.get("mention_everyone")) |value| try boolValue(value) else old.mention_everyone;
            const pinned = if (object.get("pinned")) |value| try boolValue(value) else old.pinned;
            const position = if (object.get("position")) |value| @as(i32, @intCast(try intValue(value))) else old.position;
            const flags = if (object.get("flags")) |value| @as(u32, @intCast(try intValue(value))) else old.flags;

            const owned_content = try self.allocator.dupe(u8, content);
            errdefer self.allocator.free(owned_content);
            const owned_member = if (member) |value| try copyGuildMember(self.allocator, value) else null;
            errdefer if (owned_member) |value| deinitGuildMember(value, self.allocator);
            const owned_timestamp = if (timestamp) |value| try self.allocator.dupe(u8, value) else null;
            errdefer if (owned_timestamp) |value| self.allocator.free(value);
            const owned_edited_timestamp = if (edited_timestamp) |value| try self.allocator.dupe(u8, value) else null;
            errdefer if (owned_edited_timestamp) |value| self.allocator.free(value);
            const owned_attachments = try copyAttachments(self.allocator, attachments);
            errdefer deinitAttachments(owned_attachments, self.allocator);
            const owned_reactions = try copyReactions(self.allocator, reactions);
            errdefer deinitReactions(owned_reactions, self.allocator);
            const owned_embeds = try copyEmbeds(self.allocator, embeds);
            errdefer deinitEmbeds(owned_embeds, self.allocator);
            const owned_mentions = try copyUsers(self.allocator, mentions);
            errdefer deinitUsers(owned_mentions, self.allocator);
            const owned_mention_roles = try self.allocator.dupe(Snowflake, mention_roles);
            errdefer self.allocator.free(owned_mention_roles);
            const owned_mention_channels = try copyChannels(self.allocator, mention_channels);
            errdefer deinitChannels(owned_mention_channels, self.allocator);
            const owned_message_snapshots = try copyMessageSnapshots(self.allocator, message_snapshots);
            errdefer deinitMessageSnapshots(owned_message_snapshots, self.allocator);
            const owned_sticker_items = try copyMessageStickerItems(self.allocator, sticker_items);
            errdefer deinitMessageStickerItems(owned_sticker_items, self.allocator);
            const owned_stickers = try copyStickers(self.allocator, stickers);
            errdefer deinitStickers(owned_stickers, self.allocator);
            const owned_components = try copyComponents(self.allocator, components);
            errdefer deinitComponents(owned_components, self.allocator);
            const owned_call = if (call) |value| try copyMessageCall(self.allocator, value) else null;
            errdefer if (owned_call) |value| deinitMessageCall(value, self.allocator);
            const owned_role_subscription_data = if (role_subscription_data) |value| try copyRoleSubscriptionData(self.allocator, value) else null;
            errdefer if (owned_role_subscription_data) |value| deinitRoleSubscriptionData(value, self.allocator);
            const owned_shared_client_theme = if (shared_client_theme) |value| try copySharedClientTheme(self.allocator, value) else null;
            errdefer if (owned_shared_client_theme) |value| deinitSharedClientTheme(value, self.allocator);
            const owned_poll = if (poll) |value| try copyMessagePoll(self.allocator, value) else null;
            errdefer if (owned_poll) |value| deinitMessagePoll(value, self.allocator);
            const owned_thread = if (thread) |value| try copyChannel(self.allocator, value) else null;
            errdefer if (owned_thread) |value| deinitChannel(value, self.allocator);
            const owned_nonce = if (message_nonce) |value| try self.allocator.dupe(u8, value) else null;
            errdefer if (owned_nonce) |value| self.allocator.free(value);
            const owned_interaction_metadata = if (interaction_metadata) |value| try copyMessageInteractionMetadata(self.allocator, value) else null;
            errdefer if (owned_interaction_metadata) |value| deinitMessageInteractionMetadata(value, self.allocator);
            const owned_application = if (application) |value| try copyApplication(self.allocator, value) else null;
            errdefer if (owned_application) |value| deinitApplication(value, self.allocator);
            const owned_activity = if (activity) |value| try copyMessageActivity(self.allocator, value) else null;
            errdefer if (owned_activity) |value| deinitMessageActivity(value, self.allocator);

            old.deinit(self.allocator);
            old.content = owned_content;
            old.member = owned_member;
            old.timestamp = owned_timestamp;
            old.edited_timestamp = owned_edited_timestamp;
            old.attachments = owned_attachments;
            old.reactions = owned_reactions;
            old.embeds = owned_embeds;
            old.mentions = owned_mentions;
            old.mention_roles = owned_mention_roles;
            old.mention_channels = owned_mention_channels;
            old.message_snapshots = owned_message_snapshots;
            old.sticker_items = owned_sticker_items;
            old.stickers = owned_stickers;
            old.components = owned_components;
            old.call = owned_call;
            old.role_subscription_data = owned_role_subscription_data;
            old.shared_client_theme = owned_shared_client_theme;
            old.poll = owned_poll;
            old.thread = owned_thread;
            old.channel_id = channel_id;
            old.guild_id = guild_id;
            old.message_reference = message_reference;
            old.referenced_message_id = referenced_message_id;
            old.webhook_id = webhook_id;
            old.application_id = application_id;
            old.application = owned_application;
            old.activity = owned_activity;
            old.interaction_metadata = owned_interaction_metadata;
            old.type = message_type;
            old.nonce = owned_nonce;
            old.tts = tts;
            old.mention_everyone = mention_everyone;
            old.pinned = pinned;
            old.position = position;
            old.flags = flags;
            if (object.get("member") != null) {
                if (old.member) |value| if (value.user != null) {
                    if (old.guild_id) |member_guild_id| try self.putMember(member_guild_id, value);
                };
            }
            if (object.get("thread") != null) {
                if (old.thread) |value| try self.putChannel(value);
            }
            if (object.get("interaction_metadata") != null) {
                if (old.interaction_metadata) |metadata| {
                    try self.putUser(metadata.user);
                    if (metadata.target_user) |user| try self.putUser(user);
                }
            }
            if (object.get("application") != null) {
                if (old.application) |application_value| {
                    if (application_value.bot) |bot| try self.putUser(bot);
                    if (application_value.owner) |owner| try self.putUser(owner);
                }
            }
            try self.messages.put(id.value, old);
        }

        pub fn addReactionFromJson(self: *Cache, data: std.json.Value) !void {
            const event = try reactionEventFromJson(data);
            var message = self.messages.get(event.message_id.value) orelse return;
            try incrementReaction(self.allocator, &message, event.emoji);
            try self.messages.put(event.message_id.value, message);
        }

        pub fn removeReactionFromJson(self: *Cache, data: std.json.Value) !void {
            const event = try reactionEventFromJson(data);
            var message = self.messages.get(event.message_id.value) orelse return;
            try decrementReaction(self.allocator, &message, event.emoji);
            try self.messages.put(event.message_id.value, message);
        }

        pub fn removeAllReactionsFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            const message_id = try snowflakeField(object, "message_id");
            var message = self.messages.get(message_id.value) orelse return;
            deinitReactions(message.reactions, self.allocator);
            message.reactions = try self.allocator.dupe(Types.MessageReaction, &.{});
            try self.messages.put(message_id.value, message);
        }

        pub fn removeReactionEmojiFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            const message_id = try snowflakeField(object, "message_id");
            const emoji = try reactionEmojiFromJson(object.get("emoji") orelse return error.MissingField);
            var message = self.messages.get(message_id.value) orelse return;
            try removeReactionEmoji(self.allocator, &message, emoji);
            try self.messages.put(message_id.value, message);
        }

        pub fn deleteMessageFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            self.removeMessage(try snowflakeField(object, "id"));
        }

        pub fn deleteMessagesFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            const ids = try requireArray(object.get("ids") orelse return error.MissingField);
            for (ids.items) |id| self.removeMessage(try snowflakeValue(id));
        }

        pub fn putChannelsFromJson(self: *Cache, guild_id: Snowflake, value: std.json.Value) !void {
            const channels = try requireArray(value);
            for (channels.items) |item| {
                const channel = try channelFromJson(self.allocator, item, guild_id);
                defer deinitParsedChannel(channel, self.allocator);
                try self.putChannel(channel);
            }
        }

        pub fn putChannelFromJson(self: *Cache, data: std.json.Value) !void {
            const channel = try channelFromJson(self.allocator, data, null);
            defer deinitParsedChannel(channel, self.allocator);
            try self.putChannel(channel);
        }

        pub fn deleteChannelFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            self.removeChannel(try snowflakeField(object, "id"));
        }

        pub fn updateChannelInfoFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            const channels = try requireArray(object.get("channels") orelse return);
            for (channels.items) |item| {
                const channel_info = try requireObject(item);
                const channel_id = if (channel_info.get("id")) |id| try snowflakeValue(id) else continue;
                const channel = self.channels.getPtr(channel_id.value) orelse continue;
                try self.applyChannelInfoFields(channel, channel_info);
            }
        }

        pub fn updateVoiceChannelStatusFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            const channel_id = if (object.get("id")) |id| try snowflakeValue(id) else return;
            const channel = self.channels.getPtr(channel_id.value) orelse return;
            try self.applyChannelStatusField(channel, object.get("status") orelse return);
        }

        pub fn updateVoiceChannelStartTimeFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            const channel_id = if (object.get("id")) |id| try snowflakeValue(id) else return;
            const channel = self.channels.getPtr(channel_id.value) orelse return;
            channel.voice_start_time = try nullableIntValue(object.get("voice_start_time") orelse return);
        }

        pub fn updateChannelPinsFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            const channel_id = try snowflakeField(object, "channel_id");
            const channel = self.channels.getPtr(channel_id.value) orelse return;
            const last_pin_timestamp = if (object.get("last_pin_timestamp")) |field| try optionalStringValue(field) else null;
            const owned_last_pin_timestamp = if (last_pin_timestamp) |value| try self.allocator.dupe(u8, value) else null;

            if (channel.last_pin_timestamp) |value| self.allocator.free(value);
            channel.last_pin_timestamp = owned_last_pin_timestamp;
        }

        pub fn applyChannelInfoFields(self: *Cache, channel: *OwnedChannel, object: std.json.ObjectMap) !void {
            if (object.get("status")) |field| try self.applyChannelStatusField(channel, field);
            if (object.get("voice_start_time")) |field| channel.voice_start_time = try nullableIntValue(field);
        }

        pub fn applyChannelStatusField(self: *Cache, channel: *OwnedChannel, field: std.json.Value) !void {
            const status = try optionalStringValue(field);
            const owned_status = if (status) |value| try self.allocator.dupe(u8, value) else null;

            if (channel.status) |value| self.allocator.free(value);
            channel.status = owned_status;
        }

        pub fn syncThreadsFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            const guild_id = try snowflakeField(object, "guild_id");

            var received = std.AutoHashMap(u64, void).init(self.allocator);
            defer received.deinit();

            const threads = try requireArray(object.get("threads") orelse return error.MissingField);
            for (threads.items) |item| {
                const thread = try channelFromJson(self.allocator, item, guild_id);
                defer deinitParsedChannel(thread, self.allocator);
                try received.put(thread.id.value, {});
                try self.putChannel(thread);
            }

            var synced_parent_ids = std.AutoHashMap(u64, void).init(self.allocator);
            defer synced_parent_ids.deinit();
            const has_parent_scope = object.get("channel_ids") != null;
            if (object.get("channel_ids")) |channel_ids| {
                const ids = try requireArray(channel_ids);
                for (ids.items) |item| {
                    const id = try snowflakeValue(item);
                    try synced_parent_ids.put(id.value, {});
                }
            }

            var stale_thread_ids = std.array_list.Managed(u64).init(self.allocator);
            defer stale_thread_ids.deinit();

            var iterator = self.channels.iterator();
            while (iterator.next()) |entry| {
                const channel = entry.value_ptr;
                if (!channelTypeIsThread(channel.type)) continue;
                const channel_guild_id = channel.guild_id orelse continue;
                if (channel_guild_id.value != guild_id.value) continue;
                if (received.contains(entry.key_ptr.*)) continue;

                if (has_parent_scope) {
                    const parent_id = channel.parent_id orelse continue;
                    if (!synced_parent_ids.contains(parent_id.value)) continue;
                }

                try stale_thread_ids.append(entry.key_ptr.*);
            }

            for (stale_thread_ids.items) |id| self.removeChannel(Snowflake.init(id));
        }

        pub fn updateThreadMemberCountFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            const thread_id = try snowflakeField(object, "id");
            const member_count: u32 = @intCast(try intField(object, "member_count"));
            const channel = self.channels.getPtr(thread_id.value) orelse return;
            if (!channelTypeIsThread(channel.type)) return;
            channel.member_count = member_count;
        }

        pub fn putMembersFromJson(self: *Cache, guild_id: Snowflake, value: std.json.Value) !void {
            const members = try requireArray(value);
            for (members.items) |item| {
                try self.putMemberFromJson(item, guild_id);
            }
        }

        pub fn putRolesFromJson(self: *Cache, guild_id: Snowflake, value: std.json.Value) !void {
            const roles = try requireArray(value);
            for (roles.items) |item| {
                try self.putRole(guild_id, try roleFromJson(item));
            }
        }

        pub fn putRoleEventFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            const guild_id = try snowflakeField(object, "guild_id");
            try self.putRole(guild_id, try roleFromJson(object.get("role") orelse return error.MissingField));
        }

        pub fn deleteRoleEventFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            self.removeRole(try snowflakeField(object, "guild_id"), try snowflakeField(object, "role_id"));
        }

        pub fn putGuildEmojisFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            const guild_id = try snowflakeField(object, "guild_id");
            self.removeGuildEmojis(guild_id);
            try self.putEmojisFromJson(guild_id, object.get("emojis") orelse return error.MissingField);
        }

        pub fn putEmojisFromJson(self: *Cache, guild_id: Snowflake, value: std.json.Value) !void {
            const emojis = try requireArray(value);
            for (emojis.items) |item| {
                const emoji = try emojiFromJson(self.allocator, item);
                defer self.allocator.free(emoji.roles);
                try self.putEmoji(guild_id, emoji);
            }
        }

        pub fn putStickersFromJson(self: *Cache, guild_id: Snowflake, value: std.json.Value) !void {
            const stickers = try requireArray(value);
            for (stickers.items) |item| try self.putSticker(guild_id, try stickerFromJson(item, guild_id));
        }

        pub fn putGuildStickersFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            const guild_id = try snowflakeField(object, "guild_id");
            self.removeGuildStickers(guild_id);
            try self.putStickersFromJson(guild_id, object.get("stickers") orelse return error.MissingField);
        }

        pub fn putScheduledEventsFromJson(self: *Cache, value: std.json.Value) !void {
            const events = try requireArray(value);
            for (events.items) |item| try self.putScheduledEvent(try scheduledEventFromJson(item));
        }

        pub fn putScheduledEventFromJson(self: *Cache, data: std.json.Value) !void {
            try self.putScheduledEvent(try scheduledEventFromJson(data));
        }

        pub fn deleteScheduledEventFromJson(self: *Cache, data: std.json.Value) !void {
            const event = try scheduledEventFromJson(data);
            self.removeScheduledEvent(event.guild_id, event.id);
        }

        pub fn incrementScheduledEventUserCountFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            const guild_id = try snowflakeField(object, "guild_id");
            const event_id = try snowflakeField(object, "guild_scheduled_event_id");
            const event = self.scheduled_events.getPtr(roleKey(guild_id, event_id)) orelse return;
            if (event.user_count) |count| event.user_count = count +| 1;
        }

        pub fn decrementScheduledEventUserCountFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            const guild_id = try snowflakeField(object, "guild_id");
            const event_id = try snowflakeField(object, "guild_scheduled_event_id");
            const event = self.scheduled_events.getPtr(roleKey(guild_id, event_id)) orelse return;
            if (event.user_count) |count| event.user_count = if (count == 0) 0 else count - 1;
        }

        pub fn putStageInstanceFromJson(self: *Cache, data: std.json.Value) !void {
            try self.putStageInstance(try stageInstanceFromJson(data));
        }

        pub fn putStageInstancesFromJson(self: *Cache, value: std.json.Value) !void {
            const stage_instances = try requireArray(value);
            for (stage_instances.items) |item| try self.putStageInstance(try stageInstanceFromJson(item));
        }

        pub fn deleteStageInstanceFromJson(self: *Cache, data: std.json.Value) !void {
            const stage_instance = try stageInstanceFromJson(data);
            self.removeStageInstance(stage_instance.guild_id, stage_instance.id);
        }

        pub fn putInviteFromJson(self: *Cache, data: std.json.Value) !void {
            try self.putInvite(try inviteFromJson(data));
        }

        pub fn deleteInviteFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            self.removeInvite(try stringField(object, "code"));
        }

        pub fn putMemberFromJson(self: *Cache, data: std.json.Value, fallback_guild_id: ?Snowflake) !void {
            const object = try requireObject(data);
            const guild_id = if (object.get("guild_id")) |value| try snowflakeValue(value) else fallback_guild_id orelse return error.MissingField;
            const member = try memberFromJson(self.allocator, data);
            defer self.allocator.free(member.roles);
            try self.putMember(guild_id, member);
        }

        pub fn addMemberFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            const guild_id = try snowflakeField(object, "guild_id");
            try self.putMemberFromJson(data, guild_id);
            self.incrementGuildMemberCount(guild_id);
        }

        pub fn deleteMemberFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            const guild_id = try snowflakeField(object, "guild_id");
            const user = try userFromJson(object.get("user") orelse return error.MissingField);
            try self.putUser(user);
            self.removeMember(guild_id, user.id);
            self.decrementGuildMemberCount(guild_id);
        }

        pub fn incrementGuildMemberCount(self: *Cache, guild_id: Snowflake) void {
            const guild = self.guilds.getPtr(guild_id.value) orelse return;
            if (guild.approximate_member_count) |count| guild.approximate_member_count = count +| 1;
        }

        pub fn decrementGuildMemberCount(self: *Cache, guild_id: Snowflake) void {
            const guild = self.guilds.getPtr(guild_id.value) orelse return;
            if (guild.approximate_member_count) |count| guild.approximate_member_count = if (count == 0) 0 else count - 1;
        }
    };
}
