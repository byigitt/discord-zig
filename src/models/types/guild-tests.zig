const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Json = @import("../../core/json.zig");
const Interactions = @import("../../interactions/mod.zig");
const Permissions = @import("../../core/permissions.zig");

const Root = @import("../types.zig");
const EditGuild = Root.EditGuild;
const GetGuildWidgetImage = Root.GetGuildWidgetImage;
const EditGuildIncidentActions = Root.EditGuildIncidentActions;
const OnboardingPromptOption = Root.OnboardingPromptOption;
const OnboardingPrompt = Root.OnboardingPrompt;
const EditGuildOnboarding = Root.EditGuildOnboarding;
const WelcomeScreenChannel = Root.WelcomeScreenChannel;
const Role = Root.Role;
const RoleColors = Root.RoleColors;
const DefaultReactionEmoji = Root.DefaultReactionEmoji;
const ChannelFlags = Root.ChannelFlags;
const WriteForumTag = Root.WriteForumTag;
const PermissionOverwrite = Root.PermissionOverwrite;
const CreateGuildChannel = Root.CreateGuildChannel;
const CreateGuild = Root.CreateGuild;
const CreateGuildFromTemplate = Root.CreateGuildFromTemplate;
const CreateGuildTemplate = Root.CreateGuildTemplate;
const EditGuildTemplate = Root.EditGuildTemplate;
const EditGuildWidgetSettings = Root.EditGuildWidgetSettings;
const EditWelcomeScreen = Root.EditWelcomeScreen;
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
const EditGuildSticker = Root.EditGuildSticker;
const SendSoundboardSound = Root.SendSoundboardSound;
const CreateGuildSoundboardSound = Root.CreateGuildSoundboardSound;
const EditGuildSoundboardSound = Root.EditGuildSoundboardSound;
const EditGuildMember = Root.EditGuildMember;
const AddGroupDmRecipient = Root.AddGroupDmRecipient;
const ForumThreadMessage = Root.ForumThreadMessage;
const CreateForumThread = Root.CreateForumThread;
const Embed = Root.Embed;
const ListChannelPins = Root.ListChannelPins;
const BulkDeleteMessages = Root.BulkDeleteMessages;
const writeGuildRolePositionArray = Root.writeGuildRolePositionArray;
const writeGuildChannelPositionArray = Root.writeGuildChannelPositionArray;

test "list channel pins query percent encodes timestamp" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try ListChannelPins.beforeTimestamp("2026-06-02T10:30:00.000Z")
        .withLimit(50)
        .writeQuery(&out.writer);

    try std.testing.expectEqualStrings("before=2026-06-02T10%3A30%3A00.000Z&limit=50", out.written());
}

test "bulk delete messages JSON writes message id array" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const messages = [_]Snowflake{ Snowflake.init(10), Snowflake.init(20) };
    try (BulkDeleteMessages{ .messages = &messages }).writeJson(&out.writer);

    try std.testing.expectEqualStrings("{\"messages\":[\"10\",\"20\"]}", out.written());
}

test "guild channel payload JSON includes common fields" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try CreateGuildChannel.init("general")
        .withType(.guild_text)
        .withTopic("Project chat")
        .withRateLimit(5)
        .withParent(Snowflake.init(99))
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"name\":\"general\",\"type\":0,\"topic\":\"Project chat\",\"rate_limit_per_user\":5,\"parent_id\":\"99\"}",
        out.written(),
    );
}

test "guild channel payload JSON supports forum available tags" {
    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();

    const tags = [_]WriteForumTag{
        WriteForumTag.init("Help").moderatedState(true).withEmojiId(Snowflake.init(80)),
        WriteForumTag.init("Ship").withEmojiName("🚀"),
    };
    try CreateGuildChannel.init("forum")
        .withType(.guild_forum)
        .withFlags(ChannelFlags.require_tag)
        .withAvailableTags(&tags)
        .withDefaultReactionEmoji(DefaultReactionEmoji.name("👋"))
        .withDefaultThreadRateLimit(30)
        .withDefaultSortOrder(.creation_date)
        .withDefaultForumLayout(.gallery_view)
        .writeJson(&create.writer);

    try std.testing.expectEqualStrings(
        "{\"name\":\"forum\",\"type\":15,\"flags\":16,\"available_tags\":[{\"name\":\"Help\",\"moderated\":true,\"emoji_id\":\"80\"},{\"name\":\"Ship\",\"emoji_name\":\"🚀\"}],\"default_reaction_emoji\":{\"emoji_name\":\"👋\"},\"default_thread_rate_limit_per_user\":30,\"default_sort_order\":1,\"default_forum_layout\":2}",
        create.written(),
    );
}

test "edit guild JSON supports settings media channels and clears" {
    var update = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer update.deinit();

    try EditGuild.init()
        .withName("zig guild")
        .withVerificationLevel(2)
        .withAfkChannel(Snowflake.init(20))
        .withAfkTimeout(300)
        .withIcon("data:image/png;base64,abc")
        .withSystemChannelFlags(3)
        .withRulesChannel(Snowflake.init(30))
        .withPreferredLocale("en-US")
        .withFeatures(&.{ "COMMUNITY", "NEWS" })
        .premiumProgressBarState(true)
        .writeJson(&update.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"zig guild\",\"verification_level\":2,\"afk_channel_id\":\"20\",\"afk_timeout\":300,\"icon\":\"data:image/png;base64,abc\",\"system_channel_flags\":3,\"rules_channel_id\":\"30\",\"preferred_locale\":\"en-US\",\"features\":[\"COMMUNITY\",\"NEWS\"],\"premium_progress_bar_enabled\":true}",
        update.written(),
    );

    var clear = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear.deinit();

    try EditGuild.init()
        .clearAfkChannel()
        .clearIcon()
        .clearBanner()
        .clearSystemChannel()
        .clearPublicUpdatesChannel()
        .clearDescription()
        .clearSafetyAlertsChannel()
        .writeJson(&clear.writer);
    try std.testing.expectEqualStrings(
        "{\"afk_channel_id\":null,\"icon\":null,\"banner\":null,\"system_channel_id\":null,\"public_updates_channel_id\":null,\"description\":null,\"safety_alerts_channel_id\":null}",
        clear.written(),
    );
}

test "guild template JSON supports create and edit payloads" {
    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();

    try CreateGuildTemplate.init("starter")
        .withDescription("Project starter")
        .writeJson(&create.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"starter\",\"description\":\"Project starter\"}",
        create.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    try EditGuildTemplate.init().withDescription("Updated").writeJson(&edit.writer);
    try std.testing.expectEqualStrings("{\"description\":\"Updated\"}", edit.written());
}

test "guild lifecycle and group DM payload JSON" {
    var guild = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer guild.deinit();

    const roles = [_]CreateGuildRole{CreateGuildRole.init("mod").withPermissions(Permissions.manage_messages)};
    const channels = [_]CreateGuildChannel{CreateGuildChannel.init("general").withType(.guild_text)};
    try CreateGuild.init("zig")
        .withIcon("data:image/png;base64,abc")
        .withRoles(&roles)
        .withChannels(&channels)
        .withVerificationLevel(1)
        .writeJson(&guild.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"zig\",\"icon\":\"data:image/png;base64,abc\",\"verification_level\":1,\"roles\":[{\"name\":\"mod\",\"permissions\":\"8192\"}],\"channels\":[{\"name\":\"general\",\"type\":0}]}",
        guild.written(),
    );

    var template = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer template.deinit();
    try CreateGuildFromTemplate.init("from-template").withIcon("data:image/png;base64,xyz").writeJson(&template.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"from-template\",\"icon\":\"data:image/png;base64,xyz\"}",
        template.written(),
    );

    var recipient = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer recipient.deinit();
    try AddGroupDmRecipient.init("oauth-token").withNick("baris").writeJson(&recipient.writer);
    try std.testing.expectEqualStrings("{\"access_token\":\"oauth-token\",\"nick\":\"baris\"}", recipient.written());
}

test "forum thread payload JSON includes first message and tags" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const tags = [_]Snowflake{ Snowflake.init(10), Snowflake.init(20) };
    const embeds = [_]Embed{Embed.init().withTitle("Launch")};
    try CreateForumThread.init(
        "release",
        ForumThreadMessage.init("ship").withEmbeds(&embeds),
    )
        .withAutoArchiveDuration(1440)
        .withRateLimit(5)
        .withAppliedTags(&tags)
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"name\":\"release\",\"auto_archive_duration\":1440,\"rate_limit_per_user\":5,\"message\":{\"content\":\"ship\",\"embeds\":[{\"title\":\"Launch\"}]},\"applied_tags\":[\"10\",\"20\"]}",
        out.written(),
    );
}

test "guild widget settings JSON supports update and clear channel" {
    var update = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer update.deinit();

    try EditGuildWidgetSettings.init()
        .enabledState(true)
        .withChannel(Snowflake.init(42))
        .writeJson(&update.writer);
    try std.testing.expectEqualStrings("{\"enabled\":true,\"channel_id\":\"42\"}", update.written());

    var clear = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear.deinit();

    try EditGuildWidgetSettings.init().clearChannel().writeJson(&clear.writer);
    try std.testing.expectEqualStrings("{\"channel_id\":null}", clear.written());
}

test "guild widget image query supports style option" {
    var query = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer query.deinit();

    const options = GetGuildWidgetImage.init().withStyle(.banner4);
    try std.testing.expect(options.hasQuery());
    try options.writeQuery(&query.writer);
    try std.testing.expectEqualStrings("style=banner4", query.written());

    try std.testing.expect(!GetGuildWidgetImage.init().hasQuery());
}

test "guild incident actions JSON supports set and clear fields" {
    var set = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer set.deinit();

    try EditGuildIncidentActions.init()
        .disableInvitesUntil("2026-06-03T12:00:00.000Z")
        .disableDmsUntil("2026-06-03T13:00:00.000Z")
        .writeJson(&set.writer);
    try std.testing.expectEqualStrings(
        "{\"invites_disabled_until\":\"2026-06-03T12:00:00.000Z\",\"dms_disabled_until\":\"2026-06-03T13:00:00.000Z\"}",
        set.written(),
    );

    var clear = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear.deinit();

    try EditGuildIncidentActions.init()
        .clearInvitesDisabledUntil()
        .clearDmsDisabledUntil()
        .writeJson(&clear.writer);
    try std.testing.expectEqualStrings("{\"invites_disabled_until\":null,\"dms_disabled_until\":null}", clear.written());
}

test "guild onboarding JSON supports prompts default channels and mode" {
    const option_channels = [_]Snowflake{Snowflake.init(20)};
    const option_roles = [_]Snowflake{Snowflake.init(30)};
    const options = [_]OnboardingPromptOption{
        OnboardingPromptOption.init("General chat")
            .withId(Snowflake.init(11))
            .withChannels(&option_channels)
            .withRoles(&option_roles)
            .withEmojiName("wave")
            .emojiAnimatedState(false)
            .withDescription("Meet the community"),
    };
    const prompts = [_]OnboardingPrompt{
        OnboardingPrompt.init("Choose your channels")
            .withId(Snowflake.init(10))
            .withType(.dropdown)
            .withOptions(&options)
            .singleSelectState(true)
            .requiredState(true)
            .inOnboardingState(false),
    };
    const default_channels = [_]Snowflake{ Snowflake.init(40), Snowflake.init(41) };

    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try EditGuildOnboarding.init()
        .withPrompts(&prompts)
        .withDefaultChannels(&default_channels)
        .enabledState(true)
        .withMode(.onboarding_advanced)
        .writeJson(&out.writer);
    try std.testing.expectEqualStrings(
        "{\"prompts\":[{\"id\":\"10\",\"type\":1,\"options\":[{\"id\":\"11\",\"channel_ids\":[\"20\"],\"role_ids\":[\"30\"],\"emoji_name\":\"wave\",\"emoji_animated\":false,\"title\":\"General chat\",\"description\":\"Meet the community\"}],\"title\":\"Choose your channels\",\"single_select\":true,\"required\":true,\"in_onboarding\":false}],\"default_channel_ids\":[\"40\",\"41\"],\"enabled\":true,\"mode\":1}",
        out.written(),
    );
}

test "welcome screen JSON supports channels update and clear fields" {
    var channel = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer channel.deinit();

    try WelcomeScreenChannel.init(Snowflake.init(10), "Read rules")
        .withEmojiName("wave")
        .writeJson(&channel.writer);
    try std.testing.expectEqualStrings(
        "{\"channel_id\":\"10\",\"description\":\"Read rules\",\"emoji_name\":\"wave\"}",
        channel.written(),
    );

    var update = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer update.deinit();

    const channels = [_]WelcomeScreenChannel{
        WelcomeScreenChannel.init(Snowflake.init(10), "Read rules")
            .withEmojiId(Snowflake.init(30)),
    };
    try EditWelcomeScreen.init()
        .enabledState(true)
        .withChannels(&channels)
        .withDescription("Start here")
        .writeJson(&update.writer);
    try std.testing.expectEqualStrings(
        "{\"enabled\":true,\"welcome_channels\":[{\"channel_id\":\"10\",\"description\":\"Read rules\",\"emoji_id\":\"30\"}],\"description\":\"Start here\"}",
        update.written(),
    );

    var clear = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear.deinit();

    try EditWelcomeScreen.init()
        .clearChannels()
        .clearDescription()
        .writeJson(&clear.writer);
    try std.testing.expectEqualStrings("{\"welcome_channels\":null,\"description\":null}", clear.written());
}

test "edit channel JSON emits only provided fields" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try EditChannel.init()
        .withName("voice")
        .withBitrate(64000)
        .withUserLimit(10)
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"name\":\"voice\",\"bitrate\":64000,\"user_limit\":10}",
        out.written(),
    );
}

test "edit channel JSON supports thread lifecycle fields" {
    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    const tags = [_]Snowflake{ Snowflake.init(40), Snowflake.init(50) };
    try EditChannel.init()
        .withName("resolved")
        .archivedState(true)
        .withAutoArchiveDuration(1440)
        .lockedState(true)
        .invitableState(false)
        .withAppliedTags(&tags)
        .writeJson(&edit.writer);

    try std.testing.expectEqualStrings(
        "{\"name\":\"resolved\",\"archived\":true,\"auto_archive_duration\":1440,\"locked\":true,\"invitable\":false,\"applied_tags\":[\"40\",\"50\"]}",
        edit.written(),
    );

    var clear_tags = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear_tags.deinit();

    try EditChannel.init().clearAppliedTags().writeJson(&clear_tags.writer);
    try std.testing.expectEqualStrings("{\"applied_tags\":[]}", clear_tags.written());
}

test "edit channel JSON supports forum available tags" {
    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    const tags = [_]WriteForumTag{
        WriteForumTag.init("No emoji")
            .withId(Snowflake.init(70))
            .clearEmojiId()
            .clearEmojiName(),
    };
    try EditChannel.init()
        .withFlags(ChannelFlags.require_tag | ChannelFlags.hide_media_download_options)
        .withAvailableTags(&tags)
        .withDefaultReactionEmoji(DefaultReactionEmoji.id(Snowflake.init(90)))
        .withDefaultThreadRateLimit(15)
        .withDefaultSortOrder(.latest_activity)
        .withDefaultForumLayout(.list_view)
        .writeJson(&edit.writer);
    try std.testing.expectEqualStrings(
        "{\"flags\":32784,\"available_tags\":[{\"id\":\"70\",\"name\":\"No emoji\",\"emoji_id\":null,\"emoji_name\":null}],\"default_reaction_emoji\":{\"emoji_id\":\"90\"},\"default_thread_rate_limit_per_user\":15,\"default_sort_order\":0,\"default_forum_layout\":1}",
        edit.written(),
    );

    var clear = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear.deinit();

    try EditChannel.init().clearAvailableTags().writeJson(&clear.writer);
    try std.testing.expectEqualStrings("{\"available_tags\":[]}", clear.written());
}

test "guild channel position JSON supports arrays parent moves and clears" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const positions = [_]GuildChannelPosition{
        GuildChannelPosition.init(Snowflake.init(10))
            .withPosition(2)
            .lockPermissions(true)
            .withParent(Snowflake.init(30)),
        GuildChannelPosition.init(Snowflake.init(20)).clearParent(),
    };
    try writeGuildChannelPositionArray(&positions, &out.writer);

    try std.testing.expectEqualStrings(
        "[{\"id\":\"10\",\"position\":2,\"lock_permissions\":true,\"parent_id\":\"30\"},{\"id\":\"20\",\"parent_id\":null}]",
        out.written(),
    );
}

test "edit channel permission JSON writes bitmasks as strings" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try EditChannelPermission.init(.role)
        .withAllow(Permissions.view_channel)
        .withDeny(Permissions.send_messages)
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"type\":0,\"allow\":\"1024\",\"deny\":\"2048\"}",
        out.written(),
    );

    const resolved = (PermissionOverwrite{
        .id = Snowflake.init(10),
        .type = .member,
        .allow = Permissions.view_channel,
        .deny = Permissions.send_messages,
    }).toPermissionsOverwrite();
    try std.testing.expectEqual(Permissions.OverwriteType.member, resolved.type);
    try std.testing.expectEqual(@as(u64, 10), resolved.id);
    try std.testing.expectEqual(Permissions.view_channel, resolved.allow);
    try std.testing.expectEqual(Permissions.send_messages, resolved.deny);
}

test "channel utility JSON supports voice status and announcement follow" {
    var status = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer status.deinit();

    try SetVoiceChannelStatus.clear().writeJson(&status.writer);
    try std.testing.expectEqualStrings("{\"status\":null}", status.written());

    var follow = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer follow.deinit();

    try FollowAnnouncementChannel.init(Snowflake.init(42)).writeJson(&follow.writer);
    try std.testing.expectEqualStrings("{\"webhook_channel_id\":\"42\"}", follow.written());
}

test "guild role payload JSON writes permissions as string bitmask" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try CreateGuildRole.init("moderator")
        .withPermissions(Permissions.add(Permissions.manage_messages, Permissions.kick_members))
        .withColor(0x5865F2)
        .withColors(RoleColors.init(0x5865F2).withSecondary(0xE558F2))
        .hoisted(true)
        .withIcon("data:image/png;base64,abc")
        .withUnicodeEmoji("⚡")
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"name\":\"moderator\",\"permissions\":\"8194\",\"color\":5793266,\"colors\":{\"primary_color\":5793266,\"secondary_color\":15030514,\"tertiary_color\":null},\"hoist\":true,\"icon\":\"data:image/png;base64,abc\",\"unicode_emoji\":\"⚡\"}",
        out.written(),
    );

    const role = (Role{
        .id = Snowflake.init(10),
        .name = "moderator",
        .colors = RoleColors.init(0x5865F2).withSecondary(0xE558F2),
        .permissions = Permissions.manage_messages,
    });
    const permissions_role = role.toPermissionsRole();
    try std.testing.expectEqual(@as(u24, 0x5865F2), role.colors.?.primary_color);
    try std.testing.expectEqual(@as(u24, 0xE558F2), role.colors.?.secondary_color.?);
    try std.testing.expect(role.colors.?.tertiary_color == null);
    try std.testing.expectEqual(@as(u64, 10), permissions_role.id);
    try std.testing.expectEqual(Permissions.manage_messages, permissions_role.permissions);
}

test "edit guild role JSON can explicitly disable booleans" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try EditGuildRole.init()
        .withName("helpers")
        .withColors(RoleColors.init(11127295).withSecondary(16759788).withTertiary(16761760))
        .hoisted(false)
        .clearIcon()
        .clearUnicodeEmoji()
        .mentionableState(false)
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"name\":\"helpers\",\"colors\":{\"primary_color\":11127295,\"secondary_color\":16759788,\"tertiary_color\":16761760},\"hoist\":false,\"icon\":null,\"unicode_emoji\":null,\"mentionable\":false}",
        out.written(),
    );

    var set_assets = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer set_assets.deinit();

    try EditGuildRole.init()
        .withPermissions(Permissions.manage_roles)
        .withColor(0x2ECC71)
        .withIcon("data:image/png;base64,role")
        .withUnicodeEmoji("✅")
        .mentionableState(true)
        .writeJson(&set_assets.writer);

    try std.testing.expectEqualStrings(
        "{\"permissions\":\"268435456\",\"color\":3066993,\"icon\":\"data:image/png;base64,role\",\"unicode_emoji\":\"✅\",\"mentionable\":true}",
        set_assets.written(),
    );
}

test "guild role position JSON supports arrays and nullable position" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const positions = [_]GuildRolePosition{
        GuildRolePosition.init(Snowflake.init(10)).withPosition(2),
        GuildRolePosition.init(Snowflake.init(20)).clearPosition(),
    };
    try writeGuildRolePositionArray(&positions, &out.writer);

    try std.testing.expectEqualStrings(
        "[{\"id\":\"10\",\"position\":2},{\"id\":\"20\",\"position\":null}]",
        out.written(),
    );
}

test "guild emoji JSON supports create and edit payloads" {
    const roles = [_]Snowflake{ Snowflake.init(10), Snowflake.init(20) };

    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();

    try CreateGuildEmoji.init("zig", "data:image/webp;base64,abc")
        .withRoles(&roles)
        .writeJson(&create.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"zig\",\"image\":\"data:image/webp;base64,abc\",\"roles\":[\"10\",\"20\"]}",
        create.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    try EditGuildEmoji.init()
        .withName("ziggy")
        .withRoles(&.{})
        .writeJson(&edit.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"ziggy\",\"roles\":[]}",
        edit.written(),
    );
}

test "application emoji JSON supports create and edit payloads" {
    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();

    try CreateApplicationEmoji.init("zig", "data:image/webp;base64,abc").writeJson(&create.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"zig\",\"image\":\"data:image/webp;base64,abc\"}",
        create.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    try EditApplicationEmoji.init("ziggy").writeJson(&edit.writer);
    try std.testing.expectEqualStrings("{\"name\":\"ziggy\"}", edit.written());
}

test "edit guild sticker JSON emits optional fields" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try EditGuildSticker.init()
        .withName("ziggy")
        .withDescription("Zig mascot")
        .withTags("zap")
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"name\":\"ziggy\",\"description\":\"Zig mascot\",\"tags\":\"zap\"}",
        out.written(),
    );
}

test "soundboard JSON supports send create and edit payloads" {
    var send = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer send.deinit();

    try SendSoundboardSound.init(Snowflake.init(10))
        .fromGuild(Snowflake.init(20))
        .writeJson(&send.writer);
    try std.testing.expectEqualStrings(
        "{\"sound_id\":\"10\",\"source_guild_id\":\"20\"}",
        send.written(),
    );

    var create = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer create.deinit();

    try CreateGuildSoundboardSound.init("launch", "data:audio/ogg;base64,T0dH")
        .withVolume(0.5)
        .withEmojiName("🚀")
        .writeJson(&create.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"launch\",\"sound\":\"data:audio/ogg;base64,T0dH\",\"volume\":0.5,\"emoji_name\":\"🚀\"}",
        create.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();

    try EditGuildSoundboardSound.init()
        .withName("ship")
        .withVolume(1.0)
        .clearEmojiId()
        .clearEmojiName()
        .writeJson(&edit.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"ship\",\"volume\":1,\"emoji_id\":null,\"emoji_name\":null}",
        edit.written(),
    );
}

test "edit guild member JSON supports roles voice and timeout fields" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const roles = [_]Snowflake{ Snowflake.init(10), Snowflake.init(20) };
    try EditGuildMember.init()
        .withNick("helper")
        .withRoles(&roles)
        .muteState(false)
        .deafState(true)
        .moveToVoiceChannel(Snowflake.init(30))
        .timeoutUntil("2026-06-02T10:00:00.000Z")
        .writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"nick\":\"helper\",\"roles\":[\"10\",\"20\"],\"mute\":false,\"deaf\":true,\"channel_id\":\"30\",\"communication_disabled_until\":\"2026-06-02T10:00:00.000Z\"}",
        out.written(),
    );

    var clear = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer clear.deinit();
    try EditGuildMember.init().clearTimeout().writeJson(&clear.writer);
    try std.testing.expectEqualStrings("{\"communication_disabled_until\":null}", clear.written());
}
