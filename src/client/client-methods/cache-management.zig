const std = @import("std");
const Intents = @import("../../core/intents.zig");
const Rest = @import("../../rest/client.zig");
const HttpTransport = @import("../../rest/http-transport.zig").HttpTransport;
const Events = @import("../../gateway/events.zig");
const Gateway = @import("../../gateway/protocol.zig");
const GatewaySession = @import("../../gateway/session.zig");
const CacheModule = @import("../cache.zig");
const Interactions = @import("../../interactions/mod.zig");
const Cache = CacheModule.Cache;
const Types = @import("../../models/types.zig");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Root = @import("../client.zig");

pub fn Methods(comptime Client: type) type {
    return struct {
        pub fn clearCache(self: *Client) void {
            self.cache.clear();
        }

        pub fn evictCachedUser(self: *Client, user_id: Snowflake) void {
            self.cache.removeUser(user_id);
        }

        pub fn evictCurrentCachedApplication(self: *Client) void {
            self.cache.removeCurrentApplication();
        }

        pub fn evictCachedGuild(self: *Client, guild_id: Snowflake) void {
            self.cache.removeGuild(guild_id);
        }

        pub fn evictCachedChannel(self: *Client, channel_id: Snowflake) void {
            self.cache.removeChannel(channel_id);
        }

        pub fn evictCachedMember(self: *Client, guild_id: Snowflake, user_id: Snowflake) void {
            self.cache.removeMember(guild_id, user_id);
        }

        pub fn evictCachedRole(self: *Client, guild_id: Snowflake, role_id: Snowflake) void {
            self.cache.removeRole(guild_id, role_id);
        }

        pub fn evictCachedEmoji(self: *Client, guild_id: Snowflake, emoji_id: Snowflake) void {
            self.cache.removeEmoji(guild_id, emoji_id);
        }

        pub fn evictCachedSticker(self: *Client, guild_id: Snowflake, sticker_id: Snowflake) void {
            self.cache.removeSticker(guild_id, sticker_id);
        }

        pub fn evictCachedScheduledEvent(self: *Client, guild_id: Snowflake, event_id: Snowflake) void {
            self.cache.removeScheduledEvent(guild_id, event_id);
        }

        pub fn evictCachedStageInstance(self: *Client, guild_id: Snowflake, stage_instance_id: Snowflake) void {
            self.cache.removeStageInstance(guild_id, stage_instance_id);
        }

        pub fn evictCachedInvite(self: *Client, code: []const u8) void {
            self.cache.removeInvite(code);
        }

        pub fn evictCachedPresence(self: *Client, guild_id: Snowflake, user_id: Snowflake) void {
            self.cache.removePresence(guild_id, user_id);
        }

        pub fn evictCachedVoiceState(self: *Client, guild_id: Snowflake, user_id: Snowflake) void {
            self.cache.removeVoiceState(guild_id, user_id);
        }

        pub fn evictCachedMessage(self: *Client, message_id: Snowflake) void {
            self.cache.removeMessage(message_id);
        }

        pub fn cacheStats(self: *Client) CacheModule.CacheStats {
            return self.cache.stats();
        }

        pub fn cachedUserCount(self: *Client) usize {
            return self.cacheStats().users;
        }

        pub fn cachedGuildCount(self: *Client) usize {
            return self.cacheStats().guilds;
        }

        pub fn cachedChannelCount(self: *Client) usize {
            return self.cacheStats().channels;
        }

        pub fn cachedMemberCount(self: *Client) usize {
            return self.cacheStats().members;
        }

        pub fn cachedRoleCount(self: *Client) usize {
            return self.cacheStats().roles;
        }

        pub fn cachedEmojiCount(self: *Client) usize {
            return self.cacheStats().emojis;
        }

        pub fn cachedStickerCount(self: *Client) usize {
            return self.cacheStats().stickers;
        }

        pub fn cachedMessageCount(self: *Client) usize {
            return self.cacheStats().messages;
        }

        pub fn guildCacheStats(self: *Client, guild_id: Snowflake) CacheModule.GuildCacheStats {
            return self.cache.guildStats(guild_id);
        }

        pub fn channelCacheStats(self: *Client, channel_id: Snowflake) CacheModule.ChannelCacheStats {
            return self.cache.channelStats(channel_id);
        }

        pub fn listCachedUsers(self: *Client, allocator: std.mem.Allocator) ![]Types.User {
            return self.cache.listUsers(allocator);
        }

        pub fn cachedUsers(self: *Client, allocator: std.mem.Allocator) ![]Types.User {
            return self.listCachedUsers(allocator);
        }

        pub fn listCachedGuilds(self: *Client, allocator: std.mem.Allocator) ![]Types.Guild {
            return self.cache.listGuilds(allocator);
        }

        pub fn cachedGuilds(self: *Client, allocator: std.mem.Allocator) ![]Types.Guild {
            return self.listCachedGuilds(allocator);
        }

        pub fn listCachedChannels(self: *Client, allocator: std.mem.Allocator) ![]Types.Channel {
            return self.cache.listChannels(allocator);
        }

        pub fn cachedChannels(self: *Client, allocator: std.mem.Allocator) ![]Types.Channel {
            return self.listCachedChannels(allocator);
        }

        pub fn listCachedTopLevelChannels(self: *Client, allocator: std.mem.Allocator) ![]Types.Channel {
            return self.cache.listTopLevelChannels(allocator);
        }

        pub fn cachedTopLevelChannels(self: *Client, allocator: std.mem.Allocator) ![]Types.Channel {
            return self.listCachedTopLevelChannels(allocator);
        }

        pub fn listCachedGuildChannels(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Channel {
            return self.cache.listGuildChannels(allocator, guild_id);
        }

        pub fn cachedGuildChannels(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Channel {
            return self.listCachedGuildChannels(allocator, guild_id);
        }

        pub fn listCachedChannelThreads(self: *Client, allocator: std.mem.Allocator, parent_channel_id: Snowflake) ![]Types.Channel {
            return self.cache.listChannelThreads(allocator, parent_channel_id);
        }

        pub fn cachedChannelThreads(self: *Client, allocator: std.mem.Allocator, parent_channel_id: Snowflake) ![]Types.Channel {
            return self.listCachedChannelThreads(allocator, parent_channel_id);
        }

        pub fn listCachedGuildThreads(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Channel {
            return self.cache.listGuildThreads(allocator, guild_id);
        }

        pub fn cachedGuildThreads(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Channel {
            return self.listCachedGuildThreads(allocator, guild_id);
        }

        pub fn listCachedGuildMembers(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.GuildMember {
            return self.cache.listGuildMembers(allocator, guild_id);
        }

        pub fn cachedGuildMembers(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.GuildMember {
            return self.listCachedGuildMembers(allocator, guild_id);
        }

        pub fn listCachedMembers(self: *Client, allocator: std.mem.Allocator) ![]Types.CachedGuildMember {
            return self.cache.listMembers(allocator);
        }

        pub fn cachedMembers(self: *Client, allocator: std.mem.Allocator) ![]Types.CachedGuildMember {
            return self.listCachedMembers(allocator);
        }

        pub fn listCachedGuildRoles(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Role {
            return self.cache.listGuildRoles(allocator, guild_id);
        }

        pub fn cachedGuildRoles(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Role {
            return self.listCachedGuildRoles(allocator, guild_id);
        }

        pub fn listCachedRoles(self: *Client, allocator: std.mem.Allocator) ![]Types.Role {
            return self.cache.listRoles(allocator);
        }

        pub fn cachedRoles(self: *Client, allocator: std.mem.Allocator) ![]Types.Role {
            return self.listCachedRoles(allocator);
        }

        pub fn listCachedGuildEmojis(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Emoji {
            return self.cache.listGuildEmojis(allocator, guild_id);
        }

        pub fn cachedGuildEmojis(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Emoji {
            return self.listCachedGuildEmojis(allocator, guild_id);
        }

        pub fn listCachedEmojis(self: *Client, allocator: std.mem.Allocator) ![]Types.Emoji {
            return self.cache.listEmojis(allocator);
        }

        pub fn cachedEmojis(self: *Client, allocator: std.mem.Allocator) ![]Types.Emoji {
            return self.listCachedEmojis(allocator);
        }

        pub fn listCachedGuildStickers(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Sticker {
            return self.cache.listGuildStickers(allocator, guild_id);
        }

        pub fn cachedGuildStickers(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Sticker {
            return self.listCachedGuildStickers(allocator, guild_id);
        }

        pub fn listCachedStickers(self: *Client, allocator: std.mem.Allocator) ![]Types.Sticker {
            return self.cache.listStickers(allocator);
        }

        pub fn cachedStickers(self: *Client, allocator: std.mem.Allocator) ![]Types.Sticker {
            return self.listCachedStickers(allocator);
        }

        pub fn listCachedGuildScheduledEvents(
            self: *Client,
            allocator: std.mem.Allocator,
            guild_id: Snowflake,
        ) ![]Types.GuildScheduledEvent {
            return self.cache.listGuildScheduledEvents(allocator, guild_id);
        }

        pub fn cachedGuildScheduledEvents(
            self: *Client,
            allocator: std.mem.Allocator,
            guild_id: Snowflake,
        ) ![]Types.GuildScheduledEvent {
            return self.listCachedGuildScheduledEvents(allocator, guild_id);
        }

        pub fn listCachedScheduledEvents(self: *Client, allocator: std.mem.Allocator) ![]Types.GuildScheduledEvent {
            return self.cache.listScheduledEvents(allocator);
        }

        pub fn cachedScheduledEvents(self: *Client, allocator: std.mem.Allocator) ![]Types.GuildScheduledEvent {
            return self.listCachedScheduledEvents(allocator);
        }

        pub fn listCachedGuildStageInstances(
            self: *Client,
            allocator: std.mem.Allocator,
            guild_id: Snowflake,
        ) ![]Types.StageInstance {
            return self.cache.listGuildStageInstances(allocator, guild_id);
        }

        pub fn cachedGuildStageInstances(
            self: *Client,
            allocator: std.mem.Allocator,
            guild_id: Snowflake,
        ) ![]Types.StageInstance {
            return self.listCachedGuildStageInstances(allocator, guild_id);
        }

        pub fn listCachedStageInstances(self: *Client, allocator: std.mem.Allocator) ![]Types.StageInstance {
            return self.cache.listStageInstances(allocator);
        }

        pub fn cachedStageInstances(self: *Client, allocator: std.mem.Allocator) ![]Types.StageInstance {
            return self.listCachedStageInstances(allocator);
        }

        pub fn listCachedGuildInvites(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Invite {
            return self.cache.listGuildInvites(allocator, guild_id);
        }

        pub fn cachedGuildInvites(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Invite {
            return self.listCachedGuildInvites(allocator, guild_id);
        }

        pub fn listCachedInvites(self: *Client, allocator: std.mem.Allocator) ![]Types.Invite {
            return self.cache.listInvites(allocator);
        }

        pub fn cachedInvites(self: *Client, allocator: std.mem.Allocator) ![]Types.Invite {
            return self.listCachedInvites(allocator);
        }

        pub fn listCachedChannelInvites(self: *Client, allocator: std.mem.Allocator, channel_id: Snowflake) ![]Types.Invite {
            return self.cache.listChannelInvites(allocator, channel_id);
        }

        pub fn cachedChannelInvites(self: *Client, allocator: std.mem.Allocator, channel_id: Snowflake) ![]Types.Invite {
            return self.listCachedChannelInvites(allocator, channel_id);
        }

        pub fn listCachedPresences(self: *Client, allocator: std.mem.Allocator) ![]Types.Presence {
            return self.cache.listPresences(allocator);
        }

        pub fn cachedPresences(self: *Client, allocator: std.mem.Allocator) ![]Types.Presence {
            return self.listCachedPresences(allocator);
        }

        pub fn listCachedGuildPresences(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Presence {
            return self.cache.listGuildPresences(allocator, guild_id);
        }

        pub fn cachedGuildPresences(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Presence {
            return self.listCachedGuildPresences(allocator, guild_id);
        }

        pub fn listCachedVoiceStates(self: *Client, allocator: std.mem.Allocator) ![]Types.VoiceState {
            return self.cache.listVoiceStates(allocator);
        }

        pub fn cachedVoiceStates(self: *Client, allocator: std.mem.Allocator) ![]Types.VoiceState {
            return self.listCachedVoiceStates(allocator);
        }

        pub fn listCachedGuildVoiceStates(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.VoiceState {
            return self.cache.listGuildVoiceStates(allocator, guild_id);
        }

        pub fn cachedGuildVoiceStates(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.VoiceState {
            return self.listCachedGuildVoiceStates(allocator, guild_id);
        }

        pub fn listCachedChannelMessages(self: *Client, allocator: std.mem.Allocator, channel_id: Snowflake) ![]Types.Message {
            return self.cache.listChannelMessages(allocator, channel_id);
        }

        pub fn cachedChannelMessages(self: *Client, allocator: std.mem.Allocator, channel_id: Snowflake) ![]Types.Message {
            return self.listCachedChannelMessages(allocator, channel_id);
        }

        pub fn listCachedMessages(self: *Client, allocator: std.mem.Allocator) ![]Types.Message {
            return self.cache.listMessages(allocator);
        }

        pub fn cachedMessages(self: *Client, allocator: std.mem.Allocator) ![]Types.Message {
            return self.listCachedMessages(allocator);
        }

        pub fn listCachedGuildMessages(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Message {
            return self.cache.listGuildMessages(allocator, guild_id);
        }

        pub fn cachedGuildMessages(self: *Client, allocator: std.mem.Allocator, guild_id: Snowflake) ![]Types.Message {
            return self.listCachedGuildMessages(allocator, guild_id);
        }

        pub fn deinit(self: *Client) void {
            self.cache.deinit();
            self.rest.deinit();
            if (self.owned_http_transport) |http_transport| {
                http_transport.deinit();
                self.allocator.destroy(http_transport);
            }
        }

        pub fn destroy(self: *Client) void {
            self.deinit();
        }
    };
}
