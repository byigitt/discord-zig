const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Types = @import("../../models/types.zig");
const Gateway = @import("../../gateway/protocol.zig");
const Interactions = @import("../../interactions/mod.zig");
const Permissions = @import("../../core/permissions.zig");
const Collection = @import("../../core/collection.zig").Collection;

const Root = @import("../cache.zig");
const userFromJson = Root.userFromJson;
const applicationFromJson = Root.applicationFromJson;
const deinitParsedApplication = Root.deinitParsedApplication;
const channelFromJson = Root.channelFromJson;
const deinitParsedChannel = Root.deinitParsedChannel;
const deinitParsedChannels = Root.deinitParsedChannels;
const stickerArrayFromJson = Root.stickerArrayFromJson;
const presenceFromJson = Root.presenceFromJson;
const voiceStateFromJson = Root.voiceStateFromJson;
const messageReferenceFromJson = Root.messageReferenceFromJson;
const referencedMessageIdFromJson = Root.referencedMessageIdFromJson;
const messageSnapshotArrayFromJson = Root.messageSnapshotArrayFromJson;
const deinitParsedMessageSnapshots = Root.deinitParsedMessageSnapshots;
const memberFromJson = Root.memberFromJson;
const roleArrayFromJson = Root.roleArrayFromJson;
const userArrayFromJson = Root.userArrayFromJson;
const channelArrayFromJson = Root.channelArrayFromJson;
const stringArrayFromJson = Root.stringArrayFromJson;
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
const requireObject = Root.requireObject;
const requireArray = Root.requireArray;
const snowflakeField = Root.snowflakeField;
const snowflakeValue = Root.snowflakeValue;
const nullableSnowflakeValue = Root.nullableSnowflakeValue;
const stringField = Root.stringField;
const intValue = Root.intValue;
const messageNonceFromJson = Root.messageNonceFromJson;
const stringValue = Root.stringValue;
const optionalStringValue = Root.optionalStringValue;
const boolValue = Root.boolValue;

pub fn Methods(comptime Cache: type) type {
    return struct {
        pub fn removeGuildMembers(self: *Cache, guild_id: Snowflake) void {
            var keys = std.array_list.Managed(u128).init(self.allocator);
            defer keys.deinit();

            var iterator = self.members.iterator();
            while (iterator.next()) |entry| {
                if (entry.value_ptr.guild_id.value == guild_id.value) keys.append(entry.key_ptr.*) catch return;
            }

            for (keys.items) |key| {
                if (self.members.fetchRemove(key)) |old| old.value.deinit(self.allocator);
            }
        }

        pub fn removeGuildRoles(self: *Cache, guild_id: Snowflake) void {
            var keys = std.array_list.Managed(u128).init(self.allocator);
            defer keys.deinit();

            var iterator = self.roles.iterator();
            while (iterator.next()) |entry| {
                if (entry.value_ptr.guild_id.value == guild_id.value) keys.append(entry.key_ptr.*) catch return;
            }

            for (keys.items) |key| {
                if (self.roles.fetchRemove(key)) |old| old.value.deinit(self.allocator);
            }
        }

        pub fn removeRoleFromMembers(self: *Cache, guild_id: Snowflake, role_id: Snowflake) void {
            var iterator = self.members.valueIterator();
            while (iterator.next()) |member| {
                if (member.guild_id.value != guild_id.value) continue;

                var kept_count: usize = 0;
                for (member.roles) |member_role_id| {
                    if (member_role_id.value != role_id.value) kept_count += 1;
                }
                if (kept_count == member.roles.len) continue;

                const roles = self.allocator.alloc(Snowflake, kept_count) catch return;
                var index: usize = 0;
                for (member.roles) |member_role_id| {
                    if (member_role_id.value == role_id.value) continue;
                    roles[index] = member_role_id;
                    index += 1;
                }

                self.allocator.free(member.roles);
                member.roles = roles;
            }
        }

        pub fn removeGuildEmojis(self: *Cache, guild_id: Snowflake) void {
            var keys = std.array_list.Managed(u128).init(self.allocator);
            defer keys.deinit();

            var iterator = self.emojis.iterator();
            while (iterator.next()) |entry| {
                if (entry.value_ptr.guild_id.value == guild_id.value) keys.append(entry.key_ptr.*) catch return;
            }

            for (keys.items) |key| {
                if (self.emojis.fetchRemove(key)) |old| old.value.deinit(self.allocator);
            }
        }

        pub fn removeGuildStickers(self: *Cache, guild_id: Snowflake) void {
            var keys = std.array_list.Managed(u128).init(self.allocator);
            defer keys.deinit();

            var iterator = self.stickers.iterator();
            while (iterator.next()) |entry| {
                if (entry.value_ptr.guild_id.value == guild_id.value) keys.append(entry.key_ptr.*) catch return;
            }

            for (keys.items) |key| {
                if (self.stickers.fetchRemove(key)) |old| old.value.deinit(self.allocator);
            }
        }

        pub fn removeGuildScheduledEvents(self: *Cache, guild_id: Snowflake) void {
            var keys = std.array_list.Managed(u128).init(self.allocator);
            defer keys.deinit();

            var iterator = self.scheduled_events.iterator();
            while (iterator.next()) |entry| {
                if (entry.value_ptr.guild_id.value == guild_id.value) keys.append(entry.key_ptr.*) catch return;
            }

            for (keys.items) |key| {
                if (self.scheduled_events.fetchRemove(key)) |old| old.value.deinit(self.allocator);
            }
        }

        pub fn removeGuildStageInstances(self: *Cache, guild_id: Snowflake) void {
            var keys = std.array_list.Managed(u128).init(self.allocator);
            defer keys.deinit();

            var iterator = self.stage_instances.iterator();
            while (iterator.next()) |entry| {
                if (entry.value_ptr.guild_id.value == guild_id.value) keys.append(entry.key_ptr.*) catch return;
            }

            for (keys.items) |key| {
                if (self.stage_instances.fetchRemove(key)) |old| old.value.deinit(self.allocator);
            }
        }

        pub fn removeGuildInvites(self: *Cache, guild_id: Snowflake) void {
            var keys = std.array_list.Managed([]const u8).init(self.allocator);
            defer keys.deinit();

            var iterator = self.invites.iterator();
            while (iterator.next()) |entry| {
                if (entry.value_ptr.guild_id) |invite_guild_id| {
                    if (invite_guild_id.value == guild_id.value) keys.append(entry.key_ptr.*) catch return;
                }
            }

            for (keys.items) |key| self.removeInvite(key);
        }

        pub fn removeChannelInvites(self: *Cache, channel_id: Snowflake) void {
            var keys = std.array_list.Managed([]const u8).init(self.allocator);
            defer keys.deinit();

            var iterator = self.invites.iterator();
            while (iterator.next()) |entry| {
                if (entry.value_ptr.channel_id) |invite_channel_id| {
                    if (invite_channel_id.value == channel_id.value) keys.append(entry.key_ptr.*) catch return;
                }
            }

            for (keys.items) |key| self.removeInvite(key);
        }

        pub fn removeChannelMessages(self: *Cache, channel_id: Snowflake) void {
            var ids = std.array_list.Managed(u64).init(self.allocator);
            defer ids.deinit();

            var iterator = self.messages.iterator();
            while (iterator.next()) |entry| {
                if (entry.value_ptr.channel_id.value == channel_id.value) ids.append(entry.key_ptr.*) catch return;
            }

            for (ids.items) |id| self.removeMessage(Snowflake.init(id));
        }

        pub fn removeChannelVoiceStates(self: *Cache, channel_id: Snowflake) void {
            var keys = std.array_list.Managed(u128).init(self.allocator);
            defer keys.deinit();

            var iterator = self.voice_states.iterator();
            while (iterator.next()) |entry| {
                const voice_channel_id = entry.value_ptr.channel_id orelse continue;
                if (voice_channel_id.value == channel_id.value) keys.append(entry.key_ptr.*) catch return;
            }

            for (keys.items) |key| {
                if (self.voice_states.fetchRemove(key)) |old| old.value.deinit(self.allocator);
            }
        }

        pub fn removeGuildMessages(self: *Cache, guild_id: Snowflake) void {
            var ids = std.array_list.Managed(u64).init(self.allocator);
            defer ids.deinit();

            var iterator = self.messages.iterator();
            while (iterator.next()) |entry| {
                const message_guild_id = entry.value_ptr.guild_id orelse continue;
                if (message_guild_id.value == guild_id.value) ids.append(entry.key_ptr.*) catch return;
            }

            for (ids.items) |id| self.removeMessage(Snowflake.init(id));
        }

        pub fn removeGuildPresences(self: *Cache, guild_id: Snowflake) void {
            var keys = std.array_list.Managed(u128).init(self.allocator);
            defer keys.deinit();

            var iterator = self.presences.iterator();
            while (iterator.next()) |entry| {
                if (entry.value_ptr.guild_id.value == guild_id.value) keys.append(entry.key_ptr.*) catch return;
            }

            for (keys.items) |key| {
                if (self.presences.fetchRemove(key)) |old| old.value.deinit(self.allocator);
            }
        }

        pub fn removeGuildVoiceStates(self: *Cache, guild_id: Snowflake) void {
            var keys = std.array_list.Managed(u128).init(self.allocator);
            defer keys.deinit();

            var iterator = self.voice_states.iterator();
            while (iterator.next()) |entry| {
                if (entry.value_ptr.guild_id.value == guild_id.value) keys.append(entry.key_ptr.*) catch return;
            }

            for (keys.items) |key| {
                if (self.voice_states.fetchRemove(key)) |old| old.value.deinit(self.allocator);
            }
        }

        pub fn removeMessageOrder(self: *Cache, id: u64) void {
            var index: usize = 0;
            while (index < self.message_order.items.len) : (index += 1) {
                if (self.message_order.items[index] == id) {
                    _ = self.message_order.orderedRemove(index);
                    return;
                }
            }
        }

        pub fn enforceMessageLimit(self: *Cache) !void {
            const max = self.policy.max_messages orelse return;
            while (self.messages.count() > max and self.message_order.items.len != 0) {
                const id = self.message_order.orderedRemove(0);
                if (self.messages.fetchRemove(id)) |old| old.value.deinit(self.allocator);
            }
        }

        pub fn sweepMessagesBefore(self: *Cache, cutoff_ms: u64) usize {
            var removed: usize = 0;
            var index: usize = 0;
            while (index < self.message_order.items.len) {
                const id = self.message_order.items[index];
                if (Snowflake.init(id).timestampMillis() < cutoff_ms) {
                    _ = self.message_order.orderedRemove(index);
                    if (self.messages.fetchRemove(id)) |old| old.value.deinit(self.allocator);
                    removed += 1;
                } else {
                    index += 1;
                }
            }
            return removed;
        }

        pub fn sweepMessagesOlderThan(self: *Cache, max_age_ms: u64, now_ms: u64) usize {
            const cutoff = if (now_ms > max_age_ms) now_ms - max_age_ms else 0;
            return self.sweepMessagesBefore(cutoff);
        }

        pub fn sweep(self: *Cache, now_ms: u64) usize {
            var removed: usize = 0;
            if (self.policy.message_sweep_max_age_ms) |max_age| {
                removed += self.sweepMessagesOlderThan(max_age, now_ms);
            }
            return removed;
        }

        pub fn putGuildFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            const guild = Types.Guild{
                .id = try snowflakeField(object, "id"),
                .name = try stringField(object, "name"),
                .icon = if (object.get("icon")) |field| optionalStringValue(field) catch null else null,
                .banner = if (object.get("banner")) |field| optionalStringValue(field) catch null else null,
                .owner_id = if (object.get("owner_id")) |field| try nullableSnowflakeValue(field) else null,
                .description = if (object.get("description")) |field| optionalStringValue(field) catch null else null,
                .afk_channel_id = if (object.get("afk_channel_id")) |field| try nullableSnowflakeValue(field) else null,
                .afk_timeout = if (object.get("afk_timeout")) |field| @intCast(try intValue(field)) else null,
                .system_channel_id = if (object.get("system_channel_id")) |field| try nullableSnowflakeValue(field) else null,
                .rules_channel_id = if (object.get("rules_channel_id")) |field| try nullableSnowflakeValue(field) else null,
                .public_updates_channel_id = if (object.get("public_updates_channel_id")) |field| try nullableSnowflakeValue(field) else null,
                .safety_alerts_channel_id = if (object.get("safety_alerts_channel_id")) |field| try nullableSnowflakeValue(field) else null,
                .features = if (object.get("features")) |field| try stringArrayFromJson(self.allocator, field) else &.{},
                .preferred_locale = if (object.get("preferred_locale")) |field| optionalStringValue(field) catch null else null,
                .verification_level = if (object.get("verification_level")) |field| @intCast(try intValue(field)) else null,
                .default_message_notifications = if (object.get("default_message_notifications")) |field| @intCast(try intValue(field)) else null,
                .explicit_content_filter = if (object.get("explicit_content_filter")) |field| @intCast(try intValue(field)) else null,
                .mfa_level = if (object.get("mfa_level")) |field| @intCast(try intValue(field)) else null,
                .nsfw_level = if (object.get("nsfw_level")) |field| @intCast(try intValue(field)) else null,
                .max_presences = if (object.get("max_presences")) |field| @intCast(try intValue(field)) else null,
                .max_members = if (object.get("max_members")) |field| @intCast(try intValue(field)) else null,
                .premium_tier = if (object.get("premium_tier")) |field| @intCast(try intValue(field)) else null,
                .premium_subscription_count = if (object.get("premium_subscription_count")) |field| @intCast(try intValue(field)) else null,
                .premium_progress_bar_enabled = if (object.get("premium_progress_bar_enabled")) |field| try boolValue(field) else null,
                .approximate_member_count = if (object.get("approximate_member_count")) |field| @intCast(try intValue(field)) else null,
                .approximate_presence_count = if (object.get("approximate_presence_count")) |field| @intCast(try intValue(field)) else null,
            };
            defer if (guild.features.len != 0) self.allocator.free(guild.features);
            try self.putGuild(guild);
            if (object.get("channels")) |channels| try self.putChannelsFromJson(guild.id, channels);
            if (object.get("threads")) |threads| try self.putChannelsFromJson(guild.id, threads);
            if (object.get("members")) |members| try self.putMembersFromJson(guild.id, members);
            if (object.get("roles")) |roles| try self.putRolesFromJson(guild.id, roles);
            if (object.get("emojis")) |emojis| try self.putEmojisFromJson(guild.id, emojis);
            if (object.get("stickers")) |stickers| try self.putStickersFromJson(guild.id, stickers);
            if (object.get("guild_scheduled_events")) |events| try self.putScheduledEventsFromJson(events);
            if (object.get("stage_instances")) |stage_instances| try self.putStageInstancesFromJson(stage_instances);
            if (object.get("presences")) |presences| try self.putPresencesFromJson(presences);
            if (object.get("voice_states")) |voice_states| try self.putVoiceStatesFromJson(voice_states);
        }

        pub fn deleteGuildFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            if (object.get("unavailable")) |unavailable| {
                if (try boolValue(unavailable)) return;
            }
            self.removeGuild(try snowflakeField(object, "id"));
        }

        pub fn putUserFromJson(self: *Cache, data: std.json.Value) !void {
            try self.putUser(try userFromJson(data));
        }

        pub fn putReadyFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            if (object.get("user")) |user| try self.putCurrentUser(try userFromJson(user));
            if (object.get("application")) |application| {
                const parsed = try applicationFromJson(self.allocator, application);
                defer deinitParsedApplication(parsed, self.allocator);
                try self.putCurrentApplication(parsed);
            }
        }

        pub fn putPresenceFromJson(self: *Cache, data: std.json.Value) !void {
            const presence = try presenceFromJson(data);
            if (presence.status.len == "offline".len and std.mem.eql(u8, presence.status, "offline")) {
                self.removePresence(presence.guild_id.?, presence.user_id);
                return;
            }
            try self.putPresence(presence);
        }

        pub fn putPresencesFromJson(self: *Cache, value: std.json.Value) !void {
            const presences = try requireArray(value);
            for (presences.items) |item| try self.putPresenceFromJson(item);
        }

        pub fn putVoiceStateFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            const guild_id = try snowflakeField(object, "guild_id");
            const user_id = try snowflakeField(object, "user_id");
            if (object.get("member")) |member| try self.putMemberFromJson(member, guild_id);
            if (object.get("channel_id")) |channel_id| {
                if (channel_id == .null) {
                    self.removeVoiceState(guild_id, user_id);
                    return;
                }
            }
            try self.putVoiceState(try voiceStateFromJson(data));
        }

        pub fn putVoiceStatesFromJson(self: *Cache, value: std.json.Value) !void {
            const voice_states = try requireArray(value);
            for (voice_states.items) |item| try self.putVoiceStateFromJson(item);
        }

        pub fn putMessageFromJson(self: *Cache, data: std.json.Value) !void {
            const object = try requireObject(data);
            const author = if (object.get("author")) |value| try userFromJson(value) else null;
            var member = if (object.get("member")) |value| try memberFromJson(self.allocator, value) else null;
            defer if (member) |value| self.allocator.free(value.roles);
            if (member) |*value| {
                if (value.user == null) value.user = author;
            }
            const message_guild_id = if (object.get("guild_id")) |value| try snowflakeValue(value) else null;
            const attachments = if (object.get("attachments")) |value| try attachmentArrayFromJson(self.allocator, value) else try self.allocator.dupe(Types.Attachment, &.{});
            defer self.allocator.free(attachments);
            const reactions = if (object.get("reactions")) |value| try reactionArrayFromJson(self.allocator, value) else try self.allocator.dupe(Types.MessageReaction, &.{});
            defer deinitParsedReactions(reactions, self.allocator);
            const embeds = if (object.get("embeds")) |value| try embedArrayFromJson(self.allocator, value) else try self.allocator.dupe(Types.Embed, &.{});
            defer deinitParsedEmbeds(embeds, self.allocator);
            const mentions = if (object.get("mentions")) |value| try userArrayFromJson(self.allocator, value) else try self.allocator.dupe(Types.User, &.{});
            defer self.allocator.free(mentions);
            const mention_roles = if (object.get("mention_roles")) |value| try roleArrayFromJson(self.allocator, value) else try self.allocator.dupe(Snowflake, &.{});
            defer self.allocator.free(mention_roles);
            const mention_channels = if (object.get("mention_channels")) |value| try channelArrayFromJson(self.allocator, value, null) else try self.allocator.dupe(Types.Channel, &.{});
            defer deinitParsedChannels(mention_channels, self.allocator);
            const message_snapshots = if (object.get("message_snapshots")) |value| try messageSnapshotArrayFromJson(self.allocator, value) else try self.allocator.dupe(Types.MessageSnapshot, &.{});
            defer deinitParsedMessageSnapshots(message_snapshots, self.allocator);
            const sticker_items = if (object.get("sticker_items")) |value| try messageStickerItemArrayFromJson(self.allocator, value) else try self.allocator.dupe(Types.MessageStickerItem, &.{});
            defer self.allocator.free(sticker_items);
            const stickers = if (object.get("stickers")) |value| try stickerArrayFromJson(self.allocator, value, message_guild_id) else try self.allocator.dupe(Types.Sticker, &.{});
            defer self.allocator.free(stickers);
            const components = if (object.get("components")) |value| try componentArrayFromJson(self.allocator, value) else try self.allocator.dupe(Interactions.Component, &.{});
            defer deinitParsedComponentArray(components, self.allocator);
            const call = if (object.get("call")) |value| try messageCallFromJson(self.allocator, value) else null;
            defer deinitParsedMessageCall(call, self.allocator);
            const role_subscription_data = if (object.get("role_subscription_data")) |value| try nullableRoleSubscriptionDataFromJson(value) else null;
            const shared_client_theme = if (object.get("shared_client_theme")) |value| try sharedClientThemeFromJson(self.allocator, value) else null;
            defer deinitParsedSharedClientTheme(shared_client_theme, self.allocator);
            const poll = if (object.get("poll")) |value| try messagePollFromJson(self.allocator, value) else null;
            defer deinitParsedMessagePoll(poll, self.allocator);
            const application = if (object.get("application")) |value| try applicationFromJson(self.allocator, value) else null;
            defer deinitParsedApplication(application, self.allocator);
            const nonce = if (object.get("nonce")) |value| try messageNonceFromJson(self.allocator, value) else null;
            defer if (nonce) |value| value.deinit(self.allocator);
            const thread = if (object.get("thread")) |value| try channelFromJson(self.allocator, value, message_guild_id) else null;
            defer if (thread) |value| deinitParsedChannel(value, self.allocator);
            const message = Types.Message{
                .id = try snowflakeField(object, "id"),
                .channel_id = try snowflakeField(object, "channel_id"),
                .guild_id = message_guild_id,
                .author = author,
                .member = member,
                .message_reference = if (object.get("message_reference")) |value| try messageReferenceFromJson(value) else null,
                .referenced_message_id = if (object.get("referenced_message")) |value| try referencedMessageIdFromJson(value) else null,
                .message_snapshots = message_snapshots,
                .thread = thread,
                .call = call,
                .role_subscription_data = role_subscription_data,
                .shared_client_theme = shared_client_theme,
                .webhook_id = if (object.get("webhook_id")) |value| try nullableSnowflakeValue(value) else null,
                .application_id = if (object.get("application_id")) |value| try nullableSnowflakeValue(value) else null,
                .application = application,
                .activity = if (object.get("activity")) |value| try nullableMessageActivityFromJson(value) else null,
                .interaction_metadata = if (object.get("interaction_metadata")) |value| try messageInteractionMetadataFromJson(value) else null,
                .type = if (object.get("type")) |value| @intCast(try intValue(value)) else 0,
                .nonce = if (nonce) |value| value.value else null,
                .content = try stringField(object, "content"),
                .timestamp = if (object.get("timestamp")) |value| try stringValue(value) else null,
                .edited_timestamp = if (object.get("edited_timestamp")) |value| try optionalStringValue(value) else null,
                .tts = if (object.get("tts")) |value| try boolValue(value) else false,
                .mention_everyone = if (object.get("mention_everyone")) |value| try boolValue(value) else false,
                .pinned = if (object.get("pinned")) |value| try boolValue(value) else false,
                .position = if (object.get("position")) |value| @intCast(try intValue(value)) else null,
                .flags = if (object.get("flags")) |value| @intCast(try intValue(value)) else null,
                .mentions = mentions,
                .mention_roles = mention_roles,
                .mention_channels = mention_channels,
                .embeds = embeds,
                .attachments = attachments,
                .sticker_items = sticker_items,
                .stickers = stickers,
                .components = components,
                .poll = poll,
                .reactions = reactions,
            };
            try self.putMessage(message);
        }
    };
}
