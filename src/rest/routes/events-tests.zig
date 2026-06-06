const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Types = @import("../../models/types.zig");

const Root = @import("../routes.zig");
const channel = Root.channel;
const editChannel = Root.editChannel;
const editChannelPermission = Root.editChannelPermission;
const deleteChannelPermission = Root.deleteChannelPermission;
const setVoiceChannelStatus = Root.setVoiceChannelStatus;
const followAnnouncementChannel = Root.followAnnouncementChannel;
const createStageInstance = Root.createStageInstance;
const stageInstance = Root.stageInstance;
const editStageInstance = Root.editStageInstance;
const deleteStageInstance = Root.deleteStageInstance;
const currentApplication = Root.currentApplication;
const currentBotApplication = Root.currentBotApplication;
const editCurrentApplication = Root.editCurrentApplication;
const applicationRoleConnectionMetadataRecords = Root.applicationRoleConnectionMetadataRecords;
const updateApplicationRoleConnectionMetadataRecords = Root.updateApplicationRoleConnectionMetadataRecords;
const applicationEmojis = Root.applicationEmojis;
const createApplicationEmoji = Root.createApplicationEmoji;
const editApplicationEmoji = Root.editApplicationEmoji;
const deleteApplicationEmoji = Root.deleteApplicationEmoji;
const applicationActivityInstance = Root.applicationActivityInstance;
const createLobby = Root.createLobby;
const lobby = Root.lobby;
const editLobby = Root.editLobby;
const lobbyMember = Root.lobbyMember;
const bulkUpdateLobbyMembers = Root.bulkUpdateLobbyMembers;
const leaveLobby = Root.leaveLobby;
const linkLobbyChannel = Root.linkLobbyChannel;
const updateLobbyMessageModerationMetadata = Root.updateLobbyMessageModerationMetadata;
const voiceRegions = Root.voiceRegions;
const guildVoiceRegions = Root.guildVoiceRegions;
const currentUserVoiceState = Root.currentUserVoiceState;
const editCurrentUserVoiceState = Root.editCurrentUserVoiceState;
const userVoiceState = Root.userVoiceState;
const editUserVoiceState = Root.editUserVoiceState;
const currentUser = Root.currentUser;
const editCurrentUser = Root.editCurrentUser;
const user = Root.user;
const guild = Root.guild;
const guildScheduledEvents = Root.guildScheduledEvents;
const createGuildScheduledEvent = Root.createGuildScheduledEvent;
const guildScheduledEvent = Root.guildScheduledEvent;
const editGuildScheduledEvent = Root.editGuildScheduledEvent;
const deleteGuildScheduledEvent = Root.deleteGuildScheduledEvent;
const guildScheduledEventUsers = Root.guildScheduledEventUsers;
const createGuildChannel = Root.createGuildChannel;
const editGuildChannelPositions = Root.editGuildChannelPositions;
const createGuildRole = Root.createGuildRole;
const editGuildRolePositions = Root.editGuildRolePositions;
const guildRoleMemberCounts = Root.guildRoleMemberCounts;
const guildRole = Root.guildRole;
const editGuildRole = Root.editGuildRole;
const guildEmojis = Root.guildEmojis;
const createGuildEmoji = Root.createGuildEmoji;
const editGuildEmoji = Root.editGuildEmoji;
const guildStickers = Root.guildStickers;
const sticker = Root.sticker;
const stickerPacks = Root.stickerPacks;
const createGuildSticker = Root.createGuildSticker;
const editGuildSticker = Root.editGuildSticker;
const addGuildMemberRole = Root.addGuildMemberRole;
const bucketKey = Root.bucketKey;

test "guild scheduled event routes use guild as major parameter" {
    const list_route = try guildScheduledEvents(std.testing.allocator, Snowflake.init(10), .{
        .with_user_count = true,
    });
    defer list_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, list_route.method);
    try std.testing.expectEqualStrings("/guilds/10/scheduled-events?with_user_count=true", list_route.path);

    const list_key = try bucketKey(std.testing.allocator, list_route);
    defer std.testing.allocator.free(list_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/scheduled-events:10", list_key);

    const create_route = try createGuildScheduledEvent(std.testing.allocator, Snowflake.init(10));
    defer create_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, create_route.method);
    try std.testing.expectEqualStrings("/guilds/10/scheduled-events", create_route.path);

    const get_route = try guildScheduledEvent(std.testing.allocator, Snowflake.init(10), Snowflake.init(20), .{
        .with_user_count = false,
    });
    defer get_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, get_route.method);
    try std.testing.expectEqualStrings("/guilds/10/scheduled-events/20?with_user_count=false", get_route.path);

    const edit_route = try editGuildScheduledEvent(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/guilds/10/scheduled-events/20", edit_route.path);

    const delete_route = try deleteGuildScheduledEvent(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer delete_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.DELETE, delete_route.method);
    try std.testing.expectEqualStrings("/guilds/10/scheduled-events/20", delete_route.path);

    const users_route = try guildScheduledEventUsers(std.testing.allocator, Snowflake.init(10), Snowflake.init(20), .{
        .limit = 25,
        .with_member = true,
        .after = Snowflake.init(30),
    });
    defer users_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, users_route.method);
    try std.testing.expectEqualStrings("/guilds/10/scheduled-events/20/users?limit=25&with_member=true&after=30", users_route.path);

    const users_key = try bucketKey(std.testing.allocator, users_route);
    defer std.testing.allocator.free(users_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/scheduled-events/{guild_scheduled_event_id}/users:10", users_key);
}

test "stage instance routes use expected methods and buckets" {
    const create_route = try createStageInstance(std.testing.allocator);
    defer create_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, create_route.method);
    try std.testing.expectEqualStrings("/stage-instances", create_route.path);

    const get_route = try stageInstance(std.testing.allocator, Snowflake.init(10));
    defer get_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, get_route.method);
    try std.testing.expectEqualStrings("/stage-instances/10", get_route.path);

    const get_key = try bucketKey(std.testing.allocator, get_route);
    defer std.testing.allocator.free(get_key);
    try std.testing.expectEqualStrings("GET:/stage-instances/{channel_id}:10", get_key);

    const edit_route = try editStageInstance(std.testing.allocator, Snowflake.init(10));
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/stage-instances/10", edit_route.path);

    const delete_route = try deleteStageInstance(std.testing.allocator, Snowflake.init(10));
    defer delete_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.DELETE, delete_route.method);
    try std.testing.expectEqualStrings("/stage-instances/10", delete_route.path);
}

test "current application routes use applications me path" {
    const get_route = try currentApplication(std.testing.allocator);
    defer get_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, get_route.method);
    try std.testing.expectEqualStrings("/applications/@me", get_route.path);

    const get_key = try bucketKey(std.testing.allocator, get_route);
    defer std.testing.allocator.free(get_key);
    try std.testing.expectEqualStrings("GET:/applications/@me", get_key);

    const oauth_route = try currentBotApplication(std.testing.allocator);
    defer oauth_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, oauth_route.method);
    try std.testing.expectEqualStrings("/oauth2/applications/@me", oauth_route.path);

    const oauth_key = try bucketKey(std.testing.allocator, oauth_route);
    defer std.testing.allocator.free(oauth_key);
    try std.testing.expectEqualStrings("GET:/oauth2/applications/@me", oauth_key);

    const edit_route = try editCurrentApplication(std.testing.allocator);
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/applications/@me", edit_route.path);

    const metadata_route = try applicationRoleConnectionMetadataRecords(std.testing.allocator, Snowflake.init(10));
    defer metadata_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, metadata_route.method);
    try std.testing.expectEqualStrings("/applications/10/role-connections/metadata", metadata_route.path);

    const metadata_key = try bucketKey(std.testing.allocator, metadata_route);
    defer std.testing.allocator.free(metadata_key);
    try std.testing.expectEqualStrings(
        "GET:/applications/{application_id}/role-connections/metadata:10",
        metadata_key,
    );

    const update_metadata_route = try updateApplicationRoleConnectionMetadataRecords(
        std.testing.allocator,
        Snowflake.init(10),
    );
    defer update_metadata_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, update_metadata_route.method);
    try std.testing.expectEqualStrings("/applications/10/role-connections/metadata", update_metadata_route.path);
}

test "current user routes use users me path" {
    const get_route = try currentUser(std.testing.allocator);
    defer get_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, get_route.method);
    try std.testing.expectEqualStrings("/users/@me", get_route.path);

    const edit_route = try editCurrentUser(std.testing.allocator);
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/users/@me", edit_route.path);
}

test "voice routes use expected paths and guild buckets" {
    const regions_route = try voiceRegions(std.testing.allocator);
    defer regions_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, regions_route.method);
    try std.testing.expectEqualStrings("/voice/regions", regions_route.path);

    const guild_regions_route = try guildVoiceRegions(std.testing.allocator, Snowflake.init(10));
    defer guild_regions_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, guild_regions_route.method);
    try std.testing.expectEqualStrings("/guilds/10/regions", guild_regions_route.path);

    const guild_regions_key = try bucketKey(std.testing.allocator, guild_regions_route);
    defer std.testing.allocator.free(guild_regions_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/regions:10", guild_regions_key);

    const current_route = try currentUserVoiceState(std.testing.allocator, Snowflake.init(10));
    defer current_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, current_route.method);
    try std.testing.expectEqualStrings("/guilds/10/voice-states/@me", current_route.path);

    const current_key = try bucketKey(std.testing.allocator, current_route);
    defer std.testing.allocator.free(current_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/voice-states/@me:10", current_key);

    const edit_current_route = try editCurrentUserVoiceState(std.testing.allocator, Snowflake.init(10));
    defer edit_current_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_current_route.method);
    try std.testing.expectEqualStrings("/guilds/10/voice-states/@me", edit_current_route.path);

    const user_route = try userVoiceState(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer user_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, user_route.method);
    try std.testing.expectEqualStrings("/guilds/10/voice-states/20", user_route.path);

    const user_key = try bucketKey(std.testing.allocator, user_route);
    defer std.testing.allocator.free(user_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/voice-states/{user_id}:10", user_key);

    const edit_user_route = try editUserVoiceState(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer edit_user_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_user_route.method);
    try std.testing.expectEqualStrings("/guilds/10/voice-states/20", edit_user_route.path);
}

test "channel management routes use expected methods and buckets" {
    const create_route = try createGuildChannel(std.testing.allocator, Snowflake.init(10));
    defer create_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, create_route.method);
    try std.testing.expectEqualStrings("/guilds/10/channels", create_route.path);

    const create_key = try bucketKey(std.testing.allocator, create_route);
    defer std.testing.allocator.free(create_key);
    try std.testing.expectEqualStrings("POST:/guilds/{guild_id}/channels:10", create_key);

    const positions_route = try editGuildChannelPositions(std.testing.allocator, Snowflake.init(10));
    defer positions_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, positions_route.method);
    try std.testing.expectEqualStrings("/guilds/10/channels", positions_route.path);

    const positions_key = try bucketKey(std.testing.allocator, positions_route);
    defer std.testing.allocator.free(positions_key);
    try std.testing.expectEqualStrings("PATCH:/guilds/{guild_id}/channels:10", positions_key);

    const edit_route = try editChannel(std.testing.allocator, Snowflake.init(20));
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/channels/20", edit_route.path);

    const edit_key = try bucketKey(std.testing.allocator, edit_route);
    defer std.testing.allocator.free(edit_key);
    try std.testing.expectEqualStrings("PATCH:/channels/{channel_id}:20", edit_key);
}

test "channel permission routes keep channel as major parameter" {
    const edit_route = try editChannelPermission(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, edit_route.method);
    try std.testing.expectEqualStrings("/channels/10/permissions/20", edit_route.path);

    const edit_key = try bucketKey(std.testing.allocator, edit_route);
    defer std.testing.allocator.free(edit_key);
    try std.testing.expectEqualStrings("PUT:/channels/{channel_id}/permissions/{overwrite_id}:10", edit_key);

    const delete_route = try deleteChannelPermission(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer delete_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.DELETE, delete_route.method);
    try std.testing.expectEqualStrings("/channels/10/permissions/20", delete_route.path);
}

test "channel utility routes keep channel as major parameter" {
    const status_route = try setVoiceChannelStatus(std.testing.allocator, Snowflake.init(10));
    defer status_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, status_route.method);
    try std.testing.expectEqualStrings("/channels/10/voice-status", status_route.path);

    const status_key = try bucketKey(std.testing.allocator, status_route);
    defer std.testing.allocator.free(status_key);
    try std.testing.expectEqualStrings("PUT:/channels/{channel_id}/voice-status:10", status_key);

    const follow_route = try followAnnouncementChannel(std.testing.allocator, Snowflake.init(10));
    defer follow_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, follow_route.method);
    try std.testing.expectEqualStrings("/channels/10/followers", follow_route.path);

    const follow_key = try bucketKey(std.testing.allocator, follow_route);
    defer std.testing.allocator.free(follow_key);
    try std.testing.expectEqualStrings("POST:/channels/{channel_id}/followers:10", follow_key);
}

test "role management routes use guild as major parameter" {
    const create_route = try createGuildRole(std.testing.allocator, Snowflake.init(10));
    defer create_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, create_route.method);
    try std.testing.expectEqualStrings("/guilds/10/roles", create_route.path);

    const create_key = try bucketKey(std.testing.allocator, create_route);
    defer std.testing.allocator.free(create_key);
    try std.testing.expectEqualStrings("POST:/guilds/{guild_id}/roles:10", create_key);

    const positions_route = try editGuildRolePositions(std.testing.allocator, Snowflake.init(10));
    defer positions_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, positions_route.method);
    try std.testing.expectEqualStrings("/guilds/10/roles", positions_route.path);

    const positions_key = try bucketKey(std.testing.allocator, positions_route);
    defer std.testing.allocator.free(positions_key);
    try std.testing.expectEqualStrings("PATCH:/guilds/{guild_id}/roles:10", positions_key);

    const counts_route = try guildRoleMemberCounts(std.testing.allocator, Snowflake.init(10));
    defer counts_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, counts_route.method);
    try std.testing.expectEqualStrings("/guilds/10/roles/member-counts", counts_route.path);

    const counts_key = try bucketKey(std.testing.allocator, counts_route);
    defer std.testing.allocator.free(counts_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/roles/member-counts:10", counts_key);

    const get_route = try guildRole(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer get_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, get_route.method);
    try std.testing.expectEqualStrings("/guilds/10/roles/20", get_route.path);

    const get_key = try bucketKey(std.testing.allocator, get_route);
    defer std.testing.allocator.free(get_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/roles/{role_id}:10", get_key);

    const edit_route = try editGuildRole(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/guilds/10/roles/20", edit_route.path);

    const edit_key = try bucketKey(std.testing.allocator, edit_route);
    defer std.testing.allocator.free(edit_key);
    try std.testing.expectEqualStrings("PATCH:/guilds/{guild_id}/roles/{role_id}:10", edit_key);
}

test "guild emoji routes use guild as major parameter" {
    const list_route = try guildEmojis(std.testing.allocator, Snowflake.init(10));
    defer list_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, list_route.method);
    try std.testing.expectEqualStrings("/guilds/10/emojis", list_route.path);

    const list_key = try bucketKey(std.testing.allocator, list_route);
    defer std.testing.allocator.free(list_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/emojis:10", list_key);

    const create_route = try createGuildEmoji(std.testing.allocator, Snowflake.init(10));
    defer create_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, create_route.method);
    try std.testing.expectEqualStrings("/guilds/10/emojis", create_route.path);

    const edit_route = try editGuildEmoji(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/guilds/10/emojis/20", edit_route.path);

    const edit_key = try bucketKey(std.testing.allocator, edit_route);
    defer std.testing.allocator.free(edit_key);
    try std.testing.expectEqualStrings("PATCH:/guilds/{guild_id}/emojis/{emoji_id}:10", edit_key);
}

test "application emoji routes use application as major parameter" {
    const list_route = try applicationEmojis(std.testing.allocator, Snowflake.init(10));
    defer list_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, list_route.method);
    try std.testing.expectEqualStrings("/applications/10/emojis", list_route.path);

    const list_key = try bucketKey(std.testing.allocator, list_route);
    defer std.testing.allocator.free(list_key);
    try std.testing.expectEqualStrings("GET:/applications/{application_id}/emojis:10", list_key);

    const create_route = try createApplicationEmoji(std.testing.allocator, Snowflake.init(10));
    defer create_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, create_route.method);
    try std.testing.expectEqualStrings("/applications/10/emojis", create_route.path);

    const edit_route = try editApplicationEmoji(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/applications/10/emojis/20", edit_route.path);

    const edit_key = try bucketKey(std.testing.allocator, edit_route);
    defer std.testing.allocator.free(edit_key);
    try std.testing.expectEqualStrings("PATCH:/applications/{application_id}/emojis/{emoji_id}:10", edit_key);

    const delete_route = try deleteApplicationEmoji(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer delete_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.DELETE, delete_route.method);
    try std.testing.expectEqualStrings("/applications/10/emojis/20", delete_route.path);

    const activity_instance_route = try applicationActivityInstance(
        std.testing.allocator,
        Snowflake.init(10),
        "abc:def 123",
    );
    defer activity_instance_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, activity_instance_route.method);
    try std.testing.expectEqualStrings("/applications/10/activity-instances/abc%3Adef%20123", activity_instance_route.path);

    const activity_instance_key = try bucketKey(std.testing.allocator, activity_instance_route);
    defer std.testing.allocator.free(activity_instance_key);
    try std.testing.expectEqualStrings(
        "GET:/applications/{application_id}/activity-instances/{instance_id}:10",
        activity_instance_key,
    );
}

test "lobby routes use lobby as major parameter" {
    const create_route = try createLobby(std.testing.allocator);
    defer create_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, create_route.method);
    try std.testing.expectEqualStrings("/lobbies", create_route.path);

    const create_key = try bucketKey(std.testing.allocator, create_route);
    defer std.testing.allocator.free(create_key);
    try std.testing.expectEqualStrings("POST:/lobbies", create_key);

    const get_route = try lobby(std.testing.allocator, Snowflake.init(10));
    defer get_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, get_route.method);
    try std.testing.expectEqualStrings("/lobbies/10", get_route.path);

    const get_key = try bucketKey(std.testing.allocator, get_route);
    defer std.testing.allocator.free(get_key);
    try std.testing.expectEqualStrings("GET:/lobbies/{lobby_id}:10", get_key);

    const edit_route = try editLobby(std.testing.allocator, Snowflake.init(10));
    defer edit_route.deinit(std.testing.allocator);
    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/lobbies/10", edit_route.path);

    const member_route = try lobbyMember(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer member_route.deinit(std.testing.allocator);
    try std.testing.expectEqual(.PUT, member_route.method);
    try std.testing.expectEqualStrings("/lobbies/10/members/20", member_route.path);

    const member_key = try bucketKey(std.testing.allocator, member_route);
    defer std.testing.allocator.free(member_key);
    try std.testing.expectEqualStrings("PUT:/lobbies/{lobby_id}/members/{user_id}:10", member_key);

    const bulk_route = try bulkUpdateLobbyMembers(std.testing.allocator, Snowflake.init(10));
    defer bulk_route.deinit(std.testing.allocator);
    try std.testing.expectEqual(.POST, bulk_route.method);
    try std.testing.expectEqualStrings("/lobbies/10/members/bulk", bulk_route.path);

    const leave_route = try leaveLobby(std.testing.allocator, Snowflake.init(10));
    defer leave_route.deinit(std.testing.allocator);
    try std.testing.expectEqual(.DELETE, leave_route.method);
    try std.testing.expectEqualStrings("/lobbies/10/members/@me", leave_route.path);

    const link_route = try linkLobbyChannel(std.testing.allocator, Snowflake.init(10));
    defer link_route.deinit(std.testing.allocator);
    try std.testing.expectEqual(.PATCH, link_route.method);
    try std.testing.expectEqualStrings("/lobbies/10/channel-linking", link_route.path);

    const moderation_route = try updateLobbyMessageModerationMetadata(
        std.testing.allocator,
        Snowflake.init(10),
        Snowflake.init(30),
    );
    defer moderation_route.deinit(std.testing.allocator);
    try std.testing.expectEqual(.PUT, moderation_route.method);
    try std.testing.expectEqualStrings("/lobbies/10/messages/30/moderation-metadata", moderation_route.path);

    const moderation_key = try bucketKey(std.testing.allocator, moderation_route);
    defer std.testing.allocator.free(moderation_key);
    try std.testing.expectEqualStrings(
        "PUT:/lobbies/{lobby_id}/messages/{message_id}/moderation-metadata:10",
        moderation_key,
    );
}

test "guild sticker routes use guild as major parameter" {
    const sticker_route = try sticker(std.testing.allocator, Snowflake.init(20));
    defer sticker_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, sticker_route.method);
    try std.testing.expectEqualStrings("/stickers/20", sticker_route.path);

    const sticker_key = try bucketKey(std.testing.allocator, sticker_route);
    defer std.testing.allocator.free(sticker_key);
    try std.testing.expectEqualStrings("GET:/stickers/{sticker_id}:20", sticker_key);

    const packs_route = try stickerPacks(std.testing.allocator);
    defer packs_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, packs_route.method);
    try std.testing.expectEqualStrings("/sticker-packs", packs_route.path);

    const packs_key = try bucketKey(std.testing.allocator, packs_route);
    defer std.testing.allocator.free(packs_key);
    try std.testing.expectEqualStrings("GET:/sticker-packs", packs_key);

    const list_route = try guildStickers(std.testing.allocator, Snowflake.init(10));
    defer list_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.GET, list_route.method);
    try std.testing.expectEqualStrings("/guilds/10/stickers", list_route.path);

    const list_key = try bucketKey(std.testing.allocator, list_route);
    defer std.testing.allocator.free(list_key);
    try std.testing.expectEqualStrings("GET:/guilds/{guild_id}/stickers:10", list_key);

    const create_route = try createGuildSticker(std.testing.allocator, Snowflake.init(10));
    defer create_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.POST, create_route.method);
    try std.testing.expectEqualStrings("/guilds/10/stickers", create_route.path);

    const edit_route = try editGuildSticker(std.testing.allocator, Snowflake.init(10), Snowflake.init(20));
    defer edit_route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PATCH, edit_route.method);
    try std.testing.expectEqualStrings("/guilds/10/stickers/20", edit_route.path);

    const edit_key = try bucketKey(std.testing.allocator, edit_route);
    defer std.testing.allocator.free(edit_key);
    try std.testing.expectEqualStrings("PATCH:/guilds/{guild_id}/stickers/{sticker_id}:10", edit_key);
}

test "member role routes use guild as major parameter" {
    const route = try addGuildMemberRole(
        std.testing.allocator,
        Snowflake.init(10),
        Snowflake.init(20),
        Snowflake.init(30),
    );
    defer route.deinit(std.testing.allocator);

    try std.testing.expectEqual(.PUT, route.method);
    try std.testing.expectEqualStrings("/guilds/10/members/20/roles/30", route.path);

    const key = try bucketKey(std.testing.allocator, route);
    defer std.testing.allocator.free(key);
    try std.testing.expectEqualStrings(
        "PUT:/guilds/{guild_id}/members/{user_id}/roles/{role_id}:10",
        key,
    );
}
