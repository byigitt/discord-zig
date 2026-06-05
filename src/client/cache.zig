const std = @import("std");
const Snowflake = @import("../core/snowflake.zig").Snowflake;
const Types = @import("../models/types.zig");
const Gateway = @import("../gateway/protocol.zig");
const Interactions = @import("../interactions/mod.zig");
const Permissions = @import("../core/permissions.zig");
const Collection = @import("../core/collection.zig").Collection;

pub const CachePolicy = struct {
    users: bool = true,
    guilds: bool = true,
    channels: bool = true,
    members: bool = true,
    roles: bool = true,
    emojis: bool = true,
    stickers: bool = true,
    scheduled_events: bool = true,
    stage_instances: bool = true,
    invites: bool = true,
    presences: bool = true,
    voice_states: bool = true,
    messages: bool = true,
    max_messages: ?usize = 1000,
    /// When set, `sweep` evicts cached messages older than this age in
    /// milliseconds (creation time derived from the message snowflake).
    message_sweep_max_age_ms: ?u64 = null,

    pub fn default() CachePolicy {
        return .{};
    }

    pub fn noMessages() CachePolicy {
        return .{ .messages = false, .max_messages = 0 };
    }

    pub fn minimal() CachePolicy {
        return .{ .users = false, .guilds = false, .channels = false, .members = false, .roles = false, .emojis = false, .stickers = false, .scheduled_events = false, .stage_instances = false, .invites = false, .presences = false, .voice_states = false, .messages = false, .max_messages = 0 };
    }
};

pub const CacheStats = struct {
    users: usize = 0,
    current_user: bool = false,
    current_application: bool = false,
    guilds: usize = 0,
    channels: usize = 0,
    members: usize = 0,
    roles: usize = 0,
    emojis: usize = 0,
    stickers: usize = 0,
    scheduled_events: usize = 0,
    stage_instances: usize = 0,
    invites: usize = 0,
    presences: usize = 0,
    voice_states: usize = 0,
    messages: usize = 0,
};

pub const GuildCacheStats = struct {
    channels: usize = 0,
    threads: usize = 0,
    members: usize = 0,
    roles: usize = 0,
    emojis: usize = 0,
    stickers: usize = 0,
    scheduled_events: usize = 0,
    stage_instances: usize = 0,
    invites: usize = 0,
    presences: usize = 0,
    voice_states: usize = 0,
    messages: usize = 0,
};

pub const ChannelCacheStats = struct {
    threads: usize = 0,
    invites: usize = 0,
    voice_states: usize = 0,
    messages: usize = 0,
};

pub const Cache = struct {
    allocator: std.mem.Allocator,
    policy: CachePolicy,
    users: std.AutoHashMap(u64, OwnedUser),
    current_user_id: ?Snowflake,
    current_application: ?Types.Application,
    guilds: std.AutoHashMap(u64, OwnedGuild),
    channels: std.AutoHashMap(u64, OwnedChannel),
    members: std.AutoHashMap(u128, OwnedGuildMember),
    roles: std.AutoHashMap(u128, OwnedRole),
    emojis: std.AutoHashMap(u128, OwnedEmoji),
    stickers: std.AutoHashMap(u128, OwnedSticker),
    scheduled_events: std.AutoHashMap(u128, OwnedScheduledEvent),
    stage_instances: std.AutoHashMap(u128, OwnedStageInstance),
    invites: std.StringHashMap(OwnedInvite),
    presences: std.AutoHashMap(u128, OwnedPresence),
    voice_states: std.AutoHashMap(u128, OwnedVoiceState),
    messages: std.AutoHashMap(u64, OwnedMessage),
    message_order: std.array_list.Managed(u64),

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

    /// Snapshots cached guilds into a Discord.js-style `Collection` keyed by id,
    /// giving `find`/`filter`/`first`/iteration ergonomics over the live cache.
    /// Values borrow cache-owned memory and stay valid until the cache mutates;
    /// the caller owns the returned collection and must `deinit` it.
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

    /// Snapshots cached channels into a Discord.js-style `Collection` keyed by
    /// id. Values borrow cache-owned memory; the caller owns and `deinit`s the
    /// returned collection.
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

    /// Snapshots cached users into a Discord.js-style `Collection` keyed by id.
    /// Values borrow cache-owned memory; the caller owns and `deinit`s the
    /// returned collection.
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

    /// Snapshots all cached roles into a Discord.js-style `Collection` keyed by
    /// id. Values borrow cache-owned memory; the caller owns and `deinit`s the
    /// returned collection.
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

    fn putMessageAssociations(self: *Cache, message: Types.Message) !void {
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

    fn removeGuildChannels(self: *Cache, guild_id: Snowflake) void {
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

    fn removeChildThreads(self: *Cache, parent_channel_id: Snowflake) void {
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

    fn removeGuildMembers(self: *Cache, guild_id: Snowflake) void {
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

    fn removeGuildRoles(self: *Cache, guild_id: Snowflake) void {
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

    fn removeRoleFromMembers(self: *Cache, guild_id: Snowflake, role_id: Snowflake) void {
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

    fn removeGuildEmojis(self: *Cache, guild_id: Snowflake) void {
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

    fn removeGuildStickers(self: *Cache, guild_id: Snowflake) void {
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

    fn removeGuildScheduledEvents(self: *Cache, guild_id: Snowflake) void {
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

    fn removeGuildStageInstances(self: *Cache, guild_id: Snowflake) void {
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

    fn removeGuildInvites(self: *Cache, guild_id: Snowflake) void {
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

    fn removeChannelInvites(self: *Cache, channel_id: Snowflake) void {
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

    fn removeChannelMessages(self: *Cache, channel_id: Snowflake) void {
        var ids = std.array_list.Managed(u64).init(self.allocator);
        defer ids.deinit();

        var iterator = self.messages.iterator();
        while (iterator.next()) |entry| {
            if (entry.value_ptr.channel_id.value == channel_id.value) ids.append(entry.key_ptr.*) catch return;
        }

        for (ids.items) |id| self.removeMessage(Snowflake.init(id));
    }

    fn removeChannelVoiceStates(self: *Cache, channel_id: Snowflake) void {
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

    fn removeGuildMessages(self: *Cache, guild_id: Snowflake) void {
        var ids = std.array_list.Managed(u64).init(self.allocator);
        defer ids.deinit();

        var iterator = self.messages.iterator();
        while (iterator.next()) |entry| {
            const message_guild_id = entry.value_ptr.guild_id orelse continue;
            if (message_guild_id.value == guild_id.value) ids.append(entry.key_ptr.*) catch return;
        }

        for (ids.items) |id| self.removeMessage(Snowflake.init(id));
    }

    fn removeGuildPresences(self: *Cache, guild_id: Snowflake) void {
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

    fn removeGuildVoiceStates(self: *Cache, guild_id: Snowflake) void {
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

    fn removeMessageOrder(self: *Cache, id: u64) void {
        var index: usize = 0;
        while (index < self.message_order.items.len) : (index += 1) {
            if (self.message_order.items[index] == id) {
                _ = self.message_order.orderedRemove(index);
                return;
            }
        }
    }

    fn enforceMessageLimit(self: *Cache) !void {
        const max = self.policy.max_messages orelse return;
        while (self.messages.count() > max and self.message_order.items.len != 0) {
            const id = self.message_order.orderedRemove(0);
            if (self.messages.fetchRemove(id)) |old| old.value.deinit(self.allocator);
        }
    }

    /// Evicts cached messages created before `cutoff_ms` (Unix milliseconds),
    /// deriving each message's creation time from its snowflake id. Returns the
    /// number of messages removed.
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

    /// Evicts cached messages older than `max_age_ms` relative to `now_ms`
    /// (both Unix milliseconds). Returns the number of messages removed.
    pub fn sweepMessagesOlderThan(self: *Cache, max_age_ms: u64, now_ms: u64) usize {
        const cutoff = if (now_ms > max_age_ms) now_ms - max_age_ms else 0;
        return self.sweepMessagesBefore(cutoff);
    }

    /// Applies the configured cache sweepers at time `now_ms` (Unix ms) and
    /// returns how many entries were evicted. Call this from a runtime timer to
    /// schedule periodic sweeps; `CachePolicy` controls what is swept.
    pub fn sweep(self: *Cache, now_ms: u64) usize {
        var removed: usize = 0;
        if (self.policy.message_sweep_max_age_ms) |max_age| {
            removed += self.sweepMessagesOlderThan(max_age, now_ms);
        }
        return removed;
    }

    fn putGuildFromJson(self: *Cache, data: std.json.Value) !void {
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

    fn deleteGuildFromJson(self: *Cache, data: std.json.Value) !void {
        const object = try requireObject(data);
        if (object.get("unavailable")) |unavailable| {
            if (try boolValue(unavailable)) return;
        }
        self.removeGuild(try snowflakeField(object, "id"));
    }

    fn putUserFromJson(self: *Cache, data: std.json.Value) !void {
        try self.putUser(try userFromJson(data));
    }

    fn putReadyFromJson(self: *Cache, data: std.json.Value) !void {
        const object = try requireObject(data);
        if (object.get("user")) |user| try self.putCurrentUser(try userFromJson(user));
        if (object.get("application")) |application| {
            const parsed = try applicationFromJson(self.allocator, application);
            defer deinitParsedApplication(parsed, self.allocator);
            try self.putCurrentApplication(parsed);
        }
    }

    fn putPresenceFromJson(self: *Cache, data: std.json.Value) !void {
        const presence = try presenceFromJson(data);
        if (presence.status.len == "offline".len and std.mem.eql(u8, presence.status, "offline")) {
            self.removePresence(presence.guild_id.?, presence.user_id);
            return;
        }
        try self.putPresence(presence);
    }

    fn putPresencesFromJson(self: *Cache, value: std.json.Value) !void {
        const presences = try requireArray(value);
        for (presences.items) |item| try self.putPresenceFromJson(item);
    }

    fn putVoiceStateFromJson(self: *Cache, data: std.json.Value) !void {
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

    fn putVoiceStatesFromJson(self: *Cache, value: std.json.Value) !void {
        const voice_states = try requireArray(value);
        for (voice_states.items) |item| try self.putVoiceStateFromJson(item);
    }

    fn putMessageFromJson(self: *Cache, data: std.json.Value) !void {
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

    fn updateMessageFromJson(self: *Cache, data: std.json.Value) !void {
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

    fn addReactionFromJson(self: *Cache, data: std.json.Value) !void {
        const event = try reactionEventFromJson(data);
        var message = self.messages.get(event.message_id.value) orelse return;
        try incrementReaction(self.allocator, &message, event.emoji);
        try self.messages.put(event.message_id.value, message);
    }

    fn removeReactionFromJson(self: *Cache, data: std.json.Value) !void {
        const event = try reactionEventFromJson(data);
        var message = self.messages.get(event.message_id.value) orelse return;
        try decrementReaction(self.allocator, &message, event.emoji);
        try self.messages.put(event.message_id.value, message);
    }

    fn removeAllReactionsFromJson(self: *Cache, data: std.json.Value) !void {
        const object = try requireObject(data);
        const message_id = try snowflakeField(object, "message_id");
        var message = self.messages.get(message_id.value) orelse return;
        deinitReactions(message.reactions, self.allocator);
        message.reactions = try self.allocator.dupe(Types.MessageReaction, &.{});
        try self.messages.put(message_id.value, message);
    }

    fn removeReactionEmojiFromJson(self: *Cache, data: std.json.Value) !void {
        const object = try requireObject(data);
        const message_id = try snowflakeField(object, "message_id");
        const emoji = try reactionEmojiFromJson(object.get("emoji") orelse return error.MissingField);
        var message = self.messages.get(message_id.value) orelse return;
        try removeReactionEmoji(self.allocator, &message, emoji);
        try self.messages.put(message_id.value, message);
    }

    fn deleteMessageFromJson(self: *Cache, data: std.json.Value) !void {
        const object = try requireObject(data);
        self.removeMessage(try snowflakeField(object, "id"));
    }

    fn deleteMessagesFromJson(self: *Cache, data: std.json.Value) !void {
        const object = try requireObject(data);
        const ids = try requireArray(object.get("ids") orelse return error.MissingField);
        for (ids.items) |id| self.removeMessage(try snowflakeValue(id));
    }

    fn putChannelsFromJson(self: *Cache, guild_id: Snowflake, value: std.json.Value) !void {
        const channels = try requireArray(value);
        for (channels.items) |item| {
            const channel = try channelFromJson(self.allocator, item, guild_id);
            defer deinitParsedChannel(channel, self.allocator);
            try self.putChannel(channel);
        }
    }

    fn putChannelFromJson(self: *Cache, data: std.json.Value) !void {
        const channel = try channelFromJson(self.allocator, data, null);
        defer deinitParsedChannel(channel, self.allocator);
        try self.putChannel(channel);
    }

    fn deleteChannelFromJson(self: *Cache, data: std.json.Value) !void {
        const object = try requireObject(data);
        self.removeChannel(try snowflakeField(object, "id"));
    }

    fn updateChannelInfoFromJson(self: *Cache, data: std.json.Value) !void {
        const object = try requireObject(data);
        const channels = try requireArray(object.get("channels") orelse return);
        for (channels.items) |item| {
            const channel_info = try requireObject(item);
            const channel_id = if (channel_info.get("id")) |id| try snowflakeValue(id) else continue;
            const channel = self.channels.getPtr(channel_id.value) orelse continue;
            try self.applyChannelInfoFields(channel, channel_info);
        }
    }

    fn updateVoiceChannelStatusFromJson(self: *Cache, data: std.json.Value) !void {
        const object = try requireObject(data);
        const channel_id = if (object.get("id")) |id| try snowflakeValue(id) else return;
        const channel = self.channels.getPtr(channel_id.value) orelse return;
        try self.applyChannelStatusField(channel, object.get("status") orelse return);
    }

    fn updateVoiceChannelStartTimeFromJson(self: *Cache, data: std.json.Value) !void {
        const object = try requireObject(data);
        const channel_id = if (object.get("id")) |id| try snowflakeValue(id) else return;
        const channel = self.channels.getPtr(channel_id.value) orelse return;
        channel.voice_start_time = try nullableIntValue(object.get("voice_start_time") orelse return);
    }

    fn updateChannelPinsFromJson(self: *Cache, data: std.json.Value) !void {
        const object = try requireObject(data);
        const channel_id = try snowflakeField(object, "channel_id");
        const channel = self.channels.getPtr(channel_id.value) orelse return;
        const last_pin_timestamp = if (object.get("last_pin_timestamp")) |field| try optionalStringValue(field) else null;
        const owned_last_pin_timestamp = if (last_pin_timestamp) |value| try self.allocator.dupe(u8, value) else null;

        if (channel.last_pin_timestamp) |value| self.allocator.free(value);
        channel.last_pin_timestamp = owned_last_pin_timestamp;
    }

    fn applyChannelInfoFields(self: *Cache, channel: *OwnedChannel, object: std.json.ObjectMap) !void {
        if (object.get("status")) |field| try self.applyChannelStatusField(channel, field);
        if (object.get("voice_start_time")) |field| channel.voice_start_time = try nullableIntValue(field);
    }

    fn applyChannelStatusField(self: *Cache, channel: *OwnedChannel, field: std.json.Value) !void {
        const status = try optionalStringValue(field);
        const owned_status = if (status) |value| try self.allocator.dupe(u8, value) else null;

        if (channel.status) |value| self.allocator.free(value);
        channel.status = owned_status;
    }

    fn syncThreadsFromJson(self: *Cache, data: std.json.Value) !void {
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

    fn updateThreadMemberCountFromJson(self: *Cache, data: std.json.Value) !void {
        const object = try requireObject(data);
        const thread_id = try snowflakeField(object, "id");
        const member_count: u32 = @intCast(try intField(object, "member_count"));
        const channel = self.channels.getPtr(thread_id.value) orelse return;
        if (!channelTypeIsThread(channel.type)) return;
        channel.member_count = member_count;
    }

    fn putMembersFromJson(self: *Cache, guild_id: Snowflake, value: std.json.Value) !void {
        const members = try requireArray(value);
        for (members.items) |item| {
            try self.putMemberFromJson(item, guild_id);
        }
    }

    fn putRolesFromJson(self: *Cache, guild_id: Snowflake, value: std.json.Value) !void {
        const roles = try requireArray(value);
        for (roles.items) |item| {
            try self.putRole(guild_id, try roleFromJson(item));
        }
    }

    fn putRoleEventFromJson(self: *Cache, data: std.json.Value) !void {
        const object = try requireObject(data);
        const guild_id = try snowflakeField(object, "guild_id");
        try self.putRole(guild_id, try roleFromJson(object.get("role") orelse return error.MissingField));
    }

    fn deleteRoleEventFromJson(self: *Cache, data: std.json.Value) !void {
        const object = try requireObject(data);
        self.removeRole(try snowflakeField(object, "guild_id"), try snowflakeField(object, "role_id"));
    }

    fn putGuildEmojisFromJson(self: *Cache, data: std.json.Value) !void {
        const object = try requireObject(data);
        const guild_id = try snowflakeField(object, "guild_id");
        self.removeGuildEmojis(guild_id);
        try self.putEmojisFromJson(guild_id, object.get("emojis") orelse return error.MissingField);
    }

    fn putEmojisFromJson(self: *Cache, guild_id: Snowflake, value: std.json.Value) !void {
        const emojis = try requireArray(value);
        for (emojis.items) |item| {
            const emoji = try emojiFromJson(self.allocator, item);
            defer self.allocator.free(emoji.roles);
            try self.putEmoji(guild_id, emoji);
        }
    }

    fn putStickersFromJson(self: *Cache, guild_id: Snowflake, value: std.json.Value) !void {
        const stickers = try requireArray(value);
        for (stickers.items) |item| try self.putSticker(guild_id, try stickerFromJson(item, guild_id));
    }

    fn putGuildStickersFromJson(self: *Cache, data: std.json.Value) !void {
        const object = try requireObject(data);
        const guild_id = try snowflakeField(object, "guild_id");
        self.removeGuildStickers(guild_id);
        try self.putStickersFromJson(guild_id, object.get("stickers") orelse return error.MissingField);
    }

    fn putScheduledEventsFromJson(self: *Cache, value: std.json.Value) !void {
        const events = try requireArray(value);
        for (events.items) |item| try self.putScheduledEvent(try scheduledEventFromJson(item));
    }

    fn putScheduledEventFromJson(self: *Cache, data: std.json.Value) !void {
        try self.putScheduledEvent(try scheduledEventFromJson(data));
    }

    fn deleteScheduledEventFromJson(self: *Cache, data: std.json.Value) !void {
        const event = try scheduledEventFromJson(data);
        self.removeScheduledEvent(event.guild_id, event.id);
    }

    fn incrementScheduledEventUserCountFromJson(self: *Cache, data: std.json.Value) !void {
        const object = try requireObject(data);
        const guild_id = try snowflakeField(object, "guild_id");
        const event_id = try snowflakeField(object, "guild_scheduled_event_id");
        const event = self.scheduled_events.getPtr(roleKey(guild_id, event_id)) orelse return;
        if (event.user_count) |count| event.user_count = count +| 1;
    }

    fn decrementScheduledEventUserCountFromJson(self: *Cache, data: std.json.Value) !void {
        const object = try requireObject(data);
        const guild_id = try snowflakeField(object, "guild_id");
        const event_id = try snowflakeField(object, "guild_scheduled_event_id");
        const event = self.scheduled_events.getPtr(roleKey(guild_id, event_id)) orelse return;
        if (event.user_count) |count| event.user_count = if (count == 0) 0 else count - 1;
    }

    fn putStageInstanceFromJson(self: *Cache, data: std.json.Value) !void {
        try self.putStageInstance(try stageInstanceFromJson(data));
    }

    fn putStageInstancesFromJson(self: *Cache, value: std.json.Value) !void {
        const stage_instances = try requireArray(value);
        for (stage_instances.items) |item| try self.putStageInstance(try stageInstanceFromJson(item));
    }

    fn deleteStageInstanceFromJson(self: *Cache, data: std.json.Value) !void {
        const stage_instance = try stageInstanceFromJson(data);
        self.removeStageInstance(stage_instance.guild_id, stage_instance.id);
    }

    fn putInviteFromJson(self: *Cache, data: std.json.Value) !void {
        try self.putInvite(try inviteFromJson(data));
    }

    fn deleteInviteFromJson(self: *Cache, data: std.json.Value) !void {
        const object = try requireObject(data);
        self.removeInvite(try stringField(object, "code"));
    }

    fn putMemberFromJson(self: *Cache, data: std.json.Value, fallback_guild_id: ?Snowflake) !void {
        const object = try requireObject(data);
        const guild_id = if (object.get("guild_id")) |value| try snowflakeValue(value) else fallback_guild_id orelse return error.MissingField;
        const member = try memberFromJson(self.allocator, data);
        defer self.allocator.free(member.roles);
        try self.putMember(guild_id, member);
    }

    fn addMemberFromJson(self: *Cache, data: std.json.Value) !void {
        const object = try requireObject(data);
        const guild_id = try snowflakeField(object, "guild_id");
        try self.putMemberFromJson(data, guild_id);
        self.incrementGuildMemberCount(guild_id);
    }

    fn deleteMemberFromJson(self: *Cache, data: std.json.Value) !void {
        const object = try requireObject(data);
        const guild_id = try snowflakeField(object, "guild_id");
        const user = try userFromJson(object.get("user") orelse return error.MissingField);
        try self.putUser(user);
        self.removeMember(guild_id, user.id);
        self.decrementGuildMemberCount(guild_id);
    }

    fn incrementGuildMemberCount(self: *Cache, guild_id: Snowflake) void {
        const guild = self.guilds.getPtr(guild_id.value) orelse return;
        if (guild.approximate_member_count) |count| guild.approximate_member_count = count +| 1;
    }

    fn decrementGuildMemberCount(self: *Cache, guild_id: Snowflake) void {
        const guild = self.guilds.getPtr(guild_id.value) orelse return;
        if (guild.approximate_member_count) |count| guild.approximate_member_count = if (count == 0) 0 else count - 1;
    }
};

const OwnedUser = struct {
    id: Snowflake,
    username: []u8,
    discriminator: ?[]u8,
    global_name: ?[]u8,
    avatar: ?[]u8,
    banner: ?[]u8,
    bot: bool,
    system: bool,
    mfa_enabled: ?bool,
    accent_color: ?u32,
    locale: ?[]u8,
    verified: ?bool,
    email: ?[]u8,
    flags: ?u32,
    public_flags: ?u32,

    fn copy(allocator: std.mem.Allocator, user: Types.User) !OwnedUser {
        const username = try allocator.dupe(u8, user.username);
        errdefer allocator.free(username);
        const discriminator = if (user.discriminator) |value| try allocator.dupe(u8, value) else null;
        errdefer if (discriminator) |value| allocator.free(value);
        const global_name = if (user.global_name) |value| try allocator.dupe(u8, value) else null;
        errdefer if (global_name) |value| allocator.free(value);
        const avatar = if (user.avatar) |value| try allocator.dupe(u8, value) else null;
        errdefer if (avatar) |value| allocator.free(value);
        const banner = if (user.banner) |value| try allocator.dupe(u8, value) else null;
        errdefer if (banner) |value| allocator.free(value);
        const locale = if (user.locale) |value| try allocator.dupe(u8, value) else null;
        errdefer if (locale) |value| allocator.free(value);
        const email = if (user.email) |value| try allocator.dupe(u8, value) else null;
        return .{
            .id = user.id,
            .username = username,
            .discriminator = discriminator,
            .global_name = global_name,
            .avatar = avatar,
            .banner = banner,
            .bot = user.bot,
            .system = user.system,
            .mfa_enabled = user.mfa_enabled,
            .accent_color = user.accent_color,
            .locale = locale,
            .verified = user.verified,
            .email = email,
            .flags = user.flags,
            .public_flags = user.public_flags,
        };
    }

    fn deinit(self: OwnedUser, allocator: std.mem.Allocator) void {
        allocator.free(self.username);
        if (self.discriminator) |value| allocator.free(value);
        if (self.global_name) |value| allocator.free(value);
        if (self.avatar) |value| allocator.free(value);
        if (self.banner) |value| allocator.free(value);
        if (self.locale) |value| allocator.free(value);
        if (self.email) |value| allocator.free(value);
    }

    fn view(self: OwnedUser) Types.User {
        return .{
            .id = self.id,
            .username = self.username,
            .discriminator = self.discriminator,
            .global_name = self.global_name,
            .avatar = self.avatar,
            .banner = self.banner,
            .bot = self.bot,
            .system = self.system,
            .mfa_enabled = self.mfa_enabled,
            .accent_color = self.accent_color,
            .locale = self.locale,
            .verified = self.verified,
            .email = self.email,
            .flags = self.flags,
            .public_flags = self.public_flags,
        };
    }
};

const OwnedGuild = struct {
    id: Snowflake,
    name: []u8,
    icon: ?[]u8,
    banner: ?[]u8,
    owner_id: ?Snowflake,
    description: ?[]u8,
    afk_channel_id: ?Snowflake,
    afk_timeout: ?u32,
    system_channel_id: ?Snowflake,
    rules_channel_id: ?Snowflake,
    public_updates_channel_id: ?Snowflake,
    safety_alerts_channel_id: ?Snowflake,
    features: [][]u8,
    preferred_locale: ?[]u8,
    verification_level: ?u8,
    default_message_notifications: ?u8,
    explicit_content_filter: ?u8,
    mfa_level: ?u8,
    nsfw_level: ?u8,
    max_presences: ?u32,
    max_members: ?u32,
    premium_tier: ?u8,
    premium_subscription_count: ?u32,
    premium_progress_bar_enabled: ?bool,
    approximate_member_count: ?u32,
    approximate_presence_count: ?u32,

    fn copy(allocator: std.mem.Allocator, guild: Types.Guild) !OwnedGuild {
        const name = try allocator.dupe(u8, guild.name);
        errdefer allocator.free(name);
        const icon = if (guild.icon) |value| try allocator.dupe(u8, value) else null;
        errdefer if (icon) |value| allocator.free(value);
        const banner = if (guild.banner) |value| try allocator.dupe(u8, value) else null;
        errdefer if (banner) |value| allocator.free(value);
        const description = if (guild.description) |value| try allocator.dupe(u8, value) else null;
        errdefer if (description) |value| allocator.free(value);
        const features = try copyStringArray(allocator, guild.features);
        errdefer deinitStringArray(features, allocator);
        const preferred_locale = if (guild.preferred_locale) |value| try allocator.dupe(u8, value) else null;
        return .{
            .id = guild.id,
            .name = name,
            .icon = icon,
            .banner = banner,
            .owner_id = guild.owner_id,
            .description = description,
            .afk_channel_id = guild.afk_channel_id,
            .afk_timeout = guild.afk_timeout,
            .system_channel_id = guild.system_channel_id,
            .rules_channel_id = guild.rules_channel_id,
            .public_updates_channel_id = guild.public_updates_channel_id,
            .safety_alerts_channel_id = guild.safety_alerts_channel_id,
            .features = features,
            .preferred_locale = preferred_locale,
            .verification_level = guild.verification_level,
            .default_message_notifications = guild.default_message_notifications,
            .explicit_content_filter = guild.explicit_content_filter,
            .mfa_level = guild.mfa_level,
            .nsfw_level = guild.nsfw_level,
            .max_presences = guild.max_presences,
            .max_members = guild.max_members,
            .premium_tier = guild.premium_tier,
            .premium_subscription_count = guild.premium_subscription_count,
            .premium_progress_bar_enabled = guild.premium_progress_bar_enabled,
            .approximate_member_count = guild.approximate_member_count,
            .approximate_presence_count = guild.approximate_presence_count,
        };
    }

    fn deinit(self: OwnedGuild, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        if (self.icon) |value| allocator.free(value);
        if (self.banner) |value| allocator.free(value);
        if (self.description) |value| allocator.free(value);
        deinitStringArray(self.features, allocator);
        if (self.preferred_locale) |value| allocator.free(value);
    }

    fn view(self: OwnedGuild) Types.Guild {
        return .{
            .id = self.id,
            .name = self.name,
            .icon = self.icon,
            .banner = self.banner,
            .owner_id = self.owner_id,
            .description = self.description,
            .afk_channel_id = self.afk_channel_id,
            .afk_timeout = self.afk_timeout,
            .system_channel_id = self.system_channel_id,
            .rules_channel_id = self.rules_channel_id,
            .public_updates_channel_id = self.public_updates_channel_id,
            .safety_alerts_channel_id = self.safety_alerts_channel_id,
            .features = self.features,
            .preferred_locale = self.preferred_locale,
            .verification_level = self.verification_level,
            .default_message_notifications = self.default_message_notifications,
            .explicit_content_filter = self.explicit_content_filter,
            .mfa_level = self.mfa_level,
            .nsfw_level = self.nsfw_level,
            .max_presences = self.max_presences,
            .max_members = self.max_members,
            .premium_tier = self.premium_tier,
            .premium_subscription_count = self.premium_subscription_count,
            .premium_progress_bar_enabled = self.premium_progress_bar_enabled,
            .approximate_member_count = self.approximate_member_count,
            .approximate_presence_count = self.approximate_presence_count,
        };
    }
};

const OwnedChannel = struct {
    id: Snowflake,
    type: Types.ChannelType,
    guild_id: ?Snowflake,
    name: ?[]u8,
    topic: ?[]u8,
    status: ?[]u8,
    voice_start_time: ?i64,
    last_message_id: ?Snowflake,
    last_pin_timestamp: ?[]u8,
    parent_id: ?Snowflake,
    owner_id: ?Snowflake,
    application_id: ?Snowflake,
    position: ?i32,
    nsfw: bool,
    rate_limit_per_user: ?u16,
    bitrate: ?u32,
    user_limit: ?u16,
    rtc_region: ?[]u8,
    video_quality_mode: ?u8,
    message_count: ?u32,
    member_count: ?u32,
    managed: bool,
    flags: ?Types.ChannelFlags.Bit,
    permission_overwrites: []Types.PermissionOverwrite,
    thread_metadata: ?Types.ThreadMetadata,
    applied_tags: []Snowflake,
    available_tags: []Types.ForumTag,
    default_reaction_emoji: ?Types.DefaultReactionEmoji,
    default_thread_rate_limit_per_user: ?u16,
    default_sort_order: ?Types.ChannelSortOrder,
    default_forum_layout: ?Types.ForumLayout,

    fn copy(allocator: std.mem.Allocator, channel: Types.Channel) !OwnedChannel {
        const name = if (channel.name) |value| try allocator.dupe(u8, value) else null;
        errdefer if (name) |value| allocator.free(value);
        const topic = if (channel.topic) |value| try allocator.dupe(u8, value) else null;
        errdefer if (topic) |value| allocator.free(value);
        const status = if (channel.status) |value| try allocator.dupe(u8, value) else null;
        errdefer if (status) |value| allocator.free(value);
        const last_pin_timestamp = if (channel.last_pin_timestamp) |value| try allocator.dupe(u8, value) else null;
        errdefer if (last_pin_timestamp) |value| allocator.free(value);
        const rtc_region = if (channel.rtc_region) |value| try allocator.dupe(u8, value) else null;
        errdefer if (rtc_region) |value| allocator.free(value);
        const permission_overwrites = try allocator.dupe(Types.PermissionOverwrite, channel.permission_overwrites);
        errdefer allocator.free(permission_overwrites);
        const thread_metadata = if (channel.thread_metadata) |value| try copyThreadMetadata(allocator, value) else null;
        errdefer if (thread_metadata) |value| deinitThreadMetadata(value, allocator);
        const applied_tags = try allocator.dupe(Snowflake, channel.applied_tags);
        errdefer allocator.free(applied_tags);
        const available_tags = try copyForumTags(allocator, channel.available_tags);
        errdefer deinitForumTags(available_tags, allocator);
        const default_reaction_emoji = if (channel.default_reaction_emoji) |value| try copyDefaultReactionEmoji(allocator, value) else null;
        return .{
            .id = channel.id,
            .type = channel.type,
            .guild_id = channel.guild_id,
            .name = name,
            .topic = topic,
            .status = status,
            .voice_start_time = channel.voice_start_time,
            .last_message_id = channel.last_message_id,
            .last_pin_timestamp = last_pin_timestamp,
            .parent_id = channel.parent_id,
            .owner_id = channel.owner_id,
            .application_id = channel.application_id,
            .position = channel.position,
            .nsfw = channel.nsfw,
            .rate_limit_per_user = channel.rate_limit_per_user,
            .bitrate = channel.bitrate,
            .user_limit = channel.user_limit,
            .rtc_region = rtc_region,
            .video_quality_mode = channel.video_quality_mode,
            .message_count = channel.message_count,
            .member_count = channel.member_count,
            .managed = channel.managed,
            .flags = channel.flags,
            .permission_overwrites = permission_overwrites,
            .thread_metadata = thread_metadata,
            .applied_tags = applied_tags,
            .available_tags = available_tags,
            .default_reaction_emoji = default_reaction_emoji,
            .default_thread_rate_limit_per_user = channel.default_thread_rate_limit_per_user,
            .default_sort_order = channel.default_sort_order,
            .default_forum_layout = channel.default_forum_layout,
        };
    }

    fn deinit(self: OwnedChannel, allocator: std.mem.Allocator) void {
        if (self.name) |value| allocator.free(value);
        if (self.topic) |value| allocator.free(value);
        if (self.status) |value| allocator.free(value);
        if (self.last_pin_timestamp) |value| allocator.free(value);
        if (self.rtc_region) |value| allocator.free(value);
        allocator.free(self.permission_overwrites);
        if (self.thread_metadata) |value| deinitThreadMetadata(value, allocator);
        allocator.free(self.applied_tags);
        deinitForumTags(self.available_tags, allocator);
        if (self.default_reaction_emoji) |value| deinitDefaultReactionEmoji(value, allocator);
    }

    fn view(self: OwnedChannel) Types.Channel {
        return .{
            .id = self.id,
            .type = self.type,
            .guild_id = self.guild_id,
            .name = self.name,
            .topic = self.topic,
            .status = self.status,
            .voice_start_time = self.voice_start_time,
            .last_message_id = self.last_message_id,
            .last_pin_timestamp = self.last_pin_timestamp,
            .parent_id = self.parent_id,
            .owner_id = self.owner_id,
            .application_id = self.application_id,
            .position = self.position,
            .nsfw = self.nsfw,
            .rate_limit_per_user = self.rate_limit_per_user,
            .bitrate = self.bitrate,
            .user_limit = self.user_limit,
            .rtc_region = self.rtc_region,
            .video_quality_mode = self.video_quality_mode,
            .message_count = self.message_count,
            .member_count = self.member_count,
            .managed = self.managed,
            .flags = self.flags,
            .permission_overwrites = self.permission_overwrites,
            .thread_metadata = self.thread_metadata,
            .applied_tags = self.applied_tags,
            .available_tags = self.available_tags,
            .default_reaction_emoji = self.default_reaction_emoji,
            .default_thread_rate_limit_per_user = self.default_thread_rate_limit_per_user,
            .default_sort_order = self.default_sort_order,
            .default_forum_layout = self.default_forum_layout,
        };
    }
};

const OwnedGuildMember = struct {
    guild_id: Snowflake,
    user_id: Snowflake,
    nick: ?[]u8,
    avatar: ?[]u8,
    roles: []Snowflake,
    joined_at: ?[]u8,
    premium_since: ?[]u8,
    deaf: bool,
    mute: bool,
    pending: bool,
    communication_disabled_until: ?[]u8,
    flags: u64,
    permissions: Permissions.Bit,

    fn copy(allocator: std.mem.Allocator, guild_id: Snowflake, member: Types.GuildMember) !OwnedGuildMember {
        const user = member.user orelse return error.MissingField;
        const nick = if (member.nick) |value| try allocator.dupe(u8, value) else null;
        errdefer if (nick) |value| allocator.free(value);
        const avatar = if (member.avatar) |value| try allocator.dupe(u8, value) else null;
        errdefer if (avatar) |value| allocator.free(value);
        const roles = try allocator.dupe(Snowflake, member.roles);
        errdefer allocator.free(roles);
        const joined_at = if (member.joined_at) |value| try allocator.dupe(u8, value) else null;
        errdefer if (joined_at) |value| allocator.free(value);
        const premium_since = if (member.premium_since) |value| try allocator.dupe(u8, value) else null;
        errdefer if (premium_since) |value| allocator.free(value);
        const communication_disabled_until = if (member.communication_disabled_until) |value| try allocator.dupe(u8, value) else null;
        return .{
            .guild_id = guild_id,
            .user_id = user.id,
            .nick = nick,
            .avatar = avatar,
            .roles = roles,
            .joined_at = joined_at,
            .premium_since = premium_since,
            .deaf = member.deaf,
            .mute = member.mute,
            .pending = member.pending,
            .communication_disabled_until = communication_disabled_until,
            .flags = member.flags,
            .permissions = member.permissions,
        };
    }

    fn deinit(self: OwnedGuildMember, allocator: std.mem.Allocator) void {
        if (self.nick) |value| allocator.free(value);
        if (self.avatar) |value| allocator.free(value);
        allocator.free(self.roles);
        if (self.joined_at) |value| allocator.free(value);
        if (self.premium_since) |value| allocator.free(value);
        if (self.communication_disabled_until) |value| allocator.free(value);
    }

    fn view(self: OwnedGuildMember, user: ?Types.User) Types.GuildMember {
        return .{
            .user = user,
            .nick = self.nick,
            .avatar = self.avatar,
            .roles = self.roles,
            .joined_at = self.joined_at,
            .premium_since = self.premium_since,
            .deaf = self.deaf,
            .mute = self.mute,
            .pending = self.pending,
            .communication_disabled_until = self.communication_disabled_until,
            .flags = self.flags,
            .permissions = self.permissions,
        };
    }
};

const OwnedRole = struct {
    id: Snowflake,
    guild_id: Snowflake,
    name: []u8,
    color: u24,
    colors: ?Types.RoleColors,
    hoist: bool,
    icon: ?[]u8,
    unicode_emoji: ?[]u8,
    position: i32,
    permissions: u64,
    managed: bool,
    mentionable: bool,
    tags: ?Types.RoleTags,
    flags: ?u64,

    fn copy(allocator: std.mem.Allocator, guild_id: Snowflake, role: Types.Role) !OwnedRole {
        const name = try allocator.dupe(u8, role.name);
        errdefer allocator.free(name);
        const icon = if (role.icon) |value| try allocator.dupe(u8, value) else null;
        errdefer if (icon) |value| allocator.free(value);
        const unicode_emoji = if (role.unicode_emoji) |value| try allocator.dupe(u8, value) else null;
        return .{
            .id = role.id,
            .guild_id = guild_id,
            .name = name,
            .color = role.color,
            .colors = role.colors,
            .hoist = role.hoist,
            .icon = icon,
            .unicode_emoji = unicode_emoji,
            .position = role.position,
            .permissions = role.permissions,
            .managed = role.managed,
            .mentionable = role.mentionable,
            .tags = role.tags,
            .flags = role.flags,
        };
    }

    fn deinit(self: OwnedRole, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        if (self.icon) |value| allocator.free(value);
        if (self.unicode_emoji) |value| allocator.free(value);
    }

    fn view(self: OwnedRole) Types.Role {
        return .{
            .id = self.id,
            .name = self.name,
            .color = self.color,
            .colors = self.colors,
            .hoist = self.hoist,
            .icon = self.icon,
            .unicode_emoji = self.unicode_emoji,
            .position = self.position,
            .permissions = self.permissions,
            .managed = self.managed,
            .mentionable = self.mentionable,
            .tags = self.tags,
            .flags = self.flags,
        };
    }
};

const OwnedEmoji = struct {
    id: Snowflake,
    guild_id: Snowflake,
    name: ?[]u8,
    roles: []Snowflake,
    user_id: ?Snowflake,
    require_colons: bool,
    managed: bool,
    animated: bool,
    available: bool,

    fn copy(allocator: std.mem.Allocator, guild_id: Snowflake, emoji: Types.Emoji) !OwnedEmoji {
        const id = emoji.id orelse return error.MissingField;
        const name = if (emoji.name) |value| try allocator.dupe(u8, value) else null;
        errdefer if (name) |value| allocator.free(value);
        const roles = try allocator.dupe(Snowflake, emoji.roles);
        errdefer allocator.free(roles);
        return .{
            .id = id,
            .guild_id = guild_id,
            .name = name,
            .roles = roles,
            .user_id = if (emoji.user) |user| user.id else null,
            .require_colons = emoji.require_colons,
            .managed = emoji.managed,
            .animated = emoji.animated,
            .available = emoji.available,
        };
    }

    fn deinit(self: OwnedEmoji, allocator: std.mem.Allocator) void {
        if (self.name) |value| allocator.free(value);
        allocator.free(self.roles);
    }

    fn view(self: OwnedEmoji, user: ?Types.User) Types.Emoji {
        return .{
            .id = self.id,
            .name = self.name,
            .roles = self.roles,
            .user = user,
            .require_colons = self.require_colons,
            .managed = self.managed,
            .animated = self.animated,
            .available = self.available,
        };
    }
};

const OwnedSticker = struct {
    id: Snowflake,
    pack_id: ?Snowflake,
    name: []u8,
    description: ?[]u8,
    tags: []u8,
    type: Types.StickerType,
    format_type: Types.StickerFormatType,
    available: bool,
    guild_id: Snowflake,
    user_id: ?Snowflake,
    sort_value: ?u32,

    fn copy(allocator: std.mem.Allocator, guild_id: Snowflake, sticker: Types.Sticker) !OwnedSticker {
        const name = try allocator.dupe(u8, sticker.name);
        errdefer allocator.free(name);
        const description = if (sticker.description) |value| try allocator.dupe(u8, value) else null;
        errdefer if (description) |value| allocator.free(value);
        const tags = try allocator.dupe(u8, sticker.tags);
        errdefer allocator.free(tags);
        return .{
            .id = sticker.id,
            .pack_id = sticker.pack_id,
            .name = name,
            .description = description,
            .tags = tags,
            .type = sticker.type,
            .format_type = sticker.format_type,
            .available = sticker.available,
            .guild_id = sticker.guild_id orelse guild_id,
            .user_id = if (sticker.user) |user| user.id else null,
            .sort_value = sticker.sort_value,
        };
    }

    fn deinit(self: OwnedSticker, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        if (self.description) |value| allocator.free(value);
        allocator.free(self.tags);
    }

    fn view(self: OwnedSticker, user: ?Types.User) Types.Sticker {
        return .{
            .id = self.id,
            .pack_id = self.pack_id,
            .name = self.name,
            .description = self.description,
            .tags = self.tags,
            .type = self.type,
            .format_type = self.format_type,
            .available = self.available,
            .guild_id = self.guild_id,
            .user = user,
            .sort_value = self.sort_value,
        };
    }
};

const OwnedScheduledEvent = struct {
    id: Snowflake,
    guild_id: Snowflake,
    channel_id: ?Snowflake,
    creator_id: ?Snowflake,
    name: []u8,
    description: ?[]u8,
    scheduled_start_time: []u8,
    scheduled_end_time: ?[]u8,
    privacy_level: Types.GuildScheduledEventPrivacyLevel,
    status: Types.GuildScheduledEventStatus,
    entity_type: Types.GuildScheduledEventEntityType,
    entity_id: ?Snowflake,
    user_count: ?u32,

    fn copy(allocator: std.mem.Allocator, event: Types.GuildScheduledEvent) !OwnedScheduledEvent {
        const name = try allocator.dupe(u8, event.name);
        errdefer allocator.free(name);
        const description = if (event.description) |value| try allocator.dupe(u8, value) else null;
        errdefer if (description) |value| allocator.free(value);
        const scheduled_start_time = try allocator.dupe(u8, event.scheduled_start_time);
        errdefer allocator.free(scheduled_start_time);
        const scheduled_end_time = if (event.scheduled_end_time) |value| try allocator.dupe(u8, value) else null;
        return .{
            .id = event.id,
            .guild_id = event.guild_id,
            .channel_id = event.channel_id,
            .creator_id = event.creator_id,
            .name = name,
            .description = description,
            .scheduled_start_time = scheduled_start_time,
            .scheduled_end_time = scheduled_end_time,
            .privacy_level = event.privacy_level,
            .status = event.status,
            .entity_type = event.entity_type,
            .entity_id = event.entity_id,
            .user_count = event.user_count,
        };
    }

    fn deinit(self: OwnedScheduledEvent, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        if (self.description) |value| allocator.free(value);
        allocator.free(self.scheduled_start_time);
        if (self.scheduled_end_time) |value| allocator.free(value);
    }

    fn view(self: OwnedScheduledEvent) Types.GuildScheduledEvent {
        return .{
            .id = self.id,
            .guild_id = self.guild_id,
            .channel_id = self.channel_id,
            .creator_id = self.creator_id,
            .name = self.name,
            .description = self.description,
            .scheduled_start_time = self.scheduled_start_time,
            .scheduled_end_time = self.scheduled_end_time,
            .privacy_level = self.privacy_level,
            .status = self.status,
            .entity_type = self.entity_type,
            .entity_id = self.entity_id,
            .user_count = self.user_count,
        };
    }
};

const OwnedStageInstance = struct {
    id: Snowflake,
    guild_id: Snowflake,
    channel_id: Snowflake,
    topic: []u8,
    privacy_level: Types.StageInstancePrivacyLevel,
    discoverable_disabled: bool,
    guild_scheduled_event_id: ?Snowflake,

    fn copy(allocator: std.mem.Allocator, stage_instance: Types.StageInstance) !OwnedStageInstance {
        return .{
            .id = stage_instance.id,
            .guild_id = stage_instance.guild_id,
            .channel_id = stage_instance.channel_id,
            .topic = try allocator.dupe(u8, stage_instance.topic),
            .privacy_level = stage_instance.privacy_level,
            .discoverable_disabled = stage_instance.discoverable_disabled,
            .guild_scheduled_event_id = stage_instance.guild_scheduled_event_id,
        };
    }

    fn deinit(self: OwnedStageInstance, allocator: std.mem.Allocator) void {
        allocator.free(self.topic);
    }

    fn view(self: OwnedStageInstance) Types.StageInstance {
        return .{
            .id = self.id,
            .guild_id = self.guild_id,
            .channel_id = self.channel_id,
            .topic = self.topic,
            .privacy_level = self.privacy_level,
            .discoverable_disabled = self.discoverable_disabled,
            .guild_scheduled_event_id = self.guild_scheduled_event_id,
        };
    }
};

const OwnedInvite = struct {
    code: []u8,
    type: ?u8,
    guild_id: ?Snowflake,
    channel_id: ?Snowflake,
    inviter_id: ?Snowflake,
    target_type: ?u8,
    target_user_id: ?Snowflake,
    target_application_id: ?Snowflake,
    approximate_presence_count: ?u32,
    approximate_member_count: ?u32,
    expires_at: ?[]u8,
    uses: ?u32,
    max_uses: ?u32,
    max_age: ?u32,
    temporary: ?bool,
    created_at: ?[]u8,
    guild_scheduled_event_id: ?Snowflake,

    fn copy(allocator: std.mem.Allocator, invite: Types.Invite) !OwnedInvite {
        const code = try allocator.dupe(u8, invite.code);
        errdefer allocator.free(code);
        const expires_at = if (invite.expires_at) |value| try allocator.dupe(u8, value) else null;
        errdefer if (expires_at) |value| allocator.free(value);
        const created_at = if (invite.created_at) |value| try allocator.dupe(u8, value) else null;
        return .{
            .code = code,
            .type = invite.type,
            .guild_id = invite.guild_id,
            .channel_id = invite.channel_id,
            .inviter_id = invite.inviter_id,
            .target_type = invite.target_type,
            .target_user_id = invite.target_user_id,
            .target_application_id = invite.target_application_id,
            .approximate_presence_count = invite.approximate_presence_count,
            .approximate_member_count = invite.approximate_member_count,
            .expires_at = expires_at,
            .uses = invite.uses,
            .max_uses = invite.max_uses,
            .max_age = invite.max_age,
            .temporary = invite.temporary,
            .created_at = created_at,
            .guild_scheduled_event_id = invite.guild_scheduled_event_id,
        };
    }

    fn deinit(self: OwnedInvite, allocator: std.mem.Allocator) void {
        allocator.free(self.code);
        if (self.expires_at) |value| allocator.free(value);
        if (self.created_at) |value| allocator.free(value);
    }

    fn view(self: OwnedInvite) Types.Invite {
        return .{
            .code = self.code,
            .type = self.type,
            .guild_id = self.guild_id,
            .channel_id = self.channel_id,
            .inviter_id = self.inviter_id,
            .target_type = self.target_type,
            .target_user_id = self.target_user_id,
            .target_application_id = self.target_application_id,
            .approximate_presence_count = self.approximate_presence_count,
            .approximate_member_count = self.approximate_member_count,
            .expires_at = self.expires_at,
            .uses = self.uses,
            .max_uses = self.max_uses,
            .max_age = self.max_age,
            .temporary = self.temporary,
            .created_at = self.created_at,
            .guild_scheduled_event_id = self.guild_scheduled_event_id,
        };
    }
};

const OwnedPresence = struct {
    guild_id: Snowflake,
    user_id: Snowflake,
    status: []u8,
    activities_count: usize,

    fn copy(allocator: std.mem.Allocator, presence: Types.Presence) !OwnedPresence {
        return .{
            .guild_id = presence.guild_id orelse return error.MissingField,
            .user_id = presence.user_id,
            .status = try allocator.dupe(u8, presence.status),
            .activities_count = presence.activities_count,
        };
    }

    fn deinit(self: OwnedPresence, allocator: std.mem.Allocator) void {
        allocator.free(self.status);
    }

    fn view(self: OwnedPresence) Types.Presence {
        return .{
            .guild_id = self.guild_id,
            .user_id = self.user_id,
            .status = self.status,
            .activities_count = self.activities_count,
        };
    }
};

const OwnedVoiceState = struct {
    guild_id: Snowflake,
    channel_id: ?Snowflake,
    user_id: Snowflake,
    session_id: []u8,
    deaf: bool,
    mute: bool,
    self_deaf: bool,
    self_mute: bool,
    self_stream: ?bool,
    self_video: bool,
    suppress: bool,
    request_to_speak_timestamp: ?[]u8,

    fn copy(allocator: std.mem.Allocator, voice_state: Types.VoiceState) !OwnedVoiceState {
        const session_id = try allocator.dupe(u8, voice_state.session_id);
        errdefer allocator.free(session_id);
        const request_to_speak_timestamp = if (voice_state.request_to_speak_timestamp) |value| try allocator.dupe(u8, value) else null;
        return .{
            .guild_id = voice_state.guild_id orelse return error.MissingField,
            .channel_id = voice_state.channel_id,
            .user_id = voice_state.user_id,
            .session_id = session_id,
            .deaf = voice_state.deaf,
            .mute = voice_state.mute,
            .self_deaf = voice_state.self_deaf,
            .self_mute = voice_state.self_mute,
            .self_stream = voice_state.self_stream,
            .self_video = voice_state.self_video,
            .suppress = voice_state.suppress,
            .request_to_speak_timestamp = request_to_speak_timestamp,
        };
    }

    fn deinit(self: OwnedVoiceState, allocator: std.mem.Allocator) void {
        allocator.free(self.session_id);
        if (self.request_to_speak_timestamp) |value| allocator.free(value);
    }

    fn view(self: OwnedVoiceState, member: ?Types.GuildMember) Types.VoiceState {
        return .{
            .guild_id = self.guild_id,
            .channel_id = self.channel_id,
            .user_id = self.user_id,
            .member = member,
            .session_id = self.session_id,
            .deaf = self.deaf,
            .mute = self.mute,
            .self_deaf = self.self_deaf,
            .self_mute = self.self_mute,
            .self_stream = self.self_stream,
            .self_video = self.self_video,
            .suppress = self.suppress,
            .request_to_speak_timestamp = self.request_to_speak_timestamp,
        };
    }
};

const OwnedMessage = struct {
    id: Snowflake,
    channel_id: Snowflake,
    guild_id: ?Snowflake,
    author_id: Snowflake,
    member: ?Types.GuildMember,
    message_reference: ?Types.MessageReferenceInfo,
    referenced_message_id: ?Snowflake,
    message_snapshots: []Types.MessageSnapshot,
    thread: ?Types.Channel,
    call: ?Types.MessageCall,
    role_subscription_data: ?Types.RoleSubscriptionData,
    shared_client_theme: ?Types.SharedClientTheme,
    webhook_id: ?Snowflake,
    application_id: ?Snowflake,
    application: ?Types.Application,
    activity: ?Types.MessageActivity,
    interaction_metadata: ?Types.MessageInteractionMetadata,
    type: u8,
    nonce: ?[]u8,
    content: []u8,
    timestamp: ?[]u8,
    edited_timestamp: ?[]u8,
    tts: bool,
    mention_everyone: bool,
    pinned: bool,
    position: ?i32,
    flags: ?u32,
    mentions: []Types.User,
    mention_roles: []Snowflake,
    mention_channels: []Types.Channel,
    embeds: []Types.Embed,
    attachments: []Types.Attachment,
    sticker_items: []Types.MessageStickerItem,
    stickers: []Types.Sticker,
    components: []Interactions.Component,
    poll: ?Types.MessagePoll,
    reactions: []Types.MessageReaction,

    fn copy(allocator: std.mem.Allocator, message: Types.Message) !OwnedMessage {
        const author = message.author orelse return error.MissingAuthor;
        const content = try allocator.dupe(u8, message.content);
        errdefer allocator.free(content);
        const member = if (message.member) |value| try copyGuildMember(allocator, value) else null;
        errdefer if (member) |value| deinitGuildMember(value, allocator);
        const thread = if (message.thread) |value| try copyChannel(allocator, value) else null;
        errdefer if (thread) |value| deinitChannel(value, allocator);
        const call = if (message.call) |value| try copyMessageCall(allocator, value) else null;
        errdefer if (call) |value| deinitMessageCall(value, allocator);
        const role_subscription_data = if (message.role_subscription_data) |value| try copyRoleSubscriptionData(allocator, value) else null;
        errdefer if (role_subscription_data) |value| deinitRoleSubscriptionData(value, allocator);
        const shared_client_theme = if (message.shared_client_theme) |value| try copySharedClientTheme(allocator, value) else null;
        errdefer if (shared_client_theme) |value| deinitSharedClientTheme(value, allocator);
        const nonce = if (message.nonce) |value| try allocator.dupe(u8, value) else null;
        errdefer if (nonce) |value| allocator.free(value);
        const application = if (message.application) |value| try copyApplication(allocator, value) else null;
        errdefer if (application) |value| deinitApplication(value, allocator);
        const activity = if (message.activity) |value| try copyMessageActivity(allocator, value) else null;
        errdefer if (activity) |value| deinitMessageActivity(value, allocator);
        const interaction_metadata = if (message.interaction_metadata) |value| try copyMessageInteractionMetadata(allocator, value) else null;
        errdefer if (interaction_metadata) |value| deinitMessageInteractionMetadata(value, allocator);
        const timestamp = if (message.timestamp) |value| try allocator.dupe(u8, value) else null;
        errdefer if (timestamp) |value| allocator.free(value);
        const edited_timestamp = if (message.edited_timestamp) |value| try allocator.dupe(u8, value) else null;
        errdefer if (edited_timestamp) |value| allocator.free(value);
        const message_snapshots = try copyMessageSnapshots(allocator, message.message_snapshots);
        errdefer deinitMessageSnapshots(message_snapshots, allocator);
        const attachments = try copyAttachments(allocator, message.attachments);
        errdefer deinitAttachments(attachments, allocator);
        const reactions = try copyReactions(allocator, message.reactions);
        errdefer deinitReactions(reactions, allocator);
        const embeds = try copyEmbeds(allocator, message.embeds);
        errdefer deinitEmbeds(embeds, allocator);
        const mentions = try copyUsers(allocator, message.mentions);
        errdefer deinitUsers(mentions, allocator);
        const mention_roles = try allocator.dupe(Snowflake, message.mention_roles);
        errdefer allocator.free(mention_roles);
        const mention_channels = try copyChannels(allocator, message.mention_channels);
        errdefer deinitChannels(mention_channels, allocator);
        const sticker_items = try copyMessageStickerItems(allocator, message.sticker_items);
        errdefer deinitMessageStickerItems(sticker_items, allocator);
        const stickers = try copyStickers(allocator, message.stickers);
        errdefer deinitStickers(stickers, allocator);
        const components = try copyComponents(allocator, message.components);
        errdefer deinitComponents(components, allocator);
        const poll = if (message.poll) |value| try copyMessagePoll(allocator, value) else null;
        errdefer if (poll) |value| deinitMessagePoll(value, allocator);
        return .{
            .id = message.id,
            .channel_id = message.channel_id,
            .guild_id = message.guild_id,
            .author_id = author.id,
            .member = member,
            .message_reference = message.message_reference,
            .referenced_message_id = message.referenced_message_id,
            .message_snapshots = message_snapshots,
            .thread = thread,
            .call = call,
            .role_subscription_data = role_subscription_data,
            .shared_client_theme = shared_client_theme,
            .webhook_id = message.webhook_id,
            .application_id = message.application_id,
            .application = application,
            .activity = activity,
            .interaction_metadata = interaction_metadata,
            .type = message.type,
            .nonce = nonce,
            .content = content,
            .timestamp = timestamp,
            .edited_timestamp = edited_timestamp,
            .tts = message.tts,
            .mention_everyone = message.mention_everyone,
            .pinned = message.pinned,
            .position = message.position,
            .flags = message.flags,
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
    }

    fn deinit(self: OwnedMessage, allocator: std.mem.Allocator) void {
        allocator.free(self.content);
        if (self.nonce) |value| allocator.free(value);
        if (self.application) |value| deinitApplication(value, allocator);
        if (self.activity) |value| deinitMessageActivity(value, allocator);
        if (self.interaction_metadata) |value| deinitMessageInteractionMetadata(value, allocator);
        if (self.member) |value| deinitGuildMember(value, allocator);
        if (self.thread) |value| deinitChannel(value, allocator);
        if (self.call) |value| deinitMessageCall(value, allocator);
        if (self.role_subscription_data) |value| deinitRoleSubscriptionData(value, allocator);
        if (self.shared_client_theme) |value| deinitSharedClientTheme(value, allocator);
        if (self.timestamp) |value| allocator.free(value);
        if (self.edited_timestamp) |value| allocator.free(value);
        deinitMessageSnapshots(self.message_snapshots, allocator);
        deinitUsers(self.mentions, allocator);
        allocator.free(self.mention_roles);
        deinitChannels(self.mention_channels, allocator);
        deinitEmbeds(self.embeds, allocator);
        deinitAttachments(self.attachments, allocator);
        deinitMessageStickerItems(self.sticker_items, allocator);
        deinitStickers(self.stickers, allocator);
        deinitComponents(self.components, allocator);
        if (self.poll) |value| deinitMessagePoll(value, allocator);
        deinitReactions(self.reactions, allocator);
    }

    fn view(self: OwnedMessage, author: ?Types.User) Types.Message {
        return .{
            .id = self.id,
            .channel_id = self.channel_id,
            .guild_id = self.guild_id,
            .author = author,
            .member = self.member,
            .message_reference = self.message_reference,
            .referenced_message_id = self.referenced_message_id,
            .message_snapshots = self.message_snapshots,
            .thread = self.thread,
            .call = self.call,
            .role_subscription_data = self.role_subscription_data,
            .shared_client_theme = self.shared_client_theme,
            .webhook_id = self.webhook_id,
            .application_id = self.application_id,
            .application = self.application,
            .activity = self.activity,
            .interaction_metadata = self.interaction_metadata,
            .type = self.type,
            .nonce = self.nonce,
            .content = self.content,
            .timestamp = self.timestamp,
            .edited_timestamp = self.edited_timestamp,
            .tts = self.tts,
            .mention_everyone = self.mention_everyone,
            .pinned = self.pinned,
            .position = self.position,
            .flags = self.flags,
            .mentions = self.mentions,
            .mention_roles = self.mention_roles,
            .mention_channels = self.mention_channels,
            .embeds = self.embeds,
            .attachments = self.attachments,
            .sticker_items = self.sticker_items,
            .stickers = self.stickers,
            .components = self.components,
            .poll = self.poll,
            .reactions = self.reactions,
        };
    }
};

fn copyAttachments(allocator: std.mem.Allocator, attachments: []const Types.Attachment) ![]Types.Attachment {
    const owned = try allocator.alloc(Types.Attachment, attachments.len);
    var initialized: usize = 0;
    errdefer deinitAttachments(owned[0..initialized], allocator);

    for (attachments, 0..) |attachment, index| {
        owned[index] = try copyAttachment(allocator, attachment);
        initialized += 1;
    }
    return owned;
}

fn copyAttachment(allocator: std.mem.Allocator, attachment: Types.Attachment) !Types.Attachment {
    const filename = try allocator.dupe(u8, attachment.filename);
    errdefer allocator.free(filename);
    const description = if (attachment.description) |value| try allocator.dupe(u8, value) else null;
    errdefer if (description) |value| allocator.free(value);
    const content_type = if (attachment.content_type) |value| try allocator.dupe(u8, value) else null;
    errdefer if (content_type) |value| allocator.free(value);
    const url = try allocator.dupe(u8, attachment.url);
    errdefer allocator.free(url);
    const proxy_url = try allocator.dupe(u8, attachment.proxy_url);

    return .{
        .id = attachment.id,
        .filename = filename,
        .description = description,
        .content_type = content_type,
        .size = attachment.size,
        .url = url,
        .proxy_url = proxy_url,
        .height = attachment.height,
        .width = attachment.width,
        .ephemeral = attachment.ephemeral,
    };
}

fn deinitAttachments(attachments: []Types.Attachment, allocator: std.mem.Allocator) void {
    for (attachments) |attachment| {
        allocator.free(attachment.filename);
        if (attachment.description) |value| allocator.free(value);
        if (attachment.content_type) |value| allocator.free(value);
        allocator.free(attachment.url);
        allocator.free(attachment.proxy_url);
    }
    allocator.free(attachments);
}

fn copyMessageSnapshots(
    allocator: std.mem.Allocator,
    snapshots: []const Types.MessageSnapshot,
) ![]Types.MessageSnapshot {
    const owned = try allocator.alloc(Types.MessageSnapshot, snapshots.len);
    var initialized: usize = 0;
    errdefer deinitMessageSnapshots(owned[0..initialized], allocator);

    for (snapshots, 0..) |snapshot, index| {
        owned[index] = try copyMessageSnapshot(allocator, snapshot);
        initialized += 1;
    }
    return owned;
}

fn copyMessageSnapshot(
    allocator: std.mem.Allocator,
    snapshot: Types.MessageSnapshot,
) !Types.MessageSnapshot {
    const content = try allocator.dupe(u8, snapshot.content);
    errdefer allocator.free(content);
    const timestamp = if (snapshot.timestamp) |value| try allocator.dupe(u8, value) else null;
    errdefer if (timestamp) |value| allocator.free(value);
    const edited_timestamp = if (snapshot.edited_timestamp) |value| try allocator.dupe(u8, value) else null;
    errdefer if (edited_timestamp) |value| allocator.free(value);
    const mentions = try copyUsers(allocator, snapshot.mentions);
    errdefer deinitUsers(mentions, allocator);
    const mention_roles = try allocator.dupe(Snowflake, snapshot.mention_roles);
    errdefer allocator.free(mention_roles);
    const embeds = try copyEmbeds(allocator, snapshot.embeds);
    errdefer deinitEmbeds(embeds, allocator);
    const attachments = try copyAttachments(allocator, snapshot.attachments);
    errdefer deinitAttachments(attachments, allocator);
    const components = try copyComponents(allocator, snapshot.components);
    errdefer deinitComponents(components, allocator);

    return .{
        .type = snapshot.type,
        .content = content,
        .timestamp = timestamp,
        .edited_timestamp = edited_timestamp,
        .flags = snapshot.flags,
        .mentions = mentions,
        .mention_roles = mention_roles,
        .embeds = embeds,
        .attachments = attachments,
        .components = components,
    };
}

fn deinitMessageSnapshots(snapshots: []Types.MessageSnapshot, allocator: std.mem.Allocator) void {
    for (snapshots) |snapshot| deinitMessageSnapshot(snapshot, allocator);
    allocator.free(snapshots);
}

fn deinitMessageSnapshot(snapshot: Types.MessageSnapshot, allocator: std.mem.Allocator) void {
    allocator.free(snapshot.content);
    if (snapshot.timestamp) |value| allocator.free(value);
    if (snapshot.edited_timestamp) |value| allocator.free(value);
    deinitUsers(@constCast(snapshot.mentions), allocator);
    allocator.free(snapshot.mention_roles);
    deinitEmbeds(@constCast(snapshot.embeds), allocator);
    deinitAttachments(@constCast(snapshot.attachments), allocator);
    deinitComponents(@constCast(snapshot.components), allocator);
}

fn copyMessageStickerItems(
    allocator: std.mem.Allocator,
    sticker_items: []const Types.MessageStickerItem,
) ![]Types.MessageStickerItem {
    const owned = try allocator.alloc(Types.MessageStickerItem, sticker_items.len);
    var initialized: usize = 0;
    errdefer deinitMessageStickerItems(owned[0..initialized], allocator);

    for (sticker_items, 0..) |sticker_item, index| {
        owned[index] = .{
            .id = sticker_item.id,
            .name = try allocator.dupe(u8, sticker_item.name),
            .format_type = sticker_item.format_type,
        };
        initialized += 1;
    }
    return owned;
}

fn deinitMessageStickerItems(sticker_items: []Types.MessageStickerItem, allocator: std.mem.Allocator) void {
    for (sticker_items) |sticker_item| allocator.free(sticker_item.name);
    allocator.free(sticker_items);
}

fn copyStickers(allocator: std.mem.Allocator, stickers: []const Types.Sticker) ![]Types.Sticker {
    const owned = try allocator.alloc(Types.Sticker, stickers.len);
    var initialized: usize = 0;
    errdefer deinitStickers(owned[0..initialized], allocator);

    for (stickers, 0..) |sticker, index| {
        owned[index] = try copySticker(allocator, sticker);
        initialized += 1;
    }
    return owned;
}

fn copySticker(allocator: std.mem.Allocator, sticker: Types.Sticker) !Types.Sticker {
    const name = try allocator.dupe(u8, sticker.name);
    errdefer allocator.free(name);
    const description = if (sticker.description) |value| try allocator.dupe(u8, value) else null;
    errdefer if (description) |value| allocator.free(value);
    const tags = try allocator.dupe(u8, sticker.tags);
    errdefer allocator.free(tags);
    const user = if (sticker.user) |value| try copyUser(allocator, value) else null;

    return .{
        .id = sticker.id,
        .pack_id = sticker.pack_id,
        .name = name,
        .description = description,
        .tags = tags,
        .type = sticker.type,
        .format_type = sticker.format_type,
        .available = sticker.available,
        .guild_id = sticker.guild_id,
        .user = user,
        .sort_value = sticker.sort_value,
    };
}

fn deinitStickers(stickers: []Types.Sticker, allocator: std.mem.Allocator) void {
    for (stickers) |sticker| deinitSticker(sticker, allocator);
    allocator.free(stickers);
}

fn deinitSticker(sticker: Types.Sticker, allocator: std.mem.Allocator) void {
    allocator.free(sticker.name);
    if (sticker.description) |value| allocator.free(value);
    allocator.free(sticker.tags);
    if (sticker.user) |value| deinitUser(value, allocator);
}

fn copyComponents(allocator: std.mem.Allocator, components: []const Interactions.Component) anyerror![]Interactions.Component {
    const owned = try allocator.alloc(Interactions.Component, components.len);
    var initialized: usize = 0;
    errdefer deinitComponents(owned[0..initialized], allocator);

    for (components, 0..) |component, index| {
        owned[index] = try copyComponent(allocator, component);
        initialized += 1;
    }
    return owned;
}

fn copyComponent(allocator: std.mem.Allocator, component: Interactions.Component) anyerror!Interactions.Component {
    return switch (component) {
        .action_row => |children| .{ .action_row = try copyComponents(allocator, children) },
        .button => |button| .{ .button = try copyButton(allocator, button) },
        .string_select => |select| .{ .string_select = try copyStringSelect(allocator, select) },
        .user_select => |select| .{ .user_select = try copyAutoSelect(allocator, select) },
        .role_select => |select| .{ .role_select = try copyAutoSelect(allocator, select) },
        .mentionable_select => |select| .{ .mentionable_select = try copyAutoSelect(allocator, select) },
        .channel_select => |select| .{ .channel_select = try copyAutoSelect(allocator, select) },
        .text_input => |input| .{ .text_input = try copyTextInput(allocator, input) },
        .section => |value| .{ .section = try copySection(allocator, value) },
        .text_display => |value| .{ .text_display = try copyTextDisplay(allocator, value) },
        .thumbnail => |value| .{ .thumbnail = try copyThumbnail(allocator, value) },
        .media_gallery => |value| .{ .media_gallery = try copyMediaGallery(allocator, value) },
        .file => |value| .{ .file = try copyFileComponent(allocator, value) },
        .separator => |value| .{ .separator = value },
        .container => |value| .{ .container = try copyContainer(allocator, value) },
    };
}

fn copyButton(allocator: std.mem.Allocator, button: Interactions.Button) !Interactions.Button {
    const custom_id = if (button.custom_id) |value| try allocator.dupe(u8, value) else null;
    errdefer if (custom_id) |value| allocator.free(value);
    const label = if (button.label) |value| try allocator.dupe(u8, value) else null;
    errdefer if (label) |value| allocator.free(value);
    const url = if (button.url) |value| try allocator.dupe(u8, value) else null;
    return .{ .custom_id = custom_id, .label = label, .style = button.style, .url = url, .disabled = button.disabled };
}

fn copyStringSelect(allocator: std.mem.Allocator, select: Interactions.StringSelect) !Interactions.StringSelect {
    const custom_id = try allocator.dupe(u8, select.custom_id);
    errdefer allocator.free(custom_id);
    const options = try copySelectOptions(allocator, select.options);
    errdefer deinitSelectOptions(options, allocator);
    const placeholder = if (select.placeholder) |value| try allocator.dupe(u8, value) else null;
    return .{
        .custom_id = custom_id,
        .options = options,
        .placeholder = placeholder,
        .min_values = select.min_values,
        .max_values = select.max_values,
        .disabled = select.disabled,
    };
}

fn copyAutoSelect(allocator: std.mem.Allocator, select: Interactions.AutoSelect) !Interactions.AutoSelect {
    const custom_id = try allocator.dupe(u8, select.custom_id);
    errdefer allocator.free(custom_id);
    const placeholder = if (select.placeholder) |value| try allocator.dupe(u8, value) else null;
    errdefer if (placeholder) |value| allocator.free(value);
    const channel_types = try allocator.dupe(u8, select.channel_types);
    return .{
        .type = select.type,
        .custom_id = custom_id,
        .placeholder = placeholder,
        .min_values = select.min_values,
        .max_values = select.max_values,
        .disabled = select.disabled,
        .channel_types = channel_types,
    };
}

fn copyTextInput(allocator: std.mem.Allocator, input: Interactions.TextInput) !Interactions.TextInput {
    const custom_id = try allocator.dupe(u8, input.custom_id);
    errdefer allocator.free(custom_id);
    const label = try allocator.dupe(u8, input.label);
    errdefer allocator.free(label);
    const placeholder = if (input.placeholder) |value| try allocator.dupe(u8, value) else null;
    errdefer if (placeholder) |value| allocator.free(value);
    const value = if (input.value) |field| try allocator.dupe(u8, field) else null;
    return .{
        .custom_id = custom_id,
        .label = label,
        .style = input.style,
        .placeholder = placeholder,
        .value = value,
        .required = input.required,
        .min_length = input.min_length,
        .max_length = input.max_length,
    };
}

fn copyTextDisplay(allocator: std.mem.Allocator, value: Interactions.TextDisplay) !Interactions.TextDisplay {
    return .{ .content = try allocator.dupe(u8, value.content), .id = value.id };
}

fn copyUnfurledMedia(allocator: std.mem.Allocator, value: Interactions.UnfurledMedia) !Interactions.UnfurledMedia {
    return .{ .url = try allocator.dupe(u8, value.url) };
}

fn copyThumbnail(allocator: std.mem.Allocator, value: Interactions.Thumbnail) !Interactions.Thumbnail {
    const media = try copyUnfurledMedia(allocator, value.media);
    errdefer allocator.free(media.url);
    const description = if (value.description) |field| try allocator.dupe(u8, field) else null;
    return .{ .media = media, .description = description, .spoiler = value.spoiler, .id = value.id };
}

fn copySection(allocator: std.mem.Allocator, value: Interactions.Section) !Interactions.Section {
    const components = try allocator.alloc(Interactions.TextDisplay, value.components.len);
    var initialized: usize = 0;
    errdefer {
        for (components[0..initialized]) |text| allocator.free(text.content);
        allocator.free(components);
    }
    for (value.components, 0..) |text, index| {
        components[index] = try copyTextDisplay(allocator, text);
        initialized += 1;
    }
    const accessory: Interactions.SectionAccessory = switch (value.accessory) {
        .button => |button| .{ .button = try copyButton(allocator, button) },
        .thumbnail => |thumbnail| .{ .thumbnail = try copyThumbnail(allocator, thumbnail) },
    };
    return .{ .components = components, .accessory = accessory, .id = value.id };
}

fn copyMediaGallery(allocator: std.mem.Allocator, value: Interactions.MediaGallery) !Interactions.MediaGallery {
    const items = try allocator.alloc(Interactions.MediaGalleryItem, value.items.len);
    var initialized: usize = 0;
    errdefer {
        for (items[0..initialized]) |item| deinitMediaGalleryItem(item, allocator);
        allocator.free(items);
    }
    for (value.items, 0..) |item, index| {
        const media = try copyUnfurledMedia(allocator, item.media);
        errdefer allocator.free(media.url);
        const description = if (item.description) |field| try allocator.dupe(u8, field) else null;
        items[index] = .{ .media = media, .description = description, .spoiler = item.spoiler };
        initialized += 1;
    }
    return .{ .items = items, .id = value.id };
}

fn copyFileComponent(allocator: std.mem.Allocator, value: Interactions.FileComponent) !Interactions.FileComponent {
    return .{ .file = try copyUnfurledMedia(allocator, value.file), .spoiler = value.spoiler, .id = value.id };
}

fn copyContainer(allocator: std.mem.Allocator, value: Interactions.Container) !Interactions.Container {
    return .{
        .components = try copyComponents(allocator, value.components),
        .accent_color = value.accent_color,
        .spoiler = value.spoiler,
        .id = value.id,
    };
}

fn copySelectOptions(allocator: std.mem.Allocator, options: []const Interactions.SelectOption) ![]Interactions.SelectOption {
    const owned = try allocator.alloc(Interactions.SelectOption, options.len);
    var initialized: usize = 0;
    errdefer deinitSelectOptions(owned[0..initialized], allocator);

    for (options, 0..) |option, index| {
        const label = try allocator.dupe(u8, option.label);
        errdefer allocator.free(label);
        const value = try allocator.dupe(u8, option.value);
        errdefer allocator.free(value);
        const description = if (option.description) |field| try allocator.dupe(u8, field) else null;
        owned[index] = .{ .label = label, .value = value, .description = description, .default = option.default };
        initialized += 1;
    }
    return owned;
}

fn deinitComponents(components: []Interactions.Component, allocator: std.mem.Allocator) void {
    for (components) |component| deinitComponent(component, allocator);
    allocator.free(components);
}

fn deinitComponent(component: Interactions.Component, allocator: std.mem.Allocator) void {
    switch (component) {
        .action_row => |children| deinitComponents(@constCast(children), allocator),
        .button => |button| {
            if (button.custom_id) |value| allocator.free(value);
            if (button.label) |value| allocator.free(value);
            if (button.url) |value| allocator.free(value);
        },
        .string_select => |select| {
            allocator.free(select.custom_id);
            deinitSelectOptions(@constCast(select.options), allocator);
            if (select.placeholder) |value| allocator.free(value);
        },
        .user_select, .role_select, .mentionable_select, .channel_select => |select| {
            allocator.free(select.custom_id);
            if (select.placeholder) |value| allocator.free(value);
            allocator.free(select.channel_types);
        },
        .text_input => |input| {
            allocator.free(input.custom_id);
            allocator.free(input.label);
            if (input.placeholder) |value| allocator.free(value);
            if (input.value) |value| allocator.free(value);
        },
        .section => |value| {
            for (value.components) |text| allocator.free(text.content);
            allocator.free(@constCast(value.components));
            switch (value.accessory) {
                .button => |button| {
                    if (button.custom_id) |field| allocator.free(field);
                    if (button.label) |field| allocator.free(field);
                    if (button.url) |field| allocator.free(field);
                },
                .thumbnail => |thumbnail| deinitThumbnail(thumbnail, allocator),
            }
        },
        .text_display => |value| allocator.free(value.content),
        .thumbnail => |value| deinitThumbnail(value, allocator),
        .media_gallery => |value| {
            for (value.items) |item| deinitMediaGalleryItem(item, allocator);
            allocator.free(@constCast(value.items));
        },
        .file => |value| allocator.free(value.file.url),
        .separator => {},
        .container => |value| deinitComponents(@constCast(value.components), allocator),
    }
}

fn deinitSelectOptions(options: []Interactions.SelectOption, allocator: std.mem.Allocator) void {
    for (options) |option| {
        allocator.free(option.label);
        allocator.free(option.value);
        if (option.description) |value| allocator.free(value);
    }
    allocator.free(options);
}

fn deinitThumbnail(thumbnail: Interactions.Thumbnail, allocator: std.mem.Allocator) void {
    allocator.free(thumbnail.media.url);
    if (thumbnail.description) |value| allocator.free(value);
}

fn deinitMediaGalleryItem(item: Interactions.MediaGalleryItem, allocator: std.mem.Allocator) void {
    allocator.free(item.media.url);
    if (item.description) |value| allocator.free(value);
}

fn copyMessagePoll(allocator: std.mem.Allocator, poll: Types.MessagePoll) !Types.MessagePoll {
    const question = try copyMessagePollMedia(allocator, poll.question);
    errdefer deinitMessagePollMedia(question, allocator);
    const answers = try copyMessagePollAnswers(allocator, poll.answers);
    errdefer deinitMessagePollAnswers(answers, allocator);
    const expiry = if (poll.expiry) |value| try allocator.dupe(u8, value) else null;
    errdefer if (expiry) |value| allocator.free(value);
    const results = if (poll.results) |value| try copyMessagePollResults(allocator, value) else null;

    return .{
        .question = question,
        .answers = answers,
        .expiry = expiry,
        .allow_multiselect = poll.allow_multiselect,
        .layout_type = poll.layout_type,
        .results = results,
    };
}

fn copyMessagePollMedia(allocator: std.mem.Allocator, media: Types.MessagePollMedia) !Types.MessagePollMedia {
    const text = if (media.text) |value| try allocator.dupe(u8, value) else null;
    errdefer if (text) |value| allocator.free(value);
    const emoji = if (media.emoji) |value| try copyPollEmoji(allocator, value) else null;
    return .{ .text = text, .emoji = emoji };
}

fn copyPollEmoji(allocator: std.mem.Allocator, emoji: Types.PollEmoji) !Types.PollEmoji {
    return .{
        .id = emoji.id,
        .name = if (emoji.name) |value| try allocator.dupe(u8, value) else null,
    };
}

fn copyMessagePollAnswers(
    allocator: std.mem.Allocator,
    answers: []const Types.MessagePollAnswer,
) ![]Types.MessagePollAnswer {
    const owned = try allocator.alloc(Types.MessagePollAnswer, answers.len);
    var initialized: usize = 0;
    errdefer deinitMessagePollAnswers(owned[0..initialized], allocator);

    for (answers, 0..) |answer, index| {
        owned[index] = .{
            .answer_id = answer.answer_id,
            .poll_media = try copyMessagePollMedia(allocator, answer.poll_media),
        };
        initialized += 1;
    }
    return owned;
}

fn copyMessagePollResults(
    allocator: std.mem.Allocator,
    results: Types.MessagePollResults,
) !Types.MessagePollResults {
    return .{
        .is_finalized = results.is_finalized,
        .answer_counts = try allocator.dupe(Types.MessagePollAnswerCount, results.answer_counts),
    };
}

fn deinitMessagePoll(poll: Types.MessagePoll, allocator: std.mem.Allocator) void {
    deinitMessagePollMedia(poll.question, allocator);
    deinitMessagePollAnswers(@constCast(poll.answers), allocator);
    if (poll.expiry) |value| allocator.free(value);
    if (poll.results) |value| allocator.free(value.answer_counts);
}

fn deinitMessagePollAnswers(answers: []Types.MessagePollAnswer, allocator: std.mem.Allocator) void {
    for (answers) |answer| deinitMessagePollMedia(answer.poll_media, allocator);
    allocator.free(answers);
}

fn deinitMessagePollMedia(media: Types.MessagePollMedia, allocator: std.mem.Allocator) void {
    if (media.text) |value| allocator.free(value);
    if (media.emoji) |emoji| {
        if (emoji.name) |value| allocator.free(value);
    }
}

fn copyMessageCall(allocator: std.mem.Allocator, call: Types.MessageCall) !Types.MessageCall {
    const participants = try allocator.dupe(Snowflake, call.participants);
    errdefer allocator.free(participants);
    const ended_timestamp = if (call.ended_timestamp) |value| try allocator.dupe(u8, value) else null;
    return .{ .participants = participants, .ended_timestamp = ended_timestamp };
}

fn deinitMessageCall(call: Types.MessageCall, allocator: std.mem.Allocator) void {
    allocator.free(call.participants);
    if (call.ended_timestamp) |value| allocator.free(value);
}

fn copyRoleSubscriptionData(
    allocator: std.mem.Allocator,
    data: Types.RoleSubscriptionData,
) !Types.RoleSubscriptionData {
    return .{
        .role_subscription_listing_id = data.role_subscription_listing_id,
        .tier_name = try allocator.dupe(u8, data.tier_name),
        .total_months_subscribed = data.total_months_subscribed,
        .is_renewal = data.is_renewal,
    };
}

fn deinitRoleSubscriptionData(data: Types.RoleSubscriptionData, allocator: std.mem.Allocator) void {
    allocator.free(data.tier_name);
}

fn copySharedClientTheme(
    allocator: std.mem.Allocator,
    theme: Types.SharedClientTheme,
) !Types.SharedClientTheme {
    return .{
        .colors = try copyStringArray(allocator, theme.colors),
        .gradient_angle = theme.gradient_angle,
        .base_mix = theme.base_mix,
        .base_theme = theme.base_theme,
    };
}

fn deinitSharedClientTheme(theme: Types.SharedClientTheme, allocator: std.mem.Allocator) void {
    deinitConstStringArray(theme.colors, allocator);
}

fn copyMessageActivity(allocator: std.mem.Allocator, activity: Types.MessageActivity) !Types.MessageActivity {
    return .{
        .type = activity.type,
        .party_id = if (activity.party_id) |value| try allocator.dupe(u8, value) else null,
    };
}

fn deinitMessageActivity(activity: Types.MessageActivity, allocator: std.mem.Allocator) void {
    if (activity.party_id) |value| allocator.free(value);
}

fn copyMessageInteractionMetadata(
    allocator: std.mem.Allocator,
    metadata: Types.MessageInteractionMetadata,
) !Types.MessageInteractionMetadata {
    const user = try copyUser(allocator, metadata.user);
    errdefer deinitUser(user, allocator);
    const target_user = if (metadata.target_user) |value| try copyUser(allocator, value) else null;

    return .{
        .id = metadata.id,
        .type = metadata.type,
        .user = user,
        .original_response_message_id = metadata.original_response_message_id,
        .interacted_message_id = metadata.interacted_message_id,
        .target_user = target_user,
        .target_message_id = metadata.target_message_id,
    };
}

fn deinitMessageInteractionMetadata(
    metadata: Types.MessageInteractionMetadata,
    allocator: std.mem.Allocator,
) void {
    deinitUser(metadata.user, allocator);
    if (metadata.target_user) |value| deinitUser(value, allocator);
}

fn copyGuildMember(allocator: std.mem.Allocator, member: Types.GuildMember) !Types.GuildMember {
    const user = if (member.user) |value| try copyUser(allocator, value) else null;
    errdefer if (user) |value| deinitUser(value, allocator);
    const nick = if (member.nick) |value| try allocator.dupe(u8, value) else null;
    errdefer if (nick) |value| allocator.free(value);
    const avatar = if (member.avatar) |value| try allocator.dupe(u8, value) else null;
    errdefer if (avatar) |value| allocator.free(value);
    const roles = try allocator.dupe(Snowflake, member.roles);
    errdefer allocator.free(roles);
    const joined_at = if (member.joined_at) |value| try allocator.dupe(u8, value) else null;
    errdefer if (joined_at) |value| allocator.free(value);
    const premium_since = if (member.premium_since) |value| try allocator.dupe(u8, value) else null;
    errdefer if (premium_since) |value| allocator.free(value);
    const communication_disabled_until = if (member.communication_disabled_until) |value| try allocator.dupe(u8, value) else null;

    return .{
        .user = user,
        .nick = nick,
        .avatar = avatar,
        .roles = roles,
        .joined_at = joined_at,
        .premium_since = premium_since,
        .deaf = member.deaf,
        .mute = member.mute,
        .pending = member.pending,
        .communication_disabled_until = communication_disabled_until,
        .flags = member.flags,
        .permissions = member.permissions,
    };
}

fn deinitGuildMember(member: Types.GuildMember, allocator: std.mem.Allocator) void {
    if (member.user) |value| deinitUser(value, allocator);
    if (member.nick) |value| allocator.free(value);
    if (member.avatar) |value| allocator.free(value);
    allocator.free(member.roles);
    if (member.joined_at) |value| allocator.free(value);
    if (member.premium_since) |value| allocator.free(value);
    if (member.communication_disabled_until) |value| allocator.free(value);
}

fn copyUsers(allocator: std.mem.Allocator, users: []const Types.User) ![]Types.User {
    const owned = try allocator.alloc(Types.User, users.len);
    var initialized: usize = 0;
    errdefer deinitUsers(owned[0..initialized], allocator);

    for (users, 0..) |user, index| {
        owned[index] = try copyUser(allocator, user);
        initialized += 1;
    }
    return owned;
}

fn copyUser(allocator: std.mem.Allocator, user: Types.User) !Types.User {
    const username = try allocator.dupe(u8, user.username);
    errdefer allocator.free(username);
    const discriminator = if (user.discriminator) |value| try allocator.dupe(u8, value) else null;
    errdefer if (discriminator) |value| allocator.free(value);
    const global_name = if (user.global_name) |value| try allocator.dupe(u8, value) else null;
    errdefer if (global_name) |value| allocator.free(value);
    const avatar = if (user.avatar) |value| try allocator.dupe(u8, value) else null;
    errdefer if (avatar) |value| allocator.free(value);
    const banner = if (user.banner) |value| try allocator.dupe(u8, value) else null;

    return .{
        .id = user.id,
        .username = username,
        .discriminator = discriminator,
        .global_name = global_name,
        .avatar = avatar,
        .banner = banner,
        .bot = user.bot,
    };
}

fn deinitUsers(users: []Types.User, allocator: std.mem.Allocator) void {
    for (users) |user| deinitUser(user, allocator);
    allocator.free(users);
}

fn deinitUser(user: Types.User, allocator: std.mem.Allocator) void {
    allocator.free(user.username);
    if (user.discriminator) |value| allocator.free(value);
    if (user.global_name) |value| allocator.free(value);
    if (user.avatar) |value| allocator.free(value);
    if (user.banner) |value| allocator.free(value);
}

fn copyApplication(allocator: std.mem.Allocator, application: Types.Application) !Types.Application {
    const name = try allocator.dupe(u8, application.name);
    errdefer allocator.free(name);
    const icon = if (application.icon) |value| try allocator.dupe(u8, value) else null;
    errdefer if (icon) |value| allocator.free(value);
    const description = try allocator.dupe(u8, application.description);
    errdefer allocator.free(description);
    const bot = if (application.bot) |value| try copyUser(allocator, value) else null;
    errdefer if (bot) |value| deinitUser(value, allocator);
    const owner = if (application.owner) |value| try copyUser(allocator, value) else null;
    errdefer if (owner) |value| deinitUser(value, allocator);
    const verify_key = try allocator.dupe(u8, application.verify_key);
    errdefer allocator.free(verify_key);
    const interactions_endpoint_url = if (application.interactions_endpoint_url) |value| try allocator.dupe(u8, value) else null;
    errdefer if (interactions_endpoint_url) |value| allocator.free(value);
    const role_connections_verification_url = if (application.role_connections_verification_url) |value| try allocator.dupe(u8, value) else null;
    errdefer if (role_connections_verification_url) |value| allocator.free(value);
    const event_webhooks_url = if (application.event_webhooks_url) |value| try allocator.dupe(u8, value) else null;
    errdefer if (event_webhooks_url) |value| allocator.free(value);
    const event_webhooks_types = try copyStringArray(allocator, application.event_webhooks_types);
    errdefer deinitStringArray(event_webhooks_types, allocator);
    const tags = try copyStringArray(allocator, application.tags);
    errdefer deinitStringArray(tags, allocator);
    const custom_install_url = if (application.custom_install_url) |value| try allocator.dupe(u8, value) else null;
    const team = if (application.team) |value| try copyTeam(allocator, value) else null;
    errdefer if (team) |value| deinitTeam(value, allocator);

    return .{
        .id = application.id,
        .name = name,
        .icon = icon,
        .description = description,
        .bot_public = application.bot_public,
        .bot_require_code_grant = application.bot_require_code_grant,
        .bot = bot,
        .owner = owner,
        .team = team,
        .verify_key = verify_key,
        .guild_id = application.guild_id,
        .flags = application.flags,
        .approximate_guild_count = application.approximate_guild_count,
        .approximate_user_install_count = application.approximate_user_install_count,
        .interactions_endpoint_url = interactions_endpoint_url,
        .role_connections_verification_url = role_connections_verification_url,
        .event_webhooks_url = event_webhooks_url,
        .event_webhooks_status = application.event_webhooks_status,
        .event_webhooks_types = event_webhooks_types,
        .tags = tags,
        .custom_install_url = custom_install_url,
    };
}

fn deinitApplication(application: Types.Application, allocator: std.mem.Allocator) void {
    allocator.free(application.name);
    if (application.icon) |value| allocator.free(value);
    allocator.free(application.description);
    if (application.bot) |value| deinitUser(value, allocator);
    if (application.owner) |value| deinitUser(value, allocator);
    allocator.free(application.verify_key);
    if (application.interactions_endpoint_url) |value| allocator.free(value);
    if (application.role_connections_verification_url) |value| allocator.free(value);
    if (application.event_webhooks_url) |value| allocator.free(value);
    deinitConstStringArray(application.event_webhooks_types, allocator);
    deinitConstStringArray(application.tags, allocator);
    if (application.custom_install_url) |value| allocator.free(value);
    if (application.team) |team| deinitTeam(team, allocator);
}

fn copyChannels(allocator: std.mem.Allocator, channels: []const Types.Channel) ![]Types.Channel {
    const owned = try allocator.alloc(Types.Channel, channels.len);
    var initialized: usize = 0;
    errdefer deinitChannels(owned[0..initialized], allocator);

    for (channels, 0..) |channel, index| {
        owned[index] = try copyChannel(allocator, channel);
        initialized += 1;
    }
    return owned;
}

fn copyChannel(allocator: std.mem.Allocator, channel: Types.Channel) !Types.Channel {
    const name = if (channel.name) |value| try allocator.dupe(u8, value) else null;
    errdefer if (name) |value| allocator.free(value);
    const topic = if (channel.topic) |value| try allocator.dupe(u8, value) else null;
    errdefer if (topic) |value| allocator.free(value);
    const status = if (channel.status) |value| try allocator.dupe(u8, value) else null;
    errdefer if (status) |value| allocator.free(value);
    const last_pin_timestamp = if (channel.last_pin_timestamp) |value| try allocator.dupe(u8, value) else null;
    errdefer if (last_pin_timestamp) |value| allocator.free(value);
    const rtc_region = if (channel.rtc_region) |value| try allocator.dupe(u8, value) else null;
    errdefer if (rtc_region) |value| allocator.free(value);
    const permission_overwrites = try allocator.dupe(Types.PermissionOverwrite, channel.permission_overwrites);
    errdefer allocator.free(permission_overwrites);
    const thread_metadata = if (channel.thread_metadata) |value| try copyThreadMetadata(allocator, value) else null;
    errdefer if (thread_metadata) |value| deinitThreadMetadata(value, allocator);
    const applied_tags = try allocator.dupe(Snowflake, channel.applied_tags);
    errdefer allocator.free(applied_tags);
    const available_tags = try copyForumTags(allocator, channel.available_tags);
    errdefer deinitForumTags(available_tags, allocator);
    const default_reaction_emoji = if (channel.default_reaction_emoji) |value| try copyDefaultReactionEmoji(allocator, value) else null;
    return .{
        .id = channel.id,
        .type = channel.type,
        .guild_id = channel.guild_id,
        .name = name,
        .topic = topic,
        .status = status,
        .voice_start_time = channel.voice_start_time,
        .last_message_id = channel.last_message_id,
        .last_pin_timestamp = last_pin_timestamp,
        .parent_id = channel.parent_id,
        .owner_id = channel.owner_id,
        .application_id = channel.application_id,
        .position = channel.position,
        .nsfw = channel.nsfw,
        .rate_limit_per_user = channel.rate_limit_per_user,
        .bitrate = channel.bitrate,
        .user_limit = channel.user_limit,
        .rtc_region = rtc_region,
        .video_quality_mode = channel.video_quality_mode,
        .message_count = channel.message_count,
        .member_count = channel.member_count,
        .managed = channel.managed,
        .flags = channel.flags,
        .permission_overwrites = permission_overwrites,
        .thread_metadata = thread_metadata,
        .applied_tags = applied_tags,
        .available_tags = available_tags,
        .default_reaction_emoji = default_reaction_emoji,
        .default_thread_rate_limit_per_user = channel.default_thread_rate_limit_per_user,
        .default_sort_order = channel.default_sort_order,
        .default_forum_layout = channel.default_forum_layout,
    };
}

fn copyDefaultReactionEmoji(
    allocator: std.mem.Allocator,
    emoji: Types.DefaultReactionEmoji,
) !Types.DefaultReactionEmoji {
    return .{
        .emoji_id = emoji.emoji_id,
        .emoji_name = if (emoji.emoji_name) |value| try allocator.dupe(u8, value) else null,
    };
}

fn copyForumTags(allocator: std.mem.Allocator, tags: []const Types.ForumTag) ![]Types.ForumTag {
    const owned = try allocator.alloc(Types.ForumTag, tags.len);
    var initialized: usize = 0;
    errdefer deinitForumTags(owned[0..initialized], allocator);

    for (tags, 0..) |tag, index| {
        owned[index] = try copyForumTag(allocator, tag);
        initialized += 1;
    }
    return owned;
}

fn copyForumTag(allocator: std.mem.Allocator, tag: Types.ForumTag) !Types.ForumTag {
    const name = try allocator.dupe(u8, tag.name);
    errdefer allocator.free(name);
    const emoji_name = if (tag.emoji_name) |value| try allocator.dupe(u8, value) else null;
    return .{
        .id = tag.id,
        .name = name,
        .moderated = tag.moderated,
        .emoji_id = tag.emoji_id,
        .emoji_name = emoji_name,
    };
}

fn copyThreadMetadata(
    allocator: std.mem.Allocator,
    metadata: Types.ThreadMetadata,
) !Types.ThreadMetadata {
    const archive_timestamp = if (metadata.archive_timestamp) |value| try allocator.dupe(u8, value) else null;
    errdefer if (archive_timestamp) |value| allocator.free(value);
    const create_timestamp = if (metadata.create_timestamp) |value| try allocator.dupe(u8, value) else null;
    return .{
        .archived = metadata.archived,
        .auto_archive_duration = metadata.auto_archive_duration,
        .archive_timestamp = archive_timestamp,
        .locked = metadata.locked,
        .invitable = metadata.invitable,
        .create_timestamp = create_timestamp,
    };
}

fn deinitChannels(channels: []Types.Channel, allocator: std.mem.Allocator) void {
    for (channels) |channel| deinitChannel(channel, allocator);
    allocator.free(channels);
}

fn deinitChannel(channel: Types.Channel, allocator: std.mem.Allocator) void {
    if (channel.name) |value| allocator.free(value);
    if (channel.topic) |value| allocator.free(value);
    if (channel.status) |value| allocator.free(value);
    if (channel.last_pin_timestamp) |value| allocator.free(@constCast(value));
    if (channel.rtc_region) |value| allocator.free(@constCast(value));
    allocator.free(@constCast(channel.permission_overwrites));
    if (channel.thread_metadata) |value| deinitThreadMetadata(value, allocator);
    allocator.free(channel.applied_tags);
    deinitForumTags(channel.available_tags, allocator);
    if (channel.default_reaction_emoji) |value| deinitDefaultReactionEmoji(value, allocator);
}

fn deinitDefaultReactionEmoji(emoji: Types.DefaultReactionEmoji, allocator: std.mem.Allocator) void {
    if (emoji.emoji_name) |value| allocator.free(value);
}

fn deinitForumTags(tags: []const Types.ForumTag, allocator: std.mem.Allocator) void {
    for (tags) |tag| {
        allocator.free(tag.name);
        if (tag.emoji_name) |value| allocator.free(value);
    }
    allocator.free(@constCast(tags));
}

fn deinitThreadMetadata(metadata: Types.ThreadMetadata, allocator: std.mem.Allocator) void {
    if (metadata.archive_timestamp) |value| allocator.free(value);
    if (metadata.create_timestamp) |value| allocator.free(value);
}

fn copyEmbeds(allocator: std.mem.Allocator, embeds: []const Types.Embed) ![]Types.Embed {
    const owned = try allocator.alloc(Types.Embed, embeds.len);
    var initialized: usize = 0;
    errdefer deinitEmbeds(owned[0..initialized], allocator);

    for (embeds, 0..) |embed, index| {
        owned[index] = try copyEmbed(allocator, embed);
        initialized += 1;
    }
    return owned;
}

fn copyEmbed(allocator: std.mem.Allocator, embed: Types.Embed) !Types.Embed {
    const title = if (embed.title) |value| try allocator.dupe(u8, value) else null;
    errdefer if (title) |value| allocator.free(value);
    const description = if (embed.description) |value| try allocator.dupe(u8, value) else null;
    errdefer if (description) |value| allocator.free(value);
    const url = if (embed.url) |value| try allocator.dupe(u8, value) else null;
    errdefer if (url) |value| allocator.free(value);
    const timestamp = if (embed.timestamp) |value| try allocator.dupe(u8, value) else null;
    errdefer if (timestamp) |value| allocator.free(value);
    const footer = if (embed.footer) |value| try copyEmbedFooter(allocator, value) else null;
    errdefer if (footer) |value| deinitEmbedFooter(value, allocator);
    const image = if (embed.image) |value| try copyEmbedMedia(allocator, value) else null;
    errdefer if (image) |value| deinitEmbedMedia(value, allocator);
    const thumbnail = if (embed.thumbnail) |value| try copyEmbedMedia(allocator, value) else null;
    errdefer if (thumbnail) |value| deinitEmbedMedia(value, allocator);
    const author = if (embed.author) |value| try copyEmbedAuthor(allocator, value) else null;
    errdefer if (author) |value| deinitEmbedAuthor(value, allocator);
    const fields = try copyEmbedFields(allocator, embed.fields);

    return .{
        .title = title,
        .description = description,
        .url = url,
        .timestamp = timestamp,
        .color = embed.color,
        .footer = footer,
        .image = image,
        .thumbnail = thumbnail,
        .author = author,
        .fields = fields,
    };
}

fn copyEmbedFooter(allocator: std.mem.Allocator, footer: Types.EmbedFooter) !Types.EmbedFooter {
    const text = try allocator.dupe(u8, footer.text);
    errdefer allocator.free(text);
    const icon_url = if (footer.icon_url) |value| try allocator.dupe(u8, value) else null;
    return .{ .text = text, .icon_url = icon_url };
}

fn copyEmbedMedia(allocator: std.mem.Allocator, media: Types.EmbedMedia) !Types.EmbedMedia {
    return .{ .url = try allocator.dupe(u8, media.url) };
}

fn copyEmbedAuthor(allocator: std.mem.Allocator, author: Types.EmbedAuthor) !Types.EmbedAuthor {
    const name = try allocator.dupe(u8, author.name);
    errdefer allocator.free(name);
    const url = if (author.url) |value| try allocator.dupe(u8, value) else null;
    errdefer if (url) |value| allocator.free(value);
    const icon_url = if (author.icon_url) |value| try allocator.dupe(u8, value) else null;
    return .{ .name = name, .url = url, .icon_url = icon_url };
}

fn copyEmbedFields(allocator: std.mem.Allocator, fields: []const Types.EmbedField) ![]Types.EmbedField {
    const owned = try allocator.alloc(Types.EmbedField, fields.len);
    var initialized: usize = 0;
    errdefer {
        for (owned[0..initialized]) |field| deinitEmbedField(field, allocator);
        allocator.free(owned);
    }

    for (fields, 0..) |field, index| {
        const name = try allocator.dupe(u8, field.name);
        errdefer allocator.free(name);
        const value = try allocator.dupe(u8, field.value);
        owned[index] = .{
            .name = name,
            .value = value,
            .is_inline = field.is_inline,
        };
        initialized += 1;
    }
    return owned;
}

fn deinitEmbeds(embeds: []Types.Embed, allocator: std.mem.Allocator) void {
    for (embeds) |embed| deinitEmbed(embed, allocator);
    allocator.free(embeds);
}

fn deinitEmbed(embed: Types.Embed, allocator: std.mem.Allocator) void {
    if (embed.title) |value| allocator.free(value);
    if (embed.description) |value| allocator.free(value);
    if (embed.url) |value| allocator.free(value);
    if (embed.timestamp) |value| allocator.free(value);
    if (embed.footer) |value| deinitEmbedFooter(value, allocator);
    if (embed.image) |value| deinitEmbedMedia(value, allocator);
    if (embed.thumbnail) |value| deinitEmbedMedia(value, allocator);
    if (embed.author) |value| deinitEmbedAuthor(value, allocator);
    for (embed.fields) |field| deinitEmbedField(field, allocator);
    allocator.free(embed.fields);
}

fn deinitEmbedFooter(footer: Types.EmbedFooter, allocator: std.mem.Allocator) void {
    allocator.free(footer.text);
    if (footer.icon_url) |value| allocator.free(value);
}

fn deinitEmbedMedia(media: Types.EmbedMedia, allocator: std.mem.Allocator) void {
    allocator.free(media.url);
}

fn deinitEmbedAuthor(author: Types.EmbedAuthor, allocator: std.mem.Allocator) void {
    allocator.free(author.name);
    if (author.url) |value| allocator.free(value);
    if (author.icon_url) |value| allocator.free(value);
}

fn deinitEmbedField(field: Types.EmbedField, allocator: std.mem.Allocator) void {
    allocator.free(field.name);
    allocator.free(field.value);
}

fn copyReactions(allocator: std.mem.Allocator, reactions: []const Types.MessageReaction) ![]Types.MessageReaction {
    const owned = try allocator.alloc(Types.MessageReaction, reactions.len);
    var initialized: usize = 0;
    errdefer deinitReactions(owned[0..initialized], allocator);

    for (reactions, 0..) |reaction, index| {
        owned[index] = try copyReaction(allocator, reaction);
        initialized += 1;
    }
    return owned;
}

fn copyReaction(allocator: std.mem.Allocator, reaction: Types.MessageReaction) !Types.MessageReaction {
    const emoji = try copyReactionEmoji(allocator, reaction.emoji);
    errdefer deinitReactionEmoji(emoji, allocator);
    const burst_colors = try copyStringArray(allocator, reaction.burst_colors);
    return .{
        .emoji = emoji,
        .count = reaction.count,
        .count_details = reaction.count_details,
        .me = reaction.me,
        .me_burst = reaction.me_burst,
        .burst_colors = burst_colors,
    };
}

fn copyReactionEmoji(allocator: std.mem.Allocator, emoji: Types.ReactionEmoji) !Types.ReactionEmoji {
    return .{
        .id = emoji.id,
        .name = if (emoji.name) |value| try allocator.dupe(u8, value) else null,
        .animated = emoji.animated,
    };
}

fn deinitReactions(reactions: []Types.MessageReaction, allocator: std.mem.Allocator) void {
    for (reactions) |reaction| {
        deinitReactionEmoji(reaction.emoji, allocator);
        deinitConstStringArray(reaction.burst_colors, allocator);
    }
    allocator.free(reactions);
}

fn deinitReactionEmoji(emoji: Types.ReactionEmoji, allocator: std.mem.Allocator) void {
    if (emoji.name) |value| allocator.free(value);
}

fn incrementReaction(allocator: std.mem.Allocator, message: *OwnedMessage, emoji: Types.ReactionEmoji) !void {
    for (message.reactions) |*reaction| {
        if (reactionEmojiEql(reaction.emoji, emoji)) {
            reaction.count += 1;
            reaction.count_details.normal += 1;
            return;
        }
    }

    const reactions = try allocator.alloc(Types.MessageReaction, message.reactions.len + 1);
    @memcpy(reactions[0..message.reactions.len], message.reactions);
    errdefer allocator.free(reactions);
    const owned_emoji = try copyReactionEmoji(allocator, emoji);
    errdefer deinitReactionEmoji(owned_emoji, allocator);
    const burst_colors = try allocator.dupe([]const u8, &.{});
    reactions[message.reactions.len] = .{
        .emoji = owned_emoji,
        .count = 1,
        .count_details = .{ .normal = 1 },
        .burst_colors = burst_colors,
    };
    allocator.free(message.reactions);
    message.reactions = reactions;
}

fn decrementReaction(allocator: std.mem.Allocator, message: *OwnedMessage, emoji: Types.ReactionEmoji) !void {
    for (message.reactions, 0..) |*reaction, index| {
        if (!reactionEmojiEql(reaction.emoji, emoji)) continue;
        if (reaction.count > 1) {
            reaction.count -= 1;
            if (reaction.count_details.normal > 0) reaction.count_details.normal -= 1;
            return;
        }
        try removeReactionAt(allocator, message, index);
        return;
    }
}

fn removeReactionEmoji(allocator: std.mem.Allocator, message: *OwnedMessage, emoji: Types.ReactionEmoji) !void {
    for (message.reactions, 0..) |reaction, index| {
        if (reactionEmojiEql(reaction.emoji, emoji)) {
            try removeReactionAt(allocator, message, index);
            return;
        }
    }
}

fn removeReactionAt(allocator: std.mem.Allocator, message: *OwnedMessage, index: usize) !void {
    deinitReactionEmoji(message.reactions[index].emoji, allocator);
    deinitConstStringArray(message.reactions[index].burst_colors, allocator);
    if (message.reactions.len == 1) {
        allocator.free(message.reactions);
        message.reactions = try allocator.dupe(Types.MessageReaction, &.{});
        return;
    }

    const reactions = try allocator.alloc(Types.MessageReaction, message.reactions.len - 1);
    if (index > 0) @memcpy(reactions[0..index], message.reactions[0..index]);
    if (index + 1 < message.reactions.len) {
        @memcpy(reactions[index..], message.reactions[index + 1 ..]);
    }
    allocator.free(message.reactions);
    message.reactions = reactions;
}

fn reactionEmojiEql(a: Types.ReactionEmoji, b: Types.ReactionEmoji) bool {
    if (a.id != null or b.id != null) {
        return a.id != null and b.id != null and a.id.?.value == b.id.?.value;
    }
    if (a.name == null or b.name == null) return a.name == null and b.name == null;
    return std.mem.eql(u8, a.name.?, b.name.?);
}

fn memberKey(guild_id: Snowflake, user_id: Snowflake) u128 {
    return (@as(u128, guild_id.value) << 64) | @as(u128, user_id.value);
}

fn roleKey(guild_id: Snowflake, role_id: Snowflake) u128 {
    return (@as(u128, guild_id.value) << 64) | @as(u128, role_id.value);
}

fn replaceOwned(comptime T: type, map: anytype, allocator: std.mem.Allocator, key: anytype, value: T) !void {
    if (map.fetchRemove(key)) |old| old.value.deinit(allocator);
    try map.put(key, value);
}

fn clearOwnedMap(map: anytype, allocator: std.mem.Allocator) void {
    var values = map.valueIterator();
    while (values.next()) |value| value.deinit(allocator);
    map.deinit();
}

fn clearOwnedMapRetainingCapacity(map: anytype, allocator: std.mem.Allocator) void {
    var values = map.valueIterator();
    while (values.next()) |value| value.deinit(allocator);
    map.clearRetainingCapacity();
}

fn userFromJson(value: std.json.Value) !Types.User {
    const object = try requireObject(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .username = try stringField(object, "username"),
        .discriminator = if (object.get("discriminator")) |field| try stringValue(field) else null,
        .global_name = if (object.get("global_name")) |field| optionalStringValue(field) catch null else null,
        .avatar = if (object.get("avatar")) |field| optionalStringValue(field) catch null else null,
        .banner = if (object.get("banner")) |field| optionalStringValue(field) catch null else null,
        .bot = if (object.get("bot")) |field| boolValue(field) catch false else false,
        .system = if (object.get("system")) |field| boolValue(field) catch false else false,
        .mfa_enabled = if (object.get("mfa_enabled")) |field| try boolValue(field) else null,
        .accent_color = if (object.get("accent_color")) |field| try optionalU32Value(field) else null,
        .locale = if (object.get("locale")) |field| optionalStringValue(field) catch null else null,
        .verified = if (object.get("verified")) |field| try boolValue(field) else null,
        .email = if (object.get("email")) |field| optionalStringValue(field) catch null else null,
        .flags = if (object.get("flags")) |field| @intCast(try intValue(field)) else null,
        .public_flags = if (object.get("public_flags")) |field| @intCast(try intValue(field)) else null,
    };
}

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

fn applicationFromJson(allocator: std.mem.Allocator, value: std.json.Value) !Types.Application {
    const object = try requireObject(value);
    const event_webhooks_types = if (object.get("event_webhooks_types")) |field|
        try stringArrayFromJson(allocator, field)
    else
        try allocator.dupe([]const u8, &.{});
    errdefer allocator.free(event_webhooks_types);
    const tags = if (object.get("tags")) |field|
        try stringArrayFromJson(allocator, field)
    else
        try allocator.dupe([]const u8, &.{});
    errdefer allocator.free(tags);
    const team = if (object.get("team")) |field| try teamFromJson(allocator, field) else null;
    errdefer if (team) |parsed_team| deinitParsedTeam(parsed_team, allocator);

    return .{
        .id = try snowflakeField(object, "id"),
        .name = if (object.get("name")) |field| try stringValue(field) else "",
        .icon = if (object.get("icon")) |field| try optionalStringValue(field) else null,
        .description = if (object.get("description")) |field| try stringValue(field) else "",
        .bot_public = if (object.get("bot_public")) |field| try boolValue(field) else true,
        .bot_require_code_grant = if (object.get("bot_require_code_grant")) |field| try boolValue(field) else false,
        .bot = if (object.get("bot")) |field| try userFromJson(field) else null,
        .owner = if (object.get("owner")) |field| try userFromJson(field) else null,
        .team = team,
        .verify_key = if (object.get("verify_key")) |field| try stringValue(field) else "",
        .guild_id = if (object.get("guild_id")) |field| try nullableSnowflakeValue(field) else null,
        .flags = if (object.get("flags")) |field| @intCast(try intValue(field)) else null,
        .approximate_guild_count = if (object.get("approximate_guild_count")) |field| @intCast(try intValue(field)) else null,
        .approximate_user_install_count = if (object.get("approximate_user_install_count")) |field| @intCast(try intValue(field)) else null,
        .interactions_endpoint_url = if (object.get("interactions_endpoint_url")) |field| try optionalStringValue(field) else null,
        .role_connections_verification_url = if (object.get("role_connections_verification_url")) |field| try optionalStringValue(field) else null,
        .event_webhooks_url = if (object.get("event_webhooks_url")) |field| try optionalStringValue(field) else null,
        .event_webhooks_status = if (object.get("event_webhooks_status")) |field| try applicationEventWebhookStatusFromInt(try intValue(field)) else null,
        .event_webhooks_types = event_webhooks_types,
        .tags = tags,
        .custom_install_url = if (object.get("custom_install_url")) |field| try optionalStringValue(field) else null,
    };
}

fn deinitParsedApplication(application: ?Types.Application, allocator: std.mem.Allocator) void {
    if (application) |value| {
        allocator.free(value.event_webhooks_types);
        allocator.free(value.tags);
        if (value.team) |team| deinitParsedTeam(team, allocator);
    }
}

fn teamFromJson(allocator: std.mem.Allocator, value: std.json.Value) !?Types.Team {
    const object = switch (value) {
        .object => |inner| inner,
        .null => return null,
        else => return error.InvalidField,
    };
    const members = try teamMembersFromJson(allocator, object.get("members"));
    errdefer allocator.free(members);
    return .{
        .id = try snowflakeField(object, "id"),
        .name = if (object.get("name")) |field| try stringValue(field) else "",
        .icon = if (object.get("icon")) |field| try optionalStringValue(field) else null,
        .owner_user_id = try snowflakeField(object, "owner_user_id"),
        .members = members,
    };
}

fn teamMembersFromJson(allocator: std.mem.Allocator, maybe: ?std.json.Value) ![]Types.TeamMember {
    const field = maybe orelse return allocator.alloc(Types.TeamMember, 0);
    const array = switch (field) {
        .array => |items| items,
        else => return error.InvalidField,
    };
    const members = try allocator.alloc(Types.TeamMember, array.items.len);
    errdefer allocator.free(members);
    for (array.items, 0..) |item, index| {
        members[index] = try teamMemberFromJson(item);
    }
    return members;
}

fn teamMemberFromJson(value: std.json.Value) !Types.TeamMember {
    const object = try requireObject(value);
    const state = try membershipStateFromInt(try intValue(object.get("membership_state") orelse return error.MissingField));
    return .{
        .membership_state = state,
        .team_id = try snowflakeField(object, "team_id"),
        .user = try userFromJson(object.get("user") orelse return error.MissingField),
        .role = if (object.get("role")) |field| try optionalStringValue(field) else null,
    };
}

fn membershipStateFromInt(value: i64) !Types.MembershipState {
    return switch (value) {
        1 => .invited,
        2 => .accepted,
        else => error.InvalidField,
    };
}

fn deinitParsedTeam(team: Types.Team, allocator: std.mem.Allocator) void {
    allocator.free(team.members);
}

fn copyTeam(allocator: std.mem.Allocator, team: Types.Team) !Types.Team {
    const name = try allocator.dupe(u8, team.name);
    errdefer allocator.free(name);
    const icon = if (team.icon) |value| try allocator.dupe(u8, value) else null;
    errdefer if (icon) |value| allocator.free(value);
    const members = try allocator.alloc(Types.TeamMember, team.members.len);
    var initialized: usize = 0;
    errdefer {
        for (members[0..initialized]) |member| deinitTeamMember(member, allocator);
        allocator.free(members);
    }
    for (team.members, 0..) |member, index| {
        members[index] = try copyTeamMember(allocator, member);
        initialized += 1;
    }
    return .{
        .id = team.id,
        .name = name,
        .icon = icon,
        .owner_user_id = team.owner_user_id,
        .members = members,
    };
}

fn copyTeamMember(allocator: std.mem.Allocator, member: Types.TeamMember) !Types.TeamMember {
    const user = try copyUser(allocator, member.user);
    errdefer deinitUser(user, allocator);
    const role = if (member.role) |value| try allocator.dupe(u8, value) else null;
    return .{
        .membership_state = member.membership_state,
        .team_id = member.team_id,
        .user = user,
        .role = role,
    };
}

fn deinitTeam(team: Types.Team, allocator: std.mem.Allocator) void {
    allocator.free(team.name);
    if (team.icon) |value| allocator.free(value);
    for (team.members) |member| deinitTeamMember(member, allocator);
    allocator.free(team.members);
}

fn deinitTeamMember(member: Types.TeamMember, allocator: std.mem.Allocator) void {
    deinitUser(member.user, allocator);
    if (member.role) |value| allocator.free(value);
}

fn applicationEventWebhookStatusFromInt(value: i64) !Types.ApplicationEventWebhookStatus {
    return switch (value) {
        1 => .disabled,
        2 => .enabled,
        3 => .disabled_by_discord,
        else => error.InvalidField,
    };
}

fn channelFromJson(
    allocator: std.mem.Allocator,
    value: std.json.Value,
    fallback_guild_id: ?Snowflake,
) !Types.Channel {
    const object = try requireObject(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .type = try channelTypeFromInt(try intField(object, "type")),
        .guild_id = if (object.get("guild_id")) |guild_id| try snowflakeValue(guild_id) else fallback_guild_id,
        .name = if (object.get("name")) |name| try stringValue(name) else null,
        .topic = if (object.get("topic")) |topic| try optionalStringValue(topic) else null,
        .status = if (object.get("status")) |status| try optionalStringValue(status) else null,
        .voice_start_time = if (object.get("voice_start_time")) |field| try nullableIntValue(field) else null,
        .last_message_id = if (object.get("last_message_id")) |field| try nullableSnowflakeValue(field) else null,
        .last_pin_timestamp = if (object.get("last_pin_timestamp")) |field| try optionalStringValue(field) else null,
        .parent_id = if (object.get("parent_id")) |parent_id| try nullableSnowflakeValue(parent_id) else null,
        .owner_id = if (object.get("owner_id")) |field| try nullableSnowflakeValue(field) else null,
        .application_id = if (object.get("application_id")) |field| try nullableSnowflakeValue(field) else null,
        .position = if (object.get("position")) |position| @intCast(try intValue(position)) else null,
        .nsfw = if (object.get("nsfw")) |nsfw| try boolValue(nsfw) else false,
        .rate_limit_per_user = if (object.get("rate_limit_per_user")) |rate_limit| @intCast(try intValue(rate_limit)) else null,
        .bitrate = if (object.get("bitrate")) |bitrate| @intCast(try intValue(bitrate)) else null,
        .user_limit = if (object.get("user_limit")) |user_limit| @intCast(try intValue(user_limit)) else null,
        .rtc_region = if (object.get("rtc_region")) |field| try optionalStringValue(field) else null,
        .video_quality_mode = if (object.get("video_quality_mode")) |field| @intCast(try intValue(field)) else null,
        .message_count = if (object.get("message_count")) |field| @intCast(try intValue(field)) else null,
        .member_count = if (object.get("member_count")) |field| @intCast(try intValue(field)) else null,
        .managed = if (object.get("managed")) |field| try boolValue(field) else false,
        .flags = if (object.get("flags")) |flags| @intCast(try intValue(flags)) else null,
        .permission_overwrites = if (object.get("permission_overwrites")) |field| try permissionOverwriteArrayFromJson(allocator, field) else try allocator.dupe(Types.PermissionOverwrite, &.{}),
        .thread_metadata = if (object.get("thread_metadata")) |thread_metadata| try threadMetadataFromJson(thread_metadata) else null,
        .applied_tags = if (object.get("applied_tags")) |applied_tags| try roleArrayFromJson(allocator, applied_tags) else try allocator.dupe(Snowflake, &.{}),
        .available_tags = if (object.get("available_tags")) |available_tags| try forumTagArrayFromJson(allocator, available_tags) else try allocator.dupe(Types.ForumTag, &.{}),
        .default_reaction_emoji = if (object.get("default_reaction_emoji")) |field| try nullableDefaultReactionEmojiFromJson(field) else null,
        .default_thread_rate_limit_per_user = if (object.get("default_thread_rate_limit_per_user")) |field| @intCast(try intValue(field)) else null,
        .default_sort_order = if (object.get("default_sort_order")) |field| try nullableChannelSortOrderFromJson(field) else null,
        .default_forum_layout = if (object.get("default_forum_layout")) |field| try nullableForumLayoutFromJson(field) else null,
    };
}

fn deinitParsedChannel(channel: Types.Channel, allocator: std.mem.Allocator) void {
    allocator.free(@constCast(channel.permission_overwrites));
    allocator.free(channel.applied_tags);
    deinitParsedForumTags(channel.available_tags, allocator);
}

fn deinitParsedChannels(channels: []Types.Channel, allocator: std.mem.Allocator) void {
    for (channels) |channel| deinitParsedChannel(channel, allocator);
    allocator.free(channels);
}

fn threadMetadataFromJson(value: std.json.Value) !Types.ThreadMetadata {
    const object = try requireObject(value);
    return .{
        .archived = if (object.get("archived")) |field| try boolValue(field) else false,
        .auto_archive_duration = if (object.get("auto_archive_duration")) |field| @intCast(try intValue(field)) else 0,
        .archive_timestamp = if (object.get("archive_timestamp")) |field| try optionalStringValue(field) else null,
        .locked = if (object.get("locked")) |field| try boolValue(field) else false,
        .invitable = if (object.get("invitable")) |field| try boolValue(field) else null,
        .create_timestamp = if (object.get("create_timestamp")) |field| try optionalStringValue(field) else null,
    };
}

fn permissionOverwriteArrayFromJson(
    allocator: std.mem.Allocator,
    value: std.json.Value,
) ![]Types.PermissionOverwrite {
    const array = try requireArray(value);
    const overwrites = try allocator.alloc(Types.PermissionOverwrite, array.items.len);
    errdefer allocator.free(overwrites);

    for (array.items, 0..) |item, index| overwrites[index] = try permissionOverwriteFromJson(item);
    return overwrites;
}

fn permissionOverwriteFromJson(value: std.json.Value) !Types.PermissionOverwrite {
    const object = try requireObject(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .type = try permissionOverwriteTypeFromInt(try intField(object, "type")),
        .allow = if (object.get("allow")) |field| try permissionsValue(field) else 0,
        .deny = if (object.get("deny")) |field| try permissionsValue(field) else 0,
    };
}

fn forumTagArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) ![]Types.ForumTag {
    const array = try requireArray(value);
    const tags = try allocator.alloc(Types.ForumTag, array.items.len);
    var initialized: usize = 0;
    errdefer deinitParsedForumTags(tags[0..initialized], allocator);

    for (array.items, 0..) |item, index| {
        tags[index] = try forumTagFromJson(item);
        initialized += 1;
    }
    return tags;
}

fn forumTagFromJson(value: std.json.Value) !Types.ForumTag {
    const object = try requireObject(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .name = try stringField(object, "name"),
        .moderated = if (object.get("moderated")) |field| try boolValue(field) else false,
        .emoji_id = if (object.get("emoji_id")) |field| try nullableSnowflakeValue(field) else null,
        .emoji_name = if (object.get("emoji_name")) |field| try optionalStringValue(field) else null,
    };
}

fn nullableDefaultReactionEmojiFromJson(value: std.json.Value) !?Types.DefaultReactionEmoji {
    if (value == .null) return null;
    const object = try requireObject(value);
    return .{
        .emoji_id = if (object.get("emoji_id")) |field| try nullableSnowflakeValue(field) else null,
        .emoji_name = if (object.get("emoji_name")) |field| try optionalStringValue(field) else null,
    };
}

fn nullableChannelSortOrderFromJson(value: std.json.Value) !?Types.ChannelSortOrder {
    if (value == .null) return null;
    return switch (try intValue(value)) {
        0 => .latest_activity,
        1 => .creation_date,
        else => error.InvalidField,
    };
}

fn nullableForumLayoutFromJson(value: std.json.Value) !?Types.ForumLayout {
    if (value == .null) return null;
    return switch (try intValue(value)) {
        0 => .unset,
        1 => .list_view,
        2 => .gallery_view,
        else => error.InvalidField,
    };
}

fn permissionOverwriteTypeFromInt(value: i64) !Types.PermissionOverwriteType {
    return switch (value) {
        0 => .role,
        1 => .member,
        else => error.InvalidField,
    };
}

fn deinitParsedForumTags(tags: []const Types.ForumTag, allocator: std.mem.Allocator) void {
    allocator.free(@constCast(tags));
}

fn channelTypeFromInt(value: i64) !Types.ChannelType {
    return switch (value) {
        0 => .guild_text,
        1 => .dm,
        2 => .guild_voice,
        3 => .group_dm,
        4 => .guild_category,
        5 => .guild_announcement,
        10 => .announcement_thread,
        11 => .public_thread,
        12 => .private_thread,
        13 => .guild_stage_voice,
        14 => .guild_directory,
        15 => .guild_forum,
        16 => .guild_media,
        else => error.InvalidField,
    };
}

fn channelTypeIsThread(channel_type: Types.ChannelType) bool {
    return switch (channel_type) {
        .announcement_thread, .public_thread, .private_thread => true,
        else => false,
    };
}

fn roleFromJson(value: std.json.Value) !Types.Role {
    const object = try requireObject(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .name = try stringField(object, "name"),
        .color = if (object.get("color")) |color| @intCast(try intValue(color)) else 0,
        .colors = if (object.get("colors")) |colors| try roleColorsFromJson(colors) else null,
        .hoist = if (object.get("hoist")) |hoist| try boolValue(hoist) else false,
        .icon = if (object.get("icon")) |icon| try optionalStringValue(icon) else null,
        .unicode_emoji = if (object.get("unicode_emoji")) |unicode_emoji| try optionalStringValue(unicode_emoji) else null,
        .position = if (object.get("position")) |position| @intCast(try intValue(position)) else 0,
        .permissions = if (object.get("permissions")) |permissions| try permissionsValue(permissions) else 0,
        .managed = if (object.get("managed")) |managed| try boolValue(managed) else false,
        .mentionable = if (object.get("mentionable")) |mentionable| try boolValue(mentionable) else false,
        .tags = if (object.get("tags")) |tags| try roleTagsFromJson(tags) else null,
        .flags = if (object.get("flags")) |flags| @intCast(try intValue(flags)) else null,
    };
}

fn roleColorsFromJson(value: std.json.Value) !Types.RoleColors {
    const object = try requireObject(value);
    return .{
        .primary_color = @intCast(try intField(object, "primary_color")),
        .secondary_color = if (object.get("secondary_color")) |field| try nullableU24Value(field) else null,
        .tertiary_color = if (object.get("tertiary_color")) |field| try nullableU24Value(field) else null,
    };
}

fn roleTagsFromJson(value: std.json.Value) !Types.RoleTags {
    const object = try requireObject(value);
    return .{
        .bot_id = if (object.get("bot_id")) |field| try nullableSnowflakeValue(field) else null,
        .integration_id = if (object.get("integration_id")) |field| try nullableSnowflakeValue(field) else null,
        .premium_subscriber = object.get("premium_subscriber") != null,
        .subscription_listing_id = if (object.get("subscription_listing_id")) |field| try nullableSnowflakeValue(field) else null,
        .available_for_purchase = object.get("available_for_purchase") != null,
        .guild_connections = object.get("guild_connections") != null,
    };
}

fn emojiFromJson(allocator: std.mem.Allocator, value: std.json.Value) !Types.Emoji {
    const object = try requireObject(value);
    const roles = if (object.get("roles")) |role_values| try roleArrayFromJson(allocator, role_values) else try allocator.dupe(Snowflake, &.{});
    errdefer allocator.free(roles);
    return .{
        .id = if (object.get("id")) |id| try nullableSnowflakeValue(id) else null,
        .name = if (object.get("name")) |name| try optionalStringValue(name) else null,
        .roles = roles,
        .user = if (object.get("user")) |user| try userFromJson(user) else null,
        .require_colons = if (object.get("require_colons")) |field| try boolValue(field) else false,
        .managed = if (object.get("managed")) |field| try boolValue(field) else false,
        .animated = if (object.get("animated")) |field| try boolValue(field) else false,
        .available = if (object.get("available")) |field| try boolValue(field) else true,
    };
}

fn stickerFromJson(value: std.json.Value, fallback_guild_id: Snowflake) !Types.Sticker {
    return stickerFromJsonOptionalFallback(value, fallback_guild_id);
}

fn stickerFromJsonOptionalFallback(value: std.json.Value, fallback_guild_id: ?Snowflake) !Types.Sticker {
    const object = try requireObject(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .pack_id = if (object.get("pack_id")) |pack_id| try nullableSnowflakeValue(pack_id) else null,
        .name = try stringField(object, "name"),
        .description = if (object.get("description")) |description| try optionalStringValue(description) else null,
        .tags = try stringField(object, "tags"),
        .type = try stickerTypeFromInt(try intField(object, "type")),
        .format_type = try stickerFormatTypeFromInt(try intField(object, "format_type")),
        .available = if (object.get("available")) |available| try boolValue(available) else true,
        .guild_id = if (object.get("guild_id")) |guild_id| try nullableSnowflakeValue(guild_id) else fallback_guild_id,
        .user = if (object.get("user")) |user| try userFromJson(user) else null,
        .sort_value = if (object.get("sort_value")) |sort_value| @intCast(try intValue(sort_value)) else null,
    };
}

fn stickerArrayFromJson(
    allocator: std.mem.Allocator,
    value: std.json.Value,
    fallback_guild_id: ?Snowflake,
) ![]Types.Sticker {
    const array = try requireArray(value);
    var stickers = std.array_list.Managed(Types.Sticker).init(allocator);
    errdefer stickers.deinit();
    for (array.items) |item| try stickers.append(try stickerFromJsonOptionalFallback(item, fallback_guild_id));
    return stickers.toOwnedSlice();
}

fn stickerTypeFromInt(value: i64) !Types.StickerType {
    return switch (value) {
        1 => .standard,
        2 => .guild,
        else => error.InvalidField,
    };
}

fn stickerFormatTypeFromInt(value: i64) !Types.StickerFormatType {
    return switch (value) {
        1 => .png,
        2 => .apng,
        3 => .lottie,
        4 => .gif,
        else => error.InvalidField,
    };
}

fn scheduledEventFromJson(value: std.json.Value) !Types.GuildScheduledEvent {
    const object = try requireObject(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .guild_id = try snowflakeField(object, "guild_id"),
        .channel_id = if (object.get("channel_id")) |channel_id| try nullableSnowflakeValue(channel_id) else null,
        .creator_id = if (object.get("creator_id")) |creator_id| try nullableSnowflakeValue(creator_id) else null,
        .name = try stringField(object, "name"),
        .description = if (object.get("description")) |description| try optionalStringValue(description) else null,
        .scheduled_start_time = try stringField(object, "scheduled_start_time"),
        .scheduled_end_time = if (object.get("scheduled_end_time")) |scheduled_end_time| try optionalStringValue(scheduled_end_time) else null,
        .privacy_level = try scheduledEventPrivacyLevelFromInt(try intField(object, "privacy_level")),
        .status = try scheduledEventStatusFromInt(try intField(object, "status")),
        .entity_type = try scheduledEventEntityTypeFromInt(try intField(object, "entity_type")),
        .entity_id = if (object.get("entity_id")) |entity_id| try nullableSnowflakeValue(entity_id) else null,
        .user_count = if (object.get("user_count")) |user_count| @intCast(try intValue(user_count)) else null,
    };
}

fn scheduledEventPrivacyLevelFromInt(value: i64) !Types.GuildScheduledEventPrivacyLevel {
    return switch (value) {
        2 => .guild_only,
        else => error.InvalidField,
    };
}

fn scheduledEventEntityTypeFromInt(value: i64) !Types.GuildScheduledEventEntityType {
    return switch (value) {
        1 => .stage_instance,
        2 => .voice,
        3 => .external,
        else => error.InvalidField,
    };
}

fn scheduledEventStatusFromInt(value: i64) !Types.GuildScheduledEventStatus {
    return switch (value) {
        1 => .scheduled,
        2 => .active,
        3 => .completed,
        4 => .canceled,
        else => error.InvalidField,
    };
}

fn stageInstanceFromJson(value: std.json.Value) !Types.StageInstance {
    const object = try requireObject(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .guild_id = try snowflakeField(object, "guild_id"),
        .channel_id = try snowflakeField(object, "channel_id"),
        .topic = try stringField(object, "topic"),
        .privacy_level = if (object.get("privacy_level")) |privacy_level| try stageInstancePrivacyLevelFromInt(try intValue(privacy_level)) else .guild_only,
        .discoverable_disabled = if (object.get("discoverable_disabled")) |disabled| try boolValue(disabled) else false,
        .guild_scheduled_event_id = if (object.get("guild_scheduled_event_id")) |event_id| try nullableSnowflakeValue(event_id) else null,
    };
}

fn stageInstancePrivacyLevelFromInt(value: i64) !Types.StageInstancePrivacyLevel {
    return switch (value) {
        1 => .public,
        2 => .guild_only,
        else => error.InvalidField,
    };
}

fn inviteFromJson(value: std.json.Value) !Types.Invite {
    const object = try requireObject(value);
    return .{
        .code = try stringField(object, "code"),
        .type = if (object.get("type")) |field| try optionalU8Value(field) else null,
        .guild_id = if (object.get("guild_id")) |guild_id| try nullableSnowflakeValue(guild_id) else null,
        .channel_id = if (object.get("channel_id")) |channel_id| try nullableSnowflakeValue(channel_id) else null,
        .inviter_id = try nestedIdValue(object, "inviter"),
        .target_type = if (object.get("target_type")) |field| try optionalU8Value(field) else null,
        .target_user_id = try nestedIdValue(object, "target_user"),
        .target_application_id = try nestedIdValue(object, "target_application"),
        .approximate_presence_count = if (object.get("approximate_presence_count")) |field| try optionalU32Value(field) else null,
        .approximate_member_count = if (object.get("approximate_member_count")) |field| try optionalU32Value(field) else null,
        .expires_at = if (object.get("expires_at")) |field| try optionalStringValue(field) else null,
        .uses = if (object.get("uses")) |field| try optionalU32Value(field) else null,
        .max_uses = if (object.get("max_uses")) |field| try optionalU32Value(field) else null,
        .max_age = if (object.get("max_age")) |field| try optionalU32Value(field) else null,
        .temporary = if (object.get("temporary")) |field| try optionalBoolValue(field) else null,
        .created_at = if (object.get("created_at")) |field| try optionalStringValue(field) else null,
        .guild_scheduled_event_id = if (object.get("guild_scheduled_event_id")) |field| try nullableSnowflakeValue(field) else null,
    };
}

fn presenceFromJson(value: std.json.Value) !Types.Presence {
    const object = try requireObject(value);
    const user = try requireObject(object.get("user") orelse return error.MissingField);
    const activities_count = if (object.get("activities")) |activities| (try requireArray(activities)).items.len else 0;
    return .{
        .guild_id = try snowflakeField(object, "guild_id"),
        .user_id = try snowflakeField(user, "id"),
        .status = try stringField(object, "status"),
        .activities_count = activities_count,
    };
}

fn voiceStateFromJson(value: std.json.Value) !Types.VoiceState {
    const object = try requireObject(value);
    return .{
        .guild_id = try snowflakeField(object, "guild_id"),
        .channel_id = if (object.get("channel_id")) |channel_id| try nullableSnowflakeValue(channel_id) else null,
        .user_id = try snowflakeField(object, "user_id"),
        .session_id = try stringField(object, "session_id"),
        .deaf = if (object.get("deaf")) |deaf| try boolValue(deaf) else false,
        .mute = if (object.get("mute")) |mute| try boolValue(mute) else false,
        .self_deaf = if (object.get("self_deaf")) |self_deaf| try boolValue(self_deaf) else false,
        .self_mute = if (object.get("self_mute")) |self_mute| try boolValue(self_mute) else false,
        .self_stream = if (object.get("self_stream")) |self_stream| try boolValue(self_stream) else null,
        .self_video = if (object.get("self_video")) |self_video| try boolValue(self_video) else false,
        .suppress = if (object.get("suppress")) |suppress| try boolValue(suppress) else false,
        .request_to_speak_timestamp = if (object.get("request_to_speak_timestamp")) |timestamp| try optionalStringValue(timestamp) else null,
    };
}

fn messageReferenceFromJson(value: std.json.Value) !Types.MessageReferenceInfo {
    const object = try requireObject(value);
    return .{
        .type = if (object.get("type")) |field| try messageReferenceTypeFromInt(try intValue(field)) else null,
        .message_id = if (object.get("message_id")) |field| try nullableSnowflakeValue(field) else null,
        .channel_id = if (object.get("channel_id")) |field| try nullableSnowflakeValue(field) else null,
        .guild_id = if (object.get("guild_id")) |field| try nullableSnowflakeValue(field) else null,
    };
}

fn messageReferenceTypeFromInt(value: i64) !Types.MessageReferenceType {
    return switch (value) {
        0 => .default,
        1 => .forward,
        else => error.InvalidField,
    };
}

fn referencedMessageIdFromJson(value: std.json.Value) !?Snowflake {
    if (value == .null) return null;
    const object = try requireObject(value);
    return try snowflakeField(object, "id");
}

fn messageSnapshotArrayFromJson(
    allocator: std.mem.Allocator,
    value: std.json.Value,
) ![]Types.MessageSnapshot {
    const array = try requireArray(value);
    const snapshots = try allocator.alloc(Types.MessageSnapshot, array.items.len);
    var initialized: usize = 0;
    errdefer deinitParsedMessageSnapshots(snapshots[0..initialized], allocator);

    for (array.items, 0..) |item, index| {
        snapshots[index] = try messageSnapshotFromJson(allocator, item);
        initialized += 1;
    }
    return snapshots;
}

fn messageSnapshotFromJson(
    allocator: std.mem.Allocator,
    value: std.json.Value,
) !Types.MessageSnapshot {
    const object = try requireObject(value);
    const message = try requireObject(object.get("message") orelse return error.MissingField);
    const mentions = if (message.get("mentions")) |field| try userArrayFromJson(allocator, field) else try allocator.dupe(Types.User, &.{});
    errdefer allocator.free(mentions);
    const mention_roles = if (message.get("mention_roles")) |field| try roleArrayFromJson(allocator, field) else try allocator.dupe(Snowflake, &.{});
    errdefer allocator.free(mention_roles);
    const embeds = if (message.get("embeds")) |field| try embedArrayFromJson(allocator, field) else try allocator.dupe(Types.Embed, &.{});
    errdefer deinitParsedEmbeds(embeds, allocator);
    const attachments = if (message.get("attachments")) |field| try attachmentArrayFromJson(allocator, field) else try allocator.dupe(Types.Attachment, &.{});
    errdefer allocator.free(attachments);
    const components = if (message.get("components")) |field| try componentArrayFromJson(allocator, field) else try allocator.dupe(Interactions.Component, &.{});
    errdefer deinitParsedComponentArray(components, allocator);

    return .{
        .type = if (message.get("type")) |field| @intCast(try intValue(field)) else 0,
        .content = if (message.get("content")) |field| try stringValue(field) else "",
        .timestamp = if (message.get("timestamp")) |field| try stringValue(field) else null,
        .edited_timestamp = if (message.get("edited_timestamp")) |field| try optionalStringValue(field) else null,
        .flags = if (message.get("flags")) |field| @intCast(try intValue(field)) else null,
        .mentions = mentions,
        .mention_roles = mention_roles,
        .embeds = embeds,
        .attachments = attachments,
        .components = components,
    };
}

fn deinitParsedMessageSnapshots(
    snapshots: []Types.MessageSnapshot,
    allocator: std.mem.Allocator,
) void {
    for (snapshots) |snapshot| {
        allocator.free(snapshot.mentions);
        allocator.free(snapshot.mention_roles);
        deinitParsedEmbeds(@constCast(snapshot.embeds), allocator);
        allocator.free(snapshot.attachments);
        deinitParsedComponentArray(@constCast(snapshot.components), allocator);
    }
    allocator.free(snapshots);
}

fn memberFromJson(allocator: std.mem.Allocator, value: std.json.Value) !Types.GuildMember {
    const object = try requireObject(value);
    const roles = if (object.get("roles")) |role_values| try roleArrayFromJson(allocator, role_values) else try allocator.dupe(Snowflake, &.{});
    errdefer allocator.free(roles);
    return .{
        .user = if (object.get("user")) |user| try userFromJson(user) else null,
        .nick = if (object.get("nick")) |nick| try optionalStringValue(nick) else null,
        .avatar = if (object.get("avatar")) |avatar| try optionalStringValue(avatar) else null,
        .roles = roles,
        .joined_at = if (object.get("joined_at")) |joined_at| try optionalStringValue(joined_at) else null,
        .premium_since = if (object.get("premium_since")) |premium_since| try optionalStringValue(premium_since) else null,
        .deaf = if (object.get("deaf")) |deaf| try boolValue(deaf) else false,
        .mute = if (object.get("mute")) |mute| try boolValue(mute) else false,
        .pending = if (object.get("pending")) |pending| try boolValue(pending) else false,
        .communication_disabled_until = if (object.get("communication_disabled_until")) |timeout| try optionalStringValue(timeout) else null,
        .flags = if (object.get("flags")) |flags| @intCast(try intValue(flags)) else 0,
        .permissions = if (object.get("permissions")) |permissions| try permissionsValue(permissions) else 0,
    };
}

fn roleArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) ![]const Snowflake {
    const array = try requireArray(value);
    var roles = std.array_list.Managed(Snowflake).init(allocator);
    errdefer roles.deinit();
    for (array.items) |item| try roles.append(try snowflakeValue(item));
    return roles.toOwnedSlice();
}

fn userArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) ![]Types.User {
    const array = try requireArray(value);
    var users = std.array_list.Managed(Types.User).init(allocator);
    errdefer users.deinit();
    for (array.items) |item| try users.append(try userFromJson(item));
    return users.toOwnedSlice();
}

fn channelArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value, fallback_guild_id: ?Snowflake) ![]Types.Channel {
    const array = try requireArray(value);
    var channels = std.array_list.Managed(Types.Channel).init(allocator);
    errdefer {
        for (channels.items) |channel| deinitParsedChannel(channel, allocator);
        channels.deinit();
    }
    for (array.items) |item| try channels.append(try channelFromJson(allocator, item, fallback_guild_id));
    return channels.toOwnedSlice();
}

fn stringArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) ![]const []const u8 {
    const array = try requireArray(value);
    var strings = std.array_list.Managed([]const u8).init(allocator);
    errdefer strings.deinit();
    for (array.items) |item| try strings.append(try stringValue(item));
    return strings.toOwnedSlice();
}

fn copyStringArray(allocator: std.mem.Allocator, values: []const []const u8) ![][]u8 {
    const owned = try allocator.alloc([]u8, values.len);
    var initialized: usize = 0;
    errdefer deinitStringArray(owned[0..initialized], allocator);

    for (values, 0..) |value, index| {
        owned[index] = try allocator.dupe(u8, value);
        initialized += 1;
    }
    return owned;
}

fn deinitStringArray(values: [][]u8, allocator: std.mem.Allocator) void {
    for (values) |value| allocator.free(value);
    allocator.free(values);
}

fn deinitConstStringArray(values: []const []const u8, allocator: std.mem.Allocator) void {
    for (values) |value| allocator.free(value);
    allocator.free(values);
}

fn attachmentArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) ![]Types.Attachment {
    const array = try requireArray(value);
    var attachments = std.array_list.Managed(Types.Attachment).init(allocator);
    errdefer attachments.deinit();
    for (array.items) |item| try attachments.append(try attachmentFromJson(item));
    return attachments.toOwnedSlice();
}

fn messageStickerItemArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) ![]Types.MessageStickerItem {
    const array = try requireArray(value);
    var sticker_items = std.array_list.Managed(Types.MessageStickerItem).init(allocator);
    errdefer sticker_items.deinit();
    for (array.items) |item| try sticker_items.append(try messageStickerItemFromJson(item));
    return sticker_items.toOwnedSlice();
}

fn messageStickerItemFromJson(value: std.json.Value) !Types.MessageStickerItem {
    const object = try requireObject(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .name = try stringField(object, "name"),
        .format_type = try stickerFormatTypeFromInt(try intField(object, "format_type")),
    };
}

fn componentArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) anyerror![]Interactions.Component {
    const array = try requireArray(value);
    var components = std.array_list.Managed(Interactions.Component).init(allocator);
    errdefer {
        deinitParsedComponents(components.items, allocator);
        components.deinit();
    }

    for (array.items) |item| {
        if (try componentFromJson(allocator, item)) |component| try components.append(component);
    }
    return components.toOwnedSlice();
}

fn componentFromJson(allocator: std.mem.Allocator, value: std.json.Value) anyerror!?Interactions.Component {
    const object = try requireObject(value);
    const component_type = try intField(object, "type");
    return switch (component_type) {
        1 => .{ .action_row = try componentArrayFromJson(allocator, object.get("components") orelse return error.MissingField) },
        2 => .{ .button = try buttonFromJson(object) },
        3 => .{ .string_select = try stringSelectFromJson(allocator, object) },
        5 => .{ .user_select = try autoSelectFromJson(allocator, object, .user_select) },
        6 => .{ .role_select = try autoSelectFromJson(allocator, object, .role_select) },
        7 => .{ .mentionable_select = try autoSelectFromJson(allocator, object, .mentionable_select) },
        8 => .{ .channel_select = try autoSelectFromJson(allocator, object, .channel_select) },
        else => null,
    };
}

fn buttonFromJson(object: std.json.ObjectMap) !Interactions.Button {
    return .{
        .custom_id = if (object.get("custom_id")) |field| try optionalStringValue(field) else null,
        .label = if (object.get("label")) |field| try optionalStringValue(field) else null,
        .style = try buttonStyleFromInt(if (object.get("style")) |field| try intValue(field) else 1),
        .url = if (object.get("url")) |field| try optionalStringValue(field) else null,
        .disabled = if (object.get("disabled")) |field| try boolValue(field) else false,
    };
}

fn stringSelectFromJson(allocator: std.mem.Allocator, object: std.json.ObjectMap) !Interactions.StringSelect {
    return .{
        .custom_id = try stringField(object, "custom_id"),
        .options = if (object.get("options")) |field| try selectOptionArrayFromJson(allocator, field) else &.{},
        .placeholder = if (object.get("placeholder")) |field| try optionalStringValue(field) else null,
        .min_values = if (object.get("min_values")) |field| @intCast(try intValue(field)) else null,
        .max_values = if (object.get("max_values")) |field| @intCast(try intValue(field)) else null,
        .disabled = if (object.get("disabled")) |field| try boolValue(field) else false,
    };
}

fn autoSelectFromJson(
    allocator: std.mem.Allocator,
    object: std.json.ObjectMap,
    component_type: Interactions.ComponentType,
) !Interactions.AutoSelect {
    return .{
        .type = component_type,
        .custom_id = try stringField(object, "custom_id"),
        .placeholder = if (object.get("placeholder")) |field| try optionalStringValue(field) else null,
        .min_values = if (object.get("min_values")) |field| @intCast(try intValue(field)) else null,
        .max_values = if (object.get("max_values")) |field| @intCast(try intValue(field)) else null,
        .disabled = if (object.get("disabled")) |field| try boolValue(field) else false,
        .channel_types = if (object.get("channel_types")) |field| try u8ArrayFromJson(allocator, field) else &.{},
    };
}

fn u8ArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) ![]u8 {
    const array = try requireArray(value);
    var values = std.array_list.Managed(u8).init(allocator);
    errdefer values.deinit();
    for (array.items) |item| try values.append(@intCast(try intValue(item)));
    return values.toOwnedSlice();
}

fn selectOptionArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) ![]Interactions.SelectOption {
    const array = try requireArray(value);
    var options = std.array_list.Managed(Interactions.SelectOption).init(allocator);
    errdefer options.deinit();
    for (array.items) |item| try options.append(try selectOptionFromJson(item));
    return options.toOwnedSlice();
}

fn selectOptionFromJson(value: std.json.Value) !Interactions.SelectOption {
    const object = try requireObject(value);
    return .{
        .label = try stringField(object, "label"),
        .value = try stringField(object, "value"),
        .description = if (object.get("description")) |field| try optionalStringValue(field) else null,
        .default = if (object.get("default")) |field| try boolValue(field) else false,
    };
}

fn deinitParsedComponents(components: []Interactions.Component, allocator: std.mem.Allocator) void {
    for (components) |component| {
        switch (component) {
            .action_row => |children| {
                deinitParsedComponents(@constCast(children), allocator);
                allocator.free(@constCast(children));
            },
            .string_select => |select| if (select.options.len != 0) allocator.free(select.options),
            .channel_select => |select| if (select.channel_types.len != 0) allocator.free(select.channel_types),
            else => {},
        }
    }
}

fn deinitParsedComponentArray(components: []Interactions.Component, allocator: std.mem.Allocator) void {
    deinitParsedComponents(components, allocator);
    allocator.free(components);
}

fn buttonStyleFromInt(value: i64) !Interactions.ButtonStyle {
    return switch (value) {
        1 => .primary,
        2 => .secondary,
        3 => .success,
        4 => .danger,
        5 => .link,
        else => error.InvalidField,
    };
}

fn messagePollFromJson(allocator: std.mem.Allocator, value: std.json.Value) !?Types.MessagePoll {
    if (value == .null) return null;
    const object = try requireObject(value);
    const answers = if (object.get("answers")) |field| try messagePollAnswerArrayFromJson(allocator, field) else try allocator.dupe(Types.MessagePollAnswer, &.{});
    errdefer allocator.free(answers);
    const results = if (object.get("results")) |field| try messagePollResultsFromJson(allocator, field) else null;
    errdefer if (results) |field| allocator.free(field.answer_counts);

    return .{
        .question = try messagePollMediaFromJson(object.get("question") orelse return error.MissingField),
        .answers = answers,
        .expiry = if (object.get("expiry")) |field| try optionalStringValue(field) else null,
        .allow_multiselect = if (object.get("allow_multiselect")) |field| try boolValue(field) else false,
        .layout_type = if (object.get("layout_type")) |field| try optionalU8Value(field) else null,
        .results = results,
    };
}

fn messageInteractionMetadataFromJson(value: std.json.Value) !Types.MessageInteractionMetadata {
    const object = try requireObject(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .type = try interactionTypeFromInt(try intField(object, "type")),
        .user = try userFromJson(object.get("user") orelse return error.MissingField),
        .original_response_message_id = if (object.get("original_response_message_id")) |field| try nullableSnowflakeValue(field) else null,
        .interacted_message_id = if (object.get("interacted_message_id")) |field| try nullableSnowflakeValue(field) else null,
        .target_user = if (object.get("target_user")) |field| try userFromJson(field) else null,
        .target_message_id = if (object.get("target_message_id")) |field| try nullableSnowflakeValue(field) else null,
    };
}

fn messageCallFromJson(allocator: std.mem.Allocator, value: std.json.Value) !?Types.MessageCall {
    if (value == .null) return null;
    const object = try requireObject(value);
    return .{
        .participants = if (object.get("participants")) |field| try roleArrayFromJson(allocator, field) else try allocator.dupe(Snowflake, &.{}),
        .ended_timestamp = if (object.get("ended_timestamp")) |field| try optionalStringValue(field) else null,
    };
}

fn deinitParsedMessageCall(call: ?Types.MessageCall, allocator: std.mem.Allocator) void {
    if (call) |value| allocator.free(value.participants);
}

fn nullableRoleSubscriptionDataFromJson(value: std.json.Value) !?Types.RoleSubscriptionData {
    if (value == .null) return null;
    const object = try requireObject(value);
    return .{
        .role_subscription_listing_id = try snowflakeField(object, "role_subscription_listing_id"),
        .tier_name = try stringField(object, "tier_name"),
        .total_months_subscribed = @intCast(try intField(object, "total_months_subscribed")),
        .is_renewal = try boolValue(object.get("is_renewal") orelse return error.MissingField),
    };
}

fn sharedClientThemeFromJson(
    allocator: std.mem.Allocator,
    value: std.json.Value,
) !?Types.SharedClientTheme {
    if (value == .null) return null;
    const object = try requireObject(value);
    return .{
        .colors = if (object.get("colors")) |field| try stringArrayFromJson(allocator, field) else try allocator.dupe([]const u8, &.{}),
        .gradient_angle = if (object.get("gradient_angle")) |field| @intCast(try intValue(field)) else 0,
        .base_mix = if (object.get("base_mix")) |field| @intCast(try intValue(field)) else 0,
        .base_theme = if (object.get("base_theme")) |field| try nullableSharedClientThemeBaseFromJson(field) else null,
    };
}

fn deinitParsedSharedClientTheme(theme: ?Types.SharedClientTheme, allocator: std.mem.Allocator) void {
    if (theme) |value| allocator.free(value.colors);
}

fn nullableSharedClientThemeBaseFromJson(value: std.json.Value) !?Types.SharedClientThemeBase {
    if (value == .null) return null;
    return switch (try intValue(value)) {
        0 => .unset,
        1 => .dark,
        2 => .light,
        3 => .darker,
        4 => .midnight,
        else => error.InvalidField,
    };
}

fn nullableMessageActivityFromJson(value: std.json.Value) !?Types.MessageActivity {
    if (value == .null) return null;
    const object = try requireObject(value);
    return .{
        .type = try messageActivityTypeFromInt(try intField(object, "type")),
        .party_id = if (object.get("party_id")) |field| try optionalStringValue(field) else null,
    };
}

fn messageActivityTypeFromInt(value: i64) !Types.MessageActivityType {
    return switch (value) {
        1 => .join,
        2 => .spectate,
        3 => .listen,
        5 => .join_request,
        else => error.InvalidField,
    };
}

fn interactionTypeFromInt(value: i64) !Interactions.InteractionType {
    return switch (value) {
        1 => .ping,
        2 => .application_command,
        3 => .message_component,
        4 => .application_command_autocomplete,
        5 => .modal_submit,
        else => error.InvalidField,
    };
}

fn messagePollMediaFromJson(value: std.json.Value) !Types.MessagePollMedia {
    const object = try requireObject(value);
    return .{
        .text = if (object.get("text")) |field| try optionalStringValue(field) else null,
        .emoji = if (object.get("emoji")) |field| try pollEmojiFromJson(field) else null,
    };
}

fn pollEmojiFromJson(value: std.json.Value) !Types.PollEmoji {
    const object = try requireObject(value);
    return .{
        .id = if (object.get("id")) |field| try nullableSnowflakeValue(field) else null,
        .name = if (object.get("name")) |field| try optionalStringValue(field) else null,
    };
}

fn messagePollAnswerArrayFromJson(
    allocator: std.mem.Allocator,
    value: std.json.Value,
) ![]Types.MessagePollAnswer {
    const array = try requireArray(value);
    var answers = std.array_list.Managed(Types.MessagePollAnswer).init(allocator);
    errdefer answers.deinit();
    for (array.items) |item| try answers.append(try messagePollAnswerFromJson(item));
    return answers.toOwnedSlice();
}

fn messagePollAnswerFromJson(value: std.json.Value) !Types.MessagePollAnswer {
    const object = try requireObject(value);
    return .{
        .answer_id = @intCast(try intField(object, "answer_id")),
        .poll_media = try messagePollMediaFromJson(object.get("poll_media") orelse return error.MissingField),
    };
}

fn messagePollResultsFromJson(
    allocator: std.mem.Allocator,
    value: std.json.Value,
) !Types.MessagePollResults {
    const object = try requireObject(value);
    return .{
        .is_finalized = if (object.get("is_finalized")) |field| try boolValue(field) else false,
        .answer_counts = if (object.get("answer_counts")) |field| try messagePollAnswerCountArrayFromJson(allocator, field) else try allocator.dupe(Types.MessagePollAnswerCount, &.{}),
    };
}

fn messagePollAnswerCountArrayFromJson(
    allocator: std.mem.Allocator,
    value: std.json.Value,
) ![]Types.MessagePollAnswerCount {
    const array = try requireArray(value);
    var counts = std.array_list.Managed(Types.MessagePollAnswerCount).init(allocator);
    errdefer counts.deinit();
    for (array.items) |item| try counts.append(try messagePollAnswerCountFromJson(item));
    return counts.toOwnedSlice();
}

fn messagePollAnswerCountFromJson(value: std.json.Value) !Types.MessagePollAnswerCount {
    const object = try requireObject(value);
    return .{
        .id = @intCast(try intField(object, "id")),
        .count = @intCast(try intField(object, "count")),
        .me_voted = if (object.get("me_voted")) |field| try boolValue(field) else false,
    };
}

fn deinitParsedMessagePoll(poll: ?Types.MessagePoll, allocator: std.mem.Allocator) void {
    if (poll) |value| {
        allocator.free(value.answers);
        if (value.results) |results| allocator.free(results.answer_counts);
    }
}

fn embedArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) ![]Types.Embed {
    const array = try requireArray(value);
    const embeds = try allocator.alloc(Types.Embed, array.items.len);
    var initialized: usize = 0;
    errdefer deinitParsedEmbeds(embeds[0..initialized], allocator);

    for (array.items, 0..) |item, index| {
        embeds[index] = try embedFromJson(allocator, item);
        initialized += 1;
    }
    return embeds;
}

fn deinitParsedEmbeds(embeds: []Types.Embed, allocator: std.mem.Allocator) void {
    for (embeds) |embed| {
        if (embed.fields.len != 0) allocator.free(embed.fields);
    }
    allocator.free(embeds);
}

fn embedFromJson(allocator: std.mem.Allocator, value: std.json.Value) !Types.Embed {
    const object = try requireObject(value);
    return .{
        .title = if (object.get("title")) |field| try optionalStringValue(field) else null,
        .description = if (object.get("description")) |field| try optionalStringValue(field) else null,
        .url = if (object.get("url")) |field| try optionalStringValue(field) else null,
        .timestamp = if (object.get("timestamp")) |field| try optionalStringValue(field) else null,
        .color = if (object.get("color")) |field| @intCast(try intValue(field)) else null,
        .footer = if (object.get("footer")) |field| try embedFooterFromJson(field) else null,
        .image = if (object.get("image")) |field| try embedMediaFromJson(field) else null,
        .thumbnail = if (object.get("thumbnail")) |field| try embedMediaFromJson(field) else null,
        .author = if (object.get("author")) |field| try embedAuthorFromJson(field) else null,
        .fields = if (object.get("fields")) |field| try embedFieldArrayFromJson(allocator, field) else &.{},
    };
}

fn embedFooterFromJson(value: std.json.Value) !Types.EmbedFooter {
    const object = try requireObject(value);
    return .{
        .text = try stringField(object, "text"),
        .icon_url = if (object.get("icon_url")) |field| try optionalStringValue(field) else null,
    };
}

fn embedMediaFromJson(value: std.json.Value) !Types.EmbedMedia {
    const object = try requireObject(value);
    return .{ .url = try stringField(object, "url") };
}

fn embedAuthorFromJson(value: std.json.Value) !Types.EmbedAuthor {
    const object = try requireObject(value);
    return .{
        .name = try stringField(object, "name"),
        .url = if (object.get("url")) |field| try optionalStringValue(field) else null,
        .icon_url = if (object.get("icon_url")) |field| try optionalStringValue(field) else null,
    };
}

fn embedFieldArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) ![]Types.EmbedField {
    const array = try requireArray(value);
    var fields = std.array_list.Managed(Types.EmbedField).init(allocator);
    errdefer fields.deinit();
    for (array.items) |item| try fields.append(try embedFieldFromJson(item));
    return fields.toOwnedSlice();
}

fn embedFieldFromJson(value: std.json.Value) !Types.EmbedField {
    const object = try requireObject(value);
    return .{
        .name = try stringField(object, "name"),
        .value = try stringField(object, "value"),
        .is_inline = if (object.get("inline")) |field| try boolValue(field) else false,
    };
}

fn attachmentFromJson(value: std.json.Value) !Types.Attachment {
    const object = try requireObject(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .filename = try stringField(object, "filename"),
        .description = if (object.get("description")) |field| try optionalStringValue(field) else null,
        .content_type = if (object.get("content_type")) |field| try optionalStringValue(field) else null,
        .size = if (object.get("size")) |field| @intCast(try intValue(field)) else 0,
        .url = try stringField(object, "url"),
        .proxy_url = try stringField(object, "proxy_url"),
        .height = if (object.get("height")) |field| try optionalU32Value(field) else null,
        .width = if (object.get("width")) |field| try optionalU32Value(field) else null,
        .ephemeral = if (object.get("ephemeral")) |field| try boolValue(field) else false,
    };
}

fn reactionArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) ![]Types.MessageReaction {
    const array = try requireArray(value);
    var reactions = std.array_list.Managed(Types.MessageReaction).init(allocator);
    errdefer {
        deinitParsedReactionFields(reactions.items, allocator);
        reactions.deinit();
    }
    for (array.items) |item| try reactions.append(try reactionFromJson(allocator, item));
    return reactions.toOwnedSlice();
}

fn reactionFromJson(allocator: std.mem.Allocator, value: std.json.Value) !Types.MessageReaction {
    const object = try requireObject(value);
    return .{
        .emoji = try reactionEmojiFromJson(object.get("emoji") orelse return error.MissingField),
        .count = if (object.get("count")) |field| @intCast(try intValue(field)) else 0,
        .count_details = if (object.get("count_details")) |field| try reactionCountDetailsFromJson(field) else .{},
        .me = if (object.get("me")) |field| try boolValue(field) else false,
        .me_burst = if (object.get("me_burst")) |field| try boolValue(field) else false,
        .burst_colors = if (object.get("burst_colors")) |field| try stringArrayFromJson(allocator, field) else try allocator.dupe([]const u8, &.{}),
    };
}

fn reactionCountDetailsFromJson(value: std.json.Value) !Types.ReactionCountDetails {
    const object = try requireObject(value);
    return .{
        .burst = if (object.get("burst")) |field| @intCast(try intValue(field)) else 0,
        .normal = if (object.get("normal")) |field| @intCast(try intValue(field)) else 0,
    };
}

fn deinitParsedReactions(reactions: []Types.MessageReaction, allocator: std.mem.Allocator) void {
    deinitParsedReactionFields(reactions, allocator);
    allocator.free(reactions);
}

fn deinitParsedReactionFields(reactions: []Types.MessageReaction, allocator: std.mem.Allocator) void {
    for (reactions) |reaction| allocator.free(reaction.burst_colors);
}

const ReactionEvent = struct {
    message_id: Snowflake,
    emoji: Types.ReactionEmoji,
};

fn reactionEventFromJson(value: std.json.Value) !ReactionEvent {
    const object = try requireObject(value);
    return .{
        .message_id = try snowflakeField(object, "message_id"),
        .emoji = try reactionEmojiFromJson(object.get("emoji") orelse return error.MissingField),
    };
}

fn reactionEmojiFromJson(value: std.json.Value) !Types.ReactionEmoji {
    const object = try requireObject(value);
    return .{
        .id = if (object.get("id")) |field| try nullableSnowflakeValue(field) else null,
        .name = if (object.get("name")) |field| try optionalStringValue(field) else null,
        .animated = if (object.get("animated")) |field| try boolValue(field) else false,
    };
}

fn requireObject(value: std.json.Value) !std.json.ObjectMap {
    return switch (value) {
        .object => |object| object,
        else => error.InvalidField,
    };
}

fn requireArray(value: std.json.Value) !std.json.Array {
    return switch (value) {
        .array => |array| array,
        else => error.InvalidField,
    };
}

fn snowflakeField(object: std.json.ObjectMap, field: []const u8) !Snowflake {
    return snowflakeValue(object.get(field) orelse return error.MissingField);
}

fn snowflakeValue(value: std.json.Value) !Snowflake {
    return Snowflake.parse(try stringValue(value));
}

fn nullableSnowflakeValue(value: std.json.Value) !?Snowflake {
    return switch (value) {
        .string => |string| try Snowflake.parse(string),
        .null => null,
        else => error.InvalidField,
    };
}

fn permissionsValue(value: std.json.Value) !u64 {
    return switch (value) {
        .integer => |integer| @intCast(integer),
        .string => |string| std.fmt.parseInt(u64, string, 10) catch return error.InvalidField,
        else => error.InvalidField,
    };
}

fn stringField(object: std.json.ObjectMap, field: []const u8) ![]const u8 {
    return stringValue(object.get(field) orelse return error.MissingField);
}

fn intField(object: std.json.ObjectMap, field: []const u8) !i64 {
    return intValue(object.get(field) orelse return error.MissingField);
}

fn intValue(value: std.json.Value) !i64 {
    return switch (value) {
        .integer => |integer| @intCast(integer),
        else => error.InvalidField,
    };
}

fn nullableIntValue(value: std.json.Value) !?i64 {
    return switch (value) {
        .integer => |integer| @intCast(integer),
        .null => null,
        else => error.InvalidField,
    };
}

fn nullableU24Value(value: std.json.Value) !?u24 {
    return switch (value) {
        .integer => |integer| @intCast(integer),
        .null => null,
        else => error.InvalidField,
    };
}

const ParsedMessageNonce = struct {
    value: []const u8,
    owned: bool = false,

    fn deinit(self: ParsedMessageNonce, allocator: std.mem.Allocator) void {
        if (self.owned) allocator.free(self.value);
    }
};

fn messageNonceFromJson(allocator: std.mem.Allocator, value: std.json.Value) !?ParsedMessageNonce {
    return switch (value) {
        .string => |string| .{ .value = string },
        .integer => |integer| .{ .value = try std.fmt.allocPrint(allocator, "{d}", .{integer}), .owned = true },
        .null => null,
        else => error.InvalidField,
    };
}

fn optionalU32Value(value: std.json.Value) !?u32 {
    return switch (value) {
        .integer => |integer| @intCast(integer),
        .null => null,
        else => error.InvalidField,
    };
}

fn optionalU8Value(value: std.json.Value) !?u8 {
    return switch (value) {
        .integer => |integer| @intCast(integer),
        .null => null,
        else => error.InvalidField,
    };
}

fn stringValue(value: std.json.Value) ![]const u8 {
    return switch (value) {
        .string => |string| string,
        else => error.InvalidField,
    };
}

fn optionalStringValue(value: std.json.Value) !?[]const u8 {
    return switch (value) {
        .string => |string| string,
        .null => null,
        else => error.InvalidField,
    };
}

fn boolValue(value: std.json.Value) !bool {
    return switch (value) {
        .bool => |boolean| boolean,
        else => error.InvalidField,
    };
}

fn optionalBoolValue(value: std.json.Value) !?bool {
    return switch (value) {
        .bool => |boolean| boolean,
        .null => null,
        else => error.InvalidField,
    };
}

fn nestedIdValue(object: std.json.ObjectMap, key: []const u8) !?Snowflake {
    const value = object.get(key) orelse return null;
    const nested = switch (value) {
        .object => |inner| inner,
        .null => return null,
        else => return error.InvalidField,
    };
    return try snowflakeField(nested, "id");
}

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

test "cache handles guild update and delete dispatches" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var create = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"GUILD_CREATE\",\"d\":{\"id\":\"10\",\"name\":\"Guild\",\"channels\":[{\"id\":\"20\",\"type\":0,\"guild_id\":\"10\",\"name\":\"general\"}],\"members\":[{\"user\":{\"id\":\"30\",\"username\":\"member\"},\"roles\":[]}],\"roles\":[{\"id\":\"40\",\"name\":\"Helper\",\"permissions\":\"0\"}],\"stickers\":[{\"id\":\"50\",\"name\":\"zig\",\"description\":\"mascot\",\"tags\":\"zig\",\"type\":2,\"format_type\":1,\"guild_id\":\"10\"}],\"guild_scheduled_events\":[{\"id\":\"60\",\"guild_id\":\"10\",\"channel_id\":\"20\",\"name\":\"Launch\",\"scheduled_start_time\":\"2026-06-02T10:00:00.000Z\",\"privacy_level\":2,\"status\":1,\"entity_type\":2}]}}",
    );
    defer create.deinit();
    try cache.applyDispatch(create);

    const author = Types.User{ .id = Snowflake.init(30), .username = "member" };
    try cache.putMessage(.{ .id = Snowflake.init(70), .channel_id = Snowflake.init(20), .guild_id = Snowflake.init(10), .author = author, .content = "cached channel" });
    try cache.putMessage(.{ .id = Snowflake.init(71), .channel_id = Snowflake.init(21), .guild_id = Snowflake.init(10), .author = author, .content = "uncached channel" });
    try cache.putMessage(.{ .id = Snowflake.init(72), .channel_id = Snowflake.init(22), .author = author, .content = "dm" });

    var update = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"GUILD_UPDATE\",\"d\":{\"id\":\"10\",\"name\":\"Renamed\",\"icon\":\"renamed_icon\",\"banner\":\"renamed_banner\",\"owner_id\":\"99\",\"description\":null,\"afk_channel_id\":null,\"afk_timeout\":60,\"system_channel_id\":null,\"rules_channel_id\":null,\"public_updates_channel_id\":null,\"safety_alerts_channel_id\":null,\"features\":[\"COMMUNITY\"],\"preferred_locale\":\"tr\",\"verification_level\":1,\"default_message_notifications\":0,\"explicit_content_filter\":2,\"mfa_level\":0,\"nsfw_level\":1,\"max_presences\":2000,\"max_members\":6000,\"premium_tier\":2,\"premium_subscription_count\":5,\"premium_progress_bar_enabled\":false,\"approximate_member_count\":90,\"approximate_presence_count\":20}}",
    );
    defer update.deinit();
    try cache.applyDispatch(update);

    const renamed = cache.getGuild(Snowflake.init(10)).?;
    try std.testing.expectEqualStrings("Renamed", renamed.name);
    try std.testing.expectEqualStrings("renamed_icon", renamed.icon.?);
    try std.testing.expectEqualStrings("renamed_banner", renamed.banner.?);
    try std.testing.expect(renamed.description == null);
    try std.testing.expect(renamed.afk_channel_id == null);
    try std.testing.expectEqual(@as(u32, 60), renamed.afk_timeout.?);
    try std.testing.expect(renamed.system_channel_id == null);
    try std.testing.expect(renamed.rules_channel_id == null);
    try std.testing.expect(renamed.public_updates_channel_id == null);
    try std.testing.expect(renamed.safety_alerts_channel_id == null);
    try std.testing.expectEqual(@as(usize, 1), renamed.features.len);
    try std.testing.expectEqualStrings("COMMUNITY", renamed.features[0]);
    try std.testing.expectEqualStrings("tr", renamed.preferred_locale.?);
    try std.testing.expectEqual(@as(u8, 1), renamed.verification_level.?);
    try std.testing.expectEqual(@as(u8, 0), renamed.default_message_notifications.?);
    try std.testing.expectEqual(@as(u8, 2), renamed.explicit_content_filter.?);
    try std.testing.expectEqual(@as(u8, 0), renamed.mfa_level.?);
    try std.testing.expectEqual(@as(u8, 1), renamed.nsfw_level.?);
    try std.testing.expectEqual(@as(u32, 2000), renamed.max_presences.?);
    try std.testing.expectEqual(@as(u32, 6000), renamed.max_members.?);
    try std.testing.expectEqual(@as(u8, 2), renamed.premium_tier.?);
    try std.testing.expectEqual(@as(u32, 5), renamed.premium_subscription_count.?);
    try std.testing.expect(!renamed.premium_progress_bar_enabled.?);
    try std.testing.expectEqual(@as(u32, 90), renamed.approximate_member_count.?);
    try std.testing.expectEqual(@as(u32, 20), renamed.approximate_presence_count.?);

    var unavailable = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"GUILD_DELETE\",\"d\":{\"id\":\"10\",\"unavailable\":true}}",
    );
    defer unavailable.deinit();
    try cache.applyDispatch(unavailable);

    try std.testing.expect(cache.getGuild(Snowflake.init(10)) != null);
    try std.testing.expect(cache.getChannel(Snowflake.init(20)) != null);
    try std.testing.expect(cache.getMember(Snowflake.init(10), Snowflake.init(30)) != null);
    try std.testing.expect(cache.getRole(Snowflake.init(10), Snowflake.init(40)) != null);
    try std.testing.expect(cache.getSticker(Snowflake.init(10), Snowflake.init(50)) != null);
    try std.testing.expect(cache.getScheduledEvent(Snowflake.init(10), Snowflake.init(60)) != null);
    try std.testing.expect(cache.getMessage(Snowflake.init(70)) != null);

    var delete = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":4,\"t\":\"GUILD_DELETE\",\"d\":{\"id\":\"10\",\"unavailable\":false}}",
    );
    defer delete.deinit();
    try cache.applyDispatch(delete);

    try std.testing.expect(cache.getGuild(Snowflake.init(10)) == null);
    try std.testing.expect(cache.getChannel(Snowflake.init(20)) == null);
    try std.testing.expect(cache.getMember(Snowflake.init(10), Snowflake.init(30)) == null);
    try std.testing.expect(cache.getRole(Snowflake.init(10), Snowflake.init(40)) == null);
    try std.testing.expect(cache.getSticker(Snowflake.init(10), Snowflake.init(50)) == null);
    try std.testing.expect(cache.getScheduledEvent(Snowflake.init(10), Snowflake.init(60)) == null);
    try std.testing.expect(cache.getMessage(Snowflake.init(70)) == null);
    try std.testing.expect(cache.getMessage(Snowflake.init(71)) == null);
    try std.testing.expect(cache.getMessage(Snowflake.init(72)) != null);
    try std.testing.expectEqual(@as(usize, 1), cache.messageCount());
}

test "cache handles guild role create update and delete dispatches" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var create = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"GUILD_ROLE_CREATE\",\"d\":{\"guild_id\":\"10\",\"role\":{\"id\":\"40\",\"name\":\"Helper\",\"color\":1,\"colors\":{\"primary_color\":5793266,\"secondary_color\":15030514,\"tertiary_color\":null},\"hoist\":false,\"icon\":\"role_icon\",\"unicode_emoji\":\"⚡\",\"position\":3,\"permissions\":\"8\",\"managed\":true,\"mentionable\":false,\"tags\":{\"bot_id\":\"50\",\"integration_id\":\"60\",\"premium_subscriber\":null,\"subscription_listing_id\":\"70\",\"available_for_purchase\":null,\"guild_connections\":null},\"flags\":2}}}",
    );
    defer create.deinit();
    try cache.applyDispatch(create);

    const created = cache.getRole(Snowflake.init(10), Snowflake.init(40)).?;
    try std.testing.expectEqualStrings("Helper", created.name);
    try std.testing.expectEqual(@as(u24, 5793266), created.colors.?.primary_color);
    try std.testing.expectEqual(@as(u24, 0xE558F2), created.colors.?.secondary_color.?);
    try std.testing.expect(created.colors.?.tertiary_color == null);
    try std.testing.expectEqualStrings("role_icon", created.icon.?);
    try std.testing.expectEqualStrings("⚡", created.unicode_emoji.?);
    try std.testing.expectEqual(@as(i32, 3), created.position);
    try std.testing.expect(created.managed);
    try std.testing.expectEqual(@as(u64, 50), created.tags.?.bot_id.?.value);
    try std.testing.expectEqual(@as(u64, 60), created.tags.?.integration_id.?.value);
    try std.testing.expect(created.tags.?.premium_subscriber);
    try std.testing.expectEqual(@as(u64, 70), created.tags.?.subscription_listing_id.?.value);
    try std.testing.expect(created.tags.?.available_for_purchase);
    try std.testing.expect(created.tags.?.guild_connections);
    try std.testing.expectEqual(@as(u64, 2), created.flags.?);

    var update = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"GUILD_ROLE_UPDATE\",\"d\":{\"guild_id\":\"10\",\"role\":{\"id\":\"40\",\"name\":\"Admin\",\"color\":2,\"colors\":{\"primary_color\":11127295,\"secondary_color\":16759788,\"tertiary_color\":16761760},\"hoist\":true,\"icon\":null,\"unicode_emoji\":null,\"position\":4,\"permissions\":\"16\",\"managed\":false,\"mentionable\":true,\"tags\":{},\"flags\":4}}}",
    );
    defer update.deinit();
    try cache.applyDispatch(update);

    const updated = cache.getRole(Snowflake.init(10), Snowflake.init(40)).?;
    try std.testing.expectEqualStrings("Admin", updated.name);
    try std.testing.expectEqual(@as(u24, 11127295), updated.colors.?.primary_color);
    try std.testing.expectEqual(@as(u24, 16759788), updated.colors.?.secondary_color.?);
    try std.testing.expectEqual(@as(u24, 16761760), updated.colors.?.tertiary_color.?);
    try std.testing.expectEqual(@as(u64, 16), updated.permissions);
    try std.testing.expect(updated.icon == null);
    try std.testing.expect(updated.unicode_emoji == null);
    try std.testing.expectEqual(@as(i32, 4), updated.position);
    try std.testing.expect(!updated.managed);
    try std.testing.expect(updated.mentionable);
    try std.testing.expect(updated.tags.?.bot_id == null);
    try std.testing.expect(!updated.tags.?.premium_subscriber);
    try std.testing.expectEqual(@as(u64, 4), updated.flags.?);

    try cache.putMember(Snowflake.init(10), .{
        .user = .{ .id = Snowflake.init(30), .username = "member" },
        .roles = &.{ Snowflake.init(40), Snowflake.init(41) },
    });

    var delete = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"GUILD_ROLE_DELETE\",\"d\":{\"guild_id\":\"10\",\"role_id\":\"40\"}}",
    );
    defer delete.deinit();
    try cache.applyDispatch(delete);

    try std.testing.expect(cache.getRole(Snowflake.init(10), Snowflake.init(40)) == null);
    const member = cache.getMember(Snowflake.init(10), Snowflake.init(30)).?;
    try std.testing.expectEqual(@as(usize, 1), member.roles.len);
    try std.testing.expectEqual(@as(u64, 41), member.roles[0].value);
}

test "cache handles guild emojis update dispatch" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var first = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"GUILD_EMOJIS_UPDATE\",\"d\":{\"guild_id\":\"10\",\"emojis\":[{\"id\":\"20\",\"name\":\"zig\",\"roles\":[\"30\"],\"user\":{\"id\":\"40\",\"username\":\"artist\"},\"require_colons\":true,\"managed\":false,\"animated\":true,\"available\":true}]}}",
    );
    defer first.deinit();
    try cache.applyDispatch(first);

    const emoji = cache.getEmoji(Snowflake.init(10), Snowflake.init(20)).?;
    try std.testing.expectEqualStrings("zig", emoji.name.?);
    try std.testing.expectEqual(@as(u64, 30), emoji.roles[0].value);
    try std.testing.expectEqualStrings("artist", emoji.user.?.username);
    try std.testing.expect(emoji.require_colons);
    try std.testing.expect(emoji.animated);

    var second = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"GUILD_EMOJIS_UPDATE\",\"d\":{\"guild_id\":\"10\",\"emojis\":[]}}",
    );
    defer second.deinit();
    try cache.applyDispatch(second);

    try std.testing.expect(cache.getEmoji(Snowflake.init(10), Snowflake.init(20)) == null);
}

test "cache handles guild stickers update dispatch" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var first = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"GUILD_STICKERS_UPDATE\",\"d\":{\"guild_id\":\"10\",\"stickers\":[{\"id\":\"20\",\"name\":\"zig\",\"description\":\"mascot\",\"tags\":\"zig,lang\",\"type\":2,\"format_type\":1,\"available\":true,\"guild_id\":\"10\",\"user\":{\"id\":\"40\",\"username\":\"artist\"},\"sort_value\":3}]}}",
    );
    defer first.deinit();
    try cache.applyDispatch(first);

    const sticker = cache.getSticker(Snowflake.init(10), Snowflake.init(20)).?;
    try std.testing.expectEqualStrings("zig", sticker.name);
    try std.testing.expectEqualStrings("mascot", sticker.description.?);
    try std.testing.expectEqualStrings("zig,lang", sticker.tags);
    try std.testing.expectEqual(Types.StickerType.guild, sticker.type);
    try std.testing.expectEqual(Types.StickerFormatType.png, sticker.format_type);
    try std.testing.expectEqualStrings("artist", sticker.user.?.username);
    try std.testing.expectEqual(@as(u32, 3), sticker.sort_value.?);

    var second = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"GUILD_STICKERS_UPDATE\",\"d\":{\"guild_id\":\"10\",\"stickers\":[]}}",
    );
    defer second.deinit();
    try cache.applyDispatch(second);

    try std.testing.expect(cache.getSticker(Snowflake.init(10), Snowflake.init(20)) == null);
}

test "cache handles guild scheduled event create update and delete dispatches" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var create = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"GUILD_SCHEDULED_EVENT_CREATE\",\"d\":{\"id\":\"20\",\"guild_id\":\"10\",\"channel_id\":\"30\",\"creator_id\":\"40\",\"name\":\"Launch\",\"description\":\"Ship discord.zig\",\"scheduled_start_time\":\"2026-06-02T10:00:00.000Z\",\"scheduled_end_time\":\"2026-06-02T12:00:00.000Z\",\"privacy_level\":2,\"status\":1,\"entity_type\":2,\"entity_id\":null,\"user_count\":5}}",
    );
    defer create.deinit();
    try cache.applyDispatch(create);

    const created = cache.getScheduledEvent(Snowflake.init(10), Snowflake.init(20)).?;
    try std.testing.expectEqualStrings("Launch", created.name);
    try std.testing.expectEqualStrings("Ship discord.zig", created.description.?);
    try std.testing.expectEqual(@as(u64, 30), created.channel_id.?.value);
    try std.testing.expectEqual(Types.GuildScheduledEventStatus.scheduled, created.status);
    try std.testing.expectEqual(Types.GuildScheduledEventEntityType.voice, created.entity_type);
    try std.testing.expectEqual(@as(u32, 5), created.user_count.?);

    var update = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"GUILD_SCHEDULED_EVENT_UPDATE\",\"d\":{\"id\":\"20\",\"guild_id\":\"10\",\"channel_id\":null,\"creator_id\":\"40\",\"name\":\"Meetup\",\"description\":null,\"scheduled_start_time\":\"2026-06-02T13:00:00.000Z\",\"scheduled_end_time\":null,\"privacy_level\":2,\"status\":2,\"entity_type\":3,\"entity_id\":\"50\",\"user_count\":7}}",
    );
    defer update.deinit();
    try cache.applyDispatch(update);

    const updated = cache.getScheduledEvent(Snowflake.init(10), Snowflake.init(20)).?;
    try std.testing.expectEqualStrings("Meetup", updated.name);
    try std.testing.expect(updated.description == null);
    try std.testing.expect(updated.channel_id == null);
    try std.testing.expectEqual(Types.GuildScheduledEventStatus.active, updated.status);
    try std.testing.expectEqual(Types.GuildScheduledEventEntityType.external, updated.entity_type);
    try std.testing.expectEqual(@as(u64, 50), updated.entity_id.?.value);
    try std.testing.expectEqual(@as(u32, 7), updated.user_count.?);

    var user_add = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"GUILD_SCHEDULED_EVENT_USER_ADD\",\"d\":{\"guild_scheduled_event_id\":\"20\",\"user_id\":\"70\",\"guild_id\":\"10\"}}",
    );
    defer user_add.deinit();
    try cache.applyDispatch(user_add);

    try std.testing.expectEqual(@as(u32, 8), cache.getScheduledEvent(Snowflake.init(10), Snowflake.init(20)).?.user_count.?);

    var user_remove = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":4,\"t\":\"GUILD_SCHEDULED_EVENT_USER_REMOVE\",\"d\":{\"guild_scheduled_event_id\":\"20\",\"user_id\":\"70\",\"guild_id\":\"10\"}}",
    );
    defer user_remove.deinit();
    try cache.applyDispatch(user_remove);

    try std.testing.expectEqual(@as(u32, 7), cache.getScheduledEvent(Snowflake.init(10), Snowflake.init(20)).?.user_count.?);

    try cache.putScheduledEvent(.{
        .id = Snowflake.init(21),
        .guild_id = Snowflake.init(10),
        .name = "Unknown count",
        .scheduled_start_time = "2026-06-02T15:00:00.000Z",
        .privacy_level = .guild_only,
        .status = .scheduled,
        .entity_type = .external,
    });

    var unknown_count_add = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":5,\"t\":\"GUILD_SCHEDULED_EVENT_USER_ADD\",\"d\":{\"guild_scheduled_event_id\":\"21\",\"user_id\":\"71\",\"guild_id\":\"10\"}}",
    );
    defer unknown_count_add.deinit();
    try cache.applyDispatch(unknown_count_add);

    try std.testing.expect(cache.getScheduledEvent(Snowflake.init(10), Snowflake.init(21)).?.user_count == null);

    var zero_count_remove = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":6,\"t\":\"GUILD_SCHEDULED_EVENT_USER_REMOVE\",\"d\":{\"guild_scheduled_event_id\":\"20\",\"user_id\":\"72\",\"guild_id\":\"10\"}}",
    );
    defer zero_count_remove.deinit();
    cache.scheduled_events.getPtr(roleKey(Snowflake.init(10), Snowflake.init(20))).?.user_count = 0;
    try cache.applyDispatch(zero_count_remove);

    try std.testing.expectEqual(@as(u32, 0), cache.getScheduledEvent(Snowflake.init(10), Snowflake.init(20)).?.user_count.?);

    var delete = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":7,\"t\":\"GUILD_SCHEDULED_EVENT_DELETE\",\"d\":{\"id\":\"20\",\"guild_id\":\"10\",\"channel_id\":null,\"creator_id\":\"40\",\"name\":\"Meetup\",\"description\":null,\"scheduled_start_time\":\"2026-06-02T13:00:00.000Z\",\"scheduled_end_time\":null,\"privacy_level\":2,\"status\":4,\"entity_type\":3,\"entity_id\":\"50\"}}",
    );
    defer delete.deinit();
    try cache.applyDispatch(delete);

    try std.testing.expect(cache.getScheduledEvent(Snowflake.init(10), Snowflake.init(20)) == null);
}

test "cache handles stage instance create update and delete dispatches" {
    var cache = Cache.init(std.testing.allocator);
    defer cache.deinit();

    var create = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"STAGE_INSTANCE_CREATE\",\"d\":{\"id\":\"20\",\"guild_id\":\"10\",\"channel_id\":\"30\",\"topic\":\"Live Q&A\",\"privacy_level\":2,\"discoverable_disabled\":true,\"guild_scheduled_event_id\":\"40\"}}",
    );
    defer create.deinit();
    try cache.applyDispatch(create);

    const created = cache.getStageInstance(Snowflake.init(10), Snowflake.init(20)).?;
    try std.testing.expectEqualStrings("Live Q&A", created.topic);
    try std.testing.expectEqual(@as(u64, 30), created.channel_id.value);
    try std.testing.expectEqual(Types.StageInstancePrivacyLevel.guild_only, created.privacy_level);
    try std.testing.expect(created.discoverable_disabled);
    try std.testing.expectEqual(@as(u64, 40), created.guild_scheduled_event_id.?.value);

    var update = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"STAGE_INSTANCE_UPDATE\",\"d\":{\"id\":\"20\",\"guild_id\":\"10\",\"channel_id\":\"30\",\"topic\":\"Aftershow\",\"privacy_level\":1,\"discoverable_disabled\":false,\"guild_scheduled_event_id\":null}}",
    );
    defer update.deinit();
    try cache.applyDispatch(update);

    const updated = cache.getStageInstance(Snowflake.init(10), Snowflake.init(20)).?;
    try std.testing.expectEqualStrings("Aftershow", updated.topic);
    try std.testing.expectEqual(Types.StageInstancePrivacyLevel.public, updated.privacy_level);
    try std.testing.expect(!updated.discoverable_disabled);
    try std.testing.expect(updated.guild_scheduled_event_id == null);

    var delete = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"STAGE_INSTANCE_DELETE\",\"d\":{\"id\":\"20\",\"guild_id\":\"10\",\"channel_id\":\"30\",\"topic\":\"Aftershow\",\"privacy_level\":1,\"discoverable_disabled\":false,\"guild_scheduled_event_id\":null}}",
    );
    defer delete.deinit();
    try cache.applyDispatch(delete);

    try std.testing.expect(cache.getStageInstance(Snowflake.init(10), Snowflake.init(20)) == null);
}

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
