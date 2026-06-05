const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Types = @import("../../models/types.zig");
const Gateway = @import("../../gateway/protocol.zig");
const Interactions = @import("../../interactions/mod.zig");
const Permissions = @import("../../core/permissions.zig");
const Collection = @import("../../core/collection.zig").Collection;

const Root = @import("../cache.zig");
const deinit = Root.deinit;
const copyAttachments = Root.copyAttachments;
const deinitAttachments = Root.deinitAttachments;
const copyMessageSnapshots = Root.copyMessageSnapshots;
const deinitMessageSnapshots = Root.deinitMessageSnapshots;
const copyMessageStickerItems = Root.copyMessageStickerItems;
const deinitMessageStickerItems = Root.deinitMessageStickerItems;
const copyStickers = Root.copyStickers;
const deinitStickers = Root.deinitStickers;
const copyComponents = Root.copyComponents;
const deinitComponents = Root.deinitComponents;
const copyMessagePoll = Root.copyMessagePoll;
const deinitMessagePoll = Root.deinitMessagePoll;
const copyMessageCall = Root.copyMessageCall;
const deinitMessageCall = Root.deinitMessageCall;
const copyRoleSubscriptionData = Root.copyRoleSubscriptionData;
const deinitRoleSubscriptionData = Root.deinitRoleSubscriptionData;
const copySharedClientTheme = Root.copySharedClientTheme;
const deinitSharedClientTheme = Root.deinitSharedClientTheme;
const copyMessageActivity = Root.copyMessageActivity;
const deinitMessageActivity = Root.deinitMessageActivity;
const copyMessageInteractionMetadata = Root.copyMessageInteractionMetadata;
const deinitMessageInteractionMetadata = Root.deinitMessageInteractionMetadata;
const copyGuildMember = Root.copyGuildMember;
const deinitGuildMember = Root.deinitGuildMember;
const copyUsers = Root.copyUsers;
const deinitUsers = Root.deinitUsers;
const copyApplication = Root.copyApplication;
const deinitApplication = Root.deinitApplication;
const copyChannels = Root.copyChannels;
const copyChannel = Root.copyChannel;
const deinitChannels = Root.deinitChannels;
const deinitChannel = Root.deinitChannel;
const copyEmbeds = Root.copyEmbeds;
const deinitEmbeds = Root.deinitEmbeds;
const copyReactions = Root.copyReactions;
const deinitReactions = Root.deinitReactions;

pub const OwnedInvite = struct {
    code: []u8,
    type: ?u8,
    guild_id: ?Snowflake,
    channel_id: ?Snowflake,
    inviter_id: ?Snowflake,
    target_type: ?u8,
    target_user_id: ?Snowflake,
    target_application_id: ?Snowflake,
    approximate_presence_count: ?u32,
    approximate_member_count: ?u32,
    expires_at: ?[]u8,
    uses: ?u32,
    max_uses: ?u32,
    max_age: ?u32,
    temporary: ?bool,
    created_at: ?[]u8,
    guild_scheduled_event_id: ?Snowflake,

    pub fn copy(allocator: std.mem.Allocator, invite: Types.Invite) !OwnedInvite {
        const code = try allocator.dupe(u8, invite.code);
        errdefer allocator.free(code);
        const expires_at = if (invite.expires_at) |value| try allocator.dupe(u8, value) else null;
        errdefer if (expires_at) |value| allocator.free(value);
        const created_at = if (invite.created_at) |value| try allocator.dupe(u8, value) else null;
        return .{
            .code = code,
            .type = invite.type,
            .guild_id = invite.guild_id,
            .channel_id = invite.channel_id,
            .inviter_id = invite.inviter_id,
            .target_type = invite.target_type,
            .target_user_id = invite.target_user_id,
            .target_application_id = invite.target_application_id,
            .approximate_presence_count = invite.approximate_presence_count,
            .approximate_member_count = invite.approximate_member_count,
            .expires_at = expires_at,
            .uses = invite.uses,
            .max_uses = invite.max_uses,
            .max_age = invite.max_age,
            .temporary = invite.temporary,
            .created_at = created_at,
            .guild_scheduled_event_id = invite.guild_scheduled_event_id,
        };
    }

    pub fn deinit(self: OwnedInvite, allocator: std.mem.Allocator) void {
        allocator.free(self.code);
        if (self.expires_at) |value| allocator.free(value);
        if (self.created_at) |value| allocator.free(value);
    }

    pub fn view(self: OwnedInvite) Types.Invite {
        return .{
            .code = self.code,
            .type = self.type,
            .guild_id = self.guild_id,
            .channel_id = self.channel_id,
            .inviter_id = self.inviter_id,
            .target_type = self.target_type,
            .target_user_id = self.target_user_id,
            .target_application_id = self.target_application_id,
            .approximate_presence_count = self.approximate_presence_count,
            .approximate_member_count = self.approximate_member_count,
            .expires_at = self.expires_at,
            .uses = self.uses,
            .max_uses = self.max_uses,
            .max_age = self.max_age,
            .temporary = self.temporary,
            .created_at = self.created_at,
            .guild_scheduled_event_id = self.guild_scheduled_event_id,
        };
    }
};

pub const OwnedPresence = struct {
    guild_id: Snowflake,
    user_id: Snowflake,
    status: []u8,
    activities_count: usize,

    pub fn copy(allocator: std.mem.Allocator, presence: Types.Presence) !OwnedPresence {
        return .{
            .guild_id = presence.guild_id orelse return error.MissingField,
            .user_id = presence.user_id,
            .status = try allocator.dupe(u8, presence.status),
            .activities_count = presence.activities_count,
        };
    }

    pub fn deinit(self: OwnedPresence, allocator: std.mem.Allocator) void {
        allocator.free(self.status);
    }

    pub fn view(self: OwnedPresence) Types.Presence {
        return .{
            .guild_id = self.guild_id,
            .user_id = self.user_id,
            .status = self.status,
            .activities_count = self.activities_count,
        };
    }
};

pub const OwnedVoiceState = struct {
    guild_id: Snowflake,
    channel_id: ?Snowflake,
    user_id: Snowflake,
    session_id: []u8,
    deaf: bool,
    mute: bool,
    self_deaf: bool,
    self_mute: bool,
    self_stream: ?bool,
    self_video: bool,
    suppress: bool,
    request_to_speak_timestamp: ?[]u8,

    pub fn copy(allocator: std.mem.Allocator, voice_state: Types.VoiceState) !OwnedVoiceState {
        const session_id = try allocator.dupe(u8, voice_state.session_id);
        errdefer allocator.free(session_id);
        const request_to_speak_timestamp = if (voice_state.request_to_speak_timestamp) |value| try allocator.dupe(u8, value) else null;
        return .{
            .guild_id = voice_state.guild_id orelse return error.MissingField,
            .channel_id = voice_state.channel_id,
            .user_id = voice_state.user_id,
            .session_id = session_id,
            .deaf = voice_state.deaf,
            .mute = voice_state.mute,
            .self_deaf = voice_state.self_deaf,
            .self_mute = voice_state.self_mute,
            .self_stream = voice_state.self_stream,
            .self_video = voice_state.self_video,
            .suppress = voice_state.suppress,
            .request_to_speak_timestamp = request_to_speak_timestamp,
        };
    }

    pub fn deinit(self: OwnedVoiceState, allocator: std.mem.Allocator) void {
        allocator.free(self.session_id);
        if (self.request_to_speak_timestamp) |value| allocator.free(value);
    }

    pub fn view(self: OwnedVoiceState, member: ?Types.GuildMember) Types.VoiceState {
        return .{
            .guild_id = self.guild_id,
            .channel_id = self.channel_id,
            .user_id = self.user_id,
            .member = member,
            .session_id = self.session_id,
            .deaf = self.deaf,
            .mute = self.mute,
            .self_deaf = self.self_deaf,
            .self_mute = self.self_mute,
            .self_stream = self.self_stream,
            .self_video = self.self_video,
            .suppress = self.suppress,
            .request_to_speak_timestamp = self.request_to_speak_timestamp,
        };
    }
};

pub const OwnedMessage = struct {
    id: Snowflake,
    channel_id: Snowflake,
    guild_id: ?Snowflake,
    author_id: Snowflake,
    member: ?Types.GuildMember,
    message_reference: ?Types.MessageReferenceInfo,
    referenced_message_id: ?Snowflake,
    message_snapshots: []Types.MessageSnapshot,
    thread: ?Types.Channel,
    call: ?Types.MessageCall,
    role_subscription_data: ?Types.RoleSubscriptionData,
    shared_client_theme: ?Types.SharedClientTheme,
    webhook_id: ?Snowflake,
    application_id: ?Snowflake,
    application: ?Types.Application,
    activity: ?Types.MessageActivity,
    interaction_metadata: ?Types.MessageInteractionMetadata,
    type: u8,
    nonce: ?[]u8,
    content: []u8,
    timestamp: ?[]u8,
    edited_timestamp: ?[]u8,
    tts: bool,
    mention_everyone: bool,
    pinned: bool,
    position: ?i32,
    flags: ?u32,
    mentions: []Types.User,
    mention_roles: []Snowflake,
    mention_channels: []Types.Channel,
    embeds: []Types.Embed,
    attachments: []Types.Attachment,
    sticker_items: []Types.MessageStickerItem,
    stickers: []Types.Sticker,
    components: []Interactions.Component,
    poll: ?Types.MessagePoll,
    reactions: []Types.MessageReaction,

    pub fn copy(allocator: std.mem.Allocator, message: Types.Message) !OwnedMessage {
        const author = message.author orelse return error.MissingAuthor;
        const content = try allocator.dupe(u8, message.content);
        errdefer allocator.free(content);
        const member = if (message.member) |value| try copyGuildMember(allocator, value) else null;
        errdefer if (member) |value| deinitGuildMember(value, allocator);
        const thread = if (message.thread) |value| try copyChannel(allocator, value) else null;
        errdefer if (thread) |value| deinitChannel(value, allocator);
        const call = if (message.call) |value| try copyMessageCall(allocator, value) else null;
        errdefer if (call) |value| deinitMessageCall(value, allocator);
        const role_subscription_data = if (message.role_subscription_data) |value| try copyRoleSubscriptionData(allocator, value) else null;
        errdefer if (role_subscription_data) |value| deinitRoleSubscriptionData(value, allocator);
        const shared_client_theme = if (message.shared_client_theme) |value| try copySharedClientTheme(allocator, value) else null;
        errdefer if (shared_client_theme) |value| deinitSharedClientTheme(value, allocator);
        const nonce = if (message.nonce) |value| try allocator.dupe(u8, value) else null;
        errdefer if (nonce) |value| allocator.free(value);
        const application = if (message.application) |value| try copyApplication(allocator, value) else null;
        errdefer if (application) |value| deinitApplication(value, allocator);
        const activity = if (message.activity) |value| try copyMessageActivity(allocator, value) else null;
        errdefer if (activity) |value| deinitMessageActivity(value, allocator);
        const interaction_metadata = if (message.interaction_metadata) |value| try copyMessageInteractionMetadata(allocator, value) else null;
        errdefer if (interaction_metadata) |value| deinitMessageInteractionMetadata(value, allocator);
        const timestamp = if (message.timestamp) |value| try allocator.dupe(u8, value) else null;
        errdefer if (timestamp) |value| allocator.free(value);
        const edited_timestamp = if (message.edited_timestamp) |value| try allocator.dupe(u8, value) else null;
        errdefer if (edited_timestamp) |value| allocator.free(value);
        const message_snapshots = try copyMessageSnapshots(allocator, message.message_snapshots);
        errdefer deinitMessageSnapshots(message_snapshots, allocator);
        const attachments = try copyAttachments(allocator, message.attachments);
        errdefer deinitAttachments(attachments, allocator);
        const reactions = try copyReactions(allocator, message.reactions);
        errdefer deinitReactions(reactions, allocator);
        const embeds = try copyEmbeds(allocator, message.embeds);
        errdefer deinitEmbeds(embeds, allocator);
        const mentions = try copyUsers(allocator, message.mentions);
        errdefer deinitUsers(mentions, allocator);
        const mention_roles = try allocator.dupe(Snowflake, message.mention_roles);
        errdefer allocator.free(mention_roles);
        const mention_channels = try copyChannels(allocator, message.mention_channels);
        errdefer deinitChannels(mention_channels, allocator);
        const sticker_items = try copyMessageStickerItems(allocator, message.sticker_items);
        errdefer deinitMessageStickerItems(sticker_items, allocator);
        const stickers = try copyStickers(allocator, message.stickers);
        errdefer deinitStickers(stickers, allocator);
        const components = try copyComponents(allocator, message.components);
        errdefer deinitComponents(components, allocator);
        const poll = if (message.poll) |value| try copyMessagePoll(allocator, value) else null;
        errdefer if (poll) |value| deinitMessagePoll(value, allocator);
        return .{
            .id = message.id,
            .channel_id = message.channel_id,
            .guild_id = message.guild_id,
            .author_id = author.id,
            .member = member,
            .message_reference = message.message_reference,
            .referenced_message_id = message.referenced_message_id,
            .message_snapshots = message_snapshots,
            .thread = thread,
            .call = call,
            .role_subscription_data = role_subscription_data,
            .shared_client_theme = shared_client_theme,
            .webhook_id = message.webhook_id,
            .application_id = message.application_id,
            .application = application,
            .activity = activity,
            .interaction_metadata = interaction_metadata,
            .type = message.type,
            .nonce = nonce,
            .content = content,
            .timestamp = timestamp,
            .edited_timestamp = edited_timestamp,
            .tts = message.tts,
            .mention_everyone = message.mention_everyone,
            .pinned = message.pinned,
            .position = message.position,
            .flags = message.flags,
            .mentions = mentions,
            .mention_roles = mention_roles,
            .mention_channels = mention_channels,
            .embeds = embeds,
            .attachments = attachments,
            .sticker_items = sticker_items,
            .stickers = stickers,
            .components = components,
            .poll = poll,
            .reactions = reactions,
        };
    }

    pub fn deinit(self: OwnedMessage, allocator: std.mem.Allocator) void {
        allocator.free(self.content);
        if (self.nonce) |value| allocator.free(value);
        if (self.application) |value| deinitApplication(value, allocator);
        if (self.activity) |value| deinitMessageActivity(value, allocator);
        if (self.interaction_metadata) |value| deinitMessageInteractionMetadata(value, allocator);
        if (self.member) |value| deinitGuildMember(value, allocator);
        if (self.thread) |value| deinitChannel(value, allocator);
        if (self.call) |value| deinitMessageCall(value, allocator);
        if (self.role_subscription_data) |value| deinitRoleSubscriptionData(value, allocator);
        if (self.shared_client_theme) |value| deinitSharedClientTheme(value, allocator);
        if (self.timestamp) |value| allocator.free(value);
        if (self.edited_timestamp) |value| allocator.free(value);
        deinitMessageSnapshots(self.message_snapshots, allocator);
        deinitUsers(self.mentions, allocator);
        allocator.free(self.mention_roles);
        deinitChannels(self.mention_channels, allocator);
        deinitEmbeds(self.embeds, allocator);
        deinitAttachments(self.attachments, allocator);
        deinitMessageStickerItems(self.sticker_items, allocator);
        deinitStickers(self.stickers, allocator);
        deinitComponents(self.components, allocator);
        if (self.poll) |value| deinitMessagePoll(value, allocator);
        deinitReactions(self.reactions, allocator);
    }

    pub fn view(self: OwnedMessage, author: ?Types.User) Types.Message {
        return .{
            .id = self.id,
            .channel_id = self.channel_id,
            .guild_id = self.guild_id,
            .author = author,
            .member = self.member,
            .message_reference = self.message_reference,
            .referenced_message_id = self.referenced_message_id,
            .message_snapshots = self.message_snapshots,
            .thread = self.thread,
            .call = self.call,
            .role_subscription_data = self.role_subscription_data,
            .shared_client_theme = self.shared_client_theme,
            .webhook_id = self.webhook_id,
            .application_id = self.application_id,
            .application = self.application,
            .activity = self.activity,
            .interaction_metadata = self.interaction_metadata,
            .type = self.type,
            .nonce = self.nonce,
            .content = self.content,
            .timestamp = self.timestamp,
            .edited_timestamp = self.edited_timestamp,
            .tts = self.tts,
            .mention_everyone = self.mention_everyone,
            .pinned = self.pinned,
            .position = self.position,
            .flags = self.flags,
            .mentions = self.mentions,
            .mention_roles = self.mention_roles,
            .mention_channels = self.mention_channels,
            .embeds = self.embeds,
            .attachments = self.attachments,
            .sticker_items = self.sticker_items,
            .stickers = self.stickers,
            .components = self.components,
            .poll = self.poll,
            .reactions = self.reactions,
        };
    }
};
