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
        pub fn listGuildApplicationCommandPermissions(
            self: *Client,
            bearer_token: []const u8,
            application_id: Snowflake,
            guild_id: Snowflake,
        ) !Rest.Response {
            return self.rest.listGuildApplicationCommandPermissions(bearer_token, application_id, guild_id);
        }

        pub fn fetchGuildApplicationCommandPermissions(
            self: *Client,
            bearer_token: []const u8,
            application_id: Snowflake,
            guild_id: Snowflake,
        ) !Rest.Response {
            return self.listGuildApplicationCommandPermissions(bearer_token, application_id, guild_id);
        }

        pub fn getApplicationCommandPermissions(
            self: *Client,
            bearer_token: []const u8,
            application_id: Snowflake,
            guild_id: Snowflake,
            command_id: Snowflake,
        ) !Rest.Response {
            return self.rest.getApplicationCommandPermissions(bearer_token, application_id, guild_id, command_id);
        }

        pub fn fetchApplicationCommandPermissions(
            self: *Client,
            bearer_token: []const u8,
            application_id: Snowflake,
            guild_id: Snowflake,
            command_id: Snowflake,
        ) !Rest.Response {
            return self.getApplicationCommandPermissions(bearer_token, application_id, guild_id, command_id);
        }

        pub fn editApplicationCommandPermissions(
            self: *Client,
            bearer_token: []const u8,
            application_id: Snowflake,
            guild_id: Snowflake,
            command_id: Snowflake,
            permissions: []const Interactions.ApplicationCommandPermission,
        ) !Rest.Response {
            return self.rest.editApplicationCommandPermissions(bearer_token, application_id, guild_id, command_id, permissions);
        }

        pub fn createInteractionResponse(
            self: *Client,
            interaction_id: Snowflake,
            token: []const u8,
            response_payload: Interactions.InteractionResponse,
        ) !Rest.Response {
            return self.rest.createInteractionResponse(interaction_id, token, response_payload);
        }

        pub fn replyInteraction(
            self: *Client,
            interaction_id: Snowflake,
            token: []const u8,
            response_payload: Interactions.InteractionResponse,
        ) !Rest.Response {
            var payload = response_payload;
            payload.type = .channel_message_with_source;
            return self.createInteractionResponse(interaction_id, token, payload);
        }

        pub fn deferInteractionReply(
            self: *Client,
            interaction_id: Snowflake,
            token: []const u8,
            ephemeral: bool,
        ) !Rest.Response {
            return self.createInteractionResponse(interaction_id, token, Interactions.InteractionResponse.deferredMessage(ephemeral));
        }

        pub fn deferInteractionUpdate(self: *Client, interaction_id: Snowflake, token: []const u8) !Rest.Response {
            return self.createInteractionResponse(interaction_id, token, Interactions.InteractionResponse.deferredUpdate());
        }

        pub fn updateInteractionMessage(
            self: *Client,
            interaction_id: Snowflake,
            token: []const u8,
            response_payload: Interactions.InteractionResponse,
        ) !Rest.Response {
            var payload = response_payload;
            payload.type = .update_message;
            return self.createInteractionResponse(interaction_id, token, payload);
        }

        pub fn autocompleteInteraction(
            self: *Client,
            interaction_id: Snowflake,
            token: []const u8,
            choices: []const Interactions.CommandChoice,
        ) !Rest.Response {
            return self.createInteractionResponse(interaction_id, token, Interactions.InteractionResponse.autocomplete(choices));
        }

        pub fn showModal(
            self: *Client,
            interaction_id: Snowflake,
            token: []const u8,
            response_payload: Interactions.InteractionResponse,
        ) !Rest.Response {
            var payload = response_payload;
            payload.type = .modal;
            return self.createInteractionResponse(interaction_id, token, payload);
        }

        pub fn getOriginalInteractionResponse(
            self: *Client,
            application_id: Snowflake,
            token: []const u8,
        ) !Rest.Response {
            return self.rest.getOriginalInteractionResponse(application_id, token);
        }

        pub fn fetchOriginalInteractionResponse(
            self: *Client,
            application_id: Snowflake,
            token: []const u8,
        ) !Rest.Response {
            return self.getOriginalInteractionResponse(application_id, token);
        }

        pub fn fetchInteractionReply(self: *Client, token: []const u8) !Rest.Response {
            return self.getOriginalInteractionResponse(try self.requireCurrentApplicationId(), token);
        }

        pub fn editOriginalInteractionResponse(
            self: *Client,
            application_id: Snowflake,
            token: []const u8,
            payload: Types.EditMessage,
        ) !Rest.Response {
            return self.rest.editOriginalInteractionResponse(application_id, token, payload);
        }

        pub fn editInteractionReply(self: *Client, token: []const u8, payload: Types.EditMessage) !Rest.Response {
            return self.editOriginalInteractionResponse(try self.requireCurrentApplicationId(), token, payload);
        }

        pub fn deleteOriginalInteractionResponse(
            self: *Client,
            application_id: Snowflake,
            token: []const u8,
        ) !Rest.Response {
            return self.rest.deleteOriginalInteractionResponse(application_id, token);
        }

        pub fn deleteInteractionReply(self: *Client, token: []const u8) !Rest.Response {
            return self.deleteOriginalInteractionResponse(try self.requireCurrentApplicationId(), token);
        }

        pub fn createFollowupMessage(
            self: *Client,
            application_id: Snowflake,
            token: []const u8,
            payload: Types.ExecuteWebhook,
        ) !Rest.Response {
            return self.rest.createFollowupMessage(application_id, token, payload);
        }

        pub fn createFollowupMessageWithContent(
            self: *Client,
            application_id: Snowflake,
            token: []const u8,
            content: []const u8,
        ) !Rest.Response {
            return self.createFollowupMessage(application_id, token, Types.ExecuteWebhook.init(content));
        }

        pub fn followUpInteraction(self: *Client, token: []const u8, payload: Types.ExecuteWebhook) !Rest.Response {
            return self.createFollowupMessage(try self.requireCurrentApplicationId(), token, payload);
        }

        pub fn followUpInteractionWithContent(self: *Client, token: []const u8, content: []const u8) !Rest.Response {
            return self.followUpInteraction(token, Types.ExecuteWebhook.init(content));
        }

        pub fn getFollowupMessage(
            self: *Client,
            application_id: Snowflake,
            token: []const u8,
            message_id: Snowflake,
        ) !Rest.Response {
            return self.rest.getFollowupMessage(application_id, token, message_id);
        }

        pub fn fetchFollowupMessage(
            self: *Client,
            application_id: Snowflake,
            token: []const u8,
            message_id: Snowflake,
        ) !Rest.Response {
            return self.getFollowupMessage(application_id, token, message_id);
        }

        pub fn fetchFollowUpInteraction(self: *Client, token: []const u8, message_id: Snowflake) !Rest.Response {
            return self.getFollowupMessage(try self.requireCurrentApplicationId(), token, message_id);
        }

        pub fn editFollowupMessage(
            self: *Client,
            application_id: Snowflake,
            token: []const u8,
            message_id: Snowflake,
            payload: Types.EditMessage,
        ) !Rest.Response {
            return self.rest.editFollowupMessage(application_id, token, message_id, payload);
        }

        pub fn editFollowUpInteraction(
            self: *Client,
            token: []const u8,
            message_id: Snowflake,
            payload: Types.EditMessage,
        ) !Rest.Response {
            return self.editFollowupMessage(try self.requireCurrentApplicationId(), token, message_id, payload);
        }

        pub fn deleteFollowupMessage(
            self: *Client,
            application_id: Snowflake,
            token: []const u8,
            message_id: Snowflake,
        ) !Rest.Response {
            return self.rest.deleteFollowupMessage(application_id, token, message_id);
        }

        pub fn deleteFollowUpInteraction(self: *Client, token: []const u8, message_id: Snowflake) !Rest.Response {
            return self.deleteFollowupMessage(try self.requireCurrentApplicationId(), token, message_id);
        }

        pub fn requireCurrentApplicationId(self: *Client) !Snowflake {
            return self.currentApplicationId() orelse error.MissingCurrentApplication;
        }

        pub fn react(self: *Client, channel_id: Snowflake, message_id: Snowflake, emoji: []const u8) !Rest.Response {
            return self.rest.createReaction(channel_id, message_id, emoji);
        }

        pub fn addReaction(self: *Client, channel_id: Snowflake, message_id: Snowflake, emoji: []const u8) !Rest.Response {
            return self.react(channel_id, message_id, emoji);
        }

        pub fn unreact(self: *Client, channel_id: Snowflake, message_id: Snowflake, emoji: []const u8) !Rest.Response {
            return self.rest.deleteOwnReaction(channel_id, message_id, emoji);
        }

        pub fn deleteOwnReaction(self: *Client, channel_id: Snowflake, message_id: Snowflake, emoji: []const u8) !Rest.Response {
            return self.unreact(channel_id, message_id, emoji);
        }

        pub fn removeUserReaction(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            emoji: []const u8,
            user_id: Snowflake,
        ) !Rest.Response {
            return self.rest.deleteUserReaction(channel_id, message_id, emoji, user_id);
        }

        pub fn removeReaction(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            emoji: []const u8,
            user_id: Snowflake,
        ) !Rest.Response {
            return self.removeUserReaction(channel_id, message_id, emoji, user_id);
        }

        pub fn listReactions(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            emoji: []const u8,
            options: Types.ListReactions,
        ) !Rest.Response {
            return self.rest.listReactions(channel_id, message_id, emoji, options);
        }

        pub fn fetchReactions(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            emoji: []const u8,
            options: Types.ListReactions,
        ) !Rest.Response {
            return self.listReactions(channel_id, message_id, emoji, options);
        }

        pub fn clearReactions(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
            return self.rest.deleteAllReactions(channel_id, message_id);
        }

        pub fn deleteAllReactions(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
            return self.clearReactions(channel_id, message_id);
        }

        pub fn removeAllReactions(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
            return self.clearReactions(channel_id, message_id);
        }

        pub fn clearReactionsForEmoji(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            emoji: []const u8,
        ) !Rest.Response {
            return self.rest.deleteAllReactionsForEmoji(channel_id, message_id, emoji);
        }

        pub fn deleteAllReactionsForEmoji(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            emoji: []const u8,
        ) !Rest.Response {
            return self.clearReactionsForEmoji(channel_id, message_id, emoji);
        }

        pub fn listPollAnswerVoters(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            answer_id: u32,
            options: Types.ListPollAnswerVoters,
        ) !Rest.Response {
            return self.rest.listPollAnswerVoters(channel_id, message_id, answer_id, options);
        }

        pub fn fetchPollAnswerVoters(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            answer_id: u32,
            options: Types.ListPollAnswerVoters,
        ) !Rest.Response {
            return self.listPollAnswerVoters(channel_id, message_id, answer_id, options);
        }

        pub fn endPoll(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
            return self.rest.endPoll(channel_id, message_id);
        }

        pub fn getCachedUser(self: *Client, user_id: Snowflake) ?Types.User {
            return self.cache.getUser(user_id);
        }

        pub fn cachedUser(self: *Client, user_id: Snowflake) ?Types.User {
            return self.getCachedUser(user_id);
        }

        pub fn hasCachedUser(self: *Client, user_id: Snowflake) bool {
            return self.cache.hasUser(user_id);
        }

        pub fn getCurrentCachedUser(self: *Client) ?Types.User {
            return self.cache.getCurrentUser();
        }

        pub fn currentUser(self: *Client) ?Types.User {
            return self.getCurrentCachedUser();
        }

        pub fn me(self: *Client) ?Types.User {
            return self.getCurrentCachedUser();
        }

        pub fn currentUserId(self: *Client) ?Snowflake {
            return self.cache.currentUserId();
        }

        pub fn hasCurrentCachedUser(self: *Client) bool {
            return self.cache.hasCurrentUser();
        }

        pub fn getCurrentCachedApplication(self: *Client) ?Types.Application {
            return self.cache.getCurrentApplication();
        }

        pub fn currentApplication(self: *Client) ?Types.Application {
            return self.getCurrentCachedApplication();
        }

        pub fn currentApplicationId(self: *Client) ?Snowflake {
            return self.cache.currentApplicationId();
        }

        pub fn hasCurrentCachedApplication(self: *Client) bool {
            return self.cache.hasCurrentApplication();
        }

        pub fn getCachedGuild(self: *Client, guild_id: Snowflake) ?Types.Guild {
            return self.cache.getGuild(guild_id);
        }

        pub fn cachedGuild(self: *Client, guild_id: Snowflake) ?Types.Guild {
            return self.getCachedGuild(guild_id);
        }

        pub fn hasCachedGuild(self: *Client, guild_id: Snowflake) bool {
            return self.cache.hasGuild(guild_id);
        }

        pub fn getCachedChannel(self: *Client, channel_id: Snowflake) ?Types.Channel {
            return self.cache.getChannel(channel_id);
        }

        pub fn cachedChannel(self: *Client, channel_id: Snowflake) ?Types.Channel {
            return self.getCachedChannel(channel_id);
        }

        pub fn hasCachedChannel(self: *Client, channel_id: Snowflake) bool {
            return self.cache.hasChannel(channel_id);
        }

        pub fn getCachedMember(self: *Client, guild_id: Snowflake, user_id: Snowflake) ?Types.GuildMember {
            return self.cache.getMember(guild_id, user_id);
        }

        pub fn cachedMember(self: *Client, guild_id: Snowflake, user_id: Snowflake) ?Types.GuildMember {
            return self.getCachedMember(guild_id, user_id);
        }

        pub fn hasCachedMember(self: *Client, guild_id: Snowflake, user_id: Snowflake) bool {
            return self.cache.hasMember(guild_id, user_id);
        }

        pub fn getCachedRole(self: *Client, guild_id: Snowflake, role_id: Snowflake) ?Types.Role {
            return self.cache.getRole(guild_id, role_id);
        }

        pub fn cachedRole(self: *Client, guild_id: Snowflake, role_id: Snowflake) ?Types.Role {
            return self.getCachedRole(guild_id, role_id);
        }

        pub fn hasCachedRole(self: *Client, guild_id: Snowflake, role_id: Snowflake) bool {
            return self.cache.hasRole(guild_id, role_id);
        }

        pub fn getCachedEmoji(self: *Client, guild_id: Snowflake, emoji_id: Snowflake) ?Types.Emoji {
            return self.cache.getEmoji(guild_id, emoji_id);
        }

        pub fn cachedEmoji(self: *Client, guild_id: Snowflake, emoji_id: Snowflake) ?Types.Emoji {
            return self.getCachedEmoji(guild_id, emoji_id);
        }

        pub fn hasCachedEmoji(self: *Client, guild_id: Snowflake, emoji_id: Snowflake) bool {
            return self.cache.hasEmoji(guild_id, emoji_id);
        }

        pub fn getCachedSticker(self: *Client, guild_id: Snowflake, sticker_id: Snowflake) ?Types.Sticker {
            return self.cache.getSticker(guild_id, sticker_id);
        }

        pub fn cachedSticker(self: *Client, guild_id: Snowflake, sticker_id: Snowflake) ?Types.Sticker {
            return self.getCachedSticker(guild_id, sticker_id);
        }

        pub fn hasCachedSticker(self: *Client, guild_id: Snowflake, sticker_id: Snowflake) bool {
            return self.cache.hasSticker(guild_id, sticker_id);
        }

        pub fn getCachedScheduledEvent(self: *Client, guild_id: Snowflake, event_id: Snowflake) ?Types.GuildScheduledEvent {
            return self.cache.getScheduledEvent(guild_id, event_id);
        }

        pub fn cachedScheduledEvent(self: *Client, guild_id: Snowflake, event_id: Snowflake) ?Types.GuildScheduledEvent {
            return self.getCachedScheduledEvent(guild_id, event_id);
        }

        pub fn hasCachedScheduledEvent(self: *Client, guild_id: Snowflake, event_id: Snowflake) bool {
            return self.cache.hasScheduledEvent(guild_id, event_id);
        }

        pub fn getCachedStageInstance(self: *Client, guild_id: Snowflake, stage_instance_id: Snowflake) ?Types.StageInstance {
            return self.cache.getStageInstance(guild_id, stage_instance_id);
        }

        pub fn cachedStageInstance(self: *Client, guild_id: Snowflake, stage_instance_id: Snowflake) ?Types.StageInstance {
            return self.getCachedStageInstance(guild_id, stage_instance_id);
        }

        pub fn hasCachedStageInstance(self: *Client, guild_id: Snowflake, stage_instance_id: Snowflake) bool {
            return self.cache.hasStageInstance(guild_id, stage_instance_id);
        }

        pub fn getCachedInvite(self: *Client, code: []const u8) ?Types.Invite {
            return self.cache.getInvite(code);
        }

        pub fn cachedInvite(self: *Client, code: []const u8) ?Types.Invite {
            return self.getCachedInvite(code);
        }

        pub fn hasCachedInvite(self: *Client, code: []const u8) bool {
            return self.cache.hasInvite(code);
        }

        pub fn getCachedPresence(self: *Client, guild_id: Snowflake, user_id: Snowflake) ?Types.Presence {
            return self.cache.getPresence(guild_id, user_id);
        }

        pub fn cachedPresence(self: *Client, guild_id: Snowflake, user_id: Snowflake) ?Types.Presence {
            return self.getCachedPresence(guild_id, user_id);
        }

        pub fn hasCachedPresence(self: *Client, guild_id: Snowflake, user_id: Snowflake) bool {
            return self.cache.hasPresence(guild_id, user_id);
        }

        pub fn getCachedVoiceState(self: *Client, guild_id: Snowflake, user_id: Snowflake) ?Types.VoiceState {
            return self.cache.getVoiceState(guild_id, user_id);
        }

        pub fn cachedVoiceState(self: *Client, guild_id: Snowflake, user_id: Snowflake) ?Types.VoiceState {
            return self.getCachedVoiceState(guild_id, user_id);
        }

        pub fn hasCachedVoiceState(self: *Client, guild_id: Snowflake, user_id: Snowflake) bool {
            return self.cache.hasVoiceState(guild_id, user_id);
        }

        pub fn getCachedMessage(self: *Client, message_id: Snowflake) ?Types.Message {
            return self.cache.getMessage(message_id);
        }

        pub fn cachedMessage(self: *Client, message_id: Snowflake) ?Types.Message {
            return self.getCachedMessage(message_id);
        }

        pub fn hasCachedMessage(self: *Client, message_id: Snowflake) bool {
            return self.cache.hasMessage(message_id);
        }
    };
}
