const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Json = @import("../../core/json.zig");
const Permissions = @import("../../core/permissions.zig");

const Root = @import("../types.zig");
const RoleColors = Root.RoleColors;
const DefaultReactionEmoji = Root.DefaultReactionEmoji;
const ChannelFlags = Root.ChannelFlags;
const ChannelSortOrder = Root.ChannelSortOrder;
const ForumLayout = Root.ForumLayout;
const WriteForumTag = Root.WriteForumTag;
const PermissionOverwriteType = Root.PermissionOverwriteType;
const ChannelType = Root.ChannelType;
const writeRoleFields = Root.writeRoleFields;
const writeThreadEditFields = Root.writeThreadEditFields;
const writeChannelFields = Root.writeChannelFields;
const writeSnowflakeStringArray = Root.writeSnowflakeStringArray;
const writeSnowflakeCommaList = Root.writeSnowflakeCommaList;
const writeOptionalStringField = Root.writeOptionalStringField;
const writeNullableSnowflakeField = Root.writeNullableSnowflakeField;
const writeOptionalIntegerField = Root.writeOptionalIntegerField;
const writeOptionalBoolField = Root.writeOptionalBoolField;
const writeSnowflakeQueryParam = Root.writeSnowflakeQueryParam;
const writeQueryStringValue = Root.writeQueryStringValue;
const writeQuerySeparator = Root.writeQuerySeparator;
const writeComma = Root.writeComma;

pub const ListGuildBans = struct {
    before: ?Snowflake = null,
    after: ?Snowflake = null,
    limit: ?u16 = null,

    pub fn init() ListGuildBans {
        return .{};
    }

    pub fn beforeUser(self: ListGuildBans, user_id: Snowflake) ListGuildBans {
        var options = self;
        options.before = user_id;
        return options;
    }

    pub fn afterUser(self: ListGuildBans, user_id: Snowflake) ListGuildBans {
        var options = self;
        options.after = user_id;
        return options;
    }

    pub fn withLimit(self: ListGuildBans, limit: u16) ListGuildBans {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn hasQuery(self: ListGuildBans) bool {
        return self.before != null or self.after != null or self.limit != null;
    }

    pub fn writeQuery(self: ListGuildBans, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.before) |before| try writeSnowflakeQueryParam(writer, &needs_ampersand, "before", before);
        if (self.after) |after| try writeSnowflakeQueryParam(writer, &needs_ampersand, "after", after);
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
    }
};

pub const ListGuildMembers = struct {
    limit: ?u16 = null,
    after: ?Snowflake = null,

    pub fn init() ListGuildMembers {
        return .{};
    }

    pub fn withLimit(self: ListGuildMembers, limit: u16) ListGuildMembers {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn afterMember(self: ListGuildMembers, user_id: Snowflake) ListGuildMembers {
        var options = self;
        options.after = user_id;
        return options;
    }

    pub fn hasQuery(self: ListGuildMembers) bool {
        return self.limit != null or self.after != null;
    }

    pub fn writeQuery(self: ListGuildMembers, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
        if (self.after) |after| try writeSnowflakeQueryParam(writer, &needs_ampersand, "after", after);
    }
};

pub const GetGuildPruneCount = struct {
    days: ?u8 = null,
    include_roles: []const Snowflake = &.{},

    pub fn init() GetGuildPruneCount {
        return .{};
    }

    pub fn withDays(self: GetGuildPruneCount, days: u8) GetGuildPruneCount {
        var options = self;
        options.days = days;
        return options;
    }

    pub fn withRoles(self: GetGuildPruneCount, include_roles: []const Snowflake) GetGuildPruneCount {
        var options = self;
        options.include_roles = include_roles;
        return options;
    }

    pub fn hasQuery(self: GetGuildPruneCount) bool {
        return self.days != null or self.include_roles.len != 0;
    }

    pub fn writeQuery(self: GetGuildPruneCount, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.days) |days| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("days={d}", .{days});
        }
        if (self.include_roles.len != 0) {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.writeAll("include_roles=");
            try writeSnowflakeCommaList(self.include_roles, writer);
        }
    }
};

pub const BeginGuildPrune = struct {
    days: ?u8 = null,
    compute_prune_count: ?bool = null,
    include_roles: []const Snowflake = &.{},

    pub fn init() BeginGuildPrune {
        return .{};
    }

    pub fn withDays(self: BeginGuildPrune, days: u8) BeginGuildPrune {
        var payload = self;
        payload.days = days;
        return payload;
    }

    pub fn computeCount(self: BeginGuildPrune, compute_prune_count: bool) BeginGuildPrune {
        var payload = self;
        payload.compute_prune_count = compute_prune_count;
        return payload;
    }

    pub fn withRoles(self: BeginGuildPrune, include_roles: []const Snowflake) BeginGuildPrune {
        var payload = self;
        payload.include_roles = include_roles;
        return payload;
    }

    pub fn writeJson(self: BeginGuildPrune, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        if (self.days) |days| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"days\":{d}", .{days});
        }
        try writeOptionalBoolField(writer, &needs_comma, "compute_prune_count", self.compute_prune_count);
        if (self.include_roles.len != 0) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"include_roles\":");
            try writeSnowflakeStringArray(self.include_roles, writer);
        }
        try writer.writeByte('}');
    }
};

pub const SearchGuildMembers = struct {
    query: []const u8,
    limit: ?u16 = null,

    pub fn init(query: []const u8) SearchGuildMembers {
        return .{ .query = query };
    }

    pub fn withLimit(self: SearchGuildMembers, limit: u16) SearchGuildMembers {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn writeQuery(self: SearchGuildMembers, writer: anytype) !void {
        var needs_ampersand = false;
        try writeQuerySeparator(writer, &needs_ampersand);
        try writer.writeAll("query=");
        try writeQueryStringValue(self.query, writer);
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
    }
};

pub const EditChannel = struct {
    name: ?[]const u8 = null,
    type: ?ChannelType = null,
    topic: ?[]const u8 = null,
    nsfw: bool = false,
    rate_limit_per_user: ?u16 = null,
    bitrate: ?u32 = null,
    user_limit: ?u16 = null,
    flags: ?ChannelFlags.Bit = null,
    parent_id: ?Snowflake = null,
    position: ?i32 = null,
    archived: ?bool = null,
    auto_archive_duration: ?u16 = null,
    locked: ?bool = null,
    invitable: ?bool = null,
    applied_tags: ?[]const Snowflake = null,
    available_tags: ?[]const WriteForumTag = null,
    default_reaction_emoji: ?DefaultReactionEmoji = null,
    default_thread_rate_limit_per_user: ?u16 = null,
    default_sort_order: ?ChannelSortOrder = null,
    default_forum_layout: ?ForumLayout = null,

    pub fn init() EditChannel {
        return .{};
    }

    pub fn withName(self: EditChannel, name: []const u8) EditChannel {
        var payload = self;
        payload.name = name;
        return payload;
    }

    pub fn withType(self: EditChannel, channel_type: ChannelType) EditChannel {
        var payload = self;
        payload.type = channel_type;
        return payload;
    }

    pub fn withTopic(self: EditChannel, topic: []const u8) EditChannel {
        var payload = self;
        payload.topic = topic;
        return payload;
    }

    pub fn nsfwState(self: EditChannel, nsfw: bool) EditChannel {
        var payload = self;
        payload.nsfw = nsfw;
        return payload;
    }

    pub fn withRateLimit(self: EditChannel, seconds: u16) EditChannel {
        var payload = self;
        payload.rate_limit_per_user = seconds;
        return payload;
    }

    pub fn withBitrate(self: EditChannel, bitrate: u32) EditChannel {
        var payload = self;
        payload.bitrate = bitrate;
        return payload;
    }

    pub fn withUserLimit(self: EditChannel, user_limit: u16) EditChannel {
        var payload = self;
        payload.user_limit = user_limit;
        return payload;
    }

    pub fn withFlags(self: EditChannel, flags: ChannelFlags.Bit) EditChannel {
        var payload = self;
        payload.flags = flags;
        return payload;
    }

    pub fn withParent(self: EditChannel, parent_id: Snowflake) EditChannel {
        var payload = self;
        payload.parent_id = parent_id;
        return payload;
    }

    pub fn withPosition(self: EditChannel, position: i32) EditChannel {
        var payload = self;
        payload.position = position;
        return payload;
    }

    pub fn archivedState(self: EditChannel, archived: bool) EditChannel {
        var payload = self;
        payload.archived = archived;
        return payload;
    }

    pub fn withAutoArchiveDuration(self: EditChannel, minutes: u16) EditChannel {
        var payload = self;
        payload.auto_archive_duration = minutes;
        return payload;
    }

    pub fn lockedState(self: EditChannel, locked: bool) EditChannel {
        var payload = self;
        payload.locked = locked;
        return payload;
    }

    pub fn invitableState(self: EditChannel, invitable: bool) EditChannel {
        var payload = self;
        payload.invitable = invitable;
        return payload;
    }

    pub fn withAppliedTags(self: EditChannel, tags: []const Snowflake) EditChannel {
        var payload = self;
        payload.applied_tags = tags;
        return payload;
    }

    pub fn clearAppliedTags(self: EditChannel) EditChannel {
        var payload = self;
        payload.applied_tags = &.{};
        return payload;
    }

    pub fn withAvailableTags(self: EditChannel, tags: []const WriteForumTag) EditChannel {
        var payload = self;
        payload.available_tags = tags;
        return payload;
    }

    pub fn clearAvailableTags(self: EditChannel) EditChannel {
        var payload = self;
        payload.available_tags = &.{};
        return payload;
    }

    pub fn withDefaultReactionEmoji(self: EditChannel, emoji: DefaultReactionEmoji) EditChannel {
        var payload = self;
        payload.default_reaction_emoji = emoji;
        return payload;
    }

    pub fn withDefaultThreadRateLimit(self: EditChannel, seconds: u16) EditChannel {
        var payload = self;
        payload.default_thread_rate_limit_per_user = seconds;
        return payload;
    }

    pub fn withDefaultSortOrder(self: EditChannel, sort_order: ChannelSortOrder) EditChannel {
        var payload = self;
        payload.default_sort_order = sort_order;
        return payload;
    }

    pub fn withDefaultForumLayout(self: EditChannel, layout: ForumLayout) EditChannel {
        var payload = self;
        payload.default_forum_layout = layout;
        return payload;
    }

    pub fn writeJson(self: EditChannel, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "name", self.name);
        try writeChannelFields(.{
            .type = self.type,
            .topic = self.topic,
            .nsfw = self.nsfw,
            .rate_limit_per_user = self.rate_limit_per_user,
            .bitrate = self.bitrate,
            .user_limit = self.user_limit,
            .flags = self.flags,
            .parent_id = self.parent_id,
            .position = self.position,
            .available_tags = self.available_tags,
            .default_reaction_emoji = self.default_reaction_emoji,
            .default_thread_rate_limit_per_user = self.default_thread_rate_limit_per_user,
            .default_sort_order = self.default_sort_order,
            .default_forum_layout = self.default_forum_layout,
        }, writer, &needs_comma);
        try writeThreadEditFields(.{
            .archived = self.archived,
            .auto_archive_duration = self.auto_archive_duration,
            .locked = self.locked,
            .invitable = self.invitable,
            .applied_tags = self.applied_tags,
        }, writer, &needs_comma);

        try writer.writeByte('}');
    }
};

pub const GuildChannelPosition = struct {
    id: Snowflake,
    position: ?i32 = null,
    lock_permissions: ?bool = null,
    parent_id: ?Snowflake = null,
    clear_parent_id: bool = false,

    pub fn init(id: Snowflake) GuildChannelPosition {
        return .{ .id = id };
    }

    pub fn withPosition(self: GuildChannelPosition, position: i32) GuildChannelPosition {
        var payload = self;
        payload.position = position;
        return payload;
    }

    pub fn lockPermissions(self: GuildChannelPosition, lock_permissions: bool) GuildChannelPosition {
        var payload = self;
        payload.lock_permissions = lock_permissions;
        return payload;
    }

    pub fn withParent(self: GuildChannelPosition, parent_id: Snowflake) GuildChannelPosition {
        var payload = self;
        payload.parent_id = parent_id;
        payload.clear_parent_id = false;
        return payload;
    }

    pub fn clearParent(self: GuildChannelPosition) GuildChannelPosition {
        var payload = self;
        payload.parent_id = null;
        payload.clear_parent_id = true;
        return payload;
    }

    pub fn writeJson(self: GuildChannelPosition, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.print("\"id\":\"{d}\"", .{self.id.value});
        try writeOptionalIntegerField(writer, &needs_comma, "position", self.position);
        try writeOptionalBoolField(writer, &needs_comma, "lock_permissions", self.lock_permissions);
        try writeNullableSnowflakeField(writer, &needs_comma, "parent_id", self.parent_id, self.clear_parent_id);

        try writer.writeByte('}');
    }
};

pub const EditChannelPermission = struct {
    type: PermissionOverwriteType,
    allow: ?Permissions.Bit = null,
    deny: ?Permissions.Bit = null,

    pub fn init(overwrite_type: PermissionOverwriteType) EditChannelPermission {
        return .{ .type = overwrite_type };
    }

    pub fn withAllow(self: EditChannelPermission, allow: Permissions.Bit) EditChannelPermission {
        var payload = self;
        payload.allow = allow;
        return payload;
    }

    pub fn withDeny(self: EditChannelPermission, deny: Permissions.Bit) EditChannelPermission {
        var payload = self;
        payload.deny = deny;
        return payload;
    }

    pub fn writeJson(self: EditChannelPermission, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.print("\"type\":{d}", .{@intFromEnum(self.type)});
        if (self.allow) |allow| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"allow\":\"{d}\"", .{allow});
        }
        if (self.deny) |deny| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"deny\":\"{d}\"", .{deny});
        }

        try writer.writeByte('}');
    }
};

pub const SetVoiceChannelStatus = struct {
    status: ?[]const u8,

    pub fn init(status: []const u8) SetVoiceChannelStatus {
        return .{ .status = status };
    }

    pub fn clear() SetVoiceChannelStatus {
        return .{ .status = null };
    }

    pub fn writeJson(self: SetVoiceChannelStatus, writer: anytype) !void {
        try writer.writeAll("{\"status\":");
        if (self.status) |status| {
            try Json.writeString(status, writer);
        } else {
            try writer.writeAll("null");
        }
        try writer.writeByte('}');
    }
};

pub const FollowAnnouncementChannel = struct {
    webhook_channel_id: Snowflake,

    pub fn init(webhook_channel_id: Snowflake) FollowAnnouncementChannel {
        return .{ .webhook_channel_id = webhook_channel_id };
    }

    pub fn writeJson(self: FollowAnnouncementChannel, writer: anytype) !void {
        try writer.print("{{\"webhook_channel_id\":\"{d}\"}}", .{self.webhook_channel_id.value});
    }
};

pub const CreateGuildRole = struct {
    name: []const u8,
    permissions: ?Permissions.Bit = null,
    color: ?u24 = null,
    colors: ?RoleColors = null,
    hoist: ?bool = null,
    icon: ?[]const u8 = null,
    unicode_emoji: ?[]const u8 = null,
    mentionable: ?bool = null,

    pub fn init(name: []const u8) CreateGuildRole {
        return .{ .name = name };
    }

    pub fn withPermissions(self: CreateGuildRole, permissions: Permissions.Bit) CreateGuildRole {
        var role = self;
        role.permissions = permissions;
        return role;
    }

    pub fn withColor(self: CreateGuildRole, color: u24) CreateGuildRole {
        var role = self;
        role.color = color;
        return role;
    }

    pub fn withColors(self: CreateGuildRole, colors: RoleColors) CreateGuildRole {
        var role = self;
        role.colors = colors;
        return role;
    }

    pub fn hoisted(self: CreateGuildRole, hoist: bool) CreateGuildRole {
        var role = self;
        role.hoist = hoist;
        return role;
    }

    pub fn withIcon(self: CreateGuildRole, icon: []const u8) CreateGuildRole {
        var role = self;
        role.icon = icon;
        return role;
    }

    pub fn withUnicodeEmoji(self: CreateGuildRole, unicode_emoji: []const u8) CreateGuildRole {
        var role = self;
        role.unicode_emoji = unicode_emoji;
        return role;
    }

    pub fn mentionableState(self: CreateGuildRole, mentionable: bool) CreateGuildRole {
        var role = self;
        role.mentionable = mentionable;
        return role;
    }

    pub fn writeJson(self: CreateGuildRole, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);

        try writeRoleFields(.{
            .permissions = self.permissions,
            .color = self.color,
            .colors = self.colors,
            .hoist = self.hoist,
            .icon = self.icon,
            .unicode_emoji = self.unicode_emoji,
            .mentionable = self.mentionable,
        }, writer, &needs_comma);

        try writer.writeByte('}');
    }
};
