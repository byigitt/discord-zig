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
const Cache = CacheModule.Cache;
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
        pub fn startThreadFromMessageWithName(
            self: *Client,
            channel_id: Snowflake,
            message_id: Snowflake,
            name: []const u8,
        ) !Rest.Response {
            return self.createThreadFromMessage(channel_id, message_id, Types.CreateThreadFromMessage.init(name));
        }

        pub fn addGroupDmRecipient(
            self: *Client,
            channel_id: Snowflake,
            user_id: Snowflake,
            payload: Types.AddGroupDmRecipient,
        ) !Rest.Response {
            return self.rest.addGroupDmRecipient(channel_id, user_id, payload);
        }

        pub fn removeGroupDmRecipient(self: *Client, channel_id: Snowflake, user_id: Snowflake) !Rest.Response {
            return self.rest.removeGroupDmRecipient(channel_id, user_id);
        }

        pub fn createInvite(self: *Client, channel_id: Snowflake, payload: Types.CreateChannelInvite) !Rest.Response {
            return self.rest.createChannelInvite(channel_id, payload);
        }

        pub fn createDefaultInvite(self: *Client, channel_id: Snowflake) !Rest.Response {
            return self.createInvite(channel_id, Types.CreateChannelInvite.init());
        }

        pub fn createInviteWithMaxUses(
            self: *Client,
            channel_id: Snowflake,
            max_uses: u16,
        ) !Rest.Response {
            return self.createInvite(channel_id, Types.CreateChannelInvite.init().withMaxUses(max_uses));
        }

        pub fn createInviteWithMaxAge(
            self: *Client,
            channel_id: Snowflake,
            max_age: u32,
        ) !Rest.Response {
            return self.createInvite(channel_id, Types.CreateChannelInvite.init().withMaxAge(max_age));
        }

        pub fn createUniqueInvite(self: *Client, channel_id: Snowflake) !Rest.Response {
            return self.createInvite(channel_id, Types.CreateChannelInvite.init().uniqueState(true));
        }

        pub fn listChannelInvites(self: *Client, channel_id: Snowflake) !Rest.Response {
            return self.rest.listChannelInvites(channel_id);
        }

        pub fn fetchChannelInvites(self: *Client, channel_id: Snowflake) !Rest.Response {
            return self.listChannelInvites(channel_id);
        }

        pub fn listGuildInvites(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.listGuildInvites(guild_id);
        }

        pub fn fetchGuildInvites(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.listGuildInvites(guild_id);
        }

        pub fn getInvite(self: *Client, code: []const u8) !Rest.Response {
            return self.rest.getInvite(code);
        }

        pub fn fetchInvite(self: *Client, code: []const u8) !Rest.Response {
            return self.getInvite(code);
        }

        pub fn getInviteWithOptions(self: *Client, code: []const u8, options: Types.GetInvite) !Rest.Response {
            return self.rest.getInviteWithOptions(code, options);
        }

        pub fn fetchInviteWithOptions(self: *Client, code: []const u8, options: Types.GetInvite) !Rest.Response {
            return self.getInviteWithOptions(code, options);
        }

        pub fn deleteInvite(self: *Client, code: []const u8) !Rest.Response {
            return self.rest.deleteInvite(code);
        }

        pub fn getInviteTargetUsers(self: *Client, code: []const u8) !Rest.Response {
            return self.rest.getInviteTargetUsers(code);
        }

        pub fn listInviteTargetUsers(self: *Client, code: []const u8) !Rest.Response {
            return self.getInviteTargetUsers(code);
        }

        pub fn fetchInviteTargetUsers(self: *Client, code: []const u8) !Rest.Response {
            return self.getInviteTargetUsers(code);
        }

        pub fn updateInviteTargetUsers(self: *Client, code: []const u8, file: Types.UploadFile) !Rest.Response {
            return self.rest.updateInviteTargetUsers(code, file);
        }

        pub fn setInviteTargetUsers(self: *Client, code: []const u8, file: Types.UploadFile) !Rest.Response {
            return self.updateInviteTargetUsers(code, file);
        }

        pub fn getInviteTargetUsersJobStatus(self: *Client, code: []const u8) !Rest.Response {
            return self.rest.getInviteTargetUsersJobStatus(code);
        }

        pub fn fetchInviteTargetUsersJobStatus(self: *Client, code: []const u8) !Rest.Response {
            return self.getInviteTargetUsersJobStatus(code);
        }

        pub fn listChannelWebhooks(self: *Client, channel_id: Snowflake) !Rest.Response {
            return self.rest.listChannelWebhooks(channel_id);
        }

        pub fn fetchChannelWebhooks(self: *Client, channel_id: Snowflake) !Rest.Response {
            return self.listChannelWebhooks(channel_id);
        }

        pub fn createWebhook(self: *Client, channel_id: Snowflake, payload: Types.CreateWebhook) !Rest.Response {
            return self.rest.createWebhook(channel_id, payload);
        }

        pub fn createWebhookWithName(
            self: *Client,
            channel_id: Snowflake,
            name: []const u8,
        ) !Rest.Response {
            return self.createWebhook(channel_id, Types.CreateWebhook.init(name));
        }

        pub fn createWebhookWithAvatar(
            self: *Client,
            channel_id: Snowflake,
            name: []const u8,
            avatar: []const u8,
        ) !Rest.Response {
            return self.createWebhook(channel_id, Types.CreateWebhook.init(name).withAvatar(avatar));
        }

        pub fn listGuildWebhooks(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.rest.listGuildWebhooks(guild_id);
        }

        pub fn fetchGuildWebhooks(self: *Client, guild_id: Snowflake) !Rest.Response {
            return self.listGuildWebhooks(guild_id);
        }

        pub fn getWebhook(self: *Client, webhook_id: Snowflake) !Rest.Response {
            return self.rest.getWebhook(webhook_id);
        }

        pub fn fetchWebhook(self: *Client, webhook_id: Snowflake) !Rest.Response {
            return self.getWebhook(webhook_id);
        }

        pub fn editWebhook(self: *Client, webhook_id: Snowflake, payload: Types.EditWebhook) !Rest.Response {
            return self.rest.editWebhook(webhook_id, payload);
        }

        pub fn deleteWebhook(self: *Client, webhook_id: Snowflake) !Rest.Response {
            return self.rest.deleteWebhook(webhook_id);
        }

        pub fn getWebhookWithToken(self: *Client, webhook_id: Snowflake, webhook_token: []const u8) !Rest.Response {
            return self.rest.getWebhookWithToken(webhook_id, webhook_token);
        }

        pub fn fetchWebhookWithToken(self: *Client, webhook_id: Snowflake, webhook_token: []const u8) !Rest.Response {
            return self.getWebhookWithToken(webhook_id, webhook_token);
        }

        pub fn editWebhookWithToken(
            self: *Client,
            webhook_id: Snowflake,
            webhook_token: []const u8,
            payload: Types.EditWebhookWithToken,
        ) !Rest.Response {
            return self.rest.editWebhookWithToken(webhook_id, webhook_token, payload);
        }

        pub fn deleteWebhookWithToken(self: *Client, webhook_id: Snowflake, webhook_token: []const u8) !Rest.Response {
            return self.rest.deleteWebhookWithToken(webhook_id, webhook_token);
        }

        pub fn executeWebhook(
            self: *Client,
            webhook_id: Snowflake,
            webhook_token: []const u8,
            payload: Types.ExecuteWebhook,
        ) !Rest.Response {
            return self.rest.executeWebhook(webhook_id, webhook_token, payload);
        }

        pub fn executeWebhookWithContent(
            self: *Client,
            webhook_id: Snowflake,
            webhook_token: []const u8,
            content: []const u8,
        ) !Rest.Response {
            return self.executeWebhook(webhook_id, webhook_token, Types.ExecuteWebhook.init(content));
        }

        pub fn executeWebhookWithFiles(
            self: *Client,
            webhook_id: Snowflake,
            webhook_token: []const u8,
            payload: Types.ExecuteWebhook,
            files: []const Types.UploadFile,
        ) !Rest.Response {
            return self.rest.executeWebhookWithFiles(webhook_id, webhook_token, payload, files);
        }

        pub fn executeWebhookWithOptionsAndFiles(
            self: *Client,
            webhook_id: Snowflake,
            webhook_token: []const u8,
            options: Types.ExecuteWebhookQuery,
            payload: Types.ExecuteWebhook,
            files: []const Types.UploadFile,
        ) !Rest.Response {
            return self.rest.executeWebhookWithOptionsAndFiles(webhook_id, webhook_token, options, payload, files);
        }

        pub fn getWebhookMessage(
            self: *Client,
            webhook_id: Snowflake,
            webhook_token: []const u8,
            message_id: Snowflake,
        ) !Rest.Response {
            return self.rest.getWebhookMessage(webhook_id, webhook_token, message_id);
        }

        pub fn fetchWebhookMessage(
            self: *Client,
            webhook_id: Snowflake,
            webhook_token: []const u8,
            message_id: Snowflake,
        ) !Rest.Response {
            return self.getWebhookMessage(webhook_id, webhook_token, message_id);
        }

        pub fn editWebhookMessage(
            self: *Client,
            webhook_id: Snowflake,
            webhook_token: []const u8,
            message_id: Snowflake,
            payload: Types.EditMessage,
        ) !Rest.Response {
            return self.rest.editWebhookMessage(webhook_id, webhook_token, message_id, payload);
        }

        pub fn deleteWebhookMessage(
            self: *Client,
            webhook_id: Snowflake,
            webhook_token: []const u8,
            message_id: Snowflake,
        ) !Rest.Response {
            return self.rest.deleteWebhookMessage(webhook_id, webhook_token, message_id);
        }

        pub fn listGlobalApplicationCommands(self: *Client, application_id: Snowflake) !Rest.Response {
            return self.rest.listGlobalApplicationCommands(application_id);
        }

        pub fn fetchGlobalApplicationCommands(self: *Client, application_id: Snowflake) !Rest.Response {
            return self.listGlobalApplicationCommands(application_id);
        }

        pub fn createGlobalApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            command: Interactions.ApplicationCommand,
        ) !Rest.Response {
            return self.rest.createGlobalApplicationCommand(application_id, command);
        }

        pub fn registerGlobalApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            command: Interactions.ApplicationCommand,
        ) !Rest.Response {
            return self.createGlobalApplicationCommand(application_id, command);
        }

        pub fn bulkOverwriteGlobalApplicationCommands(
            self: *Client,
            application_id: Snowflake,
            commands: []const Interactions.ApplicationCommand,
        ) !Rest.Response {
            return self.rest.bulkOverwriteGlobalApplicationCommands(application_id, commands);
        }

        pub fn setGlobalApplicationCommands(
            self: *Client,
            application_id: Snowflake,
            commands: []const Interactions.ApplicationCommand,
        ) !Rest.Response {
            return self.bulkOverwriteGlobalApplicationCommands(application_id, commands);
        }

        pub fn getGlobalApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            command_id: Snowflake,
        ) !Rest.Response {
            return self.rest.getGlobalApplicationCommand(application_id, command_id);
        }

        pub fn fetchGlobalApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            command_id: Snowflake,
        ) !Rest.Response {
            return self.getGlobalApplicationCommand(application_id, command_id);
        }

        pub fn editGlobalApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            command_id: Snowflake,
            command: Interactions.EditApplicationCommand,
        ) !Rest.Response {
            return self.rest.editGlobalApplicationCommand(application_id, command_id, command);
        }

        pub fn updateGlobalApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            command_id: Snowflake,
            command: Interactions.EditApplicationCommand,
        ) !Rest.Response {
            return self.editGlobalApplicationCommand(application_id, command_id, command);
        }

        pub fn renameGlobalApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            command_id: Snowflake,
            name: []const u8,
        ) !Rest.Response {
            return self.editGlobalApplicationCommand(
                application_id,
                command_id,
                Interactions.EditApplicationCommand.init().withName(name),
            );
        }

        pub fn setGlobalApplicationCommandDescription(
            self: *Client,
            application_id: Snowflake,
            command_id: Snowflake,
            description: []const u8,
        ) !Rest.Response {
            return self.editGlobalApplicationCommand(
                application_id,
                command_id,
                Interactions.EditApplicationCommand.init().withDescription(description),
            );
        }

        pub fn deleteGlobalApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            command_id: Snowflake,
        ) !Rest.Response {
            return self.rest.deleteGlobalApplicationCommand(application_id, command_id);
        }

        pub fn removeGlobalApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            command_id: Snowflake,
        ) !Rest.Response {
            return self.deleteGlobalApplicationCommand(application_id, command_id);
        }

        pub fn listGuildApplicationCommands(
            self: *Client,
            application_id: Snowflake,
            guild_id: Snowflake,
        ) !Rest.Response {
            return self.rest.listGuildApplicationCommands(application_id, guild_id);
        }

        pub fn fetchGuildApplicationCommands(
            self: *Client,
            application_id: Snowflake,
            guild_id: Snowflake,
        ) !Rest.Response {
            return self.listGuildApplicationCommands(application_id, guild_id);
        }

        pub fn createGuildApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            guild_id: Snowflake,
            command: Interactions.ApplicationCommand,
        ) !Rest.Response {
            return self.rest.createGuildApplicationCommand(application_id, guild_id, command);
        }

        pub fn registerGuildApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            guild_id: Snowflake,
            command: Interactions.ApplicationCommand,
        ) !Rest.Response {
            return self.createGuildApplicationCommand(application_id, guild_id, command);
        }

        pub fn bulkOverwriteGuildApplicationCommands(
            self: *Client,
            application_id: Snowflake,
            guild_id: Snowflake,
            commands: []const Interactions.ApplicationCommand,
        ) !Rest.Response {
            return self.rest.bulkOverwriteGuildApplicationCommands(application_id, guild_id, commands);
        }

        pub fn setGuildApplicationCommands(
            self: *Client,
            application_id: Snowflake,
            guild_id: Snowflake,
            commands: []const Interactions.ApplicationCommand,
        ) !Rest.Response {
            return self.bulkOverwriteGuildApplicationCommands(application_id, guild_id, commands);
        }

        pub fn getGuildApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            guild_id: Snowflake,
            command_id: Snowflake,
        ) !Rest.Response {
            return self.rest.getGuildApplicationCommand(application_id, guild_id, command_id);
        }

        pub fn fetchGuildApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            guild_id: Snowflake,
            command_id: Snowflake,
        ) !Rest.Response {
            return self.getGuildApplicationCommand(application_id, guild_id, command_id);
        }

        pub fn editGuildApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            guild_id: Snowflake,
            command_id: Snowflake,
            command: Interactions.EditApplicationCommand,
        ) !Rest.Response {
            return self.rest.editGuildApplicationCommand(application_id, guild_id, command_id, command);
        }

        pub fn updateGuildApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            guild_id: Snowflake,
            command_id: Snowflake,
            command: Interactions.EditApplicationCommand,
        ) !Rest.Response {
            return self.editGuildApplicationCommand(application_id, guild_id, command_id, command);
        }

        pub fn renameGuildApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            guild_id: Snowflake,
            command_id: Snowflake,
            name: []const u8,
        ) !Rest.Response {
            return self.editGuildApplicationCommand(
                application_id,
                guild_id,
                command_id,
                Interactions.EditApplicationCommand.init().withName(name),
            );
        }

        pub fn setGuildApplicationCommandDescription(
            self: *Client,
            application_id: Snowflake,
            guild_id: Snowflake,
            command_id: Snowflake,
            description: []const u8,
        ) !Rest.Response {
            return self.editGuildApplicationCommand(
                application_id,
                guild_id,
                command_id,
                Interactions.EditApplicationCommand.init().withDescription(description),
            );
        }

        pub fn deleteGuildApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            guild_id: Snowflake,
            command_id: Snowflake,
        ) !Rest.Response {
            return self.rest.deleteGuildApplicationCommand(application_id, guild_id, command_id);
        }

        pub fn removeGuildApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            guild_id: Snowflake,
            command_id: Snowflake,
        ) !Rest.Response {
            return self.deleteGuildApplicationCommand(application_id, guild_id, command_id);
        }
    };
}
