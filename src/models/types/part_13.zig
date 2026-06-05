const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Json = @import("../../core/json.zig");
const Interactions = @import("../../interactions/mod.zig");
const Permissions = @import("../../core/permissions.zig");

const Root = @import("../types.zig");
const User = Root.User;
const StringPair = Root.StringPair;
const ApplicationRoleConnectionMetadataType = Root.ApplicationRoleConnectionMetadataType;
const ApplicationRoleConnectionMetadata = Root.ApplicationRoleConnectionMetadata;
const UpdateApplicationRoleConnectionMetadataRecords = Root.UpdateApplicationRoleConnectionMetadataRecords;
const Presence = Root.Presence;
const Guild = Root.Guild;
const EditGuild = Root.EditGuild;
const GuildTemplate = Root.GuildTemplate;
const GuildWidgetSettings = Root.GuildWidgetSettings;
const GuildWidget = Root.GuildWidget;
const GuildWidgetImageStyle = Root.GuildWidgetImageStyle;
const GetGuildWidgetImage = Root.GetGuildWidgetImage;
const IncidentsData = Root.IncidentsData;
const EditGuildIncidentActions = Root.EditGuildIncidentActions;
const OnboardingMode = Root.OnboardingMode;
const OnboardingPromptType = Root.OnboardingPromptType;
const OnboardingPromptOption = Root.OnboardingPromptOption;
const OnboardingPrompt = Root.OnboardingPrompt;
const EditGuildOnboarding = Root.EditGuildOnboarding;
const WelcomeScreen = Root.WelcomeScreen;
const WelcomeScreenChannel = Root.WelcomeScreenChannel;
const PartialInvite = Root.PartialInvite;
const ApplicationEventWebhookStatus = Root.ApplicationEventWebhookStatus;
const ApplicationEventWebhookType = Root.ApplicationEventWebhookType;
const ApplicationEventWebhookPayloadType = Root.ApplicationEventWebhookPayloadType;
const ApplicationEventWebhookPayload = Root.ApplicationEventWebhookPayload;
const ApplicationEventWebhookBody = Root.ApplicationEventWebhookBody;
const Application = Root.Application;
const MembershipState = Root.MembershipState;
const TeamMember = Root.TeamMember;
const Team = Root.Team;
const SkuType = Root.SkuType;
const SkuFlags = Root.SkuFlags;
const UserFlags = Root.UserFlags;
const ApplicationFlags = Root.ApplicationFlags;
const Sku = Root.Sku;
const EntitlementType = Root.EntitlementType;
const Entitlement = Root.Entitlement;
const SubscriptionStatus = Root.SubscriptionStatus;
const Subscription = Root.Subscription;
const ListEntitlements = Root.ListEntitlements;
const EntitlementOwnerType = Root.EntitlementOwnerType;
const CreateTestEntitlement = Root.CreateTestEntitlement;
const ListSkuSubscriptions = Root.ListSkuSubscriptions;
const ApplicationInstallParams = Root.ApplicationInstallParams;
const GuildScheduledEventPrivacyLevel = Root.GuildScheduledEventPrivacyLevel;
const GuildScheduledEventEntityType = Root.GuildScheduledEventEntityType;
const GuildScheduledEventStatus = Root.GuildScheduledEventStatus;
const StageInstancePrivacyLevel = Root.StageInstancePrivacyLevel;
const GuildScheduledEvent = Root.GuildScheduledEvent;
const StageInstance = Root.StageInstance;
const VoiceState = Root.VoiceState;
const VoiceRegion = Root.VoiceRegion;
const GuildScheduledEventEntityMetadata = Root.GuildScheduledEventEntityMetadata;
const GuildScheduledEventUser = Root.GuildScheduledEventUser;
const ListGuildScheduledEvents = Root.ListGuildScheduledEvents;
const GetGuildScheduledEvent = Root.GetGuildScheduledEvent;
const ListGuildScheduledEventUsers = Root.ListGuildScheduledEventUsers;
const UserGuild = Root.UserGuild;
const AuditLog = Root.AuditLog;
const AuditLogEntry = Root.AuditLogEntry;
const GuildMember = Root.GuildMember;
const CachedGuildMember = Root.CachedGuildMember;
const Ban = Root.Ban;
const AutoModerationRuleEventType = Root.AutoModerationRuleEventType;
const AutoModerationTriggerType = Root.AutoModerationTriggerType;
const AutoModerationKeywordPresetType = Root.AutoModerationKeywordPresetType;
const AutoModerationActionType = Root.AutoModerationActionType;
const AutoModerationRule = Root.AutoModerationRule;
const AutoModerationTriggerMetadata = Root.AutoModerationTriggerMetadata;
const AutoModerationActionMetadata = Root.AutoModerationActionMetadata;
const AutoModerationAction = Root.AutoModerationAction;
const CreateAutoModerationRule = Root.CreateAutoModerationRule;
const EditAutoModerationRule = Root.EditAutoModerationRule;
const Role = Root.Role;
const RoleColors = Root.RoleColors;
const RoleTags = Root.RoleTags;
const Emoji = Root.Emoji;
const StickerType = Root.StickerType;
const StickerFormatType = Root.StickerFormatType;
const Sticker = Root.Sticker;
const MessageStickerItem = Root.MessageStickerItem;
const SoundboardSound = Root.SoundboardSound;
const Channel = Root.Channel;
const ThreadMetadata = Root.ThreadMetadata;
const ForumTag = Root.ForumTag;
const DefaultReactionEmoji = Root.DefaultReactionEmoji;
const ChannelFlags = Root.ChannelFlags;
const ChannelSortOrder = Root.ChannelSortOrder;
const ForumLayout = Root.ForumLayout;
const WriteForumTag = Root.WriteForumTag;
const PermissionOverwriteType = Root.PermissionOverwriteType;
const PermissionOverwrite = Root.PermissionOverwrite;
const ChannelType = Root.ChannelType;
const CreateGuildChannel = Root.CreateGuildChannel;
const CreateGuild = Root.CreateGuild;
const CreateGuildFromTemplate = Root.CreateGuildFromTemplate;
const CreateGuildTemplate = Root.CreateGuildTemplate;
const EditGuildTemplate = Root.EditGuildTemplate;
const EditGuildWidgetSettings = Root.EditGuildWidgetSettings;
const EditWelcomeScreen = Root.EditWelcomeScreen;
const CreateGuildScheduledEvent = Root.CreateGuildScheduledEvent;
const EditGuildScheduledEvent = Root.EditGuildScheduledEvent;
const CreateStageInstance = Root.CreateStageInstance;
const EditStageInstance = Root.EditStageInstance;
const EditCurrentUserVoiceState = Root.EditCurrentUserVoiceState;
const EditUserVoiceState = Root.EditUserVoiceState;
const EditCurrentApplication = Root.EditCurrentApplication;
const OAuth2TokenRequest = Root.OAuth2TokenRequest;
const OAuth2TokenRevocation = Root.OAuth2TokenRevocation;
const AuditLogEvent = Root.AuditLogEvent;
const ListAuditLog = Root.ListAuditLog;
const ListCurrentUserGuilds = Root.ListCurrentUserGuilds;
const GetGuild = Root.GetGuild;
const ListGuildBans = Root.ListGuildBans;
const ListGuildMembers = Root.ListGuildMembers;
const GetGuildPruneCount = Root.GetGuildPruneCount;
const BeginGuildPrune = Root.BeginGuildPrune;
const SearchGuildMembers = Root.SearchGuildMembers;
const EditChannel = Root.EditChannel;
const GuildChannelPosition = Root.GuildChannelPosition;
const EditChannelPermission = Root.EditChannelPermission;
const SetVoiceChannelStatus = Root.SetVoiceChannelStatus;
const FollowAnnouncementChannel = Root.FollowAnnouncementChannel;
const CreateGuildRole = Root.CreateGuildRole;
const EditGuildRole = Root.EditGuildRole;
const GuildRolePosition = Root.GuildRolePosition;
const CreateGuildEmoji = Root.CreateGuildEmoji;
const EditGuildEmoji = Root.EditGuildEmoji;
const CreateApplicationEmoji = Root.CreateApplicationEmoji;
const EditApplicationEmoji = Root.EditApplicationEmoji;
const CreateGuildSticker = Root.CreateGuildSticker;
const EditGuildSticker = Root.EditGuildSticker;
const SendSoundboardSound = Root.SendSoundboardSound;
const CreateGuildSoundboardSound = Root.CreateGuildSoundboardSound;
const EditGuildSoundboardSound = Root.EditGuildSoundboardSound;
const EditGuildMember = Root.EditGuildMember;
const AddGuildMember = Root.AddGuildMember;
const EditCurrentGuildMember = Root.EditCurrentGuildMember;
const EditCurrentUserNick = Root.EditCurrentUserNick;
const EditCurrentUser = Root.EditCurrentUser;
const UpdateApplicationRoleConnection = Root.UpdateApplicationRoleConnection;
const CreateDmChannel = Root.CreateDmChannel;
const AddGroupDmRecipient = Root.AddGroupDmRecipient;
const CreateThreadFromMessage = Root.CreateThreadFromMessage;
const CreateThread = Root.CreateThread;
const ForumThreadMessage = Root.ForumThreadMessage;
const CreateForumThread = Root.CreateForumThread;
const Invite = Root.Invite;
const GetInvite = Root.GetInvite;
const LobbyMember = Root.LobbyMember;
const CreateLobby = Root.CreateLobby;
const EditLobby = Root.EditLobby;
const UpdateLobbyMember = Root.UpdateLobbyMember;
const BulkUpdateLobbyMembers = Root.BulkUpdateLobbyMembers;
const LinkLobbyChannel = Root.LinkLobbyChannel;
const UpdateLobbyMessageModerationMetadata = Root.UpdateLobbyMessageModerationMetadata;
const CreateChannelInvite = Root.CreateChannelInvite;
const Webhook = Root.Webhook;
const CreateWebhook = Root.CreateWebhook;
const EditWebhook = Root.EditWebhook;
const EditWebhookWithToken = Root.EditWebhookWithToken;
const ExecuteWebhook = Root.ExecuteWebhook;
const writeExecuteWebhookJsonWithAttachments = Root.writeExecuteWebhookJsonWithAttachments;
const writeExecuteWebhookJsonWithAttachmentMetadata = Root.writeExecuteWebhookJsonWithAttachmentMetadata;
const ExecuteWebhookQuery = Root.ExecuteWebhookQuery;
const CreateGuildBan = Root.CreateGuildBan;
const BulkGuildBan = Root.BulkGuildBan;
const Message = Root.Message;
const MessagePin = Root.MessagePin;
const ChannelPins = Root.ChannelPins;
const MessageFlags = Root.MessageFlags;
const MessageType = Root.MessageType;
const GuildMemberFlags = Root.GuildMemberFlags;
const MessageReferenceInfo = Root.MessageReferenceInfo;
const MessageReferenceType = Root.MessageReferenceType;
const MessageSnapshot = Root.MessageSnapshot;
const MessageCall = Root.MessageCall;
const RoleSubscriptionData = Root.RoleSubscriptionData;
const SharedClientThemeBase = Root.SharedClientThemeBase;
const SharedClientTheme = Root.SharedClientTheme;
const MessageActivityType = Root.MessageActivityType;
const MessageActivity = Root.MessageActivity;
const MessageInteractionMetadata = Root.MessageInteractionMetadata;
const Attachment = Root.Attachment;
const ReactionEmoji = Root.ReactionEmoji;
const ReactionCountDetails = Root.ReactionCountDetails;
const ReactionType = Root.ReactionType;
const MessageReaction = Root.MessageReaction;
const MessagePollMedia = Root.MessagePollMedia;
const MessagePollAnswer = Root.MessagePollAnswer;
const MessagePollAnswerCount = Root.MessagePollAnswerCount;
const MessagePollResults = Root.MessagePollResults;
const MessagePoll = Root.MessagePoll;
const EmbedMedia = Root.EmbedMedia;
const EmbedFooter = Root.EmbedFooter;
const EmbedAuthor = Root.EmbedAuthor;
const EmbedField = Root.EmbedField;
const Colors = Root.Colors;
const Embed = Root.Embed;
const AllowedMentionType = Root.AllowedMentionType;
const AllowedMentions = Root.AllowedMentions;
const PollLayoutType = Root.PollLayoutType;
const PollEmoji = Root.PollEmoji;
const PollMedia = Root.PollMedia;
const PollAnswer = Root.PollAnswer;
const CreatePoll = Root.CreatePoll;
const max_message_content_len = Root.max_message_content_len;
const max_message_nonce_len = Root.max_message_nonce_len;
const max_message_embeds = Root.max_message_embeds;
const max_message_stickers = Root.max_message_stickers;
const MessageValidationError = Root.MessageValidationError;
const validateMessagePayload = Root.validateMessagePayload;
const CreateMessage = Root.CreateMessage;
const ListMessages = Root.ListMessages;
const ListReactions = Root.ListReactions;
const ListPollAnswerVoters = Root.ListPollAnswerVoters;
const ListArchivedThreads = Root.ListArchivedThreads;
const ListThreadMembers = Root.ListThreadMembers;
const ListChannelPins = Root.ListChannelPins;
const EditMessage = Root.EditMessage;
const writeSnowflakeCommaList = Root.writeSnowflakeCommaList;
const writeOptionalStringField = Root.writeOptionalStringField;
const writeNullableStringField = Root.writeNullableStringField;
const writeNullableSnowflakeField = Root.writeNullableSnowflakeField;
const writeOptionalIntegerField = Root.writeOptionalIntegerField;
const writeOptionalFloatField = Root.writeOptionalFloatField;
const writeOptionalBoolField = Root.writeOptionalBoolField;
const writeSnowflakeQueryParam = Root.writeSnowflakeQueryParam;
const writeStringQueryParam = Root.writeStringQueryParam;
const writeOptionalStringQueryParam = Root.writeOptionalStringQueryParam;
const writeOptionalBoolQueryParam = Root.writeOptionalBoolQueryParam;
const writeQueryStringValue = Root.writeQueryStringValue;
const writeQuerySeparator = Root.writeQuerySeparator;
const writeComma = Root.writeComma;

pub const BulkDeleteMessages = struct {
    messages: []const Snowflake,

    pub fn writeJson(self: BulkDeleteMessages, writer: anytype) !void {
        try writer.writeAll("{\"messages\":");
        try writeSnowflakeStringArray(self.messages, writer);
        try writer.writeByte('}');
    }
};

pub const MessageReference = struct {
    type: ?MessageReferenceType = null,
    message_id: Snowflake,
    channel_id: ?Snowflake = null,
    guild_id: ?Snowflake = null,
    fail_if_not_exists: bool = true,

    pub fn writeJson(self: MessageReference, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        if (self.type) |reference_type| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"type\":{d}", .{@intFromEnum(reference_type)});
        }
        try writeComma(writer, &needs_comma);
        try writer.print("\"message_id\":\"{d}\"", .{self.message_id.value});
        if (self.channel_id) |channel_id| try writer.print(",\"channel_id\":\"{d}\"", .{channel_id.value});
        if (self.guild_id) |guild_id| try writer.print(",\"guild_id\":\"{d}\"", .{guild_id.value});
        if (!self.fail_if_not_exists) try writer.writeAll(",\"fail_if_not_exists\":false");
        try writer.writeByte('}');
    }

    pub fn reply(message_id: Snowflake) MessageReference {
        return .{ .type = .default, .message_id = message_id };
    }

    pub fn forward(message_id: Snowflake, channel_id: Snowflake) MessageReference {
        return .{ .type = .forward, .message_id = message_id, .channel_id = channel_id };
    }
};

pub const UploadFile = struct {
    filename: []const u8,
    content: []const u8,
    content_type: []const u8 = "application/octet-stream",
    description: ?[]const u8 = null,

    pub fn init(filename: []const u8, content: []const u8) UploadFile {
        return .{ .filename = filename, .content = content };
    }

    pub fn withContentType(self: UploadFile, content_type: []const u8) UploadFile {
        var file = self;
        file.content_type = content_type;
        return file;
    }

    pub fn withDescription(self: UploadFile, description: []const u8) UploadFile {
        var file = self;
        file.description = description;
        return file;
    }
};

pub const UploadFilePath = struct {
    filename: []const u8,
    path: []const u8,
    content_type: []const u8 = "application/octet-stream",
    description: ?[]const u8 = null,

    pub fn init(filename: []const u8, path: []const u8) UploadFilePath {
        return .{ .filename = filename, .path = path };
    }

    pub fn withContentType(self: UploadFilePath, content_type: []const u8) UploadFilePath {
        var file = self;
        file.content_type = content_type;
        return file;
    }

    pub fn withDescription(self: UploadFilePath, description: []const u8) UploadFilePath {
        var file = self;
        file.description = description;
        return file;
    }
};

pub const EmbedBuilder = Embed;

pub const AttachmentBuilder = UploadFile;

pub const AttachmentPathBuilder = UploadFilePath;

pub const AllowedMentionsBuilder = AllowedMentions;

pub const PollBuilder = CreatePoll;

pub fn writeCreateMessageJsonWithAttachments(
    payload: CreateMessage,
    files: []const UploadFile,
    writer: anytype,
) !void {
    try writeCreateMessageJsonWithAttachmentMetadata(payload, files, writer);
}

pub fn writeCreateMessageJsonWithAttachmentMetadata(
    payload: CreateMessage,
    files: anytype,
    writer: anytype,
) !void {
    try writer.writeByte('{');
    var needs_comma = false;
    if (payload.content.len != 0) {
        try writeMessagePayloadFields(.{
            .content = payload.content,
            .embeds = payload.embeds,
            .sticker_ids = payload.sticker_ids,
            .allowed_mentions = payload.allowed_mentions,
            .components = payload.components,
            .poll = payload.poll,
            .flags = payload.flags,
            .shared_client_theme = payload.shared_client_theme,
        }, writer, &needs_comma);
    }
    if (payload.nonce) |nonce| {
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"nonce\":");
        try Json.writeString(nonce, writer);
    }
    if (payload.enforce_nonce) {
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"enforce_nonce\":true");
    }
    if (payload.tts) {
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"tts\":true");
    }
    if (payload.content.len == 0) {
        try writeMessagePayloadFields(.{
            .content = null,
            .embeds = payload.embeds,
            .sticker_ids = payload.sticker_ids,
            .allowed_mentions = payload.allowed_mentions,
            .components = payload.components,
            .poll = payload.poll,
            .flags = payload.flags,
            .shared_client_theme = payload.shared_client_theme,
        }, writer, &needs_comma);
    }
    if (files.len != 0) {
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"attachments\":");
        try writeUploadAttachmentArray(files, writer);
    }
    try writer.writeByte('}');
}

const MessagePayloadFields = struct {
    content: ?[]const u8 = null,
    embeds: []const Embed = &.{},
    sticker_ids: []const Snowflake = &.{},
    allowed_mentions: ?AllowedMentions = null,
    components: []const Interactions.Component = &.{},
    poll: ?CreatePoll = null,
    flags: ?MessageFlags.Bit = null,
    shared_client_theme: ?SharedClientTheme = null,
};

const ChannelFields = struct {
    type: ?ChannelType = null,
    topic: ?[]const u8 = null,
    nsfw: bool = false,
    rate_limit_per_user: ?u16 = null,
    bitrate: ?u32 = null,
    user_limit: ?u16 = null,
    flags: ?ChannelFlags.Bit = null,
    parent_id: ?Snowflake = null,
    position: ?i32 = null,
    available_tags: ?[]const WriteForumTag = null,
    default_reaction_emoji: ?DefaultReactionEmoji = null,
    default_thread_rate_limit_per_user: ?u16 = null,
    default_sort_order: ?ChannelSortOrder = null,
    default_forum_layout: ?ForumLayout = null,
};

const RoleFields = struct {
    permissions: ?Permissions.Bit = null,
    color: ?u24 = null,
    colors: ?RoleColors = null,
    hoist: ?bool = null,
    icon: ?[]const u8 = null,
    clear_icon: bool = false,
    unicode_emoji: ?[]const u8 = null,
    clear_unicode_emoji: bool = false,
    mentionable: ?bool = null,
};

const ThreadFields = struct {
    auto_archive_duration: ?u16 = null,
    rate_limit_per_user: ?u16 = null,
    invitable: ?bool = null,
};

const ThreadEditFields = struct {
    archived: ?bool = null,
    auto_archive_duration: ?u16 = null,
    locked: ?bool = null,
    invitable: ?bool = null,
    applied_tags: ?[]const Snowflake = null,
};

pub fn writeRoleFields(fields: RoleFields, writer: anytype, needs_comma: *bool) !void {
    if (fields.permissions) |permissions| {
        try writeComma(writer, needs_comma);
        try writer.print("\"permissions\":\"{d}\"", .{permissions});
    }
    if (fields.color) |color| {
        try writeComma(writer, needs_comma);
        try writer.print("\"color\":{d}", .{color});
    }
    if (fields.colors) |colors| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"colors\":");
        try colors.writeJson(writer);
    }
    if (fields.hoist) |hoist| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"hoist\":");
        try writer.writeAll(if (hoist) "true" else "false");
    }
    try writeNullableStringField(writer, needs_comma, "icon", fields.icon, fields.clear_icon);
    try writeNullableStringField(
        writer,
        needs_comma,
        "unicode_emoji",
        fields.unicode_emoji,
        fields.clear_unicode_emoji,
    );
    if (fields.mentionable) |mentionable| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"mentionable\":");
        try writer.writeAll(if (mentionable) "true" else "false");
    }
}

pub fn writeThreadFields(fields: ThreadFields, writer: anytype, needs_comma: *bool) !void {
    if (fields.auto_archive_duration) |duration| {
        try writeComma(writer, needs_comma);
        try writer.print("\"auto_archive_duration\":{d}", .{duration});
    }
    if (fields.rate_limit_per_user) |rate_limit_per_user| {
        try writeComma(writer, needs_comma);
        try writer.print("\"rate_limit_per_user\":{d}", .{rate_limit_per_user});
    }
    try writeOptionalBoolField(writer, needs_comma, "invitable", fields.invitable);
}

pub fn writeThreadEditFields(fields: ThreadEditFields, writer: anytype, needs_comma: *bool) !void {
    try writeOptionalBoolField(writer, needs_comma, "archived", fields.archived);
    if (fields.auto_archive_duration) |duration| {
        try writeComma(writer, needs_comma);
        try writer.print("\"auto_archive_duration\":{d}", .{duration});
    }
    try writeOptionalBoolField(writer, needs_comma, "locked", fields.locked);
    try writeOptionalBoolField(writer, needs_comma, "invitable", fields.invitable);
    if (fields.applied_tags) |applied_tags| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"applied_tags\":");
        try writeSnowflakeStringArray(applied_tags, writer);
    }
}

pub fn writeChannelFields(fields: ChannelFields, writer: anytype, needs_comma: *bool) !void {
    if (fields.type) |channel_type| {
        try writeComma(writer, needs_comma);
        try writer.print("\"type\":{d}", .{@intFromEnum(channel_type)});
    }
    try writeOptionalStringField(writer, needs_comma, "topic", fields.topic);
    if (fields.nsfw) {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"nsfw\":true");
    }
    if (fields.rate_limit_per_user) |rate_limit_per_user| {
        try writeComma(writer, needs_comma);
        try writer.print("\"rate_limit_per_user\":{d}", .{rate_limit_per_user});
    }
    if (fields.bitrate) |bitrate| {
        try writeComma(writer, needs_comma);
        try writer.print("\"bitrate\":{d}", .{bitrate});
    }
    if (fields.user_limit) |user_limit| {
        try writeComma(writer, needs_comma);
        try writer.print("\"user_limit\":{d}", .{user_limit});
    }
    if (fields.flags) |flags| {
        try writeComma(writer, needs_comma);
        try writer.print("\"flags\":{d}", .{flags});
    }
    if (fields.parent_id) |parent_id| {
        try writeComma(writer, needs_comma);
        try writer.print("\"parent_id\":\"{d}\"", .{parent_id.value});
    }
    if (fields.position) |position| {
        try writeComma(writer, needs_comma);
        try writer.print("\"position\":{d}", .{position});
    }
    if (fields.available_tags) |available_tags| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"available_tags\":");
        try writeForumTagArray(available_tags, writer);
    }
    if (fields.default_reaction_emoji) |default_reaction_emoji| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"default_reaction_emoji\":");
        try default_reaction_emoji.writeJson(writer);
    }
    if (fields.default_thread_rate_limit_per_user) |rate_limit| {
        try writeComma(writer, needs_comma);
        try writer.print("\"default_thread_rate_limit_per_user\":{d}", .{rate_limit});
    }
    if (fields.default_sort_order) |sort_order| {
        try writeComma(writer, needs_comma);
        try writer.print("\"default_sort_order\":{d}", .{@intFromEnum(sort_order)});
    }
    if (fields.default_forum_layout) |layout| {
        try writeComma(writer, needs_comma);
        try writer.print("\"default_forum_layout\":{d}", .{@intFromEnum(layout)});
    }
}

pub fn writeForumTagArray(tags: []const WriteForumTag, writer: anytype) !void {
    try writer.writeByte('[');
    for (tags, 0..) |tag, index| {
        if (index != 0) try writer.writeByte(',');
        try tag.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn writeMessagePayloadFields(fields: MessagePayloadFields, writer: anytype, needs_comma: *bool) !void {
    if (fields.content) |content| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"content\":");
        try Json.writeString(content, writer);
    }
    if (fields.embeds.len != 0) {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"embeds\":");
        try writeEmbedArray(fields.embeds, writer);
    }
    if (fields.sticker_ids.len != 0) {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"sticker_ids\":");
        try writeSnowflakeStringArray(fields.sticker_ids, writer);
    }
    if (fields.allowed_mentions) |allowed_mentions| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"allowed_mentions\":");
        try allowed_mentions.writeJson(writer);
    }
    if (fields.components.len != 0) {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"components\":");
        try Interactions.writeComponentArray(fields.components, writer);
    }
    if (fields.poll) |poll| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"poll\":");
        try poll.writeJson(writer);
    }
    if (fields.shared_client_theme) |shared_client_theme| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"shared_client_theme\":");
        try shared_client_theme.writeJson(writer);
    }
    if (fields.flags) |flags| {
        try writeComma(writer, needs_comma);
        try writer.print("\"flags\":{d}", .{flags});
    }
}

pub fn writeEmbedArray(embeds: []const Embed, writer: anytype) !void {
    try writer.writeByte('[');
    for (embeds, 0..) |embed, index| {
        if (index != 0) try writer.writeByte(',');
        try embed.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn writePollAnswerArray(answers: []const PollAnswer, writer: anytype) !void {
    try writer.writeByte('[');
    for (answers, 0..) |answer, index| {
        if (index != 0) try writer.writeByte(',');
        try answer.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn writeUploadAttachmentArray(files: anytype, writer: anytype) !void {
    try writer.writeByte('[');
    for (files, 0..) |file, index| {
        if (index != 0) try writer.writeByte(',');
        try writer.print("{{\"id\":\"{d}\",\"filename\":", .{index});
        try Json.writeString(file.filename, writer);
        if (file.description) |description| {
            try writer.writeAll(",\"description\":");
            try Json.writeString(description, writer);
        }
        try writer.writeByte('}');
    }
    try writer.writeByte(']');
}

pub fn writeCreateGuildRoleArray(roles: []const CreateGuildRole, writer: anytype) !void {
    try writer.writeByte('[');
    for (roles, 0..) |role, index| {
        if (index != 0) try writer.writeByte(',');
        try role.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn writeCreateGuildChannelArray(channels: []const CreateGuildChannel, writer: anytype) !void {
    try writer.writeByte('[');
    for (channels, 0..) |channel, index| {
        if (index != 0) try writer.writeByte(',');
        try channel.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn writeEmbedFieldArray(fields: []const EmbedField, writer: anytype) !void {
    try writer.writeByte('[');
    for (fields, 0..) |field, index| {
        if (index != 0) try writer.writeByte(',');
        try field.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn writeAllowedMentionTypeArray(types: []const AllowedMentionType, writer: anytype) !void {
    try writer.writeByte('[');
    for (types, 0..) |mention_type, index| {
        if (index != 0) try writer.writeByte(',');
        const value = switch (mention_type) {
            .roles => "roles",
            .users => "users",
            .everyone => "everyone",
        };
        try Json.writeString(value, writer);
    }
    try writer.writeByte(']');
}

pub fn writeStringArray(values: []const []const u8, writer: anytype) !void {
    try writer.writeByte('[');
    for (values, 0..) |value, index| {
        if (index != 0) try writer.writeByte(',');
        try Json.writeString(value, writer);
    }
    try writer.writeByte(']');
}

pub fn writeStringPairObject(values: []const StringPair, writer: anytype) !void {
    try writer.writeByte('{');
    for (values, 0..) |entry, index| {
        if (index != 0) try writer.writeByte(',');
        try Json.writeString(entry.key, writer);
        try writer.writeByte(':');
        try Json.writeString(entry.value, writer);
    }
    try writer.writeByte('}');
}

pub fn writeNullableStringPairObjectField(
    writer: anytype,
    needs_comma: *bool,
    comptime field: []const u8,
    values: ?[]const StringPair,
    clear: bool,
) !void {
    if (clear) {
        try writeComma(writer, needs_comma);
        try writer.print("\"{s}\":null", .{field});
    } else if (values) |entries| {
        try writeComma(writer, needs_comma);
        try writer.print("\"{s}\":", .{field});
        try writeStringPairObject(entries, writer);
    }
}

pub fn writeLobbyPayloadJson(
    fields: struct {
        metadata: ?[]const StringPair,
        clear_metadata: bool,
        members: []const LobbyMember,
        idle_timeout_seconds: ?u32,
    },
    writer: anytype,
) !void {
    try writer.writeByte('{');
    var needs_comma = false;

    try writeNullableStringPairObjectField(writer, &needs_comma, "metadata", fields.metadata, fields.clear_metadata);
    if (fields.members.len != 0) {
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"members\":");
        try writeLobbyMemberArray(fields.members, writer);
    }
    if (fields.idle_timeout_seconds) |seconds| {
        try writeComma(writer, &needs_comma);
        try writer.print("\"idle_timeout_seconds\":{d}", .{seconds});
    }

    try writer.writeByte('}');
}

pub fn writeLobbyMemberArray(members: []const LobbyMember, writer: anytype) !void {
    try writer.writeByte('[');
    for (members, 0..) |member, index| {
        if (index != 0) try writer.writeByte(',');
        try member.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn writeApplicationRoleConnectionMetadataArray(
    records: []const ApplicationRoleConnectionMetadata,
    writer: anytype,
) !void {
    try writer.writeByte('[');
    for (records, 0..) |record, index| {
        if (index != 0) try writer.writeByte(',');
        try record.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn writeSnowflakeStringArray(ids: []const Snowflake, writer: anytype) !void {
    try writer.writeByte('[');
    for (ids, 0..) |id, index| {
        if (index != 0) try writer.writeByte(',');
        try writer.print("\"{d}\"", .{id.value});
    }
    try writer.writeByte(']');
}

pub fn writeAutoModerationKeywordPresetArray(presets: []const AutoModerationKeywordPresetType, writer: anytype) !void {
    try writer.writeByte('[');
    for (presets, 0..) |preset, index| {
        if (index != 0) try writer.writeByte(',');
        try writer.print("{d}", .{@intFromEnum(preset)});
    }
    try writer.writeByte(']');
}

pub fn writeAutoModerationActionArray(actions: []const AutoModerationAction, writer: anytype) !void {
    try writer.writeByte('[');
    for (actions, 0..) |action, index| {
        if (index != 0) try writer.writeByte(',');
        try action.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn writeAutoModerationRuleFields(
    fields: struct {
        event_type: AutoModerationRuleEventType,
        trigger_type: AutoModerationTriggerType,
        trigger_metadata: ?AutoModerationTriggerMetadata,
        actions: []const AutoModerationAction,
        enabled: ?bool,
        exempt_roles: []const Snowflake,
        exempt_channels: []const Snowflake,
    },
    writer: anytype,
    needs_comma: *bool,
) !void {
    try writeComma(writer, needs_comma);
    try writer.print("\"event_type\":{d}", .{@intFromEnum(fields.event_type)});

    try writeComma(writer, needs_comma);
    try writer.print("\"trigger_type\":{d}", .{@intFromEnum(fields.trigger_type)});

    if (fields.trigger_metadata) |metadata| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"trigger_metadata\":");
        try metadata.writeJson(writer);
    }

    try writeComma(writer, needs_comma);
    try writer.writeAll("\"actions\":");
    try writeAutoModerationActionArray(fields.actions, writer);

    try writeOptionalBoolField(writer, needs_comma, "enabled", fields.enabled);
    if (fields.exempt_roles.len != 0) {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"exempt_roles\":");
        try writeSnowflakeStringArray(fields.exempt_roles, writer);
    }
    if (fields.exempt_channels.len != 0) {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"exempt_channels\":");
        try writeSnowflakeStringArray(fields.exempt_channels, writer);
    }
}

pub fn writeWelcomeScreenChannelArray(channels: []const WelcomeScreenChannel, writer: anytype) !void {
    try writer.writeByte('[');
    for (channels, 0..) |channel, index| {
        if (index != 0) try writer.writeByte(',');
        try channel.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn writeOnboardingPromptOptionArray(options: []const OnboardingPromptOption, writer: anytype) !void {
    try writer.writeByte('[');
    for (options, 0..) |option, index| {
        if (index != 0) try writer.writeByte(',');
        try option.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn writeOnboardingPromptArray(prompts: []const OnboardingPrompt, writer: anytype) !void {
    try writer.writeByte('[');
    for (prompts, 0..) |prompt, index| {
        if (index != 0) try writer.writeByte(',');
        try prompt.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn writeGuildRolePositionArray(positions: []const GuildRolePosition, writer: anytype) !void {
    try writer.writeByte('[');
    for (positions, 0..) |position, index| {
        if (index != 0) try writer.writeByte(',');
        try position.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn writeGuildChannelPositionArray(positions: []const GuildChannelPosition, writer: anytype) !void {
    try writer.writeByte('[');
    for (positions, 0..) |position, index| {
        if (index != 0) try writer.writeByte(',');
        try position.writeJson(writer);
    }
    try writer.writeByte(']');
}

pub fn writeOptionalScheduledEventMetadata(
    writer: anytype,
    needs_comma: *bool,
    metadata: ?GuildScheduledEventEntityMetadata,
) !void {
    if (metadata) |value| {
        try writeComma(writer, needs_comma);
        try writer.writeAll("\"entity_metadata\":");
        try value.writeJson(writer);
    }
}
