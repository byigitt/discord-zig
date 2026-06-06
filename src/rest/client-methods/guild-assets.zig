const std = @import("std");
const Routes = @import("../routes.zig");
const Types = @import("../../models/types.zig");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;

const Root = @import("../client.zig");
const Response = Root.Response;

pub fn Methods(comptime Client: type) type {
    return struct {
        pub fn editAutoModerationRule(
            self: *Client,
            guild_id: Snowflake,
            rule_id: Snowflake,
            payload: Types.EditAutoModerationRule,
        ) !Response {
            const route = try Routes.editAutoModerationRule(self.allocator, guild_id, rule_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn deleteAutoModerationRule(self: *Client, guild_id: Snowflake, rule_id: Snowflake) !Response {
            const route = try Routes.deleteAutoModerationRule(self.allocator, guild_id, rule_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn getGuildTemplate(self: *Client, code: []const u8) !Response {
            const route = try Routes.guildTemplate(self.allocator, code);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn createGuildFromTemplate(self: *Client, code: []const u8, payload: Types.CreateGuildFromTemplate) !Response {
            const route = try Routes.createGuildFromTemplate(self.allocator, code);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn listGuildTemplates(self: *Client, guild_id: Snowflake) !Response {
            const route = try Routes.guildTemplates(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn createGuildTemplate(self: *Client, guild_id: Snowflake, payload: Types.CreateGuildTemplate) !Response {
            const route = try Routes.createGuildTemplate(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn syncGuildTemplate(self: *Client, guild_id: Snowflake, code: []const u8) !Response {
            const route = try Routes.syncGuildTemplate(self.allocator, guild_id, code);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn editGuildTemplate(
            self: *Client,
            guild_id: Snowflake,
            code: []const u8,
            payload: Types.EditGuildTemplate,
        ) !Response {
            const route = try Routes.editGuildTemplate(self.allocator, guild_id, code);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn deleteGuildTemplate(self: *Client, guild_id: Snowflake, code: []const u8) !Response {
            const route = try Routes.deleteGuildTemplate(self.allocator, guild_id, code);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn getGuildWidgetSettings(self: *Client, guild_id: Snowflake) !Response {
            const route = try Routes.guildWidgetSettings(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn editGuildWidgetSettings(
            self: *Client,
            guild_id: Snowflake,
            payload: Types.EditGuildWidgetSettings,
        ) !Response {
            const route = try Routes.editGuildWidgetSettings(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn getGuildWidget(self: *Client, guild_id: Snowflake) !Response {
            const route = try Routes.guildWidget(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn getGuildWidgetImage(self: *Client, guild_id: Snowflake, options: Types.GetGuildWidgetImage) !Response {
            const route = try Routes.guildWidgetImage(self.allocator, guild_id, options);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn getGuildWelcomeScreen(self: *Client, guild_id: Snowflake) !Response {
            const route = try Routes.guildWelcomeScreen(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn editGuildWelcomeScreen(
            self: *Client,
            guild_id: Snowflake,
            payload: Types.EditWelcomeScreen,
        ) !Response {
            const route = try Routes.editGuildWelcomeScreen(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn getGuildOnboarding(self: *Client, guild_id: Snowflake) !Response {
            const route = try Routes.guildOnboarding(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn editGuildOnboarding(self: *Client, guild_id: Snowflake, payload: Types.EditGuildOnboarding) !Response {
            const route = try Routes.editGuildOnboarding(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn editGuildIncidentActions(
            self: *Client,
            guild_id: Snowflake,
            payload: Types.EditGuildIncidentActions,
        ) !Response {
            const route = try Routes.editGuildIncidentActions(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn getGuildVanityUrl(self: *Client, guild_id: Snowflake) !Response {
            const route = try Routes.guildVanityUrl(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listGuildScheduledEvents(self: *Client, guild_id: Snowflake, options: Types.ListGuildScheduledEvents) !Response {
            const route = try Routes.guildScheduledEvents(self.allocator, guild_id, options);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn createGuildScheduledEvent(
            self: *Client,
            guild_id: Snowflake,
            payload: Types.CreateGuildScheduledEvent,
        ) !Response {
            const route = try Routes.createGuildScheduledEvent(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn getGuildScheduledEvent(
            self: *Client,
            guild_id: Snowflake,
            event_id: Snowflake,
            options: Types.GetGuildScheduledEvent,
        ) !Response {
            const route = try Routes.guildScheduledEvent(self.allocator, guild_id, event_id, options);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn editGuildScheduledEvent(
            self: *Client,
            guild_id: Snowflake,
            event_id: Snowflake,
            payload: Types.EditGuildScheduledEvent,
        ) !Response {
            const route = try Routes.editGuildScheduledEvent(self.allocator, guild_id, event_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn deleteGuildScheduledEvent(self: *Client, guild_id: Snowflake, event_id: Snowflake) !Response {
            const route = try Routes.deleteGuildScheduledEvent(self.allocator, guild_id, event_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listGuildScheduledEventUsers(
            self: *Client,
            guild_id: Snowflake,
            event_id: Snowflake,
            options: Types.ListGuildScheduledEventUsers,
        ) !Response {
            const route = try Routes.guildScheduledEventUsers(self.allocator, guild_id, event_id, options);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listGuildAuditLog(self: *Client, guild_id: Snowflake, options: Types.ListAuditLog) !Response {
            const route = try Routes.guildAuditLog(self.allocator, guild_id, options);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listGuildIntegrations(self: *Client, guild_id: Snowflake) !Response {
            const route = try Routes.guildIntegrations(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn deleteGuildIntegration(self: *Client, guild_id: Snowflake, integration_id: Snowflake) !Response {
            const route = try Routes.deleteGuildIntegration(self.allocator, guild_id, integration_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listGuildChannels(self: *Client, guild_id: Snowflake) !Response {
            const route = try Routes.guildChannels(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn createGuildChannel(self: *Client, guild_id: Snowflake, payload: Types.CreateGuildChannel) !Response {
            const route = try Routes.createGuildChannel(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn editGuildChannelPositions(self: *Client, guild_id: Snowflake, positions: []const Types.GuildChannelPosition) !Response {
            const route = try Routes.editGuildChannelPositions(self.allocator, guild_id);
            defer route.deinit(self.allocator);

            var body = std.Io.Writer.Allocating.init(self.allocator);
            defer body.deinit();
            try Types.writeGuildChannelPositionArray(positions, &body.writer);

            return self.request(route, body.written(), "application/json");
        }

        pub fn listGuildMembers(self: *Client, guild_id: Snowflake, options: Types.ListGuildMembers) !Response {
            const route = try Routes.guildMembers(self.allocator, guild_id, options);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn searchGuildMembers(self: *Client, guild_id: Snowflake, options: Types.SearchGuildMembers) !Response {
            const route = try Routes.searchGuildMembers(self.allocator, guild_id, options);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn getGuildMember(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Response {
            const route = try Routes.guildMember(self.allocator, guild_id, user_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn addGuildMember(self: *Client, guild_id: Snowflake, user_id: Snowflake, payload: Types.AddGuildMember) !Response {
            const route = try Routes.addGuildMember(self.allocator, guild_id, user_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn editGuildMember(self: *Client, guild_id: Snowflake, user_id: Snowflake, payload: Types.EditGuildMember) !Response {
            const route = try Routes.editGuildMember(self.allocator, guild_id, user_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn editCurrentGuildMember(self: *Client, guild_id: Snowflake, payload: Types.EditCurrentGuildMember) !Response {
            const route = try Routes.editCurrentGuildMember(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn editCurrentUserNick(self: *Client, guild_id: Snowflake, payload: Types.EditCurrentUserNick) !Response {
            const route = try Routes.editCurrentUserNick(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn removeGuildMember(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Response {
            const route = try Routes.removeGuildMember(self.allocator, guild_id, user_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listGuildBans(self: *Client, guild_id: Snowflake, options: Types.ListGuildBans) !Response {
            const route = try Routes.guildBans(self.allocator, guild_id, options);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn getGuildBan(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Response {
            const route = try Routes.guildBan(self.allocator, guild_id, user_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn getGuildPruneCount(self: *Client, guild_id: Snowflake, options: Types.GetGuildPruneCount) !Response {
            const route = try Routes.guildPruneCount(self.allocator, guild_id, options);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn beginGuildPrune(self: *Client, guild_id: Snowflake, payload: Types.BeginGuildPrune) !Response {
            const route = try Routes.beginGuildPrune(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn createGuildBan(self: *Client, guild_id: Snowflake, user_id: Snowflake, payload: Types.CreateGuildBan) !Response {
            const route = try Routes.createGuildBan(self.allocator, guild_id, user_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn bulkGuildBan(self: *Client, guild_id: Snowflake, payload: Types.BulkGuildBan) !Response {
            const route = try Routes.bulkGuildBan(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn removeGuildBan(self: *Client, guild_id: Snowflake, user_id: Snowflake) !Response {
            const route = try Routes.removeGuildBan(self.allocator, guild_id, user_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listGuildRoles(self: *Client, guild_id: Snowflake) !Response {
            const route = try Routes.guildRoles(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn getGuildRole(self: *Client, guild_id: Snowflake, role_id: Snowflake) !Response {
            const route = try Routes.guildRole(self.allocator, guild_id, role_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn getGuildRoleMemberCounts(self: *Client, guild_id: Snowflake) !Response {
            const route = try Routes.guildRoleMemberCounts(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn createGuildRole(self: *Client, guild_id: Snowflake, payload: Types.CreateGuildRole) !Response {
            const route = try Routes.createGuildRole(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn editGuildRolePositions(self: *Client, guild_id: Snowflake, positions: []const Types.GuildRolePosition) !Response {
            const route = try Routes.editGuildRolePositions(self.allocator, guild_id);
            defer route.deinit(self.allocator);

            var body = std.Io.Writer.Allocating.init(self.allocator);
            defer body.deinit();
            try Types.writeGuildRolePositionArray(positions, &body.writer);

            return self.request(route, body.written(), "application/json");
        }

        pub fn editGuildRole(self: *Client, guild_id: Snowflake, role_id: Snowflake, payload: Types.EditGuildRole) !Response {
            const route = try Routes.editGuildRole(self.allocator, guild_id, role_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn deleteGuildRole(self: *Client, guild_id: Snowflake, role_id: Snowflake) !Response {
            const route = try Routes.deleteGuildRole(self.allocator, guild_id, role_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listGuildEmojis(self: *Client, guild_id: Snowflake) !Response {
            const route = try Routes.guildEmojis(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn getGuildEmoji(self: *Client, guild_id: Snowflake, emoji_id: Snowflake) !Response {
            const route = try Routes.guildEmoji(self.allocator, guild_id, emoji_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn createGuildEmoji(self: *Client, guild_id: Snowflake, payload: Types.CreateGuildEmoji) !Response {
            const route = try Routes.createGuildEmoji(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn editGuildEmoji(
            self: *Client,
            guild_id: Snowflake,
            emoji_id: Snowflake,
            payload: Types.EditGuildEmoji,
        ) !Response {
            const route = try Routes.editGuildEmoji(self.allocator, guild_id, emoji_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn deleteGuildEmoji(self: *Client, guild_id: Snowflake, emoji_id: Snowflake) !Response {
            const route = try Routes.deleteGuildEmoji(self.allocator, guild_id, emoji_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn getSticker(self: *Client, sticker_id: Snowflake) !Response {
            const route = try Routes.sticker(self.allocator, sticker_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listStickerPacks(self: *Client) !Response {
            const route = try Routes.stickerPacks(self.allocator);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listGuildStickers(self: *Client, guild_id: Snowflake) !Response {
            const route = try Routes.guildStickers(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn getGuildSticker(self: *Client, guild_id: Snowflake, sticker_id: Snowflake) !Response {
            const route = try Routes.guildSticker(self.allocator, guild_id, sticker_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn createGuildSticker(
            self: *Client,
            guild_id: Snowflake,
            payload: Types.CreateGuildSticker,
            file: Types.UploadFile,
        ) !Response {
            const route = try Routes.createGuildSticker(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.requestGuildStickerMultipart(route, payload, file);
        }

        pub fn editGuildSticker(
            self: *Client,
            guild_id: Snowflake,
            sticker_id: Snowflake,
            payload: Types.EditGuildSticker,
        ) !Response {
            const route = try Routes.editGuildSticker(self.allocator, guild_id, sticker_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn deleteGuildSticker(self: *Client, guild_id: Snowflake, sticker_id: Snowflake) !Response {
            const route = try Routes.deleteGuildSticker(self.allocator, guild_id, sticker_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listDefaultSoundboardSounds(self: *Client) !Response {
            const route = try Routes.defaultSoundboardSounds(self.allocator);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listGuildSoundboardSounds(self: *Client, guild_id: Snowflake) !Response {
            const route = try Routes.guildSoundboardSounds(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn getGuildSoundboardSound(self: *Client, guild_id: Snowflake, sound_id: Snowflake) !Response {
            const route = try Routes.guildSoundboardSound(self.allocator, guild_id, sound_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn createGuildSoundboardSound(
            self: *Client,
            guild_id: Snowflake,
            payload: Types.CreateGuildSoundboardSound,
        ) !Response {
            const route = try Routes.createGuildSoundboardSound(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn editGuildSoundboardSound(
            self: *Client,
            guild_id: Snowflake,
            sound_id: Snowflake,
            payload: Types.EditGuildSoundboardSound,
        ) !Response {
            const route = try Routes.editGuildSoundboardSound(self.allocator, guild_id, sound_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn deleteGuildSoundboardSound(self: *Client, guild_id: Snowflake, sound_id: Snowflake) !Response {
            const route = try Routes.deleteGuildSoundboardSound(self.allocator, guild_id, sound_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn addGuildMemberRole(self: *Client, guild_id: Snowflake, user_id: Snowflake, role_id: Snowflake) !Response {
            const route = try Routes.addGuildMemberRole(self.allocator, guild_id, user_id, role_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn removeGuildMemberRole(self: *Client, guild_id: Snowflake, user_id: Snowflake, role_id: Snowflake) !Response {
            const route = try Routes.removeGuildMemberRole(self.allocator, guild_id, user_id, role_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }
    };
}
