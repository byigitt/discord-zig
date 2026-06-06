const std = @import("std");
const Api = @import("../../core/api.zig");
const Routes = @import("../routes.zig");
const Types = @import("../../models/types.zig");
const Interactions = @import("../../interactions/mod.zig");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;

const Root = @import("../client.zig");
const Response = Root.Response;

pub fn Methods(comptime Client: type) type {
    return struct {
        pub fn createMessageWithFiles(
            self: *Client,
            channel_id: Snowflake,
            payload: Types.CreateMessage,
            files: []const Types.UploadFile,
        ) !Response {
            const route = try Routes.createMessage(self.allocator, channel_id);
            defer route.deinit(self.allocator);

            return self.requestMultipart(route, payload, files);
        }

        pub fn createMessageWithFilePaths(
            self: *Client,
            channel_id: Snowflake,
            payload: Types.CreateMessage,
            files: []const Types.UploadFilePath,
        ) !Response {
            const route = try Routes.createMessage(self.allocator, channel_id);
            defer route.deinit(self.allocator);

            return self.requestMultipartFilePaths(route, payload, files);
        }

        pub fn getMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Response {
            const route = try Routes.channelMessage(self.allocator, channel_id, message_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listMessages(self: *Client, channel_id: Snowflake) !Response {
            return self.listMessagesWithOptions(channel_id, .{});
        }

        pub fn listMessagesWithOptions(self: *Client, channel_id: Snowflake, options: Types.ListMessages) !Response {
            const route = try Routes.channelMessagesWithOptions(self.allocator, channel_id, options);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn bulkDeleteMessages(self: *Client, channel_id: Snowflake, messages: []const Snowflake) !Response {
            const route = try Routes.bulkDeleteMessages(self.allocator, channel_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, Types.BulkDeleteMessages{ .messages = messages });
        }

        pub fn triggerTyping(self: *Client, channel_id: Snowflake) !Response {
            const route = try Routes.triggerTyping(self.allocator, channel_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn createThread(self: *Client, channel_id: Snowflake, payload: Types.CreateThread) !Response {
            const route = try Routes.createThread(self.allocator, channel_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn createForumThread(self: *Client, channel_id: Snowflake, payload: Types.CreateForumThread) !Response {
            const route = try Routes.createThread(self.allocator, channel_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn startThreadInForum(self: *Client, channel_id: Snowflake, payload: Types.CreateForumThread) !Response {
            return self.createForumThread(channel_id, payload);
        }

        pub fn startThreadInMedia(self: *Client, channel_id: Snowflake, payload: Types.CreateForumThread) !Response {
            return self.createForumThread(channel_id, payload);
        }

        pub fn listActiveGuildThreads(self: *Client, guild_id: Snowflake) !Response {
            const route = try Routes.activeGuildThreads(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn joinThread(self: *Client, thread_id: Snowflake) !Response {
            const route = try Routes.joinThread(self.allocator, thread_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn leaveThread(self: *Client, thread_id: Snowflake) !Response {
            const route = try Routes.leaveThread(self.allocator, thread_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn addThreadMember(self: *Client, thread_id: Snowflake, user_id: Snowflake) !Response {
            const route = try Routes.addThreadMember(self.allocator, thread_id, user_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn getThreadMember(self: *Client, thread_id: Snowflake, user_id: Snowflake) !Response {
            const route = try Routes.getThreadMember(self.allocator, thread_id, user_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn removeThreadMember(self: *Client, thread_id: Snowflake, user_id: Snowflake) !Response {
            const route = try Routes.removeThreadMember(self.allocator, thread_id, user_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listThreadMembers(self: *Client, thread_id: Snowflake) !Response {
            const route = try Routes.threadMembers(self.allocator, thread_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listThreadMembersWithOptions(
            self: *Client,
            thread_id: Snowflake,
            options: Types.ListThreadMembers,
        ) !Response {
            const route = try Routes.threadMembersWithOptions(self.allocator, thread_id, options);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listPublicArchivedThreads(
            self: *Client,
            channel_id: Snowflake,
            options: Types.ListArchivedThreads,
        ) !Response {
            const route = try Routes.publicArchivedThreads(self.allocator, channel_id, options);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listPrivateArchivedThreads(
            self: *Client,
            channel_id: Snowflake,
            options: Types.ListArchivedThreads,
        ) !Response {
            const route = try Routes.privateArchivedThreads(self.allocator, channel_id, options);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listJoinedPrivateArchivedThreads(
            self: *Client,
            channel_id: Snowflake,
            options: Types.ListArchivedThreads,
        ) !Response {
            const route = try Routes.joinedPrivateArchivedThreads(self.allocator, channel_id, options);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listPinnedMessages(self: *Client, channel_id: Snowflake) !Response {
            const route = try Routes.pinnedMessages(self.allocator, channel_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listChannelPins(self: *Client, channel_id: Snowflake, options: Types.ListChannelPins) !Response {
            const route = try Routes.channelPins(self.allocator, channel_id, options);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn pinMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Response {
            const route = try Routes.pinMessage(self.allocator, channel_id, message_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn unpinMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Response {
            const route = try Routes.unpinMessage(self.allocator, channel_id, message_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn createThreadFromMessage(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            payload: Types.CreateThreadFromMessage,
        ) !Response {
            const route = try Routes.createThreadFromMessage(self.allocator, channel_id, message_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn addGroupDmRecipient(
            self: *Client,
            channel_id: Snowflake,
            user_id: Snowflake,
            payload: Types.AddGroupDmRecipient,
        ) !Response {
            const route = try Routes.addGroupDmRecipient(self.allocator, channel_id, user_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn removeGroupDmRecipient(self: *Client, channel_id: Snowflake, user_id: Snowflake) !Response {
            const route = try Routes.removeGroupDmRecipient(self.allocator, channel_id, user_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listChannelInvites(self: *Client, channel_id: Snowflake) !Response {
            const route = try Routes.channelInvites(self.allocator, channel_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn createChannelInvite(self: *Client, channel_id: Snowflake, payload: Types.CreateChannelInvite) !Response {
            const route = try Routes.createChannelInvite(self.allocator, channel_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn listChannelWebhooks(self: *Client, channel_id: Snowflake) !Response {
            const route = try Routes.channelWebhooks(self.allocator, channel_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn createWebhook(self: *Client, channel_id: Snowflake, payload: Types.CreateWebhook) !Response {
            const route = try Routes.createWebhook(self.allocator, channel_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn listGuildWebhooks(self: *Client, guild_id: Snowflake) !Response {
            const route = try Routes.guildWebhooks(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn getWebhook(self: *Client, webhook_id: Snowflake) !Response {
            const route = try Routes.webhook(self.allocator, webhook_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn editWebhook(self: *Client, webhook_id: Snowflake, payload: Types.EditWebhook) !Response {
            const route = try Routes.editWebhook(self.allocator, webhook_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn deleteWebhook(self: *Client, webhook_id: Snowflake) !Response {
            const route = try Routes.deleteWebhook(self.allocator, webhook_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn getWebhookWithToken(self: *Client, webhook_id: Snowflake, webhook_token: []const u8) !Response {
            const route = try Routes.webhookWithToken(self.allocator, webhook_id, webhook_token);
            defer route.deinit(self.allocator);
            return self.requestWithToken(route, "", null, null);
        }

        pub fn editWebhookWithToken(
            self: *Client,
            webhook_id: Snowflake,
            webhook_token: []const u8,
            payload: Types.EditWebhookWithToken,
        ) !Response {
            const route = try Routes.editWebhookWithToken(self.allocator, webhook_id, webhook_token);
            defer route.deinit(self.allocator);
            return self.requestJsonWithToken(route, "", payload);
        }

        pub fn deleteWebhookWithToken(self: *Client, webhook_id: Snowflake, webhook_token: []const u8) !Response {
            const route = try Routes.deleteWebhookWithToken(self.allocator, webhook_id, webhook_token);
            defer route.deinit(self.allocator);
            return self.requestWithToken(route, "", null, null);
        }

        pub fn executeWebhook(
            self: *Client,
            webhook_id: Snowflake,
            webhook_token: []const u8,
            payload: Types.ExecuteWebhook,
        ) !Response {
            const route = try Routes.executeWebhook(self.allocator, webhook_id, webhook_token);
            defer route.deinit(self.allocator);
            return self.requestJsonWithToken(route, "", payload);
        }

        pub fn executeWebhookWithOptions(
            self: *Client,
            webhook_id: Snowflake,
            webhook_token: []const u8,
            options: Types.ExecuteWebhookQuery,
            payload: Types.ExecuteWebhook,
        ) !Response {
            const route = try Routes.executeWebhookWithOptions(self.allocator, webhook_id, webhook_token, options);
            defer route.deinit(self.allocator);
            return self.requestJsonWithToken(route, "", payload);
        }

        pub fn executeWebhookWithFiles(
            self: *Client,
            webhook_id: Snowflake,
            webhook_token: []const u8,
            payload: Types.ExecuteWebhook,
            files: []const Types.UploadFile,
        ) !Response {
            const route = try Routes.executeWebhook(self.allocator, webhook_id, webhook_token);
            defer route.deinit(self.allocator);
            return self.requestWebhookMultipartWithToken(route, "", payload, files);
        }

        pub fn executeWebhookWithOptionsAndFiles(
            self: *Client,
            webhook_id: Snowflake,
            webhook_token: []const u8,
            options: Types.ExecuteWebhookQuery,
            payload: Types.ExecuteWebhook,
            files: []const Types.UploadFile,
        ) !Response {
            const route = try Routes.executeWebhookWithOptions(self.allocator, webhook_id, webhook_token, options);
            defer route.deinit(self.allocator);
            return self.requestWebhookMultipartWithToken(route, "", payload, files);
        }

        pub fn getWebhookMessage(
            self: *Client,
            webhook_id: Snowflake,
            webhook_token: []const u8,
            message_id: Snowflake,
        ) !Response {
            const route = try Routes.getWebhookMessage(self.allocator, webhook_id, webhook_token, message_id);
            defer route.deinit(self.allocator);
            return self.requestWithToken(route, "", null, null);
        }

        pub fn editWebhookMessage(
            self: *Client,
            webhook_id: Snowflake,
            webhook_token: []const u8,
            message_id: Snowflake,
            payload: Types.EditMessage,
        ) !Response {
            const route = try Routes.editWebhookMessage(self.allocator, webhook_id, webhook_token, message_id);
            defer route.deinit(self.allocator);
            return self.requestJsonWithToken(route, "", payload);
        }

        pub fn deleteWebhookMessage(
            self: *Client,
            webhook_id: Snowflake,
            webhook_token: []const u8,
            message_id: Snowflake,
        ) !Response {
            const route = try Routes.deleteWebhookMessage(self.allocator, webhook_id, webhook_token, message_id);
            defer route.deinit(self.allocator);
            return self.requestWithToken(route, "", null, null);
        }

        pub fn listGuildInvites(self: *Client, guild_id: Snowflake) !Response {
            const route = try Routes.guildInvites(self.allocator, guild_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn getInvite(self: *Client, code: []const u8) !Response {
            const route = try Routes.invite(self.allocator, code);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn getInviteWithOptions(self: *Client, code: []const u8, options: Types.GetInvite) !Response {
            const route = try Routes.inviteWithOptions(self.allocator, code, options);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn deleteInvite(self: *Client, code: []const u8) !Response {
            const route = try Routes.deleteInvite(self.allocator, code);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn getInviteTargetUsers(self: *Client, code: []const u8) !Response {
            const route = try Routes.inviteTargetUsers(self.allocator, code);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn updateInviteTargetUsers(self: *Client, code: []const u8, file: Types.UploadFile) !Response {
            const route = try Routes.updateInviteTargetUsers(self.allocator, code);
            defer route.deinit(self.allocator);
            return self.requestInviteTargetUsersMultipart(route, file);
        }

        pub fn getInviteTargetUsersJobStatus(self: *Client, code: []const u8) !Response {
            const route = try Routes.inviteTargetUsersJobStatus(self.allocator, code);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn deleteMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Response {
            const route = try Routes.deleteMessage(self.allocator, channel_id, message_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn editMessage(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            payload: Types.EditMessage,
        ) !Response {
            const route = try Routes.editMessage(self.allocator, channel_id, message_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn crosspostMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Response {
            const route = try Routes.crosspostMessage(self.allocator, channel_id, message_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn createReaction(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            emoji: []const u8,
        ) !Response {
            const route = try Routes.createReaction(self.allocator, channel_id, message_id, emoji);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn deleteOwnReaction(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            emoji: []const u8,
        ) !Response {
            const route = try Routes.deleteOwnReaction(self.allocator, channel_id, message_id, emoji);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn deleteUserReaction(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            emoji: []const u8,
            user_id: Snowflake,
        ) !Response {
            const route = try Routes.deleteUserReaction(self.allocator, channel_id, message_id, emoji, user_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listReactions(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            emoji: []const u8,
            options: Types.ListReactions,
        ) !Response {
            const route = try Routes.listReactions(self.allocator, channel_id, message_id, emoji, options);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn deleteAllReactions(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Response {
            const route = try Routes.deleteAllReactions(self.allocator, channel_id, message_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn deleteAllReactionsForEmoji(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            emoji: []const u8,
        ) !Response {
            const route = try Routes.deleteAllReactionsForEmoji(self.allocator, channel_id, message_id, emoji);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listPollAnswerVoters(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            answer_id: u32,
            options: Types.ListPollAnswerVoters,
        ) !Response {
            const route = try Routes.pollAnswerVoters(self.allocator, channel_id, message_id, answer_id, options);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn endPoll(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Response {
            const route = try Routes.endPoll(self.allocator, channel_id, message_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listGlobalApplicationCommands(self: *Client, application_id: Snowflake) !Response {
            const route = try Routes.globalApplicationCommands(self.allocator, application_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }
    };
}
