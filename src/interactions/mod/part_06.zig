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

pub fn objectValue(value: std.json.Value) !std.json.ObjectMap {
    return switch (value) {
        .object => |object| object,
        else => error.InvalidField,
    };
}

pub fn arrayValue(value: std.json.Value) !std.json.Array {
    return switch (value) {
        .array => |array| array,
        else => error.InvalidField,
    };
}

pub fn snowflakeField(object: std.json.ObjectMap, field: []const u8) !Snowflake {
    return snowflakeValue(object.get(field) orelse return error.MissingField);
}

pub fn snowflakeValue(value: std.json.Value) !Snowflake {
    return Snowflake.parse(try stringValue(value));
}

pub fn stringField(object: std.json.ObjectMap, field: []const u8) ![]const u8 {
    return stringValue(object.get(field) orelse return error.MissingField);
}

pub fn stringValue(value: std.json.Value) ![]const u8 {
    return switch (value) {
        .string => |string| string,
        else => error.InvalidField,
    };
}

pub fn integerValue(value: std.json.Value) !i64 {
    return switch (value) {
        .integer => |integer| @intCast(integer),
        else => error.InvalidField,
    };
}

pub fn numberValue(value: std.json.Value) !f64 {
    return switch (value) {
        .float => |float| float,
        .integer => |integer| @floatFromInt(integer),
        else => error.InvalidField,
    };
}

pub fn boolValue(value: std.json.Value) !bool {
    return switch (value) {
        .bool => |boolean| boolean,
        else => error.InvalidField,
    };
}

pub fn interactionTypeValue(value: std.json.Value) !InteractionType {
    const raw: u8 = @intCast(try integerValue(value));
    return switch (raw) {
        1 => .ping,
        2 => .application_command,
        3 => .message_component,
        4 => .application_command_autocomplete,
        5 => .modal_submit,
        else => error.InvalidField,
    };
}

pub fn applicationCommandTypeValue(value: std.json.Value) !ApplicationCommandType {
    const raw: u8 = @intCast(try integerValue(value));
    return switch (raw) {
        1 => .chat_input,
        2 => .user,
        3 => .message,
        else => error.InvalidField,
    };
}

pub fn applicationCommandOptionTypeValue(value: std.json.Value) !ApplicationCommandOptionType {
    const raw: u8 = @intCast(try integerValue(value));
    return switch (raw) {
        1 => .sub_command,
        2 => .sub_command_group,
        3 => .string,
        4 => .integer,
        5 => .boolean,
        6 => .user,
        7 => .channel,
        8 => .role,
        9 => .mentionable,
        10 => .number,
        11 => .attachment,
        else => error.InvalidField,
    };
}

pub fn componentTypeValue(value: std.json.Value) !ComponentType {
    const raw: u8 = @intCast(try integerValue(value));
    return switch (raw) {
        1 => .action_row,
        2 => .button,
        3 => .string_select,
        4 => .text_input,
        5 => .user_select,
        6 => .role_select,
        7 => .mentionable_select,
        8 => .channel_select,
        else => error.InvalidField,
    };
}

pub const ButtonBuilder = Button;

pub const StringSelectMenuBuilder = StringSelect;

pub const UserSelectMenuBuilder = AutoSelect;

pub const RoleSelectMenuBuilder = AutoSelect;

pub const MentionableSelectMenuBuilder = AutoSelect;

pub const ChannelSelectMenuBuilder = AutoSelect;

pub const TextInputBuilder = TextInput;

pub const ActionRowBuilder = Component;

pub const SlashCommandBuilder = ApplicationCommand;

pub const ContextMenuCommandBuilder = ApplicationCommand;

pub const SlashCommandOptionBuilder = ApplicationCommandOption;

pub const SlashCommandStringOption = ApplicationCommandOption;

pub const SlashCommandIntegerOption = ApplicationCommandOption;

pub const SlashCommandNumberOption = ApplicationCommandOption;

pub const SlashCommandBooleanOption = ApplicationCommandOption;

pub const SlashCommandUserOption = ApplicationCommandOption;

pub const SlashCommandChannelOption = ApplicationCommandOption;

pub const SlashCommandRoleOption = ApplicationCommandOption;

pub const SlashCommandMentionableOption = ApplicationCommandOption;

pub const SlashCommandAttachmentOption = ApplicationCommandOption;

pub const SlashCommandSubcommandBuilder = ApplicationCommandOption;

pub const SlashCommandSubcommandGroupBuilder = ApplicationCommandOption;

pub const StringSelectMenuOptionBuilder = SelectOption;

pub const ModalBuilder = InteractionResponse;

pub const EmbedBuilder = @import("../../models/types.zig").Embed;

test "discordjs style builder aliases compile to existing builders" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const choices = [_]CommandChoice{CommandChoice.string("Ada", "ada")};
    const options = [_]ApplicationCommandOption{
        SlashCommandStringOption.string("user", "Target user", true).withChoices(&choices),
    };
    const row_children = [_]Component{
        .{ .button = ButtonBuilder.primary("confirm", "Confirm") },
    };

    try SlashCommandBuilder.chatInput("inspect", "Inspect a user")
        .withOptions(&options)
        .writeJson(&out.writer);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "\"name\":\"inspect\"") != null);

    var components_out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer components_out.deinit();
    try ActionRowBuilder.actionRow(&row_children).writeJson(&components_out.writer);
    try std.testing.expectEqualStrings(
        "{\"type\":1,\"components\":[{\"type\":2,\"style\":1,\"custom_id\":\"confirm\",\"label\":\"Confirm\"}]}",
        components_out.written(),
    );
}

test "interaction response supports ephemeral message" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try InteractionResponse.message("private pong")
        .ephemeralState(true)
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"type\":4,\"data\":{\"content\":\"private pong\",\"flags\":64}}",
        out.written(),
    );
}

test "message component response JSON" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const row_children = [_]Component{
        .{ .button = Button.success("confirm", "Confirm") },
    };
    const rows = [_]Component{
        Component.actionRow(&row_children),
    };

    try InteractionResponse.message("Choose an action")
        .withComponents(&rows)
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"type\":4,\"data\":{\"content\":\"Choose an action\",\"components\":[{\"type\":1,\"components\":[{\"type\":2,\"style\":3,\"custom_id\":\"confirm\",\"label\":\"Confirm\"}]}]}}",
        out.written(),
    );
}

test "button and action row single component helpers write component JSON" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const button = Component{ .button = Button.danger("delete", "Delete").disabledState(true) };
    const row = Component.actionRowWithComponent(&button);

    try row.writeJson(&out.writer);
    try std.testing.expectEqualStrings(
        "{\"type\":1,\"components\":[{\"type\":2,\"style\":4,\"custom_id\":\"delete\",\"label\":\"Delete\",\"disabled\":true}]}",
        out.written(),
    );
}

test "select option builder helpers write description and default state" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const options = [_]SelectOption{
        SelectOption.init("Public", "public").withDescription("Visible to everyone"),
        SelectOption.init("Private", "private").defaultState(true),
    };

    try writeSelectOptionArray(&options, &out.writer);
    try std.testing.expectEqualStrings(
        "[{\"label\":\"Public\",\"value\":\"public\",\"description\":\"Visible to everyone\"},{\"label\":\"Private\",\"value\":\"private\",\"default\":true}]",
        out.written(),
    );
}

test "auto select component JSON" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const row_children = [_]Component{
        .{ .user_select = AutoSelect.user("assignee").withPlaceholder("Pick user").withValueRange(1, 2) },
        .{ .channel_select = AutoSelect.channel("target", &.{ 0, 11 }).disabledState(true) },
    };
    const rows = [_]Component{
        Component.actionRow(&row_children),
    };

    try writeComponentArray(&rows, &out.writer);
    try std.testing.expectEqualStrings(
        "[{\"type\":1,\"components\":[{\"type\":5,\"custom_id\":\"assignee\",\"placeholder\":\"Pick user\",\"min_values\":1,\"max_values\":2},{\"type\":8,\"custom_id\":\"target\",\"disabled\":true,\"channel_types\":[0,11]}]}]",
        out.written(),
    );
}

test "autocomplete interaction response JSON" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const choices = [_]CommandChoice{
        CommandChoice.string("Public", "public"),
        CommandChoice.integer("Ten", 10),
        CommandChoice.number("Half", 0.5),
    };

    try InteractionResponse.autocomplete(&choices).writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"type\":8,\"data\":{\"choices\":[{\"name\":\"Public\",\"value\":\"public\"},{\"name\":\"Ten\",\"value\":10},{\"name\":\"Half\",\"value\":0.5}]}}",
        out.written(),
    );
}

test "modal response JSON" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const name_input = [_]Component{
        .{ .text_input = TextInput.short("name", "Name") },
    };
    const rows = [_]Component{
        Component.actionRow(&name_input),
    };

    try InteractionResponse.modal("profile_modal", "Edit profile", &rows).writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"type\":9,\"data\":{\"custom_id\":\"profile_modal\",\"title\":\"Edit profile\",\"components\":[{\"type\":1,\"components\":[{\"type\":4,\"custom_id\":\"name\",\"label\":\"Name\",\"style\":1}]}]}}",
        out.written(),
    );
}

test "application command array JSON" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try writeApplicationCommandArray(&.{
        ApplicationCommand.chatInput("ping", "Replies with pong"),
        ApplicationCommand.chatInput("help", "Shows commands"),
    }, &out.writer);

    try std.testing.expectEqualStrings(
        "[{\"name\":\"ping\",\"description\":\"Replies with pong\",\"type\":1},{\"name\":\"help\",\"description\":\"Shows commands\",\"type\":1}]",
        out.written(),
    );
}

test "application command metadata helpers write localization permissions and visibility" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const name_localizations = [_]Localization{
        .{ .locale = "tr", .value = "yay" },
    };
    const description_localizations = [_]Localization{
        .{ .locale = "tr", .value = "Mesaj yayinlar" },
    };

    try ApplicationCommand
        .chatInput("publish", "Publishes a message")
        .withNameLocalizations(&name_localizations)
        .withDescriptionLocalizations(&description_localizations)
        .withDefaultMemberPermissions(8)
        .dmPermissionState(false)
        .nsfwState(true)
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"name\":\"publish\",\"description\":\"Publishes a message\",\"type\":1,\"name_localizations\":{\"tr\":\"yay\"},\"description_localizations\":{\"tr\":\"Mesaj yayinlar\"},\"default_member_permissions\":\"8\",\"dm_permission\":false,\"nsfw\":true}",
        out.written(),
    );
}

test "edit application command JSON emits only provided fields" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const options = [_]ApplicationCommandOption{
        ApplicationCommandOption.string("text", "Text to echo", true),
    };

    try EditApplicationCommand.init()
        .withDescription("Echoes the supplied text")
        .withOptions(&options)
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"description\":\"Echoes the supplied text\",\"options\":[{\"type\":3,\"name\":\"text\",\"description\":\"Text to echo\",\"required\":true}]}",
        out.written(),
    );
}

test "edit application command metadata helpers write partial fields" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const name_localizations = [_]Localization{
        .{ .locale = "tr", .value = "profil" },
    };

    try EditApplicationCommand
        .init()
        .withNameLocalizations(&name_localizations)
        .clearDefaultMemberPermissions()
        .dmPermissionState(true)
        .nsfwState(false)
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"name_localizations\":{\"tr\":\"profil\"},\"default_member_permissions\":null,\"dm_permission\":true,\"nsfw\":false}",
        out.written(),
    );
}

test "application command permissions update JSON" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const permissions = [_]ApplicationCommandPermission{
        ApplicationCommandPermission.role(Snowflake.init(10), true),
        ApplicationCommandPermission.channel(Snowflake.init(20), false),
    };

    try ApplicationCommandPermissionsUpdate.init(&permissions).writeJson(&out.writer);
    try std.testing.expectEqualStrings(
        "{\"permissions\":[{\"id\":\"10\",\"type\":1,\"permission\":true},{\"id\":\"20\",\"type\":3,\"permission\":false}]}",
        out.written(),
    );
}

test "application command options JSON" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const choices = [_]CommandChoice{
        CommandChoice.string("Public", "public"),
        CommandChoice.string("Private", "private"),
    };
    const options = [_]ApplicationCommandOption{
        ApplicationCommandOption.string("visibility", "Who can see the reply", true).withChoices(&choices),
        ApplicationCommandOption.integer("count", "How many times", false),
    };

    try ApplicationCommand.chatInput("echo", "Echoes text")
        .withOptions(&options)
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"name\":\"echo\",\"description\":\"Echoes text\",\"type\":1,\"options\":[{\"type\":3,\"name\":\"visibility\",\"description\":\"Who can see the reply\",\"required\":true,\"choices\":[{\"name\":\"Public\",\"value\":\"public\"},{\"name\":\"Private\",\"value\":\"private\"}]},{\"type\":4,\"name\":\"count\",\"description\":\"How many times\"}]}",
        out.written(),
    );
}

test "application command single option and choice helpers compose JSON" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const choice = CommandChoice.string("Public", "public");
    const visibility = ApplicationCommandOption
        .string("visibility", "Who can see it", false)
        .requiredOption()
        .withChoice(&choice);

    try ApplicationCommand
        .chatInput("publish", "Publishes a message")
        .withOption(&visibility)
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"name\":\"publish\",\"description\":\"Publishes a message\",\"type\":1,\"options\":[{\"type\":3,\"name\":\"visibility\",\"description\":\"Who can see it\",\"required\":true,\"choices\":[{\"name\":\"Public\",\"value\":\"public\"}]}]}",
        out.written(),
    );
}

test "application command option localization helpers compose JSON" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const name_localizations = [_]Localization{
        .{ .locale = "tr", .value = "hedef" },
    };
    const description_localizations = [_]Localization{
        .{ .locale = "tr", .value = "Incelenecek kullanici" },
    };

    try ApplicationCommandOption
        .user("target", "User to inspect", false)
        .withNameLocalizations(&name_localizations)
        .withDescriptionLocalizations(&description_localizations)
        .requiredOption()
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"type\":6,\"name\":\"target\",\"description\":\"User to inspect\",\"name_localizations\":{\"tr\":\"hedef\"},\"description_localizations\":{\"tr\":\"Incelenecek kullanici\"},\"required\":true}",
        out.written(),
    );
}

test "subcommand single child option helper composes JSON" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const target = ApplicationCommandOption.user("target", "User to inspect", false).requiredState(true);
    const subcommand = ApplicationCommandOption.subCommand("info", "Shows user info", &.{}).withOption(&target);

    try subcommand.writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"type\":1,\"name\":\"info\",\"description\":\"Shows user info\",\"options\":[{\"type\":6,\"name\":\"target\",\"description\":\"User to inspect\",\"required\":true}]}",
        out.written(),
    );
}

test "nested subcommand option JSON" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const nested = [_]ApplicationCommandOption{
        ApplicationCommandOption.user("target", "User to inspect", true),
    };
    const options = [_]ApplicationCommandOption{
        ApplicationCommandOption.subCommand("info", "Shows user info", &nested),
    };

    try writeOptionArray(&options, &out.writer);

    try std.testing.expectEqualStrings(
        "[{\"type\":1,\"name\":\"info\",\"description\":\"Shows user info\",\"options\":[{\"type\":6,\"name\":\"target\",\"description\":\"User to inspect\",\"required\":true}]}]",
        out.written(),
    );
}

test "application command option helpers cover current Discord option types" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const options = [_]ApplicationCommandOption{
        ApplicationCommandOption.number("ratio", "Ratio to apply", true),
        ApplicationCommandOption.role("role", "Role to target", true),
        ApplicationCommandOption.mentionable("target", "User or role to target", false),
        ApplicationCommandOption.attachment("file", "File to process", false),
    };

    try writeOptionArray(&options, &out.writer);

    try std.testing.expectEqualStrings(
        "[{\"type\":10,\"name\":\"ratio\",\"description\":\"Ratio to apply\",\"required\":true},{\"type\":8,\"name\":\"role\",\"description\":\"Role to target\",\"required\":true},{\"type\":9,\"name\":\"target\",\"description\":\"User or role to target\"},{\"type\":11,\"name\":\"file\",\"description\":\"File to process\"}]",
        out.written(),
    );
}

test "application command subcommand group helper JSON" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const nested = [_]ApplicationCommandOption{
        ApplicationCommandOption.user("target", "User to inspect", true),
    };
    const subcommands = [_]ApplicationCommandOption{
        ApplicationCommandOption.subCommand("info", "Shows user info", &nested),
    };
    const options = [_]ApplicationCommandOption{
        ApplicationCommandOption.subCommandGroup("user", "User commands", &subcommands),
    };

    try writeOptionArray(&options, &out.writer);

    try std.testing.expectEqualStrings(
        "[{\"type\":2,\"name\":\"user\",\"description\":\"User commands\",\"options\":[{\"type\":1,\"name\":\"info\",\"description\":\"Shows user info\",\"options\":[{\"type\":6,\"name\":\"target\",\"description\":\"User to inspect\",\"required\":true}]}]}]",
        out.written(),
    );
}

test "string select component JSON" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const options = [_]SelectOption{
        SelectOption.init("One", "1").withEmoji(ComponentEmoji.unicode("1️⃣")),
        .{ .label = "Two", .value = "2", .default = true },
    };
    const component = Component{ .string_select = StringSelect.init("numbers", &options).withPlaceholder("Pick").withValueRange(1, 1).disabledState(true) };

    try component.writeJson(&out.writer);
    try std.testing.expectEqualStrings(
        "{\"type\":3,\"custom_id\":\"numbers\",\"options\":[{\"label\":\"One\",\"value\":\"1\",\"emoji\":{\"name\":\"1️⃣\"}},{\"label\":\"Two\",\"value\":\"2\",\"default\":true}],\"placeholder\":\"Pick\",\"min_values\":1,\"max_values\":1,\"disabled\":true}",
        out.written(),
    );
}

test "button emoji premium and style validation" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const button = Component{ .button = Button.primary("confirm", "Confirm").withEmoji(ComponentEmoji.unicode("✅")) };
    try button.validate();
    try button.writeJson(&out.writer);
    try std.testing.expectEqualStrings(
        "{\"type\":2,\"style\":1,\"custom_id\":\"confirm\",\"label\":\"Confirm\",\"emoji\":{\"name\":\"✅\"}}",
        out.written(),
    );

    try std.testing.expectError(error.ButtonUrlRequired, (Button{ .style = .link, .label = "Docs" }).validate());
    try std.testing.expectError(error.ButtonCustomIdRequired, (Button{ .style = .primary, .label = "Missing id" }).validate());
    try Button.premium(Snowflake.init(42)).validate();
    try std.testing.expectError(error.ButtonFieldConflict, Button.premium(Snowflake.init(42)).withEmoji(ComponentEmoji.unicode("x")).validate());
}

test "text input component builder helpers JSON" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const input = Component{
        .text_input = TextInput
            .paragraph("bio", "Bio")
            .optional()
            .withPlaceholder("Tell us about yourself")
            .withValue("Built with Zig")
            .withLengthRange(2, 400),
    };

    try input.writeJson(&out.writer);
    try std.testing.expectEqualStrings(
        "{\"type\":4,\"custom_id\":\"bio\",\"label\":\"Bio\",\"style\":2,\"placeholder\":\"Tell us about yourself\",\"value\":\"Built with Zig\",\"required\":false,\"min_length\":2,\"max_length\":400}",
        out.written(),
    );
}

test "parse application command interaction options" {
    var parsed = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"guild_id\":\"3\",\"channel_id\":\"4\",\"member\":{\"user\":{\"id\":\"7\",\"username\":\"baris\"}},\"data\":{\"id\":\"5\",\"name\":\"echo\",\"type\":1,\"options\":[{\"name\":\"text\",\"type\":3,\"value\":\"hello\"},{\"name\":\"count\",\"type\":4,\"value\":2},{\"name\":\"silent\",\"type\":5,\"value\":true},{\"name\":\"target\",\"type\":6,\"value\":\"42\"}]}}",
    );
    defer parsed.deinit();

    try std.testing.expectEqual(InteractionType.application_command, parsed.interaction.type);
    try std.testing.expectEqualStrings("tok", parsed.interaction.token);
    try std.testing.expectEqual(@as(u64, 7), parsed.interaction.user_id.?.value);
    const data = parsed.data.?;
    try std.testing.expectEqualStrings("echo", data.name);
    try std.testing.expectEqualStrings("hello", try data.getString("text"));
    try std.testing.expectEqual(@as(i64, 2), try data.getInteger("count"));
    try std.testing.expect(try data.getBoolean("silent"));
    try std.testing.expectEqual(@as(u64, 42), (try data.getSnowflake("target")).value);
}

test "parse nested subcommand interaction options" {
    var parsed = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"admin\",\"type\":1,\"options\":[{\"name\":\"ban\",\"type\":1,\"options\":[{\"name\":\"target\",\"type\":6,\"value\":\"99\"}]}]}}",
    );
    defer parsed.deinit();

    const subcommand = parsed.data.?.option("ban").?;
    const nested = try subcommand.getOptions();
    try std.testing.expectEqual(@as(usize, 1), nested.len);
    try std.testing.expectEqualStrings("target", nested[0].name);
    try std.testing.expectEqual(@as(u64, 99), (try nested[0].getSnowflake()).value);
}

test "parse message component interaction values" {
    var parsed = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"user\":{\"id\":\"8\",\"username\":\"dm-user\"},\"data\":{\"custom_id\":\"numbers\",\"component_type\":3,\"values\":[\"1\",\"2\"]}}",
    );
    defer parsed.deinit();

    try std.testing.expectEqual(@as(u64, 8), parsed.interaction.user_id.?.value);
    const data = parsed.component_data.?;
    try std.testing.expectEqual(ComponentType.string_select, data.type.?);
    try std.testing.expectEqualStrings("numbers", data.custom_id);
    try std.testing.expectEqual(@as(usize, 2), data.values.len);
    try std.testing.expectEqualStrings("1", data.values[0]);
    try std.testing.expectEqualStrings("1", data.firstValue().?);
}

test "parse modal submit text input values" {
    var parsed = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":5,\"token\":\"tok\",\"data\":{\"custom_id\":\"profile_modal\",\"components\":[{\"type\":1,\"components\":[{\"type\":4,\"custom_id\":\"name\",\"value\":\"Baris\"}]}]}}",
    );
    defer parsed.deinit();

    const data = parsed.component_data.?;
    try std.testing.expectEqualStrings("profile_modal", data.custom_id);
    const name = data.find("name").?;
    try std.testing.expectEqual(ComponentType.text_input, name.type.?);
    try std.testing.expectEqualStrings("Baris", name.firstValue().?);
}
