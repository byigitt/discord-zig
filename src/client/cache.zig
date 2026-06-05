const std = @import("std");
const Snowflake = @import("../core/snowflake.zig").Snowflake;
const Types = @import("../models/types.zig");
const Gateway = @import("../gateway/protocol.zig");
const Interactions = @import("../interactions/mod.zig");
const Permissions = @import("../core/permissions.zig");
const Collection = @import("../core/collection.zig").Collection;

const test_part_01 = @import("cache_tests/part_01.zig");
const test_part_02 = @import("cache_tests/part_02.zig");
const test_part_03 = @import("cache_tests/part_03.zig");
const test_part_04 = @import("cache_tests/part_04.zig");
const test_part_05 = @import("cache_tests/part_05.zig");
const test_part_06 = @import("cache_tests/part_06.zig");
const test_part_07 = @import("cache_tests/part_07.zig");

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
    const Methods01 = @import("cache_methods/part_01.zig").Methods(@This());
    const Methods02 = @import("cache_methods/part_02.zig").Methods(@This());
    const Methods03 = @import("cache_methods/part_03.zig").Methods(@This());
    const Methods04 = @import("cache_methods/part_04.zig").Methods(@This());
    pub const init = Methods01.init;
    pub const initWithPolicy = Methods01.initWithPolicy;
    pub const deinit = Methods01.deinit;
    pub const applyDispatch = Methods01.applyDispatch;
    pub const getUser = Methods01.getUser;
    pub const hasUser = Methods01.hasUser;
    pub const getCurrentUser = Methods01.getCurrentUser;
    pub const currentUserId = Methods01.currentUserId;
    pub const hasCurrentUser = Methods01.hasCurrentUser;
    pub const getCurrentApplication = Methods01.getCurrentApplication;
    pub const currentApplicationId = Methods01.currentApplicationId;
    pub const hasCurrentApplication = Methods01.hasCurrentApplication;
    pub const getGuild = Methods01.getGuild;
    pub const hasGuild = Methods01.hasGuild;
    pub const getChannel = Methods01.getChannel;
    pub const hasChannel = Methods01.hasChannel;
    pub const getMember = Methods01.getMember;
    pub const hasMember = Methods01.hasMember;
    pub const getRole = Methods01.getRole;
    pub const hasRole = Methods01.hasRole;
    pub const getEmoji = Methods01.getEmoji;
    pub const hasEmoji = Methods01.hasEmoji;
    pub const getSticker = Methods01.getSticker;
    pub const hasSticker = Methods01.hasSticker;
    pub const getScheduledEvent = Methods01.getScheduledEvent;
    pub const hasScheduledEvent = Methods01.hasScheduledEvent;
    pub const getStageInstance = Methods01.getStageInstance;
    pub const hasStageInstance = Methods01.hasStageInstance;
    pub const getInvite = Methods01.getInvite;
    pub const hasInvite = Methods01.hasInvite;
    pub const getPresence = Methods01.getPresence;
    pub const hasPresence = Methods01.hasPresence;
    pub const getVoiceState = Methods01.getVoiceState;
    pub const hasVoiceState = Methods01.hasVoiceState;
    pub const getMessage = Methods01.getMessage;
    pub const hasMessage = Methods01.hasMessage;
    pub const clear = Methods01.clear;
    pub const stats = Methods01.stats;
    pub const guildStats = Methods01.guildStats;
    pub const channelStats = Methods01.channelStats;
    pub const listUsers = Methods01.listUsers;
    pub const listGuilds = Methods01.listGuilds;
    pub const listChannels = Methods01.listChannels;
    pub const collectGuilds = Methods01.collectGuilds;
    pub const collectChannels = Methods01.collectChannels;
    pub const collectUsers = Methods01.collectUsers;
    pub const collectRoles = Methods01.collectRoles;
    pub const listTopLevelChannels = Methods01.listTopLevelChannels;
    pub const listGuildChannels = Methods01.listGuildChannels;
    pub const listChannelThreads = Methods01.listChannelThreads;
    pub const listGuildThreads = Methods01.listGuildThreads;
    pub const listGuildMembers = Methods02.listGuildMembers;
    pub const listMembers = Methods02.listMembers;
    pub const listGuildRoles = Methods02.listGuildRoles;
    pub const listRoles = Methods02.listRoles;
    pub const listGuildEmojis = Methods02.listGuildEmojis;
    pub const listEmojis = Methods02.listEmojis;
    pub const listGuildStickers = Methods02.listGuildStickers;
    pub const listStickers = Methods02.listStickers;
    pub const listGuildScheduledEvents = Methods02.listGuildScheduledEvents;
    pub const listScheduledEvents = Methods02.listScheduledEvents;
    pub const listGuildStageInstances = Methods02.listGuildStageInstances;
    pub const listStageInstances = Methods02.listStageInstances;
    pub const listGuildInvites = Methods02.listGuildInvites;
    pub const listInvites = Methods02.listInvites;
    pub const listChannelInvites = Methods02.listChannelInvites;
    pub const listPresences = Methods02.listPresences;
    pub const listGuildPresences = Methods02.listGuildPresences;
    pub const listVoiceStates = Methods02.listVoiceStates;
    pub const listGuildVoiceStates = Methods02.listGuildVoiceStates;
    pub const listChannelMessages = Methods02.listChannelMessages;
    pub const listMessages = Methods02.listMessages;
    pub const listGuildMessages = Methods02.listGuildMessages;
    pub const putUser = Methods02.putUser;
    pub const putCurrentUser = Methods02.putCurrentUser;
    pub const removeUser = Methods02.removeUser;
    pub const putCurrentApplication = Methods02.putCurrentApplication;
    pub const removeCurrentApplication = Methods02.removeCurrentApplication;
    pub const putGuild = Methods02.putGuild;
    pub const removeGuild = Methods02.removeGuild;
    pub const putChannel = Methods02.putChannel;
    pub const removeChannel = Methods02.removeChannel;
    pub const putMember = Methods02.putMember;
    pub const removeMember = Methods02.removeMember;
    pub const putRole = Methods02.putRole;
    pub const removeRole = Methods02.removeRole;
    pub const putEmoji = Methods02.putEmoji;
    pub const removeEmoji = Methods02.removeEmoji;
    pub const putSticker = Methods02.putSticker;
    pub const removeSticker = Methods02.removeSticker;
    pub const putScheduledEvent = Methods02.putScheduledEvent;
    pub const removeScheduledEvent = Methods02.removeScheduledEvent;
    pub const putStageInstance = Methods02.putStageInstance;
    pub const removeStageInstance = Methods02.removeStageInstance;
    pub const putInvite = Methods02.putInvite;
    pub const removeInvite = Methods02.removeInvite;
    pub const putPresence = Methods02.putPresence;
    pub const removePresence = Methods02.removePresence;
    pub const putVoiceState = Methods02.putVoiceState;
    pub const removeVoiceState = Methods02.removeVoiceState;
    pub const putMessage = Methods02.putMessage;
    pub const putMessageAssociations = Methods02.putMessageAssociations;
    pub const clearMessages = Methods02.clearMessages;
    pub const removeMessage = Methods02.removeMessage;
    pub const messageCount = Methods02.messageCount;
    pub const removeGuildChannels = Methods02.removeGuildChannels;
    pub const removeChildThreads = Methods02.removeChildThreads;
    pub const removeGuildMembers = Methods03.removeGuildMembers;
    pub const removeGuildRoles = Methods03.removeGuildRoles;
    pub const removeRoleFromMembers = Methods03.removeRoleFromMembers;
    pub const removeGuildEmojis = Methods03.removeGuildEmojis;
    pub const removeGuildStickers = Methods03.removeGuildStickers;
    pub const removeGuildScheduledEvents = Methods03.removeGuildScheduledEvents;
    pub const removeGuildStageInstances = Methods03.removeGuildStageInstances;
    pub const removeGuildInvites = Methods03.removeGuildInvites;
    pub const removeChannelInvites = Methods03.removeChannelInvites;
    pub const removeChannelMessages = Methods03.removeChannelMessages;
    pub const removeChannelVoiceStates = Methods03.removeChannelVoiceStates;
    pub const removeGuildMessages = Methods03.removeGuildMessages;
    pub const removeGuildPresences = Methods03.removeGuildPresences;
    pub const removeGuildVoiceStates = Methods03.removeGuildVoiceStates;
    pub const removeMessageOrder = Methods03.removeMessageOrder;
    pub const enforceMessageLimit = Methods03.enforceMessageLimit;
    pub const sweepMessagesBefore = Methods03.sweepMessagesBefore;
    pub const sweepMessagesOlderThan = Methods03.sweepMessagesOlderThan;
    pub const sweep = Methods03.sweep;
    pub const putGuildFromJson = Methods03.putGuildFromJson;
    pub const deleteGuildFromJson = Methods03.deleteGuildFromJson;
    pub const putUserFromJson = Methods03.putUserFromJson;
    pub const putReadyFromJson = Methods03.putReadyFromJson;
    pub const putPresenceFromJson = Methods03.putPresenceFromJson;
    pub const putPresencesFromJson = Methods03.putPresencesFromJson;
    pub const putVoiceStateFromJson = Methods03.putVoiceStateFromJson;
    pub const putVoiceStatesFromJson = Methods03.putVoiceStatesFromJson;
    pub const putMessageFromJson = Methods03.putMessageFromJson;
    pub const updateMessageFromJson = Methods04.updateMessageFromJson;
    pub const addReactionFromJson = Methods04.addReactionFromJson;
    pub const removeReactionFromJson = Methods04.removeReactionFromJson;
    pub const removeAllReactionsFromJson = Methods04.removeAllReactionsFromJson;
    pub const removeReactionEmojiFromJson = Methods04.removeReactionEmojiFromJson;
    pub const deleteMessageFromJson = Methods04.deleteMessageFromJson;
    pub const deleteMessagesFromJson = Methods04.deleteMessagesFromJson;
    pub const putChannelsFromJson = Methods04.putChannelsFromJson;
    pub const putChannelFromJson = Methods04.putChannelFromJson;
    pub const deleteChannelFromJson = Methods04.deleteChannelFromJson;
    pub const updateChannelInfoFromJson = Methods04.updateChannelInfoFromJson;
    pub const updateVoiceChannelStatusFromJson = Methods04.updateVoiceChannelStatusFromJson;
    pub const updateVoiceChannelStartTimeFromJson = Methods04.updateVoiceChannelStartTimeFromJson;
    pub const updateChannelPinsFromJson = Methods04.updateChannelPinsFromJson;
    pub const applyChannelInfoFields = Methods04.applyChannelInfoFields;
    pub const applyChannelStatusField = Methods04.applyChannelStatusField;
    pub const syncThreadsFromJson = Methods04.syncThreadsFromJson;
    pub const updateThreadMemberCountFromJson = Methods04.updateThreadMemberCountFromJson;
    pub const putMembersFromJson = Methods04.putMembersFromJson;
    pub const putRolesFromJson = Methods04.putRolesFromJson;
    pub const putRoleEventFromJson = Methods04.putRoleEventFromJson;
    pub const deleteRoleEventFromJson = Methods04.deleteRoleEventFromJson;
    pub const putGuildEmojisFromJson = Methods04.putGuildEmojisFromJson;
    pub const putEmojisFromJson = Methods04.putEmojisFromJson;
    pub const putStickersFromJson = Methods04.putStickersFromJson;
    pub const putGuildStickersFromJson = Methods04.putGuildStickersFromJson;
    pub const putScheduledEventsFromJson = Methods04.putScheduledEventsFromJson;
    pub const putScheduledEventFromJson = Methods04.putScheduledEventFromJson;
    pub const deleteScheduledEventFromJson = Methods04.deleteScheduledEventFromJson;
    pub const incrementScheduledEventUserCountFromJson = Methods04.incrementScheduledEventUserCountFromJson;
    pub const decrementScheduledEventUserCountFromJson = Methods04.decrementScheduledEventUserCountFromJson;
    pub const putStageInstanceFromJson = Methods04.putStageInstanceFromJson;
    pub const putStageInstancesFromJson = Methods04.putStageInstancesFromJson;
    pub const deleteStageInstanceFromJson = Methods04.deleteStageInstanceFromJson;
    pub const putInviteFromJson = Methods04.putInviteFromJson;
    pub const deleteInviteFromJson = Methods04.deleteInviteFromJson;
    pub const putMemberFromJson = Methods04.putMemberFromJson;
    pub const addMemberFromJson = Methods04.addMemberFromJson;
    pub const deleteMemberFromJson = Methods04.deleteMemberFromJson;
    pub const incrementGuildMemberCount = Methods04.incrementGuildMemberCount;
    pub const decrementGuildMemberCount = Methods04.decrementGuildMemberCount;
};
const cache_part_01 = @import("cache_parts/part_01.zig");
const cache_part_02 = @import("cache_parts/part_02.zig");
const cache_part_03 = @import("cache_parts/part_03.zig");
const cache_part_04 = @import("cache_parts/part_04.zig");
const cache_part_05 = @import("cache_parts/part_05.zig");
const cache_part_06 = @import("cache_parts/part_06.zig");
const cache_part_07 = @import("cache_parts/part_07.zig");
const cache_part_08 = @import("cache_parts/part_08.zig");
const cache_part_09 = @import("cache_parts/part_09.zig");
const cache_part_10 = @import("cache_parts/part_10.zig");

pub const OwnedUser = cache_part_01.OwnedUser;
pub const OwnedGuild = cache_part_01.OwnedGuild;
pub const OwnedChannel = cache_part_01.OwnedChannel;
pub const OwnedGuildMember = cache_part_02.OwnedGuildMember;
pub const OwnedRole = cache_part_02.OwnedRole;
pub const OwnedEmoji = cache_part_02.OwnedEmoji;
pub const OwnedSticker = cache_part_02.OwnedSticker;
pub const OwnedScheduledEvent = cache_part_02.OwnedScheduledEvent;
pub const OwnedStageInstance = cache_part_02.OwnedStageInstance;
pub const OwnedInvite = cache_part_03.OwnedInvite;
pub const OwnedPresence = cache_part_03.OwnedPresence;
pub const OwnedVoiceState = cache_part_03.OwnedVoiceState;
pub const OwnedMessage = cache_part_03.OwnedMessage;
pub const copyAttachments = cache_part_04.copyAttachments;
pub const copyAttachment = cache_part_04.copyAttachment;
pub const deinitAttachments = cache_part_04.deinitAttachments;
pub const copyMessageSnapshots = cache_part_04.copyMessageSnapshots;
pub const copyMessageSnapshot = cache_part_04.copyMessageSnapshot;
pub const deinitMessageSnapshots = cache_part_04.deinitMessageSnapshots;
pub const deinitMessageSnapshot = cache_part_04.deinitMessageSnapshot;
pub const copyMessageStickerItems = cache_part_04.copyMessageStickerItems;
pub const deinitMessageStickerItems = cache_part_04.deinitMessageStickerItems;
pub const copyStickers = cache_part_04.copyStickers;
pub const copySticker = cache_part_04.copySticker;
pub const deinitStickers = cache_part_04.deinitStickers;
pub const deinitSticker = cache_part_04.deinitSticker;
pub const copyComponents = cache_part_04.copyComponents;
pub const copyComponent = cache_part_04.copyComponent;
pub const copyButton = cache_part_04.copyButton;
pub const copyStringSelect = cache_part_04.copyStringSelect;
pub const copyAutoSelect = cache_part_04.copyAutoSelect;
pub const copyTextInput = cache_part_04.copyTextInput;
pub const copyTextDisplay = cache_part_04.copyTextDisplay;
pub const copyUnfurledMedia = cache_part_04.copyUnfurledMedia;
pub const copyThumbnail = cache_part_04.copyThumbnail;
pub const copySection = cache_part_04.copySection;
pub const copyMediaGallery = cache_part_04.copyMediaGallery;
pub const copyFileComponent = cache_part_04.copyFileComponent;
pub const copyContainer = cache_part_04.copyContainer;
pub const copySelectOptions = cache_part_04.copySelectOptions;
pub const deinitComponents = cache_part_04.deinitComponents;
pub const deinitComponent = cache_part_05.deinitComponent;
pub const deinitSelectOptions = cache_part_05.deinitSelectOptions;
pub const deinitThumbnail = cache_part_05.deinitThumbnail;
pub const deinitMediaGalleryItem = cache_part_05.deinitMediaGalleryItem;
pub const copyMessagePoll = cache_part_05.copyMessagePoll;
pub const copyMessagePollMedia = cache_part_05.copyMessagePollMedia;
pub const copyPollEmoji = cache_part_05.copyPollEmoji;
pub const copyMessagePollAnswers = cache_part_05.copyMessagePollAnswers;
pub const copyMessagePollResults = cache_part_05.copyMessagePollResults;
pub const deinitMessagePoll = cache_part_05.deinitMessagePoll;
pub const deinitMessagePollAnswers = cache_part_05.deinitMessagePollAnswers;
pub const deinitMessagePollMedia = cache_part_05.deinitMessagePollMedia;
pub const copyMessageCall = cache_part_05.copyMessageCall;
pub const deinitMessageCall = cache_part_05.deinitMessageCall;
pub const copyRoleSubscriptionData = cache_part_05.copyRoleSubscriptionData;
pub const deinitRoleSubscriptionData = cache_part_05.deinitRoleSubscriptionData;
pub const copySharedClientTheme = cache_part_05.copySharedClientTheme;
pub const deinitSharedClientTheme = cache_part_05.deinitSharedClientTheme;
pub const copyMessageActivity = cache_part_05.copyMessageActivity;
pub const deinitMessageActivity = cache_part_05.deinitMessageActivity;
pub const copyMessageInteractionMetadata = cache_part_05.copyMessageInteractionMetadata;
pub const deinitMessageInteractionMetadata = cache_part_05.deinitMessageInteractionMetadata;
pub const copyGuildMember = cache_part_05.copyGuildMember;
pub const deinitGuildMember = cache_part_05.deinitGuildMember;
pub const copyUsers = cache_part_05.copyUsers;
pub const copyUser = cache_part_05.copyUser;
pub const deinitUsers = cache_part_05.deinitUsers;
pub const deinitUser = cache_part_05.deinitUser;
pub const copyApplication = cache_part_05.copyApplication;
pub const deinitApplication = cache_part_05.deinitApplication;
pub const copyChannels = cache_part_06.copyChannels;
pub const copyChannel = cache_part_06.copyChannel;
pub const copyDefaultReactionEmoji = cache_part_06.copyDefaultReactionEmoji;
pub const copyForumTags = cache_part_06.copyForumTags;
pub const copyForumTag = cache_part_06.copyForumTag;
pub const copyThreadMetadata = cache_part_06.copyThreadMetadata;
pub const deinitChannels = cache_part_06.deinitChannels;
pub const deinitChannel = cache_part_06.deinitChannel;
pub const deinitDefaultReactionEmoji = cache_part_06.deinitDefaultReactionEmoji;
pub const deinitForumTags = cache_part_06.deinitForumTags;
pub const deinitThreadMetadata = cache_part_06.deinitThreadMetadata;
pub const copyEmbeds = cache_part_06.copyEmbeds;
pub const copyEmbed = cache_part_06.copyEmbed;
pub const copyEmbedFooter = cache_part_06.copyEmbedFooter;
pub const copyEmbedMedia = cache_part_06.copyEmbedMedia;
pub const copyEmbedAuthor = cache_part_06.copyEmbedAuthor;
pub const copyEmbedFields = cache_part_06.copyEmbedFields;
pub const deinitEmbeds = cache_part_06.deinitEmbeds;
pub const deinitEmbed = cache_part_06.deinitEmbed;
pub const deinitEmbedFooter = cache_part_06.deinitEmbedFooter;
pub const deinitEmbedMedia = cache_part_06.deinitEmbedMedia;
pub const deinitEmbedAuthor = cache_part_06.deinitEmbedAuthor;
pub const deinitEmbedField = cache_part_06.deinitEmbedField;
pub const copyReactions = cache_part_06.copyReactions;
pub const copyReaction = cache_part_06.copyReaction;
pub const copyReactionEmoji = cache_part_06.copyReactionEmoji;
pub const deinitReactions = cache_part_06.deinitReactions;
pub const deinitReactionEmoji = cache_part_06.deinitReactionEmoji;
pub const incrementReaction = cache_part_06.incrementReaction;
pub const decrementReaction = cache_part_06.decrementReaction;
pub const removeReactionEmoji = cache_part_06.removeReactionEmoji;
pub const removeReactionAt = cache_part_06.removeReactionAt;
pub const reactionEmojiEql = cache_part_07.reactionEmojiEql;
pub const memberKey = cache_part_07.memberKey;
pub const roleKey = cache_part_07.roleKey;
pub const replaceOwned = cache_part_07.replaceOwned;
pub const clearOwnedMap = cache_part_07.clearOwnedMap;
pub const clearOwnedMapRetainingCapacity = cache_part_07.clearOwnedMapRetainingCapacity;
pub const userFromJson = cache_part_07.userFromJson;
pub const applicationFromJson = cache_part_07.applicationFromJson;
pub const deinitParsedApplication = cache_part_07.deinitParsedApplication;
pub const teamFromJson = cache_part_07.teamFromJson;
pub const teamMembersFromJson = cache_part_07.teamMembersFromJson;
pub const teamMemberFromJson = cache_part_07.teamMemberFromJson;
pub const membershipStateFromInt = cache_part_07.membershipStateFromInt;
pub const deinitParsedTeam = cache_part_07.deinitParsedTeam;
pub const copyTeam = cache_part_07.copyTeam;
pub const copyTeamMember = cache_part_07.copyTeamMember;
pub const deinitTeam = cache_part_07.deinitTeam;
pub const deinitTeamMember = cache_part_07.deinitTeamMember;
pub const applicationEventWebhookStatusFromInt = cache_part_07.applicationEventWebhookStatusFromInt;
pub const channelFromJson = cache_part_07.channelFromJson;
pub const deinitParsedChannel = cache_part_07.deinitParsedChannel;
pub const deinitParsedChannels = cache_part_07.deinitParsedChannels;
pub const threadMetadataFromJson = cache_part_07.threadMetadataFromJson;
pub const permissionOverwriteArrayFromJson = cache_part_07.permissionOverwriteArrayFromJson;
pub const permissionOverwriteFromJson = cache_part_07.permissionOverwriteFromJson;
pub const forumTagArrayFromJson = cache_part_07.forumTagArrayFromJson;
pub const forumTagFromJson = cache_part_07.forumTagFromJson;
pub const nullableDefaultReactionEmojiFromJson = cache_part_07.nullableDefaultReactionEmojiFromJson;
pub const nullableChannelSortOrderFromJson = cache_part_07.nullableChannelSortOrderFromJson;
pub const nullableForumLayoutFromJson = cache_part_07.nullableForumLayoutFromJson;
pub const permissionOverwriteTypeFromInt = cache_part_07.permissionOverwriteTypeFromInt;
pub const deinitParsedForumTags = cache_part_07.deinitParsedForumTags;
pub const channelTypeFromInt = cache_part_07.channelTypeFromInt;
pub const channelTypeIsThread = cache_part_07.channelTypeIsThread;
pub const roleFromJson = cache_part_08.roleFromJson;
pub const roleColorsFromJson = cache_part_08.roleColorsFromJson;
pub const roleTagsFromJson = cache_part_08.roleTagsFromJson;
pub const emojiFromJson = cache_part_08.emojiFromJson;
pub const stickerFromJson = cache_part_08.stickerFromJson;
pub const stickerFromJsonOptionalFallback = cache_part_08.stickerFromJsonOptionalFallback;
pub const stickerArrayFromJson = cache_part_08.stickerArrayFromJson;
pub const stickerTypeFromInt = cache_part_08.stickerTypeFromInt;
pub const stickerFormatTypeFromInt = cache_part_08.stickerFormatTypeFromInt;
pub const scheduledEventFromJson = cache_part_08.scheduledEventFromJson;
pub const scheduledEventPrivacyLevelFromInt = cache_part_08.scheduledEventPrivacyLevelFromInt;
pub const scheduledEventEntityTypeFromInt = cache_part_08.scheduledEventEntityTypeFromInt;
pub const scheduledEventStatusFromInt = cache_part_08.scheduledEventStatusFromInt;
pub const stageInstanceFromJson = cache_part_08.stageInstanceFromJson;
pub const stageInstancePrivacyLevelFromInt = cache_part_08.stageInstancePrivacyLevelFromInt;
pub const inviteFromJson = cache_part_08.inviteFromJson;
pub const presenceFromJson = cache_part_08.presenceFromJson;
pub const voiceStateFromJson = cache_part_08.voiceStateFromJson;
pub const messageReferenceFromJson = cache_part_08.messageReferenceFromJson;
pub const messageReferenceTypeFromInt = cache_part_08.messageReferenceTypeFromInt;
pub const referencedMessageIdFromJson = cache_part_08.referencedMessageIdFromJson;
pub const messageSnapshotArrayFromJson = cache_part_08.messageSnapshotArrayFromJson;
pub const messageSnapshotFromJson = cache_part_08.messageSnapshotFromJson;
pub const deinitParsedMessageSnapshots = cache_part_08.deinitParsedMessageSnapshots;
pub const memberFromJson = cache_part_08.memberFromJson;
pub const roleArrayFromJson = cache_part_08.roleArrayFromJson;
pub const userArrayFromJson = cache_part_08.userArrayFromJson;
pub const channelArrayFromJson = cache_part_08.channelArrayFromJson;
pub const stringArrayFromJson = cache_part_08.stringArrayFromJson;
pub const copyStringArray = cache_part_08.copyStringArray;
pub const deinitStringArray = cache_part_08.deinitStringArray;
pub const deinitConstStringArray = cache_part_08.deinitConstStringArray;
pub const attachmentArrayFromJson = cache_part_09.attachmentArrayFromJson;
pub const messageStickerItemArrayFromJson = cache_part_09.messageStickerItemArrayFromJson;
pub const messageStickerItemFromJson = cache_part_09.messageStickerItemFromJson;
pub const componentArrayFromJson = cache_part_09.componentArrayFromJson;
pub const componentFromJson = cache_part_09.componentFromJson;
pub const buttonFromJson = cache_part_09.buttonFromJson;
pub const stringSelectFromJson = cache_part_09.stringSelectFromJson;
pub const autoSelectFromJson = cache_part_09.autoSelectFromJson;
pub const u8ArrayFromJson = cache_part_09.u8ArrayFromJson;
pub const selectOptionArrayFromJson = cache_part_09.selectOptionArrayFromJson;
pub const selectOptionFromJson = cache_part_09.selectOptionFromJson;
pub const deinitParsedComponents = cache_part_09.deinitParsedComponents;
pub const deinitParsedComponentArray = cache_part_09.deinitParsedComponentArray;
pub const buttonStyleFromInt = cache_part_09.buttonStyleFromInt;
pub const messagePollFromJson = cache_part_09.messagePollFromJson;
pub const messageInteractionMetadataFromJson = cache_part_09.messageInteractionMetadataFromJson;
pub const messageCallFromJson = cache_part_09.messageCallFromJson;
pub const deinitParsedMessageCall = cache_part_09.deinitParsedMessageCall;
pub const nullableRoleSubscriptionDataFromJson = cache_part_09.nullableRoleSubscriptionDataFromJson;
pub const sharedClientThemeFromJson = cache_part_09.sharedClientThemeFromJson;
pub const deinitParsedSharedClientTheme = cache_part_09.deinitParsedSharedClientTheme;
pub const nullableSharedClientThemeBaseFromJson = cache_part_09.nullableSharedClientThemeBaseFromJson;
pub const nullableMessageActivityFromJson = cache_part_09.nullableMessageActivityFromJson;
pub const messageActivityTypeFromInt = cache_part_09.messageActivityTypeFromInt;
pub const interactionTypeFromInt = cache_part_09.interactionTypeFromInt;
pub const messagePollMediaFromJson = cache_part_09.messagePollMediaFromJson;
pub const pollEmojiFromJson = cache_part_09.pollEmojiFromJson;
pub const messagePollAnswerArrayFromJson = cache_part_09.messagePollAnswerArrayFromJson;
pub const messagePollAnswerFromJson = cache_part_09.messagePollAnswerFromJson;
pub const messagePollResultsFromJson = cache_part_09.messagePollResultsFromJson;
pub const messagePollAnswerCountArrayFromJson = cache_part_09.messagePollAnswerCountArrayFromJson;
pub const messagePollAnswerCountFromJson = cache_part_09.messagePollAnswerCountFromJson;
pub const deinitParsedMessagePoll = cache_part_09.deinitParsedMessagePoll;
pub const embedArrayFromJson = cache_part_09.embedArrayFromJson;
pub const deinitParsedEmbeds = cache_part_09.deinitParsedEmbeds;
pub const embedFromJson = cache_part_09.embedFromJson;
pub const embedFooterFromJson = cache_part_09.embedFooterFromJson;
pub const embedMediaFromJson = cache_part_09.embedMediaFromJson;
pub const embedAuthorFromJson = cache_part_09.embedAuthorFromJson;
pub const embedFieldArrayFromJson = cache_part_10.embedFieldArrayFromJson;
pub const embedFieldFromJson = cache_part_10.embedFieldFromJson;
pub const attachmentFromJson = cache_part_10.attachmentFromJson;
pub const reactionArrayFromJson = cache_part_10.reactionArrayFromJson;
pub const reactionFromJson = cache_part_10.reactionFromJson;
pub const reactionCountDetailsFromJson = cache_part_10.reactionCountDetailsFromJson;
pub const deinitParsedReactions = cache_part_10.deinitParsedReactions;
pub const deinitParsedReactionFields = cache_part_10.deinitParsedReactionFields;
pub const ReactionEvent = cache_part_10.ReactionEvent;
pub const reactionEventFromJson = cache_part_10.reactionEventFromJson;
pub const reactionEmojiFromJson = cache_part_10.reactionEmojiFromJson;
pub const requireObject = cache_part_10.requireObject;
pub const requireArray = cache_part_10.requireArray;
pub const snowflakeField = cache_part_10.snowflakeField;
pub const snowflakeValue = cache_part_10.snowflakeValue;
pub const nullableSnowflakeValue = cache_part_10.nullableSnowflakeValue;
pub const permissionsValue = cache_part_10.permissionsValue;
pub const stringField = cache_part_10.stringField;
pub const intField = cache_part_10.intField;
pub const intValue = cache_part_10.intValue;
pub const nullableIntValue = cache_part_10.nullableIntValue;
pub const nullableU24Value = cache_part_10.nullableU24Value;
pub const ParsedMessageNonce = cache_part_10.ParsedMessageNonce;
pub const messageNonceFromJson = cache_part_10.messageNonceFromJson;
pub const optionalU32Value = cache_part_10.optionalU32Value;
pub const optionalU8Value = cache_part_10.optionalU8Value;
pub const stringValue = cache_part_10.stringValue;
pub const optionalStringValue = cache_part_10.optionalStringValue;
pub const boolValue = cache_part_10.boolValue;
pub const optionalBoolValue = cache_part_10.optionalBoolValue;
pub const nestedIdValue = cache_part_10.nestedIdValue;
