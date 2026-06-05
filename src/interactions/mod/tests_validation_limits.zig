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

test "resolved typed channel and member views" {
    var context = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"Move\",\"type\":1,\"resolved\":{\"channels\":{\"20\":{\"id\":\"20\",\"name\":\"general\",\"type\":0,\"permissions\":\"1024\",\"parent_id\":\"19\"}},\"members\":{\"42\":{\"nick\":\"Adabot\",\"joined_at\":\"2024-01-01T00:00:00.000Z\",\"pending\":false,\"permissions\":\"2048\",\"roles\":[\"7\",\"8\"]}}}}}",
    );
    defer context.deinit();
    const resolved = context.data.?.resolved;

    const channel = (try resolved.resolvedChannel(Snowflake.init(20))).?;
    try std.testing.expectEqualStrings("general", channel.name.?);
    try std.testing.expectEqual(@as(u8, 0), channel.type);
    try std.testing.expectEqual(@as(?u64, 1024), channel.permissions);
    try std.testing.expectEqual(@as(u64, 19), channel.parent_id.?.value);
    try std.testing.expect((try resolved.resolvedChannel(Snowflake.init(99))) == null);

    const member = (try resolved.resolvedMember(Snowflake.init(42))).?;
    try std.testing.expectEqualStrings("Adabot", member.nick.?);
    try std.testing.expectEqualStrings("2024-01-01T00:00:00.000Z", member.joined_at.?);
    try std.testing.expectEqual(@as(?u64, 2048), member.permissions);
    try std.testing.expectEqual(@as(usize, 2), member.roleCount());
    try std.testing.expectEqual(@as(u64, 7), (try member.roleAt(0)).?.value);
    try std.testing.expectEqual(@as(u64, 8), (try member.roleAt(1)).?.value);
    try std.testing.expect((try member.roleAt(2)) == null);
}

test "resolved typed attachment and message views" {
    var context = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"Inspect\",\"type\":3,\"target_id\":\"88\",\"resolved\":{\"messages\":{\"88\":{\"id\":\"88\",\"channel_id\":\"20\",\"author\":{\"id\":\"40\",\"username\":\"poster\"},\"content\":\"hello\",\"timestamp\":\"2026-01-01T00:00:00.000Z\",\"pinned\":true,\"type\":0,\"attachments\":[{\"id\":\"77\",\"filename\":\"a.png\",\"size\":2048,\"url\":\"https://cdn/a.png\",\"width\":100,\"height\":50}],\"embeds\":[{\"title\":\"x\"}]}},\"attachments\":{\"77\":{\"id\":\"77\",\"filename\":\"a.png\",\"size\":2048,\"url\":\"https://cdn/a.png\",\"content_type\":\"image/png\",\"width\":100,\"height\":50}}}}}",
    );
    defer context.deinit();
    const data = context.data.?;
    const resolved = data.resolved;

    const message = (try resolved.resolvedMessage(Snowflake.init(88))).?;
    try std.testing.expectEqual(@as(u64, 20), message.channel_id.?.value);
    try std.testing.expectEqual(@as(u64, 40), message.author_id.?.value);
    try std.testing.expectEqualStrings("hello", message.content.?);
    try std.testing.expect(message.pinned);
    try std.testing.expectEqual(@as(usize, 1), message.attachment_count);
    try std.testing.expectEqual(@as(usize, 1), message.embed_count);

    const attachment = (try resolved.resolvedAttachment(Snowflake.init(77))).?;
    try std.testing.expectEqualStrings("a.png", attachment.filename);
    try std.testing.expectEqual(@as(u64, 2048), attachment.size);
    try std.testing.expectEqualStrings("image/png", attachment.content_type.?);
    try std.testing.expectEqual(@as(?u32, 100), attachment.width);
    try std.testing.expectEqual(@as(?u32, 50), attachment.height);

    try std.testing.expect(data.targetMessage() != null);
    try std.testing.expect((try resolved.resolvedAttachment(Snowflake.init(99))) == null);
}

test "interaction router per-route guard gates the handler" {
    const State = struct {
        handled: usize = 0,
        guard_calls: usize = 0,
        allow: bool = true,

        pub fn guard(self: *@This(), interaction: *const ParsedInteraction) !bool {
            _ = interaction;
            self.guard_calls += 1;
            return self.allow;
        }

        pub fn onPing(self: *@This(), interaction: *const ParsedInteraction) !void {
            _ = interaction;
            self.handled += 1;
        }
    };

    var state = State{};
    const commands = [_]CommandRoute{
        .{ .name = "ping", .handler = parsedHandler(&state, State.onPing), .guard = middlewareHandler(&state, State.guard) },
    };
    const router = InteractionRouter{ .commands = &commands };
    const payload = "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"ping\",\"type\":1}}";

    // Guard allows -> handler runs.
    var allowed = try parseInteraction(std.testing.allocator, payload);
    defer allowed.deinit();
    try std.testing.expect(try router.dispatch(&allowed));
    try std.testing.expectEqual(@as(usize, 1), state.handled);
    try std.testing.expectEqual(@as(usize, 1), state.guard_calls);

    // Guard rejects -> handler skipped, dispatch still reports handled.
    state.allow = false;
    var blocked = try parseInteraction(std.testing.allocator, payload);
    defer blocked.deinit();
    try std.testing.expect(try router.dispatch(&blocked));
    try std.testing.expectEqual(@as(usize, 1), state.handled);
    try std.testing.expectEqual(@as(usize, 2), state.guard_calls);
}

test "typed locale codes build localization entries" {
    try std.testing.expectEqualStrings("en-US", Locale.english_us.code());
    try std.testing.expectEqualStrings("pt-BR", Locale.portuguese_brazil.code());
    try std.testing.expectEqualStrings("es-419", Locale.spanish_latam.code());

    const entry = Localization.of(.turkish, "yay");
    try std.testing.expectEqualStrings("tr", entry.locale);
    try std.testing.expectEqualStrings("yay", entry.value);

    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();
    const locales = [_]Localization{
        Localization.of(.english_us, "publish"),
        Localization.of(.turkish, "yayinla"),
    };
    try ApplicationCommand.chatInput("publish", "Publish").withNameLocalizations(&locales).writeJson(&out.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"publish\",\"description\":\"Publish\",\"type\":1,\"name_localizations\":{\"en-US\":\"publish\",\"tr\":\"yayinla\"}}",
        out.written(),
    );
}
