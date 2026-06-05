const std = @import("std");
const Api = @import("../../core/api.zig");
const Routes = @import("../routes.zig");
const Types = @import("../../models/types.zig");
const Interactions = @import("../../interactions/mod.zig");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;

const Root = @import("../client.zig");
const Header = Root.Header;
const Request = Root.Request;
const BodyStream = Root.BodyStream;
const Response = Root.Response;
const Transport = Root.Transport;
const RateLimitState = Root.RateLimitState;
const MultipartFilePathStream = Root.MultipartFilePathStream;
const writeMessageMultipart = Root.writeMessageMultipart;
const writeExecuteWebhookMultipart = Root.writeExecuteWebhookMultipart;
const writeGuildStickerMultipart = Root.writeGuildStickerMultipart;
const writeInviteTargetUsersMultipart = Root.writeInviteTargetUsersMultipart;
const writeMessageMultipartFilePaths = Root.writeMessageMultipartFilePaths;
const writeMessageMultipartFilePathMetadata = Root.writeMessageMultipartFilePathMetadata;
const writeMultipartPayloadJson = Root.writeMultipartPayloadJson;
const writeMultipartTextField = Root.writeMultipartTextField;
const writeMultipartFileHeader = Root.writeMultipartFileHeader;
const writeMultipartQuoted = Root.writeMultipartQuoted;
const MemoryTransport = Root.MemoryTransport;

pub fn Methods(comptime Client: type) type {
    return struct {
        pub fn createGlobalApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            command: Interactions.ApplicationCommand,
        ) !Response {
            const route = try Routes.createGlobalApplicationCommand(self.allocator, application_id);
            defer route.deinit(self.allocator);

            return self.requestJson(route, command);
        }

        pub fn bulkOverwriteGlobalApplicationCommands(
            self: *Client,
            application_id: Snowflake,
            commands: []const Interactions.ApplicationCommand,
        ) !Response {
            const route = try Routes.bulkOverwriteGlobalApplicationCommands(self.allocator, application_id);
            defer route.deinit(self.allocator);

            var body = std.Io.Writer.Allocating.init(self.allocator);
            defer body.deinit();
            try Interactions.writeApplicationCommandArray(commands, &body.writer);

            return self.request(route, body.written(), "application/json");
        }

        pub fn getGlobalApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            command_id: Snowflake,
        ) !Response {
            const route = try Routes.globalApplicationCommand(self.allocator, application_id, command_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn editGlobalApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            command_id: Snowflake,
            command: Interactions.EditApplicationCommand,
        ) !Response {
            const route = try Routes.editGlobalApplicationCommand(self.allocator, application_id, command_id);
            defer route.deinit(self.allocator);

            return self.requestJson(route, command);
        }

        pub fn deleteGlobalApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            command_id: Snowflake,
        ) !Response {
            const route = try Routes.deleteGlobalApplicationCommand(self.allocator, application_id, command_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listGuildApplicationCommands(
            self: *Client,
            application_id: Snowflake,
            guild_id: Snowflake,
        ) !Response {
            const route = try Routes.guildApplicationCommands(self.allocator, application_id, guild_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn createGuildApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            guild_id: Snowflake,
            command: Interactions.ApplicationCommand,
        ) !Response {
            const route = try Routes.createGuildApplicationCommand(self.allocator, application_id, guild_id);
            defer route.deinit(self.allocator);

            return self.requestJson(route, command);
        }

        pub fn bulkOverwriteGuildApplicationCommands(
            self: *Client,
            application_id: Snowflake,
            guild_id: Snowflake,
            commands: []const Interactions.ApplicationCommand,
        ) !Response {
            const route = try Routes.bulkOverwriteGuildApplicationCommands(self.allocator, application_id, guild_id);
            defer route.deinit(self.allocator);

            var body = std.Io.Writer.Allocating.init(self.allocator);
            defer body.deinit();
            try Interactions.writeApplicationCommandArray(commands, &body.writer);

            return self.request(route, body.written(), "application/json");
        }

        pub fn getGuildApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            guild_id: Snowflake,
            command_id: Snowflake,
        ) !Response {
            const route = try Routes.guildApplicationCommand(self.allocator, application_id, guild_id, command_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn editGuildApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            guild_id: Snowflake,
            command_id: Snowflake,
            command: Interactions.EditApplicationCommand,
        ) !Response {
            const route = try Routes.editGuildApplicationCommand(self.allocator, application_id, guild_id, command_id);
            defer route.deinit(self.allocator);

            return self.requestJson(route, command);
        }

        pub fn deleteGuildApplicationCommand(
            self: *Client,
            application_id: Snowflake,
            guild_id: Snowflake,
            command_id: Snowflake,
        ) !Response {
            const route = try Routes.deleteGuildApplicationCommand(self.allocator, application_id, guild_id, command_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn listGuildApplicationCommandPermissions(
            self: *Client,
            bearer_token: []const u8,
            application_id: Snowflake,
            guild_id: Snowflake,
        ) !Response {
            const route = try Routes.guildApplicationCommandPermissions(self.allocator, application_id, guild_id);
            defer route.deinit(self.allocator);
            return self.requestWithToken(route, bearer_token, null, null);
        }

        pub fn getApplicationCommandPermissions(
            self: *Client,
            bearer_token: []const u8,
            application_id: Snowflake,
            guild_id: Snowflake,
            command_id: Snowflake,
        ) !Response {
            const route = try Routes.applicationCommandPermissions(self.allocator, application_id, guild_id, command_id);
            defer route.deinit(self.allocator);
            return self.requestWithToken(route, bearer_token, null, null);
        }

        pub fn editApplicationCommandPermissions(
            self: *Client,
            bearer_token: []const u8,
            application_id: Snowflake,
            guild_id: Snowflake,
            command_id: Snowflake,
            permissions: []const Interactions.ApplicationCommandPermission,
        ) !Response {
            const route = try Routes.editApplicationCommandPermissions(self.allocator, application_id, guild_id, command_id);
            defer route.deinit(self.allocator);

            return self.requestJsonWithToken(
                route,
                bearer_token,
                Interactions.ApplicationCommandPermissionsUpdate{ .permissions = permissions },
            );
        }

        pub fn createInteractionResponse(
            self: *Client,
            interaction_id: Snowflake,
            token: []const u8,
            response_payload: Interactions.InteractionResponse,
        ) !Response {
            const route = try Routes.interactionCallback(self.allocator, interaction_id, token);
            defer route.deinit(self.allocator);

            return self.requestJson(route, response_payload);
        }

        pub fn getOriginalInteractionResponse(
            self: *Client,
            application_id: Snowflake,
            token: []const u8,
        ) !Response {
            const route = try Routes.getOriginalInteractionResponse(self.allocator, application_id, token);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn editOriginalInteractionResponse(
            self: *Client,
            application_id: Snowflake,
            token: []const u8,
            payload: Types.EditMessage,
        ) !Response {
            const route = try Routes.editOriginalInteractionResponse(self.allocator, application_id, token);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn deleteOriginalInteractionResponse(
            self: *Client,
            application_id: Snowflake,
            token: []const u8,
        ) !Response {
            const route = try Routes.deleteOriginalInteractionResponse(self.allocator, application_id, token);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn createFollowupMessage(
            self: *Client,
            application_id: Snowflake,
            token: []const u8,
            payload: Types.ExecuteWebhook,
        ) !Response {
            const route = try Routes.createFollowupMessage(self.allocator, application_id, token);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn getFollowupMessage(
            self: *Client,
            application_id: Snowflake,
            token: []const u8,
            message_id: Snowflake,
        ) !Response {
            const route = try Routes.getFollowupMessage(self.allocator, application_id, token, message_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn editFollowupMessage(
            self: *Client,
            application_id: Snowflake,
            token: []const u8,
            message_id: Snowflake,
            payload: Types.EditMessage,
        ) !Response {
            const route = try Routes.editFollowupMessage(self.allocator, application_id, token, message_id);
            defer route.deinit(self.allocator);
            return self.requestJson(route, payload);
        }

        pub fn deleteFollowupMessage(
            self: *Client,
            application_id: Snowflake,
            token: []const u8,
            message_id: Snowflake,
        ) !Response {
            const route = try Routes.deleteFollowupMessage(self.allocator, application_id, token, message_id);
            defer route.deinit(self.allocator);
            return self.request(route, null, null);
        }

        pub fn requestJson(self: *Client, route: Routes.Route, payload: anytype) !Response {
            var body = std.Io.Writer.Allocating.init(self.allocator);
            defer body.deinit();
            try payload.writeJson(&body.writer);

            return self.request(route, body.written(), "application/json");
        }

        pub fn requestJsonWithToken(
            self: *Client,
            route: Routes.Route,
            token: []const u8,
            payload: anytype,
        ) !Response {
            var body = std.Io.Writer.Allocating.init(self.allocator);
            defer body.deinit();
            try payload.writeJson(&body.writer);

            return self.requestWithToken(route, token, body.written(), "application/json");
        }

        pub fn requestFormWithToken(
            self: *Client,
            route: Routes.Route,
            token: []const u8,
            payload: anytype,
        ) !Response {
            var body = std.Io.Writer.Allocating.init(self.allocator);
            defer body.deinit();
            try payload.writeForm(&body.writer);

            return self.requestWithToken(route, token, body.written(), "application/x-www-form-urlencoded");
        }

        pub fn requestMultipart(
            self: *Client,
            route: Routes.Route,
            payload: Types.CreateMessage,
            files: []const Types.UploadFile,
        ) !Response {
            const boundary = "discord-zig-boundary";
            var body = std.Io.Writer.Allocating.init(self.allocator);
            defer body.deinit();

            try writeMessageMultipart(boundary, payload, files, &body.writer);

            const content_type = "multipart/form-data; boundary=" ++ boundary;
            return self.request(route, body.written(), content_type);
        }

        pub fn requestWebhookMultipartWithToken(
            self: *Client,
            route: Routes.Route,
            token: []const u8,
            payload: Types.ExecuteWebhook,
            files: []const Types.UploadFile,
        ) !Response {
            const boundary = "discord-zig-boundary";
            var body = std.Io.Writer.Allocating.init(self.allocator);
            defer body.deinit();

            try writeExecuteWebhookMultipart(boundary, payload, files, &body.writer);

            const content_type = "multipart/form-data; boundary=" ++ boundary;
            return self.requestWithToken(route, token, body.written(), content_type);
        }

        pub fn requestMultipartFilePaths(
            self: *Client,
            route: Routes.Route,
            payload: Types.CreateMessage,
            files: []const Types.UploadFilePath,
        ) !Response {
            const boundary = "discord-zig-boundary";
            var stream = try MultipartFilePathStream.init(self.allocator, boundary, payload, files);
            defer stream.deinit();

            const content_type = "multipart/form-data; boundary=" ++ boundary;
            return self.requestStream(route, stream.bodyStream(), content_type);
        }

        pub fn requestGuildStickerMultipart(
            self: *Client,
            route: Routes.Route,
            payload: Types.CreateGuildSticker,
            file: Types.UploadFile,
        ) !Response {
            const boundary = "discord-zig-boundary";
            var body = std.Io.Writer.Allocating.init(self.allocator);
            defer body.deinit();

            try writeGuildStickerMultipart(boundary, payload, file, &body.writer);

            const content_type = "multipart/form-data; boundary=" ++ boundary;
            return self.request(route, body.written(), content_type);
        }

        pub fn requestInviteTargetUsersMultipart(
            self: *Client,
            route: Routes.Route,
            file: Types.UploadFile,
        ) !Response {
            const boundary = "discord-zig-boundary";
            var body = std.Io.Writer.Allocating.init(self.allocator);
            defer body.deinit();

            try writeInviteTargetUsersMultipart(boundary, file, &body.writer);

            const content_type = "multipart/form-data; boundary=" ++ boundary;
            return self.request(route, body.written(), content_type);
        }

        pub fn request(
            self: *Client,
            route: Routes.Route,
            body: ?[]const u8,
            content_type: ?[]const u8,
        ) !Response {
            return self.requestWithToken(route, self.token, body, content_type);
        }

        pub fn requestWithToken(
            self: *Client,
            route: Routes.Route,
            token: []const u8,
            body: ?[]const u8,
            content_type: ?[]const u8,
        ) !Response {
            const url = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ Api.base_url, route.path });
            defer self.allocator.free(url);

            const response = try self.transport.send(self.allocator, .{
                .method = route.method,
                .url = url,
                .token = token,
                .body = body,
                .content_type = content_type,
            });

            return self.finishRequest(route, response);
        }

        pub fn requestStream(
            self: *Client,
            route: Routes.Route,
            body_stream: BodyStream,
            content_type: ?[]const u8,
        ) !Response {
            const url = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ Api.base_url, route.path });
            defer self.allocator.free(url);

            const response = try self.transport.send(self.allocator, .{
                .method = route.method,
                .url = url,
                .token = self.token,
                .body_stream = body_stream,
                .content_type = content_type,
            });

            return self.finishRequest(route, response);
        }

        pub fn finishRequest(self: *Client, route: Routes.Route, response: Response) !Response {
            const key = try Routes.bucketKey(self.allocator, route);
            errdefer self.allocator.free(key);
            var state = self.rate_limits.get(key) orelse RateLimitState{};
            state.updateFromHeaders(response.headers);

            const existing = try self.rate_limits.getOrPut(key);
            if (existing.found_existing) {
                self.allocator.free(key);
                existing.value_ptr.* = state;
            } else {
                existing.value_ptr.* = state;
            }

            return response;
        }
    };
}
