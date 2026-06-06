const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Interactions = @import("../../interactions/mod.zig");

const Root = @import("../types.zig");
const UserFlags = Root.UserFlags;
const ApplicationFlags = Root.ApplicationFlags;
const ChannelType = Root.ChannelType;
const AuditLogEvent = Root.AuditLogEvent;
const ListAuditLog = Root.ListAuditLog;
const ExecuteWebhook = Root.ExecuteWebhook;
const ExecuteWebhookQuery = Root.ExecuteWebhookQuery;
const MessageFlags = Root.MessageFlags;
const MessageType = Root.MessageType;
const GuildMemberFlags = Root.GuildMemberFlags;
const EmbedField = Root.EmbedField;
const Colors = Root.Colors;
const Embed = Root.Embed;
const AllowedMentions = Root.AllowedMentions;
const PollAnswer = Root.PollAnswer;
const CreatePoll = Root.CreatePoll;
const max_message_content_len = Root.max_message_content_len;
const max_message_nonce_len = Root.max_message_nonce_len;
const max_message_embeds = Root.max_message_embeds;
const max_message_stickers = Root.max_message_stickers;
const CreateMessage = Root.CreateMessage;
const EditMessage = Root.EditMessage;
const MessageReference = Root.MessageReference;
const UploadFile = Root.UploadFile;
const UploadFilePath = Root.UploadFilePath;
const writeCreateMessageJsonWithAttachments = Root.writeCreateMessageJsonWithAttachments;
const writeCreateMessageJsonWithAttachmentMetadata = Root.writeCreateMessageJsonWithAttachmentMetadata;

test "create message payload_json includes shared client theme with attachments" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const files = [_]UploadFile{
        UploadFile.init("hello.txt", "hello"),
    };

    try writeCreateMessageJsonWithAttachments(.{
        .shared_client_theme = .{
            .colors = &.{"111111"},
            .base_theme = .light,
        },
    }, &files, &out.writer);
    try std.testing.expectEqualStrings(
        "{\"shared_client_theme\":{\"colors\":[\"111111\"],\"base_theme\":2},\"attachments\":[{\"id\":\"0\",\"filename\":\"hello.txt\"}]}",
        out.written(),
    );
}

test "create message payload_json includes poll with attachments" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const answers = [_]PollAnswer{
        PollAnswer.text("yes"),
        PollAnswer.text("no"),
    };
    const files = [_]UploadFile{
        UploadFile.init("context.txt", "details"),
    };

    try writeCreateMessageJsonWithAttachments(.{
        .poll = CreatePoll.init("Ship?", &answers),
    }, &files, &out.writer);
    try std.testing.expectEqualStrings(
        "{\"poll\":{\"question\":{\"text\":\"Ship?\"},\"answers\":[{\"poll_media\":{\"text\":\"yes\"}},{\"poll_media\":{\"text\":\"no\"}}]},\"attachments\":[{\"id\":\"0\",\"filename\":\"context.txt\"}]}",
        out.written(),
    );
}

test "upload file path builder helpers include attachment metadata" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const files = [_]UploadFilePath{
        UploadFilePath.init("report.json", "fixtures/report.json")
            .withContentType("application/json")
            .withDescription("Build report"),
    };

    try writeCreateMessageJsonWithAttachmentMetadata(.{
        .content = "path file",
    }, &files, &out.writer);

    try std.testing.expectEqualStrings(
        "{\"content\":\"path file\",\"attachments\":[{\"id\":\"0\",\"filename\":\"report.json\",\"description\":\"Build report\"}]}",
        out.written(),
    );
}

test "create message JSON includes reply reference" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try (CreateMessage{
        .content = "reply",
        .message_reference = .{
            .message_id = Snowflake.init(10),
            .channel_id = Snowflake.init(20),
            .fail_if_not_exists = false,
        },
    }).writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"content\":\"reply\",\"message_reference\":{\"message_id\":\"10\",\"channel_id\":\"20\",\"fail_if_not_exists\":false}}",
        out.written(),
    );

    var forward = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer forward.deinit();

    try (CreateMessage{
        .message_reference = MessageReference.forward(Snowflake.init(10), Snowflake.init(20)),
    }).writeJson(&forward.writer);

    try std.testing.expectEqualStrings(
        "{\"message_reference\":{\"type\":1,\"message_id\":\"10\",\"channel_id\":\"20\"}}",
        forward.written(),
    );
}

test "edit message JSON supports content and embeds" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const embeds = [_]Embed{.{ .title = "edited" }};
    try EditMessage.init()
        .withContent("updated")
        .withEmbeds(&embeds)
        .withAllowedMentions(AllowedMentions.none())
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"content\":\"updated\",\"embeds\":[{\"title\":\"edited\"}],\"allowed_mentions\":{\"parse\":[]}}",
        out.written(),
    );
}

test "message payload validate enforces content embed sticker mention and component limits" {
    const long_content = "x" ** (max_message_content_len + 1);
    try std.testing.expectError(error.ContentTooLong, CreateMessage.init(long_content).validate());

    const too_many_embeds = [_]Embed{Embed.init()} ** (max_message_embeds + 1);
    try std.testing.expectError(error.TooManyEmbeds, CreateMessage.empty().withEmbeds(&too_many_embeds).validate());

    const too_many_stickers = [_]Snowflake{Snowflake.init(1)} ** (max_message_stickers + 1);
    try std.testing.expectError(error.TooManyStickers, CreateMessage.empty().withStickers(&too_many_stickers).validate());

    const users = [_]Snowflake{Snowflake.init(2)} ** (AllowedMentions.max_users + 1);
    try std.testing.expectError(
        error.TooManyUsers,
        CreateMessage.init("hi").withAllowedMentions(AllowedMentions.none().withUsers(&users)).validate(),
    );

    const row_children = [_]Interactions.Component{.{ .button = Interactions.Button.primary("id", "ok") }} ** (Interactions.max_row_components + 1);
    const rows = [_]Interactions.Component{Interactions.Component.actionRow(&row_children)};
    try std.testing.expectError(error.TooManyRowComponents, CreateMessage.empty().withComponents(&rows).validate());
}

test "message payload validate handles components v2 exclusivity and nonce length" {
    const text = [_]Interactions.TextDisplay{Interactions.TextDisplay.init("body")};
    const components = [_]Interactions.Component{.{ .section = Interactions.Section.withButton(&text, Interactions.Button.primary("id", "ok")) }};

    try CreateMessage.empty()
        .withFlags(MessageFlags.is_components_v2)
        .withComponents(&components)
        .validate();

    try std.testing.expectError(
        error.ComponentsV2Exclusive,
        CreateMessage.init("not allowed")
            .withFlags(MessageFlags.is_components_v2)
            .withComponents(&components)
            .validate(),
    );

    const long_nonce = "n" ** (max_message_nonce_len + 1);
    try std.testing.expectError(error.NonceTooLong, CreateMessage.init("hi").withNonce(long_nonce, true).validate());

    try std.testing.expectError(error.ContentTooLong, EditMessage.init().withContent("x" ** (max_message_content_len + 1)).validate());
}

test "embed validate rejects field overflow at the limit boundary" {
    const at_limit = [_]EmbedField{EmbedField.init("n", "v")} ** Embed.max_fields;
    try Embed.init().withFields(&at_limit).validate();

    const over_limit = [_]EmbedField{EmbedField.init("n", "v")} ** (Embed.max_fields + 1);
    try std.testing.expectError(error.TooManyFields, Embed.init().withFields(&over_limit).validate());
}

test "embed validate enforces per-field and total character limits" {
    const long_title = "x" ** (Embed.max_title_len + 1);
    try std.testing.expectError(error.TitleTooLong, Embed.init().withTitle(long_title).validate());

    const long_value = "y" ** (EmbedField.max_value_len + 1);
    const big_field = [_]EmbedField{EmbedField.init("ok", long_value)};
    try std.testing.expectError(error.FieldValueTooLong, Embed.init().withFields(&big_field).validate());

    // Each field is within its own limit, but together they exceed the 6000 total.
    const chunk = "z" ** 1000;
    const heavy = [_]EmbedField{EmbedField.init("name", chunk)} ** 7;
    try std.testing.expectError(error.EmbedTooLong, Embed.init().withFields(&heavy).validate());

    // Multi-byte characters are counted as single code points, not bytes.
    const two_byte = "é" ** Embed.max_title_len; // 2 bytes each, 256 code points
    try Embed.init().withTitle(two_byte).validate();

    try std.testing.expectError(error.InvalidUtf8, Embed.init().withTitle("\xff\xfe").validate());
}

test "allowed mentions validate enforces id limits and parse conflicts" {
    const id = Snowflake.init(1);
    const too_many = [_]Snowflake{id} ** (AllowedMentions.max_users + 1);
    try std.testing.expectError(error.TooManyUsers, AllowedMentions.none().withUsers(&too_many).validate());

    // Explicit allowlist plus the broad parse entry of the same kind is rejected.
    const one = [_]Snowflake{id};
    const conflict = AllowedMentions.usersOnly().withUsers(&one);
    try std.testing.expectError(error.UserParseConflict, conflict.validate());

    // Explicit roles with a users-only parse policy is allowed.
    try AllowedMentions.usersOnly().withRoles(&one).validate();
    try AllowedMentions.all().validate();
}

test "execute webhook thread name and query options" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();
    try ExecuteWebhook.init("hi").withThreadName("forum post").writeJson(&out.writer);
    try std.testing.expectEqualStrings("{\"content\":\"hi\",\"thread_name\":\"forum post\"}", out.written());

    var query = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer query.deinit();
    const options = ExecuteWebhookQuery{ .wait = true, .thread_id = Snowflake.init(55) };
    try std.testing.expect(options.hasQuery());
    try options.writeQuery(&query.writer);
    try std.testing.expectEqualStrings("wait=true&thread_id=55", query.written());

    try std.testing.expect(!(ExecuteWebhookQuery{}).hasQuery());
}

test "channel type guards classify channels like Discord.js" {
    try std.testing.expect(ChannelType.public_thread.isThread());
    try std.testing.expect(ChannelType.PublicThread.isThread());
    try std.testing.expect(!ChannelType.guild_text.isThread());
    try std.testing.expect(!ChannelType.GuildText.isThread());

    try std.testing.expect(ChannelType.guild_voice.isVoiceBased());
    try std.testing.expect(ChannelType.guild_stage_voice.isVoiceBased());
    try std.testing.expect(ChannelType.GuildVoice.isVoiceBased());
    try std.testing.expect(ChannelType.GuildStageVoice.isVoiceBased());
    try std.testing.expect(!ChannelType.guild_text.isVoiceBased());

    // Voice channels and threads are text-based; categories/forums are not.
    try std.testing.expect(ChannelType.guild_text.isTextBased());
    try std.testing.expect(ChannelType.guild_voice.isTextBased());
    try std.testing.expect(ChannelType.public_thread.isTextBased());
    try std.testing.expect(!ChannelType.guild_category.isTextBased());
    try std.testing.expect(!ChannelType.guild_forum.isTextBased());

    try std.testing.expect(ChannelType.dm.isDMBased());
    try std.testing.expect(ChannelType.group_dm.isDMBased());
    try std.testing.expect(!ChannelType.guild_text.isDMBased());

    try std.testing.expect(ChannelType.guild_forum.isThreadOnly());
    try std.testing.expect(ChannelType.guild_media.isThreadOnly());
    try std.testing.expect(!ChannelType.guild_text.isThreadOnly());

    try std.testing.expect(ChannelType.guild_text.isGuildBased());
    try std.testing.expect(!ChannelType.dm.isGuildBased());

    try std.testing.expectEqual(@as(u8, 0), @intFromEnum(ChannelType.GuildText));
    try std.testing.expectEqual(@as(u8, 13), @intFromEnum(ChannelType.GuildStageVoice));
    try std.testing.expectEqual(@as(u8, 16), @intFromEnum(ChannelType.GuildMedia));
    try std.testing.expectEqualStrings("GuildText", ChannelType.GuildText.discordJsName());
    try std.testing.expectEqualStrings("GuildForum", ChannelType.GuildForum.discordJsName());
    try std.testing.expectEqual(ChannelType.guild_text, ChannelType.fromDiscordJsName("GuildText").?);
    try std.testing.expectEqual(ChannelType.guild_media, ChannelType.fromDiscordJsName("GuildMedia").?);
    try std.testing.expectEqual(@as(?ChannelType, null), ChannelType.fromDiscordJsName("GuildNews"));
}

test "embed color uses Discord color palette" {
    try std.testing.expectEqual(@as(u24, 0x5865F2), Colors.blurple);
    try std.testing.expectEqual(@as(u24, 0x5865F2), Colors.Blurple);
    try std.testing.expectEqual(@as(u24, 0xED4245), Colors.red);
    try std.testing.expectEqual(@as(u24, 0xED4245), Colors.Red);
    try std.testing.expectEqual(@as(u24, 0x2C2F33), Colors.DarkButNotBlack);
    try std.testing.expectEqualStrings("Blurple", Colors.discordJsName(Colors.Blurple).?);
    try std.testing.expectEqual(Colors.Yellow, Colors.fromDiscordJsName("Yellow").?);
    try std.testing.expectEqual(@as(?u24, null), Colors.fromDiscordJsName("Random"));

    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();
    try Embed.init().withColor(Colors.Blurple).writeJson(&out.writer);
    try std.testing.expectEqualStrings("{\"color\":5793266}", out.written());
}

test "user and application flag helpers detect set bits" {
    const badges = UserFlags.active_developer | UserFlags.verified_bot;
    try std.testing.expect(UserFlags.has(badges, UserFlags.active_developer));
    try std.testing.expect(UserFlags.has(badges, UserFlags.verified_bot));
    try std.testing.expect(!UserFlags.has(badges, UserFlags.staff));
    try std.testing.expectEqual(@as(u32, 1) << 22, UserFlags.active_developer);

    const app = ApplicationFlags.gateway_message_content | ApplicationFlags.embedded;
    try std.testing.expect(ApplicationFlags.has(app, ApplicationFlags.embedded));
    try std.testing.expect(!ApplicationFlags.has(app, ApplicationFlags.gateway_presence));
}

test "message type and guild member flags expose Discord values" {
    try std.testing.expectEqual(@as(u8, 19), @intFromEnum(MessageType.reply));
    try std.testing.expectEqual(@as(u8, 0), @intFromEnum(MessageType.default));
    try std.testing.expectEqual(@as(u8, 46), @intFromEnum(MessageType.poll_result));

    const flags = GuildMemberFlags.completed_onboarding | GuildMemberFlags.did_rejoin;
    try std.testing.expect(GuildMemberFlags.has(flags, GuildMemberFlags.completed_onboarding));
    try std.testing.expect(!GuildMemberFlags.has(flags, GuildMemberFlags.is_guest));
}

test "audit log event enum filters the audit log query" {
    try std.testing.expectEqual(@as(u16, 72), @intFromEnum(AuditLogEvent.message_delete));
    try std.testing.expectEqual(@as(u16, 1), @intFromEnum(AuditLogEvent.guild_update));
    try std.testing.expectEqual(@as(u16, 145), @intFromEnum(AuditLogEvent.auto_moderation_user_communication_disabled));

    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();
    const options = ListAuditLog.init().withAuditEvent(.member_ban_add).withLimit(10);
    try options.writeQuery(&out.writer);
    try std.testing.expectEqualStrings("action_type=22&limit=10", out.written());
}
