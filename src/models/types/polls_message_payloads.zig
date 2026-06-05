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

pub const PollMedia = struct {
    text: []const u8,
    emoji: ?PollEmoji = null,

    pub fn textOnly(text: []const u8) PollMedia {
        return .{ .text = text };
    }

    pub fn withEmoji(text: []const u8, emoji: PollEmoji) PollMedia {
        return .{ .text = text, .emoji = emoji };
    }

    pub fn writeJson(self: PollMedia, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"text\":");
        try Json.writeString(self.text, writer);
        if (self.emoji) |emoji| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"emoji\":");
            try emoji.writeJson(writer);
        }

        try writer.writeByte('}');
    }
};

pub const PollAnswer = struct {
    poll_media: PollMedia,

    pub fn text(value: []const u8) PollAnswer {
        return .{ .poll_media = PollMedia.textOnly(value) };
    }

    pub fn withEmoji(value: []const u8, emoji: PollEmoji) PollAnswer {
        return .{ .poll_media = PollMedia.withEmoji(value, emoji) };
    }

    pub fn writeJson(self: PollAnswer, writer: anytype) !void {
        try writer.writeAll("{\"poll_media\":");
        try self.poll_media.writeJson(writer);
        try writer.writeByte('}');
    }
};

pub const CreatePoll = struct {
    question: PollMedia,
    answers: []const PollAnswer,
    duration: ?u16 = null,
    allow_multiselect: ?bool = null,
    layout_type: ?PollLayoutType = null,

    pub fn init(question: []const u8, answers: []const PollAnswer) CreatePoll {
        return .{ .question = PollMedia.textOnly(question), .answers = answers };
    }

    pub fn withQuestionEmoji(self: CreatePoll, emoji: PollEmoji) CreatePoll {
        var poll = self;
        poll.question.emoji = emoji;
        return poll;
    }

    pub fn withDuration(self: CreatePoll, duration: u16) CreatePoll {
        var poll = self;
        poll.duration = duration;
        return poll;
    }

    pub fn multiselect(self: CreatePoll, allow_multiselect: bool) CreatePoll {
        var poll = self;
        poll.allow_multiselect = allow_multiselect;
        return poll;
    }

    pub fn withLayout(self: CreatePoll, layout_type: PollLayoutType) CreatePoll {
        var poll = self;
        poll.layout_type = layout_type;
        return poll;
    }

    pub fn writeJson(self: CreatePoll, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"question\":");
        try self.question.writeJson(writer);

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"answers\":");
        try writePollAnswerArray(self.answers, writer);

        if (self.duration) |duration| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"duration\":{d}", .{duration});
        }
        try writeOptionalBoolField(writer, &needs_comma, "allow_multiselect", self.allow_multiselect);
        if (self.layout_type) |layout_type| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"layout_type\":{d}", .{@intFromEnum(layout_type)});
        }

        try writer.writeByte('}');
    }
};

pub const max_message_content_len = 2000;

pub const max_message_nonce_len = 25;

pub const max_message_embeds = 10;

pub const max_message_stickers = 3;

pub const MessageValidationError = error{
    ContentTooLong,
    NonceTooLong,
    TooManyEmbeds,
    TooManyStickers,
    ComponentsV2Exclusive,
    TooManyFields,
    TitleTooLong,
    DescriptionTooLong,
    FooterTooLong,
    AuthorNameTooLong,
    FieldNameTooLong,
    FieldValueTooLong,
    EmbedTooLong,
    TooManyUsers,
    TooManyRoles,
    UserParseConflict,
    RoleParseConflict,
    TooManyActionRows,
    TooManyRowComponents,
    TooManySelectOptions,
    TooManyCommandOptions,
    TooManyCommandChoices,
    CustomIdTooLong,
    ButtonLabelTooLong,
    ButtonCustomIdRequired,
    ButtonUrlRequired,
    ButtonSkuIdRequired,
    ButtonFieldConflict,
    SelectPlaceholderTooLong,
    SelectOptionLabelTooLong,
    SelectOptionValueTooLong,
    SelectOptionDescriptionTooLong,
    SelectValueRangeInvalid,
    TextInputLabelTooLong,
    TextInputPlaceholderTooLong,
    TextInputValueTooLong,
    CommandNameInvalid,
    CommandDescriptionInvalid,
    OptionNameInvalid,
    OptionDescriptionInvalid,
    ChoiceNameTooLong,
    ChoiceValueTooLong,
    SectionComponentCountInvalid,
    MediaGalleryItemCountInvalid,
    InvalidUtf8,
};

pub fn validateMessagePayload(
    content: ?[]const u8,
    flags: ?MessageFlags.Bit,
    embeds: []const Embed,
    sticker_ids: []const Snowflake,
    allowed_mentions: ?AllowedMentions,
    components: []const Interactions.Component,
    poll: ?CreatePoll,
    shared_client_theme: ?SharedClientTheme,
) MessageValidationError!void {
    if (content) |value| {
        const len = try Json.codepointLen(value);
        if (len > max_message_content_len) return error.ContentTooLong;
    }
    if (embeds.len > max_message_embeds) return error.TooManyEmbeds;
    for (embeds) |embed| try embed.validate();
    if (sticker_ids.len > max_message_stickers) return error.TooManyStickers;
    if (allowed_mentions) |mentions| try mentions.validate();
    try Interactions.Component.validateLayout(components);

    if (flags) |bits| {
        if ((bits & MessageFlags.is_components_v2) != 0) {
            var has_non_component_body = embeds.len != 0 or
                sticker_ids.len != 0 or
                poll != null or
                shared_client_theme != null;
            if (content) |value| has_non_component_body = has_non_component_body or value.len != 0;
            if (has_non_component_body) return error.ComponentsV2Exclusive;
        }
    }
}

pub const CreateMessage = struct {
    content: []const u8 = "",
    nonce: ?[]const u8 = null,
    enforce_nonce: bool = false,
    tts: bool = false,
    flags: ?MessageFlags.Bit = null,
    embeds: []const Embed = &.{},
    sticker_ids: []const Snowflake = &.{},
    allowed_mentions: ?AllowedMentions = null,
    components: []const Interactions.Component = &.{},
    message_reference: ?MessageReference = null,
    poll: ?CreatePoll = null,
    shared_client_theme: ?SharedClientTheme = null,

    pub fn init(content: []const u8) CreateMessage {
        return .{ .content = content };
    }

    pub fn empty() CreateMessage {
        return .{};
    }

    pub fn withNonce(self: CreateMessage, nonce: []const u8, enforce: bool) CreateMessage {
        var message = self;
        message.nonce = nonce;
        message.enforce_nonce = enforce;
        return message;
    }

    pub fn ttsState(self: CreateMessage, tts: bool) CreateMessage {
        var message = self;
        message.tts = tts;
        return message;
    }

    pub fn withFlags(self: CreateMessage, flags: MessageFlags.Bit) CreateMessage {
        var message = self;
        message.flags = flags;
        return message;
    }

    pub fn withEmbeds(self: CreateMessage, embeds: []const Embed) CreateMessage {
        var message = self;
        message.embeds = embeds;
        return message;
    }

    pub fn withStickers(self: CreateMessage, sticker_ids: []const Snowflake) CreateMessage {
        var message = self;
        message.sticker_ids = sticker_ids;
        return message;
    }

    pub fn withAllowedMentions(self: CreateMessage, allowed_mentions: AllowedMentions) CreateMessage {
        var message = self;
        message.allowed_mentions = allowed_mentions;
        return message;
    }

    pub fn withComponents(self: CreateMessage, components: []const Interactions.Component) CreateMessage {
        var message = self;
        message.components = components;
        return message;
    }

    pub fn withReference(self: CreateMessage, message_reference: MessageReference) CreateMessage {
        var message = self;
        message.message_reference = message_reference;
        return message;
    }

    pub fn withPoll(self: CreateMessage, poll: CreatePoll) CreateMessage {
        var message = self;
        message.poll = poll;
        return message;
    }

    pub fn withSharedClientTheme(self: CreateMessage, shared_client_theme: SharedClientTheme) CreateMessage {
        var message = self;
        message.shared_client_theme = shared_client_theme;
        return message;
    }

    pub fn validate(self: CreateMessage) MessageValidationError!void {
        try validateMessagePayload(
            if (self.content.len != 0) self.content else null,
            self.flags,
            self.embeds,
            self.sticker_ids,
            self.allowed_mentions,
            self.components,
            self.poll,
            self.shared_client_theme,
        );
        if (self.nonce) |nonce| {
            const len = try Json.codepointLen(nonce);
            if (len > max_message_nonce_len) return error.NonceTooLong;
        }
    }

    pub fn writeJson(self: CreateMessage, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        try writeMessagePayloadFields(.{
            .content = if (self.content.len != 0) self.content else null,
            .embeds = self.embeds,
            .sticker_ids = self.sticker_ids,
            .allowed_mentions = self.allowed_mentions,
            .components = self.components,
            .poll = self.poll,
            .flags = self.flags,
            .shared_client_theme = self.shared_client_theme,
        }, writer, &needs_comma);
        if (self.nonce) |nonce| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"nonce\":");
            try Json.writeString(nonce, writer);
        }
        if (self.enforce_nonce) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"enforce_nonce\":true");
        }
        if (self.tts) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"tts\":true");
        }
        if (self.message_reference) |reference| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"message_reference\":");
            try reference.writeJson(writer);
        }
        try writer.writeByte('}');
    }
};

pub const ListMessages = struct {
    around: ?Snowflake = null,
    before: ?Snowflake = null,
    after: ?Snowflake = null,
    limit: ?u8 = null,

    pub fn init() ListMessages {
        return .{};
    }

    pub fn aroundMessage(message_id: Snowflake) ListMessages {
        return .{ .around = message_id };
    }

    pub fn beforeMessage(message_id: Snowflake) ListMessages {
        return .{ .before = message_id };
    }

    pub fn afterMessage(message_id: Snowflake) ListMessages {
        return .{ .after = message_id };
    }

    pub fn withLimit(self: ListMessages, limit: u8) ListMessages {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn hasQuery(self: ListMessages) bool {
        return self.around != null or self.before != null or self.after != null or self.limit != null;
    }

    pub fn writeQuery(self: ListMessages, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.around) |around| try writeSnowflakeQueryParam(writer, &needs_ampersand, "around", around);
        if (self.before) |before| try writeSnowflakeQueryParam(writer, &needs_ampersand, "before", before);
        if (self.after) |after| try writeSnowflakeQueryParam(writer, &needs_ampersand, "after", after);
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
    }
};

pub const ListReactions = struct {
    after: ?Snowflake = null,
    limit: ?u8 = null,
    type: ?ReactionType = null,

    pub fn init() ListReactions {
        return .{};
    }

    pub fn afterUser(user_id: Snowflake) ListReactions {
        return .{ .after = user_id };
    }

    pub fn withLimit(self: ListReactions, limit: u8) ListReactions {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn withType(self: ListReactions, reaction_type: ReactionType) ListReactions {
        var options = self;
        options.type = reaction_type;
        return options;
    }

    pub fn hasQuery(self: ListReactions) bool {
        return self.after != null or self.limit != null or self.type != null;
    }

    pub fn writeQuery(self: ListReactions, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.after) |after| try writeSnowflakeQueryParam(writer, &needs_ampersand, "after", after);
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
        if (self.type) |reaction_type| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("type={d}", .{@intFromEnum(reaction_type)});
        }
    }
};

pub const ListPollAnswerVoters = struct {
    after: ?Snowflake = null,
    limit: ?u8 = null,

    pub fn init() ListPollAnswerVoters {
        return .{};
    }

    pub fn afterUser(user_id: Snowflake) ListPollAnswerVoters {
        return .{ .after = user_id };
    }

    pub fn withLimit(self: ListPollAnswerVoters, limit: u8) ListPollAnswerVoters {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn hasQuery(self: ListPollAnswerVoters) bool {
        return self.after != null or self.limit != null;
    }

    pub fn writeQuery(self: ListPollAnswerVoters, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.after) |after| try writeSnowflakeQueryParam(writer, &needs_ampersand, "after", after);
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
    }
};

pub const ListArchivedThreads = struct {
    before: ?[]const u8 = null,
    limit: ?u8 = null,

    pub fn init() ListArchivedThreads {
        return .{};
    }

    pub fn beforeTimestamp(before: []const u8) ListArchivedThreads {
        return .{ .before = before };
    }

    pub fn withLimit(self: ListArchivedThreads, limit: u8) ListArchivedThreads {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn hasQuery(self: ListArchivedThreads) bool {
        return self.before != null or self.limit != null;
    }

    pub fn writeQuery(self: ListArchivedThreads, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.before) |before| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.writeAll("before=");
            try writeQueryStringValue(before, writer);
        }
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
    }
};

pub const ListThreadMembers = struct {
    with_member: ?bool = null,
    after: ?Snowflake = null,
    limit: ?u16 = null,

    pub fn init() ListThreadMembers {
        return .{};
    }

    pub fn withMemberExpansion(self: ListThreadMembers, with_member: bool) ListThreadMembers {
        var options = self;
        options.with_member = with_member;
        return options;
    }

    pub fn afterMember(self: ListThreadMembers, user_id: Snowflake) ListThreadMembers {
        var options = self;
        options.after = user_id;
        return options;
    }

    pub fn withLimit(self: ListThreadMembers, limit: u16) ListThreadMembers {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn hasQuery(self: ListThreadMembers) bool {
        return self.with_member != null or self.after != null or self.limit != null;
    }

    pub fn writeQuery(self: ListThreadMembers, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.with_member) |with_member| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("with_member={}", .{with_member});
        }
        if (self.after) |after| try writeSnowflakeQueryParam(writer, &needs_ampersand, "after", after);
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
    }
};

pub const ListChannelPins = struct {
    before: ?[]const u8 = null,
    limit: ?u8 = null,

    pub fn init() ListChannelPins {
        return .{};
    }

    pub fn beforeTimestamp(before: []const u8) ListChannelPins {
        return .{ .before = before };
    }

    pub fn withLimit(self: ListChannelPins, limit: u8) ListChannelPins {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn hasQuery(self: ListChannelPins) bool {
        return self.before != null or self.limit != null;
    }

    pub fn writeQuery(self: ListChannelPins, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.before) |before| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.writeAll("before=");
            try writeQueryStringValue(before, writer);
        }
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
    }
};

pub const EditMessage = struct {
    content: ?[]const u8 = null,
    flags: ?MessageFlags.Bit = null,
    embeds: []const Embed = &.{},
    allowed_mentions: ?AllowedMentions = null,
    components: []const Interactions.Component = &.{},

    pub fn init() EditMessage {
        return .{};
    }

    pub fn withContent(self: EditMessage, content: []const u8) EditMessage {
        var message = self;
        message.content = content;
        return message;
    }

    pub fn withFlags(self: EditMessage, flags: MessageFlags.Bit) EditMessage {
        var message = self;
        message.flags = flags;
        return message;
    }

    pub fn withEmbeds(self: EditMessage, embeds: []const Embed) EditMessage {
        var message = self;
        message.embeds = embeds;
        return message;
    }

    pub fn withAllowedMentions(self: EditMessage, allowed_mentions: AllowedMentions) EditMessage {
        var message = self;
        message.allowed_mentions = allowed_mentions;
        return message;
    }

    pub fn withComponents(self: EditMessage, components: []const Interactions.Component) EditMessage {
        var message = self;
        message.components = components;
        return message;
    }

    pub fn validate(self: EditMessage) MessageValidationError!void {
        try validateMessagePayload(
            self.content,
            self.flags,
            self.embeds,
            &.{},
            self.allowed_mentions,
            self.components,
            null,
            null,
        );
    }

    pub fn writeJson(self: EditMessage, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;
        try writeMessagePayloadFields(.{
            .content = self.content,
            .embeds = self.embeds,
            .allowed_mentions = self.allowed_mentions,
            .components = self.components,
            .flags = self.flags,
        }, writer, &needs_comma);
        try writer.writeByte('}');
    }
};
