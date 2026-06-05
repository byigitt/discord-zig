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
const InteractionRouter = Root.InteractionRouter;
const InteractionRouterBuilder = Root.InteractionRouterBuilder;
const parsedHandler = Root.parsedHandler;
const middlewareHandler = Root.middlewareHandler;
const parseInteraction = Root.parseInteraction;
const interactionUserId = Root.interactionUserId;
const InteractionResponse = Root.InteractionResponse;
const IntegrationType = Root.IntegrationType;
const InteractionContextType = Root.InteractionContextType;
const writeEnumIntArray = Root.writeEnumIntArray;
const ApplicationCommand = Root.ApplicationCommand;
const ApplicationCommandAnnotationKind = Root.ApplicationCommandAnnotationKind;
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

pub const ApplicationCommandAnnotation = struct {
    kind: ApplicationCommandAnnotationKind = .chat_input,
    name: []const u8,
    description: []const u8 = "",
    options: []const ApplicationCommandOption = &.{},
    default_member_permissions: ?u64 = null,
    dm_permission: ?bool = null,
    integration_types: []const IntegrationType = &.{},
    contexts: []const InteractionContextType = &.{},
    handler: ParsedHandler,
    autocomplete_handler: ?ParsedHandler = null,
    components: []const ComponentRoute = &.{},
    modals: []const ComponentRoute = &.{},
    middleware: []const Middleware = &.{},

    pub fn slash(name: []const u8, description: []const u8, handler: ParsedHandler) ApplicationCommandAnnotation {
        return .{ .name = name, .description = description, .handler = handler };
    }

    pub fn user(name: []const u8, handler: ParsedHandler) ApplicationCommandAnnotation {
        return .{ .kind = .user, .name = name, .handler = handler };
    }

    pub fn message(name: []const u8, handler: ParsedHandler) ApplicationCommandAnnotation {
        return .{ .kind = .message, .name = name, .handler = handler };
    }

    pub fn withOptions(self: ApplicationCommandAnnotation, options: []const ApplicationCommandOption) ApplicationCommandAnnotation {
        var annotation = self;
        annotation.options = options;
        return annotation;
    }

    pub fn withDefaultMemberPermissions(self: ApplicationCommandAnnotation, permissions: u64) ApplicationCommandAnnotation {
        var annotation = self;
        annotation.default_member_permissions = permissions;
        return annotation;
    }

    pub fn withDMPermission(self: ApplicationCommandAnnotation, allowed: bool) ApplicationCommandAnnotation {
        var annotation = self;
        annotation.dm_permission = allowed;
        return annotation;
    }

    pub fn withIntegrationTypes(self: ApplicationCommandAnnotation, integration_types: []const IntegrationType) ApplicationCommandAnnotation {
        var annotation = self;
        annotation.integration_types = integration_types;
        return annotation;
    }

    pub fn withContexts(self: ApplicationCommandAnnotation, contexts: []const InteractionContextType) ApplicationCommandAnnotation {
        var annotation = self;
        annotation.contexts = contexts;
        return annotation;
    }

    pub fn withAutocomplete(self: ApplicationCommandAnnotation, handler: ParsedHandler) ApplicationCommandAnnotation {
        var annotation = self;
        annotation.autocomplete_handler = handler;
        return annotation;
    }

    pub fn withComponents(self: ApplicationCommandAnnotation, components: []const ComponentRoute) ApplicationCommandAnnotation {
        var annotation = self;
        annotation.components = components;
        return annotation;
    }

    pub fn withModals(self: ApplicationCommandAnnotation, modals: []const ComponentRoute) ApplicationCommandAnnotation {
        var annotation = self;
        annotation.modals = modals;
        return annotation;
    }

    pub fn withMiddleware(self: ApplicationCommandAnnotation, middleware: []const Middleware) ApplicationCommandAnnotation {
        var annotation = self;
        annotation.middleware = middleware;
        return annotation;
    }

    pub fn command(self: ApplicationCommandAnnotation) ApplicationCommand {
        var definition = switch (self.kind) {
            .chat_input => ApplicationCommand.chatInput(self.name, self.description),
            .user => ApplicationCommand.user(self.name),
            .message => ApplicationCommand.message(self.name),
        };
        if (self.options.len != 0) definition = definition.withOptions(self.options);
        if (self.default_member_permissions) |permissions| definition = definition.withDefaultMemberPermissions(permissions);
        if (self.dm_permission) |allowed| definition = definition.dmPermissionState(allowed);
        if (self.integration_types.len != 0) definition = definition.withIntegrationTypes(self.integration_types);
        if (self.contexts.len != 0) definition = definition.withContexts(self.contexts);
        return definition;
    }

    pub fn module(self: ApplicationCommandAnnotation) ApplicationCommandModule {
        var module_definition = ApplicationCommandModule.init(self.command(), self.handler)
            .withComponents(self.components)
            .withModals(self.modals)
            .withMiddleware(self.middleware);
        if (self.autocomplete_handler) |handler| module_definition = module_definition.withAutocomplete(handler);
        return module_definition;
    }

    pub fn register(self: ApplicationCommandAnnotation, registry: *ApplicationCommandRegistry) !void {
        var module_definition = ApplicationCommandModule.init(self.command(), self.handler)
            .withComponents(self.components)
            .withModals(self.modals)
            .withMiddleware(self.middleware);
        if (self.autocomplete_handler) |handler| module_definition = module_definition.withAutocomplete(handler);
        try module_definition.register(registry);
    }
};

pub const ApplicationCommandAnnotationManifest = struct {
    annotations: []const ApplicationCommandAnnotation,

    pub fn init(annotations: []const ApplicationCommandAnnotation) ApplicationCommandAnnotationManifest {
        return .{ .annotations = annotations };
    }

    pub fn register(self: ApplicationCommandAnnotationManifest, registry: *ApplicationCommandRegistry) !void {
        for (self.annotations) |annotation| try annotation.register(registry);
    }

    pub fn writeDefinitionsJson(self: ApplicationCommandAnnotationManifest, allocator: std.mem.Allocator, writer: anytype) !void {
        var registry = ApplicationCommandRegistry.init(allocator);
        defer registry.deinit();
        try self.register(&registry);
        try registry.writeDefinitionsJson(writer);
    }
};

pub const ApplicationCommandModule = struct {
    command_definition: ApplicationCommand,
    handler: ParsedHandler,
    autocomplete_handler: ?ParsedHandler = null,
    components: []const ComponentRoute = &.{},
    modals: []const ComponentRoute = &.{},
    middleware: []const Middleware = &.{},

    pub fn init(command_definition: ApplicationCommand, handler: ParsedHandler) ApplicationCommandModule {
        return .{ .command_definition = command_definition, .handler = handler };
    }

    pub fn withAutocomplete(self: ApplicationCommandModule, handler: ParsedHandler) ApplicationCommandModule {
        var module = self;
        module.autocomplete_handler = handler;
        return module;
    }

    pub fn withComponents(self: ApplicationCommandModule, components: []const ComponentRoute) ApplicationCommandModule {
        var module = self;
        module.components = components;
        return module;
    }

    pub fn withModals(self: ApplicationCommandModule, modals: []const ComponentRoute) ApplicationCommandModule {
        var module = self;
        module.modals = modals;
        return module;
    }

    pub fn withMiddleware(self: ApplicationCommandModule, middleware: []const Middleware) ApplicationCommandModule {
        var module = self;
        module.middleware = middleware;
        return module;
    }

    pub fn register(self: ApplicationCommandModule, registry: *ApplicationCommandRegistry) !void {
        try registry.addCommandRoute(self.command_definition, self.handler);
        if (self.autocomplete_handler) |handler| try registry.addAutocompleteRoute(self.command_definition.name, handler);
        for (self.components) |route| try registry.router_builder.components.append(route);
        for (self.modals) |route| try registry.router_builder.modals.append(route);
        for (self.middleware) |middleware| try registry.addMiddleware(middleware);
    }
};

pub const ApplicationCommandManifest = struct {
    modules: []const ApplicationCommandModule,

    pub fn init(modules: []const ApplicationCommandModule) ApplicationCommandManifest {
        return .{ .modules = modules };
    }

    pub fn register(self: ApplicationCommandManifest, registry: *ApplicationCommandRegistry) !void {
        for (self.modules) |module| try module.register(registry);
    }
};

pub const ApplicationCommandRegistry = struct {
    allocator: std.mem.Allocator,
    commands: std.array_list.Managed(ApplicationCommand),
    router_builder: InteractionRouterBuilder,

    pub fn init(allocator: std.mem.Allocator) ApplicationCommandRegistry {
        return .{
            .allocator = allocator,
            .commands = std.array_list.Managed(ApplicationCommand).init(allocator),
            .router_builder = InteractionRouterBuilder.init(allocator),
        };
    }

    pub fn deinit(self: *ApplicationCommandRegistry) void {
        self.commands.deinit();
        self.router_builder.deinit();
    }

    pub fn addCommand(self: *ApplicationCommandRegistry, command_definition: ApplicationCommand) !void {
        try command_definition.validate();
        try self.commands.append(command_definition);
    }

    pub fn addCommandRoute(
        self: *ApplicationCommandRegistry,
        command_definition: ApplicationCommand,
        handler: ParsedHandler,
    ) !void {
        try self.addCommand(command_definition);
        try self.router_builder.command(command_definition.name, handler);
    }

    pub fn addAutocompleteRoute(
        self: *ApplicationCommandRegistry,
        command_name: []const u8,
        handler: ParsedHandler,
    ) !void {
        try self.router_builder.autocompleteRoute(command_name, handler);
    }

    pub fn addComponentRoute(self: *ApplicationCommandRegistry, custom_id: []const u8, handler: ParsedHandler) !void {
        try self.router_builder.component(custom_id, handler);
    }

    pub fn addComponentPrefixRoute(self: *ApplicationCommandRegistry, prefix: []const u8, handler: ParsedHandler) !void {
        try self.router_builder.componentPrefix(prefix, handler);
    }

    pub fn addModalRoute(self: *ApplicationCommandRegistry, custom_id: []const u8, handler: ParsedHandler) !void {
        try self.router_builder.modal(custom_id, handler);
    }

    pub fn addMiddleware(self: *ApplicationCommandRegistry, middleware: Middleware) !void {
        try self.router_builder.use(middleware);
    }

    pub fn fallbackTo(self: *ApplicationCommandRegistry, handler: ParsedHandler) void {
        self.router_builder.fallbackTo(handler);
    }

    pub fn definitions(self: *const ApplicationCommandRegistry) []const ApplicationCommand {
        return self.commands.items;
    }

    pub fn router(self: *const ApplicationCommandRegistry) InteractionRouter {
        return self.router_builder.router();
    }

    pub fn writeDefinitionsJson(self: *const ApplicationCommandRegistry, writer: anytype) !void {
        try writeApplicationCommandArray(self.commands.items, writer);
    }
};

pub const EditApplicationCommand = struct {
    name: ?[]const u8 = null,
    description: ?[]const u8 = null,
    options: ?[]const ApplicationCommandOption = null,
    name_localizations: ?[]const Localization = null,
    description_localizations: ?[]const Localization = null,
    default_member_permissions: ?u64 = null,
    clear_default_member_permissions: bool = false,
    dm_permission: ?bool = null,
    nsfw: ?bool = null,
    integration_types: []const IntegrationType = &.{},
    contexts: []const InteractionContextType = &.{},

    pub fn init() EditApplicationCommand {
        return .{};
    }

    pub fn withName(self: EditApplicationCommand, name: []const u8) EditApplicationCommand {
        var command = self;
        command.name = name;
        return command;
    }

    pub fn withDescription(self: EditApplicationCommand, description: []const u8) EditApplicationCommand {
        var command = self;
        command.description = description;
        return command;
    }

    pub fn withOptions(self: EditApplicationCommand, options: []const ApplicationCommandOption) EditApplicationCommand {
        var command = self;
        command.options = options;
        return command;
    }

    pub fn withNameLocalizations(self: EditApplicationCommand, localizations: []const Localization) EditApplicationCommand {
        var command = self;
        command.name_localizations = localizations;
        return command;
    }

    pub fn withDescriptionLocalizations(self: EditApplicationCommand, localizations: []const Localization) EditApplicationCommand {
        var command = self;
        command.description_localizations = localizations;
        return command;
    }

    pub fn withDefaultMemberPermissions(self: EditApplicationCommand, permissions: u64) EditApplicationCommand {
        var command = self;
        command.default_member_permissions = permissions;
        command.clear_default_member_permissions = false;
        return command;
    }

    pub fn clearDefaultMemberPermissions(self: EditApplicationCommand) EditApplicationCommand {
        var command = self;
        command.default_member_permissions = null;
        command.clear_default_member_permissions = true;
        return command;
    }

    pub fn dmPermissionState(self: EditApplicationCommand, allowed: bool) EditApplicationCommand {
        var command = self;
        command.dm_permission = allowed;
        return command;
    }

    pub fn nsfwState(self: EditApplicationCommand, nsfw: bool) EditApplicationCommand {
        var command = self;
        command.nsfw = nsfw;
        return command;
    }

    pub fn withIntegrationTypes(self: EditApplicationCommand, integration_types: []const IntegrationType) EditApplicationCommand {
        var command = self;
        command.integration_types = integration_types;
        return command;
    }

    pub fn withContexts(self: EditApplicationCommand, contexts: []const InteractionContextType) EditApplicationCommand {
        var command = self;
        command.contexts = contexts;
        return command;
    }

    pub fn writeJson(self: EditApplicationCommand, writer: anytype) !void {
        var needs_comma = false;

        try writer.writeByte('{');
        if (self.name) |name| {
            try writer.writeAll("\"name\":");
            try Json.writeString(name, writer);
            needs_comma = true;
        }
        if (self.description) |description| {
            if (needs_comma) try writer.writeByte(',');
            try writer.writeAll("\"description\":");
            try Json.writeString(description, writer);
            needs_comma = true;
        }
        if (self.options) |options| {
            if (needs_comma) try writer.writeByte(',');
            try writer.writeAll("\"options\":");
            try writeOptionArray(options, writer);
            needs_comma = true;
        }
        if (self.name_localizations) |localizations| {
            if (needs_comma) try writer.writeByte(',');
            try writer.writeAll("\"name_localizations\":");
            try writeLocalizationObject(localizations, writer);
            needs_comma = true;
        }
        if (self.description_localizations) |localizations| {
            if (needs_comma) try writer.writeByte(',');
            try writer.writeAll("\"description_localizations\":");
            try writeLocalizationObject(localizations, writer);
            needs_comma = true;
        }
        if (self.default_member_permissions) |permissions| {
            if (needs_comma) try writer.writeByte(',');
            try writer.print("\"default_member_permissions\":\"{d}\"", .{permissions});
            needs_comma = true;
        } else if (self.clear_default_member_permissions) {
            if (needs_comma) try writer.writeByte(',');
            try writer.writeAll("\"default_member_permissions\":null");
            needs_comma = true;
        }
        if (self.dm_permission) |allowed| {
            if (needs_comma) try writer.writeByte(',');
            try writer.writeAll("\"dm_permission\":");
            try writer.writeAll(if (allowed) "true" else "false");
            needs_comma = true;
        }
        if (self.nsfw) |is_nsfw| {
            if (needs_comma) try writer.writeByte(',');
            try writer.writeAll("\"nsfw\":");
            try writer.writeAll(if (is_nsfw) "true" else "false");
        }
        if (self.integration_types.len != 0) {
            if (needs_comma) try writer.writeByte(',');
            try writer.writeAll("\"integration_types\":");
            try writeEnumIntArray(IntegrationType, self.integration_types, writer);
            needs_comma = true;
        }
        if (self.contexts.len != 0) {
            if (needs_comma) try writer.writeByte(',');
            try writer.writeAll("\"contexts\":");
            try writeEnumIntArray(InteractionContextType, self.contexts, writer);
        }
        try writer.writeByte('}');
    }
};

pub const ApplicationCommandPermissionType = enum(u8) {
    role = 1,
    user = 2,
    channel = 3,
};

pub const ApplicationCommandPermission = struct {
    id: Snowflake,
    type: ApplicationCommandPermissionType,
    permission: bool,

    pub fn role(id: Snowflake, permission: bool) ApplicationCommandPermission {
        return .{ .id = id, .type = .role, .permission = permission };
    }

    pub fn user(id: Snowflake, permission: bool) ApplicationCommandPermission {
        return .{ .id = id, .type = .user, .permission = permission };
    }

    pub fn channel(id: Snowflake, permission: bool) ApplicationCommandPermission {
        return .{ .id = id, .type = .channel, .permission = permission };
    }

    pub fn writeJson(self: ApplicationCommandPermission, writer: anytype) !void {
        try writer.print("{{\"id\":\"{d}\",\"type\":{d},\"permission\":", .{
            self.id.value,
            @intFromEnum(self.type),
        });
        try writer.writeAll(if (self.permission) "true" else "false");
        try writer.writeByte('}');
    }
};

pub const ApplicationCommandPermissionsUpdate = struct {
    permissions: []const ApplicationCommandPermission,

    pub fn init(permissions: []const ApplicationCommandPermission) ApplicationCommandPermissionsUpdate {
        return .{ .permissions = permissions };
    }

    pub fn writeJson(self: ApplicationCommandPermissionsUpdate, writer: anytype) !void {
        try writer.writeAll("{\"permissions\":");
        try writeApplicationCommandPermissionArray(self.permissions, writer);
        try writer.writeByte('}');
    }
};

pub fn writeApplicationCommandPermissionArray(
    permissions: []const ApplicationCommandPermission,
    writer: anytype,
) !void {
    try writer.writeByte('[');
    for (permissions, 0..) |permission, index| {
        if (index != 0) try writer.writeByte(',');
        try permission.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn writeLocalizationObject(localizations: []const Localization, writer: anytype) !void {
    try writer.writeByte('{');
    for (localizations, 0..) |localization, index| {
        if (index != 0) try writer.writeByte(',');
        try Json.writeString(localization.locale, writer);
        try writer.writeByte(':');
        try Json.writeString(localization.value, writer);
    }
    try writer.writeByte('}');
}

pub fn writeOptionArray(options: []const ApplicationCommandOption, writer: anytype) anyerror!void {
    try writer.writeByte('[');
    for (options, 0..) |option, index| {
        if (index != 0) try writer.writeByte(',');
        try option.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn writeChoiceArray(choices: []const CommandChoice, writer: anytype) !void {
    try writer.writeByte('[');
    for (choices, 0..) |choice, index| {
        if (index != 0) try writer.writeByte(',');
        try choice.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn writeApplicationCommandArray(commands: []const ApplicationCommand, writer: anytype) !void {
    try writer.writeByte('[');
    for (commands, 0..) |command, index| {
        if (index != 0) try writer.writeByte(',');
        try command.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn writeComponentArray(components: []const Component, writer: anytype) anyerror!void {
    try writer.writeByte('[');
    for (components, 0..) |component, index| {
        if (index != 0) try writer.writeByte(',');
        try component.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn writeSelectOptionArray(options: []const SelectOption, writer: anytype) !void {
    try writer.writeByte('[');
    for (options, 0..) |option, index| {
        if (index != 0) try writer.writeByte(',');
        try option.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn commandDataFromJson(allocator: std.mem.Allocator, value: std.json.Value) !CommandData {
    const object = try objectValue(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .name = try stringField(object, "name"),
        .type = try applicationCommandTypeValue(object.get("type") orelse return error.MissingField),
        .options = if (object.get("options")) |options| try commandDataOptionsFromJson(allocator, options) else &.{},
        .target_id = if (object.get("target_id")) |field| try snowflakeValue(field) else null,
        .resolved = if (object.get("resolved")) |field| try resolvedFromJson(field) else .{},
    };
}

pub fn commandDataOptionsFromJson(allocator: std.mem.Allocator, value: std.json.Value) anyerror![]const CommandDataOption {
    const array = try arrayValue(value);
    const options = try allocator.alloc(CommandDataOption, array.items.len);
    errdefer allocator.free(options);

    for (array.items, 0..) |item, index| {
        options[index] = try commandDataOptionFromJson(allocator, item);
    }

    return options;
}

pub fn commandDataOptionFromJson(allocator: std.mem.Allocator, value: std.json.Value) anyerror!CommandDataOption {
    const object = try objectValue(value);
    const option_type = try applicationCommandOptionTypeValue(object.get("type") orelse return error.MissingField);
    const name = try stringField(object, "name");

    const option_value: CommandOptionValue = switch (option_type) {
        .sub_command => .{ .sub_command = if (object.get("options")) |options| try commandDataOptionsFromJson(allocator, options) else &.{} },
        .sub_command_group => .{ .sub_command_group = if (object.get("options")) |options| try commandDataOptionsFromJson(allocator, options) else &.{} },
        .string => .{ .string = try stringValue(object.get("value") orelse return error.MissingField) },
        .integer => .{ .integer = try integerValue(object.get("value") orelse return error.MissingField) },
        .boolean => .{ .boolean = try boolValue(object.get("value") orelse return error.MissingField) },
        .user => .{ .user = try snowflakeValue(object.get("value") orelse return error.MissingField) },
        .channel => .{ .channel = try snowflakeValue(object.get("value") orelse return error.MissingField) },
        .role => .{ .role = try snowflakeValue(object.get("value") orelse return error.MissingField) },
        .mentionable => .{ .mentionable = try snowflakeValue(object.get("value") orelse return error.MissingField) },
        .number => .{ .number = try numberValue(object.get("value") orelse return error.MissingField) },
        .attachment => .{ .attachment = try snowflakeValue(object.get("value") orelse return error.MissingField) },
    };

    const focused = if (object.get("focused")) |field| boolValue(field) catch false else false;
    return .{ .name = name, .value = option_value, .focused = focused };
}

pub fn componentDataFromJson(allocator: std.mem.Allocator, value: std.json.Value) anyerror!ComponentData {
    const object = try objectValue(value);
    const component_type = if (object.get("component_type")) |field|
        try componentTypeValue(field)
    else if (object.get("type")) |field|
        try componentTypeValue(field)
    else
        null;

    return .{
        .custom_id = if (object.get("custom_id")) |field| try stringValue(field) else "",
        .type = component_type,
        .values = if (object.get("values")) |field| try stringArrayValue(allocator, field) else &.{},
        .value = if (object.get("value")) |field| try stringValue(field) else null,
        .components = if (object.get("components")) |field| try componentDataArrayFromJson(allocator, field) else &.{},
    };
}

pub fn componentDataArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) anyerror![]const ComponentData {
    const array = try arrayValue(value);
    const components = try allocator.alloc(ComponentData, array.items.len);
    errdefer allocator.free(components);

    for (array.items, 0..) |item, index| {
        components[index] = try componentDataFromJson(allocator, item);
    }

    return components;
}

pub fn stringArrayValue(allocator: std.mem.Allocator, value: std.json.Value) ![]const []const u8 {
    const array = try arrayValue(value);
    const values = try allocator.alloc([]const u8, array.items.len);
    errdefer allocator.free(values);

    for (array.items, 0..) |item, index| {
        values[index] = try stringValue(item);
    }

    return values;
}

pub fn resolvedFromJson(value: std.json.Value) !Resolved {
    const object = try objectValue(value);
    return .{
        .users = resolvedSubObject(object, "users"),
        .members = resolvedSubObject(object, "members"),
        .roles = resolvedSubObject(object, "roles"),
        .channels = resolvedSubObject(object, "channels"),
        .messages = resolvedSubObject(object, "messages"),
        .attachments = resolvedSubObject(object, "attachments"),
    };
}

pub fn resolvedSubObject(object: std.json.ObjectMap, key: []const u8) ?std.json.ObjectMap {
    if (object.get(key)) |field| {
        return switch (field) {
            .object => |inner| inner,
            else => null,
        };
    }
    return null;
}
