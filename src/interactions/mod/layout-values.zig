const Json = @import("../../core/json.zig");

const Root = @import("../mod.zig");
const ComponentType = Root.ComponentType;
const TextInputStyle = Root.TextInputStyle;
const max_action_rows = Root.max_action_rows;
const max_row_components = Root.max_row_components;
const max_custom_id_len = Root.max_custom_id_len;
const max_text_input_label_len = Root.max_text_input_label_len;
const max_text_input_placeholder_len = Root.max_text_input_placeholder_len;
const max_text_input_value_len = Root.max_text_input_value_len;
const max_choice_name_len = Root.max_choice_name_len;
const max_choice_string_value_len = Root.max_choice_string_value_len;
const max_section_components = Root.max_section_components;
const max_media_gallery_items = Root.max_media_gallery_items;
const ValidationError = Root.ValidationError;
const checkLen = Root.checkLen;
const Button = Root.Button;
const StringSelect = Root.StringSelect;
const AutoSelect = Root.AutoSelect;
const writeComponentArray = Root.writeComponentArray;

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

    pub fn writeJson(self: TextInput, writer: anytype) !void {
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

pub const UnfurledMedia = struct {
    url: []const u8,

    pub fn init(url: []const u8) UnfurledMedia {
        return .{ .url = url };
    }

    pub fn writeJson(self: UnfurledMedia, writer: anytype) !void {
        try writer.writeAll("{\"url\":");
        try Json.writeString(self.url, writer);
        try writer.writeByte('}');
    }
};

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

    pub fn writeJson(self: TextDisplay, writer: anytype) !void {
        try writer.print("{{\"type\":{d},\"content\":", .{@intFromEnum(ComponentType.text_display)});
        try Json.writeString(self.content, writer);
        if (self.id) |id| try writer.print(",\"id\":{d}", .{id});
        try writer.writeByte('}');
    }
};

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

    pub fn writeJson(self: Thumbnail, writer: anytype) !void {
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

pub const SectionAccessory = union(enum) {
    button: Button,
    thumbnail: Thumbnail,

    pub fn writeJson(self: SectionAccessory, writer: anytype) !void {
        switch (self) {
            .button => |button| try button.writeJson(writer),
            .thumbnail => |thumbnail| try thumbnail.writeJson(writer),
        }
    }
};

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

    pub fn writeJson(self: Section, writer: anytype) !void {
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

    pub fn writeJson(self: MediaGalleryItem, writer: anytype) !void {
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

    pub fn writeJson(self: MediaGallery, writer: anytype) !void {
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

    pub fn writeJson(self: FileComponent, writer: anytype) !void {
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

    pub fn writeJson(self: Separator, writer: anytype) !void {
        try writer.print("{{\"type\":{d}", .{@intFromEnum(ComponentType.separator)});
        if (!self.divider) try writer.writeAll(",\"divider\":false");
        if (self.spacing) |spacing| try writer.print(",\"spacing\":{d}", .{@intFromEnum(spacing)});
        if (self.id) |id| try writer.print(",\"id\":{d}", .{id});
        try writer.writeByte('}');
    }
};

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

    pub fn writeJson(self: Container, writer: anytype) !void {
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

    pub fn writeJson(self: CommandChoiceValue, writer: anytype) !void {
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

    pub fn writeJson(self: CommandChoice, writer: anytype) !void {
        try writer.writeAll("{\"name\":");
        try Json.writeString(self.name, writer);
        try writer.writeAll(",\"value\":");
        try self.value.writeJson(writer);
        try writer.writeByte('}');
    }
};
