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

pub const MessageSnapshot = struct {
    type: u8 = 0,
    content: []const u8 = "",
    timestamp: ?[]const u8 = null,
    edited_timestamp: ?[]const u8 = null,
    flags: ?u32 = null,
    mentions: []const User = &.{},
    mention_roles: []const Snowflake = &.{},
    embeds: []const Embed = &.{},
    attachments: []const Attachment = &.{},
    components: []const Interactions.Component = &.{},
};

pub const MessageCall = struct {
    participants: []const Snowflake = &.{},
    ended_timestamp: ?[]const u8 = null,
};

pub const RoleSubscriptionData = struct {
    role_subscription_listing_id: Snowflake,
    tier_name: []const u8,
    total_months_subscribed: u32,
    is_renewal: bool,
};

pub const SharedClientThemeBase = enum(u8) {
    unset = 0,
    dark = 1,
    light = 2,
    darker = 3,
    midnight = 4,
};

pub const SharedClientTheme = struct {
    colors: []const []const u8 = &.{},
    gradient_angle: u16 = 0,
    base_mix: u8 = 0,
    base_theme: ?SharedClientThemeBase = null,

    pub fn writeJson(self: SharedClientTheme, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        if (self.colors.len != 0) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"colors\":");
            try writeStringArray(self.colors, writer);
        }
        if (self.gradient_angle != 0) {
            try writeComma(writer, &needs_comma);
            try writer.print("\"gradient_angle\":{d}", .{self.gradient_angle});
        }
        if (self.base_mix != 0) {
            try writeComma(writer, &needs_comma);
            try writer.print("\"base_mix\":{d}", .{self.base_mix});
        }
        if (self.base_theme) |base_theme| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"base_theme\":{d}", .{@intFromEnum(base_theme)});
        }
        try writer.writeByte('}');
    }
};

pub const MessageActivityType = enum(u8) {
    join = 1,
    spectate = 2,
    listen = 3,
    join_request = 5,
};

pub const MessageActivity = struct {
    type: MessageActivityType,
    party_id: ?[]const u8 = null,
};

pub const MessageInteractionMetadata = struct {
    id: Snowflake,
    type: Interactions.InteractionType,
    user: User,
    original_response_message_id: ?Snowflake = null,
    interacted_message_id: ?Snowflake = null,
    target_user: ?User = null,
    target_message_id: ?Snowflake = null,
};

pub const Attachment = struct {
    id: Snowflake,
    filename: []const u8,
    description: ?[]const u8 = null,
    content_type: ?[]const u8 = null,
    size: u64 = 0,
    url: []const u8,
    proxy_url: []const u8,
    height: ?u32 = null,
    width: ?u32 = null,
    ephemeral: bool = false,
};

pub const ReactionEmoji = struct {
    id: ?Snowflake = null,
    name: ?[]const u8 = null,
    animated: bool = false,
};

pub const ReactionCountDetails = struct {
    burst: u32 = 0,
    normal: u32 = 0,
};

pub const ReactionType = enum(u8) {
    normal = 0,
    burst = 1,
};

pub const MessageReaction = struct {
    emoji: ReactionEmoji,
    count: u32 = 0,
    count_details: ReactionCountDetails = .{},
    me: bool = false,
    me_burst: bool = false,
    burst_colors: []const []const u8 = &.{},
};

pub const MessagePollMedia = struct {
    text: ?[]const u8 = null,
    emoji: ?PollEmoji = null,
};

pub const MessagePollAnswer = struct {
    answer_id: u32,
    poll_media: MessagePollMedia,
};

pub const MessagePollAnswerCount = struct {
    id: u32,
    count: u32,
    me_voted: bool = false,
};

pub const MessagePollResults = struct {
    is_finalized: bool = false,
    answer_counts: []const MessagePollAnswerCount = &.{},
};

pub const MessagePoll = struct {
    question: MessagePollMedia,
    answers: []const MessagePollAnswer = &.{},
    expiry: ?[]const u8 = null,
    allow_multiselect: bool = false,
    layout_type: ?u8 = null,
    results: ?MessagePollResults = null,
};

pub const EmbedMedia = struct {
    url: []const u8,

    pub fn init(url: []const u8) EmbedMedia {
        return .{ .url = url };
    }

    pub fn writeJson(self: EmbedMedia, writer: anytype) !void {
        try writer.writeAll("{\"url\":");
        try Json.writeString(self.url, writer);
        try writer.writeByte('}');
    }
};

pub const EmbedFooter = struct {
    text: []const u8,
    icon_url: ?[]const u8 = null,

    pub fn init(text: []const u8) EmbedFooter {
        return .{ .text = text };
    }

    pub fn withIcon(self: EmbedFooter, icon_url: []const u8) EmbedFooter {
        var footer = self;
        footer.icon_url = icon_url;
        return footer;
    }

    pub fn writeJson(self: EmbedFooter, writer: anytype) !void {
        try writer.writeAll("{\"text\":");
        try Json.writeString(self.text, writer);
        if (self.icon_url) |icon_url| {
            try writer.writeAll(",\"icon_url\":");
            try Json.writeString(icon_url, writer);
        }
        try writer.writeByte('}');
    }
};

pub const EmbedAuthor = struct {
    name: []const u8,
    url: ?[]const u8 = null,
    icon_url: ?[]const u8 = null,

    pub fn init(name: []const u8) EmbedAuthor {
        return .{ .name = name };
    }

    pub fn withUrl(self: EmbedAuthor, url: []const u8) EmbedAuthor {
        var author = self;
        author.url = url;
        return author;
    }

    pub fn withIcon(self: EmbedAuthor, icon_url: []const u8) EmbedAuthor {
        var author = self;
        author.icon_url = icon_url;
        return author;
    }

    pub fn writeJson(self: EmbedAuthor, writer: anytype) !void {
        try writer.writeAll("{\"name\":");
        try Json.writeString(self.name, writer);
        if (self.url) |url| {
            try writer.writeAll(",\"url\":");
            try Json.writeString(url, writer);
        }
        if (self.icon_url) |icon_url| {
            try writer.writeAll(",\"icon_url\":");
            try Json.writeString(icon_url, writer);
        }
        try writer.writeByte('}');
    }
};

pub const EmbedField = struct {
    name: []const u8,
    value: []const u8,
    is_inline: bool = false,

    /// Discord per-field character limits.
    pub const max_name_len = 256;
    pub const max_value_len = 1024;

    pub fn init(name: []const u8, value: []const u8) EmbedField {
        return .{ .name = name, .value = value };
    }

    pub fn inlineField(name: []const u8, value: []const u8) EmbedField {
        return .{ .name = name, .value = value, .is_inline = true };
    }

    pub fn inlineState(self: EmbedField, is_inline: bool) EmbedField {
        var field = self;
        field.is_inline = is_inline;
        return field;
    }

    pub fn writeJson(self: EmbedField, writer: anytype) !void {
        try writer.writeAll("{\"name\":");
        try Json.writeString(self.name, writer);
        try writer.writeAll(",\"value\":");
        try Json.writeString(self.value, writer);
        if (self.is_inline) try writer.writeAll(",\"inline\":true");
        try writer.writeByte('}');
    }
};

pub const Colors = struct {
    pub const default: u24 = 0x000000;
    pub const white: u24 = 0xFFFFFF;
    pub const aqua: u24 = 0x1ABC9C;
    pub const green: u24 = 0x57F287;
    pub const blue: u24 = 0x3498DB;
    pub const yellow: u24 = 0xFEE75C;
    pub const purple: u24 = 0x9B59B6;
    pub const luminous_vivid_pink: u24 = 0xE91E63;
    pub const fuchsia: u24 = 0xEB459E;
    pub const gold: u24 = 0xF1C40F;
    pub const orange: u24 = 0xE67E22;
    pub const red: u24 = 0xED4245;
    pub const grey: u24 = 0x95A5A6;
    pub const navy: u24 = 0x34495E;
    pub const dark_aqua: u24 = 0x11806A;
    pub const dark_green: u24 = 0x1F8B4C;
    pub const dark_blue: u24 = 0x206694;
    pub const dark_purple: u24 = 0x71368A;
    pub const dark_vivid_pink: u24 = 0xAD1457;
    pub const dark_gold: u24 = 0xC27C0E;
    pub const dark_orange: u24 = 0xA84300;
    pub const dark_red: u24 = 0x992D22;
    pub const dark_grey: u24 = 0x979C9F;
    pub const darker_grey: u24 = 0x7F8C8D;
    pub const light_grey: u24 = 0xBCC0C0;
    pub const dark_navy: u24 = 0x2C3E50;
    pub const blurple: u24 = 0x5865F2;
    pub const greyple: u24 = 0x99AAB5;
    pub const dark_but_not_black: u24 = 0x2C2F33;
    pub const not_quite_black: u24 = 0x23272A;

    pub const Default = default;
    pub const White = white;
    pub const Aqua = aqua;
    pub const Green = green;
    pub const Blue = blue;
    pub const Yellow = yellow;
    pub const Purple = purple;
    pub const LuminousVividPink = luminous_vivid_pink;
    pub const Fuchsia = fuchsia;
    pub const Gold = gold;
    pub const Orange = orange;
    pub const Red = red;
    pub const Grey = grey;
    pub const Navy = navy;
    pub const DarkAqua = dark_aqua;
    pub const DarkGreen = dark_green;
    pub const DarkBlue = dark_blue;
    pub const DarkPurple = dark_purple;
    pub const DarkVividPink = dark_vivid_pink;
    pub const DarkGold = dark_gold;
    pub const DarkOrange = dark_orange;
    pub const DarkRed = dark_red;
    pub const DarkGrey = dark_grey;
    pub const DarkerGrey = darker_grey;
    pub const LightGrey = light_grey;
    pub const DarkNavy = dark_navy;
    pub const Blurple = blurple;
    pub const Greyple = greyple;
    pub const DarkButNotBlack = dark_but_not_black;
    pub const NotQuiteBlack = not_quite_black;

    pub const ColorInfo = struct {
        value: u24,
        name: []const u8,
    };

    pub const all_colors = [_]ColorInfo{
        .{ .value = Default, .name = "Default" },
        .{ .value = White, .name = "White" },
        .{ .value = Aqua, .name = "Aqua" },
        .{ .value = Green, .name = "Green" },
        .{ .value = Blue, .name = "Blue" },
        .{ .value = Yellow, .name = "Yellow" },
        .{ .value = Purple, .name = "Purple" },
        .{ .value = LuminousVividPink, .name = "LuminousVividPink" },
        .{ .value = Fuchsia, .name = "Fuchsia" },
        .{ .value = Gold, .name = "Gold" },
        .{ .value = Orange, .name = "Orange" },
        .{ .value = Red, .name = "Red" },
        .{ .value = Grey, .name = "Grey" },
        .{ .value = Navy, .name = "Navy" },
        .{ .value = DarkAqua, .name = "DarkAqua" },
        .{ .value = DarkGreen, .name = "DarkGreen" },
        .{ .value = DarkBlue, .name = "DarkBlue" },
        .{ .value = DarkPurple, .name = "DarkPurple" },
        .{ .value = DarkVividPink, .name = "DarkVividPink" },
        .{ .value = DarkGold, .name = "DarkGold" },
        .{ .value = DarkOrange, .name = "DarkOrange" },
        .{ .value = DarkRed, .name = "DarkRed" },
        .{ .value = DarkGrey, .name = "DarkGrey" },
        .{ .value = DarkerGrey, .name = "DarkerGrey" },
        .{ .value = LightGrey, .name = "LightGrey" },
        .{ .value = DarkNavy, .name = "DarkNavy" },
        .{ .value = Blurple, .name = "Blurple" },
        .{ .value = Greyple, .name = "Greyple" },
        .{ .value = DarkButNotBlack, .name = "DarkButNotBlack" },
        .{ .value = NotQuiteBlack, .name = "NotQuiteBlack" },
    };

    pub fn discordJsName(value: u24) ?[]const u8 {
        for (all_colors) |color| {
            if (color.value == value) return color.name;
        }
        return null;
    }

    pub fn fromDiscordJsName(name: []const u8) ?u24 {
        for (all_colors) |color| {
            if (std.mem.eql(u8, color.name, name)) return color.value;
        }
        return null;
    }
};

pub const Embed = struct {
    title: ?[]const u8 = null,
    description: ?[]const u8 = null,
    url: ?[]const u8 = null,
    timestamp: ?[]const u8 = null,
    color: ?u24 = null,
    footer: ?EmbedFooter = null,
    image: ?EmbedMedia = null,
    thumbnail: ?EmbedMedia = null,
    author: ?EmbedAuthor = null,
    fields: []const EmbedField = &.{},

    pub fn init() Embed {
        return .{};
    }

    pub fn withTitle(self: Embed, title: []const u8) Embed {
        var embed = self;
        embed.title = title;
        return embed;
    }

    pub fn withDescription(self: Embed, description: []const u8) Embed {
        var embed = self;
        embed.description = description;
        return embed;
    }

    pub fn withUrl(self: Embed, url: []const u8) Embed {
        var embed = self;
        embed.url = url;
        return embed;
    }

    pub fn withTimestamp(self: Embed, timestamp: []const u8) Embed {
        var embed = self;
        embed.timestamp = timestamp;
        return embed;
    }

    pub fn withColor(self: Embed, color: u24) Embed {
        var embed = self;
        embed.color = color;
        return embed;
    }

    pub fn withFooter(self: Embed, footer: EmbedFooter) Embed {
        var embed = self;
        embed.footer = footer;
        return embed;
    }

    pub fn withImage(self: Embed, image_url: []const u8) Embed {
        var embed = self;
        embed.image = EmbedMedia.init(image_url);
        return embed;
    }

    pub fn withThumbnail(self: Embed, thumbnail_url: []const u8) Embed {
        var embed = self;
        embed.thumbnail = EmbedMedia.init(thumbnail_url);
        return embed;
    }

    pub fn withAuthor(self: Embed, author: EmbedAuthor) Embed {
        var embed = self;
        embed.author = author;
        return embed;
    }

    pub fn withFields(self: Embed, fields: []const EmbedField) Embed {
        var embed = self;
        embed.fields = fields;
        return embed;
    }

    pub fn withField(self: Embed, field: *const EmbedField) Embed {
        var embed = self;
        embed.fields = field[0..1];
        return embed;
    }

    /// Discord embed character/count limits.
    pub const max_fields = 25;
    pub const max_title_len = 256;
    pub const max_description_len = 4096;
    pub const max_footer_len = 2048;
    pub const max_author_name_len = 256;
    /// Combined character budget across title, description, field names/values,
    /// footer text, and author name for a single embed.
    pub const max_total_len = 6000;

    pub const ValidationError = error{
        TooManyFields,
        TitleTooLong,
        DescriptionTooLong,
        FooterTooLong,
        AuthorNameTooLong,
        FieldNameTooLong,
        FieldValueTooLong,
        EmbedTooLong,
        InvalidUtf8,
    };

    /// Rejects an embed that violates a documented Discord limit, turning a
    /// guaranteed API rejection into a local, allocation-free error. Lengths are
    /// measured in Unicode code points, matching how Discord counts characters.
    pub fn validate(self: Embed) ValidationError!void {
        if (self.fields.len > max_fields) return error.TooManyFields;
        var total: usize = 0;
        if (self.title) |title| {
            const len = try Json.codepointLen(title);
            if (len > max_title_len) return error.TitleTooLong;
            total += len;
        }
        if (self.description) |description| {
            const len = try Json.codepointLen(description);
            if (len > max_description_len) return error.DescriptionTooLong;
            total += len;
        }
        if (self.footer) |footer| {
            const len = try Json.codepointLen(footer.text);
            if (len > max_footer_len) return error.FooterTooLong;
            total += len;
        }
        if (self.author) |author| {
            const len = try Json.codepointLen(author.name);
            if (len > max_author_name_len) return error.AuthorNameTooLong;
            total += len;
        }
        for (self.fields) |field| {
            const name_len = try Json.codepointLen(field.name);
            if (name_len > EmbedField.max_name_len) return error.FieldNameTooLong;
            const value_len = try Json.codepointLen(field.value);
            if (value_len > EmbedField.max_value_len) return error.FieldValueTooLong;
            total += name_len + value_len;
        }
        if (total > max_total_len) return error.EmbedTooLong;
    }

    pub fn writeJson(self: Embed, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        try writeOptionalStringField(writer, &needs_comma, "title", self.title);
        try writeOptionalStringField(writer, &needs_comma, "description", self.description);
        try writeOptionalStringField(writer, &needs_comma, "url", self.url);
        try writeOptionalStringField(writer, &needs_comma, "timestamp", self.timestamp);
        if (self.color) |color| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"color\":{d}", .{color});
        }
        if (self.footer) |footer| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"footer\":");
            try footer.writeJson(writer);
        }
        if (self.image) |image| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"image\":");
            try image.writeJson(writer);
        }
        if (self.thumbnail) |thumbnail| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"thumbnail\":");
            try thumbnail.writeJson(writer);
        }
        if (self.author) |author| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"author\":");
            try author.writeJson(writer);
        }
        if (self.fields.len != 0) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"fields\":");
            try writeEmbedFieldArray(self.fields, writer);
        }
        try writer.writeByte('}');
    }
};

pub const AllowedMentionType = enum {
    roles,
    users,
    everyone,
};

pub const AllowedMentions = struct {
    parse: []const AllowedMentionType = &.{},
    users: []const Snowflake = &.{},
    roles: []const Snowflake = &.{},
    replied_user: bool = false,

    pub fn none() AllowedMentions {
        return .{};
    }

    pub fn all() AllowedMentions {
        return .{ .parse = &.{ .roles, .users, .everyone } };
    }

    pub fn usersOnly() AllowedMentions {
        return .{ .parse = &.{.users} };
    }

    pub fn rolesOnly() AllowedMentions {
        return .{ .parse = &.{.roles} };
    }

    pub fn everyoneOnly() AllowedMentions {
        return .{ .parse = &.{.everyone} };
    }

    pub fn repliedUserOnly() AllowedMentions {
        return .{ .replied_user = true };
    }

    pub fn withUsers(self: AllowedMentions, users: []const Snowflake) AllowedMentions {
        var mentions = self;
        mentions.users = users;
        return mentions;
    }

    pub fn withUser(self: AllowedMentions, user: *const Snowflake) AllowedMentions {
        var mentions = self;
        mentions.users = user[0..1];
        return mentions;
    }

    pub fn withRoles(self: AllowedMentions, roles: []const Snowflake) AllowedMentions {
        var mentions = self;
        mentions.roles = roles;
        return mentions;
    }

    pub fn withRole(self: AllowedMentions, role: *const Snowflake) AllowedMentions {
        var mentions = self;
        mentions.roles = role[0..1];
        return mentions;
    }

    pub fn withParse(self: AllowedMentions, parse: []const AllowedMentionType) AllowedMentions {
        var mentions = self;
        mentions.parse = parse;
        return mentions;
    }

    pub fn repliedUser(self: AllowedMentions, allow: bool) AllowedMentions {
        var mentions = self;
        mentions.replied_user = allow;
        return mentions;
    }

    /// Discord allows at most 100 explicit user and 100 explicit role mentions.
    pub const max_users = 100;
    pub const max_roles = 100;

    pub const ValidationError = error{
        TooManyUsers,
        TooManyRoles,
        UserParseConflict,
        RoleParseConflict,
    };

    /// Rejects an allowed-mentions payload Discord would reject: more than 100
    /// explicit ids of either kind, or an explicit allowlist combined with the
    /// matching broad `parse` entry (Discord forbids mixing the two).
    pub fn validate(self: AllowedMentions) ValidationError!void {
        if (self.users.len > max_users) return error.TooManyUsers;
        if (self.roles.len > max_roles) return error.TooManyRoles;
        for (self.parse) |kind| {
            switch (kind) {
                .users => if (self.users.len != 0) return error.UserParseConflict,
                .roles => if (self.roles.len != 0) return error.RoleParseConflict,
                .everyone => {},
            }
        }
    }

    pub fn writeJson(self: AllowedMentions, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"parse\":");
        try writeAllowedMentionTypeArray(self.parse, writer);
        if (self.users.len != 0) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"users\":");
            try writeSnowflakeStringArray(self.users, writer);
        }
        if (self.roles.len != 0) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"roles\":");
            try writeSnowflakeStringArray(self.roles, writer);
        }
        if (self.replied_user) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"replied_user\":true");
        }
        try writer.writeByte('}');
    }
};

pub const PollLayoutType = enum(u8) {
    default = 1,
};

pub const PollEmoji = struct {
    id: ?Snowflake = null,
    name: ?[]const u8 = null,

    pub fn unicode(name: []const u8) PollEmoji {
        return .{ .name = name };
    }

    pub fn custom(id: Snowflake) PollEmoji {
        return .{ .id = id };
    }

    pub fn writeJson(self: PollEmoji, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        if (self.id) |id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"id\":\"{d}\"", .{id.value});
        }
        try writeOptionalStringField(writer, &needs_comma, "name", self.name);
        try writer.writeByte('}');
    }
};
