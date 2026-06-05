const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Json = @import("../../core/json.zig");

const Root = @import("../mod.zig");
const InteractionType = Root.InteractionType;
const CallbackType = Root.CallbackType;
const ComponentType = Root.ComponentType;
const ButtonStyle = Root.ButtonStyle;
const TextInputStyle = Root.TextInputStyle;
const ApplicationCommandType = Root.ApplicationCommandType;
const max_action_rows = Root.max_action_rows;
const max_row_components = Root.max_row_components;
const max_select_options = Root.max_select_options;
const max_command_options = Root.max_command_options;
const max_command_choices = Root.max_command_choices;
const max_custom_id_len = Root.max_custom_id_len;
const max_button_label_len = Root.max_button_label_len;
const max_select_placeholder_len = Root.max_select_placeholder_len;
const max_select_option_label_len = Root.max_select_option_label_len;
const max_select_option_value_len = Root.max_select_option_value_len;
const max_select_option_description_len = Root.max_select_option_description_len;
const max_select_values = Root.max_select_values;
const max_text_input_label_len = Root.max_text_input_label_len;
const max_text_input_placeholder_len = Root.max_text_input_placeholder_len;
const max_text_input_value_len = Root.max_text_input_value_len;
const max_command_name_len = Root.max_command_name_len;
const max_command_description_len = Root.max_command_description_len;
const max_choice_name_len = Root.max_choice_name_len;
const max_choice_string_value_len = Root.max_choice_string_value_len;
const max_section_components = Root.max_section_components;
const max_media_gallery_items = Root.max_media_gallery_items;
const max_button_sku_id_len = Root.max_button_sku_id_len;
const ValidationError = Root.ValidationError;
const writeComma = Root.writeComma;
const checkLen = Root.checkLen;
const checkNameLen = Root.checkNameLen;
const checkDescriptionLen = Root.checkDescriptionLen;
const checkSelectRange = Root.checkSelectRange;
const Locale = Root.Locale;
const Localization = Root.Localization;
const ComponentEmoji = Root.ComponentEmoji;
const SelectOption = Root.SelectOption;
const Button = Root.Button;
const StringSelect = Root.StringSelect;
const AutoSelect = Root.AutoSelect;
const TextInput = Root.TextInput;
const UnfurledMedia = Root.UnfurledMedia;
const TextDisplay = Root.TextDisplay;
const Thumbnail = Root.Thumbnail;
const SectionAccessory = Root.SectionAccessory;
const Section = Root.Section;
const MediaGalleryItem = Root.MediaGalleryItem;
const MediaGallery = Root.MediaGallery;
const FileComponent = Root.FileComponent;
const SeparatorSpacing = Root.SeparatorSpacing;
const Separator = Root.Separator;
const Container = Root.Container;
const Component = Root.Component;
const ApplicationCommandOptionType = Root.ApplicationCommandOptionType;
const CommandChoiceValue = Root.CommandChoiceValue;
const CommandChoice = Root.CommandChoice;
const ApplicationCommandOption = Root.ApplicationCommandOption;
const Interaction = Root.Interaction;
const CommandOptionValue = Root.CommandOptionValue;
const CommandDataOption = Root.CommandDataOption;
const Resolved = Root.Resolved;
const ResolvedUser = Root.ResolvedUser;
const ResolvedRole = Root.ResolvedRole;
const parseResolvedUser = Root.parseResolvedUser;
const parseResolvedRole = Root.parseResolvedRole;
const optionalStringValue = Root.optionalStringValue;
const permissionsBitValue = Root.permissionsBitValue;
const ResolvedChannel = Root.ResolvedChannel;
const ResolvedMember = Root.ResolvedMember;
const parseResolvedChannel = Root.parseResolvedChannel;
const parseResolvedMember = Root.parseResolvedMember;
const optionalSnowflakeValue = Root.optionalSnowflakeValue;
const ResolvedAttachment = Root.ResolvedAttachment;
const ResolvedMessage = Root.ResolvedMessage;
const parseResolvedAttachment = Root.parseResolvedAttachment;
const parseResolvedMessage = Root.parseResolvedMessage;
const optionalU32Field = Root.optionalU32Field;
const CommandData = Root.CommandData;
const ComponentData = Root.ComponentData;
const ParsedInteraction = Root.ParsedInteraction;
const ParsedHandler = Root.ParsedHandler;
const CommandRoute = Root.CommandRoute;
const MatchKind = Root.MatchKind;
const ComponentRoute = Root.ComponentRoute;
const Middleware = Root.Middleware;
const ApplicationCommandAnnotation = Root.ApplicationCommandAnnotation;
const ApplicationCommandAnnotationManifest = Root.ApplicationCommandAnnotationManifest;
const ApplicationCommandModule = Root.ApplicationCommandModule;
const ApplicationCommandManifest = Root.ApplicationCommandManifest;
const ApplicationCommandRegistry = Root.ApplicationCommandRegistry;
const EditApplicationCommand = Root.EditApplicationCommand;
const ApplicationCommandPermissionType = Root.ApplicationCommandPermissionType;
const ApplicationCommandPermission = Root.ApplicationCommandPermission;
const ApplicationCommandPermissionsUpdate = Root.ApplicationCommandPermissionsUpdate;
const writeApplicationCommandPermissionArray = Root.writeApplicationCommandPermissionArray;
const writeLocalizationObject = Root.writeLocalizationObject;
const writeOptionArray = Root.writeOptionArray;
const writeChoiceArray = Root.writeChoiceArray;
const writeApplicationCommandArray = Root.writeApplicationCommandArray;
const writeComponentArray = Root.writeComponentArray;
const writeSelectOptionArray = Root.writeSelectOptionArray;
const commandDataFromJson = Root.commandDataFromJson;
const commandDataOptionsFromJson = Root.commandDataOptionsFromJson;
const commandDataOptionFromJson = Root.commandDataOptionFromJson;
const componentDataFromJson = Root.componentDataFromJson;
const componentDataArrayFromJson = Root.componentDataArrayFromJson;
const stringArrayValue = Root.stringArrayValue;
const resolvedFromJson = Root.resolvedFromJson;
const resolvedSubObject = Root.resolvedSubObject;
const objectValue = Root.objectValue;
const arrayValue = Root.arrayValue;
const snowflakeField = Root.snowflakeField;
const snowflakeValue = Root.snowflakeValue;
const stringField = Root.stringField;
const stringValue = Root.stringValue;
const integerValue = Root.integerValue;
const numberValue = Root.numberValue;
const boolValue = Root.boolValue;
const interactionTypeValue = Root.interactionTypeValue;
const applicationCommandTypeValue = Root.applicationCommandTypeValue;
const applicationCommandOptionTypeValue = Root.applicationCommandOptionTypeValue;
const componentTypeValue = Root.componentTypeValue;
const ButtonBuilder = Root.ButtonBuilder;
const StringSelectMenuBuilder = Root.StringSelectMenuBuilder;
const UserSelectMenuBuilder = Root.UserSelectMenuBuilder;
const RoleSelectMenuBuilder = Root.RoleSelectMenuBuilder;
const MentionableSelectMenuBuilder = Root.MentionableSelectMenuBuilder;
const ChannelSelectMenuBuilder = Root.ChannelSelectMenuBuilder;
const TextInputBuilder = Root.TextInputBuilder;
const ActionRowBuilder = Root.ActionRowBuilder;
const SlashCommandBuilder = Root.SlashCommandBuilder;
const ContextMenuCommandBuilder = Root.ContextMenuCommandBuilder;
const SlashCommandOptionBuilder = Root.SlashCommandOptionBuilder;
const SlashCommandStringOption = Root.SlashCommandStringOption;
const SlashCommandIntegerOption = Root.SlashCommandIntegerOption;
const SlashCommandNumberOption = Root.SlashCommandNumberOption;
const SlashCommandBooleanOption = Root.SlashCommandBooleanOption;
const SlashCommandUserOption = Root.SlashCommandUserOption;
const SlashCommandChannelOption = Root.SlashCommandChannelOption;
const SlashCommandRoleOption = Root.SlashCommandRoleOption;
const SlashCommandMentionableOption = Root.SlashCommandMentionableOption;
const SlashCommandAttachmentOption = Root.SlashCommandAttachmentOption;
const SlashCommandSubcommandBuilder = Root.SlashCommandSubcommandBuilder;
const SlashCommandSubcommandGroupBuilder = Root.SlashCommandSubcommandGroupBuilder;
const StringSelectMenuOptionBuilder = Root.StringSelectMenuOptionBuilder;
const ModalBuilder = Root.ModalBuilder;
const EmbedBuilder = Root.EmbedBuilder;

pub const InteractionRouter = struct {
    commands: []const CommandRoute = &.{},
    autocomplete: []const CommandRoute = &.{},
    components: []const ComponentRoute = &.{},
    modals: []const ComponentRoute = &.{},
    middleware: []const Middleware = &.{},
    /// Invoked when no route matches a non-ping interaction, letting a bot
    /// answer unknown commands/components from one place.
    fallback: ?ParsedHandler = null,

    pub fn dispatch(self: InteractionRouter, interaction: *const ParsedInteraction) !bool {
        for (self.middleware) |entry| {
            if (!try entry.call(interaction)) return false;
        }

        const routed = switch (interaction.interaction.type) {
            .application_command => try dispatchCommand(interaction, self.commands),
            .application_command_autocomplete => try dispatchCommand(interaction, self.autocomplete),
            .message_component => try dispatchComponent(interaction, self.components),
            .modal_submit => try dispatchComponent(interaction, self.modals),
            .ping => false,
        };
        if (routed) return true;

        if (interaction.interaction.type != .ping) {
            if (self.fallback) |handler| {
                try handler.call(interaction);
                return true;
            }
        }
        return false;
    }

    pub fn dispatchCommand(interaction: *const ParsedInteraction, routes: []const CommandRoute) !bool {
        const data = interaction.data orelse return false;
        for (routes) |route| {
            if (std.mem.eql(u8, route.name, data.name)) {
                if (route.guard) |guard| {
                    if (!try guard.call(interaction)) return true;
                }
                try route.handler.call(interaction);
                return true;
            }
        }
        return false;
    }

    pub fn dispatchComponent(interaction: *const ParsedInteraction, routes: []const ComponentRoute) !bool {
        const data = interaction.component_data orelse return false;
        for (routes) |route| {
            const matched = switch (route.match) {
                .exact => std.mem.eql(u8, route.custom_id, data.custom_id),
                .prefix => std.mem.startsWith(u8, data.custom_id, route.custom_id),
            };
            if (matched) {
                if (route.guard) |guard| {
                    if (!try guard.call(interaction)) return true;
                }
                try route.handler.call(interaction);
                return true;
            }
        }
        return false;
    }
};

pub const InteractionRouterBuilder = struct {
    allocator: std.mem.Allocator,
    commands: std.array_list.Managed(CommandRoute),
    autocomplete: std.array_list.Managed(CommandRoute),
    components: std.array_list.Managed(ComponentRoute),
    modals: std.array_list.Managed(ComponentRoute),
    middleware: std.array_list.Managed(Middleware),
    fallback: ?ParsedHandler = null,

    pub fn init(allocator: std.mem.Allocator) InteractionRouterBuilder {
        return .{
            .allocator = allocator,
            .commands = std.array_list.Managed(CommandRoute).init(allocator),
            .autocomplete = std.array_list.Managed(CommandRoute).init(allocator),
            .components = std.array_list.Managed(ComponentRoute).init(allocator),
            .modals = std.array_list.Managed(ComponentRoute).init(allocator),
            .middleware = std.array_list.Managed(Middleware).init(allocator),
        };
    }

    pub fn deinit(self: *InteractionRouterBuilder) void {
        self.commands.deinit();
        self.autocomplete.deinit();
        self.components.deinit();
        self.modals.deinit();
        self.middleware.deinit();
        self.fallback = null;
    }

    pub fn command(self: *InteractionRouterBuilder, name: []const u8, handler: ParsedHandler) !void {
        try self.commands.append(.{ .name = name, .handler = handler });
    }

    pub fn commandWithGuard(
        self: *InteractionRouterBuilder,
        name: []const u8,
        handler: ParsedHandler,
        guard: Middleware,
    ) !void {
        try self.commands.append(.{ .name = name, .handler = handler, .guard = guard });
    }

    pub fn autocompleteRoute(self: *InteractionRouterBuilder, name: []const u8, handler: ParsedHandler) !void {
        try self.autocomplete.append(.{ .name = name, .handler = handler });
    }

    pub fn component(self: *InteractionRouterBuilder, custom_id: []const u8, handler: ParsedHandler) !void {
        try self.components.append(.{ .custom_id = custom_id, .handler = handler });
    }

    pub fn componentPrefix(self: *InteractionRouterBuilder, prefix: []const u8, handler: ParsedHandler) !void {
        try self.components.append(.{ .custom_id = prefix, .handler = handler, .match = .prefix });
    }

    pub fn componentWithGuard(
        self: *InteractionRouterBuilder,
        custom_id: []const u8,
        handler: ParsedHandler,
        guard: Middleware,
    ) !void {
        try self.components.append(.{ .custom_id = custom_id, .handler = handler, .guard = guard });
    }

    pub fn modal(self: *InteractionRouterBuilder, custom_id: []const u8, handler: ParsedHandler) !void {
        try self.modals.append(.{ .custom_id = custom_id, .handler = handler });
    }

    pub fn modalPrefix(self: *InteractionRouterBuilder, prefix: []const u8, handler: ParsedHandler) !void {
        try self.modals.append(.{ .custom_id = prefix, .handler = handler, .match = .prefix });
    }

    pub fn use(self: *InteractionRouterBuilder, middleware: Middleware) !void {
        try self.middleware.append(middleware);
    }

    pub fn fallbackTo(self: *InteractionRouterBuilder, handler: ParsedHandler) void {
        self.fallback = handler;
    }

    pub fn router(self: *const InteractionRouterBuilder) InteractionRouter {
        return .{
            .commands = self.commands.items,
            .autocomplete = self.autocomplete.items,
            .components = self.components.items,
            .modals = self.modals.items,
            .middleware = self.middleware.items,
            .fallback = self.fallback,
        };
    }
};

pub fn parsedHandler(ptr: anytype, comptime function: anytype) ParsedHandler {
    const Ptr = @TypeOf(ptr);
    const wrapper = struct {
        pub fn call(raw: *anyopaque, interaction: *const ParsedInteraction) anyerror!void {
            const typed: Ptr = @ptrCast(@alignCast(raw));
            try function(typed, interaction);
        }
    };

    return .{ .ptr = ptr, .callFn = wrapper.call };
}

pub fn middlewareHandler(ptr: anytype, comptime function: anytype) Middleware {
    const Ptr = @TypeOf(ptr);
    const wrapper = struct {
        pub fn call(raw: *anyopaque, interaction: *const ParsedInteraction) anyerror!bool {
            const typed: Ptr = @ptrCast(@alignCast(raw));
            return function(typed, interaction);
        }
    };

    return .{ .ptr = ptr, .callFn = wrapper.call };
}

pub fn parseInteraction(allocator: std.mem.Allocator, payload: []const u8) !ParsedInteraction {
    var parsed = try std.json.parseFromSlice(std.json.Value, allocator, payload, .{});
    errdefer parsed.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    errdefer arena.deinit();
    const arena_allocator = arena.allocator();

    const root = try objectValue(parsed.value);
    const interaction_type = try interactionTypeValue(root.get("type") orelse return error.MissingField);
    const data_value = root.get("data");
    const data = switch (interaction_type) {
        .application_command, .application_command_autocomplete => if (data_value) |value| try commandDataFromJson(arena_allocator, value) else null,
        else => null,
    };
    const component_data = switch (interaction_type) {
        .message_component, .modal_submit => if (data_value) |value| try componentDataFromJson(arena_allocator, value) else null,
        else => null,
    };

    return .{
        .parsed = parsed,
        .arena = arena,
        .interaction = .{
            .id = try snowflakeField(root, "id"),
            .application_id = try snowflakeField(root, "application_id"),
            .type = interaction_type,
            .token = try stringField(root, "token"),
            .guild_id = if (root.get("guild_id")) |value| try snowflakeValue(value) else null,
            .channel_id = if (root.get("channel_id")) |value| try snowflakeValue(value) else null,
            .user_id = try interactionUserId(root),
        },
        .data = data,
        .component_data = component_data,
    };
}

pub fn interactionUserId(root: std.json.ObjectMap) !?Snowflake {
    if (root.get("member")) |member_value| {
        const member = try objectValue(member_value);
        if (member.get("user")) |user_value| {
            const user = try objectValue(user_value);
            return try snowflakeField(user, "id");
        }
    }
    if (root.get("user")) |user_value| {
        const user = try objectValue(user_value);
        return try snowflakeField(user, "id");
    }
    return null;
}

pub const InteractionResponse = struct {
    type: CallbackType,
    content: ?[]const u8 = null,
    ephemeral: bool = false,
    custom_id: ?[]const u8 = null,
    title: ?[]const u8 = null,
    components: []const Component = &.{},
    choices: []const CommandChoice = &.{},

    pub fn pong() InteractionResponse {
        return .{ .type = .pong };
    }

    pub fn message(content: []const u8) InteractionResponse {
        return .{
            .type = .channel_message_with_source,
            .content = content,
        };
    }

    pub fn deferredMessage(ephemeral: bool) InteractionResponse {
        return .{
            .type = .deferred_channel_message_with_source,
            .ephemeral = ephemeral,
        };
    }

    pub fn deferredUpdate() InteractionResponse {
        return .{ .type = .deferred_update_message };
    }

    pub fn updateMessage(content: []const u8) InteractionResponse {
        return .{
            .type = .update_message,
            .content = content,
        };
    }

    pub fn autocomplete(choices: []const CommandChoice) InteractionResponse {
        return .{
            .type = .application_command_autocomplete_result,
            .choices = choices,
        };
    }

    pub fn modal(custom_id: []const u8, title: []const u8, components: []const Component) InteractionResponse {
        return .{
            .type = .modal,
            .custom_id = custom_id,
            .title = title,
            .components = components,
        };
    }

    pub fn ephemeralState(self: InteractionResponse, ephemeral: bool) InteractionResponse {
        var response = self;
        response.ephemeral = ephemeral;
        return response;
    }

    pub fn withContent(self: InteractionResponse, content: []const u8) InteractionResponse {
        var response = self;
        response.content = content;
        return response;
    }

    pub fn withComponents(self: InteractionResponse, components: []const Component) InteractionResponse {
        var response = self;
        response.components = components;
        return response;
    }

    pub fn withChoices(self: InteractionResponse, choices: []const CommandChoice) InteractionResponse {
        var response = self;
        response.choices = choices;
        return response;
    }

    pub fn writeJson(self: InteractionResponse, writer: anytype) !void {
        try writer.print("{{\"type\":{d}", .{@intFromEnum(self.type)});
        if (self.content != null or self.ephemeral or self.custom_id != null or self.title != null or self.components.len != 0 or self.choices.len != 0) {
            try writer.writeAll(",\"data\":{");
            var needs_comma = false;
            if (self.content) |content| {
                try writer.writeAll("\"content\":");
                try Json.writeString(content, writer);
                needs_comma = true;
            }
            if (self.ephemeral) {
                if (needs_comma) try writer.writeByte(',');
                try writer.writeAll("\"flags\":64");
                needs_comma = true;
            }
            if (self.custom_id) |custom_id| {
                if (needs_comma) try writer.writeByte(',');
                try writer.writeAll("\"custom_id\":");
                try Json.writeString(custom_id, writer);
                needs_comma = true;
            }
            if (self.title) |title| {
                if (needs_comma) try writer.writeByte(',');
                try writer.writeAll("\"title\":");
                try Json.writeString(title, writer);
                needs_comma = true;
            }
            if (self.components.len != 0) {
                if (needs_comma) try writer.writeByte(',');
                try writer.writeAll("\"components\":");
                try writeComponentArray(self.components, writer);
                needs_comma = true;
            }
            if (self.choices.len != 0) {
                if (needs_comma) try writer.writeByte(',');
                try writer.writeAll("\"choices\":");
                try writeChoiceArray(self.choices, writer);
            }
            try writer.writeByte('}');
        }
        try writer.writeByte('}');
    }
};

pub const IntegrationType = enum(u8) {
    guild_install = 0,
    user_install = 1,
};

pub const InteractionContextType = enum(u8) {
    guild = 0,
    bot_dm = 1,
    private_channel = 2,
};

pub fn writeEnumIntArray(comptime T: type, values: []const T, writer: anytype) !void {
    try writer.writeByte('[');
    for (values, 0..) |value, index| {
        if (index != 0) try writer.writeByte(',');
        try writer.print("{d}", .{@intFromEnum(value)});
    }
    try writer.writeByte(']');
}

pub const ApplicationCommand = struct {
    name: []const u8,
    description: []const u8,
    type: ApplicationCommandType = .chat_input,
    options: []const ApplicationCommandOption = &.{},
    name_localizations: []const Localization = &.{},
    description_localizations: []const Localization = &.{},
    default_member_permissions: ?u64 = null,
    clear_default_member_permissions: bool = false,
    dm_permission: ?bool = null,
    nsfw: ?bool = null,
    integration_types: []const IntegrationType = &.{},
    contexts: []const InteractionContextType = &.{},

    pub fn chatInput(name: []const u8, description: []const u8) ApplicationCommand {
        return .{
            .name = name,
            .description = description,
            .type = .chat_input,
        };
    }

    pub fn user(name: []const u8) ApplicationCommand {
        return .{
            .name = name,
            .description = "",
            .type = .user,
        };
    }

    pub fn message(name: []const u8) ApplicationCommand {
        return .{
            .name = name,
            .description = "",
            .type = .message,
        };
    }

    pub fn withOptions(self: ApplicationCommand, options: []const ApplicationCommandOption) ApplicationCommand {
        var command = self;
        command.options = options;
        return command;
    }

    pub fn withOption(self: ApplicationCommand, option: *const ApplicationCommandOption) ApplicationCommand {
        var command = self;
        command.options = option[0..1];
        return command;
    }

    pub fn withNameLocalizations(self: ApplicationCommand, localizations: []const Localization) ApplicationCommand {
        var command = self;
        command.name_localizations = localizations;
        return command;
    }

    pub fn withDescriptionLocalizations(self: ApplicationCommand, localizations: []const Localization) ApplicationCommand {
        var command = self;
        command.description_localizations = localizations;
        return command;
    }

    pub fn withDefaultMemberPermissions(self: ApplicationCommand, permissions: u64) ApplicationCommand {
        var command = self;
        command.default_member_permissions = permissions;
        command.clear_default_member_permissions = false;
        return command;
    }

    pub fn clearDefaultMemberPermissions(self: ApplicationCommand) ApplicationCommand {
        var command = self;
        command.default_member_permissions = null;
        command.clear_default_member_permissions = true;
        return command;
    }

    pub fn dmPermissionState(self: ApplicationCommand, allowed: bool) ApplicationCommand {
        var command = self;
        command.dm_permission = allowed;
        return command;
    }

    pub fn nsfwState(self: ApplicationCommand, nsfw: bool) ApplicationCommand {
        var command = self;
        command.nsfw = nsfw;
        return command;
    }

    pub fn withIntegrationTypes(self: ApplicationCommand, integration_types: []const IntegrationType) ApplicationCommand {
        var command = self;
        command.integration_types = integration_types;
        return command;
    }

    pub fn withContexts(self: ApplicationCommand, contexts: []const InteractionContextType) ApplicationCommand {
        var command = self;
        command.contexts = contexts;
        return command;
    }

    /// Rejects a command that breaks a Discord limit: name length, description
    /// rules (chat-input commands need 1-100 chars; user/message commands must
    /// have an empty description), option count, or any invalid option subtree.
    pub fn validate(self: ApplicationCommand) ValidationError!void {
        try checkNameLen(self.name, error.CommandNameInvalid);
        switch (self.type) {
            .chat_input => try checkDescriptionLen(self.description, error.CommandDescriptionInvalid),
            .user, .message => {
                const len = Json.codepointLen(self.description) catch return error.InvalidUtf8;
                if (len != 0) return error.CommandDescriptionInvalid;
            },
        }
        if (self.options.len > max_command_options) return error.TooManyCommandOptions;
        for (self.options) |option| try option.validate();
    }

    pub fn writeJson(self: ApplicationCommand, writer: anytype) !void {
        try writer.writeByte('{');
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);
        try writer.writeAll(",\"description\":");
        try Json.writeString(self.description, writer);
        try writer.print(",\"type\":{d}", .{@intFromEnum(self.type)});
        if (self.options.len != 0) {
            try writer.writeAll(",\"options\":");
            try writeOptionArray(self.options, writer);
        }
        if (self.name_localizations.len != 0) {
            try writer.writeAll(",\"name_localizations\":");
            try writeLocalizationObject(self.name_localizations, writer);
        }
        if (self.description_localizations.len != 0) {
            try writer.writeAll(",\"description_localizations\":");
            try writeLocalizationObject(self.description_localizations, writer);
        }
        if (self.default_member_permissions) |permissions| {
            try writer.print(",\"default_member_permissions\":\"{d}\"", .{permissions});
        } else if (self.clear_default_member_permissions) {
            try writer.writeAll(",\"default_member_permissions\":null");
        }
        if (self.dm_permission) |allowed| {
            try writer.writeAll(",\"dm_permission\":");
            try writer.writeAll(if (allowed) "true" else "false");
        }
        if (self.nsfw) |is_nsfw| {
            try writer.writeAll(",\"nsfw\":");
            try writer.writeAll(if (is_nsfw) "true" else "false");
        }
        if (self.integration_types.len != 0) {
            try writer.writeAll(",\"integration_types\":");
            try writeEnumIntArray(IntegrationType, self.integration_types, writer);
        }
        if (self.contexts.len != 0) {
            try writer.writeAll(",\"contexts\":");
            try writeEnumIntArray(InteractionContextType, self.contexts, writer);
        }
        try writer.writeByte('}');
    }
};

pub const ApplicationCommandAnnotationKind = enum {
    chat_input,
    user,
    message,
};
