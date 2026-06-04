const std = @import("std");
const Snowflake = @import("snowflake.zig").Snowflake;
const Json = @import("json.zig");

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
};

pub const ButtonStyle = enum(u8) {
    primary = 1,
    secondary = 2,
    success = 3,
    danger = 4,
    link = 5,
    premium = 6,
};

pub const TextInputStyle = enum(u8) {
    short = 1,
    paragraph = 2,
};

pub const ApplicationCommandType = enum(u8) {
    chat_input = 1,
    user = 2,
    message = 3,
};

/// Discord-documented builder limits. The `validate` helpers below reject
/// payloads that exceed these counts/lengths before they are handed to the REST
/// API, turning a guaranteed 400 from Discord into a local, allocation-free
/// error. Lengths are measured in Unicode code points, matching how Discord
/// counts characters.
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

fn writeComma(writer: anytype, needs_comma: *bool) !void {
    if (needs_comma.*) {
        try writer.writeByte(',');
    } else {
        needs_comma.* = true;
    }
}

fn checkLen(value: []const u8, max_len: usize, too_long: ValidationError) ValidationError!void {
    const len = Json.codepointLen(value) catch return error.InvalidUtf8;
    if (len > max_len) return too_long;
}

fn checkNameLen(value: []const u8, invalid: ValidationError) ValidationError!void {
    const len = Json.codepointLen(value) catch return error.InvalidUtf8;
    if (len < 1 or len > max_command_name_len) return invalid;
}

fn checkDescriptionLen(value: []const u8, invalid: ValidationError) ValidationError!void {
    const len = Json.codepointLen(value) catch return error.InvalidUtf8;
    if (len < 1 or len > max_command_description_len) return invalid;
}

fn checkSelectRange(min_values: ?u8, max_values: ?u8) ValidationError!void {
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

/// Discord locales valid for command/option localization keys, matching
/// Discord.js `Locale`. `code()` returns the wire string Discord expects.
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

    fn writeJson(self: Button, writer: anytype) !void {
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

    fn writeJson(self: StringSelect, writer: anytype) !void {
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

    fn writeJson(self: AutoSelect, writer: anytype) !void {
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

pub const TextInput = struct {
    custom_id: []const u8,
    label: []const u8,
    style: TextInputStyle = .short,
    placeholder: ?[]const u8 = null,
    value: ?[]const u8 = null,
    required: bool = true,
    min_length: ?u16 = null,
    max_length: ?u16 = null,

    pub fn short(custom_id: []const u8, label: []const u8) TextInput {
        return .{ .custom_id = custom_id, .label = label, .style = .short };
    }

    pub fn paragraph(custom_id: []const u8, label: []const u8) TextInput {
        return .{ .custom_id = custom_id, .label = label, .style = .paragraph };
    }

    pub fn optional(self: TextInput) TextInput {
        var input = self;
        input.required = false;
        return input;
    }

    pub fn withPlaceholder(self: TextInput, placeholder: []const u8) TextInput {
        var input = self;
        input.placeholder = placeholder;
        return input;
    }

    pub fn withValue(self: TextInput, value: []const u8) TextInput {
        var input = self;
        input.value = value;
        return input;
    }

    pub fn withLengthRange(self: TextInput, min_length: u16, max_length: u16) TextInput {
        var input = self;
        input.min_length = min_length;
        input.max_length = max_length;
        return input;
    }

    /// Rejects a text input that breaks a Discord length limit on its custom id,
    /// label, placeholder, or prefilled value.
    pub fn validate(self: TextInput) ValidationError!void {
        try checkLen(self.custom_id, max_custom_id_len, error.CustomIdTooLong);
        try checkLen(self.label, max_text_input_label_len, error.TextInputLabelTooLong);
        if (self.placeholder) |placeholder| {
            try checkLen(placeholder, max_text_input_placeholder_len, error.TextInputPlaceholderTooLong);
        }
        if (self.value) |value| {
            try checkLen(value, max_text_input_value_len, error.TextInputValueTooLong);
        }
    }

    fn writeJson(self: TextInput, writer: anytype) !void {
        try writer.print("{{\"type\":{d},\"custom_id\":", .{@intFromEnum(ComponentType.text_input)});
        try Json.writeString(self.custom_id, writer);
        try writer.writeAll(",\"label\":");
        try Json.writeString(self.label, writer);
        try writer.print(",\"style\":{d}", .{@intFromEnum(self.style)});
        if (self.placeholder) |placeholder| {
            try writer.writeAll(",\"placeholder\":");
            try Json.writeString(placeholder, writer);
        }
        if (self.value) |value| {
            try writer.writeAll(",\"value\":");
            try Json.writeString(value, writer);
        }
        if (!self.required) try writer.writeAll(",\"required\":false");
        if (self.min_length) |value| try writer.print(",\"min_length\":{d}", .{value});
        if (self.max_length) |value| try writer.print(",\"max_length\":{d}", .{value});
        try writer.writeByte('}');
    }
};

/// A Components V2 unfurled media item. For `file` components the URL uses the
/// `attachment://<filename>` scheme to reference an uploaded attachment.
pub const UnfurledMedia = struct {
    url: []const u8,

    pub fn init(url: []const u8) UnfurledMedia {
        return .{ .url = url };
    }

    fn writeJson(self: UnfurledMedia, writer: anytype) !void {
        try writer.writeAll("{\"url\":");
        try Json.writeString(self.url, writer);
        try writer.writeByte('}');
    }
};

/// Components V2 markdown text block (type 10).
pub const TextDisplay = struct {
    content: []const u8,
    id: ?u32 = null,

    pub fn init(content: []const u8) TextDisplay {
        return .{ .content = content };
    }

    pub fn withId(self: TextDisplay, id: u32) TextDisplay {
        var text = self;
        text.id = id;
        return text;
    }

    fn writeJson(self: TextDisplay, writer: anytype) !void {
        try writer.print("{{\"type\":{d},\"content\":", .{@intFromEnum(ComponentType.text_display)});
        try Json.writeString(self.content, writer);
        if (self.id) |id| try writer.print(",\"id\":{d}", .{id});
        try writer.writeByte('}');
    }
};

/// Components V2 thumbnail accessory (type 11).
pub const Thumbnail = struct {
    media: UnfurledMedia,
    description: ?[]const u8 = null,
    spoiler: bool = false,
    id: ?u32 = null,

    pub fn init(url: []const u8) Thumbnail {
        return .{ .media = UnfurledMedia.init(url) };
    }

    pub fn withDescription(self: Thumbnail, description: []const u8) Thumbnail {
        var thumbnail = self;
        thumbnail.description = description;
        return thumbnail;
    }

    pub fn spoilerState(self: Thumbnail, spoiler: bool) Thumbnail {
        var thumbnail = self;
        thumbnail.spoiler = spoiler;
        return thumbnail;
    }

    fn writeJson(self: Thumbnail, writer: anytype) !void {
        try writer.print("{{\"type\":{d},\"media\":", .{@intFromEnum(ComponentType.thumbnail)});
        try self.media.writeJson(writer);
        if (self.description) |description| {
            try writer.writeAll(",\"description\":");
            try Json.writeString(description, writer);
        }
        if (self.spoiler) try writer.writeAll(",\"spoiler\":true");
        if (self.id) |id| try writer.print(",\"id\":{d}", .{id});
        try writer.writeByte('}');
    }
};

/// Accessory attached to the right of a Components V2 section (type 9).
pub const SectionAccessory = union(enum) {
    button: Button,
    thumbnail: Thumbnail,

    fn writeJson(self: SectionAccessory, writer: anytype) !void {
        switch (self) {
            .button => |button| try button.writeJson(writer),
            .thumbnail => |thumbnail| try thumbnail.writeJson(writer),
        }
    }
};

/// Components V2 section (type 9): one to three text displays plus an accessory.
pub const Section = struct {
    components: []const TextDisplay,
    accessory: SectionAccessory,
    id: ?u32 = null,

    pub fn init(components: []const TextDisplay, accessory: SectionAccessory) Section {
        return .{ .components = components, .accessory = accessory };
    }

    pub fn withButton(components: []const TextDisplay, button: Button) Section {
        return .{ .components = components, .accessory = .{ .button = button } };
    }

    pub fn withThumbnail(components: []const TextDisplay, thumbnail: Thumbnail) Section {
        return .{ .components = components, .accessory = .{ .thumbnail = thumbnail } };
    }

    pub fn validate(self: Section) ValidationError!void {
        if (self.components.len < 1 or self.components.len > max_section_components) {
            return error.SectionComponentCountInvalid;
        }
    }

    fn writeJson(self: Section, writer: anytype) !void {
        try writer.print("{{\"type\":{d},\"components\":[", .{@intFromEnum(ComponentType.section)});
        for (self.components, 0..) |text, index| {
            if (index != 0) try writer.writeByte(',');
            try text.writeJson(writer);
        }
        try writer.writeAll("],\"accessory\":");
        try self.accessory.writeJson(writer);
        if (self.id) |id| try writer.print(",\"id\":{d}", .{id});
        try writer.writeByte('}');
    }
};

/// A single item inside a Components V2 media gallery (type 12).
pub const MediaGalleryItem = struct {
    media: UnfurledMedia,
    description: ?[]const u8 = null,
    spoiler: bool = false,

    pub fn init(url: []const u8) MediaGalleryItem {
        return .{ .media = UnfurledMedia.init(url) };
    }

    pub fn withDescription(self: MediaGalleryItem, description: []const u8) MediaGalleryItem {
        var item = self;
        item.description = description;
        return item;
    }

    pub fn spoilerState(self: MediaGalleryItem, spoiler: bool) MediaGalleryItem {
        var item = self;
        item.spoiler = spoiler;
        return item;
    }

    fn writeJson(self: MediaGalleryItem, writer: anytype) !void {
        try writer.writeAll("{\"media\":");
        try self.media.writeJson(writer);
        if (self.description) |description| {
            try writer.writeAll(",\"description\":");
            try Json.writeString(description, writer);
        }
        if (self.spoiler) try writer.writeAll(",\"spoiler\":true");
        try writer.writeByte('}');
    }
};

/// Components V2 media gallery (type 12): one to ten media items.
pub const MediaGallery = struct {
    items: []const MediaGalleryItem,
    id: ?u32 = null,

    pub fn init(items: []const MediaGalleryItem) MediaGallery {
        return .{ .items = items };
    }

    pub fn validate(self: MediaGallery) ValidationError!void {
        if (self.items.len < 1 or self.items.len > max_media_gallery_items) {
            return error.MediaGalleryItemCountInvalid;
        }
    }

    fn writeJson(self: MediaGallery, writer: anytype) !void {
        try writer.print("{{\"type\":{d},\"items\":[", .{@intFromEnum(ComponentType.media_gallery)});
        for (self.items, 0..) |item, index| {
            if (index != 0) try writer.writeByte(',');
            try item.writeJson(writer);
        }
        try writer.writeByte(']');
        if (self.id) |id| try writer.print(",\"id\":{d}", .{id});
        try writer.writeByte('}');
    }
};

/// Components V2 file component (type 13). The media URL references an uploaded
/// attachment via the `attachment://<filename>` scheme.
pub const FileComponent = struct {
    file: UnfurledMedia,
    spoiler: bool = false,
    id: ?u32 = null,

    pub fn init(attachment_url: []const u8) FileComponent {
        return .{ .file = UnfurledMedia.init(attachment_url) };
    }

    pub fn spoilerState(self: FileComponent, spoiler: bool) FileComponent {
        var component = self;
        component.spoiler = spoiler;
        return component;
    }

    fn writeJson(self: FileComponent, writer: anytype) !void {
        try writer.print("{{\"type\":{d},\"file\":", .{@intFromEnum(ComponentType.file)});
        try self.file.writeJson(writer);
        if (self.spoiler) try writer.writeAll(",\"spoiler\":true");
        if (self.id) |id| try writer.print(",\"id\":{d}", .{id});
        try writer.writeByte('}');
    }
};

pub const SeparatorSpacing = enum(u8) {
    small = 1,
    large = 2,
};

/// Components V2 separator (type 14). `divider` defaults to true on Discord, so
/// only a non-default value is serialized.
pub const Separator = struct {
    divider: bool = true,
    spacing: ?SeparatorSpacing = null,
    id: ?u32 = null,

    pub fn init() Separator {
        return .{};
    }

    pub fn dividerState(self: Separator, divider: bool) Separator {
        var separator = self;
        separator.divider = divider;
        return separator;
    }

    pub fn withSpacing(self: Separator, spacing: SeparatorSpacing) Separator {
        var separator = self;
        separator.spacing = spacing;
        return separator;
    }

    fn writeJson(self: Separator, writer: anytype) !void {
        try writer.print("{{\"type\":{d}", .{@intFromEnum(ComponentType.separator)});
        if (!self.divider) try writer.writeAll(",\"divider\":false");
        if (self.spacing) |spacing| try writer.print(",\"spacing\":{d}", .{@intFromEnum(spacing)});
        if (self.id) |id| try writer.print(",\"id\":{d}", .{id});
        try writer.writeByte('}');
    }
};

/// Components V2 container (type 17): groups child components with an optional
/// accent color and spoiler state.
pub const Container = struct {
    components: []const Component,
    accent_color: ?u32 = null,
    spoiler: bool = false,
    id: ?u32 = null,

    pub fn init(components: []const Component) Container {
        return .{ .components = components };
    }

    pub fn withAccentColor(self: Container, accent_color: u32) Container {
        var container = self;
        container.accent_color = accent_color;
        return container;
    }

    pub fn spoilerState(self: Container, spoiler: bool) Container {
        var container = self;
        container.spoiler = spoiler;
        return container;
    }

    pub fn validate(self: Container) ValidationError!void {
        for (self.components) |component| try component.validate();
    }

    fn writeJson(self: Container, writer: anytype) !void {
        try writer.print("{{\"type\":{d},\"components\":", .{@intFromEnum(ComponentType.container)});
        try writeComponentArray(self.components, writer);
        if (self.accent_color) |accent_color| try writer.print(",\"accent_color\":{d}", .{accent_color});
        if (self.spoiler) try writer.writeAll(",\"spoiler\":true");
        if (self.id) |id| try writer.print(",\"id\":{d}", .{id});
        try writer.writeByte('}');
    }
};

pub const Component = union(enum) {
    action_row: []const Component,
    button: Button,
    string_select: StringSelect,
    user_select: AutoSelect,
    role_select: AutoSelect,
    mentionable_select: AutoSelect,
    channel_select: AutoSelect,
    text_input: TextInput,
    section: Section,
    text_display: TextDisplay,
    thumbnail: Thumbnail,
    media_gallery: MediaGallery,
    file: FileComponent,
    separator: Separator,
    container: Container,

    pub fn actionRow(components: []const Component) Component {
        return .{ .action_row = components };
    }

    pub fn actionRowWithComponent(component: *const Component) Component {
        return .{ .action_row = component[0..1] };
    }

    /// Validates a single component against its own Discord limits, recursing
    /// into action-row children.
    pub fn validate(self: Component) ValidationError!void {
        switch (self) {
            .action_row => |children| {
                if (children.len > max_row_components) return error.TooManyRowComponents;
                for (children) |child| try child.validate();
            },
            .button => |button| try button.validate(),
            .string_select => |select| try select.validate(),
            .user_select, .role_select, .mentionable_select, .channel_select => |select| try select.validate(),
            .text_input => |input| try input.validate(),
            .section => |value| try value.validate(),
            .media_gallery => |value| try value.validate(),
            .container => |value| try value.validate(),
            .text_display, .thumbnail, .file, .separator => {},
        }
    }

    /// Validates a message/modal component list against Discord limits: at most
    /// five action rows, plus the per-component limits enforced by `validate`.
    /// Non-row top-level entries are still validated so newer top-level component
    /// kinds keep working.
    pub fn validateLayout(components: []const Component) ValidationError!void {
        var action_rows: usize = 0;
        for (components) |component| {
            switch (component) {
                .action_row => action_rows += 1,
                else => {},
            }
            try component.validate();
        }
        if (action_rows > max_action_rows) return error.TooManyActionRows;
    }

    pub fn writeJson(self: Component, writer: anytype) anyerror!void {
        switch (self) {
            .action_row => |components| {
                try writer.print("{{\"type\":{d},\"components\":", .{@intFromEnum(ComponentType.action_row)});
                try writeComponentArray(components, writer);
                try writer.writeByte('}');
            },
            .button => |button| try button.writeJson(writer),
            .string_select => |select| try select.writeJson(writer),
            .user_select, .role_select, .mentionable_select, .channel_select => |select| try select.writeJson(writer),
            .text_input => |input| try input.writeJson(writer),
            .section => |value| try value.writeJson(writer),
            .text_display => |value| try value.writeJson(writer),
            .thumbnail => |value| try value.writeJson(writer),
            .media_gallery => |value| try value.writeJson(writer),
            .file => |value| try value.writeJson(writer),
            .separator => |value| try value.writeJson(writer),
            .container => |value| try value.writeJson(writer),
        }
    }
};

pub const ApplicationCommandOptionType = enum(u8) {
    sub_command = 1,
    sub_command_group = 2,
    string = 3,
    integer = 4,
    boolean = 5,
    user = 6,
    channel = 7,
    role = 8,
    mentionable = 9,
    number = 10,
    attachment = 11,
};

pub const CommandChoiceValue = union(enum) {
    string: []const u8,
    integer: i64,
    number: f64,

    fn writeJson(self: CommandChoiceValue, writer: anytype) !void {
        switch (self) {
            .string => |value| try Json.writeString(value, writer),
            .integer => |value| try writer.print("{d}", .{value}),
            .number => |value| try writer.print("{d}", .{value}),
        }
    }
};

pub const CommandChoice = struct {
    name: []const u8,
    value: CommandChoiceValue,

    pub fn string(name: []const u8, value: []const u8) CommandChoice {
        return .{ .name = name, .value = .{ .string = value } };
    }

    pub fn integer(name: []const u8, value: i64) CommandChoice {
        return .{ .name = name, .value = .{ .integer = value } };
    }

    pub fn number(name: []const u8, value: f64) CommandChoice {
        return .{ .name = name, .value = .{ .number = value } };
    }

    /// Rejects a choice whose name or string value exceeds the Discord limit.
    pub fn validate(self: CommandChoice) ValidationError!void {
        try checkLen(self.name, max_choice_name_len, error.ChoiceNameTooLong);
        switch (self.value) {
            .string => |value| try checkLen(value, max_choice_string_value_len, error.ChoiceValueTooLong),
            else => {},
        }
    }

    fn writeJson(self: CommandChoice, writer: anytype) !void {
        try writer.writeAll("{\"name\":");
        try Json.writeString(self.name, writer);
        try writer.writeAll(",\"value\":");
        try self.value.writeJson(writer);
        try writer.writeByte('}');
    }
};

pub const ApplicationCommandOption = struct {
    type: ApplicationCommandOptionType,
    name: []const u8,
    description: []const u8,
    required: bool = false,
    autocomplete: bool = false,
    choices: []const CommandChoice = &.{},
    options: []const ApplicationCommandOption = &.{},
    name_localizations: []const Localization = &.{},
    description_localizations: []const Localization = &.{},

    pub fn string(name: []const u8, description: []const u8, required: bool) ApplicationCommandOption {
        return .{ .type = .string, .name = name, .description = description, .required = required };
    }

    pub fn integer(name: []const u8, description: []const u8, required: bool) ApplicationCommandOption {
        return .{ .type = .integer, .name = name, .description = description, .required = required };
    }

    pub fn number(name: []const u8, description: []const u8, required: bool) ApplicationCommandOption {
        return .{ .type = .number, .name = name, .description = description, .required = required };
    }

    pub fn boolean(name: []const u8, description: []const u8, required: bool) ApplicationCommandOption {
        return .{ .type = .boolean, .name = name, .description = description, .required = required };
    }

    pub fn user(name: []const u8, description: []const u8, required: bool) ApplicationCommandOption {
        return .{ .type = .user, .name = name, .description = description, .required = required };
    }

    pub fn channel(name: []const u8, description: []const u8, required: bool) ApplicationCommandOption {
        return .{ .type = .channel, .name = name, .description = description, .required = required };
    }

    pub fn role(name: []const u8, description: []const u8, required: bool) ApplicationCommandOption {
        return .{ .type = .role, .name = name, .description = description, .required = required };
    }

    pub fn mentionable(name: []const u8, description: []const u8, required: bool) ApplicationCommandOption {
        return .{ .type = .mentionable, .name = name, .description = description, .required = required };
    }

    pub fn attachment(name: []const u8, description: []const u8, required: bool) ApplicationCommandOption {
        return .{ .type = .attachment, .name = name, .description = description, .required = required };
    }

    pub fn subCommand(name: []const u8, description: []const u8, options: []const ApplicationCommandOption) ApplicationCommandOption {
        return .{ .type = .sub_command, .name = name, .description = description, .options = options };
    }

    pub fn subCommandGroup(name: []const u8, description: []const u8, options: []const ApplicationCommandOption) ApplicationCommandOption {
        return .{ .type = .sub_command_group, .name = name, .description = description, .options = options };
    }

    pub fn withChoices(self: ApplicationCommandOption, choices: []const CommandChoice) ApplicationCommandOption {
        var option = self;
        option.choices = choices;
        return option;
    }

    pub fn withChoice(self: ApplicationCommandOption, choice: *const CommandChoice) ApplicationCommandOption {
        var option = self;
        option.choices = choice[0..1];
        return option;
    }

    pub fn withAutocomplete(self: ApplicationCommandOption) ApplicationCommandOption {
        var option = self;
        option.autocomplete = true;
        return option;
    }

    pub fn requiredState(self: ApplicationCommandOption, required: bool) ApplicationCommandOption {
        var option = self;
        option.required = required;
        return option;
    }

    pub fn requiredOption(self: ApplicationCommandOption) ApplicationCommandOption {
        return self.requiredState(true);
    }

    pub fn optionalOption(self: ApplicationCommandOption) ApplicationCommandOption {
        return self.requiredState(false);
    }

    pub fn withOption(self: ApplicationCommandOption, child: *const ApplicationCommandOption) ApplicationCommandOption {
        var option = self;
        option.options = child[0..1];
        return option;
    }

    pub fn withNameLocalizations(self: ApplicationCommandOption, localizations: []const Localization) ApplicationCommandOption {
        var option = self;
        option.name_localizations = localizations;
        return option;
    }

    pub fn withDescriptionLocalizations(self: ApplicationCommandOption, localizations: []const Localization) ApplicationCommandOption {
        var option = self;
        option.description_localizations = localizations;
        return option;
    }

    /// Recursively rejects an option that breaks a Discord limit: name or
    /// description length, choice count, an over-long choice, or nested-option
    /// count. Sub-command and sub-command-group children are walked so a whole
    /// option tree can be checked from its root.
    pub fn validate(self: ApplicationCommandOption) ValidationError!void {
        try checkNameLen(self.name, error.OptionNameInvalid);
        try checkDescriptionLen(self.description, error.OptionDescriptionInvalid);
        if (self.choices.len > max_command_choices) return error.TooManyCommandChoices;
        for (self.choices) |choice| try choice.validate();
        if (self.options.len > max_command_options) return error.TooManyCommandOptions;
        for (self.options) |child| try child.validate();
    }

    fn writeJson(self: ApplicationCommandOption, writer: anytype) anyerror!void {
        try writer.print("{{\"type\":{d},\"name\":", .{@intFromEnum(self.type)});
        try Json.writeString(self.name, writer);
        try writer.writeAll(",\"description\":");
        try Json.writeString(self.description, writer);
        if (self.name_localizations.len != 0) {
            try writer.writeAll(",\"name_localizations\":");
            try writeLocalizationObject(self.name_localizations, writer);
        }
        if (self.description_localizations.len != 0) {
            try writer.writeAll(",\"description_localizations\":");
            try writeLocalizationObject(self.description_localizations, writer);
        }
        if (self.required) try writer.writeAll(",\"required\":true");
        if (self.autocomplete) try writer.writeAll(",\"autocomplete\":true");
        if (self.choices.len != 0) {
            try writer.writeAll(",\"choices\":");
            try writeChoiceArray(self.choices, writer);
        }
        if (self.options.len != 0) {
            try writer.writeAll(",\"options\":");
            try writeOptionArray(self.options, writer);
        }
        try writer.writeByte('}');
    }
};

pub const Interaction = struct {
    id: Snowflake,
    application_id: Snowflake,
    type: InteractionType,
    token: []const u8,
    guild_id: ?Snowflake = null,
    channel_id: ?Snowflake = null,
    user_id: ?Snowflake = null,
};

pub const CommandOptionValue = union(ApplicationCommandOptionType) {
    sub_command: []const CommandDataOption,
    sub_command_group: []const CommandDataOption,
    string: []const u8,
    integer: i64,
    boolean: bool,
    user: Snowflake,
    channel: Snowflake,
    role: Snowflake,
    mentionable: Snowflake,
    number: f64,
    attachment: Snowflake,
};

pub const CommandDataOption = struct {
    name: []const u8,
    value: CommandOptionValue,
    focused: bool = false,

    pub fn getString(self: CommandDataOption) ![]const u8 {
        return switch (self.value) {
            .string => |value| value,
            else => error.OptionTypeMismatch,
        };
    }

    pub fn getInteger(self: CommandDataOption) !i64 {
        return switch (self.value) {
            .integer => |value| value,
            else => error.OptionTypeMismatch,
        };
    }

    pub fn getBoolean(self: CommandDataOption) !bool {
        return switch (self.value) {
            .boolean => |value| value,
            else => error.OptionTypeMismatch,
        };
    }

    pub fn getNumber(self: CommandDataOption) !f64 {
        return switch (self.value) {
            .number => |value| value,
            else => error.OptionTypeMismatch,
        };
    }

    pub fn getSnowflake(self: CommandDataOption) !Snowflake {
        return switch (self.value) {
            .user, .channel, .role, .mentionable, .attachment => |value| value,
            else => error.OptionTypeMismatch,
        };
    }

    pub fn getOptions(self: CommandDataOption) ![]const CommandDataOption {
        return switch (self.value) {
            .sub_command, .sub_command_group => |value| value,
            else => error.OptionTypeMismatch,
        };
    }
};

/// Resolved entities attached to a command interaction's `data.resolved`. Each
/// map is keyed by snowflake-id string; lookups return the raw JSON object for
/// that id, valid for the lifetime of the owning `ParsedInteraction`.
pub const Resolved = struct {
    users: ?std.json.ObjectMap = null,
    members: ?std.json.ObjectMap = null,
    roles: ?std.json.ObjectMap = null,
    channels: ?std.json.ObjectMap = null,
    messages: ?std.json.ObjectMap = null,
    attachments: ?std.json.ObjectMap = null,

    fn lookup(map: ?std.json.ObjectMap, id: Snowflake) ?std.json.Value {
        const entries = map orelse return null;
        var buffer = [_]u8{0} ** 20;
        const key = std.fmt.bufPrint(&buffer, "{d}", .{id.value}) catch return null;
        return entries.get(key);
    }

    pub fn user(self: Resolved, id: Snowflake) ?std.json.Value {
        return lookup(self.users, id);
    }

    pub fn member(self: Resolved, id: Snowflake) ?std.json.Value {
        return lookup(self.members, id);
    }

    pub fn role(self: Resolved, id: Snowflake) ?std.json.Value {
        return lookup(self.roles, id);
    }

    pub fn channel(self: Resolved, id: Snowflake) ?std.json.Value {
        return lookup(self.channels, id);
    }

    pub fn message(self: Resolved, id: Snowflake) ?std.json.Value {
        return lookup(self.messages, id);
    }

    pub fn attachment(self: Resolved, id: Snowflake) ?std.json.Value {
        return lookup(self.attachments, id);
    }

    /// Typed view of a resolved user, parsed on demand from the raw JSON.
    pub fn resolvedUser(self: Resolved, id: Snowflake) !?ResolvedUser {
        const value = lookup(self.users, id) orelse return null;
        return try parseResolvedUser(value);
    }

    /// Typed view of a resolved role, parsed on demand from the raw JSON.
    pub fn resolvedRole(self: Resolved, id: Snowflake) !?ResolvedRole {
        const value = lookup(self.roles, id) orelse return null;
        return try parseResolvedRole(value);
    }

    /// Typed view of a resolved channel, parsed on demand from the raw JSON.
    pub fn resolvedChannel(self: Resolved, id: Snowflake) !?ResolvedChannel {
        const value = lookup(self.channels, id) orelse return null;
        return try parseResolvedChannel(value);
    }

    /// Typed view of a resolved partial guild member, parsed on demand from the
    /// raw JSON. The member carries no nested user; pair it with `resolvedUser`.
    pub fn resolvedMember(self: Resolved, id: Snowflake) !?ResolvedMember {
        const value = lookup(self.members, id) orelse return null;
        return try parseResolvedMember(value);
    }

    /// Typed view of a resolved attachment, parsed on demand from the raw JSON.
    pub fn resolvedAttachment(self: Resolved, id: Snowflake) !?ResolvedAttachment {
        const value = lookup(self.attachments, id) orelse return null;
        return try parseResolvedAttachment(value);
    }

    /// Typed view of a resolved partial message (e.g. the target of a MESSAGE
    /// context-menu command), parsed on demand from the raw JSON.
    pub fn resolvedMessage(self: Resolved, id: Snowflake) !?ResolvedMessage {
        const value = lookup(self.messages, id) orelse return null;
        return try parseResolvedMessage(value);
    }
};

/// Typed view of a resolved user attached to a command interaction. String
/// fields reference the owning `ParsedInteraction`'s JSON storage.
pub const ResolvedUser = struct {
    id: Snowflake,
    username: []const u8,
    discriminator: ?[]const u8 = null,
    global_name: ?[]const u8 = null,
    avatar: ?[]const u8 = null,
    bot: bool = false,
    public_flags: ?u32 = null,

    pub fn displayName(self: ResolvedUser) []const u8 {
        return self.global_name orelse self.username;
    }
};

/// Typed view of a resolved role attached to a command interaction.
pub const ResolvedRole = struct {
    id: Snowflake,
    name: []const u8,
    color: u24 = 0,
    hoist: bool = false,
    position: i32 = 0,
    permissions: u64 = 0,
    managed: bool = false,
    mentionable: bool = false,
    icon: ?[]const u8 = null,
    unicode_emoji: ?[]const u8 = null,
};

fn parseResolvedUser(value: std.json.Value) !ResolvedUser {
    const object = try objectValue(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .username = try stringField(object, "username"),
        .discriminator = if (object.get("discriminator")) |field| try optionalStringValue(field) else null,
        .global_name = if (object.get("global_name")) |field| try optionalStringValue(field) else null,
        .avatar = if (object.get("avatar")) |field| try optionalStringValue(field) else null,
        .bot = if (object.get("bot")) |field| try boolValue(field) else false,
        .public_flags = if (object.get("public_flags")) |field| @as(u32, @intCast(try integerValue(field))) else null,
    };
}

fn parseResolvedRole(value: std.json.Value) !ResolvedRole {
    const object = try objectValue(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .name = try stringField(object, "name"),
        .color = if (object.get("color")) |field| @as(u24, @intCast(try integerValue(field))) else 0,
        .hoist = if (object.get("hoist")) |field| try boolValue(field) else false,
        .position = if (object.get("position")) |field| @as(i32, @intCast(try integerValue(field))) else 0,
        .permissions = if (object.get("permissions")) |field| try permissionsBitValue(field) else 0,
        .managed = if (object.get("managed")) |field| try boolValue(field) else false,
        .mentionable = if (object.get("mentionable")) |field| try boolValue(field) else false,
        .icon = if (object.get("icon")) |field| try optionalStringValue(field) else null,
        .unicode_emoji = if (object.get("unicode_emoji")) |field| try optionalStringValue(field) else null,
    };
}

fn optionalStringValue(value: std.json.Value) !?[]const u8 {
    return switch (value) {
        .string => |string| string,
        .null => null,
        else => error.InvalidField,
    };
}

fn permissionsBitValue(value: std.json.Value) !u64 {
    return switch (value) {
        .string => |string| std.fmt.parseInt(u64, string, 10) catch error.InvalidField,
        .integer => |integer| @intCast(integer),
        else => error.InvalidField,
    };
}

/// Typed view of a resolved channel attached to a command interaction.
pub const ResolvedChannel = struct {
    id: Snowflake,
    name: ?[]const u8 = null,
    type: u8 = 0,
    permissions: ?u64 = null,
    parent_id: ?Snowflake = null,
};

/// Typed view of a resolved partial guild member (no nested user object).
pub const ResolvedMember = struct {
    nick: ?[]const u8 = null,
    avatar: ?[]const u8 = null,
    joined_at: ?[]const u8 = null,
    premium_since: ?[]const u8 = null,
    pending: bool = false,
    permissions: ?u64 = null,
    communication_disabled_until: ?[]const u8 = null,
    roles: ?std.json.Array = null,

    pub fn roleCount(self: ResolvedMember) usize {
        return if (self.roles) |roles| roles.items.len else 0;
    }

    /// Role id at `index` in the member's role list, or null when out of range.
    pub fn roleAt(self: ResolvedMember, index: usize) !?Snowflake {
        const roles = self.roles orelse return null;
        if (index >= roles.items.len) return null;
        return try snowflakeValue(roles.items[index]);
    }
};

fn parseResolvedChannel(value: std.json.Value) !ResolvedChannel {
    const object = try objectValue(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .name = if (object.get("name")) |field| try optionalStringValue(field) else null,
        .type = if (object.get("type")) |field| @as(u8, @intCast(try integerValue(field))) else 0,
        .permissions = if (object.get("permissions")) |field| try permissionsBitValue(field) else null,
        .parent_id = if (object.get("parent_id")) |field| try optionalSnowflakeValue(field) else null,
    };
}

fn parseResolvedMember(value: std.json.Value) !ResolvedMember {
    const object = try objectValue(value);
    return .{
        .nick = if (object.get("nick")) |field| try optionalStringValue(field) else null,
        .avatar = if (object.get("avatar")) |field| try optionalStringValue(field) else null,
        .joined_at = if (object.get("joined_at")) |field| try optionalStringValue(field) else null,
        .premium_since = if (object.get("premium_since")) |field| try optionalStringValue(field) else null,
        .pending = if (object.get("pending")) |field| try boolValue(field) else false,
        .permissions = if (object.get("permissions")) |field| try permissionsBitValue(field) else null,
        .communication_disabled_until = if (object.get("communication_disabled_until")) |field| try optionalStringValue(field) else null,
        .roles = if (object.get("roles")) |field| try arrayValue(field) else null,
    };
}

fn optionalSnowflakeValue(value: std.json.Value) !?Snowflake {
    return switch (value) {
        .string => |string| try Snowflake.parse(string),
        .null => null,
        else => error.InvalidField,
    };
}

/// Typed view of a resolved attachment attached to a command interaction.
pub const ResolvedAttachment = struct {
    id: Snowflake,
    filename: []const u8,
    size: u64 = 0,
    url: []const u8,
    proxy_url: ?[]const u8 = null,
    content_type: ?[]const u8 = null,
    height: ?u32 = null,
    width: ?u32 = null,
    ephemeral: bool = false,
    description: ?[]const u8 = null,
};

/// Typed view of a resolved partial message attached to a command interaction.
pub const ResolvedMessage = struct {
    id: Snowflake,
    channel_id: ?Snowflake = null,
    author_id: ?Snowflake = null,
    content: ?[]const u8 = null,
    timestamp: ?[]const u8 = null,
    edited_timestamp: ?[]const u8 = null,
    tts: bool = false,
    pinned: bool = false,
    type: u8 = 0,
    attachment_count: usize = 0,
    embed_count: usize = 0,
};

fn parseResolvedAttachment(value: std.json.Value) !ResolvedAttachment {
    const object = try objectValue(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .filename = try stringField(object, "filename"),
        .size = if (object.get("size")) |field| @as(u64, @intCast(try integerValue(field))) else 0,
        .url = try stringField(object, "url"),
        .proxy_url = if (object.get("proxy_url")) |field| try optionalStringValue(field) else null,
        .content_type = if (object.get("content_type")) |field| try optionalStringValue(field) else null,
        .height = if (object.get("height")) |field| try optionalU32Field(field) else null,
        .width = if (object.get("width")) |field| try optionalU32Field(field) else null,
        .ephemeral = if (object.get("ephemeral")) |field| try boolValue(field) else false,
        .description = if (object.get("description")) |field| try optionalStringValue(field) else null,
    };
}

fn parseResolvedMessage(value: std.json.Value) !ResolvedMessage {
    const object = try objectValue(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .channel_id = if (object.get("channel_id")) |field| try optionalSnowflakeValue(field) else null,
        .author_id = if (object.get("author")) |field| try snowflakeField(try objectValue(field), "id") else null,
        .content = if (object.get("content")) |field| try optionalStringValue(field) else null,
        .timestamp = if (object.get("timestamp")) |field| try optionalStringValue(field) else null,
        .edited_timestamp = if (object.get("edited_timestamp")) |field| try optionalStringValue(field) else null,
        .tts = if (object.get("tts")) |field| try boolValue(field) else false,
        .pinned = if (object.get("pinned")) |field| try boolValue(field) else false,
        .type = if (object.get("type")) |field| @as(u8, @intCast(try integerValue(field))) else 0,
        .attachment_count = if (object.get("attachments")) |field| (try arrayValue(field)).items.len else 0,
        .embed_count = if (object.get("embeds")) |field| (try arrayValue(field)).items.len else 0,
    };
}

fn optionalU32Field(value: std.json.Value) !?u32 {
    return switch (value) {
        .integer => |integer| @intCast(integer),
        .null => null,
        else => error.InvalidField,
    };
}

pub const CommandData = struct {
    id: Snowflake,
    name: []const u8,
    type: ApplicationCommandType,
    options: []const CommandDataOption = &.{},
    target_id: ?Snowflake = null,
    resolved: Resolved = .{},

    pub fn option(self: CommandData, name: []const u8) ?CommandDataOption {
        for (self.options) |candidate| {
            if (std.mem.eql(u8, candidate.name, name)) return candidate;
        }
        return null;
    }

    pub fn getString(self: CommandData, name: []const u8) ![]const u8 {
        return try (self.option(name) orelse return error.OptionNotFound).getString();
    }

    pub fn getInteger(self: CommandData, name: []const u8) !i64 {
        return try (self.option(name) orelse return error.OptionNotFound).getInteger();
    }

    pub fn getBoolean(self: CommandData, name: []const u8) !bool {
        return try (self.option(name) orelse return error.OptionNotFound).getBoolean();
    }

    pub fn getNumber(self: CommandData, name: []const u8) !f64 {
        return try (self.option(name) orelse return error.OptionNotFound).getNumber();
    }

    pub fn getSnowflake(self: CommandData, name: []const u8) !Snowflake {
        return try (self.option(name) orelse return error.OptionNotFound).getSnowflake();
    }

    /// The focused option of an autocomplete interaction, searching nested
    /// sub-command options, or null if none is focused.
    pub fn focusedOption(self: CommandData) ?CommandDataOption {
        return findFocused(self.options);
    }

    fn findFocused(options: []const CommandDataOption) ?CommandDataOption {
        for (options) |candidate| {
            if (candidate.focused) return candidate;
            switch (candidate.value) {
                .sub_command, .sub_command_group => |children| {
                    if (findFocused(children)) |found| return found;
                },
                else => {},
            }
        }
        return null;
    }

    /// Resolved user object targeted by a USER context-menu command.
    pub fn targetUser(self: CommandData) ?std.json.Value {
        const id = self.target_id orelse return null;
        return self.resolved.user(id);
    }

    /// Resolved message object targeted by a MESSAGE context-menu command.
    pub fn targetMessage(self: CommandData) ?std.json.Value {
        const id = self.target_id orelse return null;
        return self.resolved.message(id);
    }
};

pub const ComponentData = struct {
    custom_id: []const u8,
    type: ?ComponentType = null,
    values: []const []const u8 = &.{},
    value: ?[]const u8 = null,
    components: []const ComponentData = &.{},

    pub fn find(self: ComponentData, custom_id: []const u8) ?ComponentData {
        if (std.mem.eql(u8, self.custom_id, custom_id)) return self;
        for (self.components) |component| {
            if (component.find(custom_id)) |found| return found;
        }
        return null;
    }

    pub fn firstValue(self: ComponentData) ?[]const u8 {
        if (self.value) |value| return value;
        if (self.values.len != 0) return self.values[0];
        return null;
    }
};

pub const ParsedInteraction = struct {
    parsed: std.json.Parsed(std.json.Value),
    interaction: Interaction,
    data: ?CommandData,
    component_data: ?ComponentData,
    arena: std.heap.ArenaAllocator,

    pub fn deinit(self: *ParsedInteraction) void {
        self.parsed.deinit();
        self.arena.deinit();
    }
};

pub const ParsedHandler = struct {
    ptr: *anyopaque,
    callFn: *const fn (ptr: *anyopaque, interaction: *const ParsedInteraction) anyerror!void,

    pub fn call(self: ParsedHandler, interaction: *const ParsedInteraction) !void {
        try self.callFn(self.ptr, interaction);
    }
};

pub const CommandRoute = struct {
    name: []const u8,
    handler: ParsedHandler,
    /// Optional precondition run before the handler. Returning `false` skips the
    /// handler (the guard is expected to answer the interaction itself).
    guard: ?Middleware = null,
};

pub const MatchKind = enum { exact, prefix };

pub const ComponentRoute = struct {
    custom_id: []const u8,
    handler: ParsedHandler,
    /// `.exact` matches the full custom id; `.prefix` matches when the
    /// interaction custom id starts with `custom_id` (e.g. "vote:" routes both
    /// "vote:yes" and "vote:no" to one handler).
    match: MatchKind = .exact,
    /// Optional precondition run before the handler. Returning `false` skips the
    /// handler (the guard is expected to answer the interaction itself).
    guard: ?Middleware = null,
};

/// Middleware runs before route dispatch. Returning `false` halts the pipeline:
/// no route handler (and no fallback) runs and `dispatch` returns `false`.
/// Returning `true` continues to the next middleware and then to routing.
pub const Middleware = struct {
    ptr: *anyopaque,
    callFn: *const fn (ptr: *anyopaque, interaction: *const ParsedInteraction) anyerror!bool,

    pub fn call(self: Middleware, interaction: *const ParsedInteraction) !bool {
        return self.callFn(self.ptr, interaction);
    }
};

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

    fn dispatchCommand(interaction: *const ParsedInteraction, routes: []const CommandRoute) !bool {
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

    fn dispatchComponent(interaction: *const ParsedInteraction, routes: []const ComponentRoute) !bool {
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
        fn call(raw: *anyopaque, interaction: *const ParsedInteraction) anyerror!void {
            const typed: Ptr = @ptrCast(@alignCast(raw));
            try function(typed, interaction);
        }
    };

    return .{ .ptr = ptr, .callFn = wrapper.call };
}

pub fn middlewareHandler(ptr: anytype, comptime function: anytype) Middleware {
    const Ptr = @TypeOf(ptr);
    const wrapper = struct {
        fn call(raw: *anyopaque, interaction: *const ParsedInteraction) anyerror!bool {
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

fn interactionUserId(root: std.json.ObjectMap) !?Snowflake {
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

/// How an application must be installed for a command to be available
/// (user-installable apps support).
pub const IntegrationType = enum(u8) {
    guild_install = 0,
    user_install = 1,
};

/// Context in which a command/interaction is allowed to be used.
pub const InteractionContextType = enum(u8) {
    guild = 0,
    bot_dm = 1,
    private_channel = 2,
};

fn writeEnumIntArray(comptime T: type, values: []const T, writer: anytype) !void {
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

fn commandDataFromJson(allocator: std.mem.Allocator, value: std.json.Value) !CommandData {
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

fn commandDataOptionsFromJson(allocator: std.mem.Allocator, value: std.json.Value) anyerror![]const CommandDataOption {
    const array = try arrayValue(value);
    const options = try allocator.alloc(CommandDataOption, array.items.len);
    errdefer allocator.free(options);

    for (array.items, 0..) |item, index| {
        options[index] = try commandDataOptionFromJson(allocator, item);
    }

    return options;
}

fn commandDataOptionFromJson(allocator: std.mem.Allocator, value: std.json.Value) anyerror!CommandDataOption {
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

fn componentDataFromJson(allocator: std.mem.Allocator, value: std.json.Value) anyerror!ComponentData {
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

fn componentDataArrayFromJson(allocator: std.mem.Allocator, value: std.json.Value) anyerror![]const ComponentData {
    const array = try arrayValue(value);
    const components = try allocator.alloc(ComponentData, array.items.len);
    errdefer allocator.free(components);

    for (array.items, 0..) |item, index| {
        components[index] = try componentDataFromJson(allocator, item);
    }

    return components;
}

fn stringArrayValue(allocator: std.mem.Allocator, value: std.json.Value) ![]const []const u8 {
    const array = try arrayValue(value);
    const values = try allocator.alloc([]const u8, array.items.len);
    errdefer allocator.free(values);

    for (array.items, 0..) |item, index| {
        values[index] = try stringValue(item);
    }

    return values;
}

fn resolvedFromJson(value: std.json.Value) !Resolved {
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

fn resolvedSubObject(object: std.json.ObjectMap, key: []const u8) ?std.json.ObjectMap {
    if (object.get(key)) |field| {
        return switch (field) {
            .object => |inner| inner,
            else => null,
        };
    }
    return null;
}

fn objectValue(value: std.json.Value) !std.json.ObjectMap {
    return switch (value) {
        .object => |object| object,
        else => error.InvalidField,
    };
}

fn arrayValue(value: std.json.Value) !std.json.Array {
    return switch (value) {
        .array => |array| array,
        else => error.InvalidField,
    };
}

fn snowflakeField(object: std.json.ObjectMap, field: []const u8) !Snowflake {
    return snowflakeValue(object.get(field) orelse return error.MissingField);
}

fn snowflakeValue(value: std.json.Value) !Snowflake {
    return Snowflake.parse(try stringValue(value));
}

fn stringField(object: std.json.ObjectMap, field: []const u8) ![]const u8 {
    return stringValue(object.get(field) orelse return error.MissingField);
}

fn stringValue(value: std.json.Value) ![]const u8 {
    return switch (value) {
        .string => |string| string,
        else => error.InvalidField,
    };
}

fn integerValue(value: std.json.Value) !i64 {
    return switch (value) {
        .integer => |integer| @intCast(integer),
        else => error.InvalidField,
    };
}

fn numberValue(value: std.json.Value) !f64 {
    return switch (value) {
        .float => |float| float,
        .integer => |integer| @floatFromInt(integer),
        else => error.InvalidField,
    };
}

fn boolValue(value: std.json.Value) !bool {
    return switch (value) {
        .bool => |boolean| boolean,
        else => error.InvalidField,
    };
}

fn interactionTypeValue(value: std.json.Value) !InteractionType {
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

fn applicationCommandTypeValue(value: std.json.Value) !ApplicationCommandType {
    const raw: u8 = @intCast(try integerValue(value));
    return switch (raw) {
        1 => .chat_input,
        2 => .user,
        3 => .message,
        else => error.InvalidField,
    };
}

fn applicationCommandOptionTypeValue(value: std.json.Value) !ApplicationCommandOptionType {
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

fn componentTypeValue(value: std.json.Value) !ComponentType {
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
pub const EmbedBuilder = @import("types.zig").Embed;

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

test "interaction router dispatches commands autocomplete components and modals" {
    const State = struct {
        command: bool = false,
        autocomplete: bool = false,
        component: bool = false,
        modal: bool = false,

        fn onCommand(self: *@This(), interaction: *const ParsedInteraction) !void {
            try std.testing.expectEqual(InteractionType.application_command, interaction.interaction.type);
            try std.testing.expectEqualStrings("echo", interaction.data.?.name);
            try std.testing.expectEqualStrings("hello", try interaction.data.?.getString("text"));
            self.command = true;
        }

        fn onAutocomplete(self: *@This(), interaction: *const ParsedInteraction) !void {
            try std.testing.expectEqual(InteractionType.application_command_autocomplete, interaction.interaction.type);
            try std.testing.expectEqualStrings("echo", interaction.data.?.name);
            self.autocomplete = true;
        }

        fn onComponent(self: *@This(), interaction: *const ParsedInteraction) !void {
            try std.testing.expectEqual(InteractionType.message_component, interaction.interaction.type);
            try std.testing.expectEqualStrings("confirm", interaction.component_data.?.custom_id);
            self.component = true;
        }

        fn onModal(self: *@This(), interaction: *const ParsedInteraction) !void {
            try std.testing.expectEqual(InteractionType.modal_submit, interaction.interaction.type);
            try std.testing.expectEqualStrings("profile_modal", interaction.component_data.?.custom_id);
            self.modal = true;
        }
    };

    var state = State{};
    const commands = [_]CommandRoute{
        .{ .name = "echo", .handler = parsedHandler(&state, State.onCommand) },
    };
    const autocomplete = [_]CommandRoute{
        .{ .name = "echo", .handler = parsedHandler(&state, State.onAutocomplete) },
    };
    const components = [_]ComponentRoute{
        .{ .custom_id = "confirm", .handler = parsedHandler(&state, State.onComponent) },
    };
    const modals = [_]ComponentRoute{
        .{ .custom_id = "profile_modal", .handler = parsedHandler(&state, State.onModal) },
    };
    const router = InteractionRouter{
        .commands = &commands,
        .autocomplete = &autocomplete,
        .components = &components,
        .modals = &modals,
    };

    var command = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"echo\",\"type\":1,\"options\":[{\"name\":\"text\",\"type\":3,\"value\":\"hello\"}]}}",
    );
    defer command.deinit();
    try std.testing.expect(try router.dispatch(&command));

    var autocomplete_interaction = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":4,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"echo\",\"type\":1}}",
    );
    defer autocomplete_interaction.deinit();
    try std.testing.expect(try router.dispatch(&autocomplete_interaction));

    var component = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"data\":{\"custom_id\":\"confirm\",\"component_type\":2}}",
    );
    defer component.deinit();
    try std.testing.expect(try router.dispatch(&component));

    var modal = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":5,\"token\":\"tok\",\"data\":{\"custom_id\":\"profile_modal\",\"components\":[]}}",
    );
    defer modal.deinit();
    try std.testing.expect(try router.dispatch(&modal));

    var unknown = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"missing\",\"type\":1}}",
    );
    defer unknown.deinit();
    try std.testing.expect(!try router.dispatch(&unknown));

    try std.testing.expect(state.command);
    try std.testing.expect(state.autocomplete);
    try std.testing.expect(state.component);
    try std.testing.expect(state.modal);
}

test "interaction router builder registers routes incrementally" {
    const State = struct {
        command: usize = 0,
        component: usize = 0,
        modal: usize = 0,
        fallback: usize = 0,

        fn onCommand(self: *@This(), interaction: *const ParsedInteraction) !void {
            try std.testing.expectEqualStrings("ping", interaction.data.?.name);
            self.command += 1;
        }

        fn onComponent(self: *@This(), interaction: *const ParsedInteraction) !void {
            try std.testing.expect(std.mem.startsWith(u8, interaction.component_data.?.custom_id, "menu:"));
            self.component += 1;
        }

        fn onModal(self: *@This(), interaction: *const ParsedInteraction) !void {
            try std.testing.expectEqualStrings("profile", interaction.component_data.?.custom_id);
            self.modal += 1;
        }

        fn onFallback(self: *@This(), _: *const ParsedInteraction) !void {
            self.fallback += 1;
        }
    };

    var state = State{};
    var builder = InteractionRouterBuilder.init(std.testing.allocator);
    defer builder.deinit();

    try builder.command("ping", parsedHandler(&state, State.onCommand));
    try builder.componentPrefix("menu:", parsedHandler(&state, State.onComponent));
    try builder.modal("profile", parsedHandler(&state, State.onModal));
    builder.fallbackTo(parsedHandler(&state, State.onFallback));
    const router = builder.router();

    var command = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"ping\",\"type\":1}}",
    );
    defer command.deinit();
    try std.testing.expect(try router.dispatch(&command));

    var component = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"data\":{\"custom_id\":\"menu:next\",\"component_type\":2}}",
    );
    defer component.deinit();
    try std.testing.expect(try router.dispatch(&component));

    var modal = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":5,\"token\":\"tok\",\"data\":{\"custom_id\":\"profile\",\"components\":[]}}",
    );
    defer modal.deinit();
    try std.testing.expect(try router.dispatch(&modal));

    var unknown = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"unknown\",\"type\":1}}",
    );
    defer unknown.deinit();
    try std.testing.expect(try router.dispatch(&unknown));

    try std.testing.expectEqual(@as(usize, 1), state.command);
    try std.testing.expectEqual(@as(usize, 1), state.component);
    try std.testing.expectEqual(@as(usize, 1), state.modal);
    try std.testing.expectEqual(@as(usize, 1), state.fallback);
}

test "application command registry pairs definitions with router routes" {
    const State = struct {
        calls: usize = 0,

        fn onPing(self: *@This(), interaction: *const ParsedInteraction) !void {
            try std.testing.expectEqualStrings("ping", interaction.data.?.name);
            self.calls += 1;
        }
    };

    var state = State{};
    var registry = ApplicationCommandRegistry.init(std.testing.allocator);
    defer registry.deinit();

    try registry.addCommandRoute(
        ApplicationCommand.chatInput("ping", "Replies with pong"),
        parsedHandler(&state, State.onPing),
    );
    try std.testing.expectEqual(@as(usize, 1), registry.definitions().len);

    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();
    try registry.writeDefinitionsJson(&out.writer);
    try std.testing.expectEqualStrings(
        "[{\"name\":\"ping\",\"description\":\"Replies with pong\",\"type\":1}]",
        out.written(),
    );

    var command = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"ping\",\"type\":1}}",
    );
    defer command.deinit();
    try std.testing.expect(try registry.router().dispatch(&command));
    try std.testing.expectEqual(@as(usize, 1), state.calls);
}

test "application command module registers command autocomplete and components" {
    const State = struct {
        command: usize = 0,
        autocomplete: usize = 0,
        component: usize = 0,

        fn onCommand(self: *@This(), _: *const ParsedInteraction) !void {
            self.command += 1;
        }

        fn onAutocomplete(self: *@This(), _: *const ParsedInteraction) !void {
            self.autocomplete += 1;
        }

        fn onComponent(self: *@This(), _: *const ParsedInteraction) !void {
            self.component += 1;
        }
    };

    var state = State{};
    const component_routes = [_]ComponentRoute{
        .{ .custom_id = "module:", .match = .prefix, .handler = parsedHandler(&state, State.onComponent) },
    };
    const module = ApplicationCommandModule
        .init(ApplicationCommand.chatInput("module", "Module command"), parsedHandler(&state, State.onCommand))
        .withAutocomplete(parsedHandler(&state, State.onAutocomplete))
        .withComponents(&component_routes);

    var registry = ApplicationCommandRegistry.init(std.testing.allocator);
    defer registry.deinit();
    try module.register(&registry);

    var command = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"module\",\"type\":1}}",
    );
    defer command.deinit();
    try std.testing.expect(try registry.router().dispatch(&command));

    var autocomplete = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":4,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"module\",\"type\":1}}",
    );
    defer autocomplete.deinit();
    try std.testing.expect(try registry.router().dispatch(&autocomplete));

    var component = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"data\":{\"custom_id\":\"module:next\",\"component_type\":2}}",
    );
    defer component.deinit();
    try std.testing.expect(try registry.router().dispatch(&component));

    try std.testing.expectEqual(@as(usize, 1), state.command);
    try std.testing.expectEqual(@as(usize, 1), state.autocomplete);
    try std.testing.expectEqual(@as(usize, 1), state.component);
}

test "application command manifest registers multiple modules" {
    const State = struct {
        calls: usize = 0,

        fn onAny(self: *@This(), _: *const ParsedInteraction) !void {
            self.calls += 1;
        }
    };

    var state = State{};
    const modules = [_]ApplicationCommandModule{
        ApplicationCommandModule.init(ApplicationCommand.chatInput("one", "First command"), parsedHandler(&state, State.onAny)),
        ApplicationCommandModule.init(ApplicationCommand.chatInput("two", "Second command"), parsedHandler(&state, State.onAny)),
    };
    const manifest = ApplicationCommandManifest.init(&modules);

    var registry = ApplicationCommandRegistry.init(std.testing.allocator);
    defer registry.deinit();
    try manifest.register(&registry);
    try std.testing.expectEqual(@as(usize, 2), registry.definitions().len);

    var one = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"one\",\"type\":1}}",
    );
    defer one.deinit();
    try std.testing.expect(try registry.router().dispatch(&one));

    var two = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"two\",\"type\":1}}",
    );
    defer two.deinit();
    try std.testing.expect(try registry.router().dispatch(&two));
    try std.testing.expectEqual(@as(usize, 2), state.calls);
}

test "application command annotations build definitions and modules" {
    const State = struct {
        calls: usize = 0,

        fn onRun(self: *@This(), interaction: *const ParsedInteraction) !void {
            try std.testing.expectEqualStrings("annotated", interaction.data.?.name);
            self.calls += 1;
        }
    };

    var state = State{};
    const options = [_]ApplicationCommandOption{
        ApplicationCommandOption.string("target", "Target name", true),
    };
    const annotation = ApplicationCommandAnnotation
        .slash("annotated", "Annotated command", parsedHandler(&state, State.onRun))
        .withOptions(&options)
        .withDMPermission(false);

    const definition = annotation.command();
    try std.testing.expectEqualStrings("annotated", definition.name);
    try std.testing.expectEqual(@as(usize, 1), definition.options.len);
    try std.testing.expectEqual(@as(?bool, false), definition.dm_permission);

    var registry = ApplicationCommandRegistry.init(std.testing.allocator);
    defer registry.deinit();
    try annotation.register(&registry);

    var interaction = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"annotated\",\"type\":1}}",
    );
    defer interaction.deinit();
    try std.testing.expect(try registry.router().dispatch(&interaction));
    try std.testing.expectEqual(@as(usize, 1), state.calls);
}

test "string select validate rejects option overflow at the limit boundary" {
    const at_limit = [_]SelectOption{SelectOption.init("l", "v")} ** max_select_options;
    try StringSelect.init("menu", &at_limit).validate();

    const over_limit = [_]SelectOption{SelectOption.init("l", "v")} ** (max_select_options + 1);
    try std.testing.expectError(error.TooManySelectOptions, StringSelect.init("menu", &over_limit).validate());
}

test "component layout validate enforces row and per-row component limits" {
    const button = Component{ .button = Button.primary("id", "Label") };

    const full_row_children = [_]Component{button} ** max_row_components;
    const full_row = Component.actionRow(&full_row_children);
    const max_rows = [_]Component{full_row} ** max_action_rows;
    try Component.validateLayout(&max_rows);

    const overfull_children = [_]Component{button} ** (max_row_components + 1);
    const overfull_row = [_]Component{Component.actionRow(&overfull_children)};
    try std.testing.expectError(error.TooManyRowComponents, Component.validateLayout(&overfull_row));

    const single_child = [_]Component{button};
    const slim_row = Component.actionRow(&single_child);
    const too_many_rows = [_]Component{slim_row} ** (max_action_rows + 1);
    try std.testing.expectError(error.TooManyActionRows, Component.validateLayout(&too_many_rows));
}

test "component layout validate walks nested string select option limits" {
    const over_limit = [_]SelectOption{SelectOption.init("l", "v")} ** (max_select_options + 1);
    const select = Component{ .string_select = StringSelect.init("menu", &over_limit) };
    const nested = [_]Component{select};
    const row = [_]Component{Component.actionRow(&nested)};
    try std.testing.expectError(error.TooManySelectOptions, Component.validateLayout(&row));
}

test "command validate rejects choice and option overflow recursively" {
    const at_choice_limit = [_]CommandChoice{CommandChoice.string("n", "v")} ** max_command_choices;
    try ApplicationCommandOption.string("opt", "desc", false).withChoices(&at_choice_limit).validate();

    const over_choices = [_]CommandChoice{CommandChoice.string("n", "v")} ** (max_command_choices + 1);
    try std.testing.expectError(
        error.TooManyCommandChoices,
        ApplicationCommandOption.string("opt", "desc", false).withChoices(&over_choices).validate(),
    );

    const over_options = [_]ApplicationCommandOption{ApplicationCommandOption.string("o", "d", false)} ** (max_command_options + 1);
    try std.testing.expectError(
        error.TooManyCommandOptions,
        ApplicationCommand.chatInput("cmd", "desc").withOptions(&over_options).validate(),
    );

    // A bad choice list nested inside a sub-command must be caught from the command root.
    const bad_child = ApplicationCommandOption.string("inner", "d", false).withChoices(&over_choices);
    const group = ApplicationCommandOption.subCommand("sub", "d", &.{}).withOption(&bad_child);
    try std.testing.expectError(
        error.TooManyCommandChoices,
        ApplicationCommand.chatInput("cmd", "desc").withOption(&group).validate(),
    );
}

test "component validate enforces string length limits" {
    const long_id = "c" ** (max_custom_id_len + 1);
    try std.testing.expectError(error.CustomIdTooLong, (Button{ .custom_id = long_id, .label = "ok" }).validate());

    const long_label = "L" ** (max_button_label_len + 1);
    try std.testing.expectError(error.ButtonLabelTooLong, Button.primary("id", long_label).validate());

    const long_text_label = "L" ** (max_text_input_label_len + 1);
    try std.testing.expectError(error.TextInputLabelTooLong, TextInput.short("id", long_text_label).validate());

    const long_desc = "d" ** (max_select_option_description_len + 1);
    try std.testing.expectError(
        error.SelectOptionDescriptionTooLong,
        SelectOption.init("label", "value").withDescription(long_desc).validate(),
    );

    const long_placeholder = "p" ** (max_select_placeholder_len + 1);
    const opts = [_]SelectOption{SelectOption.init("a", "1")};
    try std.testing.expectError(
        error.SelectPlaceholderTooLong,
        StringSelect.init("menu", &opts).withPlaceholder(long_placeholder).validate(),
    );

    // min_values greater than max_values is rejected.
    try std.testing.expectError(
        error.SelectValueRangeInvalid,
        StringSelect.init("menu", &opts).withValueRange(3, 2).validate(),
    );
    try std.testing.expectError(
        error.SelectValueRangeInvalid,
        AutoSelect.user("picker").withValueRange(1, 30).validate(),
    );
}

test "command validate enforces name description and choice length rules" {
    const long_name = "n" ** (max_command_name_len + 1);
    try std.testing.expectError(error.CommandNameInvalid, ApplicationCommand.chatInput(long_name, "desc").validate());

    // Chat-input commands require a non-empty description.
    try std.testing.expectError(error.CommandDescriptionInvalid, ApplicationCommand.chatInput("ok", "").validate());

    // User and message commands must carry an empty description.
    try ApplicationCommand.user("Inspect").validate();
    try std.testing.expectError(
        error.CommandDescriptionInvalid,
        (ApplicationCommand{ .name = "Inspect", .description = "nope", .type = .user }).validate(),
    );

    const long_choice = "v" ** (max_choice_string_value_len + 1);
    const choices = [_]CommandChoice{CommandChoice.string("name", long_choice)};
    const option = ApplicationCommandOption.string("opt", "desc", false).withChoices(&choices);
    try std.testing.expectError(error.ChoiceValueTooLong, option.validate());

    // A well-formed command tree validates cleanly.
    const good_choices = [_]CommandChoice{CommandChoice.string("Public", "public")};
    const good_option = ApplicationCommandOption.string("visibility", "Who sees it", true).withChoices(&good_choices);
    try ApplicationCommand.chatInput("echo", "Echoes text").withOption(&good_option).validate();
}

test "components v2 builders stream expected JSON" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const section_text = [_]TextDisplay{TextDisplay.init("Body")};
    const gallery_items = [_]MediaGalleryItem{MediaGalleryItem.init("https://cdn/a.png")};
    const children = [_]Component{
        .{ .text_display = TextDisplay.init("# Title") },
        .{ .section = Section.withThumbnail(&section_text, Thumbnail.init("https://cdn/x.png").withDescription("art")) },
        .{ .media_gallery = MediaGallery.init(&gallery_items) },
        .{ .separator = Separator.init().withSpacing(.large) },
        .{ .file = FileComponent.init("attachment://a.txt") },
    };
    const component = Component{ .container = Container.init(&children).withAccentColor(0x5865F2) };
    try component.writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"type\":17,\"components\":[" ++
            "{\"type\":10,\"content\":\"# Title\"}," ++
            "{\"type\":9,\"components\":[{\"type\":10,\"content\":\"Body\"}],\"accessory\":{\"type\":11,\"media\":{\"url\":\"https://cdn/x.png\"},\"description\":\"art\"}}," ++
            "{\"type\":12,\"items\":[{\"media\":{\"url\":\"https://cdn/a.png\"}}]}," ++
            "{\"type\":14,\"spacing\":2}," ++
            "{\"type\":13,\"file\":{\"url\":\"attachment://a.txt\"}}" ++
            "],\"accent_color\":5793266}",
        out.written(),
    );
}

test "components v2 validate enforces section and gallery limits" {
    const four_texts = [_]TextDisplay{TextDisplay.init("t")} ** 4;
    const bad_section = Component{ .section = Section.withButton(&four_texts, Button.primary("a", "b")) };
    try std.testing.expectError(error.SectionComponentCountInvalid, bad_section.validate());

    const no_items = [_]MediaGalleryItem{};
    const empty_gallery = Component{ .media_gallery = MediaGallery.init(&no_items) };
    try std.testing.expectError(error.MediaGalleryItemCountInvalid, empty_gallery.validate());

    // A container surfaces a nested child's violation.
    const eleven = [_]MediaGalleryItem{MediaGalleryItem.init("u")} ** 11;
    const inner = [_]Component{.{ .media_gallery = MediaGallery.init(&eleven) }};
    const container = Component{ .container = Container.init(&inner) };
    try std.testing.expectError(error.MediaGalleryItemCountInvalid, container.validate());

    const one_text = [_]TextDisplay{TextDisplay.init("ok")};
    const good = Component{ .section = Section.withThumbnail(&one_text, Thumbnail.init("https://cdn/x.png")) };
    try good.validate();
}

test "interaction router supports middleware prefix routes and fallback" {
    const State = struct {
        seen: usize = 0,
        prefix_hits: usize = 0,
        fallback_hits: usize = 0,
        allow: bool = true,

        fn guard(self: *@This(), interaction: *const ParsedInteraction) !bool {
            _ = interaction;
            self.seen += 1;
            return self.allow;
        }

        fn onVote(self: *@This(), interaction: *const ParsedInteraction) !void {
            _ = interaction;
            self.prefix_hits += 1;
        }

        fn onFallback(self: *@This(), interaction: *const ParsedInteraction) !void {
            _ = interaction;
            self.fallback_hits += 1;
        }
    };

    var state = State{};
    const middleware = [_]Middleware{middlewareHandler(&state, State.guard)};
    const components = [_]ComponentRoute{
        .{ .custom_id = "vote:", .handler = parsedHandler(&state, State.onVote), .match = .prefix },
    };
    const router = InteractionRouter{
        .components = &components,
        .middleware = &middleware,
        .fallback = parsedHandler(&state, State.onFallback),
    };

    // Prefix route: custom_id "vote:yes" matches the "vote:" prefix route.
    var vote = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"data\":{\"custom_id\":\"vote:yes\",\"component_type\":2}}",
    );
    defer vote.deinit();
    try std.testing.expect(try router.dispatch(&vote));
    try std.testing.expectEqual(@as(usize, 1), state.prefix_hits);
    try std.testing.expectEqual(@as(usize, 1), state.seen);

    // Unmatched component falls through to the fallback handler.
    var other = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"data\":{\"custom_id\":\"nope\",\"component_type\":2}}",
    );
    defer other.deinit();
    try std.testing.expect(try router.dispatch(&other));
    try std.testing.expectEqual(@as(usize, 1), state.fallback_hits);

    // Middleware halt: no route or fallback runs, and dispatch returns false.
    state.allow = false;
    var halted = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"data\":{\"custom_id\":\"vote:no\",\"component_type\":2}}",
    );
    defer halted.deinit();
    try std.testing.expect(!try router.dispatch(&halted));
    try std.testing.expectEqual(@as(usize, 1), state.prefix_hits);
    try std.testing.expectEqual(@as(usize, 1), state.fallback_hits);
}

test "parse autocomplete focused option and resolved context-menu target" {
    var autocomplete = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":4,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"search\",\"type\":1,\"options\":[{\"name\":\"scope\",\"type\":3,\"value\":\"a\"},{\"name\":\"query\",\"type\":3,\"value\":\"par\",\"focused\":true}]}}",
    );
    defer autocomplete.deinit();
    const focused = autocomplete.data.?.focusedOption().?;
    try std.testing.expectEqualStrings("query", focused.name);
    try std.testing.expectEqualStrings("par", try focused.getString());

    // USER context-menu command: target_id resolves into resolved.users.
    var context = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"Profile\",\"type\":2,\"target_id\":\"42\",\"resolved\":{\"users\":{\"42\":{\"id\":\"42\",\"username\":\"ada\"}}}}}",
    );
    defer context.deinit();
    const data = context.data.?;
    try std.testing.expectEqual(Snowflake.init(42), data.target_id.?);
    try std.testing.expect(data.focusedOption() == null);

    const target = data.targetUser().?;
    try std.testing.expectEqualStrings("ada", target.object.get("username").?.string);
    try std.testing.expect(data.resolved.user(Snowflake.init(99)) == null);
    try std.testing.expect(data.targetMessage() == null);
}

test "application command writes integration types and contexts" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try ApplicationCommand.chatInput("deploy", "Deploy")
        .withIntegrationTypes(&.{ .guild_install, .user_install })
        .withContexts(&.{ .guild, .bot_dm, .private_channel })
        .writeJson(&out.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"deploy\",\"description\":\"Deploy\",\"type\":1,\"integration_types\":[0,1],\"contexts\":[0,1,2]}",
        out.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();
    try EditApplicationCommand.init()
        .withIntegrationTypes(&.{.user_install})
        .writeJson(&edit.writer);
    try std.testing.expectEqualStrings("{\"integration_types\":[1]}", edit.written());
}

test "resolved typed user and role views" {
    var context = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"Promote\",\"type\":2,\"target_id\":\"42\",\"resolved\":{\"users\":{\"42\":{\"id\":\"42\",\"username\":\"ada\",\"global_name\":\"Ada L\",\"bot\":true,\"public_flags\":64}},\"roles\":{\"7\":{\"id\":\"7\",\"name\":\"Admins\",\"color\":255,\"hoist\":true,\"position\":3,\"permissions\":\"8\",\"managed\":false,\"mentionable\":true}}}}}",
    );
    defer context.deinit();
    const resolved = context.data.?.resolved;

    const user = (try resolved.resolvedUser(Snowflake.init(42))).?;
    try std.testing.expectEqualStrings("ada", user.username);
    try std.testing.expectEqualStrings("Ada L", user.displayName());
    try std.testing.expect(user.bot);
    try std.testing.expectEqual(@as(?u32, 64), user.public_flags);
    try std.testing.expect((try resolved.resolvedUser(Snowflake.init(99))) == null);

    const role = (try resolved.resolvedRole(Snowflake.init(7))).?;
    try std.testing.expectEqualStrings("Admins", role.name);
    try std.testing.expectEqual(@as(u24, 255), role.color);
    try std.testing.expect(role.hoist);
    try std.testing.expectEqual(@as(u64, 8), role.permissions);
    try std.testing.expect(role.mentionable);
}

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

        fn guard(self: *@This(), interaction: *const ParsedInteraction) !bool {
            _ = interaction;
            self.guard_calls += 1;
            return self.allow;
        }

        fn onPing(self: *@This(), interaction: *const ParsedInteraction) !void {
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
