const std = @import("std");
const Api = @import("../../core/api.zig");
const Routes = @import("../routes.zig");
const Types = @import("../../models/types.zig");
const Interactions = @import("../../interactions/mod.zig");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;

const Root = @import("../client.zig");
const Header = Root.Header;
const Request = Root.Request;
const BodyStream = Root.BodyStream;
const Response = Root.Response;
const Transport = Root.Transport;
const RateLimitState = Root.RateLimitState;
const Client = Root.Client;
const MultipartFilePathStream = Root.MultipartFilePathStream;
const writeMessageMultipart = Root.writeMessageMultipart;
const writeExecuteWebhookMultipart = Root.writeExecuteWebhookMultipart;
const writeGuildStickerMultipart = Root.writeGuildStickerMultipart;
const writeInviteTargetUsersMultipart = Root.writeInviteTargetUsersMultipart;
const writeMessageMultipartFilePaths = Root.writeMessageMultipartFilePaths;
const writeMessageMultipartFilePathMetadata = Root.writeMessageMultipartFilePathMetadata;
const writeMultipartPayloadJson = Root.writeMultipartPayloadJson;
const writeMultipartTextField = Root.writeMultipartTextField;
const writeMultipartFileHeader = Root.writeMultipartFileHeader;
const writeMultipartQuoted = Root.writeMultipartQuoted;
const MemoryTransport = Root.MemoryTransport;

test "REST channel management helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.createGuildChannel(
        Snowflake.init(10),
        Types.CreateGuildChannel.init("general")
            .withType(.guild_text)
            .withTopic("Project chat"),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/channels",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"general\",\"type\":0,\"topic\":\"Project chat\"}",
        memory.last_request.?.body.?,
    );

    const positions = [_]Types.GuildChannelPosition{
        Types.GuildChannelPosition.init(Snowflake.init(20)).withPosition(2),
        Types.GuildChannelPosition.init(Snowflake.init(30)).clearParent(),
    };
    _ = try client.editGuildChannelPositions(Snowflake.init(10), &positions);
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/channels",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "[{\"id\":\"20\",\"position\":2},{\"id\":\"30\",\"parent_id\":null}]",
        memory.last_request.?.body.?,
    );

    _ = try client.editChannel(
        Snowflake.init(20),
        Types.EditChannel.init()
            .withName("renamed")
            .archivedState(false)
            .lockedState(false)
            .invitableState(true)
            .withAppliedTags(&.{Snowflake.init(40)})
            .withFlags(Types.ChannelFlags.require_tag)
            .withAvailableTags(&.{Types.WriteForumTag.init("Help").withEmojiName("❓")})
            .withDefaultReactionEmoji(Types.DefaultReactionEmoji.name("❓"))
            .withDefaultSortOrder(.creation_date)
            .withDefaultForumLayout(.gallery_view),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"renamed\",\"flags\":16,\"available_tags\":[{\"name\":\"Help\",\"emoji_name\":\"❓\"}],\"default_reaction_emoji\":{\"emoji_name\":\"❓\"},\"default_sort_order\":1,\"default_forum_layout\":2,\"archived\":false,\"locked\":false,\"invitable\":true,\"applied_tags\":[\"40\"]}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteChannel(Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/20",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);
}

test "REST channel permission helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 204,
        .body = "",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.editChannelPermission(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.EditChannelPermission.init(.member)
            .withAllow(1024)
            .withDeny(2048),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/permissions/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"type\":1,\"allow\":\"1024\",\"deny\":\"2048\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteChannelPermission(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/permissions/20",
        memory.last_request.?.url,
    );
    try std.testing.expect(memory.last_request.?.body == null);
}

test "REST channel utility helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.setVoiceChannelStatus(Snowflake.init(10), Types.SetVoiceChannelStatus.init("Focus room"));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/voice-status",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"status\":\"Focus room\"}", memory.last_request.?.body.?);

    _ = try client.followAnnouncementChannel(Snowflake.init(10), Types.FollowAnnouncementChannel.init(Snowflake.init(20)));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/followers",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"webhook_channel_id\":\"20\"}", memory.last_request.?.body.?);

    _ = try client.sendSoundboardSound(
        Snowflake.init(10),
        Types.SendSoundboardSound.init(Snowflake.init(40)).fromGuild(Snowflake.init(50)),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/send-soundboard-sound",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"sound_id\":\"40\",\"source_guild_id\":\"50\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.createStageInstance(
        Types.CreateStageInstance.init(Snowflake.init(30), "Live Q&A").sendStartNotification(true),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/stage-instances", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"channel_id\":\"30\",\"topic\":\"Live Q&A\",\"send_start_notification\":true}",
        memory.last_request.?.body.?,
    );

    _ = try client.getStageInstance(Snowflake.init(30));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/stage-instances/30", memory.last_request.?.url);

    _ = try client.editStageInstance(Snowflake.init(30), Types.EditStageInstance.init().withTopic("Aftershow"));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/stage-instances/30", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"topic\":\"Aftershow\"}", memory.last_request.?.body.?);

    _ = try client.deleteStageInstance(Snowflake.init(30));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/stage-instances/30", memory.last_request.?.url);

    _ = try client.listVoiceRegions();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/voice/regions", memory.last_request.?.url);

    _ = try client.listGuildVoiceRegions(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/regions", memory.last_request.?.url);

    _ = try client.getCurrentUserVoiceState(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/voice-states/@me", memory.last_request.?.url);

    _ = try client.getUserVoiceState(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/voice-states/20", memory.last_request.?.url);

    _ = try client.editCurrentUserVoiceState(
        Snowflake.init(10),
        Types.EditCurrentUserVoiceState.init()
            .withChannel(Snowflake.init(30))
            .clearRequestToSpeak(),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/voice-states/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"channel_id\":\"30\",\"request_to_speak_timestamp\":null}",
        memory.last_request.?.body.?,
    );

    _ = try client.editUserVoiceState(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.EditUserVoiceState.init()
            .withChannel(Snowflake.init(30))
            .suppressState(true),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/voice-states/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"channel_id\":\"30\",\"suppress\":true}",
        memory.last_request.?.body.?,
    );
}

test "REST role management helpers use expected routes and payloads" {
    var memory = MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, "Bot test", memory.transport());
    defer client.deinit();

    _ = try client.listGuildRoles(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/roles",
        memory.last_request.?.url,
    );

    _ = try client.getGuildRole(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/roles/20",
        memory.last_request.?.url,
    );

    _ = try client.getGuildRoleMemberCounts(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/roles/member-counts",
        memory.last_request.?.url,
    );

    _ = try client.createGuildRole(
        Snowflake.init(10),
        Types.CreateGuildRole.init("moderator")
            .withPermissions(8192)
            .withColors(Types.RoleColors.init(0x5865F2).withSecondary(0xE558F2))
            .withIcon("data:image/png;base64,abc")
            .mentionableState(true),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "{\"name\":\"moderator\",\"permissions\":\"8192\",\"colors\":{\"primary_color\":5793266,\"secondary_color\":15030514,\"tertiary_color\":null},\"icon\":\"data:image/png;base64,abc\",\"mentionable\":true}",
        memory.last_request.?.body.?,
    );

    const positions = [_]Types.GuildRolePosition{
        Types.GuildRolePosition.init(Snowflake.init(20)).withPosition(2),
        Types.GuildRolePosition.init(Snowflake.init(30)).clearPosition(),
    };
    _ = try client.editGuildRolePositions(Snowflake.init(10), &positions);
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/roles",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "[{\"id\":\"20\",\"position\":2},{\"id\":\"30\",\"position\":null}]",
        memory.last_request.?.body.?,
    );

    _ = try client.editGuildRole(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.EditGuildRole.init()
            .withName("helpers")
            .hoisted(false)
            .clearIcon()
            .withUnicodeEmoji("⚡"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/roles/20",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings(
        "{\"name\":\"helpers\",\"hoist\":false,\"icon\":null,\"unicode_emoji\":\"⚡\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteGuildRole(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/guilds/10/roles/20",
        memory.last_request.?.url,
    );
}
