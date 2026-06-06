const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Json = @import("../../core/json.zig");

const Root = @import("../mod.zig");
const TextInput = Root.TextInput;
const TextDisplay = Root.TextDisplay;
const Thumbnail = Root.Thumbnail;
const Section = Root.Section;
const MediaGallery = Root.MediaGallery;
const Separator = Root.Separator;
const Container = Root.Container;
const writeSelectOptionArray = Root.writeSelectOptionArray;

pub const InteractionType = enum(u8) {
    ping = 1,
    application_command = 2,
    message_component = 3,
    application_command_autocomplete = 4,
    modal_submit = 5,
};

pub const CallbackType = enum(u8) {
    pong = 1,
    channel_message_with_source = 4,
    deferred_channel_message_with_source = 5,
    deferred_update_message = 6,
    update_message = 7,
    application_command_autocomplete_result = 8,
    modal = 9,
};

pub const ComponentType = enum(u8) {
    action_row = 1,
    button = 2,
    string_select = 3,
    text_input = 4,
    user_select = 5,
    role_select = 6,
    mentionable_select = 7,
    channel_select = 8,
    section = 9,
    text_display = 10,
    thumbnail = 11,
    media_gallery = 12,
    file = 13,
    separator = 14,
    container = 17,

    pub const ActionRow: @This() = .action_row;
    pub const Button: @This() = .button;
    pub const StringSelect: @This() = .string_select;
    pub const TextInput: @This() = .text_input;
    pub const UserSelect: @This() = .user_select;
    pub const RoleSelect: @This() = .role_select;
    pub const MentionableSelect: @This() = .mentionable_select;
    pub const ChannelSelect: @This() = .channel_select;
    pub const Section: @This() = .section;
    pub const TextDisplay: @This() = .text_display;
    pub const Thumbnail: @This() = .thumbnail;
    pub const MediaGallery: @This() = .media_gallery;
    pub const File: @This() = .file;
    pub const Separator: @This() = .separator;
    pub const Container: @This() = .container;

    pub const ComponentTypeInfo = struct {
        value: ComponentType,
        name: []const u8,
    };

    pub const all_component_types = [_]ComponentTypeInfo{
        .{ .value = ComponentType.ActionRow, .name = "ActionRow" },
        .{ .value = ComponentType.Button, .name = "Button" },
        .{ .value = ComponentType.StringSelect, .name = "StringSelect" },
        .{ .value = ComponentType.TextInput, .name = "TextInput" },
        .{ .value = ComponentType.UserSelect, .name = "UserSelect" },
        .{ .value = ComponentType.RoleSelect, .name = "RoleSelect" },
        .{ .value = ComponentType.MentionableSelect, .name = "MentionableSelect" },
        .{ .value = ComponentType.ChannelSelect, .name = "ChannelSelect" },
        .{ .value = ComponentType.Section, .name = "Section" },
        .{ .value = ComponentType.TextDisplay, .name = "TextDisplay" },
        .{ .value = ComponentType.Thumbnail, .name = "Thumbnail" },
        .{ .value = ComponentType.MediaGallery, .name = "MediaGallery" },
        .{ .value = ComponentType.File, .name = "File" },
        .{ .value = ComponentType.Separator, .name = "Separator" },
        .{ .value = ComponentType.Container, .name = "Container" },
    };

    pub fn discordJsName(self: ComponentType) []const u8 {
        return switch (self) {
            .action_row => "ActionRow",
            .button => "Button",
            .string_select => "StringSelect",
            .text_input => "TextInput",
            .user_select => "UserSelect",
            .role_select => "RoleSelect",
            .mentionable_select => "MentionableSelect",
            .channel_select => "ChannelSelect",
            .section => "Section",
            .text_display => "TextDisplay",
            .thumbnail => "Thumbnail",
            .media_gallery => "MediaGallery",
            .file => "File",
            .separator => "Separator",
            .container => "Container",
        };
    }

    pub fn fromDiscordJsName(name: []const u8) ?ComponentType {
        for (all_component_types) |component_type| {
            if (std.mem.eql(u8, component_type.name, name)) return component_type.value;
        }
        return null;
    }
};

pub const ButtonStyle = enum(u8) {
    primary = 1,
    secondary = 2,
    success = 3,
    danger = 4,
    link = 5,
    premium = 6,

    pub const Primary: @This() = .primary;
    pub const Secondary: @This() = .secondary;
    pub const Success: @This() = .success;
    pub const Danger: @This() = .danger;
    pub const Link: @This() = .link;
    pub const Premium: @This() = .premium;

    pub const ButtonStyleInfo = struct {
        value: ButtonStyle,
        name: []const u8,
    };

    pub const all_button_styles = [_]ButtonStyleInfo{
        .{ .value = Primary, .name = "Primary" },
        .{ .value = Secondary, .name = "Secondary" },
        .{ .value = Success, .name = "Success" },
        .{ .value = Danger, .name = "Danger" },
        .{ .value = Link, .name = "Link" },
        .{ .value = Premium, .name = "Premium" },
    };

    pub fn discordJsName(self: ButtonStyle) []const u8 {
        return switch (self) {
            .primary => "Primary",
            .secondary => "Secondary",
            .success => "Success",
            .danger => "Danger",
            .link => "Link",
            .premium => "Premium",
        };
    }

    pub fn fromDiscordJsName(name: []const u8) ?ButtonStyle {
        for (all_button_styles) |style| {
            if (std.mem.eql(u8, style.name, name)) return style.value;
        }
        return null;
    }
};

pub const TextInputStyle = enum(u8) {
    short = 1,
    paragraph = 2,

    pub const Short: @This() = .short;
    pub const Paragraph: @This() = .paragraph;

    pub const TextInputStyleInfo = struct {
        value: TextInputStyle,
        name: []const u8,
    };

    pub const all_text_input_styles = [_]TextInputStyleInfo{
        .{ .value = Short, .name = "Short" },
        .{ .value = Paragraph, .name = "Paragraph" },
    };

    pub fn discordJsName(self: TextInputStyle) []const u8 {
        return switch (self) {
            .short => "Short",
            .paragraph => "Paragraph",
        };
    }

    pub fn fromDiscordJsName(name: []const u8) ?TextInputStyle {
        for (all_text_input_styles) |style| {
            if (std.mem.eql(u8, style.name, name)) return style.value;
        }
        return null;
    }
};

pub const ApplicationCommandType = enum(u8) {
    chat_input = 1,
    user = 2,
    message = 3,
};

pub const max_action_rows = 5;

pub const max_row_components = 5;

pub const max_select_options = 25;

pub const max_command_options = 25;

pub const max_command_choices = 25;

pub const max_custom_id_len = 100;

pub const max_button_label_len = 80;

pub const max_select_placeholder_len = 150;

pub const max_select_option_label_len = 100;

pub const max_select_option_value_len = 100;

pub const max_select_option_description_len = 100;

pub const max_select_values = 25;

pub const max_text_input_label_len = 45;

pub const max_text_input_placeholder_len = 100;

pub const max_text_input_value_len = 4000;

pub const max_command_name_len = 32;

pub const max_command_description_len = 100;

pub const max_choice_name_len = 100;

pub const max_choice_string_value_len = 100;

pub const max_section_components = 3;

pub const max_media_gallery_items = 10;

pub const max_button_sku_id_len = 100;

pub const ValidationError = error{
    TooManyActionRows,
    TooManyRowComponents,
    TooManySelectOptions,
    TooManyCommandOptions,
    TooManyCommandChoices,
    CustomIdTooLong,
    ButtonLabelTooLong,
    ButtonCustomIdRequired,
    ButtonUrlRequired,
    ButtonSkuIdRequired,
    ButtonFieldConflict,
    SelectPlaceholderTooLong,
    SelectOptionLabelTooLong,
    SelectOptionValueTooLong,
    SelectOptionDescriptionTooLong,
    SelectValueRangeInvalid,
    TextInputLabelTooLong,
    TextInputPlaceholderTooLong,
    TextInputValueTooLong,
    CommandNameInvalid,
    CommandDescriptionInvalid,
    OptionNameInvalid,
    OptionDescriptionInvalid,

    ChoiceNameTooLong,
    ChoiceValueTooLong,
    SectionComponentCountInvalid,
    MediaGalleryItemCountInvalid,
    InvalidUtf8,
};

pub fn writeComma(writer: anytype, needs_comma: *bool) !void {
    if (needs_comma.*) {
        try writer.writeByte(',');
    } else {
        needs_comma.* = true;
    }
}

pub fn checkLen(value: []const u8, max_len: usize, too_long: ValidationError) ValidationError!void {
    const len = Json.codepointLen(value) catch return error.InvalidUtf8;
    if (len > max_len) return too_long;
}

pub fn checkNameLen(value: []const u8, invalid: ValidationError) ValidationError!void {
    const len = Json.codepointLen(value) catch return error.InvalidUtf8;
    if (len < 1 or len > max_command_name_len) return invalid;
}

pub fn checkDescriptionLen(value: []const u8, invalid: ValidationError) ValidationError!void {
    const len = Json.codepointLen(value) catch return error.InvalidUtf8;
    if (len < 1 or len > max_command_description_len) return invalid;
}

pub fn checkSelectRange(min_values: ?u8, max_values: ?u8) ValidationError!void {
    if (max_values) |max| {
        if (max < 1 or max > max_select_values) return error.SelectValueRangeInvalid;
    }
    if (min_values) |min| {
        if (min > max_select_values) return error.SelectValueRangeInvalid;
    }
    if (min_values) |min| {
        if (max_values) |max| {
            if (min > max) return error.SelectValueRangeInvalid;
        }
    }
}

pub const Locale = enum {
    indonesian,
    english_us,
    english_gb,
    bulgarian,
    chinese_china,
    chinese_taiwan,
    croatian,
    czech,
    danish,
    dutch,
    finnish,
    french,
    german,
    greek,
    hindi,
    hungarian,
    italian,
    japanese,
    korean,
    lithuanian,
    norwegian,
    polish,
    portuguese_brazil,
    romanian,
    russian,
    spanish_spain,
    spanish_latam,
    swedish,
    thai,
    turkish,
    ukrainian,
    vietnamese,

    pub fn code(self: Locale) []const u8 {
        return switch (self) {
            .indonesian => "id",
            .english_us => "en-US",
            .english_gb => "en-GB",
            .bulgarian => "bg",
            .chinese_china => "zh-CN",
            .chinese_taiwan => "zh-TW",
            .croatian => "hr",
            .czech => "cs",
            .danish => "da",
            .dutch => "nl",
            .finnish => "fi",
            .french => "fr",
            .german => "de",
            .greek => "el",
            .hindi => "hi",
            .hungarian => "hu",
            .italian => "it",
            .japanese => "ja",
            .korean => "ko",
            .lithuanian => "lt",
            .norwegian => "no",
            .polish => "pl",
            .portuguese_brazil => "pt-BR",
            .romanian => "ro",
            .russian => "ru",
            .spanish_spain => "es-ES",
            .spanish_latam => "es-419",
            .swedish => "sv-SE",
            .thai => "th",
            .turkish => "tr",
            .ukrainian => "uk",
            .vietnamese => "vi",
        };
    }
};

pub const Localization = struct {
    locale: []const u8,
    value: []const u8,

    /// Builds a localization entry from a typed `Locale`.
    pub fn of(locale: Locale, value: []const u8) Localization {
        return .{ .locale = locale.code(), .value = value };
    }
};

pub const ComponentEmoji = struct {
    id: ?Snowflake = null,
    name: ?[]const u8 = null,
    animated: bool = false,

    pub fn unicode(name: []const u8) ComponentEmoji {
        return .{ .name = name };
    }

    pub fn custom(id: Snowflake, name: ?[]const u8, animated: bool) ComponentEmoji {
        return .{ .id = id, .name = name, .animated = animated };
    }

    pub fn writeJson(self: ComponentEmoji, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        if (self.id) |id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"id\":\"{d}\"", .{id.value});
        }
        if (self.name) |name| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"name\":");
            try Json.writeString(name, writer);
        }
        if (self.animated) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"animated\":true");
        }
        try writer.writeByte('}');
    }
};

pub const SelectOption = struct {
    label: []const u8,
    value: []const u8,
    description: ?[]const u8 = null,
    default: bool = false,
    emoji: ?ComponentEmoji = null,

    pub fn init(label: []const u8, value: []const u8) SelectOption {
        return .{ .label = label, .value = value };
    }

    pub fn withDescription(self: SelectOption, description: []const u8) SelectOption {
        var option = self;
        option.description = description;
        return option;
    }

    pub fn defaultState(self: SelectOption, default: bool) SelectOption {
        var option = self;
        option.default = default;
        return option;
    }

    pub fn withEmoji(self: SelectOption, emoji: ComponentEmoji) SelectOption {
        var option = self;
        option.emoji = emoji;
        return option;
    }

    /// Rejects a select option whose label, value, or description exceeds the
    /// Discord character limit.
    pub fn validate(self: SelectOption) ValidationError!void {
        try checkLen(self.label, max_select_option_label_len, error.SelectOptionLabelTooLong);
        try checkLen(self.value, max_select_option_value_len, error.SelectOptionValueTooLong);
        if (self.description) |description| {
            try checkLen(description, max_select_option_description_len, error.SelectOptionDescriptionTooLong);
        }
    }

    pub fn writeJson(self: SelectOption, writer: anytype) !void {
        try writer.writeAll("{\"label\":");
        try Json.writeString(self.label, writer);
        try writer.writeAll(",\"value\":");
        try Json.writeString(self.value, writer);
        if (self.description) |description| {
            try writer.writeAll(",\"description\":");
            try Json.writeString(description, writer);
        }
        if (self.default) try writer.writeAll(",\"default\":true");
        if (self.emoji) |emoji| {
            try writer.writeAll(",\"emoji\":");
            try emoji.writeJson(writer);
        }
        try writer.writeByte('}');
    }
};

pub const Button = struct {
    custom_id: ?[]const u8 = null,
    label: ?[]const u8 = null,
    style: ButtonStyle = .primary,
    url: ?[]const u8 = null,
    disabled: bool = false,
    emoji: ?ComponentEmoji = null,
    sku_id: ?Snowflake = null,

    pub fn primary(custom_id: []const u8, label: []const u8) Button {
        return .{ .custom_id = custom_id, .label = label, .style = .primary };
    }

    pub fn secondary(custom_id: []const u8, label: []const u8) Button {
        return .{ .custom_id = custom_id, .label = label, .style = .secondary };
    }

    pub fn success(custom_id: []const u8, label: []const u8) Button {
        return .{ .custom_id = custom_id, .label = label, .style = .success };
    }

    pub fn danger(custom_id: []const u8, label: []const u8) Button {
        return .{ .custom_id = custom_id, .label = label, .style = .danger };
    }

    pub fn link(url: []const u8, label: []const u8) Button {
        return .{ .url = url, .label = label, .style = .link };
    }

    pub fn premium(sku_id: Snowflake) Button {
        return .{ .sku_id = sku_id, .style = .premium };
    }

    pub fn withStyle(self: Button, style: ButtonStyle) Button {
        var button = self;
        button.style = style;
        return button;
    }

    pub fn disabledState(self: Button, disabled: bool) Button {
        var button = self;
        button.disabled = disabled;
        return button;
    }

    pub fn withEmoji(self: Button, emoji: ComponentEmoji) Button {
        var button = self;
        button.emoji = emoji;
        return button;
    }

    pub fn withSkuId(self: Button, sku_id: Snowflake) Button {
        var button = self;
        button.sku_id = sku_id;
        return button;
    }

    /// Rejects a button whose fields exceed Discord limits or violate the style
    /// contract: link buttons need a URL, premium buttons need a SKU id, and
    /// interactive buttons need a custom id.
    pub fn validate(self: Button) ValidationError!void {
        if (self.custom_id) |custom_id| try checkLen(custom_id, max_custom_id_len, error.CustomIdTooLong);
        if (self.label) |label| try checkLen(label, max_button_label_len, error.ButtonLabelTooLong);
        switch (self.style) {
            .link => {
                if (self.url == null) return error.ButtonUrlRequired;
                if (self.custom_id != null or self.sku_id != null) return error.ButtonFieldConflict;
            },
            .premium => {
                if (self.sku_id == null) return error.ButtonSkuIdRequired;
                if (self.custom_id != null or self.url != null or self.label != null or self.emoji != null) {
                    return error.ButtonFieldConflict;
                }
            },
            else => {
                if (self.custom_id == null) return error.ButtonCustomIdRequired;
                if (self.url != null or self.sku_id != null) return error.ButtonFieldConflict;
            },
        }
    }

    pub fn writeJson(self: Button, writer: anytype) !void {
        try writer.print("{{\"type\":{d},\"style\":{d}", .{
            @intFromEnum(ComponentType.button),
            @intFromEnum(self.style),
        });
        if (self.custom_id) |custom_id| {
            try writer.writeAll(",\"custom_id\":");
            try Json.writeString(custom_id, writer);
        }
        if (self.label) |label| {
            try writer.writeAll(",\"label\":");
            try Json.writeString(label, writer);
        }
        if (self.url) |url| {
            try writer.writeAll(",\"url\":");
            try Json.writeString(url, writer);
        }
        if (self.emoji) |emoji| {
            try writer.writeAll(",\"emoji\":");
            try emoji.writeJson(writer);
        }
        if (self.sku_id) |sku_id| {
            try writer.print(",\"sku_id\":\"{d}\"", .{sku_id.value});
        }
        if (self.disabled) try writer.writeAll(",\"disabled\":true");
        try writer.writeByte('}');
    }
};

pub const StringSelect = struct {
    custom_id: []const u8,
    options: []const SelectOption,
    placeholder: ?[]const u8 = null,
    min_values: ?u8 = null,
    max_values: ?u8 = null,
    disabled: bool = false,

    pub fn init(custom_id: []const u8, options: []const SelectOption) StringSelect {
        return .{ .custom_id = custom_id, .options = options };
    }

    pub fn withPlaceholder(self: StringSelect, placeholder: []const u8) StringSelect {
        var select = self;
        select.placeholder = placeholder;
        return select;
    }

    pub fn withValueRange(self: StringSelect, min_values: u8, max_values: u8) StringSelect {
        var select = self;
        select.min_values = min_values;
        select.max_values = max_values;
        return select;
    }

    pub fn disabledState(self: StringSelect, disabled: bool) StringSelect {
        var select = self;
        select.disabled = disabled;
        return select;
    }

    /// Rejects a string select that breaks a Discord limit: custom id or
    /// placeholder length, option count, an out-of-range value selection, or an
    /// option whose own strings are too long.
    pub fn validate(self: StringSelect) ValidationError!void {
        try checkLen(self.custom_id, max_custom_id_len, error.CustomIdTooLong);
        if (self.placeholder) |placeholder| {
            try checkLen(placeholder, max_select_placeholder_len, error.SelectPlaceholderTooLong);
        }
        if (self.options.len > max_select_options) return error.TooManySelectOptions;
        for (self.options) |option| try option.validate();
        try checkSelectRange(self.min_values, self.max_values);
    }

    pub fn writeJson(self: StringSelect, writer: anytype) !void {
        try writer.print("{{\"type\":{d},\"custom_id\":", .{@intFromEnum(ComponentType.string_select)});
        try Json.writeString(self.custom_id, writer);
        try writer.writeAll(",\"options\":");
        try writeSelectOptionArray(self.options, writer);
        if (self.placeholder) |placeholder| {
            try writer.writeAll(",\"placeholder\":");
            try Json.writeString(placeholder, writer);
        }
        if (self.min_values) |value| try writer.print(",\"min_values\":{d}", .{value});
        if (self.max_values) |value| try writer.print(",\"max_values\":{d}", .{value});
        if (self.disabled) try writer.writeAll(",\"disabled\":true");
        try writer.writeByte('}');
    }
};

pub const AutoSelect = struct {
    type: ComponentType,
    custom_id: []const u8,
    placeholder: ?[]const u8 = null,
    min_values: ?u8 = null,
    max_values: ?u8 = null,
    disabled: bool = false,
    channel_types: []const u8 = &.{},

    pub fn user(custom_id: []const u8) AutoSelect {
        return .{ .type = .user_select, .custom_id = custom_id };
    }

    pub fn role(custom_id: []const u8) AutoSelect {
        return .{ .type = .role_select, .custom_id = custom_id };
    }

    pub fn mentionable(custom_id: []const u8) AutoSelect {
        return .{ .type = .mentionable_select, .custom_id = custom_id };
    }

    pub fn channel(custom_id: []const u8, channel_types: []const u8) AutoSelect {
        return .{ .type = .channel_select, .custom_id = custom_id, .channel_types = channel_types };
    }

    pub fn withPlaceholder(self: AutoSelect, placeholder: []const u8) AutoSelect {
        var select = self;
        select.placeholder = placeholder;
        return select;
    }

    pub fn withValueRange(self: AutoSelect, min_values: u8, max_values: u8) AutoSelect {
        var select = self;
        select.min_values = min_values;
        select.max_values = max_values;
        return select;
    }

    pub fn disabledState(self: AutoSelect, disabled: bool) AutoSelect {
        var select = self;
        select.disabled = disabled;
        return select;
    }

    /// Rejects an auto-populated select that breaks a Discord limit on custom id
    /// length, placeholder length, or value-selection range.
    pub fn validate(self: AutoSelect) ValidationError!void {
        try checkLen(self.custom_id, max_custom_id_len, error.CustomIdTooLong);
        if (self.placeholder) |placeholder| {
            try checkLen(placeholder, max_select_placeholder_len, error.SelectPlaceholderTooLong);
        }
        try checkSelectRange(self.min_values, self.max_values);
    }

    pub fn writeJson(self: AutoSelect, writer: anytype) !void {
        try writer.print("{{\"type\":{d},\"custom_id\":", .{@intFromEnum(self.type)});
        try Json.writeString(self.custom_id, writer);
        if (self.placeholder) |placeholder| {
            try writer.writeAll(",\"placeholder\":");
            try Json.writeString(placeholder, writer);
        }
        if (self.min_values) |value| try writer.print(",\"min_values\":{d}", .{value});
        if (self.max_values) |value| try writer.print(",\"max_values\":{d}", .{value});
        if (self.disabled) try writer.writeAll(",\"disabled\":true");
        if (self.type == .channel_select and self.channel_types.len != 0) {
            try writer.writeAll(",\"channel_types\":[");
            for (self.channel_types, 0..) |channel_type, index| {
                if (index != 0) try writer.writeByte(',');
                try writer.print("{d}", .{channel_type});
            }
            try writer.writeByte(']');
        }
        try writer.writeByte('}');
    }
};

test "Discord.js component enum aliases map to protocol values" {
    try std.testing.expectEqual(ComponentType.action_row, ComponentType.ActionRow);
    try std.testing.expectEqual(ComponentType.button, ComponentType.Button);
    try std.testing.expectEqual(ComponentType.string_select, ComponentType.StringSelect);
    try std.testing.expectEqual(ComponentType.text_input, ComponentType.TextInput);
    try std.testing.expectEqual(ComponentType.container, ComponentType.Container);
    try std.testing.expectEqual(@as(u8, 17), @intFromEnum(ComponentType.Container));
    try std.testing.expectEqualStrings("ActionRow", ComponentType.ActionRow.discordJsName());
    try std.testing.expectEqualStrings("TextDisplay", ComponentType.TextDisplay.discordJsName());
    try std.testing.expectEqual(ComponentType.text_display, ComponentType.fromDiscordJsName("TextDisplay").?);
    try std.testing.expectEqual(ComponentType.media_gallery, ComponentType.fromDiscordJsName("MediaGallery").?);
    try std.testing.expectEqual(@as(?ComponentType, null), ComponentType.fromDiscordJsName("Unknown"));

    try std.testing.expectEqual(ButtonStyle.primary, ButtonStyle.Primary);
    try std.testing.expectEqual(ButtonStyle.success, ButtonStyle.Success);
    try std.testing.expectEqual(ButtonStyle.premium, ButtonStyle.Premium);
    try std.testing.expectEqual(@as(u8, 6), @intFromEnum(ButtonStyle.Premium));
    try std.testing.expectEqualStrings("Success", ButtonStyle.Success.discordJsName());
    try std.testing.expectEqual(ButtonStyle.danger, ButtonStyle.fromDiscordJsName("Danger").?);
    try std.testing.expectEqual(@as(?ButtonStyle, null), ButtonStyle.fromDiscordJsName("Warning"));

    try std.testing.expectEqual(TextInputStyle.short, TextInputStyle.Short);
    try std.testing.expectEqual(TextInputStyle.paragraph, TextInputStyle.Paragraph);
    try std.testing.expectEqualStrings("Paragraph", TextInputStyle.Paragraph.discordJsName());
    try std.testing.expectEqual(TextInputStyle.short, TextInputStyle.fromDiscordJsName("Short").?);
    try std.testing.expectEqual(@as(?TextInputStyle, null), TextInputStyle.fromDiscordJsName("Long"));
}
