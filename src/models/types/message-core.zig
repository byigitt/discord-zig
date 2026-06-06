const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Json = @import("../../core/json.zig");
const Interactions = @import("../../interactions/mod.zig");

const Root = @import("../types.zig");
const User = Root.User;
const StringPair = Root.StringPair;
const Application = Root.Application;
const GuildMember = Root.GuildMember;
const Sticker = Root.Sticker;
const MessageStickerItem = Root.MessageStickerItem;
const Channel = Root.Channel;
const LobbyMember = Root.LobbyMember;
const MessageSnapshot = Root.MessageSnapshot;
const MessageCall = Root.MessageCall;
const RoleSubscriptionData = Root.RoleSubscriptionData;
const SharedClientTheme = Root.SharedClientTheme;
const MessageActivity = Root.MessageActivity;
const MessageInteractionMetadata = Root.MessageInteractionMetadata;
const Attachment = Root.Attachment;
const MessageReaction = Root.MessageReaction;
const MessagePoll = Root.MessagePoll;
const Embed = Root.Embed;
const AllowedMentions = Root.AllowedMentions;
const UploadFile = Root.UploadFile;
const writeMessagePayloadFields = Root.writeMessagePayloadFields;
const writeUploadAttachmentArray = Root.writeUploadAttachmentArray;
const writeStringPairObject = Root.writeStringPairObject;
const writeNullableStringPairObjectField = Root.writeNullableStringPairObjectField;
const writeLobbyPayloadJson = Root.writeLobbyPayloadJson;
const writeLobbyMemberArray = Root.writeLobbyMemberArray;
const writeSnowflakeStringArray = Root.writeSnowflakeStringArray;
const writeOptionalStringField = Root.writeOptionalStringField;
const writeNullableSnowflakeField = Root.writeNullableSnowflakeField;
const writeOptionalBoolField = Root.writeOptionalBoolField;
const writeComma = Root.writeComma;

pub const EditLobby = struct {
    metadata: ?[]const StringPair = null,
    clear_metadata: bool = false,
    members: []const LobbyMember = &.{},
    idle_timeout_seconds: ?u32 = null,

    pub fn init() EditLobby {
        return .{};
    }

    pub fn withMetadata(self: EditLobby, metadata: []const StringPair) EditLobby {
        var payload = self;
        payload.metadata = metadata;
        payload.clear_metadata = false;
        return payload;
    }

    pub fn clearMetadata(self: EditLobby) EditLobby {
        var payload = self;
        payload.metadata = null;
        payload.clear_metadata = true;
        return payload;
    }

    pub fn withMembers(self: EditLobby, members: []const LobbyMember) EditLobby {
        var payload = self;
        payload.members = members;
        return payload;
    }

    pub fn withIdleTimeout(self: EditLobby, idle_timeout_seconds: u32) EditLobby {
        var payload = self;
        payload.idle_timeout_seconds = idle_timeout_seconds;
        return payload;
    }

    pub fn writeJson(self: EditLobby, writer: anytype) !void {
        try writeLobbyPayloadJson(.{
            .metadata = self.metadata,
            .clear_metadata = self.clear_metadata,
            .members = self.members,
            .idle_timeout_seconds = self.idle_timeout_seconds,
        }, writer);
    }
};

pub const UpdateLobbyMember = struct {
    metadata: ?[]const StringPair = null,
    clear_metadata: bool = false,
    flags: ?u32 = null,

    pub fn init() UpdateLobbyMember {
        return .{};
    }

    pub fn withMetadata(self: UpdateLobbyMember, metadata: []const StringPair) UpdateLobbyMember {
        var payload = self;
        payload.metadata = metadata;
        payload.clear_metadata = false;
        return payload;
    }

    pub fn clearMetadata(self: UpdateLobbyMember) UpdateLobbyMember {
        var payload = self;
        payload.metadata = null;
        payload.clear_metadata = true;
        return payload;
    }

    pub fn withFlags(self: UpdateLobbyMember, flags: u32) UpdateLobbyMember {
        var payload = self;
        payload.flags = flags;
        return payload;
    }

    pub fn writeJson(self: UpdateLobbyMember, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeNullableStringPairObjectField(writer, &needs_comma, "metadata", self.metadata, self.clear_metadata);
        if (self.flags) |flags| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"flags\":{d}", .{flags});
        }

        try writer.writeByte('}');
    }
};

pub const BulkUpdateLobbyMembers = struct {
    members: []const LobbyMember,

    pub fn init(members: []const LobbyMember) BulkUpdateLobbyMembers {
        return .{ .members = members };
    }

    pub fn writeJson(self: BulkUpdateLobbyMembers, writer: anytype) !void {
        try writeLobbyMemberArray(self.members, writer);
    }
};

pub const LinkLobbyChannel = struct {
    channel_id: ?Snowflake = null,
    clear_channel_id: bool = false,

    pub fn init(channel_id: Snowflake) LinkLobbyChannel {
        return .{ .channel_id = channel_id };
    }

    pub fn unlink() LinkLobbyChannel {
        return .{ .clear_channel_id = true };
    }

    pub fn writeJson(self: LinkLobbyChannel, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        try writeNullableSnowflakeField(writer, &needs_comma, "channel_id", self.channel_id, self.clear_channel_id);
        try writer.writeByte('}');
    }
};

pub const UpdateLobbyMessageModerationMetadata = struct {
    metadata: []const StringPair,

    pub fn init(metadata: []const StringPair) UpdateLobbyMessageModerationMetadata {
        return .{ .metadata = metadata };
    }

    pub fn writeJson(self: UpdateLobbyMessageModerationMetadata, writer: anytype) !void {
        try writeStringPairObject(self.metadata, writer);
    }
};

pub const CreateChannelInvite = struct {
    max_age: ?u32 = null,
    max_uses: ?u16 = null,
    temporary: ?bool = null,
    unique: ?bool = null,

    pub fn init() CreateChannelInvite {
        return .{};
    }

    pub fn withMaxAge(self: CreateChannelInvite, max_age: u32) CreateChannelInvite {
        var payload = self;
        payload.max_age = max_age;
        return payload;
    }

    pub fn withMaxUses(self: CreateChannelInvite, max_uses: u16) CreateChannelInvite {
        var payload = self;
        payload.max_uses = max_uses;
        return payload;
    }

    pub fn temporaryState(self: CreateChannelInvite, temporary: bool) CreateChannelInvite {
        var payload = self;
        payload.temporary = temporary;
        return payload;
    }

    pub fn uniqueState(self: CreateChannelInvite, unique: bool) CreateChannelInvite {
        var payload = self;
        payload.unique = unique;
        return payload;
    }

    pub fn writeJson(self: CreateChannelInvite, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        if (self.max_age) |max_age| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"max_age\":{d}", .{max_age});
        }
        if (self.max_uses) |max_uses| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"max_uses\":{d}", .{max_uses});
        }
        try writeOptionalBoolField(writer, &needs_comma, "temporary", self.temporary);
        try writeOptionalBoolField(writer, &needs_comma, "unique", self.unique);

        try writer.writeByte('}');
    }
};

pub const Webhook = struct {
    id: Snowflake,
    guild_id: ?Snowflake = null,
    channel_id: ?Snowflake = null,
    name: ?[]const u8 = null,
};

pub const CreateWebhook = struct {
    name: []const u8,
    avatar: ?[]const u8 = null,

    pub fn init(name: []const u8) CreateWebhook {
        return .{ .name = name };
    }

    pub fn withAvatar(self: CreateWebhook, avatar: []const u8) CreateWebhook {
        var webhook = self;
        webhook.avatar = avatar;
        return webhook;
    }

    pub fn writeJson(self: CreateWebhook, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);
        try writeOptionalStringField(writer, &needs_comma, "avatar", self.avatar);

        try writer.writeByte('}');
    }
};

pub const EditWebhook = struct {
    name: ?[]const u8 = null,
    avatar: ?[]const u8 = null,
    channel_id: ?Snowflake = null,

    pub fn init() EditWebhook {
        return .{};
    }

    pub fn withName(self: EditWebhook, name: []const u8) EditWebhook {
        var webhook = self;
        webhook.name = name;
        return webhook;
    }

    pub fn withAvatar(self: EditWebhook, avatar: []const u8) EditWebhook {
        var webhook = self;
        webhook.avatar = avatar;
        return webhook;
    }

    pub fn withChannel(self: EditWebhook, channel_id: Snowflake) EditWebhook {
        var webhook = self;
        webhook.channel_id = channel_id;
        return webhook;
    }

    pub fn writeJson(self: EditWebhook, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "name", self.name);
        try writeOptionalStringField(writer, &needs_comma, "avatar", self.avatar);
        if (self.channel_id) |channel_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"channel_id\":\"{d}\"", .{channel_id.value});
        }

        try writer.writeByte('}');
    }
};

pub const EditWebhookWithToken = struct {
    name: ?[]const u8 = null,
    avatar: ?[]const u8 = null,

    pub fn init() EditWebhookWithToken {
        return .{};
    }

    pub fn withName(self: EditWebhookWithToken, name: []const u8) EditWebhookWithToken {
        var webhook = self;
        webhook.name = name;
        return webhook;
    }

    pub fn withAvatar(self: EditWebhookWithToken, avatar: []const u8) EditWebhookWithToken {
        var webhook = self;
        webhook.avatar = avatar;
        return webhook;
    }

    pub fn writeJson(self: EditWebhookWithToken, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "name", self.name);
        try writeOptionalStringField(writer, &needs_comma, "avatar", self.avatar);

        try writer.writeByte('}');
    }
};

pub const ExecuteWebhook = struct {
    content: []const u8 = "",
    username: ?[]const u8 = null,
    avatar_url: ?[]const u8 = null,
    tts: bool = false,
    flags: ?MessageFlags.Bit = null,
    embeds: []const Embed = &.{},
    allowed_mentions: ?AllowedMentions = null,
    components: []const Interactions.Component = &.{},
    thread_name: ?[]const u8 = null,

    pub fn init(content: []const u8) ExecuteWebhook {
        return .{ .content = content };
    }

    pub fn empty() ExecuteWebhook {
        return .{};
    }

    pub fn withUsername(self: ExecuteWebhook, username: []const u8) ExecuteWebhook {
        var webhook = self;
        webhook.username = username;
        return webhook;
    }

    pub fn withAvatarUrl(self: ExecuteWebhook, avatar_url: []const u8) ExecuteWebhook {
        var webhook = self;
        webhook.avatar_url = avatar_url;
        return webhook;
    }

    pub fn ttsState(self: ExecuteWebhook, tts: bool) ExecuteWebhook {
        var webhook = self;
        webhook.tts = tts;
        return webhook;
    }

    pub fn withFlags(self: ExecuteWebhook, flags: MessageFlags.Bit) ExecuteWebhook {
        var webhook = self;
        webhook.flags = flags;
        return webhook;
    }

    pub fn withEmbeds(self: ExecuteWebhook, embeds: []const Embed) ExecuteWebhook {
        var webhook = self;
        webhook.embeds = embeds;
        return webhook;
    }

    pub fn withAllowedMentions(self: ExecuteWebhook, allowed_mentions: AllowedMentions) ExecuteWebhook {
        var webhook = self;
        webhook.allowed_mentions = allowed_mentions;
        return webhook;
    }

    pub fn withComponents(self: ExecuteWebhook, components: []const Interactions.Component) ExecuteWebhook {
        var webhook = self;
        webhook.components = components;
        return webhook;
    }

    pub fn withThreadName(self: ExecuteWebhook, thread_name: []const u8) ExecuteWebhook {
        var webhook = self;
        webhook.thread_name = thread_name;
        return webhook;
    }

    pub fn writeJson(self: ExecuteWebhook, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeMessagePayloadFields(.{
            .content = if (self.content.len != 0) self.content else null,
            .embeds = self.embeds,
            .allowed_mentions = self.allowed_mentions,
            .components = self.components,
            .flags = self.flags,
        }, writer, &needs_comma);
        try writeOptionalStringField(writer, &needs_comma, "username", self.username);
        try writeOptionalStringField(writer, &needs_comma, "avatar_url", self.avatar_url);
        if (self.tts) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"tts\":true");
        }
        try writeOptionalStringField(writer, &needs_comma, "thread_name", self.thread_name);

        try writer.writeByte('}');
    }
};

pub fn writeExecuteWebhookJsonWithAttachments(
    payload: ExecuteWebhook,
    files: []const UploadFile,
    writer: anytype,
) !void {
    try writeExecuteWebhookJsonWithAttachmentMetadata(payload, files, writer);
}

pub fn writeExecuteWebhookJsonWithAttachmentMetadata(
    payload: ExecuteWebhook,
    files: anytype,
    writer: anytype,
) !void {
    try writer.writeByte('{');
    var needs_comma = false;
    try writeMessagePayloadFields(.{
        .content = if (payload.content.len != 0) payload.content else null,
        .embeds = payload.embeds,
        .allowed_mentions = payload.allowed_mentions,
        .components = payload.components,
        .flags = payload.flags,
    }, writer, &needs_comma);
    try writeOptionalStringField(writer, &needs_comma, "username", payload.username);
    try writeOptionalStringField(writer, &needs_comma, "avatar_url", payload.avatar_url);
    if (payload.tts) {
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"tts\":true");
    }
    try writeOptionalStringField(writer, &needs_comma, "thread_name", payload.thread_name);
    if (files.len != 0) {
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"attachments\":");
        try writeUploadAttachmentArray(files, writer);
    }
    try writer.writeByte('}');
}

pub const ExecuteWebhookQuery = struct {
    wait: bool = false,
    thread_id: ?Snowflake = null,

    pub fn hasQuery(self: ExecuteWebhookQuery) bool {
        return self.wait or self.thread_id != null;
    }

    pub fn writeQuery(self: ExecuteWebhookQuery, writer: anytype) !void {
        var first = true;
        if (self.wait) {
            try writer.writeAll("wait=true");
            first = false;
        }
        if (self.thread_id) |thread_id| {
            if (!first) try writer.writeByte('&');
            try writer.print("thread_id={d}", .{thread_id.value});
        }
    }
};

pub const CreateGuildBan = struct {
    delete_message_seconds: ?u32 = null,

    pub fn init() CreateGuildBan {
        return .{};
    }

    pub fn deleteMessagesFor(self: CreateGuildBan, seconds: u32) CreateGuildBan {
        var payload = self;
        payload.delete_message_seconds = seconds;
        return payload;
    }

    pub fn writeJson(self: CreateGuildBan, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        if (self.delete_message_seconds) |seconds| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"delete_message_seconds\":{d}", .{seconds});
        }
        try writer.writeByte('}');
    }
};

pub const BulkGuildBan = struct {
    user_ids: []const Snowflake,
    delete_message_seconds: ?u32 = null,

    pub fn init(user_ids: []const Snowflake) BulkGuildBan {
        return .{ .user_ids = user_ids };
    }

    pub fn deleteMessagesFor(self: BulkGuildBan, seconds: u32) BulkGuildBan {
        var payload = self;
        payload.delete_message_seconds = seconds;
        return payload;
    }

    pub fn writeJson(self: BulkGuildBan, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"user_ids\":");
        try writeSnowflakeStringArray(self.user_ids, writer);
        if (self.delete_message_seconds) |seconds| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"delete_message_seconds\":{d}", .{seconds});
        }

        try writer.writeByte('}');
    }
};

pub const Message = struct {
    id: Snowflake,
    channel_id: Snowflake,
    guild_id: ?Snowflake = null,
    author: ?User = null,
    member: ?GuildMember = null,
    message_reference: ?MessageReferenceInfo = null,
    referenced_message_id: ?Snowflake = null,
    message_snapshots: []const MessageSnapshot = &.{},
    thread: ?Channel = null,
    call: ?MessageCall = null,
    role_subscription_data: ?RoleSubscriptionData = null,
    shared_client_theme: ?SharedClientTheme = null,
    webhook_id: ?Snowflake = null,
    application_id: ?Snowflake = null,
    application: ?Application = null,
    activity: ?MessageActivity = null,
    interaction_metadata: ?MessageInteractionMetadata = null,
    type: u8 = 0,
    nonce: ?[]const u8 = null,
    content: []const u8 = "",
    timestamp: ?[]const u8 = null,
    edited_timestamp: ?[]const u8 = null,
    tts: bool = false,
    mention_everyone: bool = false,
    pinned: bool = false,
    position: ?i32 = null,
    flags: ?u32 = null,
    mentions: []const User = &.{},
    mention_roles: []const Snowflake = &.{},
    mention_channels: []const Channel = &.{},
    embeds: []const Embed = &.{},
    attachments: []const Attachment = &.{},
    sticker_items: []const MessageStickerItem = &.{},
    stickers: []const Sticker = &.{},
    components: []const Interactions.Component = &.{},
    poll: ?MessagePoll = null,
    reactions: []const MessageReaction = &.{},
};

pub const MessagePin = struct {
    pinned_at: []const u8,
    message: Message,
};

pub const ChannelPins = struct {
    items: []const MessagePin = &.{},
    has_more: bool = false,
};

pub const MessageFlags = struct {
    pub const Bit = u32;

    pub const crossposted: Bit = 1 << 0;
    pub const is_crosspost: Bit = 1 << 1;
    pub const suppress_embeds: Bit = 1 << 2;
    pub const source_message_deleted: Bit = 1 << 3;
    pub const urgent: Bit = 1 << 4;
    pub const has_thread: Bit = 1 << 5;
    pub const ephemeral: Bit = 1 << 6;
    pub const loading: Bit = 1 << 7;
    pub const failed_to_mention_some_roles_in_thread: Bit = 1 << 8;
    pub const suppress_notifications: Bit = 1 << 12;
    pub const is_voice_message: Bit = 1 << 13;
    pub const has_snapshot: Bit = 1 << 14;
    pub const is_components_v2: Bit = 1 << 15;
};

pub const MessageType = enum(u8) {
    default = 0,
    recipient_add = 1,
    recipient_remove = 2,
    call = 3,
    channel_name_change = 4,
    channel_icon_change = 5,
    channel_pinned_message = 6,
    user_join = 7,
    guild_boost = 8,
    guild_boost_tier_1 = 9,
    guild_boost_tier_2 = 10,
    guild_boost_tier_3 = 11,
    channel_follow_add = 12,
    guild_discovery_disqualified = 14,
    guild_discovery_requalified = 15,
    guild_discovery_grace_period_initial_warning = 16,
    guild_discovery_grace_period_final_warning = 17,
    thread_created = 18,
    reply = 19,
    chat_input_command = 20,
    thread_starter_message = 21,
    guild_invite_reminder = 22,
    context_menu_command = 23,
    auto_moderation_action = 24,
    role_subscription_purchase = 25,
    interaction_premium_upsell = 26,
    stage_start = 27,
    stage_end = 28,
    stage_speaker = 29,
    stage_topic = 31,
    guild_application_premium_subscription = 32,
    guild_incident_alert_mode_enabled = 36,
    guild_incident_alert_mode_disabled = 37,
    guild_incident_report_raid = 38,
    guild_incident_report_false_alarm = 39,
    purchase_notification = 44,
    poll_result = 46,
};

pub const GuildMemberFlags = struct {
    pub const Bit = u32;

    pub const did_rejoin: Bit = 1 << 0;
    pub const completed_onboarding: Bit = 1 << 1;
    pub const bypasses_verification: Bit = 1 << 2;
    pub const started_onboarding: Bit = 1 << 3;
    pub const is_guest: Bit = 1 << 4;
    pub const started_home_actions: Bit = 1 << 5;
    pub const completed_home_actions: Bit = 1 << 6;
    pub const automod_quarantined_username: Bit = 1 << 7;
    pub const dm_settings_upsell_acknowledged: Bit = 1 << 9;

    pub fn has(flags: Bit, flag: Bit) bool {
        return (flags & flag) == flag;
    }
};

pub const MessageReferenceInfo = struct {
    type: ?MessageReferenceType = null,
    message_id: ?Snowflake = null,
    channel_id: ?Snowflake = null,
    guild_id: ?Snowflake = null,
};

pub const MessageReferenceType = enum(u8) {
    default = 0,
    forward = 1,
};
