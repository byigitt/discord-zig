const std = @import("std");
const Snowflake = @import("../core/snowflake.zig").Snowflake;
const Types = @import("../models/types.zig");
const Collection = @import("../core/collection.zig").Collection;

test {
    _ = @import("cache-tests/ready-test.zig");
    _ = @import("cache-tests/presence-test.zig");
    _ = @import("cache-tests/reactions-test.zig");
    _ = @import("cache-tests/collection-test.zig");
    _ = @import("cache-tests/resources-test.zig");
    _ = @import("cache-tests/channels-test.zig");
    _ = @import("cache-tests/threads-test.zig");
}

pub const CachePolicy = struct {
    users: bool = true,
    guilds: bool = true,
    channels: bool = true,
    members: bool = true,
    roles: bool = true,
    emojis: bool = true,
    stickers: bool = true,
    scheduled_events: bool = true,
    stage_instances: bool = true,
    invites: bool = true,
    presences: bool = true,
    voice_states: bool = true,
    messages: bool = true,
    max_messages: ?usize = 1000,
    /// When set, `sweep` evicts cached messages older than this age in
    /// milliseconds (creation time derived from the message snowflake).
    message_sweep_max_age_ms: ?u64 = null,

    pub fn default() CachePolicy {
        return .{};
    }

    pub fn noMessages() CachePolicy {
        return .{ .messages = false, .max_messages = 0 };
    }

    pub fn minimal() CachePolicy {
        return .{ .users = false, .guilds = false, .channels = false, .members = false, .roles = false, .emojis = false, .stickers = false, .scheduled_events = false, .stage_instances = false, .invites = false, .presences = false, .voice_states = false, .messages = false, .max_messages = 0 };
    }
};

pub const CacheStats = struct {
    users: usize = 0,
    current_user: bool = false,
    current_application: bool = false,
    guilds: usize = 0,
    channels: usize = 0,
    members: usize = 0,
    roles: usize = 0,
    emojis: usize = 0,
    stickers: usize = 0,
    scheduled_events: usize = 0,
    stage_instances: usize = 0,
    invites: usize = 0,
    presences: usize = 0,
    voice_states: usize = 0,
    messages: usize = 0,
};

pub const GuildCacheStats = struct {
    channels: usize = 0,
    threads: usize = 0,
    members: usize = 0,
    roles: usize = 0,
    emojis: usize = 0,
    stickers: usize = 0,
    scheduled_events: usize = 0,
    stage_instances: usize = 0,
    invites: usize = 0,
    presences: usize = 0,
    voice_states: usize = 0,
    messages: usize = 0,
};

pub const ChannelCacheStats = struct {
    threads: usize = 0,
    invites: usize = 0,
    voice_states: usize = 0,
    messages: usize = 0,
};

pub const Cache = struct {
    allocator: std.mem.Allocator,
    policy: CachePolicy,
    users: std.AutoHashMap(u64, OwnedUser),
    current_user_id: ?Snowflake,
    current_application: ?Types.Application,
    guilds: std.AutoHashMap(u64, OwnedGuild),
    channels: std.AutoHashMap(u64, OwnedChannel),
    members: std.AutoHashMap(u128, OwnedGuildMember),
    roles: std.AutoHashMap(u128, OwnedRole),
    emojis: std.AutoHashMap(u128, OwnedEmoji),
    stickers: std.AutoHashMap(u128, OwnedSticker),
    scheduled_events: std.AutoHashMap(u128, OwnedScheduledEvent),
    stage_instances: std.AutoHashMap(u128, OwnedStageInstance),
    invites: std.StringHashMap(OwnedInvite),
    presences: std.AutoHashMap(u128, OwnedPresence),
    voice_states: std.AutoHashMap(u128, OwnedVoiceState),
    messages: std.AutoHashMap(u64, OwnedMessage),
    message_order: std.array_list.Managed(u64),

    /// Snapshots cached guilds into a Discord.js-style `Collection` keyed by id,
    /// giving `find`/`filter`/`first`/iteration ergonomics over the live cache.
    /// Values borrow cache-owned memory and stay valid until the cache mutates;
    /// the caller owns the returned collection and must `deinit` it.
    /// Snapshots cached channels into a Discord.js-style `Collection` keyed by
    /// id. Values borrow cache-owned memory; the caller owns and `deinit`s the
    /// returned collection.
    /// Snapshots cached users into a Discord.js-style `Collection` keyed by id.
    /// Values borrow cache-owned memory; the caller owns and `deinit`s the
    /// returned collection.
    /// Snapshots all cached roles into a Discord.js-style `Collection` keyed by
    /// id. Values borrow cache-owned memory; the caller owns and `deinit`s the
    /// returned collection.
    /// Evicts cached messages created before `cutoff_ms` (Unix milliseconds),
    /// deriving each message's creation time from its snowflake id. Returns the
    /// number of messages removed.
    /// Evicts cached messages older than `max_age_ms` relative to `now_ms`
    /// (both Unix milliseconds). Returns the number of messages removed.
    /// Applies the configured cache sweepers at time `now_ms` (Unix ms) and
    /// returns how many entries were evicted. Call this from a runtime timer to
    /// schedule periodic sweeps; `CachePolicy` controls what is swept.
    const identity_guild_collections_methods = @import("cache-methods/identity-guild.zig").Methods(@This());
    const collection_views_cleanup_methods = @import("cache-methods/collection-cleanup.zig").Methods(@This());
    const guild_dispatch_hydration_methods = @import("cache-methods/guild-hydration.zig").Methods(@This());
    const message_dispatch_updates_methods = @import("cache-methods/message-updates.zig").Methods(@This());
    pub const init = identity_guild_collections_methods.init;
    pub const initWithPolicy = identity_guild_collections_methods.initWithPolicy;
    pub const deinit = identity_guild_collections_methods.deinit;
    pub const applyDispatch = identity_guild_collections_methods.applyDispatch;
    pub const getUser = identity_guild_collections_methods.getUser;
    pub const hasUser = identity_guild_collections_methods.hasUser;
    pub const getCurrentUser = identity_guild_collections_methods.getCurrentUser;
    pub const currentUserId = identity_guild_collections_methods.currentUserId;
    pub const hasCurrentUser = identity_guild_collections_methods.hasCurrentUser;
    pub const getCurrentApplication = identity_guild_collections_methods.getCurrentApplication;
    pub const currentApplicationId = identity_guild_collections_methods.currentApplicationId;
    pub const hasCurrentApplication = identity_guild_collections_methods.hasCurrentApplication;
    pub const getGuild = identity_guild_collections_methods.getGuild;
    pub const hasGuild = identity_guild_collections_methods.hasGuild;
    pub const getChannel = identity_guild_collections_methods.getChannel;
    pub const hasChannel = identity_guild_collections_methods.hasChannel;
    pub const getMember = identity_guild_collections_methods.getMember;
    pub const hasMember = identity_guild_collections_methods.hasMember;
    pub const getRole = identity_guild_collections_methods.getRole;
    pub const hasRole = identity_guild_collections_methods.hasRole;
    pub const getEmoji = identity_guild_collections_methods.getEmoji;
    pub const hasEmoji = identity_guild_collections_methods.hasEmoji;
    pub const getSticker = identity_guild_collections_methods.getSticker;
    pub const hasSticker = identity_guild_collections_methods.hasSticker;
    pub const getScheduledEvent = identity_guild_collections_methods.getScheduledEvent;
    pub const hasScheduledEvent = identity_guild_collections_methods.hasScheduledEvent;
    pub const getStageInstance = identity_guild_collections_methods.getStageInstance;
    pub const hasStageInstance = identity_guild_collections_methods.hasStageInstance;
    pub const getInvite = identity_guild_collections_methods.getInvite;
    pub const hasInvite = identity_guild_collections_methods.hasInvite;
    pub const getPresence = identity_guild_collections_methods.getPresence;
    pub const hasPresence = identity_guild_collections_methods.hasPresence;
    pub const getVoiceState = identity_guild_collections_methods.getVoiceState;
    pub const hasVoiceState = identity_guild_collections_methods.hasVoiceState;
    pub const getMessage = identity_guild_collections_methods.getMessage;
    pub const hasMessage = identity_guild_collections_methods.hasMessage;
    pub const clear = identity_guild_collections_methods.clear;
    pub const stats = identity_guild_collections_methods.stats;
    pub const guildStats = identity_guild_collections_methods.guildStats;
    pub const channelStats = identity_guild_collections_methods.channelStats;
    pub const listUsers = identity_guild_collections_methods.listUsers;
    pub const listGuilds = identity_guild_collections_methods.listGuilds;
    pub const listChannels = identity_guild_collections_methods.listChannels;
    pub const collectGuilds = identity_guild_collections_methods.collectGuilds;
    pub const collectChannels = identity_guild_collections_methods.collectChannels;
    pub const collectUsers = identity_guild_collections_methods.collectUsers;
    pub const collectRoles = identity_guild_collections_methods.collectRoles;
    pub const listTopLevelChannels = identity_guild_collections_methods.listTopLevelChannels;
    pub const listGuildChannels = identity_guild_collections_methods.listGuildChannels;
    pub const listChannelThreads = identity_guild_collections_methods.listChannelThreads;
    pub const listGuildThreads = identity_guild_collections_methods.listGuildThreads;
    pub const listGuildMembers = collection_views_cleanup_methods.listGuildMembers;
    pub const listMembers = collection_views_cleanup_methods.listMembers;
    pub const listGuildRoles = collection_views_cleanup_methods.listGuildRoles;
    pub const listRoles = collection_views_cleanup_methods.listRoles;
    pub const listGuildEmojis = collection_views_cleanup_methods.listGuildEmojis;
    pub const listEmojis = collection_views_cleanup_methods.listEmojis;
    pub const listGuildStickers = collection_views_cleanup_methods.listGuildStickers;
    pub const listStickers = collection_views_cleanup_methods.listStickers;
    pub const listGuildScheduledEvents = collection_views_cleanup_methods.listGuildScheduledEvents;
    pub const listScheduledEvents = collection_views_cleanup_methods.listScheduledEvents;
    pub const listGuildStageInstances = collection_views_cleanup_methods.listGuildStageInstances;
    pub const listStageInstances = collection_views_cleanup_methods.listStageInstances;
    pub const listGuildInvites = collection_views_cleanup_methods.listGuildInvites;
    pub const listInvites = collection_views_cleanup_methods.listInvites;
    pub const listChannelInvites = collection_views_cleanup_methods.listChannelInvites;
    pub const listPresences = collection_views_cleanup_methods.listPresences;
    pub const listGuildPresences = collection_views_cleanup_methods.listGuildPresences;
    pub const listVoiceStates = collection_views_cleanup_methods.listVoiceStates;
    pub const listGuildVoiceStates = collection_views_cleanup_methods.listGuildVoiceStates;
    pub const listChannelMessages = collection_views_cleanup_methods.listChannelMessages;
    pub const listMessages = collection_views_cleanup_methods.listMessages;
    pub const listGuildMessages = collection_views_cleanup_methods.listGuildMessages;
    pub const putUser = collection_views_cleanup_methods.putUser;
    pub const putCurrentUser = collection_views_cleanup_methods.putCurrentUser;
    pub const removeUser = collection_views_cleanup_methods.removeUser;
    pub const putCurrentApplication = collection_views_cleanup_methods.putCurrentApplication;
    pub const removeCurrentApplication = collection_views_cleanup_methods.removeCurrentApplication;
    pub const putGuild = collection_views_cleanup_methods.putGuild;
    pub const removeGuild = collection_views_cleanup_methods.removeGuild;
    pub const putChannel = collection_views_cleanup_methods.putChannel;
    pub const removeChannel = collection_views_cleanup_methods.removeChannel;
    pub const putMember = collection_views_cleanup_methods.putMember;
    pub const removeMember = collection_views_cleanup_methods.removeMember;
    pub const putRole = collection_views_cleanup_methods.putRole;
    pub const removeRole = collection_views_cleanup_methods.removeRole;
    pub const putEmoji = collection_views_cleanup_methods.putEmoji;
    pub const removeEmoji = collection_views_cleanup_methods.removeEmoji;
    pub const putSticker = collection_views_cleanup_methods.putSticker;
    pub const removeSticker = collection_views_cleanup_methods.removeSticker;
    pub const putScheduledEvent = collection_views_cleanup_methods.putScheduledEvent;
    pub const removeScheduledEvent = collection_views_cleanup_methods.removeScheduledEvent;
    pub const putStageInstance = collection_views_cleanup_methods.putStageInstance;
    pub const removeStageInstance = collection_views_cleanup_methods.removeStageInstance;
    pub const putInvite = collection_views_cleanup_methods.putInvite;
    pub const removeInvite = collection_views_cleanup_methods.removeInvite;
    pub const putPresence = collection_views_cleanup_methods.putPresence;
    pub const removePresence = collection_views_cleanup_methods.removePresence;
    pub const putVoiceState = collection_views_cleanup_methods.putVoiceState;
    pub const removeVoiceState = collection_views_cleanup_methods.removeVoiceState;
    pub const putMessage = collection_views_cleanup_methods.putMessage;
    pub const putMessageAssociations = collection_views_cleanup_methods.putMessageAssociations;
    pub const clearMessages = collection_views_cleanup_methods.clearMessages;
    pub const removeMessage = collection_views_cleanup_methods.removeMessage;
    pub const messageCount = collection_views_cleanup_methods.messageCount;
    pub const removeGuildChannels = collection_views_cleanup_methods.removeGuildChannels;
    pub const removeChildThreads = collection_views_cleanup_methods.removeChildThreads;
    pub const removeGuildMembers = guild_dispatch_hydration_methods.removeGuildMembers;
    pub const removeGuildRoles = guild_dispatch_hydration_methods.removeGuildRoles;
    pub const removeRoleFromMembers = guild_dispatch_hydration_methods.removeRoleFromMembers;
    pub const removeGuildEmojis = guild_dispatch_hydration_methods.removeGuildEmojis;
    pub const removeGuildStickers = guild_dispatch_hydration_methods.removeGuildStickers;
    pub const removeGuildScheduledEvents = guild_dispatch_hydration_methods.removeGuildScheduledEvents;
    pub const removeGuildStageInstances = guild_dispatch_hydration_methods.removeGuildStageInstances;
    pub const removeGuildInvites = guild_dispatch_hydration_methods.removeGuildInvites;
    pub const removeChannelInvites = guild_dispatch_hydration_methods.removeChannelInvites;
    pub const removeChannelMessages = guild_dispatch_hydration_methods.removeChannelMessages;
    pub const removeChannelVoiceStates = guild_dispatch_hydration_methods.removeChannelVoiceStates;
    pub const removeGuildMessages = guild_dispatch_hydration_methods.removeGuildMessages;
    pub const removeGuildPresences = guild_dispatch_hydration_methods.removeGuildPresences;
    pub const removeGuildVoiceStates = guild_dispatch_hydration_methods.removeGuildVoiceStates;
    pub const removeMessageOrder = guild_dispatch_hydration_methods.removeMessageOrder;
    pub const enforceMessageLimit = guild_dispatch_hydration_methods.enforceMessageLimit;
    pub const sweepMessagesBefore = guild_dispatch_hydration_methods.sweepMessagesBefore;
    pub const sweepMessagesOlderThan = guild_dispatch_hydration_methods.sweepMessagesOlderThan;
    pub const sweep = guild_dispatch_hydration_methods.sweep;
    pub const putGuildFromJson = guild_dispatch_hydration_methods.putGuildFromJson;
    pub const deleteGuildFromJson = guild_dispatch_hydration_methods.deleteGuildFromJson;
    pub const putUserFromJson = guild_dispatch_hydration_methods.putUserFromJson;
    pub const putReadyFromJson = guild_dispatch_hydration_methods.putReadyFromJson;
    pub const putPresenceFromJson = guild_dispatch_hydration_methods.putPresenceFromJson;
    pub const putPresencesFromJson = guild_dispatch_hydration_methods.putPresencesFromJson;
    pub const putVoiceStateFromJson = guild_dispatch_hydration_methods.putVoiceStateFromJson;
    pub const putVoiceStatesFromJson = guild_dispatch_hydration_methods.putVoiceStatesFromJson;
    pub const putMessageFromJson = guild_dispatch_hydration_methods.putMessageFromJson;
    pub const updateMessageFromJson = message_dispatch_updates_methods.updateMessageFromJson;
    pub const addReactionFromJson = message_dispatch_updates_methods.addReactionFromJson;
    pub const removeReactionFromJson = message_dispatch_updates_methods.removeReactionFromJson;
    pub const removeAllReactionsFromJson = message_dispatch_updates_methods.removeAllReactionsFromJson;
    pub const removeReactionEmojiFromJson = message_dispatch_updates_methods.removeReactionEmojiFromJson;
    pub const deleteMessageFromJson = message_dispatch_updates_methods.deleteMessageFromJson;
    pub const deleteMessagesFromJson = message_dispatch_updates_methods.deleteMessagesFromJson;
    pub const putChannelsFromJson = message_dispatch_updates_methods.putChannelsFromJson;
    pub const putChannelFromJson = message_dispatch_updates_methods.putChannelFromJson;
    pub const deleteChannelFromJson = message_dispatch_updates_methods.deleteChannelFromJson;
    pub const updateChannelInfoFromJson = message_dispatch_updates_methods.updateChannelInfoFromJson;
    pub const updateVoiceChannelStatusFromJson = message_dispatch_updates_methods.updateVoiceChannelStatusFromJson;
    pub const updateVoiceChannelStartTimeFromJson = message_dispatch_updates_methods.updateVoiceChannelStartTimeFromJson;
    pub const updateChannelPinsFromJson = message_dispatch_updates_methods.updateChannelPinsFromJson;
    pub const applyChannelInfoFields = message_dispatch_updates_methods.applyChannelInfoFields;
    pub const applyChannelStatusField = message_dispatch_updates_methods.applyChannelStatusField;
    pub const syncThreadsFromJson = message_dispatch_updates_methods.syncThreadsFromJson;
    pub const updateThreadMemberCountFromJson = message_dispatch_updates_methods.updateThreadMemberCountFromJson;
    pub const putMembersFromJson = message_dispatch_updates_methods.putMembersFromJson;
    pub const putRolesFromJson = message_dispatch_updates_methods.putRolesFromJson;
    pub const putRoleEventFromJson = message_dispatch_updates_methods.putRoleEventFromJson;
    pub const deleteRoleEventFromJson = message_dispatch_updates_methods.deleteRoleEventFromJson;
    pub const putGuildEmojisFromJson = message_dispatch_updates_methods.putGuildEmojisFromJson;
    pub const putEmojisFromJson = message_dispatch_updates_methods.putEmojisFromJson;
    pub const putStickersFromJson = message_dispatch_updates_methods.putStickersFromJson;
    pub const putGuildStickersFromJson = message_dispatch_updates_methods.putGuildStickersFromJson;
    pub const putScheduledEventsFromJson = message_dispatch_updates_methods.putScheduledEventsFromJson;
    pub const putScheduledEventFromJson = message_dispatch_updates_methods.putScheduledEventFromJson;
    pub const deleteScheduledEventFromJson = message_dispatch_updates_methods.deleteScheduledEventFromJson;
    pub const incrementScheduledEventUserCountFromJson = message_dispatch_updates_methods.incrementScheduledEventUserCountFromJson;
    pub const decrementScheduledEventUserCountFromJson = message_dispatch_updates_methods.decrementScheduledEventUserCountFromJson;
    pub const putStageInstanceFromJson = message_dispatch_updates_methods.putStageInstanceFromJson;
    pub const putStageInstancesFromJson = message_dispatch_updates_methods.putStageInstancesFromJson;
    pub const deleteStageInstanceFromJson = message_dispatch_updates_methods.deleteStageInstanceFromJson;
    pub const putInviteFromJson = message_dispatch_updates_methods.putInviteFromJson;
    pub const deleteInviteFromJson = message_dispatch_updates_methods.deleteInviteFromJson;
    pub const putMemberFromJson = message_dispatch_updates_methods.putMemberFromJson;
    pub const addMemberFromJson = message_dispatch_updates_methods.addMemberFromJson;
    pub const deleteMemberFromJson = message_dispatch_updates_methods.deleteMemberFromJson;
    pub const incrementGuildMemberCount = message_dispatch_updates_methods.incrementGuildMemberCount;
    pub const decrementGuildMemberCount = message_dispatch_updates_methods.decrementGuildMemberCount;
};
const cache_owned_core_models = @import("cache-parts/owned-core.zig");
const cache_owned_guild_assets = @import("cache-parts/owned-assets.zig");
const cache_owned_presence_messages = @import("cache-parts/owned-messages.zig");
const cache_message_component_copy = @import("cache-parts/component-copy.zig");
const cache_poll_user_application_copy = @import("cache-parts/application-copy.zig");
const cache_channel_embed_reaction_copy = @import("cache-parts/channel-copy.zig");
const cache_json_guild_channel_parse = @import("cache-parts/guild-parse.zig");
const cache_json_role_event_parse = @import("cache-parts/role-parse.zig");
const cache_json_message_component_parse = @import("cache-parts/message-parse.zig");
const cache_json_embed_reaction_parse = @import("cache-parts/embed-parse.zig");

pub const OwnedUser = cache_owned_core_models.OwnedUser;
pub const OwnedGuild = cache_owned_core_models.OwnedGuild;
pub const OwnedChannel = cache_owned_core_models.OwnedChannel;
pub const OwnedGuildMember = cache_owned_guild_assets.OwnedGuildMember;
pub const OwnedRole = cache_owned_guild_assets.OwnedRole;
pub const OwnedEmoji = cache_owned_guild_assets.OwnedEmoji;
pub const OwnedSticker = cache_owned_guild_assets.OwnedSticker;
pub const OwnedScheduledEvent = cache_owned_guild_assets.OwnedScheduledEvent;
pub const OwnedStageInstance = cache_owned_guild_assets.OwnedStageInstance;
pub const OwnedInvite = cache_owned_presence_messages.OwnedInvite;
pub const OwnedPresence = cache_owned_presence_messages.OwnedPresence;
pub const OwnedVoiceState = cache_owned_presence_messages.OwnedVoiceState;
pub const OwnedMessage = cache_owned_presence_messages.OwnedMessage;
pub const copyAttachments = cache_message_component_copy.copyAttachments;
pub const copyAttachment = cache_message_component_copy.copyAttachment;
pub const deinitAttachments = cache_message_component_copy.deinitAttachments;
pub const copyMessageSnapshots = cache_message_component_copy.copyMessageSnapshots;
pub const copyMessageSnapshot = cache_message_component_copy.copyMessageSnapshot;
pub const deinitMessageSnapshots = cache_message_component_copy.deinitMessageSnapshots;
pub const deinitMessageSnapshot = cache_message_component_copy.deinitMessageSnapshot;
pub const copyMessageStickerItems = cache_message_component_copy.copyMessageStickerItems;
pub const deinitMessageStickerItems = cache_message_component_copy.deinitMessageStickerItems;
pub const copyStickers = cache_message_component_copy.copyStickers;
pub const copySticker = cache_message_component_copy.copySticker;
pub const deinitStickers = cache_message_component_copy.deinitStickers;
pub const deinitSticker = cache_message_component_copy.deinitSticker;
pub const copyComponents = cache_message_component_copy.copyComponents;
pub const copyComponent = cache_message_component_copy.copyComponent;
pub const copyButton = cache_message_component_copy.copyButton;
pub const copyStringSelect = cache_message_component_copy.copyStringSelect;
pub const copyAutoSelect = cache_message_component_copy.copyAutoSelect;
pub const copyTextInput = cache_message_component_copy.copyTextInput;
pub const copyTextDisplay = cache_message_component_copy.copyTextDisplay;
pub const copyUnfurledMedia = cache_message_component_copy.copyUnfurledMedia;
pub const copyThumbnail = cache_message_component_copy.copyThumbnail;
pub const copySection = cache_message_component_copy.copySection;
pub const copyMediaGallery = cache_message_component_copy.copyMediaGallery;
pub const copyFileComponent = cache_message_component_copy.copyFileComponent;
pub const copyContainer = cache_message_component_copy.copyContainer;
pub const copySelectOptions = cache_message_component_copy.copySelectOptions;
pub const deinitComponents = cache_message_component_copy.deinitComponents;
pub const deinitComponent = cache_poll_user_application_copy.deinitComponent;
pub const deinitSelectOptions = cache_poll_user_application_copy.deinitSelectOptions;
pub const deinitThumbnail = cache_poll_user_application_copy.deinitThumbnail;
pub const deinitMediaGalleryItem = cache_poll_user_application_copy.deinitMediaGalleryItem;
pub const copyMessagePoll = cache_poll_user_application_copy.copyMessagePoll;
pub const copyMessagePollMedia = cache_poll_user_application_copy.copyMessagePollMedia;
pub const copyPollEmoji = cache_poll_user_application_copy.copyPollEmoji;
pub const copyMessagePollAnswers = cache_poll_user_application_copy.copyMessagePollAnswers;
pub const copyMessagePollResults = cache_poll_user_application_copy.copyMessagePollResults;
pub const deinitMessagePoll = cache_poll_user_application_copy.deinitMessagePoll;
pub const deinitMessagePollAnswers = cache_poll_user_application_copy.deinitMessagePollAnswers;
pub const deinitMessagePollMedia = cache_poll_user_application_copy.deinitMessagePollMedia;
pub const copyMessageCall = cache_poll_user_application_copy.copyMessageCall;
pub const deinitMessageCall = cache_poll_user_application_copy.deinitMessageCall;
pub const copyRoleSubscriptionData = cache_poll_user_application_copy.copyRoleSubscriptionData;
pub const deinitRoleSubscriptionData = cache_poll_user_application_copy.deinitRoleSubscriptionData;
pub const copySharedClientTheme = cache_poll_user_application_copy.copySharedClientTheme;
pub const deinitSharedClientTheme = cache_poll_user_application_copy.deinitSharedClientTheme;
pub const copyMessageActivity = cache_poll_user_application_copy.copyMessageActivity;
pub const deinitMessageActivity = cache_poll_user_application_copy.deinitMessageActivity;
pub const copyMessageInteractionMetadata = cache_poll_user_application_copy.copyMessageInteractionMetadata;
pub const deinitMessageInteractionMetadata = cache_poll_user_application_copy.deinitMessageInteractionMetadata;
pub const copyGuildMember = cache_poll_user_application_copy.copyGuildMember;
pub const deinitGuildMember = cache_poll_user_application_copy.deinitGuildMember;
pub const copyUsers = cache_poll_user_application_copy.copyUsers;
pub const copyUser = cache_poll_user_application_copy.copyUser;
pub const deinitUsers = cache_poll_user_application_copy.deinitUsers;
pub const deinitUser = cache_poll_user_application_copy.deinitUser;
pub const copyApplication = cache_poll_user_application_copy.copyApplication;
pub const deinitApplication = cache_poll_user_application_copy.deinitApplication;
pub const copyChannels = cache_channel_embed_reaction_copy.copyChannels;
pub const copyChannel = cache_channel_embed_reaction_copy.copyChannel;
pub const copyDefaultReactionEmoji = cache_channel_embed_reaction_copy.copyDefaultReactionEmoji;
pub const copyForumTags = cache_channel_embed_reaction_copy.copyForumTags;
pub const copyForumTag = cache_channel_embed_reaction_copy.copyForumTag;
pub const copyThreadMetadata = cache_channel_embed_reaction_copy.copyThreadMetadata;
pub const deinitChannels = cache_channel_embed_reaction_copy.deinitChannels;
pub const deinitChannel = cache_channel_embed_reaction_copy.deinitChannel;
pub const deinitDefaultReactionEmoji = cache_channel_embed_reaction_copy.deinitDefaultReactionEmoji;
pub const deinitForumTags = cache_channel_embed_reaction_copy.deinitForumTags;
pub const deinitThreadMetadata = cache_channel_embed_reaction_copy.deinitThreadMetadata;
pub const copyEmbeds = cache_channel_embed_reaction_copy.copyEmbeds;
pub const copyEmbed = cache_channel_embed_reaction_copy.copyEmbed;
pub const copyEmbedFooter = cache_channel_embed_reaction_copy.copyEmbedFooter;
pub const copyEmbedMedia = cache_channel_embed_reaction_copy.copyEmbedMedia;
pub const copyEmbedAuthor = cache_channel_embed_reaction_copy.copyEmbedAuthor;
pub const copyEmbedFields = cache_channel_embed_reaction_copy.copyEmbedFields;
pub const deinitEmbeds = cache_channel_embed_reaction_copy.deinitEmbeds;
pub const deinitEmbed = cache_channel_embed_reaction_copy.deinitEmbed;
pub const deinitEmbedFooter = cache_channel_embed_reaction_copy.deinitEmbedFooter;
pub const deinitEmbedMedia = cache_channel_embed_reaction_copy.deinitEmbedMedia;
pub const deinitEmbedAuthor = cache_channel_embed_reaction_copy.deinitEmbedAuthor;
pub const deinitEmbedField = cache_channel_embed_reaction_copy.deinitEmbedField;
pub const copyReactions = cache_channel_embed_reaction_copy.copyReactions;
pub const copyReaction = cache_channel_embed_reaction_copy.copyReaction;
pub const copyReactionEmoji = cache_channel_embed_reaction_copy.copyReactionEmoji;
pub const deinitReactions = cache_channel_embed_reaction_copy.deinitReactions;
pub const deinitReactionEmoji = cache_channel_embed_reaction_copy.deinitReactionEmoji;
pub const incrementReaction = cache_channel_embed_reaction_copy.incrementReaction;
pub const decrementReaction = cache_channel_embed_reaction_copy.decrementReaction;
pub const removeReactionEmoji = cache_channel_embed_reaction_copy.removeReactionEmoji;
pub const removeReactionAt = cache_channel_embed_reaction_copy.removeReactionAt;
pub const reactionEmojiEql = cache_json_guild_channel_parse.reactionEmojiEql;
pub const memberKey = cache_json_guild_channel_parse.memberKey;
pub const roleKey = cache_json_guild_channel_parse.roleKey;
pub const replaceOwned = cache_json_guild_channel_parse.replaceOwned;
pub const clearOwnedMap = cache_json_guild_channel_parse.clearOwnedMap;
pub const clearOwnedMapRetainingCapacity = cache_json_guild_channel_parse.clearOwnedMapRetainingCapacity;
pub const userFromJson = cache_json_guild_channel_parse.userFromJson;
pub const applicationFromJson = cache_json_guild_channel_parse.applicationFromJson;
pub const deinitParsedApplication = cache_json_guild_channel_parse.deinitParsedApplication;
pub const teamFromJson = cache_json_guild_channel_parse.teamFromJson;
pub const teamMembersFromJson = cache_json_guild_channel_parse.teamMembersFromJson;
pub const teamMemberFromJson = cache_json_guild_channel_parse.teamMemberFromJson;
pub const membershipStateFromInt = cache_json_guild_channel_parse.membershipStateFromInt;
pub const deinitParsedTeam = cache_json_guild_channel_parse.deinitParsedTeam;
pub const copyTeam = cache_json_guild_channel_parse.copyTeam;
pub const copyTeamMember = cache_json_guild_channel_parse.copyTeamMember;
pub const deinitTeam = cache_json_guild_channel_parse.deinitTeam;
pub const deinitTeamMember = cache_json_guild_channel_parse.deinitTeamMember;
pub const applicationEventWebhookStatusFromInt = cache_json_guild_channel_parse.applicationEventWebhookStatusFromInt;
pub const channelFromJson = cache_json_guild_channel_parse.channelFromJson;
pub const deinitParsedChannel = cache_json_guild_channel_parse.deinitParsedChannel;
pub const deinitParsedChannels = cache_json_guild_channel_parse.deinitParsedChannels;
pub const threadMetadataFromJson = cache_json_guild_channel_parse.threadMetadataFromJson;
pub const permissionOverwriteArrayFromJson = cache_json_guild_channel_parse.permissionOverwriteArrayFromJson;
pub const permissionOverwriteFromJson = cache_json_guild_channel_parse.permissionOverwriteFromJson;
pub const forumTagArrayFromJson = cache_json_guild_channel_parse.forumTagArrayFromJson;
pub const forumTagFromJson = cache_json_guild_channel_parse.forumTagFromJson;
pub const nullableDefaultReactionEmojiFromJson = cache_json_guild_channel_parse.nullableDefaultReactionEmojiFromJson;
pub const nullableChannelSortOrderFromJson = cache_json_guild_channel_parse.nullableChannelSortOrderFromJson;
pub const nullableForumLayoutFromJson = cache_json_guild_channel_parse.nullableForumLayoutFromJson;
pub const permissionOverwriteTypeFromInt = cache_json_guild_channel_parse.permissionOverwriteTypeFromInt;
pub const deinitParsedForumTags = cache_json_guild_channel_parse.deinitParsedForumTags;
pub const channelTypeFromInt = cache_json_guild_channel_parse.channelTypeFromInt;
pub const channelTypeIsThread = cache_json_guild_channel_parse.channelTypeIsThread;
pub const roleFromJson = cache_json_role_event_parse.roleFromJson;
pub const roleColorsFromJson = cache_json_role_event_parse.roleColorsFromJson;
pub const roleTagsFromJson = cache_json_role_event_parse.roleTagsFromJson;
pub const emojiFromJson = cache_json_role_event_parse.emojiFromJson;
pub const stickerFromJson = cache_json_role_event_parse.stickerFromJson;
pub const stickerFromJsonOptionalFallback = cache_json_role_event_parse.stickerFromJsonOptionalFallback;
pub const stickerArrayFromJson = cache_json_role_event_parse.stickerArrayFromJson;
pub const stickerTypeFromInt = cache_json_role_event_parse.stickerTypeFromInt;
pub const stickerFormatTypeFromInt = cache_json_role_event_parse.stickerFormatTypeFromInt;
pub const scheduledEventFromJson = cache_json_role_event_parse.scheduledEventFromJson;
pub const scheduledEventPrivacyLevelFromInt = cache_json_role_event_parse.scheduledEventPrivacyLevelFromInt;
pub const scheduledEventEntityTypeFromInt = cache_json_role_event_parse.scheduledEventEntityTypeFromInt;
pub const scheduledEventStatusFromInt = cache_json_role_event_parse.scheduledEventStatusFromInt;
pub const stageInstanceFromJson = cache_json_role_event_parse.stageInstanceFromJson;
pub const stageInstancePrivacyLevelFromInt = cache_json_role_event_parse.stageInstancePrivacyLevelFromInt;
pub const inviteFromJson = cache_json_role_event_parse.inviteFromJson;
pub const presenceFromJson = cache_json_role_event_parse.presenceFromJson;
pub const voiceStateFromJson = cache_json_role_event_parse.voiceStateFromJson;
pub const messageReferenceFromJson = cache_json_role_event_parse.messageReferenceFromJson;
pub const messageReferenceTypeFromInt = cache_json_role_event_parse.messageReferenceTypeFromInt;
pub const referencedMessageIdFromJson = cache_json_role_event_parse.referencedMessageIdFromJson;
pub const messageSnapshotArrayFromJson = cache_json_role_event_parse.messageSnapshotArrayFromJson;
pub const messageSnapshotFromJson = cache_json_role_event_parse.messageSnapshotFromJson;
pub const deinitParsedMessageSnapshots = cache_json_role_event_parse.deinitParsedMessageSnapshots;
pub const memberFromJson = cache_json_role_event_parse.memberFromJson;
pub const roleArrayFromJson = cache_json_role_event_parse.roleArrayFromJson;
pub const userArrayFromJson = cache_json_role_event_parse.userArrayFromJson;
pub const channelArrayFromJson = cache_json_role_event_parse.channelArrayFromJson;
pub const stringArrayFromJson = cache_json_role_event_parse.stringArrayFromJson;
pub const copyStringArray = cache_json_role_event_parse.copyStringArray;
pub const deinitStringArray = cache_json_role_event_parse.deinitStringArray;
pub const deinitConstStringArray = cache_json_role_event_parse.deinitConstStringArray;
pub const attachmentArrayFromJson = cache_json_message_component_parse.attachmentArrayFromJson;
pub const messageStickerItemArrayFromJson = cache_json_message_component_parse.messageStickerItemArrayFromJson;
pub const messageStickerItemFromJson = cache_json_message_component_parse.messageStickerItemFromJson;
pub const componentArrayFromJson = cache_json_message_component_parse.componentArrayFromJson;
pub const componentFromJson = cache_json_message_component_parse.componentFromJson;
pub const buttonFromJson = cache_json_message_component_parse.buttonFromJson;
pub const stringSelectFromJson = cache_json_message_component_parse.stringSelectFromJson;
pub const autoSelectFromJson = cache_json_message_component_parse.autoSelectFromJson;
pub const u8ArrayFromJson = cache_json_message_component_parse.u8ArrayFromJson;
pub const selectOptionArrayFromJson = cache_json_message_component_parse.selectOptionArrayFromJson;
pub const selectOptionFromJson = cache_json_message_component_parse.selectOptionFromJson;
pub const deinitParsedComponents = cache_json_message_component_parse.deinitParsedComponents;
pub const deinitParsedComponentArray = cache_json_message_component_parse.deinitParsedComponentArray;
pub const buttonStyleFromInt = cache_json_message_component_parse.buttonStyleFromInt;
pub const messagePollFromJson = cache_json_message_component_parse.messagePollFromJson;
pub const messageInteractionMetadataFromJson = cache_json_message_component_parse.messageInteractionMetadataFromJson;
pub const messageCallFromJson = cache_json_message_component_parse.messageCallFromJson;
pub const deinitParsedMessageCall = cache_json_message_component_parse.deinitParsedMessageCall;
pub const nullableRoleSubscriptionDataFromJson = cache_json_message_component_parse.nullableRoleSubscriptionDataFromJson;
pub const sharedClientThemeFromJson = cache_json_message_component_parse.sharedClientThemeFromJson;
pub const deinitParsedSharedClientTheme = cache_json_message_component_parse.deinitParsedSharedClientTheme;
pub const nullableSharedClientThemeBaseFromJson = cache_json_message_component_parse.nullableSharedClientThemeBaseFromJson;
pub const nullableMessageActivityFromJson = cache_json_message_component_parse.nullableMessageActivityFromJson;
pub const messageActivityTypeFromInt = cache_json_message_component_parse.messageActivityTypeFromInt;
pub const interactionTypeFromInt = cache_json_message_component_parse.interactionTypeFromInt;
pub const messagePollMediaFromJson = cache_json_message_component_parse.messagePollMediaFromJson;
pub const pollEmojiFromJson = cache_json_message_component_parse.pollEmojiFromJson;
pub const messagePollAnswerArrayFromJson = cache_json_message_component_parse.messagePollAnswerArrayFromJson;
pub const messagePollAnswerFromJson = cache_json_message_component_parse.messagePollAnswerFromJson;
pub const messagePollResultsFromJson = cache_json_message_component_parse.messagePollResultsFromJson;
pub const messagePollAnswerCountArrayFromJson = cache_json_message_component_parse.messagePollAnswerCountArrayFromJson;
pub const messagePollAnswerCountFromJson = cache_json_message_component_parse.messagePollAnswerCountFromJson;
pub const deinitParsedMessagePoll = cache_json_message_component_parse.deinitParsedMessagePoll;
pub const embedArrayFromJson = cache_json_message_component_parse.embedArrayFromJson;
pub const deinitParsedEmbeds = cache_json_message_component_parse.deinitParsedEmbeds;
pub const embedFromJson = cache_json_message_component_parse.embedFromJson;
pub const embedFooterFromJson = cache_json_message_component_parse.embedFooterFromJson;
pub const embedMediaFromJson = cache_json_message_component_parse.embedMediaFromJson;
pub const embedAuthorFromJson = cache_json_message_component_parse.embedAuthorFromJson;
pub const embedFieldArrayFromJson = cache_json_embed_reaction_parse.embedFieldArrayFromJson;
pub const embedFieldFromJson = cache_json_embed_reaction_parse.embedFieldFromJson;
pub const attachmentFromJson = cache_json_embed_reaction_parse.attachmentFromJson;
pub const reactionArrayFromJson = cache_json_embed_reaction_parse.reactionArrayFromJson;
pub const reactionFromJson = cache_json_embed_reaction_parse.reactionFromJson;
pub const reactionCountDetailsFromJson = cache_json_embed_reaction_parse.reactionCountDetailsFromJson;
pub const deinitParsedReactions = cache_json_embed_reaction_parse.deinitParsedReactions;
pub const deinitParsedReactionFields = cache_json_embed_reaction_parse.deinitParsedReactionFields;
pub const ReactionEvent = cache_json_embed_reaction_parse.ReactionEvent;
pub const reactionEventFromJson = cache_json_embed_reaction_parse.reactionEventFromJson;
pub const reactionEmojiFromJson = cache_json_embed_reaction_parse.reactionEmojiFromJson;
pub const requireObject = cache_json_embed_reaction_parse.requireObject;
pub const requireArray = cache_json_embed_reaction_parse.requireArray;
pub const snowflakeField = cache_json_embed_reaction_parse.snowflakeField;
pub const snowflakeValue = cache_json_embed_reaction_parse.snowflakeValue;
pub const nullableSnowflakeValue = cache_json_embed_reaction_parse.nullableSnowflakeValue;
pub const permissionsValue = cache_json_embed_reaction_parse.permissionsValue;
pub const stringField = cache_json_embed_reaction_parse.stringField;
pub const intField = cache_json_embed_reaction_parse.intField;
pub const intValue = cache_json_embed_reaction_parse.intValue;
pub const nullableIntValue = cache_json_embed_reaction_parse.nullableIntValue;
pub const nullableU24Value = cache_json_embed_reaction_parse.nullableU24Value;
pub const ParsedMessageNonce = cache_json_embed_reaction_parse.ParsedMessageNonce;
pub const messageNonceFromJson = cache_json_embed_reaction_parse.messageNonceFromJson;
pub const optionalU32Value = cache_json_embed_reaction_parse.optionalU32Value;
pub const optionalU8Value = cache_json_embed_reaction_parse.optionalU8Value;
pub const stringValue = cache_json_embed_reaction_parse.stringValue;
pub const optionalStringValue = cache_json_embed_reaction_parse.optionalStringValue;
pub const boolValue = cache_json_embed_reaction_parse.boolValue;
pub const optionalBoolValue = cache_json_embed_reaction_parse.optionalBoolValue;
pub const nestedIdValue = cache_json_embed_reaction_parse.nestedIdValue;
