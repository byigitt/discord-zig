const std = @import("std");
const Intents = @import("../../../core/intents.zig");
const Rest = @import("../../../rest/client.zig");
const HttpTransport = @import("../../../rest/http_transport.zig").HttpTransport;
const Events = @import("../../../gateway/events.zig");
const Gateway = @import("../../../gateway/protocol.zig");
const GatewaySession = @import("../../../gateway/session.zig");
const CacheModule = @import("../../cache.zig");
const Interactions = @import("../../../interactions/mod.zig");
const Types = @import("../../../models/types.zig");
const Snowflake = @import("../../../core/snowflake.zig").Snowflake;
const Root = @import("../../client.zig");
const Cache = Root.Cache;
const ClientOptions = Root.ClientOptions;
const SetActivityOptions = Root.SetActivityOptions;
const Client = Root.Client;
const GatewayStep = Root.GatewayStep;
const GatewayStartMode = Root.GatewayStartMode;
const ReconnectBackoff = Root.ReconnectBackoff;
const GatewayRunner = Root.GatewayRunner;
const noTransportValue = Root.noTransportValue;
const noTransportSend = Root.noTransportSend;

test "client convenience send reply and react delegate to REST part 5" {
    var memory = Rest.MemoryTransport.init(std.testing.allocator, .{
        .status = 200,
        .body = "{}",
    });
    defer memory.deinit();

    var client = Client.init(std.testing.allocator, .{
        .token = "Bot test",
        .transport = memory.transport(),
    });
    defer client.deinit();
    _ = try client.editChannel(
        Snowflake.init(20),
        Types.EditChannel.init()
            .withName("announcements")
            .archivedState(true)
            .lockedState(true)
            .withAutoArchiveDuration(1440),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"announcements\",\"archived\":true,\"auto_archive_duration\":1440,\"locked\":true}",
        memory.last_request.?.body.?,
    );

    _ = try client.deleteChannel(Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/20", memory.last_request.?.url);

    _ = try client.editChannelPermission(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.EditChannelPermission.init(.role).withAllow(1024),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/permissions/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"type\":0,\"allow\":\"1024\"}", memory.last_request.?.body.?);

    _ = try client.setChannelPermission(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.EditChannelPermission.init(.role).withAllow(1024),
    );
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/permissions/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"type\":0,\"allow\":\"1024\"}", memory.last_request.?.body.?);

    _ = try client.deleteChannelPermission(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/permissions/20", memory.last_request.?.url);

    _ = try client.removeChannelPermission(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/permissions/20", memory.last_request.?.url);

    _ = try client.setVoiceChannelStatus(Snowflake.init(10), Types.SetVoiceChannelStatus.clear());
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/voice-status", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"status\":null}", memory.last_request.?.body.?);

    _ = try client.setVoiceChannelStatusText(Snowflake.init(10), "Focus room");
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/voice-status", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"status\":\"Focus room\"}", memory.last_request.?.body.?);

    _ = try client.clearVoiceChannelStatus(Snowflake.init(10));
    try std.testing.expectEqual(.PUT, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/voice-status", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"status\":null}", memory.last_request.?.body.?);

    _ = try client.followAnnouncementChannel(Snowflake.init(10), Types.FollowAnnouncementChannel.init(Snowflake.init(30)));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/followers", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"webhook_channel_id\":\"30\"}", memory.last_request.?.body.?);

    _ = try client.followAnnouncementChannelTo(Snowflake.init(10), Snowflake.init(31));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/followers", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"webhook_channel_id\":\"31\"}", memory.last_request.?.body.?);

    _ = try client.followNewsChannel(Snowflake.init(10), Types.FollowAnnouncementChannel.init(Snowflake.init(32)));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/followers", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"webhook_channel_id\":\"32\"}", memory.last_request.?.body.?);

    _ = try client.followNewsChannelTo(Snowflake.init(10), Snowflake.init(33));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/channels/10/followers", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"webhook_channel_id\":\"33\"}", memory.last_request.?.body.?);

    _ = try client.sendSoundboardSound(Snowflake.init(10), Types.SendSoundboardSound.init(Snowflake.init(40)));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/send-soundboard-sound",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"sound_id\":\"40\"}", memory.last_request.?.body.?);

    _ = try client.sendSoundboardSoundById(Snowflake.init(10), Snowflake.init(41));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/send-soundboard-sound",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"sound_id\":\"41\"}", memory.last_request.?.body.?);

    _ = try client.playSoundboardSound(Snowflake.init(10), Snowflake.init(42));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings(
        "https://discord.com/api/v10/channels/10/send-soundboard-sound",
        memory.last_request.?.url,
    );
    try std.testing.expectEqualStrings("{\"sound_id\":\"42\"}", memory.last_request.?.body.?);

    _ = try client.createStageInstance(
        Types.CreateStageInstance.init(Snowflake.init(10), "Live Q&A")
            .withScheduledEvent(Snowflake.init(40)),
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/stage-instances", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"channel_id\":\"10\",\"topic\":\"Live Q&A\",\"guild_scheduled_event_id\":\"40\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.fetchStageInstance(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/stage-instances/10", memory.last_request.?.url);

    _ = try client.editStageInstance(Snowflake.init(10), Types.EditStageInstance.init().withTopic("Aftershow"));
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/stage-instances/10", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"topic\":\"Aftershow\"}", memory.last_request.?.body.?);

    _ = try client.fetchVoiceRegions();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/voice/regions", memory.last_request.?.url);

    _ = try client.listGuildVoiceRegions(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/regions", memory.last_request.?.url);

    _ = try client.fetchGuildVoiceRegions(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/regions", memory.last_request.?.url);

    _ = try client.fetchCurrentUserVoiceState(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/voice-states/@me", memory.last_request.?.url);

    _ = try client.fetchUserVoiceState(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/voice-states/20", memory.last_request.?.url);

    _ = try client.editCurrentUserVoiceState(
        Snowflake.init(10),
        Types.EditCurrentUserVoiceState.init()
            .suppressState(false)
            .requestToSpeakAt("2026-06-02T10:00:00.000Z"),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/voice-states/@me", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"suppress\":false,\"request_to_speak_timestamp\":\"2026-06-02T10:00:00.000Z\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.fetchRoles(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/roles", memory.last_request.?.url);

    _ = try client.fetchRole(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/roles/20", memory.last_request.?.url);

    _ = try client.getGuildRoleMemberCounts(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/roles/member-counts", memory.last_request.?.url);

    _ = try client.fetchRoleMemberCounts(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/roles/member-counts", memory.last_request.?.url);

    _ = try client.createRoleWithName(Snowflake.init(10), "helpers");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/roles", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"helpers\"}", memory.last_request.?.body.?);

    const positions = [_]Types.GuildRolePosition{Types.GuildRolePosition.init(Snowflake.init(20)).withPosition(3)};
    _ = try client.editGuildRolePositions(Snowflake.init(10), &positions);
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/roles", memory.last_request.?.url);
    try std.testing.expectEqualStrings("[{\"id\":\"20\",\"position\":3}]", memory.last_request.?.body.?);

    _ = try client.editGuildRole(
        Snowflake.init(10),
        Snowflake.init(20),
        Types.EditGuildRole.init()
            .withColors(Types.RoleColors.init(5793266))
            .mentionableState(true)
            .clearUnicodeEmoji(),
    );
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/roles/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"colors\":{\"primary_color\":5793266,\"secondary_color\":null,\"tertiary_color\":null},\"unicode_emoji\":null,\"mentionable\":true}",
        memory.last_request.?.body.?,
    );

    _ = try client.renameRole(Snowflake.init(10), Snowflake.init(20), "helpers-renamed");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/roles/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"helpers-renamed\"}", memory.last_request.?.body.?);

    _ = try client.fetchEmojis(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/emojis", memory.last_request.?.url);

    _ = try client.fetchEmoji(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/emojis/20", memory.last_request.?.url);

    _ = try client.createGuildEmoji(Snowflake.init(10), Types.CreateGuildEmoji.init("zig", "data:image/webp;base64,abc"));
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/emojis", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"zig\",\"image\":\"data:image/webp;base64,abc\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.createEmojiWithImage(Snowflake.init(10), "ziggy", "data:image/webp;base64,def");
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/emojis", memory.last_request.?.url);
    try std.testing.expectEqualStrings(
        "{\"name\":\"ziggy\",\"image\":\"data:image/webp;base64,def\"}",
        memory.last_request.?.body.?,
    );

    _ = try client.renameEmoji(Snowflake.init(10), Snowflake.init(20), "zig-renamed");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/emojis/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"zig-renamed\"}", memory.last_request.?.body.?);

    _ = try client.deleteGuildEmoji(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/emojis/20", memory.last_request.?.url);

    _ = try client.fetchStickerById(Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/stickers/20", memory.last_request.?.url);

    _ = try client.fetchStickerPacks();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/sticker-packs", memory.last_request.?.url);

    _ = try client.fetchStickers(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/stickers", memory.last_request.?.url);

    _ = try client.fetchSticker(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/stickers/20", memory.last_request.?.url);

    _ = try client.createGuildSticker(
        Snowflake.init(10),
        Types.CreateGuildSticker.init("zig", "zap"),
        .{ .filename = "zig.png", .content = "PNG", .content_type = "image/png" },
    );
    try std.testing.expectEqual(.POST, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/stickers", memory.last_request.?.url);
    try std.testing.expect(std.mem.indexOf(u8, memory.last_request.?.body.?, "name=\"file\"; filename=\"zig.png\"") != null);

    _ = try client.renameSticker(Snowflake.init(10), Snowflake.init(20), "zig-renamed");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/stickers/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"name\":\"zig-renamed\"}", memory.last_request.?.body.?);

    _ = try client.setStickerDescription(Snowflake.init(10), Snowflake.init(20), "Zig sticker");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/stickers/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"description\":\"Zig sticker\"}", memory.last_request.?.body.?);

    _ = try client.setStickerTags(Snowflake.init(10), Snowflake.init(20), "zig,zap");
    try std.testing.expectEqual(.PATCH, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/stickers/20", memory.last_request.?.url);
    try std.testing.expectEqualStrings("{\"tags\":\"zig,zap\"}", memory.last_request.?.body.?);

    _ = try client.deleteGuildSticker(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.DELETE, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/stickers/20", memory.last_request.?.url);

    _ = try client.fetchDefaultSoundboardSounds();
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/soundboard-default-sounds", memory.last_request.?.url);

    _ = try client.fetchGuildSoundboardSounds(Snowflake.init(10));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/soundboard-sounds", memory.last_request.?.url);

    _ = try client.fetchGuildSoundboardSound(Snowflake.init(10), Snowflake.init(20));
    try std.testing.expectEqual(.GET, memory.last_request.?.method);
    try std.testing.expectEqualStrings("https://discord.com/api/v10/guilds/10/soundboard-sounds/20", memory.last_request.?.url);
}
