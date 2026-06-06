const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Json = @import("../../core/json.zig");

const Root = @import("../mod.zig");
const InteractionType = Root.InteractionType;
const ComponentType = Root.ComponentType;
const ApplicationCommandType = Root.ApplicationCommandType;
const max_command_options = Root.max_command_options;
const max_command_choices = Root.max_command_choices;
const ValidationError = Root.ValidationError;
const checkNameLen = Root.checkNameLen;
const checkDescriptionLen = Root.checkDescriptionLen;
const Localization = Root.Localization;
const ApplicationCommandOptionType = Root.ApplicationCommandOptionType;
const CommandChoice = Root.CommandChoice;
const writeLocalizationObject = Root.writeLocalizationObject;
const writeOptionArray = Root.writeOptionArray;
const writeChoiceArray = Root.writeChoiceArray;
const objectValue = Root.objectValue;
const arrayValue = Root.arrayValue;
const snowflakeField = Root.snowflakeField;
const snowflakeValue = Root.snowflakeValue;
const stringField = Root.stringField;
const integerValue = Root.integerValue;
const boolValue = Root.boolValue;

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

    pub fn writeJson(self: ApplicationCommandOption, writer: anytype) anyerror!void {
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

pub const Resolved = struct {
    users: ?std.json.ObjectMap = null,
    members: ?std.json.ObjectMap = null,
    roles: ?std.json.ObjectMap = null,
    channels: ?std.json.ObjectMap = null,
    messages: ?std.json.ObjectMap = null,
    attachments: ?std.json.ObjectMap = null,

    pub fn lookup(map: ?std.json.ObjectMap, id: Snowflake) ?std.json.Value {
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

pub fn parseResolvedUser(value: std.json.Value) !ResolvedUser {
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

pub fn parseResolvedRole(value: std.json.Value) !ResolvedRole {
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

pub fn optionalStringValue(value: std.json.Value) !?[]const u8 {
    return switch (value) {
        .string => |string| string,
        .null => null,
        else => error.InvalidField,
    };
}

pub fn permissionsBitValue(value: std.json.Value) !u64 {
    return switch (value) {
        .string => |string| std.fmt.parseInt(u64, string, 10) catch error.InvalidField,
        .integer => |integer| @intCast(integer),
        else => error.InvalidField,
    };
}

pub const ResolvedChannel = struct {
    id: Snowflake,
    name: ?[]const u8 = null,
    type: u8 = 0,
    permissions: ?u64 = null,
    parent_id: ?Snowflake = null,
};

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

pub fn parseResolvedChannel(value: std.json.Value) !ResolvedChannel {
    const object = try objectValue(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .name = if (object.get("name")) |field| try optionalStringValue(field) else null,
        .type = if (object.get("type")) |field| @as(u8, @intCast(try integerValue(field))) else 0,
        .permissions = if (object.get("permissions")) |field| try permissionsBitValue(field) else null,
        .parent_id = if (object.get("parent_id")) |field| try optionalSnowflakeValue(field) else null,
    };
}

pub fn parseResolvedMember(value: std.json.Value) !ResolvedMember {
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

pub fn optionalSnowflakeValue(value: std.json.Value) !?Snowflake {
    return switch (value) {
        .string => |string| try Snowflake.parse(string),
        .null => null,
        else => error.InvalidField,
    };
}

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

pub fn parseResolvedAttachment(value: std.json.Value) !ResolvedAttachment {
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

pub fn parseResolvedMessage(value: std.json.Value) !ResolvedMessage {
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

pub fn optionalU32Field(value: std.json.Value) !?u32 {
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

    pub fn findFocused(options: []const CommandDataOption) ?CommandDataOption {
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

pub const Middleware = struct {
    ptr: *anyopaque,
    callFn: *const fn (ptr: *anyopaque, interaction: *const ParsedInteraction) anyerror!bool,

    pub fn call(self: Middleware, interaction: *const ParsedInteraction) !bool {
        return self.callFn(self.ptr, interaction);
    }
};
