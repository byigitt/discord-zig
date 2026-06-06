const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Interactions = @import("../../interactions/mod.zig");

const Root = @import("../types.zig");
const StringPair = Root.StringPair;
const AutoModerationTriggerMetadata = Root.AutoModerationTriggerMetadata;
const AutoModerationAction = Root.AutoModerationAction;
const CreateAutoModerationRule = Root.CreateAutoModerationRule;
const EditAutoModerationRule = Root.EditAutoModerationRule;
const EditCurrentGuildMember = Root.EditCurrentGuildMember;
const EditCurrentUserNick = Root.EditCurrentUserNick;
const EditCurrentUser = Root.EditCurrentUser;
const CreateDmChannel = Root.CreateDmChannel;
const CreateThreadFromMessage = Root.CreateThreadFromMessage;
const CreateThread = Root.CreateThread;
const GetInvite = Root.GetInvite;
const LobbyMember = Root.LobbyMember;
const CreateLobby = Root.CreateLobby;
const EditLobby = Root.EditLobby;
const BulkUpdateLobbyMembers = Root.BulkUpdateLobbyMembers;
const LinkLobbyChannel = Root.LinkLobbyChannel;
const UpdateLobbyMessageModerationMetadata = Root.UpdateLobbyMessageModerationMetadata;
const CreateChannelInvite = Root.CreateChannelInvite;
const CreateWebhook = Root.CreateWebhook;
const EditWebhook = Root.EditWebhook;
const EditWebhookWithToken = Root.EditWebhookWithToken;
const ExecuteWebhook = Root.ExecuteWebhook;
const writeExecuteWebhookJsonWithAttachments = Root.writeExecuteWebhookJsonWithAttachments;
const CreateGuildBan = Root.CreateGuildBan;
const BulkGuildBan = Root.BulkGuildBan;
const MessageFlags = Root.MessageFlags;
const EmbedFooter = Root.EmbedFooter;
const EmbedAuthor = Root.EmbedAuthor;
const EmbedField = Root.EmbedField;
const Embed = Root.Embed;
const AllowedMentions = Root.AllowedMentions;
const PollEmoji = Root.PollEmoji;
const PollAnswer = Root.PollAnswer;
const CreatePoll = Root.CreatePoll;
const CreateMessage = Root.CreateMessage;
const EditMessage = Root.EditMessage;
const UploadFile = Root.UploadFile;
const EmbedBuilder = Root.EmbedBuilder;
const AttachmentBuilder = Root.AttachmentBuilder;
const AttachmentPathBuilder = Root.AttachmentPathBuilder;
const AllowedMentionsBuilder = Root.AllowedMentionsBuilder;
const PollBuilder = Root.PollBuilder;
const writeCreateMessageJsonWithAttachments = Root.writeCreateMessageJsonWithAttachments;

test "edit current guild member JSON supports profile fields and clears" {
    var update = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer update.deinit();

    try EditCurrentGuildMember.init()
        .withNick("ziggy")
        .withAvatar("data:image/png;base64,abc")
        .withBio("Built with Zig")
        .writeJson(&update.writer);
    try std.testing.expectEqualStrings(
        "{\"nick\":\"ziggy\",\"avatar\":\"data:image/png;base64,abc\",\"bio\":\"Built with Zig\"}",
        update.written(),
    );

    var clear = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear.deinit();

    try EditCurrentGuildMember.init()
        .clearNick()
        .clearAvatar()
        .clearBanner()
        .clearBio()
        .writeJson(&clear.writer);
    try std.testing.expectEqualStrings(
        "{\"nick\":null,\"avatar\":null,\"banner\":null,\"bio\":null}",
        clear.written(),
    );
}

test "edit current user nick JSON supports set and clear" {
    var set = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer set.deinit();

    try EditCurrentUserNick.init().withNick("ziggy").writeJson(&set.writer);
    try std.testing.expectEqualStrings("{\"nick\":\"ziggy\"}", set.written());

    var clear = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear.deinit();

    try EditCurrentUserNick.init().clearNick().writeJson(&clear.writer);
    try std.testing.expectEqualStrings("{\"nick\":null}", clear.written());
}

test "edit current user JSON supports username image fields and clears" {
    var update = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer update.deinit();

    try EditCurrentUser.init()
        .withUsername("zigbot")
        .withAvatar("data:image/png;base64,abc")
        .writeJson(&update.writer);
    try std.testing.expectEqualStrings(
        "{\"username\":\"zigbot\",\"avatar\":\"data:image/png;base64,abc\"}",
        update.written(),
    );

    var clear = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear.deinit();

    try EditCurrentUser.init()
        .clearAvatar()
        .clearBanner()
        .writeJson(&clear.writer);
    try std.testing.expectEqualStrings("{\"avatar\":null,\"banner\":null}", clear.written());
}

test "create guild ban JSON supports delete message seconds" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try CreateGuildBan.init().deleteMessagesFor(3600).writeJson(&out.writer);
    try std.testing.expectEqualStrings("{\"delete_message_seconds\":3600}", out.written());

    var bulk = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer bulk.deinit();

    const user_ids = [_]Snowflake{ Snowflake.init(10), Snowflake.init(20) };
    try BulkGuildBan.init(&user_ids).deleteMessagesFor(60).writeJson(&bulk.writer);
    try std.testing.expectEqualStrings(
        "{\"user_ids\":[\"10\",\"20\"],\"delete_message_seconds\":60}",
        bulk.written(),
    );
}

test "auto moderation rule JSON supports create and edit payloads" {
    const actions = [_]AutoModerationAction{
        AutoModerationAction.blockMessage("Use #finance for finance talk"),
        AutoModerationAction.sendAlertMessage(Snowflake.init(40)),
        AutoModerationAction.timeout(60),
    };
    const roles = [_]Snowflake{Snowflake.init(10)};
    const channels = [_]Snowflake{Snowflake.init(20)};

    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();

    try CreateAutoModerationRule.init("keyword guard", .keyword, &actions)
        .withTriggerMetadata(AutoModerationTriggerMetadata.init()
            .withKeywordFilter(&.{ "cat*", "*dog" })
            .withRegexPatterns(&.{"(b|c)at"})
            .withAllowList(&.{"educational cat"}))
        .enabledState(true)
        .withExemptRoles(&roles)
        .withExemptChannels(&channels)
        .writeJson(&create.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"keyword guard\",\"event_type\":1,\"trigger_type\":1,\"trigger_metadata\":{\"keyword_filter\":[\"cat*\",\"*dog\"],\"regex_patterns\":[\"(b|c)at\"],\"allow_list\":[\"educational cat\"]},\"actions\":[{\"type\":1,\"metadata\":{\"custom_message\":\"Use #finance for finance talk\"}},{\"type\":2,\"metadata\":{\"channel_id\":\"40\"}},{\"type\":3,\"metadata\":{\"duration_seconds\":60}}],\"enabled\":true,\"exempt_roles\":[\"10\"],\"exempt_channels\":[\"20\"]}",
        create.written(),
    );

    var preset = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer preset.deinit();

    try CreateAutoModerationRule.init("preset guard", .keyword_preset, &.{AutoModerationAction.blockMemberInteraction()})
        .withTriggerMetadata(AutoModerationTriggerMetadata.init().withPresets(&.{ .profanity, .slurs }))
        .writeJson(&preset.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"preset guard\",\"event_type\":1,\"trigger_type\":4,\"trigger_metadata\":{\"presets\":[1,3]},\"actions\":[{\"type\":4}]}",
        preset.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    try EditAutoModerationRule.init()
        .withName("mention guard")
        .withEventType(.member_update)
        .withTriggerMetadata(AutoModerationTriggerMetadata.init()
            .withMentionLimit(8)
            .mentionRaidProtection(true))
        .withActions(&.{AutoModerationAction.timeout(300)})
        .enabledState(false)
        .withExemptRoles(&.{})
        .withExemptChannels(&channels)
        .writeJson(&edit.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"mention guard\",\"event_type\":2,\"trigger_metadata\":{\"mention_total_limit\":8,\"mention_raid_protection_enabled\":true},\"actions\":[{\"type\":3,\"metadata\":{\"duration_seconds\":300}}],\"enabled\":false,\"exempt_roles\":[],\"exempt_channels\":[\"20\"]}",
        edit.written(),
    );
}

test "create DM channel JSON writes recipient id as string" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try CreateDmChannel.init(Snowflake.init(42)).writeJson(&out.writer);
    try std.testing.expectEqualStrings("{\"recipient_id\":\"42\"}", out.written());
}

test "thread creation JSON supports message and standalone variants" {
    var from_message = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer from_message.deinit();

    try CreateThreadFromMessage.init("debug")
        .withAutoArchiveDuration(1440)
        .withRateLimit(5)
        .writeJson(&from_message.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"debug\",\"auto_archive_duration\":1440,\"rate_limit_per_user\":5}",
        from_message.written(),
    );

    var standalone = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer standalone.deinit();

    try CreateThread.init("private")
        .withType(.private_thread)
        .invitableState(false)
        .writeJson(&standalone.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"private\",\"type\":12,\"invitable\":false}",
        standalone.written(),
    );
}

test "create channel invite JSON emits optional settings" {
    var query = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer query.deinit();

    try GetInvite.init()
        .withCounts(true)
        .withScheduledEvent(Snowflake.init(99))
        .writeQuery(&query.writer);
    try std.testing.expectEqualStrings(
        "with_counts=true&guild_scheduled_event_id=99",
        query.written(),
    );

    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try CreateChannelInvite.init()
        .withMaxAge(3600)
        .withMaxUses(5)
        .temporaryState(false)
        .uniqueState(true)
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"max_age\":3600,\"max_uses\":5,\"temporary\":false,\"unique\":true}",
        out.written(),
    );
}

test "lobby JSON supports metadata members bulk updates and channel links" {
    const metadata = [_]StringPair{.{ .key = "mode", .value = "duo" }};
    const member_metadata = [_]StringPair{.{ .key = "rank", .value = "gold" }};
    const members = [_]LobbyMember{
        LobbyMember.init(Snowflake.init(20)).withMetadata(&member_metadata).withFlags(1),
    };

    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();
    try CreateLobby.init()
        .withMetadata(&metadata)
        .withMembers(&members)
        .withIdleTimeout(60)
        .writeJson(&create.writer);
    try std.testing.expectEqualStrings(
        "{\"metadata\":{\"mode\":\"duo\"},\"members\":[{\"id\":\"20\",\"metadata\":{\"rank\":\"gold\"},\"flags\":1}],\"idle_timeout_seconds\":60}",
        create.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();
    try EditLobby.init().clearMetadata().writeJson(&edit.writer);
    try std.testing.expectEqualStrings("{\"metadata\":null}", edit.written());

    var bulk = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer bulk.deinit();
    const bulk_members = [_]LobbyMember{LobbyMember.init(Snowflake.init(21)).removeState(true)};
    try BulkUpdateLobbyMembers.init(&bulk_members).writeJson(&bulk.writer);
    try std.testing.expectEqualStrings("[{\"id\":\"21\",\"remove_member\":true}]", bulk.written());

    var link = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer link.deinit();
    try LinkLobbyChannel.init(Snowflake.init(30)).writeJson(&link.writer);
    try std.testing.expectEqualStrings("{\"channel_id\":\"30\"}", link.written());

    var unlink = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer unlink.deinit();
    try LinkLobbyChannel.unlink().writeJson(&unlink.writer);
    try std.testing.expectEqualStrings("{\"channel_id\":null}", unlink.written());

    var moderation = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer moderation.deinit();
    const moderation_metadata = [_]StringPair{
        .{ .key = "action", .value = "replace" },
        .{ .key = "replacement", .value = "Be kind" },
    };
    try UpdateLobbyMessageModerationMetadata.init(&moderation_metadata).writeJson(&moderation.writer);
    try std.testing.expectEqualStrings("{\"action\":\"replace\",\"replacement\":\"Be kind\"}", moderation.written());
}

test "webhook JSON supports create and edit payloads" {
    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();

    try CreateWebhook.init("deploys").withAvatar("data:image/png;base64,abc").writeJson(&create.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"deploys\",\"avatar\":\"data:image/png;base64,abc\"}",
        create.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    try EditWebhook.init().withName("alerts").withChannel(Snowflake.init(42)).writeJson(&edit.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"alerts\",\"channel_id\":\"42\"}",
        edit.written(),
    );

    var edit_with_token = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit_with_token.deinit();

    try EditWebhookWithToken.init()
        .withName("token-alerts")
        .withAvatar("data:image/png;base64,def")
        .writeJson(&edit_with_token.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"token-alerts\",\"avatar\":\"data:image/png;base64,def\"}",
        edit_with_token.written(),
    );
}

test "execute webhook JSON supports message override fields" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try ExecuteWebhook.init("deploy complete")
        .withFlags(MessageFlags.suppress_notifications)
        .withUsername("deploys")
        .withAvatarUrl("https://example.com/avatar.png")
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"content\":\"deploy complete\",\"flags\":4096,\"username\":\"deploys\",\"avatar_url\":\"https://example.com/avatar.png\"}",
        out.written(),
    );

    var rich = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer rich.deinit();

    const embeds = [_]Embed{Embed.init().withTitle("Deploy")};
    const buttons = [_]Interactions.Component{.{ .button = Interactions.Button.primary("ack", "Ack") }};
    const rows = [_]Interactions.Component{Interactions.Component.actionRow(&buttons)};

    try ExecuteWebhook.empty()
        .withEmbeds(&embeds)
        .withComponents(&rows)
        .withAllowedMentions(AllowedMentions.none())
        .ttsState(true)
        .writeJson(&rich.writer);

    try std.testing.expectEqualStrings(
        "{\"embeds\":[{\"title\":\"Deploy\"}],\"allowed_mentions\":{\"parse\":[]},\"components\":[{\"type\":1,\"components\":[{\"type\":2,\"style\":1,\"custom_id\":\"ack\",\"label\":\"Ack\"}]}],\"tts\":true}",
        rich.written(),
    );
}

test "execute webhook payload_json includes attachments" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const files = [_]UploadFile{
        UploadFile.init("deploy.txt", "done").withDescription("Release notes"),
    };

    try writeExecuteWebhookJsonWithAttachments(
        ExecuteWebhook.init("ship")
            .withUsername("deploys")
            .withThreadName("release-thread"),
        &files,
        &out.writer,
    );

    try std.testing.expectEqualStrings(
        "{\"content\":\"ship\",\"username\":\"deploys\",\"thread_name\":\"release-thread\",\"attachments\":[{\"id\":\"0\",\"filename\":\"deploy.txt\",\"description\":\"Release notes\"}]}",
        out.written(),
    );
}

test "message JSON supports flags for create and edit" {
    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();

    try CreateMessage.init("quiet")
        .withFlags(MessageFlags.suppress_embeds | MessageFlags.suppress_notifications)
        .writeJson(&create.writer);
    try std.testing.expectEqualStrings(
        "{\"content\":\"quiet\",\"flags\":4100}",
        create.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    try EditMessage.init().withFlags(MessageFlags.suppress_embeds).writeJson(&edit.writer);
    try std.testing.expectEqualStrings("{\"flags\":4}", edit.written());
}

test "create message JSON supports stickers and nonce enforcement" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const stickers = [_]Snowflake{ Snowflake.init(60), Snowflake.init(61) };

    try CreateMessage.empty()
        .withNonce("client-1", true)
        .withStickers(&stickers)
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"sticker_ids\":[\"60\",\"61\"],\"nonce\":\"client-1\",\"enforce_nonce\":true}",
        out.written(),
    );
}

test "create message JSON includes embeds and allowed mentions" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const fields = [_]EmbedField{
        .{ .name = "Runtime", .value = "Zig", .is_inline = true },
    };
    const embeds = [_]Embed{
        .{
            .title = "discord.zig",
            .description = "Fast bot core",
            .color = 0x5865F2,
            .footer = .{ .text = "v0.1" },
            .fields = &fields,
        },
    };
    const users = [_]Snowflake{Snowflake.init(42)};

    try CreateMessage.init("hello")
        .withEmbeds(&embeds)
        .withAllowedMentions(AllowedMentions.usersOnly().withUsers(&users))
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"content\":\"hello\",\"embeds\":[{\"title\":\"discord.zig\",\"description\":\"Fast bot core\",\"color\":5793266,\"footer\":{\"text\":\"v0.1\"},\"fields\":[{\"name\":\"Runtime\",\"value\":\"Zig\",\"inline\":true}]}],\"allowed_mentions\":{\"parse\":[\"users\"],\"users\":[\"42\"]}}",
        out.written(),
    );
}

test "embed helper supports single field storage" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const field = EmbedField.inlineField("Runtime", "Zig");
    try Embed.init()
        .withTitle("Status")
        .withField(&field)
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"title\":\"Status\",\"fields\":[{\"name\":\"Runtime\",\"value\":\"Zig\",\"inline\":true}]}",
        out.written(),
    );
}

test "allowed mentions helper JSON covers common mention policies" {
    var none = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer none.deinit();
    try AllowedMentions.none().writeJson(&none.writer);
    try std.testing.expectEqualStrings("{\"parse\":[]}", none.written());

    var all_mentions = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer all_mentions.deinit();
    try AllowedMentions.all().repliedUser(true).writeJson(&all_mentions.writer);
    try std.testing.expectEqualStrings("{\"parse\":[\"roles\",\"users\",\"everyone\"],\"replied_user\":true}", all_mentions.written());

    var reply_only = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer reply_only.deinit();
    try AllowedMentions.repliedUserOnly().writeJson(&reply_only.writer);
    try std.testing.expectEqualStrings("{\"parse\":[],\"replied_user\":true}", reply_only.written());

    var allowlists = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer allowlists.deinit();
    const users = [_]Snowflake{Snowflake.init(10)};
    const roles = [_]Snowflake{Snowflake.init(20)};
    try AllowedMentions.none()
        .withUsers(&users)
        .withRoles(&roles)
        .repliedUser(true)
        .writeJson(&allowlists.writer);
    try std.testing.expectEqualStrings(
        "{\"parse\":[],\"users\":[\"10\"],\"roles\":[\"20\"],\"replied_user\":true}",
        allowlists.written(),
    );

    var single_allowlist = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer single_allowlist.deinit();
    const single_user = Snowflake.init(30);
    const single_role = Snowflake.init(40);
    try AllowedMentions.none()
        .withUser(&single_user)
        .withRole(&single_role)
        .writeJson(&single_allowlist.writer);
    try std.testing.expectEqualStrings(
        "{\"parse\":[],\"users\":[\"30\"],\"roles\":[\"40\"]}",
        single_allowlist.written(),
    );
}

test "embed builder helpers stream expected JSON" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const fields = [_]EmbedField{
        EmbedField.inlineField("Runtime", "Zig"),
        EmbedField.init("Transport", "REST").inlineState(false),
    };
    const embed = Embed.init()
        .withTitle("discord.zig")
        .withDescription("Fast bot core")
        .withUrl("https://example.com")
        .withTimestamp("2026-06-02T00:00:00.000Z")
        .withColor(0x5865F2)
        .withFooter(EmbedFooter.init("v0.1").withIcon("https://example.com/footer.png"))
        .withImage("https://example.com/image.png")
        .withThumbnail("https://example.com/thumb.png")
        .withAuthor(EmbedAuthor.init("Deploys").withUrl("https://example.com/deploys").withIcon("https://example.com/author.png"))
        .withFields(&fields);

    try embed.writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"title\":\"discord.zig\",\"description\":\"Fast bot core\",\"url\":\"https://example.com\",\"timestamp\":\"2026-06-02T00:00:00.000Z\",\"color\":5793266,\"footer\":{\"text\":\"v0.1\",\"icon_url\":\"https://example.com/footer.png\"},\"image\":{\"url\":\"https://example.com/image.png\"},\"thumbnail\":{\"url\":\"https://example.com/thumb.png\"},\"author\":{\"name\":\"Deploys\",\"url\":\"https://example.com/deploys\",\"icon_url\":\"https://example.com/author.png\"},\"fields\":[{\"name\":\"Runtime\",\"value\":\"Zig\",\"inline\":true},{\"name\":\"Transport\",\"value\":\"REST\"}]}",
        out.written(),
    );
}

test "create message JSON includes components" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const buttons = [_]Interactions.Component{
        .{ .button = Interactions.Button.primary("ok", "OK") },
    };
    const rows = [_]Interactions.Component{
        Interactions.Component.actionRow(&buttons),
    };

    try (CreateMessage{
        .content = "choose",
        .components = &rows,
    }).writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"content\":\"choose\",\"components\":[{\"type\":1,\"components\":[{\"type\":2,\"style\":1,\"custom_id\":\"ok\",\"label\":\"OK\"}]}]}",
        out.written(),
    );
}

test "create message JSON includes poll" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const answers = [_]PollAnswer{
        PollAnswer.text("Zig"),
        PollAnswer.withEmoji("C", PollEmoji.unicode("🇨")),
    };

    try (CreateMessage{
        .poll = CreatePoll.init("Runtime?", &answers)
            .withDuration(24)
            .multiselect(false)
            .withLayout(.default),
    }).writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"poll\":{\"question\":{\"text\":\"Runtime?\"},\"answers\":[{\"poll_media\":{\"text\":\"Zig\"}},{\"poll_media\":{\"text\":\"C\",\"emoji\":{\"name\":\"🇨\"}}}],\"duration\":24,\"allow_multiselect\":false,\"layout_type\":1}}",
        out.written(),
    );

    var question_emoji = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer question_emoji.deinit();

    try CreatePoll.init("Ship?", &answers)
        .withQuestionEmoji(PollEmoji.unicode("🚀"))
        .multiselect(true)
        .writeJson(&question_emoji.writer);

    try std.testing.expectEqualStrings(
        "{\"question\":{\"text\":\"Ship?\",\"emoji\":{\"name\":\"🚀\"}},\"answers\":[{\"poll_media\":{\"text\":\"Zig\"}},{\"poll_media\":{\"text\":\"C\",\"emoji\":{\"name\":\"🇨\"}}}],\"allow_multiselect\":true}",
        question_emoji.written(),
    );
}

test "create message JSON includes shared client theme" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try CreateMessage.init("theme").withSharedClientTheme(.{
        .colors = &.{ "5865F2", "E558F2" },
        .gradient_angle = 45,
        .base_mix = 58,
        .base_theme = .dark,
    }).writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"content\":\"theme\",\"shared_client_theme\":{\"colors\":[\"5865F2\",\"E558F2\"],\"gradient_angle\":45,\"base_mix\":58,\"base_theme\":1}}",
        out.written(),
    );
}

test "create message builder helpers compose components poll and tts" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const buttons = [_]Interactions.Component{
        .{ .button = Interactions.Button.primary("ok", "OK") },
    };
    const rows = [_]Interactions.Component{
        Interactions.Component.actionRow(&buttons),
    };
    const answers = [_]PollAnswer{
        PollAnswer.text("yes"),
        PollAnswer.text("no"),
    };

    try CreateMessage.init("choose")
        .withComponents(&rows)
        .withPoll(CreatePoll.init("Ship?", &answers))
        .ttsState(true)
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"content\":\"choose\",\"components\":[{\"type\":1,\"components\":[{\"type\":2,\"style\":1,\"custom_id\":\"ok\",\"label\":\"OK\"}]}],\"poll\":{\"question\":{\"text\":\"Ship?\"},\"answers\":[{\"poll_media\":{\"text\":\"yes\"}},{\"poll_media\":{\"text\":\"no\"}}]},\"tts\":true}",
        out.written(),
    );
}

test "discordjs style type aliases compile to existing builders" {
    var embed_out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer embed_out.deinit();
    try EmbedBuilder.init().withTitle("Deploy").writeJson(&embed_out.writer);
    try std.testing.expectEqualStrings("{\"title\":\"Deploy\"}", embed_out.written());

    const attachment = AttachmentBuilder.init("hello.txt", "hi").withDescription("Greeting");
    try std.testing.expectEqualStrings("hello.txt", attachment.filename);

    const attachment_path = AttachmentPathBuilder.init("hello.txt", "fixtures/hello.txt");
    try std.testing.expectEqualStrings("fixtures/hello.txt", attachment_path.path);

    var mentions_out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer mentions_out.deinit();
    try AllowedMentionsBuilder.none().withUsers(&.{Snowflake.init(10)}).writeJson(&mentions_out.writer);
    try std.testing.expectEqualStrings("{\"parse\":[],\"users\":[\"10\"]}", mentions_out.written());

    var poll_out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer poll_out.deinit();
    const answers = [_]PollAnswer{ PollAnswer.text("yes"), PollAnswer.text("no") };
    try PollBuilder.init("Ship?", &answers).writeJson(&poll_out.writer);
    try std.testing.expect(std.mem.indexOf(u8, poll_out.written(), "\"question\":{\"text\":\"Ship?\"}") != null);
}

test "create message payload_json includes upload attachments" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const stickers = [_]Snowflake{Snowflake.init(60)};
    const files = [_]UploadFile{
        UploadFile.init("hello.txt", "hello")
            .withContentType("text/plain")
            .withDescription("Greeting"),
    };

    try writeCreateMessageJsonWithAttachments(.{
        .content = "with file",
        .nonce = "upload-1",
        .enforce_nonce = true,
        .sticker_ids = &stickers,
    }, &files, &out.writer);
    try std.testing.expectEqualStrings(
        "{\"content\":\"with file\",\"sticker_ids\":[\"60\"],\"nonce\":\"upload-1\",\"enforce_nonce\":true,\"attachments\":[{\"id\":\"0\",\"filename\":\"hello.txt\",\"description\":\"Greeting\"}]}",
        out.written(),
    );
}
