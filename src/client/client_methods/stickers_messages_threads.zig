const std = @import("std");
const Intents = @import("../../core/intents.zig");
const Rest = @import("../../rest/client.zig");
const HttpTransport = @import("../../rest/http_transport.zig").HttpTransport;
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
        pub fn createGuildSticker(
            self: *Client,
            guild_id: Snowflake,
            payload: Types.CreateGuildSticker,
            file: Types.UploadFile,
        ) !Rest.Response {
            return self.rest.createGuildSticker(guild_id, payload, file);
        }

        pub fn editGuildSticker(
            self: *Client,
            guild_id: Snowflake,
            sticker_id: Snowflake,
            payload: Types.EditGuildSticker,
        ) !Rest.Response {
            return self.rest.editGuildSticker(guild_id, sticker_id, payload);
        }

        pub fn renameSticker(self: *Client, guild_id: Snowflake, sticker_id: Snowflake, name: []const u8) !Rest.Response {
            return self.editGuildSticker(guild_id, sticker_id, Types.EditGuildSticker.init().withName(name));
        }

        pub fn setStickerDescription(
            self: *Client,
            guild_id: Snowflake,
            sticker_id: Snowflake,
            description: []const u8,
        ) !Rest.Response {
            return self.editGuildSticker(guild_id, sticker_id, Types.EditGuildSticker.init().withDescription(description));
        }

        pub fn setStickerTags(
            self: *Client,
            guild_id: Snowflake,
            sticker_id: Snowflake,
            tags: []const u8,
        ) !Rest.Response {
            return self.editGuildSticker(guild_id, sticker_id, Types.EditGuildSticker.init().withTags(tags));
        }

        pub fn deleteGuildSticker(self: *Client, guild_id: Snowflake, sticker_id: Snowflake) !Rest.Response {
            return self.rest.deleteGuildSticker(guild_id, sticker_id);
        }

        pub fn listDefaultSoundboardSounds(self: *Client) !Rest.Response {
            return self.rest.listDefaultSoundboardSounds();
        }

        pub fn fetchDefaultSoundboardSounds(self: *Client) !Rest.Response {
            return self.listDefaultSoundboardSounds();
        }

        pub fn listGuildSoundboardSounds(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.listGuildSoundboardSounds(guild_id);
        }

        pub fn fetchGuildSoundboardSounds(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.listGuildSoundboardSounds(guild_id);
        }

        pub fn getGuildSoundboardSound(self: *Client, guild_id: Snowflake, sound_id: Snowflake) !Rest.Response {
            return self.rest.getGuildSoundboardSound(guild_id, sound_id);
        }

        pub fn fetchGuildSoundboardSound(self: *Client, guild_id: Snowflake, sound_id: Snowflake) !Rest.Response {
            return self.getGuildSoundboardSound(guild_id, sound_id);
        }

        pub fn createGuildSoundboardSound(
            self: *Client,
            guild_id: Snowflake,
            payload: Types.CreateGuildSoundboardSound,
        ) !Rest.Response {
            return self.rest.createGuildSoundboardSound(guild_id, payload);
        }

        pub fn createSoundboardSoundWithData(
            self: *Client,
            guild_id: Snowflake,
            name: []const u8,
            sound: []const u8,
        ) !Rest.Response {
            return self.createGuildSoundboardSound(guild_id, Types.CreateGuildSoundboardSound.init(name, sound));
        }

        pub fn editGuildSoundboardSound(
            self: *Client,
            guild_id: Snowflake,
            sound_id: Snowflake,
            payload: Types.EditGuildSoundboardSound,
        ) !Rest.Response {
            return self.rest.editGuildSoundboardSound(guild_id, sound_id, payload);
        }

        pub fn renameSoundboardSound(
            self: *Client,
            guild_id: Snowflake,
            sound_id: Snowflake,
            name: []const u8,
        ) !Rest.Response {
            return self.editGuildSoundboardSound(guild_id, sound_id, Types.EditGuildSoundboardSound.init().withName(name));
        }

        pub fn deleteGuildSoundboardSound(self: *Client, guild_id: Snowflake, sound_id: Snowflake) !Rest.Response {
            return self.rest.deleteGuildSoundboardSound(guild_id, sound_id);
        }

        pub fn sendFiles(
            self: *Client,
            channel_id: Snowflake,
            payload: Types.CreateMessage,
            files: []const Types.UploadFile,
        ) !Rest.Response {
            return self.rest.createMessageWithFiles(channel_id, payload, files);
        }

        pub fn sendMessageWithFiles(
            self: *Client,
            channel_id: Snowflake,
            payload: Types.CreateMessage,
            files: []const Types.UploadFile,
        ) !Rest.Response {
            return self.sendFiles(channel_id, payload, files);
        }

        pub fn sendWithFiles(
            self: *Client,
            channel_id: Snowflake,
            payload: Types.CreateMessage,
            files: []const Types.UploadFile,
        ) !Rest.Response {
            return self.sendFiles(channel_id, payload, files);
        }

        pub fn sendFilePaths(
            self: *Client,
            channel_id: Snowflake,
            payload: Types.CreateMessage,
            files: []const Types.UploadFilePath,
        ) !Rest.Response {
            return self.rest.createMessageWithFilePaths(channel_id, payload, files);
        }

        pub fn sendMessageWithFilePaths(
            self: *Client,
            channel_id: Snowflake,
            payload: Types.CreateMessage,
            files: []const Types.UploadFilePath,
        ) !Rest.Response {
            return self.sendFilePaths(channel_id, payload, files);
        }

        pub fn sendWithFilePaths(
            self: *Client,
            channel_id: Snowflake,
            payload: Types.CreateMessage,
            files: []const Types.UploadFilePath,
        ) !Rest.Response {
            return self.sendFilePaths(channel_id, payload, files);
        }

        pub fn reply(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            payload: Types.CreateMessage,
        ) !Rest.Response {
            var reply_payload = payload;
            reply_payload.message_reference = .{ .type = .default, .message_id = message_id, .channel_id = channel_id };
            return self.rest.createMessage(channel_id, reply_payload);
        }

        pub fn replyMessage(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            payload: Types.CreateMessage,
        ) !Rest.Response {
            return self.reply(channel_id, message_id, payload);
        }

        pub fn replyWithContent(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            content: []const u8,
        ) !Rest.Response {
            return self.reply(channel_id, message_id, Types.CreateMessage.init(content));
        }

        pub fn replyMessageWithContent(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            content: []const u8,
        ) !Rest.Response {
            return self.replyWithContent(channel_id, message_id, content);
        }

        pub fn replyText(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            content: []const u8,
        ) !Rest.Response {
            return self.replyWithContent(channel_id, message_id, content);
        }

        pub fn forwardMessage(
            self: *Client,
            target_channel_id: Snowflake,
            source_channel_id: Snowflake,
            message_id: Snowflake,
        ) !Rest.Response {
            return self.rest.createMessage(
                target_channel_id,
                Types.CreateMessage.empty().withReference(Types.MessageReference.forward(message_id, source_channel_id)),
            );
        }

        pub fn forward(
            self: *Client,
            target_channel_id: Snowflake,
            source_channel_id: Snowflake,
            message_id: Snowflake,
        ) !Rest.Response {
            return self.forwardMessage(target_channel_id, source_channel_id, message_id);
        }

        pub fn editMessage(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            payload: Types.EditMessage,
        ) !Rest.Response {
            return self.rest.editMessage(channel_id, message_id, payload);
        }

        pub fn edit(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            payload: Types.EditMessage,
        ) !Rest.Response {
            return self.editMessage(channel_id, message_id, payload);
        }

        pub fn editMessageWithContent(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            content: []const u8,
        ) !Rest.Response {
            return self.editMessage(channel_id, message_id, Types.EditMessage.init().withContent(content));
        }

        pub fn editWithContent(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            content: []const u8,
        ) !Rest.Response {
            return self.editMessageWithContent(channel_id, message_id, content);
        }

        pub fn editText(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            content: []const u8,
        ) !Rest.Response {
            return self.editMessageWithContent(channel_id, message_id, content);
        }

        pub fn setEmbedsSuppressed(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            suppressed: bool,
        ) !Rest.Response {
            return self.editMessage(
                channel_id,
                message_id,
                Types.EditMessage.init().withFlags(if (suppressed) Types.MessageFlags.suppress_embeds else 0),
            );
        }

        pub fn suppressEmbeds(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
            return self.setEmbedsSuppressed(channel_id, message_id, true);
        }

        pub fn unsuppressEmbeds(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
            return self.setEmbedsSuppressed(channel_id, message_id, false);
        }

        pub fn deleteMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
            return self.rest.deleteMessage(channel_id, message_id);
        }

        pub fn delete(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
            return self.deleteMessage(channel_id, message_id);
        }

        pub fn crosspostMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
            return self.rest.crosspostMessage(channel_id, message_id);
        }

        pub fn crosspost(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
            return self.crosspostMessage(channel_id, message_id);
        }

        pub fn publishMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
            return self.crosspostMessage(channel_id, message_id);
        }

        pub fn publish(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
            return self.publishMessage(channel_id, message_id);
        }

        pub fn getMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
            return self.rest.getMessage(channel_id, message_id);
        }

        pub fn fetchMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
            return self.getMessage(channel_id, message_id);
        }

        pub fn listMessages(self: *Client, channel_id: Snowflake) !Rest.Response {
            return self.rest.listMessages(channel_id);
        }

        pub fn listMessagesWithOptions(self: *Client, channel_id: Snowflake, options: Types.ListMessages) !Rest.Response {
            return self.rest.listMessagesWithOptions(channel_id, options);
        }

        pub fn fetchMessages(self: *Client, channel_id: Snowflake, options: Types.ListMessages) !Rest.Response {
            return self.listMessagesWithOptions(channel_id, options);
        }

        pub fn bulkDeleteMessages(self: *Client, channel_id: Snowflake, messages: []const Snowflake) !Rest.Response {
            return self.rest.bulkDeleteMessages(channel_id, messages);
        }

        pub fn bulkDelete(self: *Client, channel_id: Snowflake, messages: []const Snowflake) !Rest.Response {
            return self.bulkDeleteMessages(channel_id, messages);
        }

        pub fn sendTyping(self: *Client, channel_id: Snowflake) !Rest.Response {
            return self.rest.triggerTyping(channel_id);
        }

        pub fn triggerTyping(self: *Client, channel_id: Snowflake) !Rest.Response {
            return self.sendTyping(channel_id);
        }

        pub fn listPinnedMessages(self: *Client, channel_id: Snowflake) !Rest.Response {
            return self.rest.listPinnedMessages(channel_id);
        }

        pub fn fetchPinnedMessages(self: *Client, channel_id: Snowflake) !Rest.Response {
            return self.listPinnedMessages(channel_id);
        }

        pub fn listChannelPins(self: *Client, channel_id: Snowflake, options: Types.ListChannelPins) !Rest.Response {
            return self.rest.listChannelPins(channel_id, options);
        }

        pub fn fetchPins(self: *Client, channel_id: Snowflake, options: Types.ListChannelPins) !Rest.Response {
            return self.listChannelPins(channel_id, options);
        }

        pub fn pinMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
            return self.rest.pinMessage(channel_id, message_id);
        }

        pub fn pin(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
            return self.pinMessage(channel_id, message_id);
        }

        pub fn unpinMessage(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
            return self.rest.unpinMessage(channel_id, message_id);
        }

        pub fn unpin(self: *Client, channel_id: Snowflake, message_id: Snowflake) !Rest.Response {
            return self.unpinMessage(channel_id, message_id);
        }

        pub fn createThread(self: *Client, channel_id: Snowflake, payload: Types.CreateThread) !Rest.Response {
            return self.rest.createThread(channel_id, payload);
        }

        pub fn createThreadWithName(self: *Client, channel_id: Snowflake, name: []const u8) !Rest.Response {
            return self.createThread(channel_id, Types.CreateThread.init(name));
        }

        pub fn createForumThread(self: *Client, channel_id: Snowflake, payload: Types.CreateForumThread) !Rest.Response {
            return self.rest.createForumThread(channel_id, payload);
        }

        pub fn startThreadInForum(self: *Client, channel_id: Snowflake, payload: Types.CreateForumThread) !Rest.Response {
            return self.createForumThread(channel_id, payload);
        }

        pub fn startThreadInMedia(self: *Client, channel_id: Snowflake, payload: Types.CreateForumThread) !Rest.Response {
            return self.createForumThread(channel_id, payload);
        }

        pub fn listActiveGuildThreads(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.listActiveGuildThreads(guild_id);
        }

        pub fn fetchActiveThreads(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.listActiveGuildThreads(guild_id);
        }

        pub fn joinThread(self: *Client, thread_id: Snowflake) !Rest.Response {
            return self.rest.joinThread(thread_id);
        }

        pub fn leaveThread(self: *Client, thread_id: Snowflake) !Rest.Response {
            return self.rest.leaveThread(thread_id);
        }

        pub fn addThreadMember(self: *Client, thread_id: Snowflake, user_id: Snowflake) !Rest.Response {
            return self.rest.addThreadMember(thread_id, user_id);
        }

        pub fn getThreadMember(self: *Client, thread_id: Snowflake, user_id: Snowflake) !Rest.Response {
            return self.rest.getThreadMember(thread_id, user_id);
        }

        pub fn fetchThreadMember(self: *Client, thread_id: Snowflake, user_id: Snowflake) !Rest.Response {
            return self.getThreadMember(thread_id, user_id);
        }

        pub fn removeThreadMember(self: *Client, thread_id: Snowflake, user_id: Snowflake) !Rest.Response {
            return self.rest.removeThreadMember(thread_id, user_id);
        }

        pub fn listThreadMembers(self: *Client, thread_id: Snowflake) !Rest.Response {
            return self.rest.listThreadMembers(thread_id);
        }

        pub fn fetchThreadMembers(self: *Client, thread_id: Snowflake) !Rest.Response {
            return self.listThreadMembers(thread_id);
        }

        pub fn listThreadMembersWithOptions(
            self: *Client,
            thread_id: Snowflake,
            options: Types.ListThreadMembers,
        ) !Rest.Response {
            return self.rest.listThreadMembersWithOptions(thread_id, options);
        }

        pub fn fetchThreadMembersWithOptions(
            self: *Client,
            thread_id: Snowflake,
            options: Types.ListThreadMembers,
        ) !Rest.Response {
            return self.listThreadMembersWithOptions(thread_id, options);
        }

        pub fn listPublicArchivedThreads(
            self: *Client,
            channel_id: Snowflake,
            options: Types.ListArchivedThreads,
        ) !Rest.Response {
            return self.rest.listPublicArchivedThreads(channel_id, options);
        }

        pub fn fetchPublicArchivedThreads(
            self: *Client,
            channel_id: Snowflake,
            options: Types.ListArchivedThreads,
        ) !Rest.Response {
            return self.listPublicArchivedThreads(channel_id, options);
        }

        pub fn listPrivateArchivedThreads(
            self: *Client,
            channel_id: Snowflake,
            options: Types.ListArchivedThreads,
        ) !Rest.Response {
            return self.rest.listPrivateArchivedThreads(channel_id, options);
        }

        pub fn fetchPrivateArchivedThreads(
            self: *Client,
            channel_id: Snowflake,
            options: Types.ListArchivedThreads,
        ) !Rest.Response {
            return self.listPrivateArchivedThreads(channel_id, options);
        }

        pub fn listJoinedPrivateArchivedThreads(
            self: *Client,
            channel_id: Snowflake,
            options: Types.ListArchivedThreads,
        ) !Rest.Response {
            return self.rest.listJoinedPrivateArchivedThreads(channel_id, options);
        }

        pub fn fetchJoinedPrivateArchivedThreads(
            self: *Client,
            channel_id: Snowflake,
            options: Types.ListArchivedThreads,
        ) !Rest.Response {
            return self.listJoinedPrivateArchivedThreads(channel_id, options);
        }

        pub fn createThreadFromMessage(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            payload: Types.CreateThreadFromMessage,
        ) !Rest.Response {
            return self.rest.createThreadFromMessage(channel_id, message_id, payload);
        }

        pub fn startThreadFromMessage(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            payload: Types.CreateThreadFromMessage,
        ) !Rest.Response {
            return self.createThreadFromMessage(channel_id, message_id, payload);
        }
    };
}
