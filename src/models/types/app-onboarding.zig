const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Json = @import("../../core/json.zig");

const Root = @import("../types.zig");
const User = Root.User;
const OnboardingMode = Root.OnboardingMode;
const OnboardingPromptType = Root.OnboardingPromptType;
const writeSnowflakeStringArray = Root.writeSnowflakeStringArray;
const writeOnboardingPromptOptionArray = Root.writeOnboardingPromptOptionArray;
const writeOnboardingPromptArray = Root.writeOnboardingPromptArray;
const writeSnowflakeCommaList = Root.writeSnowflakeCommaList;
const writeOptionalStringField = Root.writeOptionalStringField;
const writeOptionalBoolField = Root.writeOptionalBoolField;
const writeSnowflakeQueryParam = Root.writeSnowflakeQueryParam;
const writeOptionalBoolQueryParam = Root.writeOptionalBoolQueryParam;
const writeQuerySeparator = Root.writeQuerySeparator;
const writeComma = Root.writeComma;

pub const OnboardingPromptOption = struct {
    id: ?Snowflake = null,
    channel_ids: []const Snowflake = &.{},
    role_ids: []const Snowflake = &.{},
    emoji_id: ?Snowflake = null,
    emoji_name: ?[]const u8 = null,
    emoji_animated: ?bool = null,
    title: []const u8,
    description: ?[]const u8 = null,

    pub fn init(title: []const u8) OnboardingPromptOption {
        return .{ .title = title };
    }

    pub fn withId(self: OnboardingPromptOption, id: Snowflake) OnboardingPromptOption {
        var option = self;
        option.id = id;
        return option;
    }

    pub fn withChannels(self: OnboardingPromptOption, channel_ids: []const Snowflake) OnboardingPromptOption {
        var option = self;
        option.channel_ids = channel_ids;
        return option;
    }

    pub fn withRoles(self: OnboardingPromptOption, role_ids: []const Snowflake) OnboardingPromptOption {
        var option = self;
        option.role_ids = role_ids;
        return option;
    }

    pub fn withEmojiId(self: OnboardingPromptOption, emoji_id: Snowflake) OnboardingPromptOption {
        var option = self;
        option.emoji_id = emoji_id;
        return option;
    }

    pub fn withEmojiName(self: OnboardingPromptOption, emoji_name: []const u8) OnboardingPromptOption {
        var option = self;
        option.emoji_name = emoji_name;
        return option;
    }

    pub fn emojiAnimatedState(self: OnboardingPromptOption, emoji_animated: bool) OnboardingPromptOption {
        var option = self;
        option.emoji_animated = emoji_animated;
        return option;
    }

    pub fn withDescription(self: OnboardingPromptOption, description: []const u8) OnboardingPromptOption {
        var option = self;
        option.description = description;
        return option;
    }

    pub fn writeJson(self: OnboardingPromptOption, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        if (self.id) |id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"id\":\"{d}\"", .{id.value});
        }
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"channel_ids\":");
        try writeSnowflakeStringArray(self.channel_ids, writer);
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"role_ids\":");
        try writeSnowflakeStringArray(self.role_ids, writer);
        if (self.emoji_id) |emoji_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"emoji_id\":\"{d}\"", .{emoji_id.value});
        }
        try writeOptionalStringField(writer, &needs_comma, "emoji_name", self.emoji_name);
        try writeOptionalBoolField(writer, &needs_comma, "emoji_animated", self.emoji_animated);
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"title\":");
        try Json.writeString(self.title, writer);
        try writeOptionalStringField(writer, &needs_comma, "description", self.description);

        try writer.writeByte('}');
    }
};

pub const OnboardingPrompt = struct {
    id: ?Snowflake = null,
    type: OnboardingPromptType = .multiple_choice,
    options: []const OnboardingPromptOption = &.{},
    title: []const u8,
    single_select: bool = false,
    required: bool = false,
    in_onboarding: bool = true,

    pub fn init(title: []const u8) OnboardingPrompt {
        return .{ .title = title };
    }

    pub fn withId(self: OnboardingPrompt, id: Snowflake) OnboardingPrompt {
        var prompt = self;
        prompt.id = id;
        return prompt;
    }

    pub fn withType(self: OnboardingPrompt, prompt_type: OnboardingPromptType) OnboardingPrompt {
        var prompt = self;
        prompt.type = prompt_type;
        return prompt;
    }

    pub fn withOptions(self: OnboardingPrompt, options: []const OnboardingPromptOption) OnboardingPrompt {
        var prompt = self;
        prompt.options = options;
        return prompt;
    }

    pub fn singleSelectState(self: OnboardingPrompt, single_select: bool) OnboardingPrompt {
        var prompt = self;
        prompt.single_select = single_select;
        return prompt;
    }

    pub fn requiredState(self: OnboardingPrompt, required: bool) OnboardingPrompt {
        var prompt = self;
        prompt.required = required;
        return prompt;
    }

    pub fn inOnboardingState(self: OnboardingPrompt, in_onboarding: bool) OnboardingPrompt {
        var prompt = self;
        prompt.in_onboarding = in_onboarding;
        return prompt;
    }

    pub fn writeJson(self: OnboardingPrompt, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        if (self.id) |id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"id\":\"{d}\"", .{id.value});
        }
        try writeComma(writer, &needs_comma);
        try writer.print("\"type\":{d}", .{@intFromEnum(self.type)});
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"options\":");
        try writeOnboardingPromptOptionArray(self.options, writer);
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"title\":");
        try Json.writeString(self.title, writer);
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"single_select\":");
        try writer.writeAll(if (self.single_select) "true" else "false");
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"required\":");
        try writer.writeAll(if (self.required) "true" else "false");
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"in_onboarding\":");
        try writer.writeAll(if (self.in_onboarding) "true" else "false");

        try writer.writeByte('}');
    }
};

pub const EditGuildOnboarding = struct {
    prompts: ?[]const OnboardingPrompt = null,
    default_channel_ids: ?[]const Snowflake = null,
    enabled: ?bool = null,
    mode: ?OnboardingMode = null,

    pub fn init() EditGuildOnboarding {
        return .{};
    }

    pub fn withPrompts(self: EditGuildOnboarding, prompts: []const OnboardingPrompt) EditGuildOnboarding {
        var payload = self;
        payload.prompts = prompts;
        return payload;
    }

    pub fn withDefaultChannels(self: EditGuildOnboarding, default_channel_ids: []const Snowflake) EditGuildOnboarding {
        var payload = self;
        payload.default_channel_ids = default_channel_ids;
        return payload;
    }

    pub fn enabledState(self: EditGuildOnboarding, enabled: bool) EditGuildOnboarding {
        var payload = self;
        payload.enabled = enabled;
        return payload;
    }

    pub fn withMode(self: EditGuildOnboarding, mode: OnboardingMode) EditGuildOnboarding {
        var payload = self;
        payload.mode = mode;
        return payload;
    }

    pub fn writeJson(self: EditGuildOnboarding, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        if (self.prompts) |prompts| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"prompts\":");
            try writeOnboardingPromptArray(prompts, writer);
        }
        if (self.default_channel_ids) |ids| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"default_channel_ids\":");
            try writeSnowflakeStringArray(ids, writer);
        }
        try writeOptionalBoolField(writer, &needs_comma, "enabled", self.enabled);
        if (self.mode) |mode| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"mode\":{d}", .{@intFromEnum(mode)});
        }

        try writer.writeByte('}');
    }
};

pub const WelcomeScreen = struct {
    description: ?[]const u8 = null,
    welcome_channels: []const WelcomeScreenChannel = &.{},
};

pub const WelcomeScreenChannel = struct {
    channel_id: Snowflake,
    description: []const u8,
    emoji_id: ?Snowflake = null,
    emoji_name: ?[]const u8 = null,

    pub fn init(channel_id: Snowflake, description: []const u8) WelcomeScreenChannel {
        return .{
            .channel_id = channel_id,
            .description = description,
        };
    }

    pub fn withEmojiId(self: WelcomeScreenChannel, emoji_id: Snowflake) WelcomeScreenChannel {
        var channel = self;
        channel.emoji_id = emoji_id;
        channel.emoji_name = null;
        return channel;
    }

    pub fn withEmojiName(self: WelcomeScreenChannel, emoji_name: []const u8) WelcomeScreenChannel {
        var channel = self;
        channel.emoji_id = null;
        channel.emoji_name = emoji_name;
        return channel;
    }

    pub fn writeJson(self: WelcomeScreenChannel, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.print("\"channel_id\":\"{d}\"", .{self.channel_id.value});

        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"description\":");
        try Json.writeString(self.description, writer);

        if (self.emoji_id) |emoji_id| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"emoji_id\":\"{d}\"", .{emoji_id.value});
        }
        try writeOptionalStringField(writer, &needs_comma, "emoji_name", self.emoji_name);

        try writer.writeByte('}');
    }
};

pub const PartialInvite = struct {
    code: ?[]const u8 = null,
    uses: ?u32 = null,
};

pub const ApplicationEventWebhookStatus = enum(u8) {
    disabled = 1,
    enabled = 2,
    disabled_by_discord = 3,
};

pub const ApplicationEventWebhookType = enum {
    application_authorized,
    application_deauthorized,
    entitlement_create,
    entitlement_update,
    entitlement_delete,
    quest_user_enrollment,
    lobby_message_create,
    lobby_message_update,
    lobby_message_delete,
    game_direct_message_create,
    game_direct_message_update,
    game_direct_message_delete,

    pub fn value(self: ApplicationEventWebhookType) []const u8 {
        return switch (self) {
            .application_authorized => "APPLICATION_AUTHORIZED",
            .application_deauthorized => "APPLICATION_DEAUTHORIZED",
            .entitlement_create => "ENTITLEMENT_CREATE",
            .entitlement_update => "ENTITLEMENT_UPDATE",
            .entitlement_delete => "ENTITLEMENT_DELETE",
            .quest_user_enrollment => "QUEST_USER_ENROLLMENT",
            .lobby_message_create => "LOBBY_MESSAGE_CREATE",
            .lobby_message_update => "LOBBY_MESSAGE_UPDATE",
            .lobby_message_delete => "LOBBY_MESSAGE_DELETE",
            .game_direct_message_create => "GAME_DIRECT_MESSAGE_CREATE",
            .game_direct_message_update => "GAME_DIRECT_MESSAGE_UPDATE",
            .game_direct_message_delete => "GAME_DIRECT_MESSAGE_DELETE",
        };
    }

    pub fn fromValue(raw: []const u8) ?ApplicationEventWebhookType {
        inline for (std.meta.fields(ApplicationEventWebhookType)) |field| {
            const event_type: ApplicationEventWebhookType = @enumFromInt(field.value);
            if (std.mem.eql(u8, raw, event_type.value())) return event_type;
        }
        return null;
    }
};

pub const ApplicationEventWebhookPayloadType = enum(u8) {
    ping = 0,
    event = 1,
};

pub const ApplicationEventWebhookPayload = struct {
    version: u8,
    application_id: Snowflake,
    type: ApplicationEventWebhookPayloadType,
    event: ?ApplicationEventWebhookBody = null,
};

pub const ApplicationEventWebhookBody = struct {
    type: ApplicationEventWebhookType,
    timestamp: []const u8,
};

pub const Application = struct {
    id: Snowflake,
    name: []const u8,
    icon: ?[]const u8 = null,
    cover_image: ?[]const u8 = null,
    description: []const u8 = "",
    bot_public: bool = true,
    bot_require_code_grant: bool = false,
    bot: ?User = null,
    owner: ?User = null,
    team: ?Team = null,
    verify_key: []const u8 = "",
    guild_id: ?Snowflake = null,
    flags: ?u32 = null,
    approximate_guild_count: ?u32 = null,
    approximate_user_install_count: ?u32 = null,
    interactions_endpoint_url: ?[]const u8 = null,
    role_connections_verification_url: ?[]const u8 = null,
    event_webhooks_url: ?[]const u8 = null,
    event_webhooks_status: ?ApplicationEventWebhookStatus = null,
    event_webhooks_types: []const []const u8 = &.{},
    tags: []const []const u8 = &.{},
    custom_install_url: ?[]const u8 = null,
};

pub const MembershipState = enum(u8) {
    invited = 1,
    accepted = 2,
};

pub const TeamMember = struct {
    membership_state: MembershipState,
    team_id: Snowflake,
    user: User,
    role: ?[]const u8 = null,
};

pub const Team = struct {
    id: Snowflake,
    name: []const u8,
    icon: ?[]const u8 = null,
    owner_user_id: Snowflake,
    members: []const TeamMember = &.{},
};

pub const SkuType = enum(u8) {
    durable = 2,
    consumable = 3,
    subscription = 5,
    subscription_group = 6,
};

pub const SkuFlags = struct {
    pub const Bit = u64;
    pub const available: Bit = 1 << 2;
    pub const guild_subscription: Bit = 1 << 7;
    pub const user_subscription: Bit = 1 << 8;
};

pub const UserFlags = struct {
    pub const Bit = u32;

    pub const staff: Bit = 1 << 0;
    pub const partner: Bit = 1 << 1;
    pub const hypesquad: Bit = 1 << 2;
    pub const bug_hunter_level_1: Bit = 1 << 3;
    pub const hypesquad_online_house_1: Bit = 1 << 6;
    pub const hypesquad_online_house_2: Bit = 1 << 7;
    pub const hypesquad_online_house_3: Bit = 1 << 8;
    pub const premium_early_supporter: Bit = 1 << 9;
    pub const team_pseudo_user: Bit = 1 << 10;
    pub const bug_hunter_level_2: Bit = 1 << 14;
    pub const verified_bot: Bit = 1 << 16;
    pub const verified_developer: Bit = 1 << 17;
    pub const certified_moderator: Bit = 1 << 18;
    pub const bot_http_interactions: Bit = 1 << 19;
    pub const active_developer: Bit = 1 << 22;

    pub fn has(flags: Bit, flag: Bit) bool {
        return (flags & flag) == flag;
    }
};

pub const ApplicationFlags = struct {
    pub const Bit = u32;

    pub const auto_moderation_rule_create_badge: Bit = 1 << 6;
    pub const gateway_presence: Bit = 1 << 12;
    pub const gateway_presence_limited: Bit = 1 << 13;
    pub const gateway_guild_members: Bit = 1 << 14;
    pub const gateway_guild_members_limited: Bit = 1 << 15;
    pub const verification_pending_guild_limit: Bit = 1 << 16;
    pub const embedded: Bit = 1 << 17;
    pub const gateway_message_content: Bit = 1 << 18;
    pub const gateway_message_content_limited: Bit = 1 << 19;
    pub const application_command_badge: Bit = 1 << 23;

    pub fn has(flags: Bit, flag: Bit) bool {
        return (flags & flag) == flag;
    }
};

pub const Sku = struct {
    id: Snowflake,
    type: SkuType,
    application_id: Snowflake,
    name: []const u8,
    slug: []const u8,
    flags: SkuFlags.Bit = 0,
};

pub const EntitlementType = enum(u8) {
    purchase = 1,
    premium_subscription = 2,
    developer_gift = 3,
    test_mode_purchase = 4,
    free_purchase = 5,
    user_gift = 6,
    premium_purchase = 7,
    application_subscription = 8,
};

pub const Entitlement = struct {
    id: Snowflake,
    sku_id: Snowflake,
    application_id: Snowflake,
    type: EntitlementType,
    deleted: bool,
    user_id: ?Snowflake = null,
    guild_id: ?Snowflake = null,
    starts_at: ?[]const u8 = null,
    ends_at: ?[]const u8 = null,
    consumed: ?bool = null,
};

pub const SubscriptionStatus = enum(u8) {
    active = 0,
    ending = 1,
    inactive = 2,
};

pub const Subscription = struct {
    id: Snowflake,
    user_id: Snowflake,
    sku_ids: []const Snowflake = &.{},
    entitlement_ids: []const Snowflake = &.{},
    renewal_sku_ids: []const Snowflake = &.{},
    current_period_start: []const u8,
    current_period_end: []const u8,
    status: SubscriptionStatus,
    canceled_at: ?[]const u8 = null,
    country: ?[]const u8 = null,
};

pub const ListEntitlements = struct {
    user_id: ?Snowflake = null,
    sku_ids: []const Snowflake = &.{},
    before: ?Snowflake = null,
    after: ?Snowflake = null,
    limit: ?u8 = null,
    guild_id: ?Snowflake = null,
    exclude_ended: ?bool = null,
    exclude_deleted: ?bool = null,

    pub fn init() ListEntitlements {
        return .{};
    }

    pub fn forUser(self: ListEntitlements, user_id: Snowflake) ListEntitlements {
        var options = self;
        options.user_id = user_id;
        return options;
    }

    pub fn withSkus(self: ListEntitlements, sku_ids: []const Snowflake) ListEntitlements {
        var options = self;
        options.sku_ids = sku_ids;
        return options;
    }

    pub fn beforeEntitlement(self: ListEntitlements, entitlement_id: Snowflake) ListEntitlements {
        var options = self;
        options.before = entitlement_id;
        return options;
    }

    pub fn afterEntitlement(self: ListEntitlements, entitlement_id: Snowflake) ListEntitlements {
        var options = self;
        options.after = entitlement_id;
        return options;
    }

    pub fn withLimit(self: ListEntitlements, limit: u8) ListEntitlements {
        var options = self;
        options.limit = limit;
        return options;
    }

    pub fn forGuild(self: ListEntitlements, guild_id: Snowflake) ListEntitlements {
        var options = self;
        options.guild_id = guild_id;
        return options;
    }

    pub fn excludeEnded(self: ListEntitlements, exclude_ended: bool) ListEntitlements {
        var options = self;
        options.exclude_ended = exclude_ended;
        return options;
    }

    pub fn excludeDeleted(self: ListEntitlements, exclude_deleted: bool) ListEntitlements {
        var options = self;
        options.exclude_deleted = exclude_deleted;
        return options;
    }

    pub fn hasQuery(self: ListEntitlements) bool {
        return self.user_id != null or self.sku_ids.len != 0 or self.before != null or self.after != null or
            self.limit != null or self.guild_id != null or self.exclude_ended != null or self.exclude_deleted != null;
    }

    pub fn writeQuery(self: ListEntitlements, writer: anytype) !void {
        var needs_ampersand = false;

        if (self.user_id) |user_id| try writeSnowflakeQueryParam(writer, &needs_ampersand, "user_id", user_id);
        if (self.sku_ids.len != 0) {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.writeAll("sku_ids=");
            try writeSnowflakeCommaList(self.sku_ids, writer);
        }
        if (self.before) |before| try writeSnowflakeQueryParam(writer, &needs_ampersand, "before", before);
        if (self.after) |after| try writeSnowflakeQueryParam(writer, &needs_ampersand, "after", after);
        if (self.limit) |limit| {
            try writeQuerySeparator(writer, &needs_ampersand);
            try writer.print("limit={d}", .{limit});
        }
        if (self.guild_id) |guild_id| try writeSnowflakeQueryParam(writer, &needs_ampersand, "guild_id", guild_id);
        try writeOptionalBoolQueryParam(writer, &needs_ampersand, "exclude_ended", self.exclude_ended);
        try writeOptionalBoolQueryParam(writer, &needs_ampersand, "exclude_deleted", self.exclude_deleted);
    }
};

pub const EntitlementOwnerType = enum(u8) {
    guild = 1,
    user = 2,
};

pub const CreateTestEntitlement = struct {
    sku_id: Snowflake,
    owner_id: Snowflake,
    owner_type: EntitlementOwnerType,

    pub fn init(sku_id: Snowflake, owner_id: Snowflake, owner_type: EntitlementOwnerType) CreateTestEntitlement {
        return .{ .sku_id = sku_id, .owner_id = owner_id, .owner_type = owner_type };
    }

    pub fn writeJson(self: CreateTestEntitlement, writer: anytype) !void {
        try writer.print(
            "{{\"sku_id\":\"{d}\",\"owner_id\":\"{d}\",\"owner_type\":{d}}}",
            .{ self.sku_id.value, self.owner_id.value, @intFromEnum(self.owner_type) },
        );
    }
};
