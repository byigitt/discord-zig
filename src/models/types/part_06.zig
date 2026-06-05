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

pub const EditCurrentUserVoiceState = struct {
    channel_id: ?Snowflake = null,
    suppress: ?bool = null,
    request_to_speak_timestamp: ?[]const u8 = null,
    clear_request_to_speak_timestamp: bool = false,

    pub fn init() EditCurrentUserVoiceState {
        return .{};
    }

    pub fn withChannel(self: EditCurrentUserVoiceState, channel_id: Snowflake) EditCurrentUserVoiceState {
        var payload = self;
        payload.channel_id = channel_id;
        return payload;
    }

    pub fn suppressState(self: EditCurrentUserVoiceState, suppress: bool) EditCurrentUserVoiceState {
        var payload = self;
        payload.suppress = suppress;
        return payload;
    }

    pub fn requestToSpeakAt(self: EditCurrentUserVoiceState, timestamp: []const u8) EditCurrentUserVoiceState {
        var payload = self;
        payload.request_to_speak_timestamp = timestamp;
        payload.clear_request_to_speak_timestamp = false;
        return payload;
    }

    pub fn clearRequestToSpeak(self: EditCurrentUserVoiceState) EditCurrentUserVoiceState {
        var payload = self;
        payload.request_to_speak_timestamp = null;
        payload.clear_request_to_speak_timestamp = true;
        return payload;
    }

    pub fn writeJson(self: EditCurrentUserVoiceState, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        if (self.channel_id) |channel_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"channel_id\":\"{d}\"", .{channel_id.value});
        }
        try writeOptionalBoolField(writer, &needs_comma, "suppress", self.suppress);
        if (self.clear_request_to_speak_timestamp) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"request_to_speak_timestamp\":null");
        } else {
            try writeOptionalStringField(
                writer,
                &needs_comma,
                "request_to_speak_timestamp",
                self.request_to_speak_timestamp,
            );
        }

        try writer.writeByte('}');
    }
};

pub const EditUserVoiceState = struct {
    channel_id: ?Snowflake = null,
    suppress: ?bool = null,

    pub fn init() EditUserVoiceState {
        return .{};
    }

    pub fn withChannel(self: EditUserVoiceState, channel_id: Snowflake) EditUserVoiceState {
        var payload = self;
        payload.channel_id = channel_id;
        return payload;
    }

    pub fn suppressState(self: EditUserVoiceState, suppress: bool) EditUserVoiceState {
        var payload = self;
        payload.suppress = suppress;
        return payload;
    }

    pub fn writeJson(self: EditUserVoiceState, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        if (self.channel_id) |channel_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"channel_id\":\"{d}\"", .{channel_id.value});
        }
        try writeOptionalBoolField(writer, &needs_comma, "suppress", self.suppress);

        try writer.writeByte('}');
    }
};

pub const EditCurrentApplication = struct {
    custom_install_url: ?[]const u8 = null,
    description: ?[]const u8 = null,
    role_connections_verification_url: ?[]const u8 = null,
    install_params: ?ApplicationInstallParams = null,
    flags: ?u32 = null,
    icon: ?[]const u8 = null,
    clear_icon: bool = false,
    cover_image: ?[]const u8 = null,
    clear_cover_image: bool = false,
    interactions_endpoint_url: ?[]const u8 = null,
    tags: ?[]const []const u8 = null,
    event_webhooks_url: ?[]const u8 = null,
    event_webhooks_status: ?ApplicationEventWebhookStatus = null,
    event_webhooks_types: ?[]const []const u8 = null,

    pub fn init() EditCurrentApplication {
        return .{};
    }

    pub fn withCustomInstallUrl(self: EditCurrentApplication, custom_install_url: []const u8) EditCurrentApplication {
        var payload = self;
        payload.custom_install_url = custom_install_url;
        return payload;
    }

    pub fn withDescription(self: EditCurrentApplication, description: []const u8) EditCurrentApplication {
        var payload = self;
        payload.description = description;
        return payload;
    }

    pub fn withRoleConnectionsVerificationUrl(self: EditCurrentApplication, role_connections_verification_url: []const u8) EditCurrentApplication {
        var payload = self;
        payload.role_connections_verification_url = role_connections_verification_url;
        return payload;
    }

    pub fn withInstallParams(self: EditCurrentApplication, install_params: ApplicationInstallParams) EditCurrentApplication {
        var payload = self;
        payload.install_params = install_params;
        return payload;
    }

    pub fn withFlags(self: EditCurrentApplication, flags: u32) EditCurrentApplication {
        var payload = self;
        payload.flags = flags;
        return payload;
    }

    pub fn withIcon(self: EditCurrentApplication, icon: []const u8) EditCurrentApplication {
        var payload = self;
        payload.icon = icon;
        payload.clear_icon = false;
        return payload;
    }

    pub fn clearIcon(self: EditCurrentApplication) EditCurrentApplication {
        var payload = self;
        payload.icon = null;
        payload.clear_icon = true;
        return payload;
    }

    pub fn withCoverImage(self: EditCurrentApplication, cover_image: []const u8) EditCurrentApplication {
        var payload = self;
        payload.cover_image = cover_image;
        payload.clear_cover_image = false;
        return payload;
    }

    pub fn clearCoverImage(self: EditCurrentApplication) EditCurrentApplication {
        var payload = self;
        payload.cover_image = null;
        payload.clear_cover_image = true;
        return payload;
    }

    pub fn withInteractionsEndpointUrl(self: EditCurrentApplication, interactions_endpoint_url: []const u8) EditCurrentApplication {
        var payload = self;
        payload.interactions_endpoint_url = interactions_endpoint_url;
        return payload;
    }

    pub fn withTags(self: EditCurrentApplication, tags: []const []const u8) EditCurrentApplication {
        var payload = self;
        payload.tags = tags;
        return payload;
    }

    pub fn withEventWebhooksUrl(self: EditCurrentApplication, event_webhooks_url: []const u8) EditCurrentApplication {
        var payload = self;
        payload.event_webhooks_url = event_webhooks_url;
        return payload;
    }

    pub fn withEventWebhooksStatus(self: EditCurrentApplication, event_webhooks_status: ApplicationEventWebhookStatus) EditCurrentApplication {
        var payload = self;
        payload.event_webhooks_status = event_webhooks_status;
        return payload;
    }

    pub fn withEventWebhookTypes(self: EditCurrentApplication, event_webhooks_types: []const []const u8) EditCurrentApplication {
        var payload = self;
        payload.event_webhooks_types = event_webhooks_types;
        return payload;
    }

    pub fn writeJson(self: EditCurrentApplication, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeOptionalStringField(writer, &needs_comma, "custom_install_url", self.custom_install_url);
        try writeOptionalStringField(writer, &needs_comma, "description", self.description);
        try writeOptionalStringField(
            writer,
            &needs_comma,
            "role_connections_verification_url",
            self.role_connections_verification_url,
        );
        if (self.install_params) |install_params| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"install_params\":");
            try install_params.writeJson(writer);
        }
        if (self.flags) |flags| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"flags\":{d}", .{flags});
        }
        if (self.clear_icon) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"icon\":null");
        } else {
            try writeOptionalStringField(writer, &needs_comma, "icon", self.icon);
        }
        if (self.clear_cover_image) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"cover_image\":null");
        } else {
            try writeOptionalStringField(writer, &needs_comma, "cover_image", self.cover_image);
        }
        try writeOptionalStringField(writer, &needs_comma, "interactions_endpoint_url", self.interactions_endpoint_url);
        if (self.tags) |tags| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"tags\":");
            try writeStringArray(tags, writer);
        }
        try writeOptionalStringField(writer, &needs_comma, "event_webhooks_url", self.event_webhooks_url);
        if (self.event_webhooks_status) |status| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"event_webhooks_status\":{d}", .{@intFromEnum(status)});
        }
        if (self.event_webhooks_types) |event_types| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"event_webhooks_types\":");
            try writeStringArray(event_types, writer);
        }

        try writer.writeByte('}');
    }
};

pub const OAuth2TokenRequest = struct {
    grant_type: []const u8,
    code: ?[]const u8 = null,
    refresh_token: ?[]const u8 = null,
    redirect_uri: ?[]const u8 = null,
    client_id: ?[]const u8 = null,
    client_secret: ?[]const u8 = null,
    scope: ?[]const u8 = null,
    code_verifier: ?[]const u8 = null,

    pub fn init(grant_type: []const u8) OAuth2TokenRequest {
        return .{ .grant_type = grant_type };
    }

    pub fn authorizationCode(code: []const u8) OAuth2TokenRequest {
        return .{ .grant_type = "authorization_code", .code = code };
    }

    pub fn refreshToken(refresh_token: []const u8) OAuth2TokenRequest {
        return .{ .grant_type = "refresh_token", .refresh_token = refresh_token };
    }

    pub fn withCode(self: OAuth2TokenRequest, code: []const u8) OAuth2TokenRequest {
        var payload = self;
        payload.code = code;
        return payload;
    }

    pub fn withRefreshToken(self: OAuth2TokenRequest, refresh_token: []const u8) OAuth2TokenRequest {
        var payload = self;
        payload.refresh_token = refresh_token;
        return payload;
    }

    pub fn withRedirectUri(self: OAuth2TokenRequest, redirect_uri: []const u8) OAuth2TokenRequest {
        var payload = self;
        payload.redirect_uri = redirect_uri;
        return payload;
    }

    pub fn withClientId(self: OAuth2TokenRequest, client_id: []const u8) OAuth2TokenRequest {
        var payload = self;
        payload.client_id = client_id;
        return payload;
    }

    pub fn withClientSecret(self: OAuth2TokenRequest, client_secret: []const u8) OAuth2TokenRequest {
        var payload = self;
        payload.client_secret = client_secret;
        return payload;
    }

    pub fn withScope(self: OAuth2TokenRequest, scope: []const u8) OAuth2TokenRequest {
        var payload = self;
        payload.scope = scope;
        return payload;
    }

    pub fn withCodeVerifier(self: OAuth2TokenRequest, code_verifier: []const u8) OAuth2TokenRequest {
        var payload = self;
        payload.code_verifier = code_verifier;
        return payload;
    }

    pub fn writeForm(self: OAuth2TokenRequest, writer: anytype) !void {
        var needs_ampersand = false;
        try writeStringQueryParam(writer, &needs_ampersand, "grant_type", self.grant_type);
        try writeOptionalStringQueryParam(writer, &needs_ampersand, "code", self.code);
        try writeOptionalStringQueryParam(writer, &needs_ampersand, "refresh_token", self.refresh_token);
        try writeOptionalStringQueryParam(writer, &needs_ampersand, "redirect_uri", self.redirect_uri);
        try writeOptionalStringQueryParam(writer, &needs_ampersand, "client_id", self.client_id);
        try writeOptionalStringQueryParam(writer, &needs_ampersand, "client_secret", self.client_secret);
        try writeOptionalStringQueryParam(writer, &needs_ampersand, "scope", self.scope);
        try writeOptionalStringQueryParam(writer, &needs_ampersand, "code_verifier", self.code_verifier);
    }
};

pub const OAuth2TokenRevocation = struct {
    token: []const u8,
    token_type_hint: ?[]const u8 = null,
    client_id: ?[]const u8 = null,
    client_secret: ?[]const u8 = null,

    pub fn init(token: []const u8) OAuth2TokenRevocation {
        return .{ .token = token };
    }

    pub fn withTokenTypeHint(self: OAuth2TokenRevocation, token_type_hint: []const u8) OAuth2TokenRevocation {
        var payload = self;
        payload.token_type_hint = token_type_hint;
        return payload;
    }

    pub fn withClientId(self: OAuth2TokenRevocation, client_id: []const u8) OAuth2TokenRevocation {
        var payload = self;
        payload.client_id = client_id;
        return payload;
    }

    pub fn withClientSecret(self: OAuth2TokenRevocation, client_secret: []const u8) OAuth2TokenRevocation {
        var payload = self;
        payload.client_secret = client_secret;
        return payload;
    }

    pub fn writeForm(self: OAuth2TokenRevocation, writer: anytype) !void {
        var needs_ampersand = false;
        try writeStringQueryParam(writer, &needs_ampersand, "token", self.token);
        try writeOptionalStringQueryParam(writer, &needs_ampersand, "token_type_hint", self.token_type_hint);
        try writeOptionalStringQueryParam(writer, &needs_ampersand, "client_id", self.client_id);
        try writeOptionalStringQueryParam(writer, &needs_ampersand, "client_secret", self.client_secret);
    }
};

pub const AuditLogEvent = enum(u16) {
    guild_update = 1,
    channel_create = 10,
    channel_update = 11,
    channel_delete = 12,
    channel_overwrite_create = 13,
    channel_overwrite_update = 14,
    channel_overwrite_delete = 15,
    member_kick = 20,
    member_prune = 21,
    member_ban_add = 22,
    member_ban_remove = 23,
    member_update = 24,
    member_role_update = 25,
    member_move = 26,
    member_disconnect = 27,
    bot_add = 28,
    role_create = 30,
    role_update = 31,
    role_delete = 32,
    invite_create = 40,
    invite_update = 41,
    invite_delete = 42,
    webhook_create = 50,
    webhook_update = 51,
    webhook_delete = 52,
    emoji_create = 60,
    emoji_update = 61,
    emoji_delete = 62,
    message_delete = 72,
    message_bulk_delete = 73,
    message_pin = 74,
    message_unpin = 75,
    integration_create = 80,
    integration_update = 81,
    integration_delete = 82,
    stage_instance_create = 83,
    stage_instance_update = 84,
    stage_instance_delete = 85,
    sticker_create = 90,
    sticker_update = 91,
    sticker_delete = 92,
    guild_scheduled_event_create = 100,
    guild_scheduled_event_update = 101,
    guild_scheduled_event_delete = 102,
    thread_create = 110,
    thread_update = 111,
    thread_delete = 112,
    application_command_permission_update = 121,
    auto_moderation_rule_create = 140,
    auto_moderation_rule_update = 141,
    auto_moderation_rule_delete = 142,
    auto_moderation_block_message = 143,
    auto_moderation_flag_to_channel = 144,
    auto_moderation_user_communication_disabled = 145,
    creator_monetization_request_created = 150,
    creator_monetization_terms_accepted = 151,
    onboarding_prompt_create = 163,
    onboarding_prompt_update = 164,
    onboarding_prompt_delete = 165,
    onboarding_create = 166,
    onboarding_update = 167,
    home_settings_create = 190,
    home_settings_update = 191,
};

pub const ListAuditLog = struct {
    user_id: ?Snowflake = null,
    action_type: ?u16 = null,
    before: ?Snowflake = null,
    after: ?Snowflake = null,
    limit: ?u8 = null,

    pub fn init() ListAuditLog {
        return .{};
    }

    pub fn forUser(self: ListAuditLog, user_id: Snowflake) ListAuditLog {
        var options = self;
        options.user_id = user_id;
        return options;
    }

    pub fn withActionType(self: ListAuditLog, action_type: u16) ListAuditLog {
        var options = self;
        options.action_type = action_type;
        return options;
    }

    pub fn withAuditEvent(self: ListAuditLog, event: AuditLogEvent) ListAuditLog {
        var options = self;
        options.action_type = @intFromEnum(event);
        return options;
    }

    pub fn beforeEntry(self: ListAuditLog, entry_id: Snowflake) ListAuditLog {
        var options = self;
        options.before = entry_id;
        return options;
    }

    pub fn afterEntry(self: ListAuditLog, entry_id: Snowflake) ListAuditLog {
        var options = self;
        options.after = entry_id;
        return options;
    }

    pub fn withLimit(self: ListAuditLog, limit: u8) ListAuditLog {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn hasQuery(self: ListAuditLog) bool {
        return self.user_id != null or
            self.action_type != null or
            self.before != null or
            self.after != null or
            self.limit != null;
    }

    pub fn writeQuery(self: ListAuditLog, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.user_id) |user_id| try writeSnowflakeQueryParam(writer, &needs_ampersand, "user_id", user_id);
        if (self.action_type) |action_type| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("action_type={d}", .{action_type});
        }
        if (self.before) |before| try writeSnowflakeQueryParam(writer, &needs_ampersand, "before", before);
        if (self.after) |after| try writeSnowflakeQueryParam(writer, &needs_ampersand, "after", after);
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
    }
};

pub const ListCurrentUserGuilds = struct {
    before: ?Snowflake = null,
    after: ?Snowflake = null,
    limit: ?u8 = null,
    with_counts: ?bool = null,

    pub fn init() ListCurrentUserGuilds {
        return .{};
    }

    pub fn beforeGuild(self: ListCurrentUserGuilds, guild_id: Snowflake) ListCurrentUserGuilds {
        var options = self;
        options.before = guild_id;
        return options;
    }

    pub fn afterGuild(self: ListCurrentUserGuilds, guild_id: Snowflake) ListCurrentUserGuilds {
        var options = self;
        options.after = guild_id;
        return options;
    }

    pub fn withLimit(self: ListCurrentUserGuilds, limit: u8) ListCurrentUserGuilds {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn withCounts(self: ListCurrentUserGuilds, with_counts: bool) ListCurrentUserGuilds {
        var options = self;
        options.with_counts = with_counts;
        return options;
    }

    pub fn hasQuery(self: ListCurrentUserGuilds) bool {
        return self.before != null or
            self.after != null or
            self.limit != null or
            self.with_counts != null;
    }

    pub fn writeQuery(self: ListCurrentUserGuilds, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.before) |before| try writeSnowflakeQueryParam(writer, &needs_ampersand, "before", before);
        if (self.after) |after| try writeSnowflakeQueryParam(writer, &needs_ampersand, "after", after);
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
        if (self.with_counts) |with_counts| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.writeAll("with_counts=");
            try writer.writeAll(if (with_counts) "true" else "false");
        }
    }
};

pub const GetGuild = struct {
    with_counts: ?bool = null,

    pub fn init() GetGuild {
        return .{};
    }

    pub fn withCounts(self: GetGuild, with_counts: bool) GetGuild {
        var options = self;
        options.with_counts = with_counts;
        return options;
    }

    pub fn hasQuery(self: GetGuild) bool {
        return self.with_counts != null;
    }

    pub fn writeQuery(self: GetGuild, writer: anytype) !void {
        var needs_ampersand = false;
        if (self.with_counts) |with_counts| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.writeAll("with_counts=");
            try writer.writeAll(if (with_counts) "true" else "false");
        }
    }
};
