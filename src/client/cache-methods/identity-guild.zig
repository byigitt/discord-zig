const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Types = @import("../../models/types.zig");
const Gateway = @import("../../gateway/protocol.zig");
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
const deinitApplication = Root.deinitApplication;
const memberKey = Root.memberKey;
const roleKey = Root.roleKey;
const clearOwnedMap = Root.clearOwnedMap;
const clearOwnedMapRetainingCapacity = Root.clearOwnedMapRetainingCapacity;
const channelTypeIsThread = Root.channelTypeIsThread;

pub fn Methods(comptime Cache: type) type {
    return struct {
        pub fn init(allocator: std.mem.Allocator) Cache {
            return initWithPolicy(allocator, .default());
        }

        pub fn initWithPolicy(allocator: std.mem.Allocator, policy: CachePolicy) Cache {
            return .{
                .allocator = allocator,
                .policy = policy,
                .users = std.AutoHashMap(u64, OwnedUser).init(allocator),
                .current_user_id = null,
                .current_application = null,
                .guilds = std.AutoHashMap(u64, OwnedGuild).init(allocator),
                .channels = std.AutoHashMap(u64, OwnedChannel).init(allocator),
                .members = std.AutoHashMap(u128, OwnedGuildMember).init(allocator),
                .roles = std.AutoHashMap(u128, OwnedRole).init(allocator),
                .emojis = std.AutoHashMap(u128, OwnedEmoji).init(allocator),
                .stickers = std.AutoHashMap(u128, OwnedSticker).init(allocator),
                .scheduled_events = std.AutoHashMap(u128, OwnedScheduledEvent).init(allocator),
                .stage_instances = std.AutoHashMap(u128, OwnedStageInstance).init(allocator),
                .invites = std.StringHashMap(OwnedInvite).init(allocator),
                .presences = std.AutoHashMap(u128, OwnedPresence).init(allocator),
                .voice_states = std.AutoHashMap(u128, OwnedVoiceState).init(allocator),
                .messages = std.AutoHashMap(u64, OwnedMessage).init(allocator),
                .message_order = std.array_list.Managed(u64).init(allocator),
            };
        }

        pub fn deinit(self: *Cache) void {
            if (self.current_application) |application| deinitApplication(application, self.allocator);
            clearOwnedMap(&self.users, self.allocator);
            clearOwnedMap(&self.guilds, self.allocator);
            clearOwnedMap(&self.channels, self.allocator);
            clearOwnedMap(&self.members, self.allocator);
            clearOwnedMap(&self.roles, self.allocator);
            clearOwnedMap(&self.emojis, self.allocator);
            clearOwnedMap(&self.stickers, self.allocator);
            clearOwnedMap(&self.scheduled_events, self.allocator);
            clearOwnedMap(&self.stage_instances, self.allocator);
            clearOwnedMap(&self.invites, self.allocator);
            clearOwnedMap(&self.presences, self.allocator);
            clearOwnedMap(&self.voice_states, self.allocator);
            clearOwnedMap(&self.messages, self.allocator);
            self.message_order.deinit();
        }

        pub fn applyDispatch(self: *Cache, dispatch: Gateway.ParsedDispatch) !void {
            switch (dispatch.event) {
                .READY => try self.putReadyFromJson(dispatch.data),
                .MESSAGE_CREATE => try self.putMessageFromJson(dispatch.data),
                .MESSAGE_UPDATE => try self.updateMessageFromJson(dispatch.data),
                .MESSAGE_DELETE => try self.deleteMessageFromJson(dispatch.data),
                .MESSAGE_DELETE_BULK => try self.deleteMessagesFromJson(dispatch.data),
                .MESSAGE_REACTION_ADD => try self.addReactionFromJson(dispatch.data),
                .MESSAGE_REACTION_REMOVE => try self.removeReactionFromJson(dispatch.data),
                .MESSAGE_REACTION_REMOVE_ALL => try self.removeAllReactionsFromJson(dispatch.data),
                .MESSAGE_REACTION_REMOVE_EMOJI => try self.removeReactionEmojiFromJson(dispatch.data),
                .USER_UPDATE => try self.putUserFromJson(dispatch.data),
                .PRESENCE_UPDATE => try self.putPresenceFromJson(dispatch.data),
                .VOICE_STATE_UPDATE => try self.putVoiceStateFromJson(dispatch.data),
                .GUILD_CREATE, .GUILD_UPDATE => try self.putGuildFromJson(dispatch.data),
                .GUILD_DELETE => try self.deleteGuildFromJson(dispatch.data),
                .GUILD_MEMBER_ADD => try self.addMemberFromJson(dispatch.data),
                .GUILD_MEMBER_UPDATE => try self.putMemberFromJson(dispatch.data, null),
                .GUILD_MEMBER_REMOVE => try self.deleteMemberFromJson(dispatch.data),
                .GUILD_ROLE_CREATE, .GUILD_ROLE_UPDATE => try self.putRoleEventFromJson(dispatch.data),
                .GUILD_ROLE_DELETE => try self.deleteRoleEventFromJson(dispatch.data),
                .GUILD_EMOJIS_UPDATE => try self.putGuildEmojisFromJson(dispatch.data),
                .GUILD_STICKERS_UPDATE => try self.putGuildStickersFromJson(dispatch.data),
                .GUILD_SCHEDULED_EVENT_CREATE, .GUILD_SCHEDULED_EVENT_UPDATE => try self.putScheduledEventFromJson(dispatch.data),
                .GUILD_SCHEDULED_EVENT_DELETE => try self.deleteScheduledEventFromJson(dispatch.data),
                .GUILD_SCHEDULED_EVENT_USER_ADD => try self.incrementScheduledEventUserCountFromJson(dispatch.data),
                .GUILD_SCHEDULED_EVENT_USER_REMOVE => try self.decrementScheduledEventUserCountFromJson(dispatch.data),
                .STAGE_INSTANCE_CREATE, .STAGE_INSTANCE_UPDATE => try self.putStageInstanceFromJson(dispatch.data),
                .STAGE_INSTANCE_DELETE => try self.deleteStageInstanceFromJson(dispatch.data),
                .INVITE_CREATE => try self.putInviteFromJson(dispatch.data),
                .INVITE_DELETE => try self.deleteInviteFromJson(dispatch.data),
                .CHANNEL_CREATE, .CHANNEL_UPDATE => try self.putChannelFromJson(dispatch.data),
                .CHANNEL_DELETE => try self.deleteChannelFromJson(dispatch.data),
                .CHANNEL_INFO => try self.updateChannelInfoFromJson(dispatch.data),
                .VOICE_CHANNEL_STATUS_UPDATE => try self.updateVoiceChannelStatusFromJson(dispatch.data),
                .VOICE_CHANNEL_START_TIME_UPDATE => try self.updateVoiceChannelStartTimeFromJson(dispatch.data),
                .CHANNEL_PINS_UPDATE => try self.updateChannelPinsFromJson(dispatch.data),
                .THREAD_CREATE, .THREAD_UPDATE => try self.putChannelFromJson(dispatch.data),
                .THREAD_DELETE => try self.deleteChannelFromJson(dispatch.data),
                .THREAD_LIST_SYNC => try self.syncThreadsFromJson(dispatch.data),
                .THREAD_MEMBERS_UPDATE => try self.updateThreadMemberCountFromJson(dispatch.data),
                else => {},
            }
        }

        pub fn getUser(self: *Cache, id: Snowflake) ?Types.User {
            const owned = self.users.get(id.value) orelse return null;
            return owned.view();
        }

        pub fn hasUser(self: *Cache, id: Snowflake) bool {
            return self.users.contains(id.value);
        }

        pub fn getCurrentUser(self: *Cache) ?Types.User {
            const id = self.current_user_id orelse return null;
            return self.getUser(id);
        }

        pub fn currentUserId(self: *Cache) ?Snowflake {
            const id = self.current_user_id orelse return null;
            if (!self.hasUser(id)) return null;
            return id;
        }

        pub fn hasCurrentUser(self: *Cache) bool {
            const id = self.current_user_id orelse return false;
            return self.hasUser(id);
        }

        pub fn getCurrentApplication(self: *Cache) ?Types.Application {
            return self.current_application;
        }

        pub fn currentApplicationId(self: *Cache) ?Snowflake {
            const application = self.current_application orelse return null;
            return application.id;
        }

        pub fn hasCurrentApplication(self: *Cache) bool {
            return self.current_application != null;
        }

        pub fn getGuild(self: *Cache, id: Snowflake) ?Types.Guild {
            const owned = self.guilds.get(id.value) orelse return null;
            return owned.view();
        }

        pub fn hasGuild(self: *Cache, id: Snowflake) bool {
            return self.guilds.contains(id.value);
        }

        pub fn getChannel(self: *Cache, id: Snowflake) ?Types.Channel {
            const owned = self.channels.get(id.value) orelse return null;
            return owned.view();
        }

        pub fn hasChannel(self: *Cache, id: Snowflake) bool {
            return self.channels.contains(id.value);
        }

        pub fn getMember(self: *Cache, guild_id: Snowflake, user_id: Snowflake) ?Types.GuildMember {
            const owned = self.members.get(memberKey(guild_id, user_id)) orelse return null;
            return owned.view(self.getUser(user_id));
        }

        pub fn hasMember(self: *Cache, guild_id: Snowflake, user_id: Snowflake) bool {
            return self.members.contains(memberKey(guild_id, user_id));
        }

        pub fn getRole(self: *Cache, guild_id: Snowflake, role_id: Snowflake) ?Types.Role {
            const owned = self.roles.get(roleKey(guild_id, role_id)) orelse return null;
            return owned.view();
        }

        pub fn hasRole(self: *Cache, guild_id: Snowflake, role_id: Snowflake) bool {
            return self.roles.contains(roleKey(guild_id, role_id));
        }

        pub fn getEmoji(self: *Cache, guild_id: Snowflake, emoji_id: Snowflake) ?Types.Emoji {
            const owned = self.emojis.get(roleKey(guild_id, emoji_id)) orelse return null;
            const user = if (owned.user_id) |user_id| self.getUser(user_id) else null;
            return owned.view(user);
        }

        pub fn hasEmoji(self: *Cache, guild_id: Snowflake, emoji_id: Snowflake) bool {
            return self.emojis.contains(roleKey(guild_id, emoji_id));
        }

        pub fn getSticker(self: *Cache, guild_id: Snowflake, sticker_id: Snowflake) ?Types.Sticker {
            const owned = self.stickers.get(roleKey(guild_id, sticker_id)) orelse return null;
            const user = if (owned.user_id) |user_id| self.getUser(user_id) else null;
            return owned.view(user);
        }

        pub fn hasSticker(self: *Cache, guild_id: Snowflake, sticker_id: Snowflake) bool {
            return self.stickers.contains(roleKey(guild_id, sticker_id));
        }

        pub fn getScheduledEvent(self: *Cache, guild_id: Snowflake, event_id: Snowflake) ?Types.GuildScheduledEvent {
            const owned = self.scheduled_events.get(roleKey(guild_id, event_id)) orelse return null;
            return owned.view();
        }

        pub fn hasScheduledEvent(self: *Cache, guild_id: Snowflake, event_id: Snowflake) bool {
            return self.scheduled_events.contains(roleKey(guild_id, event_id));
        }

        pub fn getStageInstance(self: *Cache, guild_id: Snowflake, stage_instance_id: Snowflake) ?Types.StageInstance {
            const owned = self.stage_instances.get(roleKey(guild_id, stage_instance_id)) orelse return null;
            return owned.view();
        }

        pub fn hasStageInstance(self: *Cache, guild_id: Snowflake, stage_instance_id: Snowflake) bool {
            return self.stage_instances.contains(roleKey(guild_id, stage_instance_id));
        }

        pub fn getInvite(self: *Cache, code: []const u8) ?Types.Invite {
            const owned = self.invites.get(code) orelse return null;
            return owned.view();
        }

        pub fn hasInvite(self: *Cache, code: []const u8) bool {
            return self.invites.contains(code);
        }

        pub fn getPresence(self: *Cache, guild_id: Snowflake, user_id: Snowflake) ?Types.Presence {
            const owned = self.presences.get(memberKey(guild_id, user_id)) orelse return null;
            return owned.view();
        }

        pub fn hasPresence(self: *Cache, guild_id: Snowflake, user_id: Snowflake) bool {
            return self.presences.contains(memberKey(guild_id, user_id));
        }

        pub fn getVoiceState(self: *Cache, guild_id: Snowflake, user_id: Snowflake) ?Types.VoiceState {
            const owned = self.voice_states.get(memberKey(guild_id, user_id)) orelse return null;
            return owned.view(self.getMember(guild_id, user_id));
        }

        pub fn hasVoiceState(self: *Cache, guild_id: Snowflake, user_id: Snowflake) bool {
            return self.voice_states.contains(memberKey(guild_id, user_id));
        }

        pub fn getMessage(self: *Cache, id: Snowflake) ?Types.Message {
            const owned = self.messages.get(id.value) orelse return null;
            return owned.view(self.getUser(owned.author_id));
        }

        pub fn hasMessage(self: *Cache, id: Snowflake) bool {
            return self.messages.contains(id.value);
        }

        pub fn clear(self: *Cache) void {
            self.current_user_id = null;
            if (self.current_application) |application| deinitApplication(application, self.allocator);
            self.current_application = null;
            clearOwnedMapRetainingCapacity(&self.users, self.allocator);
            clearOwnedMapRetainingCapacity(&self.guilds, self.allocator);
            clearOwnedMapRetainingCapacity(&self.channels, self.allocator);
            clearOwnedMapRetainingCapacity(&self.members, self.allocator);
            clearOwnedMapRetainingCapacity(&self.roles, self.allocator);
            clearOwnedMapRetainingCapacity(&self.emojis, self.allocator);
            clearOwnedMapRetainingCapacity(&self.stickers, self.allocator);
            clearOwnedMapRetainingCapacity(&self.scheduled_events, self.allocator);
            clearOwnedMapRetainingCapacity(&self.stage_instances, self.allocator);
            clearOwnedMapRetainingCapacity(&self.invites, self.allocator);
            clearOwnedMapRetainingCapacity(&self.presences, self.allocator);
            clearOwnedMapRetainingCapacity(&self.voice_states, self.allocator);
            clearOwnedMapRetainingCapacity(&self.messages, self.allocator);
            self.message_order.clearRetainingCapacity();
        }

        pub fn stats(self: *Cache) CacheStats {
            return .{
                .users = self.users.count(),
                .current_user = self.current_user_id != null,
                .current_application = self.current_application != null,
                .guilds = self.guilds.count(),
                .channels = self.channels.count(),
                .members = self.members.count(),
                .roles = self.roles.count(),
                .emojis = self.emojis.count(),
                .stickers = self.stickers.count(),
                .scheduled_events = self.scheduled_events.count(),
                .stage_instances = self.stage_instances.count(),
                .invites = self.invites.count(),
                .presences = self.presences.count(),
                .voice_states = self.voice_states.count(),
                .messages = self.messages.count(),
            };
        }

        pub fn guildStats(self: *Cache, guild_id: Snowflake) GuildCacheStats {
            var result = GuildCacheStats{};

            var channels = self.channels.valueIterator();
            while (channels.next()) |channel| {
                const channel_guild_id = channel.guild_id orelse continue;
                if (channel_guild_id.value != guild_id.value) continue;
                if (channelTypeIsThread(channel.type)) {
                    result.threads += 1;
                } else {
                    result.channels += 1;
                }
            }

            var members = self.members.valueIterator();
            while (members.next()) |member| {
                if (member.guild_id.value == guild_id.value) result.members += 1;
            }

            var roles = self.roles.valueIterator();
            while (roles.next()) |role| {
                if (role.guild_id.value == guild_id.value) result.roles += 1;
            }

            var emojis = self.emojis.valueIterator();
            while (emojis.next()) |emoji| {
                if (emoji.guild_id.value == guild_id.value) result.emojis += 1;
            }

            var stickers = self.stickers.valueIterator();
            while (stickers.next()) |sticker| {
                if (sticker.guild_id.value == guild_id.value) result.stickers += 1;
            }

            var scheduled_events = self.scheduled_events.valueIterator();
            while (scheduled_events.next()) |event| {
                if (event.guild_id.value == guild_id.value) result.scheduled_events += 1;
            }

            var stage_instances = self.stage_instances.valueIterator();
            while (stage_instances.next()) |stage_instance| {
                if (stage_instance.guild_id.value == guild_id.value) result.stage_instances += 1;
            }

            var invites = self.invites.valueIterator();
            while (invites.next()) |invite| {
                const invite_guild_id = invite.guild_id orelse continue;
                if (invite_guild_id.value == guild_id.value) result.invites += 1;
            }

            var presences = self.presences.valueIterator();
            while (presences.next()) |presence| {
                if (presence.guild_id.value == guild_id.value) result.presences += 1;
            }

            var voice_states = self.voice_states.valueIterator();
            while (voice_states.next()) |voice_state| {
                if (voice_state.guild_id.value == guild_id.value) result.voice_states += 1;
            }

            var messages = self.messages.valueIterator();
            while (messages.next()) |message| {
                const message_guild_id = message.guild_id orelse continue;
                if (message_guild_id.value == guild_id.value) result.messages += 1;
            }

            return result;
        }

        pub fn channelStats(self: *Cache, channel_id: Snowflake) ChannelCacheStats {
            var result = ChannelCacheStats{};

            var channels = self.channels.valueIterator();
            while (channels.next()) |channel| {
                if (!channelTypeIsThread(channel.type)) continue;
                const parent_id = channel.parent_id orelse continue;
                if (parent_id.value == channel_id.value) result.threads += 1;
            }

            var invites = self.invites.valueIterator();
            while (invites.next()) |invite| {
                const invite_channel_id = invite.channel_id orelse continue;
                if (invite_channel_id.value == channel_id.value) result.invites += 1;
            }

            var voice_states = self.voice_states.valueIterator();
            while (voice_states.next()) |voice_state| {
                const voice_channel_id = voice_state.channel_id orelse continue;
                if (voice_channel_id.value == channel_id.value) result.voice_states += 1;
            }

            var messages = self.messages.valueIterator();
            while (messages.next()) |message| {
                if (message.channel_id.value == channel_id.value) result.messages += 1;
            }

            return result;
        }

        pub fn listUsers(self: *Cache, allocator: std.mem.Allocator) ![]Types.User {
            var users = std.array_list.Managed(Types.User).init(allocator);
            errdefer users.deinit();

            var iterator = self.users.valueIterator();
            while (iterator.next()) |owned| try users.append(owned.view());
            return users.toOwnedSlice();
        }

        pub fn listGuilds(self: *Cache, allocator: std.mem.Allocator) ![]Types.Guild {
            var guilds = std.array_list.Managed(Types.Guild).init(allocator);
            errdefer guilds.deinit();

            var iterator = self.guilds.valueIterator();
            while (iterator.next()) |owned| try guilds.append(owned.view());
            return guilds.toOwnedSlice();
        }

        pub fn listChannels(self: *Cache, allocator: std.mem.Allocator) ![]Types.Channel {
            var channels = std.array_list.Managed(Types.Channel).init(allocator);
            errdefer channels.deinit();

            var iterator = self.channels.valueIterator();
            while (iterator.next()) |owned| try channels.append(owned.view());
            return channels.toOwnedSlice();
        }

        pub fn collectGuilds(self: *Cache, allocator: std.mem.Allocator) !Collection(u64, Types.Guild) {
            var result = Collection(u64, Types.Guild).init(allocator);
            errdefer result.deinit();
            var iterator = self.guilds.valueIterator();
            while (iterator.next()) |owned| {
                const guild = owned.view();
                try result.set(guild.id.value, guild);
            }
            return result;
        }

        pub fn collectChannels(self: *Cache, allocator: std.mem.Allocator) !Collection(u64, Types.Channel) {
            var result = Collection(u64, Types.Channel).init(allocator);
            errdefer result.deinit();
            var iterator = self.channels.valueIterator();
            while (iterator.next()) |owned| {
                const channel = owned.view();
                try result.set(channel.id.value, channel);
            }
            return result;
        }

        pub fn collectUsers(self: *Cache, allocator: std.mem.Allocator) !Collection(u64, Types.User) {
            var result = Collection(u64, Types.User).init(allocator);
            errdefer result.deinit();
            var iterator = self.users.valueIterator();
            while (iterator.next()) |owned| {
                const user = owned.view();
                try result.set(user.id.value, user);
            }
            return result;
        }

        pub fn collectRoles(self: *Cache, allocator: std.mem.Allocator) !Collection(u64, Types.Role) {
            var result = Collection(u64, Types.Role).init(allocator);
            errdefer result.deinit();
            var iterator = self.roles.valueIterator();
            while (iterator.next()) |owned| {
                const role = owned.view();
                try result.set(role.id.value, role);
            }
            return result;
        }

        pub fn listTopLevelChannels(self: *Cache, allocator: std.mem.Allocator) ![]Types.Channel {
            var channels = std.array_list.Managed(Types.Channel).init(allocator);
            errdefer channels.deinit();

            var iterator = self.channels.valueIterator();
            while (iterator.next()) |owned| {
                if (channelTypeIsThread(owned.type)) continue;
                try channels.append(owned.view());
            }
            return channels.toOwnedSlice();
        }

        pub fn listGuildChannels(self: *Cache, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Channel {
            var channels = std.array_list.Managed(Types.Channel).init(allocator);
            errdefer channels.deinit();

            var iterator = self.channels.valueIterator();
            while (iterator.next()) |owned| {
                if (channelTypeIsThread(owned.type)) continue;
                const channel_guild_id = owned.guild_id orelse continue;
                if (channel_guild_id.value == guild_id.value) try channels.append(owned.view());
            }
            return channels.toOwnedSlice();
        }

        pub fn listChannelThreads(self: *Cache, allocator: std.mem.Allocator, parent_channel_id: Snowflake) ![]Types.Channel {
            var threads = std.array_list.Managed(Types.Channel).init(allocator);
            errdefer threads.deinit();

            var iterator = self.channels.valueIterator();
            while (iterator.next()) |owned| {
                if (!channelTypeIsThread(owned.type)) continue;
                const parent_id = owned.parent_id orelse continue;
                if (parent_id.value == parent_channel_id.value) try threads.append(owned.view());
            }
            return threads.toOwnedSlice();
        }

        pub fn listGuildThreads(self: *Cache, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Channel {
            var threads = std.array_list.Managed(Types.Channel).init(allocator);
            errdefer threads.deinit();

            var iterator = self.channels.valueIterator();
            while (iterator.next()) |owned| {
                if (!channelTypeIsThread(owned.type)) continue;
                const channel_guild_id = owned.guild_id orelse continue;
                if (channel_guild_id.value == guild_id.value) try threads.append(owned.view());
            }
            return threads.toOwnedSlice();
        }
    };
}
