const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Json = @import("../../core/json.zig");
const Interactions = @import("../../interactions/mod.zig");
const Permissions = @import("../../core/permissions.zig");

const Root = @import("../types.zig");
const StringPair = Root.StringPair;
const ChannelType = Root.ChannelType;
const MessageFlags = Root.MessageFlags;
const Embed = Root.Embed;
const AllowedMentions = Root.AllowedMentions;
const UploadFile = Root.UploadFile;
const writeThreadFields = Root.writeThreadFields;
const writeMessagePayloadFields = Root.writeMessagePayloadFields;
const writeUploadAttachmentArray = Root.writeUploadAttachmentArray;
const writeStringPairObject = Root.writeStringPairObject;
const writeNullableStringPairObjectField = Root.writeNullableStringPairObjectField;
const writeLobbyPayloadJson = Root.writeLobbyPayloadJson;
const writeSnowflakeStringArray = Root.writeSnowflakeStringArray;
const writeOptionalStringField = Root.writeOptionalStringField;
const writeNullableStringField = Root.writeNullableStringField;
const writeOptionalBoolField = Root.writeOptionalBoolField;
const writeSnowflakeQueryParam = Root.writeSnowflakeQueryParam;
const writeQuerySeparator = Root.writeQuerySeparator;
const writeComma = Root.writeComma;

pub const EditCurrentGuildMember = struct {
    nick: ?[]const u8 = null,
    clear_nick: bool = false,
    avatar: ?[]const u8 = null,
    clear_avatar: bool = false,
    banner: ?[]const u8 = null,
    clear_banner: bool = false,
    bio: ?[]const u8 = null,
    clear_bio: bool = false,

    pub fn init() EditCurrentGuildMember {
        return .{};
    }

    pub fn withNick(self: EditCurrentGuildMember, nick: []const u8) EditCurrentGuildMember {
        var payload = self;
        payload.nick = nick;
        payload.clear_nick = false;
        return payload;
    }

    pub fn clearNick(self: EditCurrentGuildMember) EditCurrentGuildMember {
        var payload = self;
        payload.nick = null;
        payload.clear_nick = true;
        return payload;
    }

    pub fn withAvatar(self: EditCurrentGuildMember, avatar: []const u8) EditCurrentGuildMember {
        var payload = self;
        payload.avatar = avatar;
        payload.clear_avatar = false;
        return payload;
    }

    pub fn clearAvatar(self: EditCurrentGuildMember) EditCurrentGuildMember {
        var payload = self;
        payload.avatar = null;
        payload.clear_avatar = true;
        return payload;
    }

    pub fn withBanner(self: EditCurrentGuildMember, banner: []const u8) EditCurrentGuildMember {
        var payload = self;
        payload.banner = banner;
        payload.clear_banner = false;
        return payload;
    }

    pub fn clearBanner(self: EditCurrentGuildMember) EditCurrentGuildMember {
        var payload = self;
        payload.banner = null;
        payload.clear_banner = true;
        return payload;
    }

    pub fn withBio(self: EditCurrentGuildMember, bio: []const u8) EditCurrentGuildMember {
        var payload = self;
        payload.bio = bio;
        payload.clear_bio = false;
        return payload;
    }

    pub fn clearBio(self: EditCurrentGuildMember) EditCurrentGuildMember {
        var payload = self;
        payload.bio = null;
        payload.clear_bio = true;
        return payload;
    }

    pub fn writeJson(self: EditCurrentGuildMember, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeNullableStringField(writer, &needs_comma, "nick", self.nick, self.clear_nick);
        try writeNullableStringField(writer, &needs_comma, "avatar", self.avatar, self.clear_avatar);
        try writeNullableStringField(writer, &needs_comma, "banner", self.banner, self.clear_banner);
        try writeNullableStringField(writer, &needs_comma, "bio", self.bio, self.clear_bio);

        try writer.writeByte('}');
    }
};

pub const EditCurrentUserNick = struct {
    nick: ?[]const u8 = null,
    clear_nick: bool = false,

    pub fn init() EditCurrentUserNick {
        return .{};
    }

    pub fn withNick(self: EditCurrentUserNick, nick: []const u8) EditCurrentUserNick {
        var payload = self;
        payload.nick = nick;
        payload.clear_nick = false;
        return payload;
    }

    pub fn clearNick(self: EditCurrentUserNick) EditCurrentUserNick {
        var payload = self;
        payload.nick = null;
        payload.clear_nick = true;
        return payload;
    }

    pub fn writeJson(self: EditCurrentUserNick, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeNullableStringField(writer, &needs_comma, "nick", self.nick, self.clear_nick);

        try writer.writeByte('}');
    }
};

pub const EditCurrentUser = struct {
    username: ?[]const u8 = null,
    avatar: ?[]const u8 = null,
    clear_avatar: bool = false,
    banner: ?[]const u8 = null,
    clear_banner: bool = false,

    pub fn init() EditCurrentUser {
        return .{};
    }

    pub fn withUsername(self: EditCurrentUser, username: []const u8) EditCurrentUser {
        var payload = self;
        payload.username = username;
        return payload;
    }

    pub fn withAvatar(self: EditCurrentUser, avatar: []const u8) EditCurrentUser {
        var payload = self;
        payload.avatar = avatar;
        payload.clear_avatar = false;
        return payload;
    }

    pub fn clearAvatar(self: EditCurrentUser) EditCurrentUser {
        var payload = self;
        payload.avatar = null;
        payload.clear_avatar = true;
        return payload;
    }

    pub fn withBanner(self: EditCurrentUser, banner: []const u8) EditCurrentUser {
        var payload = self;
        payload.banner = banner;
        payload.clear_banner = false;
        return payload;
    }

    pub fn clearBanner(self: EditCurrentUser) EditCurrentUser {
        var payload = self;
        payload.banner = null;
        payload.clear_banner = true;
        return payload;
    }

    pub fn writeJson(self: EditCurrentUser, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "username", self.username);
        try writeNullableStringField(writer, &needs_comma, "avatar", self.avatar, self.clear_avatar);
        try writeNullableStringField(writer, &needs_comma, "banner", self.banner, self.clear_banner);

        try writer.writeByte('}');
    }
};

pub const UpdateApplicationRoleConnection = struct {
    platform_name: ?[]const u8 = null,
    platform_username: ?[]const u8 = null,
    metadata: ?[]const StringPair = null,

    pub fn init() UpdateApplicationRoleConnection {
        return .{};
    }

    pub fn withPlatformName(self: UpdateApplicationRoleConnection, platform_name: []const u8) UpdateApplicationRoleConnection {
        var payload = self;
        payload.platform_name = platform_name;
        return payload;
    }

    pub fn withPlatformUsername(self: UpdateApplicationRoleConnection, platform_username: []const u8) UpdateApplicationRoleConnection {
        var payload = self;
        payload.platform_username = platform_username;
        return payload;
    }

    pub fn withMetadata(self: UpdateApplicationRoleConnection, metadata: []const StringPair) UpdateApplicationRoleConnection {
        var payload = self;
        payload.metadata = metadata;
        return payload;
    }

    pub fn writeJson(self: UpdateApplicationRoleConnection, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "platform_name", self.platform_name);
        try writeOptionalStringField(writer, &needs_comma, "platform_username", self.platform_username);
        if (self.metadata) |metadata| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"metadata\":");
            try writeStringPairObject(metadata, writer);
        }

        try writer.writeByte('}');
    }
};

pub const CreateDmChannel = struct {
    recipient_id: Snowflake,

    pub fn init(recipient_id: Snowflake) CreateDmChannel {
        return .{ .recipient_id = recipient_id };
    }

    pub fn writeJson(self: CreateDmChannel, writer: anytype) !void {
        try writer.print("{{\"recipient_id\":\"{d}\"}}", .{self.recipient_id.value});
    }
};

pub const AddGroupDmRecipient = struct {
    access_token: []const u8,
    nick: ?[]const u8 = null,

    pub fn init(access_token: []const u8) AddGroupDmRecipient {
        return .{ .access_token = access_token };
    }

    pub fn withNick(self: AddGroupDmRecipient, nick: []const u8) AddGroupDmRecipient {
        var payload = self;
        payload.nick = nick;
        return payload;
    }

    pub fn writeJson(self: AddGroupDmRecipient, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        try writeOptionalStringField(writer, &needs_comma, "access_token", self.access_token);
        try writeOptionalStringField(writer, &needs_comma, "nick", self.nick);
        try writer.writeByte('}');
    }
};

pub const CreateThreadFromMessage = struct {
    name: []const u8,
    auto_archive_duration: ?u16 = null,
    rate_limit_per_user: ?u16 = null,

    pub fn init(name: []const u8) CreateThreadFromMessage {
        return .{ .name = name };
    }

    pub fn withAutoArchiveDuration(self: CreateThreadFromMessage, auto_archive_duration: u16) CreateThreadFromMessage {
        var payload = self;
        payload.auto_archive_duration = auto_archive_duration;
        return payload;
    }

    pub fn withRateLimit(self: CreateThreadFromMessage, rate_limit_per_user: u16) CreateThreadFromMessage {
        var payload = self;
        payload.rate_limit_per_user = rate_limit_per_user;
        return payload;
    }

    pub fn writeJson(self: CreateThreadFromMessage, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);
        try writeThreadFields(.{
            .auto_archive_duration = self.auto_archive_duration,
            .rate_limit_per_user = self.rate_limit_per_user,
        }, writer, &needs_comma);

        try writer.writeByte('}');
    }
};

pub const CreateThread = struct {
    name: []const u8,
    type: ChannelType = .public_thread,
    auto_archive_duration: ?u16 = null,
    rate_limit_per_user: ?u16 = null,
    invitable: ?bool = null,

    pub fn init(name: []const u8) CreateThread {
        return .{ .name = name };
    }

    pub fn withType(self: CreateThread, thread_type: ChannelType) CreateThread {
        var payload = self;
        payload.type = thread_type;
        return payload;
    }

    pub fn withAutoArchiveDuration(self: CreateThread, auto_archive_duration: u16) CreateThread {
        var payload = self;
        payload.auto_archive_duration = auto_archive_duration;
        return payload;
    }

    pub fn withRateLimit(self: CreateThread, rate_limit_per_user: u16) CreateThread {
        var payload = self;
        payload.rate_limit_per_user = rate_limit_per_user;
        return payload;
    }

    pub fn invitableState(self: CreateThread, invitable: bool) CreateThread {
        var payload = self;
        payload.invitable = invitable;
        return payload;
    }

    pub fn writeJson(self: CreateThread, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);
        try writer.print(",\"type\":{d}", .{@intFromEnum(self.type)});
        needs_comma = true;
        try writeThreadFields(.{
            .auto_archive_duration = self.auto_archive_duration,
            .rate_limit_per_user = self.rate_limit_per_user,
            .invitable = self.invitable,
        }, writer, &needs_comma);

        try writer.writeByte('}');
    }
};

pub const ForumThreadMessage = struct {
    content: []const u8 = "",
    embeds: []const Embed = &.{},
    allowed_mentions: ?AllowedMentions = null,
    components: []const Interactions.Component = &.{},
    sticker_ids: []const Snowflake = &.{},
    attachments: []const UploadFile = &.{},
    flags: ?MessageFlags.Bit = null,

    pub fn init(content: []const u8) ForumThreadMessage {
        return .{ .content = content };
    }

    pub fn empty() ForumThreadMessage {
        return .{};
    }

    pub fn withEmbeds(self: ForumThreadMessage, embeds: []const Embed) ForumThreadMessage {
        var message = self;
        message.embeds = embeds;
        return message;
    }

    pub fn withAllowedMentions(self: ForumThreadMessage, allowed_mentions: AllowedMentions) ForumThreadMessage {
        var message = self;
        message.allowed_mentions = allowed_mentions;
        return message;
    }

    pub fn withComponents(self: ForumThreadMessage, components: []const Interactions.Component) ForumThreadMessage {
        var message = self;
        message.components = components;
        return message;
    }

    pub fn withStickers(self: ForumThreadMessage, sticker_ids: []const Snowflake) ForumThreadMessage {
        var message = self;
        message.sticker_ids = sticker_ids;
        return message;
    }

    pub fn withAttachments(self: ForumThreadMessage, attachments: []const UploadFile) ForumThreadMessage {
        var message = self;
        message.attachments = attachments;
        return message;
    }

    pub fn withFlags(self: ForumThreadMessage, flags: MessageFlags.Bit) ForumThreadMessage {
        var message = self;
        message.flags = flags;
        return message;
    }

    pub fn writeJson(self: ForumThreadMessage, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        try writeMessagePayloadFields(.{
            .content = if (self.content.len != 0) self.content else null,
            .embeds = self.embeds,
            .sticker_ids = self.sticker_ids,
            .allowed_mentions = self.allowed_mentions,
            .components = self.components,
            .flags = self.flags,
        }, writer, &needs_comma);
        if (self.attachments.len != 0) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"attachments\":");
            try writeUploadAttachmentArray(self.attachments, writer);
        }
        try writer.writeByte('}');
    }
};

pub const CreateForumThread = struct {
    name: []const u8,
    message: ForumThreadMessage,
    auto_archive_duration: ?u16 = null,
    rate_limit_per_user: ?u16 = null,
    applied_tags: []const Snowflake = &.{},

    pub fn init(name: []const u8, message: ForumThreadMessage) CreateForumThread {
        return .{ .name = name, .message = message };
    }

    pub fn withAutoArchiveDuration(self: CreateForumThread, auto_archive_duration: u16) CreateForumThread {
        var payload = self;
        payload.auto_archive_duration = auto_archive_duration;
        return payload;
    }

    pub fn withRateLimit(self: CreateForumThread, rate_limit_per_user: u16) CreateForumThread {
        var payload = self;
        payload.rate_limit_per_user = rate_limit_per_user;
        return payload;
    }

    pub fn withAppliedTags(self: CreateForumThread, applied_tags: []const Snowflake) CreateForumThread {
        var payload = self;
        payload.applied_tags = applied_tags;
        return payload;
    }

    pub fn writeJson(self: CreateForumThread, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);
        try writeThreadFields(.{
            .auto_archive_duration = self.auto_archive_duration,
            .rate_limit_per_user = self.rate_limit_per_user,
        }, writer, &needs_comma);
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"message\":");
        try self.message.writeJson(writer);
        if (self.applied_tags.len != 0) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"applied_tags\":");
            try writeSnowflakeStringArray(self.applied_tags, writer);
        }
        try writer.writeByte('}');
    }
};

pub const Invite = struct {
    code: []const u8,
    type: ?u8 = null,
    guild_id: ?Snowflake = null,
    channel_id: ?Snowflake = null,
    inviter_id: ?Snowflake = null,
    target_type: ?u8 = null,
    target_user_id: ?Snowflake = null,
    target_application_id: ?Snowflake = null,
    approximate_presence_count: ?u32 = null,
    approximate_member_count: ?u32 = null,
    expires_at: ?[]const u8 = null,
    uses: ?u32 = null,
    max_uses: ?u32 = null,
    max_age: ?u32 = null,
    temporary: ?bool = null,
    created_at: ?[]const u8 = null,
    guild_scheduled_event_id: ?Snowflake = null,
};

pub const GetInvite = struct {
    with_counts: ?bool = null,
    guild_scheduled_event_id: ?Snowflake = null,

    pub fn init() GetInvite {
        return .{};
    }

    pub fn withCounts(self: GetInvite, with_counts: bool) GetInvite {
        var options = self;
        options.with_counts = with_counts;
        return options;
    }

    pub fn withScheduledEvent(self: GetInvite, event_id: Snowflake) GetInvite {
        var options = self;
        options.guild_scheduled_event_id = event_id;
        return options;
    }

    pub fn hasQuery(self: GetInvite) bool {
        return self.with_counts != null or self.guild_scheduled_event_id != null;
    }

    pub fn writeQuery(self: GetInvite, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.with_counts) |with_counts| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.writeAll("with_counts=");
            try writer.writeAll(if (with_counts) "true" else "false");
        }
        if (self.guild_scheduled_event_id) |event_id| {
            try writeSnowflakeQueryParam(writer, &needs_ampersand, "guild_scheduled_event_id", event_id);
        }
    }
};

pub const LobbyMember = struct {
    id: Snowflake,
    metadata: ?[]const StringPair = null,
    clear_metadata: bool = false,
    flags: ?u32 = null,
    remove_member: ?bool = null,

    pub fn init(id: Snowflake) LobbyMember {
        return .{ .id = id };
    }

    pub fn withMetadata(self: LobbyMember, metadata: []const StringPair) LobbyMember {
        var member = self;
        member.metadata = metadata;
        member.clear_metadata = false;
        return member;
    }

    pub fn clearMetadata(self: LobbyMember) LobbyMember {
        var member = self;
        member.metadata = null;
        member.clear_metadata = true;
        return member;
    }

    pub fn withFlags(self: LobbyMember, flags: u32) LobbyMember {
        var member = self;
        member.flags = flags;
        return member;
    }

    pub fn removeState(self: LobbyMember, remove_member: bool) LobbyMember {
        var member = self;
        member.remove_member = remove_member;
        return member;
    }

    pub fn writeJson(self: LobbyMember, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.print("\"id\":\"{d}\"", .{self.id.value});
        try writeNullableStringPairObjectField(writer, &needs_comma, "metadata", self.metadata, self.clear_metadata);
        if (self.flags) |flags| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"flags\":{d}", .{flags});
        }
        try writeOptionalBoolField(writer, &needs_comma, "remove_member", self.remove_member);

        try writer.writeByte('}');
    }
};

pub const CreateLobby = struct {
    metadata: ?[]const StringPair = null,
    clear_metadata: bool = false,
    members: []const LobbyMember = &.{},
    idle_timeout_seconds: ?u32 = null,

    pub fn init() CreateLobby {
        return .{};
    }

    pub fn withMetadata(self: CreateLobby, metadata: []const StringPair) CreateLobby {
        var payload = self;
        payload.metadata = metadata;
        payload.clear_metadata = false;
        return payload;
    }

    pub fn clearMetadata(self: CreateLobby) CreateLobby {
        var payload = self;
        payload.metadata = null;
        payload.clear_metadata = true;
        return payload;
    }

    pub fn withMembers(self: CreateLobby, members: []const LobbyMember) CreateLobby {
        var payload = self;
        payload.members = members;
        return payload;
    }

    pub fn withIdleTimeout(self: CreateLobby, idle_timeout_seconds: u32) CreateLobby {
        var payload = self;
        payload.idle_timeout_seconds = idle_timeout_seconds;
        return payload;
    }

    pub fn writeJson(self: CreateLobby, writer: anytype) !void {
        try writeLobbyPayloadJson(.{
            .metadata = self.metadata,
            .clear_metadata = self.clear_metadata,
            .members = self.members,
            .idle_timeout_seconds = self.idle_timeout_seconds,
        }, writer);
    }
};
