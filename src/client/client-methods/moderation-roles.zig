const std = @import("std");
const Intents = @import("../../core/intents.zig");
const Rest = @import("../../rest/client.zig");
const HttpTransport = @import("../../rest/http-transport.zig").HttpTransport;
const Events = @import("../../gateway/events.zig");
const Gateway = @import("../../gateway/protocol.zig");
const GatewaySession = @import("../../gateway/session.zig");
const CacheModule = @import("../cache.zig");
const Types = @import("../../models/types.zig");
const Interactions = @import("../../interactions/mod.zig");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Cache = CacheModule.Cache;
const Root = @import("../client.zig");
const ClientOptions = Root.ClientOptions;
const SetActivityOptions = Root.SetActivityOptions;
const GatewayStep = Root.GatewayStep;
const GatewayStartMode = Root.GatewayStartMode;
const ReconnectBackoff = Root.ReconnectBackoff;
const GatewayRunner = Root.GatewayRunner;
const noTransportValue = Root.noTransportValue;
const noTransportSend = Root.noTransportSend;

pub fn Methods(comptime Client: type) type {
    return struct {
        pub fn ban(self: *Client, guild_id: Snowflake, user_id: Snowflake, payload: Types.CreateGuildBan) !Rest.Response {
            return self.createGuildBan(guild_id, user_id, payload);
        }

        pub fn banUser(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Rest.Response {
            return self.createGuildBan(guild_id, user_id, Types.CreateGuildBan.init());
        }

        pub fn banUserDeletingMessagesFor(
            self: *Client,
            guild_id: Snowflake,
            user_id: Snowflake,
            seconds: u32,
        ) !Rest.Response {
            return self.createGuildBan(guild_id, user_id, Types.CreateGuildBan.init().deleteMessagesFor(seconds));
        }

        pub fn bulkGuildBan(self: *Client, guild_id: Snowflake, payload: Types.BulkGuildBan) !Rest.Response {
            return self.rest.bulkGuildBan(guild_id, payload);
        }

        pub fn bulkBan(self: *Client, guild_id: Snowflake, payload: Types.BulkGuildBan) !Rest.Response {
            return self.bulkGuildBan(guild_id, payload);
        }

        pub fn bulkBanUsers(self: *Client, guild_id: Snowflake, user_ids: []const Snowflake) !Rest.Response {
            return self.bulkGuildBan(guild_id, Types.BulkGuildBan.init(user_ids));
        }

        pub fn bulkBanUsersDeletingMessagesFor(
            self: *Client,
            guild_id: Snowflake,
            user_ids: []const Snowflake,
            seconds: u32,
        ) !Rest.Response {
            return self.bulkGuildBan(guild_id, Types.BulkGuildBan.init(user_ids).deleteMessagesFor(seconds));
        }

        pub fn removeGuildBan(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Rest.Response {
            return self.rest.removeGuildBan(guild_id, user_id);
        }

        pub fn unban(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Rest.Response {
            return self.removeGuildBan(guild_id, user_id);
        }

        pub fn listGuildMembers(self: *Client, guild_id: Snowflake, options: Types.ListGuildMembers) !Rest.Response {
            return self.rest.listGuildMembers(guild_id, options);
        }

        pub fn fetchMembers(self: *Client, guild_id: Snowflake, options: Types.ListGuildMembers) !Rest.Response {
            return self.listGuildMembers(guild_id, options);
        }

        pub fn searchGuildMembers(self: *Client, guild_id: Snowflake, options: Types.SearchGuildMembers) !Rest.Response {
            return self.rest.searchGuildMembers(guild_id, options);
        }

        pub fn searchMembers(self: *Client, guild_id: Snowflake, options: Types.SearchGuildMembers) !Rest.Response {
            return self.searchGuildMembers(guild_id, options);
        }

        pub fn getGuildMember(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Rest.Response {
            return self.rest.getGuildMember(guild_id, user_id);
        }

        pub fn fetchMember(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Rest.Response {
            return self.getGuildMember(guild_id, user_id);
        }

        pub fn addGuildMember(
            self: *Client,
            guild_id: Snowflake,
            user_id: Snowflake,
            payload: Types.AddGuildMember,
        ) !Rest.Response {
            return self.rest.addGuildMember(guild_id, user_id, payload);
        }

        pub fn editGuildMember(
            self: *Client,
            guild_id: Snowflake,
            user_id: Snowflake,
            payload: Types.EditGuildMember,
        ) !Rest.Response {
            return self.rest.editGuildMember(guild_id, user_id, payload);
        }

        pub fn setMemberNickname(
            self: *Client,
            guild_id: Snowflake,
            user_id: Snowflake,
            nick: []const u8,
        ) !Rest.Response {
            return self.editGuildMember(guild_id, user_id, Types.EditGuildMember.init().withNick(nick));
        }

        pub fn setMemberRoles(
            self: *Client,
            guild_id: Snowflake,
            user_id: Snowflake,
            roles: []const Snowflake,
        ) !Rest.Response {
            return self.editGuildMember(guild_id, user_id, Types.EditGuildMember.init().withRoles(roles));
        }

        pub fn muteMember(
            self: *Client,
            guild_id: Snowflake,
            user_id: Snowflake,
            muted: bool,
        ) !Rest.Response {
            return self.editGuildMember(guild_id, user_id, Types.EditGuildMember.init().muteState(muted));
        }

        pub fn deafenMember(
            self: *Client,
            guild_id: Snowflake,
            user_id: Snowflake,
            deafened: bool,
        ) !Rest.Response {
            return self.editGuildMember(guild_id, user_id, Types.EditGuildMember.init().deafState(deafened));
        }

        pub fn moveMemberToVoiceChannel(
            self: *Client,
            guild_id: Snowflake,
            user_id: Snowflake,
            channel_id: Snowflake,
        ) !Rest.Response {
            return self.editGuildMember(guild_id, user_id, Types.EditGuildMember.init().moveToVoiceChannel(channel_id));
        }

        pub fn timeoutMember(
            self: *Client,
            guild_id: Snowflake,
            user_id: Snowflake,
            communication_disabled_until: []const u8,
        ) !Rest.Response {
            return self.editGuildMember(guild_id, user_id, Types.EditGuildMember.init().timeoutUntil(communication_disabled_until));
        }

        pub fn clearMemberTimeout(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Rest.Response {
            return self.editGuildMember(guild_id, user_id, Types.EditGuildMember.init().clearTimeout());
        }

        pub fn editCurrentGuildMember(self: *Client, guild_id: Snowflake, payload: Types.EditCurrentGuildMember) !Rest.Response {
            return self.rest.editCurrentGuildMember(guild_id, payload);
        }

        pub fn setCurrentGuildMemberNick(self: *Client, guild_id: Snowflake, nick: []const u8) !Rest.Response {
            return self.editCurrentGuildMember(guild_id, Types.EditCurrentGuildMember.init().withNick(nick));
        }

        pub fn clearCurrentGuildMemberNick(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.editCurrentGuildMember(guild_id, Types.EditCurrentGuildMember.init().clearNick());
        }

        pub fn setCurrentGuildMemberAvatar(self: *Client, guild_id: Snowflake, avatar: []const u8) !Rest.Response {
            return self.editCurrentGuildMember(guild_id, Types.EditCurrentGuildMember.init().withAvatar(avatar));
        }

        pub fn clearCurrentGuildMemberAvatar(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.editCurrentGuildMember(guild_id, Types.EditCurrentGuildMember.init().clearAvatar());
        }

        pub fn setCurrentGuildMemberBanner(self: *Client, guild_id: Snowflake, banner: []const u8) !Rest.Response {
            return self.editCurrentGuildMember(guild_id, Types.EditCurrentGuildMember.init().withBanner(banner));
        }

        pub fn clearCurrentGuildMemberBanner(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.editCurrentGuildMember(guild_id, Types.EditCurrentGuildMember.init().clearBanner());
        }

        pub fn setCurrentGuildMemberBio(self: *Client, guild_id: Snowflake, bio: []const u8) !Rest.Response {
            return self.editCurrentGuildMember(guild_id, Types.EditCurrentGuildMember.init().withBio(bio));
        }

        pub fn clearCurrentGuildMemberBio(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.editCurrentGuildMember(guild_id, Types.EditCurrentGuildMember.init().clearBio());
        }

        pub fn editCurrentUserNick(self: *Client, guild_id: Snowflake, payload: Types.EditCurrentUserNick) !Rest.Response {
            return self.rest.editCurrentUserNick(guild_id, payload);
        }

        pub fn setCurrentUserNick(self: *Client, guild_id: Snowflake, nick: ?[]const u8) !Rest.Response {
            const payload = if (nick) |value| Types.EditCurrentUserNick.init().withNick(value) else Types.EditCurrentUserNick.init().clearNick();
            return self.editCurrentUserNick(guild_id, payload);
        }

        pub fn setNickname(self: *Client, guild_id: Snowflake, nick: ?[]const u8) !Rest.Response {
            return self.setCurrentUserNick(guild_id, nick);
        }

        pub fn removeGuildMember(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Rest.Response {
            return self.rest.removeGuildMember(guild_id, user_id);
        }

        pub fn kick(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Rest.Response {
            return self.removeGuildMember(guild_id, user_id);
        }

        pub fn addGuildMemberRole(self: *Client, guild_id: Snowflake, user_id: Snowflake, role_id: Snowflake) !Rest.Response {
            return self.rest.addGuildMemberRole(guild_id, user_id, role_id);
        }

        pub fn addRole(self: *Client, guild_id: Snowflake, user_id: Snowflake, role_id: Snowflake) !Rest.Response {
            return self.addGuildMemberRole(guild_id, user_id, role_id);
        }

        pub fn removeGuildMemberRole(self: *Client, guild_id: Snowflake, user_id: Snowflake, role_id: Snowflake) !Rest.Response {
            return self.rest.removeGuildMemberRole(guild_id, user_id, role_id);
        }

        pub fn removeRole(self: *Client, guild_id: Snowflake, user_id: Snowflake, role_id: Snowflake) !Rest.Response {
            return self.removeGuildMemberRole(guild_id, user_id, role_id);
        }

        pub fn listGuildChannels(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.listGuildChannels(guild_id);
        }

        pub fn fetchGuildChannels(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.listGuildChannels(guild_id);
        }

        pub fn createGuildChannel(self: *Client, guild_id: Snowflake, payload: Types.CreateGuildChannel) !Rest.Response {
            return self.rest.createGuildChannel(guild_id, payload);
        }

        pub fn editGuildChannelPositions(
            self: *Client,
            guild_id: Snowflake,
            positions: []const Types.GuildChannelPosition,
        ) !Rest.Response {
            return self.rest.editGuildChannelPositions(guild_id, positions);
        }

        pub fn setGuildChannelPositions(
            self: *Client,
            guild_id: Snowflake,
            positions: []const Types.GuildChannelPosition,
        ) !Rest.Response {
            return self.editGuildChannelPositions(guild_id, positions);
        }

        pub fn editChannel(self: *Client, channel_id: Snowflake, payload: Types.EditChannel) !Rest.Response {
            return self.rest.editChannel(channel_id, payload);
        }

        pub fn deleteChannel(self: *Client, channel_id: Snowflake) !Rest.Response {
            return self.rest.deleteChannel(channel_id);
        }

        pub fn editChannelPermission(
            self: *Client,
            channel_id: Snowflake,
            overwrite_id: Snowflake,
            payload: Types.EditChannelPermission,
        ) !Rest.Response {
            return self.rest.editChannelPermission(channel_id, overwrite_id, payload);
        }

        pub fn setChannelPermission(
            self: *Client,
            channel_id: Snowflake,
            overwrite_id: Snowflake,
            payload: Types.EditChannelPermission,
        ) !Rest.Response {
            return self.editChannelPermission(channel_id, overwrite_id, payload);
        }

        pub fn deleteChannelPermission(self: *Client, channel_id: Snowflake, overwrite_id: Snowflake) !Rest.Response {
            return self.rest.deleteChannelPermission(channel_id, overwrite_id);
        }

        pub fn removeChannelPermission(self: *Client, channel_id: Snowflake, overwrite_id: Snowflake) !Rest.Response {
            return self.deleteChannelPermission(channel_id, overwrite_id);
        }

        pub fn setVoiceChannelStatus(
            self: *Client,
            channel_id: Snowflake,
            payload: Types.SetVoiceChannelStatus,
        ) !Rest.Response {
            return self.rest.setVoiceChannelStatus(channel_id, payload);
        }

        pub fn setVoiceChannelStatusText(
            self: *Client,
            channel_id: Snowflake,
            status: []const u8,
        ) !Rest.Response {
            return self.setVoiceChannelStatus(channel_id, Types.SetVoiceChannelStatus.init(status));
        }

        pub fn clearVoiceChannelStatus(self: *Client, channel_id: Snowflake) !Rest.Response {
            return self.setVoiceChannelStatus(channel_id, Types.SetVoiceChannelStatus.clear());
        }

        pub fn followAnnouncementChannel(
            self: *Client,
            channel_id: Snowflake,
            payload: Types.FollowAnnouncementChannel,
        ) !Rest.Response {
            return self.rest.followAnnouncementChannel(channel_id, payload);
        }

        pub fn followAnnouncementChannelTo(
            self: *Client,
            channel_id: Snowflake,
            webhook_channel_id: Snowflake,
        ) !Rest.Response {
            return self.followAnnouncementChannel(channel_id, Types.FollowAnnouncementChannel.init(webhook_channel_id));
        }

        pub fn followNewsChannel(
            self: *Client,
            channel_id: Snowflake,
            payload: Types.FollowAnnouncementChannel,
        ) !Rest.Response {
            return self.followAnnouncementChannel(channel_id, payload);
        }

        pub fn followNewsChannelTo(
            self: *Client,
            channel_id: Snowflake,
            webhook_channel_id: Snowflake,
        ) !Rest.Response {
            return self.followAnnouncementChannelTo(channel_id, webhook_channel_id);
        }

        pub fn sendSoundboardSound(
            self: *Client,
            channel_id: Snowflake,
            payload: Types.SendSoundboardSound,
        ) !Rest.Response {
            return self.rest.sendSoundboardSound(channel_id, payload);
        }

        pub fn sendSoundboardSoundById(
            self: *Client,
            channel_id: Snowflake,
            sound_id: Snowflake,
        ) !Rest.Response {
            return self.sendSoundboardSound(channel_id, Types.SendSoundboardSound.init(sound_id));
        }

        pub fn playSoundboardSound(
            self: *Client,
            channel_id: Snowflake,
            sound_id: Snowflake,
        ) !Rest.Response {
            return self.sendSoundboardSoundById(channel_id, sound_id);
        }

        pub fn createStageInstance(self: *Client, payload: Types.CreateStageInstance) !Rest.Response {
            return self.rest.createStageInstance(payload);
        }

        pub fn getStageInstance(self: *Client, channel_id: Snowflake) !Rest.Response {
            return self.rest.getStageInstance(channel_id);
        }

        pub fn fetchStageInstance(self: *Client, channel_id: Snowflake) !Rest.Response {
            return self.getStageInstance(channel_id);
        }

        pub fn editStageInstance(self: *Client, channel_id: Snowflake, payload: Types.EditStageInstance) !Rest.Response {
            return self.rest.editStageInstance(channel_id, payload);
        }

        pub fn deleteStageInstance(self: *Client, channel_id: Snowflake) !Rest.Response {
            return self.rest.deleteStageInstance(channel_id);
        }

        pub fn listVoiceRegions(self: *Client) !Rest.Response {
            return self.rest.listVoiceRegions();
        }

        pub fn fetchVoiceRegions(self: *Client) !Rest.Response {
            return self.listVoiceRegions();
        }

        pub fn listGuildVoiceRegions(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.listGuildVoiceRegions(guild_id);
        }

        pub fn fetchGuildVoiceRegions(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.listGuildVoiceRegions(guild_id);
        }

        pub fn getCurrentUserVoiceState(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.getCurrentUserVoiceState(guild_id);
        }

        pub fn fetchCurrentUserVoiceState(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.getCurrentUserVoiceState(guild_id);
        }

        pub fn getUserVoiceState(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Rest.Response {
            return self.rest.getUserVoiceState(guild_id, user_id);
        }

        pub fn fetchUserVoiceState(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Rest.Response {
            return self.getUserVoiceState(guild_id, user_id);
        }

        pub fn editCurrentUserVoiceState(
            self: *Client,
            guild_id: Snowflake,
            payload: Types.EditCurrentUserVoiceState,
        ) !Rest.Response {
            return self.rest.editCurrentUserVoiceState(guild_id, payload);
        }

        pub fn editUserVoiceState(
            self: *Client,
            guild_id: Snowflake,
            user_id: Snowflake,
            payload: Types.EditUserVoiceState,
        ) !Rest.Response {
            return self.rest.editUserVoiceState(guild_id, user_id, payload);
        }

        pub fn listGuildRoles(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.listGuildRoles(guild_id);
        }

        pub fn fetchRoles(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.listGuildRoles(guild_id);
        }

        pub fn getGuildRole(self: *Client, guild_id: Snowflake, role_id: Snowflake) !Rest.Response {
            return self.rest.getGuildRole(guild_id, role_id);
        }

        pub fn fetchRole(self: *Client, guild_id: Snowflake, role_id: Snowflake) !Rest.Response {
            return self.getGuildRole(guild_id, role_id);
        }

        pub fn getGuildRoleMemberCounts(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.getGuildRoleMemberCounts(guild_id);
        }

        pub fn fetchRoleMemberCounts(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.getGuildRoleMemberCounts(guild_id);
        }

        pub fn createGuildRole(self: *Client, guild_id: Snowflake, payload: Types.CreateGuildRole) !Rest.Response {
            return self.rest.createGuildRole(guild_id, payload);
        }

        pub fn createRoleWithName(self: *Client, guild_id: Snowflake, name: []const u8) !Rest.Response {
            return self.createGuildRole(guild_id, Types.CreateGuildRole.init(name));
        }

        pub fn editGuildRolePositions(self: *Client, guild_id: Snowflake, positions: []const Types.GuildRolePosition) !Rest.Response {
            return self.rest.editGuildRolePositions(guild_id, positions);
        }

        pub fn editGuildRole(
            self: *Client,
            guild_id: Snowflake,
            role_id: Snowflake,
            payload: Types.EditGuildRole,
        ) !Rest.Response {
            return self.rest.editGuildRole(guild_id, role_id, payload);
        }

        pub fn renameRole(self: *Client, guild_id: Snowflake, role_id: Snowflake, name: []const u8) !Rest.Response {
            return self.editGuildRole(guild_id, role_id, Types.EditGuildRole.init().withName(name));
        }

        pub fn deleteGuildRole(self: *Client, guild_id: Snowflake, role_id: Snowflake) !Rest.Response {
            return self.rest.deleteGuildRole(guild_id, role_id);
        }

        pub fn listGuildEmojis(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.listGuildEmojis(guild_id);
        }

        pub fn fetchEmojis(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.listGuildEmojis(guild_id);
        }

        pub fn getGuildEmoji(self: *Client, guild_id: Snowflake, emoji_id: Snowflake) !Rest.Response {
            return self.rest.getGuildEmoji(guild_id, emoji_id);
        }

        pub fn fetchEmoji(self: *Client, guild_id: Snowflake, emoji_id: Snowflake) !Rest.Response {
            return self.getGuildEmoji(guild_id, emoji_id);
        }

        pub fn createGuildEmoji(self: *Client, guild_id: Snowflake, payload: Types.CreateGuildEmoji) !Rest.Response {
            return self.rest.createGuildEmoji(guild_id, payload);
        }

        pub fn createEmojiWithImage(
            self: *Client,
            guild_id: Snowflake,
            name: []const u8,
            image: []const u8,
        ) !Rest.Response {
            return self.createGuildEmoji(guild_id, Types.CreateGuildEmoji.init(name, image));
        }

        pub fn editGuildEmoji(
            self: *Client,
            guild_id: Snowflake,
            emoji_id: Snowflake,
            payload: Types.EditGuildEmoji,
        ) !Rest.Response {
            return self.rest.editGuildEmoji(guild_id, emoji_id, payload);
        }

        pub fn renameEmoji(self: *Client, guild_id: Snowflake, emoji_id: Snowflake, name: []const u8) !Rest.Response {
            return self.editGuildEmoji(guild_id, emoji_id, Types.EditGuildEmoji.init().withName(name));
        }

        pub fn deleteGuildEmoji(self: *Client, guild_id: Snowflake, emoji_id: Snowflake) !Rest.Response {
            return self.rest.deleteGuildEmoji(guild_id, emoji_id);
        }

        pub fn getSticker(self: *Client, sticker_id: Snowflake) !Rest.Response {
            return self.rest.getSticker(sticker_id);
        }

        pub fn fetchStickerById(self: *Client, sticker_id: Snowflake) !Rest.Response {
            return self.getSticker(sticker_id);
        }

        pub fn listStickerPacks(self: *Client) !Rest.Response {
            return self.rest.listStickerPacks();
        }

        pub fn fetchStickerPacks(self: *Client) !Rest.Response {
            return self.listStickerPacks();
        }

        pub fn listGuildStickers(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.listGuildStickers(guild_id);
        }

        pub fn fetchStickers(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.listGuildStickers(guild_id);
        }

        pub fn getGuildSticker(self: *Client, guild_id: Snowflake, sticker_id: Snowflake) !Rest.Response {
            return self.rest.getGuildSticker(guild_id, sticker_id);
        }

        pub fn fetchSticker(self: *Client, guild_id: Snowflake, sticker_id: Snowflake) !Rest.Response {
            return self.getGuildSticker(guild_id, sticker_id);
        }
    };
}
