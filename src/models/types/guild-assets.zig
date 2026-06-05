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
const BulkDeleteMessages = Root.BulkDeleteMessages;
const MessageReference = Root.MessageReference;
const UploadFile = Root.UploadFile;
const UploadFilePath = Root.UploadFilePath;
const EmbedBuilder = Root.EmbedBuilder;
const AttachmentBuilder = Root.AttachmentBuilder;
const AttachmentPathBuilder = Root.AttachmentPathBuilder;
const AllowedMentionsBuilder = Root.AllowedMentionsBuilder;
const PollBuilder = Root.PollBuilder;
const writeCreateMessageJsonWithAttachments = Root.writeCreateMessageJsonWithAttachments;
const writeCreateMessageJsonWithAttachmentMetadata = Root.writeCreateMessageJsonWithAttachmentMetadata;
const MessagePayloadFields = Root.MessagePayloadFields;
const ChannelFields = Root.ChannelFields;
const RoleFields = Root.RoleFields;
const ThreadFields = Root.ThreadFields;
const ThreadEditFields = Root.ThreadEditFields;
const writeRoleFields = Root.writeRoleFields;
const writeThreadFields = Root.writeThreadFields;
const writeThreadEditFields = Root.writeThreadEditFields;
const writeChannelFields = Root.writeChannelFields;
const writeForumTagArray = Root.writeForumTagArray;
const writeMessagePayloadFields = Root.writeMessagePayloadFields;
const writeEmbedArray = Root.writeEmbedArray;
const writePollAnswerArray = Root.writePollAnswerArray;
const writeUploadAttachmentArray = Root.writeUploadAttachmentArray;
const writeCreateGuildRoleArray = Root.writeCreateGuildRoleArray;
const writeCreateGuildChannelArray = Root.writeCreateGuildChannelArray;
const writeEmbedFieldArray = Root.writeEmbedFieldArray;
const writeAllowedMentionTypeArray = Root.writeAllowedMentionTypeArray;
const writeStringArray = Root.writeStringArray;
const writeStringPairObject = Root.writeStringPairObject;
const writeNullableStringPairObjectField = Root.writeNullableStringPairObjectField;
const writeLobbyPayloadJson = Root.writeLobbyPayloadJson;
const writeLobbyMemberArray = Root.writeLobbyMemberArray;
const writeApplicationRoleConnectionMetadataArray = Root.writeApplicationRoleConnectionMetadataArray;
const writeSnowflakeStringArray = Root.writeSnowflakeStringArray;
const writeAutoModerationKeywordPresetArray = Root.writeAutoModerationKeywordPresetArray;
const writeAutoModerationActionArray = Root.writeAutoModerationActionArray;
const writeAutoModerationRuleFields = Root.writeAutoModerationRuleFields;
const writeWelcomeScreenChannelArray = Root.writeWelcomeScreenChannelArray;
const writeOnboardingPromptOptionArray = Root.writeOnboardingPromptOptionArray;
const writeOnboardingPromptArray = Root.writeOnboardingPromptArray;
const writeGuildRolePositionArray = Root.writeGuildRolePositionArray;
const writeGuildChannelPositionArray = Root.writeGuildChannelPositionArray;
const writeOptionalScheduledEventMetadata = Root.writeOptionalScheduledEventMetadata;
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

pub const EditGuildRole = struct {
    name: ?[]const u8 = null,
    permissions: ?Permissions.Bit = null,
    color: ?u24 = null,
    colors: ?RoleColors = null,
    hoist: ?bool = null,
    icon: ?[]const u8 = null,
    clear_icon: bool = false,
    unicode_emoji: ?[]const u8 = null,
    clear_unicode_emoji: bool = false,
    mentionable: ?bool = null,

    pub fn init() EditGuildRole {
        return .{};
    }

    pub fn withName(self: EditGuildRole, name: []const u8) EditGuildRole {
        var role = self;
        role.name = name;
        return role;
    }

    pub fn withPermissions(self: EditGuildRole, permissions: Permissions.Bit) EditGuildRole {
        var role = self;
        role.permissions = permissions;
        return role;
    }

    pub fn withColor(self: EditGuildRole, color: u24) EditGuildRole {
        var role = self;
        role.color = color;
        return role;
    }

    pub fn withColors(self: EditGuildRole, colors: RoleColors) EditGuildRole {
        var role = self;
        role.colors = colors;
        return role;
    }

    pub fn hoisted(self: EditGuildRole, hoist: bool) EditGuildRole {
        var role = self;
        role.hoist = hoist;
        return role;
    }

    pub fn withIcon(self: EditGuildRole, icon: []const u8) EditGuildRole {
        var role = self;
        role.icon = icon;
        role.clear_icon = false;
        return role;
    }

    pub fn clearIcon(self: EditGuildRole) EditGuildRole {
        var role = self;
        role.icon = null;
        role.clear_icon = true;
        return role;
    }

    pub fn withUnicodeEmoji(self: EditGuildRole, unicode_emoji: []const u8) EditGuildRole {
        var role = self;
        role.unicode_emoji = unicode_emoji;
        role.clear_unicode_emoji = false;
        return role;
    }

    pub fn clearUnicodeEmoji(self: EditGuildRole) EditGuildRole {
        var role = self;
        role.unicode_emoji = null;
        role.clear_unicode_emoji = true;
        return role;
    }

    pub fn mentionableState(self: EditGuildRole, mentionable: bool) EditGuildRole {
        var role = self;
        role.mentionable = mentionable;
        return role;
    }

    pub fn writeJson(self: EditGuildRole, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "name", self.name);
        try writeRoleFields(.{
            .permissions = self.permissions,
            .color = self.color,
            .colors = self.colors,
            .hoist = self.hoist,
            .icon = self.icon,
            .clear_icon = self.clear_icon,
            .unicode_emoji = self.unicode_emoji,
            .clear_unicode_emoji = self.clear_unicode_emoji,
            .mentionable = self.mentionable,
        }, writer, &needs_comma);

        try writer.writeByte('}');
    }
};

pub const GuildRolePosition = struct {
    id: Snowflake,
    position: ?i32 = null,
    clear_position: bool = false,

    pub fn init(id: Snowflake) GuildRolePosition {
        return .{ .id = id };
    }

    pub fn withPosition(self: GuildRolePosition, position: i32) GuildRolePosition {
        var payload = self;
        payload.position = position;
        payload.clear_position = false;
        return payload;
    }

    pub fn clearPosition(self: GuildRolePosition) GuildRolePosition {
        var payload = self;
        payload.position = null;
        payload.clear_position = true;
        return payload;
    }

    pub fn writeJson(self: GuildRolePosition, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.print("\"id\":\"{d}\"", .{self.id.value});
        if (self.clear_position) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"position\":null");
        } else if (self.position) |position| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"position\":{d}", .{position});
        }

        try writer.writeByte('}');
    }
};

pub const CreateGuildEmoji = struct {
    name: []const u8,
    image: []const u8,
    roles: []const Snowflake = &.{},

    pub fn init(name: []const u8, image: []const u8) CreateGuildEmoji {
        return .{ .name = name, .image = image };
    }

    pub fn withRoles(self: CreateGuildEmoji, roles: []const Snowflake) CreateGuildEmoji {
        var payload = self;
        payload.roles = roles;
        return payload;
    }

    pub fn writeJson(self: CreateGuildEmoji, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"image\":");
        try Json.writeString(self.image, writer);

        if (self.roles.len != 0) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"roles\":");
            try writeSnowflakeStringArray(self.roles, writer);
        }

        try writer.writeByte('}');
    }
};

pub const EditGuildEmoji = struct {
    name: ?[]const u8 = null,
    roles: ?[]const Snowflake = null,

    pub fn init() EditGuildEmoji {
        return .{};
    }

    pub fn withName(self: EditGuildEmoji, name: []const u8) EditGuildEmoji {
        var payload = self;
        payload.name = name;
        return payload;
    }

    pub fn withRoles(self: EditGuildEmoji, roles: []const Snowflake) EditGuildEmoji {
        var payload = self;
        payload.roles = roles;
        return payload;
    }

    pub fn writeJson(self: EditGuildEmoji, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "name", self.name);
        if (self.roles) |roles| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"roles\":");
            try writeSnowflakeStringArray(roles, writer);
        }

        try writer.writeByte('}');
    }
};

pub const CreateApplicationEmoji = struct {
    name: []const u8,
    image: []const u8,

    pub fn init(name: []const u8, image: []const u8) CreateApplicationEmoji {
        return .{ .name = name, .image = image };
    }

    pub fn writeJson(self: CreateApplicationEmoji, writer: anytype) !void {
        try writer.writeByte('{');
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);
        try writer.writeAll(",\"image\":");
        try Json.writeString(self.image, writer);
        try writer.writeByte('}');
    }
};

pub const EditApplicationEmoji = struct {
    name: []const u8,

    pub fn init(name: []const u8) EditApplicationEmoji {
        return .{ .name = name };
    }

    pub fn writeJson(self: EditApplicationEmoji, writer: anytype) !void {
        try writer.writeByte('{');
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);
        try writer.writeByte('}');
    }
};

pub const CreateGuildSticker = struct {
    name: []const u8,
    description: ?[]const u8 = null,
    tags: []const u8,

    pub fn init(name: []const u8, tags: []const u8) CreateGuildSticker {
        return .{ .name = name, .tags = tags };
    }

    pub fn withDescription(self: CreateGuildSticker, description: []const u8) CreateGuildSticker {
        var payload = self;
        payload.description = description;
        return payload;
    }
};

pub const EditGuildSticker = struct {
    name: ?[]const u8 = null,
    description: ?[]const u8 = null,
    tags: ?[]const u8 = null,

    pub fn init() EditGuildSticker {
        return .{};
    }

    pub fn withName(self: EditGuildSticker, name: []const u8) EditGuildSticker {
        var payload = self;
        payload.name = name;
        return payload;
    }

    pub fn withDescription(self: EditGuildSticker, description: []const u8) EditGuildSticker {
        var payload = self;
        payload.description = description;
        return payload;
    }

    pub fn withTags(self: EditGuildSticker, tags: []const u8) EditGuildSticker {
        var payload = self;
        payload.tags = tags;
        return payload;
    }

    pub fn writeJson(self: EditGuildSticker, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "name", self.name);
        try writeOptionalStringField(writer, &needs_comma, "description", self.description);
        try writeOptionalStringField(writer, &needs_comma, "tags", self.tags);

        try writer.writeByte('}');
    }
};

pub const SendSoundboardSound = struct {
    sound_id: Snowflake,
    source_guild_id: ?Snowflake = null,

    pub fn init(sound_id: Snowflake) SendSoundboardSound {
        return .{ .sound_id = sound_id };
    }

    pub fn fromGuild(self: SendSoundboardSound, source_guild_id: Snowflake) SendSoundboardSound {
        var payload = self;
        payload.source_guild_id = source_guild_id;
        return payload;
    }

    pub fn writeJson(self: SendSoundboardSound, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.print("\"sound_id\":\"{d}\"", .{self.sound_id.value});
        if (self.source_guild_id) |guild_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"source_guild_id\":\"{d}\"", .{guild_id.value});
        }

        try writer.writeByte('}');
    }
};

pub const CreateGuildSoundboardSound = struct {
    name: []const u8,
    sound: []const u8,
    volume: ?f64 = null,
    emoji_id: ?Snowflake = null,
    emoji_name: ?[]const u8 = null,

    pub fn init(name: []const u8, sound: []const u8) CreateGuildSoundboardSound {
        return .{ .name = name, .sound = sound };
    }

    pub fn withVolume(self: CreateGuildSoundboardSound, volume: f64) CreateGuildSoundboardSound {
        var payload = self;
        payload.volume = volume;
        return payload;
    }

    pub fn withEmojiId(self: CreateGuildSoundboardSound, emoji_id: Snowflake) CreateGuildSoundboardSound {
        var payload = self;
        payload.emoji_id = emoji_id;
        return payload;
    }

    pub fn withEmojiName(self: CreateGuildSoundboardSound, emoji_name: []const u8) CreateGuildSoundboardSound {
        var payload = self;
        payload.emoji_name = emoji_name;
        return payload;
    }

    pub fn writeJson(self: CreateGuildSoundboardSound, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"sound\":");
        try Json.writeString(self.sound, writer);

        try writeOptionalFloatField(writer, &needs_comma, "volume", self.volume);
        if (self.emoji_id) |emoji_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"emoji_id\":\"{d}\"", .{emoji_id.value});
        }
        try writeOptionalStringField(writer, &needs_comma, "emoji_name", self.emoji_name);

        try writer.writeByte('}');
    }
};

pub const EditGuildSoundboardSound = struct {
    name: ?[]const u8 = null,
    volume: ?f64 = null,
    emoji_id: ?Snowflake = null,
    clear_emoji_id: bool = false,
    emoji_name: ?[]const u8 = null,
    clear_emoji_name: bool = false,

    pub fn init() EditGuildSoundboardSound {
        return .{};
    }

    pub fn withName(self: EditGuildSoundboardSound, name: []const u8) EditGuildSoundboardSound {
        var payload = self;
        payload.name = name;
        return payload;
    }

    pub fn withVolume(self: EditGuildSoundboardSound, volume: f64) EditGuildSoundboardSound {
        var payload = self;
        payload.volume = volume;
        return payload;
    }

    pub fn withEmojiId(self: EditGuildSoundboardSound, emoji_id: Snowflake) EditGuildSoundboardSound {
        var payload = self;
        payload.emoji_id = emoji_id;
        payload.clear_emoji_id = false;
        return payload;
    }

    pub fn clearEmojiId(self: EditGuildSoundboardSound) EditGuildSoundboardSound {
        var payload = self;
        payload.emoji_id = null;
        payload.clear_emoji_id = true;
        return payload;
    }

    pub fn withEmojiName(self: EditGuildSoundboardSound, emoji_name: []const u8) EditGuildSoundboardSound {
        var payload = self;
        payload.emoji_name = emoji_name;
        payload.clear_emoji_name = false;
        return payload;
    }

    pub fn clearEmojiName(self: EditGuildSoundboardSound) EditGuildSoundboardSound {
        var payload = self;
        payload.emoji_name = null;
        payload.clear_emoji_name = true;
        return payload;
    }

    pub fn writeJson(self: EditGuildSoundboardSound, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "name", self.name);
        try writeOptionalFloatField(writer, &needs_comma, "volume", self.volume);
        try writeNullableSnowflakeField(writer, &needs_comma, "emoji_id", self.emoji_id, self.clear_emoji_id);
        try writeNullableStringField(writer, &needs_comma, "emoji_name", self.emoji_name, self.clear_emoji_name);

        try writer.writeByte('}');
    }
};

pub const EditGuildMember = struct {
    nick: ?[]const u8 = null,
    roles: ?[]const Snowflake = null,
    mute: ?bool = null,
    deaf: ?bool = null,
    channel_id: ?Snowflake = null,
    communication_disabled_until: ?[]const u8 = null,
    clear_communication_disabled_until: bool = false,

    pub fn init() EditGuildMember {
        return .{};
    }

    pub fn withNick(self: EditGuildMember, nick: []const u8) EditGuildMember {
        var payload = self;
        payload.nick = nick;
        return payload;
    }

    pub fn withRoles(self: EditGuildMember, roles: []const Snowflake) EditGuildMember {
        var payload = self;
        payload.roles = roles;
        return payload;
    }

    pub fn muteState(self: EditGuildMember, mute: bool) EditGuildMember {
        var payload = self;
        payload.mute = mute;
        return payload;
    }

    pub fn deafState(self: EditGuildMember, deaf: bool) EditGuildMember {
        var payload = self;
        payload.deaf = deaf;
        return payload;
    }

    pub fn moveToVoiceChannel(self: EditGuildMember, channel_id: Snowflake) EditGuildMember {
        var payload = self;
        payload.channel_id = channel_id;
        return payload;
    }

    pub fn timeoutUntil(self: EditGuildMember, timestamp: []const u8) EditGuildMember {
        var payload = self;
        payload.communication_disabled_until = timestamp;
        payload.clear_communication_disabled_until = false;
        return payload;
    }

    pub fn clearTimeout(self: EditGuildMember) EditGuildMember {
        var payload = self;
        payload.communication_disabled_until = null;
        payload.clear_communication_disabled_until = true;
        return payload;
    }

    pub fn writeJson(self: EditGuildMember, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "nick", self.nick);
        if (self.roles) |roles| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"roles\":");
            try writeSnowflakeStringArray(roles, writer);
        }
        try writeOptionalBoolField(writer, &needs_comma, "mute", self.mute);
        try writeOptionalBoolField(writer, &needs_comma, "deaf", self.deaf);
        if (self.channel_id) |channel_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"channel_id\":\"{d}\"", .{channel_id.value});
        }
        try writeNullableStringField(
            writer,
            &needs_comma,
            "communication_disabled_until",
            self.communication_disabled_until,
            self.clear_communication_disabled_until,
        );

        try writer.writeByte('}');
    }
};

pub const AddGuildMember = struct {
    access_token: []const u8,
    nick: ?[]const u8 = null,
    roles: ?[]const Snowflake = null,
    mute: ?bool = null,
    deaf: ?bool = null,

    pub fn init(access_token: []const u8) AddGuildMember {
        return .{ .access_token = access_token };
    }

    pub fn withNick(self: AddGuildMember, nick: []const u8) AddGuildMember {
        var payload = self;
        payload.nick = nick;
        return payload;
    }

    pub fn withRoles(self: AddGuildMember, roles: []const Snowflake) AddGuildMember {
        var payload = self;
        payload.roles = roles;
        return payload;
    }

    pub fn muteState(self: AddGuildMember, mute: bool) AddGuildMember {
        var payload = self;
        payload.mute = mute;
        return payload;
    }

    pub fn deafState(self: AddGuildMember, deaf: bool) AddGuildMember {
        var payload = self;
        payload.deaf = deaf;
        return payload;
    }

    pub fn writeJson(self: AddGuildMember, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "access_token", self.access_token);
        try writeOptionalStringField(writer, &needs_comma, "nick", self.nick);
        if (self.roles) |roles| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"roles\":");
            try writeSnowflakeStringArray(roles, writer);
        }
        try writeOptionalBoolField(writer, &needs_comma, "mute", self.mute);
        try writeOptionalBoolField(writer, &needs_comma, "deaf", self.deaf);

        try writer.writeByte('}');
    }
};
