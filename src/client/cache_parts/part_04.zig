const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Types = @import("../../models/types.zig");
const Gateway = @import("../../gateway/protocol.zig");
const Interactions = @import("../../interactions/mod.zig");
const Permissions = @import("../../core/permissions.zig");
const Collection = @import("../../core/collection.zig").Collection;

const test_part_01 = @import("../cache_tests/part_01.zig");
const test_part_02 = @import("../cache_tests/part_02.zig");
const test_part_03 = @import("../cache_tests/part_03.zig");
const test_part_04 = @import("../cache_tests/part_04.zig");
const test_part_05 = @import("../cache_tests/part_05.zig");
const test_part_06 = @import("../cache_tests/part_06.zig");
const test_part_07 = @import("../cache_tests/part_07.zig");

const Root = @import("../cache.zig");
const default = Root.default;
const deinitComponent = Root.deinitComponent;
const deinitSelectOptions = Root.deinitSelectOptions;
const deinitMediaGalleryItem = Root.deinitMediaGalleryItem;
const copyUsers = Root.copyUsers;
const copyUser = Root.copyUser;
const deinitUsers = Root.deinitUsers;
const deinitUser = Root.deinitUser;
const copyEmbeds = Root.copyEmbeds;
const deinitEmbeds = Root.deinitEmbeds;

pub fn copyAttachments(allocator: std.mem.Allocator, attachments: []const Types.Attachment) ![]Types.Attachment {
    const owned = try allocator.alloc(Types.Attachment, attachments.len);
    var initialized: usize = 0;
    errdefer deinitAttachments(owned[0..initialized], allocator);

    for (attachments, 0..) |attachment, index| {
        owned[index] = try copyAttachment(allocator, attachment);
        initialized += 1;
    }
    return owned;
}

pub fn copyAttachment(allocator: std.mem.Allocator, attachment: Types.Attachment) !Types.Attachment {
    const filename = try allocator.dupe(u8, attachment.filename);
    errdefer allocator.free(filename);
    const description = if (attachment.description) |value| try allocator.dupe(u8, value) else null;
    errdefer if (description) |value| allocator.free(value);
    const content_type = if (attachment.content_type) |value| try allocator.dupe(u8, value) else null;
    errdefer if (content_type) |value| allocator.free(value);
    const url = try allocator.dupe(u8, attachment.url);
    errdefer allocator.free(url);
    const proxy_url = try allocator.dupe(u8, attachment.proxy_url);

    return .{
        .id = attachment.id,
        .filename = filename,
        .description = description,
        .content_type = content_type,
        .size = attachment.size,
        .url = url,
        .proxy_url = proxy_url,
        .height = attachment.height,
        .width = attachment.width,
        .ephemeral = attachment.ephemeral,
    };
}

pub fn deinitAttachments(attachments: []Types.Attachment, allocator: std.mem.Allocator) void {
    for (attachments) |attachment| {
        allocator.free(attachment.filename);
        if (attachment.description) |value| allocator.free(value);
        if (attachment.content_type) |value| allocator.free(value);
        allocator.free(attachment.url);
        allocator.free(attachment.proxy_url);
    }
    allocator.free(attachments);
}

pub fn copyMessageSnapshots(
    allocator: std.mem.Allocator,
    snapshots: []const Types.MessageSnapshot,
) ![]Types.MessageSnapshot {
    const owned = try allocator.alloc(Types.MessageSnapshot, snapshots.len);
    var initialized: usize = 0;
    errdefer deinitMessageSnapshots(owned[0..initialized], allocator);

    for (snapshots, 0..) |snapshot, index| {
        owned[index] = try copyMessageSnapshot(allocator, snapshot);
        initialized += 1;
    }
    return owned;
}

pub fn copyMessageSnapshot(
    allocator: std.mem.Allocator,
    snapshot: Types.MessageSnapshot,
) !Types.MessageSnapshot {
    const content = try allocator.dupe(u8, snapshot.content);
    errdefer allocator.free(content);
    const timestamp = if (snapshot.timestamp) |value| try allocator.dupe(u8, value) else null;
    errdefer if (timestamp) |value| allocator.free(value);
    const edited_timestamp = if (snapshot.edited_timestamp) |value| try allocator.dupe(u8, value) else null;
    errdefer if (edited_timestamp) |value| allocator.free(value);
    const mentions = try copyUsers(allocator, snapshot.mentions);
    errdefer deinitUsers(mentions, allocator);
    const mention_roles = try allocator.dupe(Snowflake, snapshot.mention_roles);
    errdefer allocator.free(mention_roles);
    const embeds = try copyEmbeds(allocator, snapshot.embeds);
    errdefer deinitEmbeds(embeds, allocator);
    const attachments = try copyAttachments(allocator, snapshot.attachments);
    errdefer deinitAttachments(attachments, allocator);
    const components = try copyComponents(allocator, snapshot.components);
    errdefer deinitComponents(components, allocator);

    return .{
        .type = snapshot.type,
        .content = content,
        .timestamp = timestamp,
        .edited_timestamp = edited_timestamp,
        .flags = snapshot.flags,
        .mentions = mentions,
        .mention_roles = mention_roles,
        .embeds = embeds,
        .attachments = attachments,
        .components = components,
    };
}

pub fn deinitMessageSnapshots(snapshots: []Types.MessageSnapshot, allocator: std.mem.Allocator) void {
    for (snapshots) |snapshot| deinitMessageSnapshot(snapshot, allocator);
    allocator.free(snapshots);
}

pub fn deinitMessageSnapshot(snapshot: Types.MessageSnapshot, allocator: std.mem.Allocator) void {
    allocator.free(snapshot.content);
    if (snapshot.timestamp) |value| allocator.free(value);
    if (snapshot.edited_timestamp) |value| allocator.free(value);
    deinitUsers(@constCast(snapshot.mentions), allocator);
    allocator.free(snapshot.mention_roles);
    deinitEmbeds(@constCast(snapshot.embeds), allocator);
    deinitAttachments(@constCast(snapshot.attachments), allocator);
    deinitComponents(@constCast(snapshot.components), allocator);
}

pub fn copyMessageStickerItems(
    allocator: std.mem.Allocator,
    sticker_items: []const Types.MessageStickerItem,
) ![]Types.MessageStickerItem {
    const owned = try allocator.alloc(Types.MessageStickerItem, sticker_items.len);
    var initialized: usize = 0;
    errdefer deinitMessageStickerItems(owned[0..initialized], allocator);

    for (sticker_items, 0..) |sticker_item, index| {
        owned[index] = .{
            .id = sticker_item.id,
            .name = try allocator.dupe(u8, sticker_item.name),
            .format_type = sticker_item.format_type,
        };
        initialized += 1;
    }
    return owned;
}

pub fn deinitMessageStickerItems(sticker_items: []Types.MessageStickerItem, allocator: std.mem.Allocator) void {
    for (sticker_items) |sticker_item| allocator.free(sticker_item.name);
    allocator.free(sticker_items);
}

pub fn copyStickers(allocator: std.mem.Allocator, stickers: []const Types.Sticker) ![]Types.Sticker {
    const owned = try allocator.alloc(Types.Sticker, stickers.len);
    var initialized: usize = 0;
    errdefer deinitStickers(owned[0..initialized], allocator);

    for (stickers, 0..) |sticker, index| {
        owned[index] = try copySticker(allocator, sticker);
        initialized += 1;
    }
    return owned;
}

pub fn copySticker(allocator: std.mem.Allocator, sticker: Types.Sticker) !Types.Sticker {
    const name = try allocator.dupe(u8, sticker.name);
    errdefer allocator.free(name);
    const description = if (sticker.description) |value| try allocator.dupe(u8, value) else null;
    errdefer if (description) |value| allocator.free(value);
    const tags = try allocator.dupe(u8, sticker.tags);
    errdefer allocator.free(tags);
    const user = if (sticker.user) |value| try copyUser(allocator, value) else null;

    return .{
        .id = sticker.id,
        .pack_id = sticker.pack_id,
        .name = name,
        .description = description,
        .tags = tags,
        .type = sticker.type,
        .format_type = sticker.format_type,
        .available = sticker.available,
        .guild_id = sticker.guild_id,
        .user = user,
        .sort_value = sticker.sort_value,
    };
}

pub fn deinitStickers(stickers: []Types.Sticker, allocator: std.mem.Allocator) void {
    for (stickers) |sticker| deinitSticker(sticker, allocator);
    allocator.free(stickers);
}

pub fn deinitSticker(sticker: Types.Sticker, allocator: std.mem.Allocator) void {
    allocator.free(sticker.name);
    if (sticker.description) |value| allocator.free(value);
    allocator.free(sticker.tags);
    if (sticker.user) |value| deinitUser(value, allocator);
}

pub fn copyComponents(allocator: std.mem.Allocator, components: []const Interactions.Component) anyerror![]Interactions.Component {
    const owned = try allocator.alloc(Interactions.Component, components.len);
    var initialized: usize = 0;
    errdefer deinitComponents(owned[0..initialized], allocator);

    for (components, 0..) |component, index| {
        owned[index] = try copyComponent(allocator, component);
        initialized += 1;
    }
    return owned;
}

pub fn copyComponent(allocator: std.mem.Allocator, component: Interactions.Component) anyerror!Interactions.Component {
    return switch (component) {
        .action_row => |children| .{ .action_row = try copyComponents(allocator, children) },
        .button => |button| .{ .button = try copyButton(allocator, button) },
        .string_select => |select| .{ .string_select = try copyStringSelect(allocator, select) },
        .user_select => |select| .{ .user_select = try copyAutoSelect(allocator, select) },
        .role_select => |select| .{ .role_select = try copyAutoSelect(allocator, select) },
        .mentionable_select => |select| .{ .mentionable_select = try copyAutoSelect(allocator, select) },
        .channel_select => |select| .{ .channel_select = try copyAutoSelect(allocator, select) },
        .text_input => |input| .{ .text_input = try copyTextInput(allocator, input) },
        .section => |value| .{ .section = try copySection(allocator, value) },
        .text_display => |value| .{ .text_display = try copyTextDisplay(allocator, value) },
        .thumbnail => |value| .{ .thumbnail = try copyThumbnail(allocator, value) },
        .media_gallery => |value| .{ .media_gallery = try copyMediaGallery(allocator, value) },
        .file => |value| .{ .file = try copyFileComponent(allocator, value) },
        .separator => |value| .{ .separator = value },
        .container => |value| .{ .container = try copyContainer(allocator, value) },
    };
}

pub fn copyButton(allocator: std.mem.Allocator, button: Interactions.Button) !Interactions.Button {
    const custom_id = if (button.custom_id) |value| try allocator.dupe(u8, value) else null;
    errdefer if (custom_id) |value| allocator.free(value);
    const label = if (button.label) |value| try allocator.dupe(u8, value) else null;
    errdefer if (label) |value| allocator.free(value);
    const url = if (button.url) |value| try allocator.dupe(u8, value) else null;
    return .{ .custom_id = custom_id, .label = label, .style = button.style, .url = url, .disabled = button.disabled };
}

pub fn copyStringSelect(allocator: std.mem.Allocator, select: Interactions.StringSelect) !Interactions.StringSelect {
    const custom_id = try allocator.dupe(u8, select.custom_id);
    errdefer allocator.free(custom_id);
    const options = try copySelectOptions(allocator, select.options);
    errdefer deinitSelectOptions(options, allocator);
    const placeholder = if (select.placeholder) |value| try allocator.dupe(u8, value) else null;
    return .{
        .custom_id = custom_id,
        .options = options,
        .placeholder = placeholder,
        .min_values = select.min_values,
        .max_values = select.max_values,
        .disabled = select.disabled,
    };
}

pub fn copyAutoSelect(allocator: std.mem.Allocator, select: Interactions.AutoSelect) !Interactions.AutoSelect {
    const custom_id = try allocator.dupe(u8, select.custom_id);
    errdefer allocator.free(custom_id);
    const placeholder = if (select.placeholder) |value| try allocator.dupe(u8, value) else null;
    errdefer if (placeholder) |value| allocator.free(value);
    const channel_types = try allocator.dupe(u8, select.channel_types);
    return .{
        .type = select.type,
        .custom_id = custom_id,
        .placeholder = placeholder,
        .min_values = select.min_values,
        .max_values = select.max_values,
        .disabled = select.disabled,
        .channel_types = channel_types,
    };
}

pub fn copyTextInput(allocator: std.mem.Allocator, input: Interactions.TextInput) !Interactions.TextInput {
    const custom_id = try allocator.dupe(u8, input.custom_id);
    errdefer allocator.free(custom_id);
    const label = try allocator.dupe(u8, input.label);
    errdefer allocator.free(label);
    const placeholder = if (input.placeholder) |value| try allocator.dupe(u8, value) else null;
    errdefer if (placeholder) |value| allocator.free(value);
    const value = if (input.value) |field| try allocator.dupe(u8, field) else null;
    return .{
        .custom_id = custom_id,
        .label = label,
        .style = input.style,
        .placeholder = placeholder,
        .value = value,
        .required = input.required,
        .min_length = input.min_length,
        .max_length = input.max_length,
    };
}

pub fn copyTextDisplay(allocator: std.mem.Allocator, value: Interactions.TextDisplay) !Interactions.TextDisplay {
    return .{ .content = try allocator.dupe(u8, value.content), .id = value.id };
}

pub fn copyUnfurledMedia(allocator: std.mem.Allocator, value: Interactions.UnfurledMedia) !Interactions.UnfurledMedia {
    return .{ .url = try allocator.dupe(u8, value.url) };
}

pub fn copyThumbnail(allocator: std.mem.Allocator, value: Interactions.Thumbnail) !Interactions.Thumbnail {
    const media = try copyUnfurledMedia(allocator, value.media);
    errdefer allocator.free(media.url);
    const description = if (value.description) |field| try allocator.dupe(u8, field) else null;
    return .{ .media = media, .description = description, .spoiler = value.spoiler, .id = value.id };
}

pub fn copySection(allocator: std.mem.Allocator, value: Interactions.Section) !Interactions.Section {
    const components = try allocator.alloc(Interactions.TextDisplay, value.components.len);
    var initialized: usize = 0;
    errdefer {
        for (components[0..initialized]) |text| allocator.free(text.content);
        allocator.free(components);
    }
    for (value.components, 0..) |text, index| {
        components[index] = try copyTextDisplay(allocator, text);
        initialized += 1;
    }
    const accessory: Interactions.SectionAccessory = switch (value.accessory) {
        .button => |button| .{ .button = try copyButton(allocator, button) },
        .thumbnail => |thumbnail| .{ .thumbnail = try copyThumbnail(allocator, thumbnail) },
    };
    return .{ .components = components, .accessory = accessory, .id = value.id };
}

pub fn copyMediaGallery(allocator: std.mem.Allocator, value: Interactions.MediaGallery) !Interactions.MediaGallery {
    const items = try allocator.alloc(Interactions.MediaGalleryItem, value.items.len);
    var initialized: usize = 0;
    errdefer {
        for (items[0..initialized]) |item| deinitMediaGalleryItem(item, allocator);
        allocator.free(items);
    }
    for (value.items, 0..) |item, index| {
        const media = try copyUnfurledMedia(allocator, item.media);
        errdefer allocator.free(media.url);
        const description = if (item.description) |field| try allocator.dupe(u8, field) else null;
        items[index] = .{ .media = media, .description = description, .spoiler = item.spoiler };
        initialized += 1;
    }
    return .{ .items = items, .id = value.id };
}

pub fn copyFileComponent(allocator: std.mem.Allocator, value: Interactions.FileComponent) !Interactions.FileComponent {
    return .{ .file = try copyUnfurledMedia(allocator, value.file), .spoiler = value.spoiler, .id = value.id };
}

pub fn copyContainer(allocator: std.mem.Allocator, value: Interactions.Container) !Interactions.Container {
    return .{
        .components = try copyComponents(allocator, value.components),
        .accent_color = value.accent_color,
        .spoiler = value.spoiler,
        .id = value.id,
    };
}

pub fn copySelectOptions(allocator: std.mem.Allocator, options: []const Interactions.SelectOption) ![]Interactions.SelectOption {
    const owned = try allocator.alloc(Interactions.SelectOption, options.len);
    var initialized: usize = 0;
    errdefer deinitSelectOptions(owned[0..initialized], allocator);

    for (options, 0..) |option, index| {
        const label = try allocator.dupe(u8, option.label);
        errdefer allocator.free(label);
        const value = try allocator.dupe(u8, option.value);
        errdefer allocator.free(value);
        const description = if (option.description) |field| try allocator.dupe(u8, field) else null;
        owned[index] = .{ .label = label, .value = value, .description = description, .default = option.default };
        initialized += 1;
    }
    return owned;
}

pub fn deinitComponents(components: []Interactions.Component, allocator: std.mem.Allocator) void {
    for (components) |component| deinitComponent(component, allocator);
    allocator.free(components);
}
