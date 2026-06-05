# discord.zig

`discord.zig` is a small Zig foundation for Discord bots inspired by the most common Discord.js primitives: client configuration, intents, permissions, REST routes, messages, and Gateway payloads.

Target Zig version: `0.16.0+`.

The current focus is a fast, dependency-light core:

- Discord API v10 routes and payload types
- `Snowflake` parsing, formatting, and timestamp helpers
- Current `GatewayIntentBits` helpers with Discord.js-compatible aliases and current `PermissionBits`
- Mention scanner for user, role, channel, everyone, and here mentions
- Discord message, channel, and invite link parsers plus OAuth2 authorization URL builder
- Discord CDN asset URL builders with explicit hash and cached model helpers
- Permission bit constants and overwrite resolution helpers
- Configurable cache policy with allocation-free current identity IDs, cache membership checks, explicit cache eviction, global/guild/channel cache stats, message cache limits, current-user and current-application READY hydration, user profile metadata, guild configuration metadata, guild-create thread/emoji/stage-instance/presence/voice-state hydration, unavailable guild preservation, voice-state member association retention, channel/member/thread metadata and counters, voice channel status/start-time info, top-level and non-thread guild-channel list views, guild-wide and parent-channel thread list views, all/channel/guild message list views, all/guild member list views, all/scoped role, emoji, sticker, scheduled-event, stage-instance, invite, presence, and voice-state list views, guild member-count updates, channel pin timestamp and voice-info updates, guild and channel message cleanup, channel voice-state cleanup, child-thread cleanup on channel delete, thread list sync, thread member-count updates, scheduled-event user-count updates, role colors/metadata/tags and delete cleanup on members, member removal cleanup for presence and voice state, member flags/effective permissions, channel permission overwrites, forum/media tags, default reaction emoji, sort/layout, flags, thread tags, and message reaction count updates
- REST client built around an injectable transport, with a `std.http.Client` transport for live API calls
- Rate-limit state that follows Discord response headers instead of hard-coding limits
- Message REST helpers for create, fetch, list, and delete
- Message payload builders for embeds, embed helper chaining, allowed mentions, components, sticker ids, nonce enforcement, shared client themes, and flags
- Message state, nonce, application id/object, activity, interaction metadata, call, role subscription data, shared client theme, member, reference, forward snapshot, thread position, mention, embed, attachment, sticker item, sticker, component, poll, and reaction model parsing with count details, super-reaction metadata, cache, and related-user retention
- Multipart message uploads for memory buffers and streaming file paths
- Message reply, forward, edit, embed suppress/unsuppress, bulk delete, typing, crosspost, reaction add/delete-own/remove aliases, poll voter fetch, pinned-message and current paginated channel pin fetch, and thread create/edit/archive/lock/tag/list REST helpers
- Application metadata/SKU/entitlement consume/subscription, application emoji, activity instance, role-connection metadata, and event webhook payload types/fetch aliases, OAuth2 current bot application/current authorization/token exchange/revoke helpers, current-user fetch/edit/me/guild/member/connection/application-role-connection aliases, user, current-user guild leave, optioned guild fetch/edit, direct-message channel, guild audit-log fetch, auto-moderation rule management, guild member list/search, guild prune, guild template/widget/widget-image/welcome/onboarding/incident/vanity fetch aliases and management, scheduled-event fetch aliases and management, stage instance, voice region, and voice-state fetch aliases, guild channel fetch/position/permission aliases with forum/media tags, default reaction emoji, sort/layout, and flags, channel utility helpers, global/guild sticker fetch, guild role color/icon/emoji fetch aliases and management, guild emoji/sticker fetch aliases and management, soundboard fetch aliases and management, current-user nickname compatibility, member moderation, and guild member REST helpers
- Channel and guild invite REST helpers with optioned invite fetch and target-user fetch/update aliases
- Lobby create/fetch/edit/delete, member management, leave, channel link, and message moderation metadata aliases
- Channel and guild webhook management plus webhook execution REST helpers
- Global and guild application command helpers for list, create, bulk overwrite, fetch, edit, and delete
- Application command permission helpers for guild command permission fetch and edit
- Slash command option and choice JSON builders
- Button, string/user/role/mentionable/channel select menu, and modal text input component builders with disabled-state and text-input convenience helpers
- Interaction callback helpers for replies, deferred replies, deferred updates, message updates, autocomplete results, modals, original responses, and follow-up messages
- Gateway URL and Gateway Bot shard/session metadata fetch aliases, documented opcode/close-code helpers, identify with optional initial presence, runtime presence/activity updates, soundboard sound and channel info requests, documented shard routing helpers, and dispatch payload parsing helpers
- Gateway session state for identify, heartbeat, resume, hello, ack, ready, and reconnect handling
- WebSocket handshake validation and frame codec for Gateway transport implementations
- Socket-backed secure WebSocket Gateway transport using `std.http.Client`
- High-level Gateway runner for hello, identify, resume, heartbeat, Gateway ping measurement, reconnect backoff, runner lifecycle inspection, client readiness tracking, cache updates, and event dispatch
- Nonblocking Gateway runtime adapter for external event loops with lifecycle inspection
- Blocking Gateway runtime adapter for connect, reconnect delay, transport replacement, runner stepping, and lifecycle inspection
- Typed event dispatcher for common Gateway events like message, reaction, poll vote, typing, invite, webhook update, integration, auto moderation, entitlement, soundboard, user, presence, voice state, interaction, application command permissions, guild audit log, guild ban, guild member, member chunk, role, emoji, sticker, scheduled event, stage instance, voice server, channel pin, channel, channel info, voice channel status, and thread dispatches, with generic persistent, one-shot, and clearable listeners
- Lightweight guild/channel/author/content message collectors and guild/channel/user interaction collectors for Discord.js-style flow control with max, time, and idle limits

Discord documents that Gateway intents are required and passed as bitwise values, and that REST rate limits should be read from response headers because limits can change. This library follows those constraints instead of baking in route limits.

References:

- https://docs.discord.com/developers/topics/gateway
- https://docs.discord.com/developers/topics/rate-limits
- https://docs.discord.com/developers/resources/message
- https://docs.discord.com/developers/resources/poll

## Source layout

The public module root stays at `src/discord.zig`. It re-exports the stable API surface while implementation code is grouped by domain:

- `src/core/`: API constants, snowflakes, intents, permissions, JSON helpers, mentions, links, assets, collections, and formatters
- `src/models/`: Discord resource and payload models
- `src/rest/`: REST routes, client helpers, transports, uploads, and rate-limit handling
- `src/gateway/`: Gateway payloads, sessions, transports, runtimes, events, sharding, and WebSocket framing
- `src/interactions/`: application commands, components, callbacks, routers, and collectors
- `src/client/`: high-level client orchestration and cache state
- `src/voice/`: voice gateway, audio resource, player, receive, and codec adapter helpers

Implementation files are kept below 1000 lines. File and subdirectory names use short kebab-case path segments with at most two words, such as `message-polls.zig`, `app-commands.zig`, `lifecycle-events.zig`, and `cache-test.zig`, so contributors can open a file by responsibility without changing the public `discord.zig` entrypoint.

## Example

```zig
const std = @import("std");
const discord = @import("discord");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var transport = discord.Rest.MemoryTransport.init(allocator, .{
        .status = 200,
        .body = "{\"id\":\"1\",\"content\":\"pong\"}",
    });
    defer transport.deinit();

    const startup_activities = [_]discord.Gateway.Activity{discord.Gateway.Activity.init("discord.zig", .watching)};
    var client = discord.Client.init(allocator, .{
        .token = "Bot token",
        .intents = discord.Intents.defaultNonPrivileged(),
        .presence = discord.Gateway.Presence.init(.online).withActivities(&startup_activities),
        .transport = transport.transport(),
    });

    const channel_id = try discord.Snowflake.parse("123456789012345678");
    const channel_created_ms = channel_id.timestampMillis();
    const channel_parts = channel_id.deconstruct();
    const first_id_at_time = try discord.Snowflake.fromTimestampMillis(channel_created_ms);
    _ = channel_parts;
    _ = first_id_at_time;
    _ = try client.sendMessage(channel_id, discord.Types.CreateMessage.init("pong"));
    _ = try client.sendText(channel_id, "pong");
    _ = try client.listMessagesWithOptions(channel_id, discord.Types.ListMessages.init().withLimit(25));
}
```

Embeds and mention controls can be sent with the same message helper:

```zig
const fields = [_]discord.Types.EmbedField{
    discord.Types.EmbedField.inlineField("Runtime", "Zig"),
};
const single_field = discord.Types.EmbedField.init("Transport", "REST");
const embeds = [_]discord.Types.Embed{
    discord.Types.Embed.init()
        .withTitle("discord.zig")
        .withDescription("Fast bot core")
        .withColor(0x5865F2)
        .withFields(&fields),
    discord.Types.Embed.init()
        .withTitle("Status")
        .withField(&single_field),
};

_ = try client.sendMessage(
    channel_id,
    discord.Types.CreateMessage.init("release notes")
        .withEmbeds(&embeds)
        .withAllowedMentions(discord.Types.AllowedMentions
            .usersOnly()
            .withUser(&user_id)
            .repliedUser(false)),
);
const reply_only_mentions = discord.Types.AllowedMentions.repliedUserOnly();

var mentions = try discord.Mentions.parse(allocator, "hi <@123> <#456>");
defer mentions.deinit();

_ = try discord.Mentions.scan("hi <@123> <#456>", discord.Mentions.handler(&state, State.onMention));
const user_mention = try discord.Mentions.userMention(allocator, user_id);
defer allocator.free(user_mention);
const role_mention = try discord.Mentions.roleMention(allocator, role_id);
defer allocator.free(role_mention);
const channel_mention = try discord.Mentions.channelMention(allocator, channel_id);
defer allocator.free(channel_mention);
const emoji_mention = try discord.Mentions.emojiMention(allocator, "zig", emoji_id);
defer allocator.free(emoji_mention);
const relative_time = try discord.Mentions.relativeTimestampMention(allocator, now_seconds);
defer allocator.free(relative_time);
const parsed_mention = try discord.Mentions.format(allocator, mentions.items[0]);
defer allocator.free(parsed_mention);
const user_display_name = user.displayName();
const user_tag = try user.tag(allocator);
defer allocator.free(user_tag);
const member_display_name = member.displayName();

const link = try discord.Links.parseMessageLink("https://discord.com/channels/1/2/3");
const message_url = try discord.Links.messageUrl(allocator, guild_id, channel_id, message_id);
defer allocator.free(message_url);
const channel_url = try discord.Links.channelUrl(allocator, guild_id, channel_id);
defer allocator.free(channel_url);
const invite_code = try discord.Links.parseInviteCode("https://discord.gg/abc123");
const invite_link = try discord.Links.inviteLink(allocator, invite_code);
defer allocator.free(invite_link);
const invite_url = try discord.Links.authorizationUrl(allocator, .{
    .client_id = application_id,
    .scopes = &.{ "bot", "applications.commands" },
    .permissions = 2048,
});
defer allocator.free(invite_url);

const avatar_url = (try discord.Assets.userAvatarUrlFor(allocator, user, .{ .size = 128 })).?;
defer allocator.free(avatar_url);
const default_avatar_url = try discord.Assets.defaultUserAvatarUrlFor(allocator, user);
defer allocator.free(default_avatar_url);
const display_avatar_url = try discord.Assets.userDisplayAvatarUrlFor(allocator, user, .{ .size = 128 });
defer allocator.free(display_avatar_url);
const application_icon_url = (try discord.Assets.applicationIconUrlFor(allocator, application, .{ .size = 256 })).?;
defer allocator.free(application_icon_url);
const member_avatar_url = (try discord.Assets.guildMemberAvatarUrlFor(allocator, guild_id, member, .{})).?;
defer allocator.free(member_avatar_url);
const role_icon_url = (try discord.Assets.roleIconUrlFor(allocator, role, .{ .format = .webp })).?;
defer allocator.free(role_icon_url);
```

Small files can be uploaded from memory with multipart support:

```zig
const files = [_]discord.Types.UploadFile{
    discord.Types.UploadFile
        .init("hello.txt", "hello")
        .withContentType("text/plain")
        .withDescription("Greeting"),
};

_ = try client.sendFiles(channel_id, discord.Types.CreateMessage.init("with attachment"), &files);
_ = try client.sendWithFiles(channel_id, discord.Types.CreateMessage.init("with attachment alias"), &files);
```

Larger files can be streamed from disk paths without building the entire multipart body in memory:

```zig
const files = [_]discord.Types.UploadFilePath{
    discord.Types.UploadFilePath
        .init("report.txt", "tmp/report.txt")
        .withContentType("text/plain")
        .withDescription("Daily report"),
};

_ = try client.sendFilePaths(channel_id, discord.Types.CreateMessage.init("streamed attachment"), &files);
_ = try client.sendWithFilePaths(channel_id, discord.Types.CreateMessage.init("streamed attachment alias"), &files);
```

Message management helpers cover common Discord.js flows:

```zig
_ = try client.send(
    channel_id,
    discord.Types.CreateMessage
        .init("reply")
        .withReference(discord.Types.MessageReference.reply(original_message_id)),
);
_ = try client.sendMessageWithContent(channel_id, "plain content");
_ = try client.sendContent(channel_id, "content alias");
_ = try client.sendText(channel_id, "text alias");
_ = try client.replyMessage(channel_id, original_message_id, discord.Types.CreateMessage.init("reply alias"));
_ = try client.replyWithContent(channel_id, original_message_id, "reply shortcut");
_ = try client.replyMessageWithContent(channel_id, original_message_id, "reply alias shortcut");
_ = try client.replyText(channel_id, original_message_id, "reply text shortcut");
_ = try client.forwardMessage(target_channel_id, source_channel_id, original_message_id);
_ = try client.forward(target_channel_id, source_channel_id, original_message_id);

_ = try client.fetchMessage(channel_id, message_id);
_ = try client.fetchMessages(channel_id, discord.Types.ListMessages.init().withLimit(25));
_ = try client.edit(channel_id, message_id, discord.Types.EditMessage.init().withContent("edited"));
_ = try client.editMessageWithContent(channel_id, message_id, "edited shortcut");
_ = try client.editWithContent(channel_id, message_id, "edited content alias");
_ = try client.editText(channel_id, message_id, "edited text alias");
_ = try client.delete(channel_id, message_id);
_ = try client.crosspost(news_channel_id, message_id);
_ = try client.publish(news_channel_id, message_id);
_ = try client.bulkDelete(channel_id, &.{ message_id_a, message_id_b });
_ = try client.sendTyping(channel_id);
_ = try client.triggerTyping(channel_id);
_ = try client.react(channel_id, message_id, "👍");
_ = try client.addReaction(channel_id, message_id, "👍");
_ = try client.unreact(channel_id, message_id, "👍");
_ = try client.deleteOwnReaction(channel_id, message_id, "👍");
_ = try client.removeReaction(channel_id, message_id, "👍", user_id);
_ = try client.fetchReactions(channel_id, message_id, "👍", discord.Types.ListReactions.init().withLimit(25).withType(.normal));
_ = try client.deleteAllReactions(channel_id, message_id);
_ = try client.removeAllReactions(channel_id, message_id);
_ = try client.clearReactionsForEmoji(channel_id, message_id, "👍");
_ = try client.deleteAllReactionsForEmoji(channel_id, message_id, "👍");
const poll_answers = [_]discord.Types.PollAnswer{
    discord.Types.PollAnswer.text("Zig"),
    discord.Types.PollAnswer.text("Other"),
};
_ = try client.sendMessage(channel_id, discord.Types.CreateMessage.empty()
    .withPoll(discord.Types.CreatePoll
        .init("Runtime?", &poll_answers)
        .withDuration(24)
        .multiselect(false)));
_ = try client.fetchPollAnswerVoters(channel_id, message_id, 1, discord.Types.ListPollAnswerVoters.init().withLimit(25));
_ = try client.endPoll(channel_id, message_id);
_ = try client.pin(channel_id, message_id);
_ = try client.unpin(channel_id, message_id);
_ = try client.fetchPinnedMessages(channel_id);
_ = try client.fetchPins(channel_id, discord.Types.ListChannelPins.init().withLimit(25));
_ = try client.startThreadFromMessage(channel_id, message_id, discord.Types.CreateThreadFromMessage.init("debug"));
_ = try client.startThreadFromMessageWithName(channel_id, message_id, "debug");
_ = try client.editChannel(thread_id, discord.Types.EditChannel.init().archivedState(true).lockedState(true));
_ = try client.joinThread(thread_id);
_ = try client.addThreadMember(thread_id, user_id);
_ = try client.fetchThreadMember(thread_id, user_id);
_ = try client.fetchThreadMembers(thread_id);
_ = try client.fetchThreadMembersWithOptions(thread_id, discord.Types.ListThreadMembers.init()
    .withMemberExpansion(true)
    .afterMember(user_id)
    .withLimit(100));
_ = try client.fetchActiveThreads(guild_id);
_ = try client.fetchPublicArchivedThreads(channel_id, discord.Types.ListArchivedThreads.init().withLimit(25));
_ = try client.fetchPrivateArchivedThreads(channel_id, discord.Types.ListArchivedThreads.init().withLimit(25));
_ = try client.fetchJoinedPrivateArchivedThreads(channel_id, discord.Types.ListArchivedThreads.init().withLimit(25));
_ = try client.createDefaultInvite(channel_id);
_ = try client.createInviteWithMaxUses(channel_id, 1);
_ = try client.createInviteWithMaxAge(channel_id, 3600);
_ = try client.createUniqueInvite(channel_id);
```

Basic entity fetch helpers are available for common cache misses:

```zig
_ = try client.fetchCurrentApplication();
_ = try client.fetchCurrentBotApplication();
_ = try client.editCurrentApplication(discord.Types.EditCurrentApplication.init().withDescription("Fast Zig bot"));
_ = try client.setCurrentApplicationDescription("Fast Zig bot");
_ = try client.setCurrentApplicationIcon("data:image/png;base64,...");
_ = try client.clearCurrentApplicationIcon();
_ = try client.setCurrentApplicationCoverImage("data:image/png;base64,...");
_ = try client.clearCurrentApplicationCoverImage();
_ = try client.fetchCurrentUser();
_ = try client.fetchMe();
_ = try client.fetchUser(user_id);
_ = try client.createDm(user_id);
_ = try client.createDM(user_id);
_ = try client.editCurrentUser(discord.Types.EditCurrentUser.init().withUsername("zigbot"));
_ = try client.setCurrentUsername("zigbot");
_ = try client.setCurrentUserAvatar("data:image/png;base64,...");
_ = try client.clearCurrentUserAvatar();
_ = try client.setCurrentUserBanner("data:image/png;base64,...");
_ = try client.clearCurrentUserBanner();
_ = try client.editMe(discord.Types.EditCurrentUser.init().withUsername("aliasbot"));
_ = try client.fetchCurrentUserGuilds(discord.Types.ListCurrentUserGuilds.init().withLimit(100).withCounts(true));
_ = try client.fetchCurrentUserGuildMember(guild_id);
_ = try client.fetchCurrentUserConnections();
_ = try client.fetchCurrentAuthorization("Bearer user-oauth-token");
_ = try client.exchangeOAuth2Token("Basic base64-client-credentials", discord.Types.OAuth2TokenRequest.authorizationCode("oauth-code")
    .withRedirectUri("https://example.com/callback"));
_ = try client.revokeOAuth2Token("Basic base64-client-credentials", discord.Types.OAuth2TokenRevocation.init("refresh-token"));
_ = try client.fetchCurrentUserApplicationRoleConnection("Bearer user-oauth-token", application_id);
_ = try client.setCurrentUserApplicationRoleConnection("Bearer user-oauth-token", application_id, discord.Types.UpdateApplicationRoleConnection.init()
    .withPlatformName("zig league")
    .withMetadata(&.{.{ .key = "level", .value = "42" }}));
_ = try client.fetchGuild(guild_id);
_ = try client.fetchGuildWithOptions(guild_id, discord.Types.GetGuild.init().withCounts(true));
_ = try client.fetchGuildPreview(guild_id);
_ = try client.editGuild(guild_id, discord.Types.EditGuild.init().withDescription("Built with Zig"));
_ = try client.fetchChannel(channel_id);
_ = try client.fetchMember(guild_id, user_id);
_ = try client.fetchAuditLog(guild_id, discord.Types.ListAuditLog.init().withLimit(25));
_ = try client.fetchGuildIntegrations(guild_id);
_ = try client.deleteGuildIntegration(guild_id, integration_id);
_ = try client.fetchApplicationSkus(application_id);
const role_metadata = [_]discord.Types.ApplicationRoleConnectionMetadata{
    discord.Types.ApplicationRoleConnectionMetadata.init(.integer_greater_than_or_equal, "level", "Level", "Player level"),
};
_ = try client.fetchApplicationRoleConnectionMetadataRecords(application_id);
_ = try client.setApplicationRoleConnectionMetadataRecords(
    application_id,
    discord.Types.UpdateApplicationRoleConnectionMetadataRecords.init(&role_metadata),
);
_ = try client.fetchApplicationActivityInstance(application_id, "activity-instance-id");
_ = try client.fetchApplicationEmojis(application_id);
_ = try client.fetchApplicationEmoji(application_id, emoji_id);
_ = try client.createApplicationEmoji(application_id, discord.Types.CreateApplicationEmoji.init("zig", "data:image/webp;base64,..."));
_ = try client.createApplicationEmojiWithImage(application_id, "zig", "data:image/webp;base64,...");
_ = try client.editApplicationEmoji(application_id, emoji_id, discord.Types.EditApplicationEmoji.init("ziggy"));
_ = try client.renameApplicationEmoji(application_id, emoji_id, "ziggy");
_ = try client.deleteApplicationEmoji(application_id, emoji_id);
_ = try client.fetchEntitlements(application_id, discord.Types.ListEntitlements.init().forGuild(guild_id));
_ = try client.fetchEntitlement(application_id, entitlement_id);
_ = try client.markEntitlementConsumed(application_id, entitlement_id);
_ = try client.createTestEntitlement(application_id, discord.Types.CreateTestEntitlement.init(sku_id, guild_id, .guild));
_ = try client.fetchSkuSubscriptions(sku_id, discord.Types.ListSkuSubscriptions.init().forUser(user_id));
_ = try client.fetchSkuSubscription(sku_id, subscription_id);
_ = try client.fetchAutoModerationRules(guild_id);
_ = try client.fetchAutoModerationRule(guild_id, rule_id);
_ = try client.createAutoModerationRule(guild_id, discord.Types.CreateAutoModerationRule.init(
    "spam guard",
    .spam,
    &.{discord.Types.AutoModerationAction.blockMessage(null)},
));
_ = try client.getChannel(channel_id);
_ = try client.getGuildMember(guild_id, user_id);
_ = try client.leaveGuild(guild_id);
```

Guild template helpers cover common template management flows:

```zig
_ = try client.fetchGuildTemplate("template-code");
_ = try client.fetchGuildTemplates(guild_id);
_ = try client.createGuildTemplate(guild_id, discord.Types.CreateGuildTemplate.init("starter"));
_ = try client.syncGuildTemplate(guild_id, "template-code");
_ = try client.editGuildTemplate(guild_id, "template-code", discord.Types.EditGuildTemplate.init().withDescription("Updated"));
_ = try client.deleteGuildTemplate(guild_id, "template-code");
_ = try client.fetchGuildWidgetSettings(guild_id);
_ = try client.editGuildWidgetSettings(guild_id, discord.Types.EditGuildWidgetSettings.init().enabledState(true));
_ = try client.fetchGuildWidget(guild_id);
_ = try client.fetchGuildWidgetImage(guild_id, discord.Types.GetGuildWidgetImage.init().withStyle(.banner2));
_ = try client.fetchGuildWelcomeScreen(guild_id);
const welcome_channels = [_]discord.Types.WelcomeScreenChannel{
    discord.Types.WelcomeScreenChannel.init(channel_id, "Read rules").withEmojiName("wave"),
};
_ = try client.editGuildWelcomeScreen(guild_id, discord.Types.EditWelcomeScreen.init()
    .enabledState(true)
    .withChannels(&welcome_channels)
    .withDescription("Start here"));
_ = try client.fetchGuildOnboarding(guild_id);
_ = try client.editGuildOnboarding(guild_id, discord.Types.EditGuildOnboarding.init()
    .withDefaultChannels(&.{channel_id})
    .enabledState(true)
    .withMode(.onboarding_advanced));
_ = try client.setGuildIncidentActions(guild_id, discord.Types.EditGuildIncidentActions.init().clearInvitesDisabledUntil());
_ = try client.fetchGuildVanityUrl(guild_id);
_ = try client.fetchGuildScheduledEvents(guild_id, discord.Types.ListGuildScheduledEvents.init().withUserCount(true));
_ = try client.fetchGuildScheduledEvent(guild_id, event_id, discord.Types.GetGuildScheduledEvent.init().withUserCount(true));
_ = try client.createGuildScheduledEvent(guild_id, discord.Types.CreateGuildScheduledEvent.init("Launch", "2026-06-02T10:00:00.000Z", .voice).withChannel(channel_id));
_ = try client.editGuildScheduledEvent(guild_id, event_id, discord.Types.EditGuildScheduledEvent.init().withStatus(.active));
_ = try client.fetchGuildScheduledEventUsers(guild_id, event_id, discord.Types.ListGuildScheduledEventUsers.init().withLimit(25));
_ = try client.createStageInstance(discord.Types.CreateStageInstance.init(stage_channel_id, "Live Q&A").withScheduledEvent(event_id));
_ = try client.fetchStageInstance(stage_channel_id);
_ = try client.editStageInstance(stage_channel_id, discord.Types.EditStageInstance.init().withTopic("Aftershow"));
_ = try client.deleteStageInstance(stage_channel_id);
_ = try client.fetchVoiceRegions();
_ = try client.fetchGuildVoiceRegions(guild_id);
_ = try client.fetchCurrentUserVoiceState(guild_id);
_ = try client.fetchUserVoiceState(guild_id, user_id);
_ = try client.editCurrentUserVoiceState(guild_id, discord.Types.EditCurrentUserVoiceState.init().suppressState(false));
_ = try client.editUserVoiceState(guild_id, user_id, discord.Types.EditUserVoiceState.init().suppressState(true));
```

Direct messages use the same channel message helpers after opening the DM channel:

```zig
_ = try client.createDmChannel(user_id);
```

Guild channel management helpers cover common Discord.js channel flows:

```zig
_ = try client.fetchGuildChannels(guild_id);
_ = try client.createGuildChannel(
    guild_id,
    discord.Types.CreateGuildChannel.init("general")
        .withType(.guild_text)
        .withTopic("Project chat"),
);

_ = try client.setGuildChannelPositions(guild_id, &.{
    discord.Types.GuildChannelPosition.init(channel_id).withPosition(2),
});
_ = try client.editChannel(channel_id, discord.Types.EditChannel.init().withName("announcements"));
_ = try client.deleteChannel(channel_id);
_ = try client.setChannelPermission(channel_id, role_id, discord.Types.EditChannelPermission.init(.role)
    .withAllow(discord.Permissions.view_channel)
    .withDeny(discord.Permissions.send_messages));
_ = try client.removeChannelPermission(channel_id, role_id);
_ = try client.setVoiceChannelStatus(voice_channel_id, discord.Types.SetVoiceChannelStatus.init("Focus room"));
_ = try client.setVoiceChannelStatusText(voice_channel_id, "Focus room");
_ = try client.clearVoiceChannelStatus(voice_channel_id);
_ = try client.followAnnouncementChannel(news_channel_id, discord.Types.FollowAnnouncementChannel.init(target_channel_id));
_ = try client.followAnnouncementChannelTo(news_channel_id, target_channel_id);
_ = try client.followNewsChannelTo(news_channel_id, target_channel_id);

_ = try client.createThread(channel_id, discord.Types.CreateThread.init("private-review")
    .withType(.private_thread)
    .invitableState(false));
_ = try client.createThreadWithName(channel_id, "standalone");
_ = try client.leaveThread(thread_id);

_ = try client.createInvite(channel_id, discord.Types.CreateChannelInvite.init().withMaxUses(1).uniqueState(true));
_ = try client.createDefaultInvite(channel_id);
_ = try client.createInviteWithMaxUses(channel_id, 1);
_ = try client.createInviteWithMaxAge(channel_id, 3600);
_ = try client.createUniqueInvite(channel_id);
_ = try client.fetchChannelInvites(channel_id);
_ = try client.fetchGuildInvites(guild_id);
_ = try client.fetchInvite("invite-code");
_ = try client.fetchInviteWithOptions("invite-code", discord.Types.GetInvite.init().withCounts(true));
_ = try client.fetchInviteTargetUsers("invite-code");
_ = try client.updateInviteTargetUsers(
    "invite-code",
    discord.Types.UploadFile.init("targets.csv", "user_id\n123\n").withContentType("text/csv"),
);
_ = try client.fetchInviteTargetUsersJobStatus("invite-code");
_ = try client.deleteInvite("invite-code");

const lobby_metadata = [_]discord.Types.StringPair{.{ .key = "mode", .value = "duo" }};
_ = try client.createLobby(discord.Types.CreateLobby.init().withMetadata(&lobby_metadata).withIdleTimeout(60));
_ = try client.fetchLobby(lobby_id);
_ = try client.editLobby(lobby_id, discord.Types.EditLobby.init().clearMetadata());
_ = try client.setLobbyMember(lobby_id, user_id, discord.Types.UpdateLobbyMember.init().withMetadata(&lobby_metadata).withFlags(1));
_ = try client.bulkUpdateLobbyMembers(lobby_id, discord.Types.BulkUpdateLobbyMembers.init(&.{discord.Types.LobbyMember.init(user_id).removeState(true)}));
_ = try client.linkLobbyChannel("Bearer user-oauth-token", lobby_id, discord.Types.LinkLobbyChannel.init(channel_id));
_ = try client.unlinkLobbyChannel("Bearer user-oauth-token", lobby_id);
_ = try client.setLobbyMessageModerationMetadata(lobby_id, message_id, discord.Types.UpdateLobbyMessageModerationMetadata.init(&.{
    .{ .key = "action", .value = "replace" },
    .{ .key = "replacement", .value = "Be kind" },
}));
_ = try client.leaveLobby("Bearer user-oauth-token", lobby_id);
_ = try client.deleteLobby(lobby_id);

_ = try client.fetchChannelWebhooks(channel_id);
_ = try client.createWebhook(channel_id, discord.Types.CreateWebhook.init("deploys"));
_ = try client.createWebhookWithName(channel_id, "deploys");
_ = try client.createWebhookWithAvatar(channel_id, "deploys", "data:image/png;base64,AAAA");
_ = try client.fetchGuildWebhooks(guild_id);
_ = try client.fetchWebhook(webhook_id);
_ = try client.editWebhook(webhook_id, discord.Types.EditWebhook.init().withName("deploys-updated"));
_ = try client.fetchWebhookWithToken(webhook_id, webhook_token);
_ = try client.editWebhookWithToken(webhook_id, webhook_token, discord.Types.EditWebhookWithToken.init().withName("token-deploys"));
_ = try client.executeWebhook(webhook_id, webhook_token, discord.Types.ExecuteWebhook.init("deployed").withUsername("deploys"));
_ = try client.executeWebhookWithContent(webhook_id, webhook_token, "deployed");
_ = try client.fetchWebhookMessage(webhook_id, webhook_token, webhook_message_id);
_ = try client.editWebhookMessage(webhook_id, webhook_token, webhook_message_id, discord.Types.EditMessage.init().withContent("updated"));
_ = try client.deleteWebhookMessage(webhook_id, webhook_token, webhook_message_id);
_ = try client.deleteWebhookWithToken(webhook_id, webhook_token);
_ = try client.deleteWebhook(webhook_id);
```

Role helpers cover common moderation setup flows:

```zig
_ = try client.fetchRoles(guild_id);
_ = try client.fetchRole(guild_id, role_id);
_ = try client.fetchRoleMemberCounts(guild_id);
_ = try client.createGuildRole(
    guild_id,
    discord.Types.CreateGuildRole.init("moderator")
        .withPermissions(discord.Permissions.manage_messages)
        .withColors(discord.Types.RoleColors.init(0x5865F2))
        .withUnicodeEmoji("⚡")
        .mentionableState(true),
);
_ = try client.createRoleWithName(guild_id, "moderator");

_ = try client.editGuildRolePositions(guild_id, &.{
    discord.Types.GuildRolePosition.init(role_id).withPosition(2),
});
_ = try client.editGuildRole(guild_id, role_id, discord.Types.EditGuildRole.init().hoisted(false));
_ = try client.renameRole(guild_id, role_id, "moderator-renamed");
_ = try client.deleteGuildRole(guild_id, role_id);
_ = try client.addRole(guild_id, user_id, role_id);
_ = try client.removeRole(guild_id, user_id, role_id);
```

Guild emoji helpers cover list, fetch, create, edit, and delete flows:

```zig
_ = try client.fetchEmojis(guild_id);
_ = try client.fetchEmoji(guild_id, emoji_id);
_ = try client.createGuildEmoji(guild_id, discord.Types.CreateGuildEmoji.init("zig", "data:image/webp;base64,..."));
_ = try client.createEmojiWithImage(guild_id, "zig", "data:image/webp;base64,...");
_ = try client.editGuildEmoji(guild_id, emoji_id, discord.Types.EditGuildEmoji.init().withName("ziggy"));
_ = try client.renameEmoji(guild_id, emoji_id, "ziggy");
_ = try client.deleteGuildEmoji(guild_id, emoji_id);
```

Guild sticker helpers support fetch, multipart create, edit, and delete flows:

```zig
_ = try client.fetchStickerById(sticker_id);
_ = try client.fetchStickerPacks();
_ = try client.fetchStickers(guild_id);
_ = try client.fetchSticker(guild_id, sticker_id);
_ = try client.createGuildSticker(
    guild_id,
    discord.Types.CreateGuildSticker.init("zig", "zap").withDescription("Zig mascot"),
    .{ .filename = "zig.png", .content = png_bytes, .content_type = "image/png" },
);
_ = try client.editGuildSticker(guild_id, sticker_id, discord.Types.EditGuildSticker.init().withName("ziggy"));
_ = try client.renameSticker(guild_id, sticker_id, "ziggy");
_ = try client.setStickerDescription(guild_id, sticker_id, "Zig mascot");
_ = try client.setStickerTags(guild_id, sticker_id, "zig,zap");
_ = try client.deleteGuildSticker(guild_id, sticker_id);
```

Member moderation helpers cover OAuth member add, kick, ban, unban, ban fetch/list, prune, and common member edits:

```zig
_ = try client.addGuildMember(guild_id, user_id, discord.Types.AddGuildMember.init("user-oauth-access-token")
    .withNick("helper")
    .withRoles(&.{role_id}));
_ = try client.editCurrentGuildMember(guild_id, discord.Types.EditCurrentGuildMember.init().withNick("ziggy"));
_ = try client.setCurrentGuildMemberNick(guild_id, "ziggy");
_ = try client.clearCurrentGuildMemberNick(guild_id);
_ = try client.setCurrentGuildMemberAvatar(guild_id, "data:image/png;base64,...");
_ = try client.clearCurrentGuildMemberAvatar(guild_id);
_ = try client.setCurrentGuildMemberBanner(guild_id, "data:image/png;base64,...");
_ = try client.clearCurrentGuildMemberBanner(guild_id);
_ = try client.setCurrentGuildMemberBio(guild_id, "Built with Zig");
_ = try client.clearCurrentGuildMemberBio(guild_id);
_ = try client.setNickname(guild_id, "ziggy");
_ = try client.editGuildMember(guild_id, user_id, discord.Types.EditGuildMember.init()
    .withNick("helper")
    .timeoutUntil("2026-06-02T10:00:00.000Z"));
_ = try client.setMemberNickname(guild_id, user_id, "helper");
_ = try client.setMemberRoles(guild_id, user_id, &.{role_id});
_ = try client.muteMember(guild_id, user_id, true);
_ = try client.deafenMember(guild_id, user_id, true);
_ = try client.moveMemberToVoiceChannel(guild_id, user_id, voice_channel_id);
_ = try client.timeoutMember(guild_id, user_id, "2026-06-02T10:00:00.000Z");
_ = try client.clearMemberTimeout(guild_id, user_id);

_ = try client.kick(guild_id, user_id);
_ = try client.fetchMembers(guild_id, discord.Types.ListGuildMembers.init().withLimit(100));
_ = try client.searchMembers(guild_id, discord.Types.SearchGuildMembers.init("helper").withLimit(25));
_ = try client.fetchBans(guild_id, discord.Types.ListGuildBans.init().withLimit(25));
_ = try client.fetchBan(guild_id, user_id);
_ = try client.fetchPruneCount(guild_id, discord.Types.GetGuildPruneCount.init().withDays(14));
_ = try client.prune(guild_id, discord.Types.BeginGuildPrune.init().withDays(14).computeCount(false));
_ = try client.pruneMembers(guild_id);
_ = try client.pruneMembersWithDays(guild_id, 14);
_ = try client.pruneMembersWithDaysAndCount(guild_id, 14, false);
_ = try client.ban(guild_id, user_id, discord.Types.CreateGuildBan.init().deleteMessagesFor(3600));
_ = try client.banUser(guild_id, user_id);
_ = try client.banUserDeletingMessagesFor(guild_id, user_id, 3600);
_ = try client.bulkBan(guild_id, discord.Types.BulkGuildBan.init(&.{ user_id_a, user_id_b }).deleteMessagesFor(3600));
_ = try client.bulkBanUsers(guild_id, &.{ user_id_a, user_id_b });
_ = try client.bulkBanUsersDeletingMessagesFor(guild_id, &.{ user_id_a, user_id_b }, 3600);
_ = try client.unban(guild_id, user_id);
```

Soundboard helpers cover default sounds, guild sounds, and sending a sound to a voice channel:

```zig
_ = try client.fetchDefaultSoundboardSounds();
_ = try client.fetchGuildSoundboardSounds(guild_id);
_ = try client.fetchGuildSoundboardSound(guild_id, sound_id);
_ = try client.createGuildSoundboardSound(guild_id, discord.Types.CreateGuildSoundboardSound.init("launch", "data:audio/ogg;base64,T0dH").withVolume(0.5));
_ = try client.createSoundboardSoundWithData(guild_id, "launch", "data:audio/ogg;base64,T0dH");
_ = try client.renameSoundboardSound(guild_id, sound_id, "launch-renamed");
_ = try client.sendSoundboardSound(voice_channel_id, discord.Types.SendSoundboardSound.init(sound_id));
_ = try client.sendSoundboardSoundById(voice_channel_id, sound_id);
_ = try client.playSoundboardSound(voice_channel_id, sound_id);
```

The top-level client also exposes small Discord.js-like convenience methods:

```zig
client.onMessageCreate(discord.Events.rawHandler(&state, State.onMessage));
client.onMessageUpdate(discord.Events.rawHandler(&state, State.onMessageUpdate));
client.onMessageDelete(discord.Events.rawHandler(&state, State.onMessageDelete));
client.onMessageReactionAdd(discord.Events.rawHandler(&state, State.onMessageReactionAdd));
client.onMessagePollVoteAdd(discord.Events.rawHandler(&state, State.onMessagePollVoteAdd));
client.onChannelPinsUpdate(discord.Events.rawHandler(&state, State.onChannelPinsUpdate));
client.onTypingStart(discord.Events.rawHandler(&state, State.onTypingStart));
client.onInviteCreate(discord.Events.rawHandler(&state, State.onInviteCreate));
client.onWebhooksUpdate(discord.Events.rawHandler(&state, State.onWebhooksUpdate));
client.onAutoModerationRuleCreate(discord.Events.rawHandler(&state, State.onAutoModerationRuleCreate));
client.onAutoModerationActionExecution(discord.Events.rawHandler(&state, State.onAutoModerationActionExecution));
client.onEntitlementCreate(discord.Events.rawHandler(&state, State.onEntitlementCreate));
client.onEntitlementDelete(discord.Events.rawHandler(&state, State.onEntitlementDelete));
client.onGuildSoundboardSoundCreate(discord.Events.rawHandler(&state, State.onGuildSoundboardSoundCreate));
client.onSoundboardSounds(discord.Events.rawHandler(&state, State.onSoundboardSounds));
client.onApplicationCommandPermissionsUpdate(discord.Events.rawHandler(&state, State.onApplicationCommandPermissionsUpdate));
client.onUserUpdate(discord.Events.rawHandler(&state, State.onUserUpdate));
client.onPresenceUpdate(discord.Events.rawHandler(&state, State.onPresenceUpdate));
client.onVoiceStateUpdate(discord.Events.rawHandler(&state, State.onVoiceStateUpdate));
client.onVoiceServerUpdate(discord.Events.rawHandler(&state, State.onVoiceServerUpdate));
client.onGuildAuditLogEntryCreate(discord.Events.rawHandler(&state, State.onGuildAuditLogEntryCreate));
client.onGuildBanAdd(discord.Events.rawHandler(&state, State.onGuildBanAdd));
client.onGuildMembersChunk(discord.Events.rawHandler(&state, State.onGuildMembersChunk));
client.onIntegrationCreate(discord.Events.rawHandler(&state, State.onIntegrationCreate));
client.onGuildMemberAdd(discord.Events.rawHandler(&state, State.onGuildMemberAdd));
client.onGuildEmojisUpdate(discord.Events.rawHandler(&state, State.onGuildEmojisUpdate));
client.onGuildStickersUpdate(discord.Events.rawHandler(&state, State.onGuildStickersUpdate));
client.onGuildScheduledEventCreate(discord.Events.rawHandler(&state, State.onGuildScheduledEventCreate));
client.onStageInstanceCreate(discord.Events.rawHandler(&state, State.onStageInstanceCreate));
client.onChannelDelete(discord.Events.rawHandler(&state, State.onChannelDelete));
client.onChannelInfo(discord.Events.rawHandler(&state, State.onChannelInfo));
client.onVoiceChannelStatusUpdate(discord.Events.rawHandler(&state, State.onVoiceChannelStatusUpdate));
client.onVoiceChannelStartTimeUpdate(discord.Events.rawHandler(&state, State.onVoiceChannelStartTimeUpdate));
client.onThreadCreate(discord.Events.rawHandler(&state, State.onThreadCreate));
client.onApplicationCommand(discord.Events.rawHandler(&state, State.onApplicationCommand));
client.onMessageComponent(discord.Events.rawHandler(&state, State.onMessageComponent));
client.onModalSubmit(discord.Events.rawHandler(&state, State.onModalSubmit));
client.onResumed(discord.Events.rawHandler(&state, State.onResumed));
client.onUnknown(discord.Events.rawHandler(&state, State.onUnknown));
client.onceReady(discord.Events.rawHandler(&state, State.onReady));
client.onceMessageCreate(discord.Events.rawHandler(&state, State.onMessage));
client.onceMessageUpdate(discord.Events.rawHandler(&state, State.onMessageUpdate));
client.onceMessageDelete(discord.Events.rawHandler(&state, State.onMessageDelete));
client.onceMessageDeleteBulk(discord.Events.rawHandler(&state, State.onMessageDeleteBulk));
client.onceMessageReactionAdd(discord.Events.rawHandler(&state, State.onMessageReactionAdd));
client.onceMessageReactionRemove(discord.Events.rawHandler(&state, State.onMessageReactionRemove));
client.onceMessageReactionRemoveAll(discord.Events.rawHandler(&state, State.onMessageReactionRemoveAll));
client.onceMessageReactionRemoveEmoji(discord.Events.rawHandler(&state, State.onMessageReactionRemoveEmoji));
client.onceMessagePollVoteAdd(discord.Events.rawHandler(&state, State.onMessagePollVoteAdd));
client.onceMessagePollVoteRemove(discord.Events.rawHandler(&state, State.onMessagePollVoteRemove));
client.onceInteractionCreate(discord.Events.rawHandler(&state, State.onInteractionCreate));
client.onceApplicationCommand(discord.Events.rawHandler(&state, State.onApplicationCommand));
client.onceMessageComponent(discord.Events.rawHandler(&state, State.onMessageComponent));
client.onceApplicationCommandAutocomplete(discord.Events.rawHandler(&state, State.onApplicationCommandAutocomplete));
client.onceModalSubmit(discord.Events.rawHandler(&state, State.onModalSubmit));
client.onceUserUpdate(discord.Events.rawHandler(&state, State.onUserUpdate));
client.oncePresenceUpdate(discord.Events.rawHandler(&state, State.onPresenceUpdate));
client.onceVoiceStateUpdate(discord.Events.rawHandler(&state, State.onVoiceStateUpdate));
client.onceTypingStart(discord.Events.rawHandler(&state, State.onTypingStart));
client.onceWebhooksUpdate(discord.Events.rawHandler(&state, State.onWebhooksUpdate));
client.onceInviteCreate(discord.Events.rawHandler(&state, State.onInviteCreate));
client.onceInviteDelete(discord.Events.rawHandler(&state, State.onInviteDelete));
client.onceAutoModerationRuleCreate(discord.Events.rawHandler(&state, State.onAutoModerationRuleCreate));
client.onceAutoModerationActionExecution(discord.Events.rawHandler(&state, State.onAutoModerationActionExecution));
client.onceEntitlementCreate(discord.Events.rawHandler(&state, State.onEntitlementCreate));
client.onceEntitlementDelete(discord.Events.rawHandler(&state, State.onEntitlementDelete));
client.onceGuildSoundboardSoundCreate(discord.Events.rawHandler(&state, State.onGuildSoundboardSoundCreate));
client.onceSoundboardSounds(discord.Events.rawHandler(&state, State.onSoundboardSounds));
client.onceGuildRoleCreate(discord.Events.rawHandler(&state, State.onGuildRoleCreate));
client.onceGuildEmojisUpdate(discord.Events.rawHandler(&state, State.onGuildEmojisUpdate));
client.onceGuildStickersUpdate(discord.Events.rawHandler(&state, State.onGuildStickersUpdate));
client.onceGuildScheduledEventCreate(discord.Events.rawHandler(&state, State.onGuildScheduledEventCreate));
client.onceStageInstanceCreate(discord.Events.rawHandler(&state, State.onStageInstanceCreate));
client.onceGuildAuditLogEntryCreate(discord.Events.rawHandler(&state, State.onGuildAuditLogEntryCreate));
client.onceGuildBanAdd(discord.Events.rawHandler(&state, State.onGuildBanAdd));
client.onceIntegrationCreate(discord.Events.rawHandler(&state, State.onIntegrationCreate));
client.onceGuildMembersChunk(discord.Events.rawHandler(&state, State.onGuildMembersChunk));
client.onceVoiceServerUpdate(discord.Events.rawHandler(&state, State.onVoiceServerUpdate));
client.onceChannelPinsUpdate(discord.Events.rawHandler(&state, State.onChannelPinsUpdate));
client.onceThreadCreate(discord.Events.rawHandler(&state, State.onThreadCreate));
client.onceGuildCreate(discord.Events.rawHandler(&state, State.onGuildCreate));
client.onceGuildMemberAdd(discord.Events.rawHandler(&state, State.onGuildMemberAdd));
client.onceChannelCreate(discord.Events.rawHandler(&state, State.onChannelCreate));
client.on(.MESSAGE_CREATE, discord.Events.rawHandler(&state, State.onMessage));
client.once(.READY, discord.Events.rawHandler(&state, State.onReady));
const message_listener_count = client.listenerCount(.MESSAGE_CREATE);
const has_ready_listener = client.hasListener(.READY);
const active_events = try client.eventNames(allocator);
defer allocator.free(active_events);
client.clearListener(.MESSAGE_CREATE);
client.off(.MESSAGE_UPDATE);
client.removeListener(.INTERACTION_CREATE);
client.removeAllListeners();

const ready = client.isReady();
const ready_timestamp_ms = client.readyTimestampMs();
const uptime_ms = client.uptimeMs(now_ms);
const gateway_ping_ms = client.gatewayPingMs();
const last_sequence = client.lastGatewaySequence();
const last_event = client.lastGatewayEvent();
client.resetGatewayState();

_ = try client.sendMessage(channel_id, discord.Types.CreateMessage.init("pong"));
_ = try client.reply(channel_id, original_message_id, discord.Types.CreateMessage.init("reply"));
_ = try client.react(channel_id, message_id, "👍");

const cached = client.getCachedMessage(message_id);
const cached_message = client.cachedMessage(message_id);
const has_cached_message = client.hasCachedMessage(message_id);
const current_user_id = client.currentUserId();
const current_user = client.getCurrentCachedUser();
const me = client.me();
const current_user_alias = client.currentUser();
const has_current_user = client.hasCurrentCachedUser();
const current_application_id = client.currentApplicationId();
const current_application = client.getCurrentCachedApplication();
const current_application_alias = client.currentApplication();
const has_current_application = client.hasCurrentCachedApplication();
const cached_channel = client.getCachedChannel(channel_id);
const cached_channel_alias = client.cachedChannel(channel_id);
const has_cached_channel = client.hasCachedChannel(channel_id);
const cached_member = client.getCachedMember(guild_id, user_id);
const cached_member_alias = client.cachedMember(guild_id, user_id);
const has_cached_member = client.hasCachedMember(guild_id, user_id);
const cached_user = client.cachedUser(user_id);
const cached_guild = client.cachedGuild(guild_id);
const cached_role = client.getCachedRole(guild_id, role_id);
const cached_role_alias = client.cachedRole(guild_id, role_id);
const cached_emoji = client.getCachedEmoji(guild_id, emoji_id);
const cached_emoji_alias = client.cachedEmoji(guild_id, emoji_id);
const cached_sticker = client.getCachedSticker(guild_id, sticker_id);
const cached_sticker_alias = client.cachedSticker(guild_id, sticker_id);
const cached_scheduled_event = client.getCachedScheduledEvent(guild_id, event_id);
const cached_scheduled_event_alias = client.cachedScheduledEvent(guild_id, event_id);
const cached_stage_instance = client.getCachedStageInstance(guild_id, stage_instance_id);
const cached_stage_instance_alias = client.cachedStageInstance(guild_id, stage_instance_id);
const cached_invite = client.getCachedInvite("invite-code");
const cached_invite_alias = client.cachedInvite("invite-code");
const cached_presence = client.getCachedPresence(guild_id, user_id);
const cached_presence_alias = client.cachedPresence(guild_id, user_id);
const cached_voice_state = client.getCachedVoiceState(guild_id, user_id);
const cached_voice_state_alias = client.cachedVoiceState(guild_id, user_id);
const cache_stats = client.cacheStats();
const cached_user_count = client.cachedUserCount();
const cached_guild_count = client.cachedGuildCount();
const cached_channel_count = client.cachedChannelCount();
const cached_member_count = client.cachedMemberCount();
const cached_role_count = client.cachedRoleCount();
const cached_emoji_count = client.cachedEmojiCount();
const cached_sticker_count = client.cachedStickerCount();
const cached_message_count = client.cachedMessageCount();
const guild_cache_stats = client.guildCacheStats(guild_id);
const channel_cache_stats = client.channelCacheStats(channel_id);

client.evictCachedMessage(message_id);
client.evictCachedChannel(channel_id);
client.evictCachedMember(guild_id, user_id);
client.evictCachedInvite("invite-code");
client.clearCache();

const cached_users = try client.listCachedUsers(allocator);
defer allocator.free(cached_users);
const cached_users_alias = try client.cachedUsers(allocator);
defer allocator.free(cached_users_alias);
const cached_guilds = try client.listCachedGuilds(allocator);
defer allocator.free(cached_guilds);
const cached_guilds_alias = try client.cachedGuilds(allocator);
defer allocator.free(cached_guilds_alias);
const cached_all_channels = try client.listCachedChannels(allocator);
defer allocator.free(cached_all_channels);
const cached_all_channels_alias = try client.cachedChannels(allocator);
defer allocator.free(cached_all_channels_alias);
const cached_top_level_channels = try client.listCachedTopLevelChannels(allocator);
defer allocator.free(cached_top_level_channels);
const cached_top_level_channels_alias = try client.cachedTopLevelChannels(allocator);
defer allocator.free(cached_top_level_channels_alias);
const cached_all_messages = try client.listCachedMessages(allocator);
defer allocator.free(cached_all_messages);
const cached_all_messages_alias = try client.cachedMessages(allocator);
defer allocator.free(cached_all_messages_alias);
const cached_guild_messages = try client.listCachedGuildMessages(allocator, guild_id);
defer allocator.free(cached_guild_messages);
const cached_guild_messages_alias = try client.cachedGuildMessages(allocator, guild_id);
defer allocator.free(cached_guild_messages_alias);
const cached_messages = try client.listCachedChannelMessages(allocator, channel_id);
defer allocator.free(cached_messages);
const cached_messages_alias = try client.cachedChannelMessages(allocator, channel_id);
defer allocator.free(cached_messages_alias);
const cached_channels = try client.listCachedGuildChannels(allocator, guild_id);
defer allocator.free(cached_channels);
const cached_channels_alias = try client.cachedGuildChannels(allocator, guild_id);
defer allocator.free(cached_channels_alias);
const cached_threads = try client.listCachedChannelThreads(allocator, channel_id);
defer allocator.free(cached_threads);
const cached_threads_alias = try client.cachedChannelThreads(allocator, channel_id);
defer allocator.free(cached_threads_alias);
const cached_guild_threads = try client.listCachedGuildThreads(allocator, guild_id);
defer allocator.free(cached_guild_threads);
const cached_guild_threads_alias = try client.cachedGuildThreads(allocator, guild_id);
defer allocator.free(cached_guild_threads_alias);
const cached_all_members = try client.listCachedMembers(allocator);
defer allocator.free(cached_all_members);
const cached_all_members_alias = try client.cachedMembers(allocator);
defer allocator.free(cached_all_members_alias);
const cached_members = try client.listCachedGuildMembers(allocator, guild_id);
defer allocator.free(cached_members);
const cached_members_alias = try client.cachedGuildMembers(allocator, guild_id);
defer allocator.free(cached_members_alias);
const cached_all_roles = try client.listCachedRoles(allocator);
defer allocator.free(cached_all_roles);
const cached_all_roles_alias = try client.cachedRoles(allocator);
defer allocator.free(cached_all_roles_alias);
const cached_roles = try client.listCachedGuildRoles(allocator, guild_id);
defer allocator.free(cached_roles);
const cached_roles_alias = try client.cachedGuildRoles(allocator, guild_id);
defer allocator.free(cached_roles_alias);
const cached_all_emojis = try client.listCachedEmojis(allocator);
defer allocator.free(cached_all_emojis);
const cached_all_emojis_alias = try client.cachedEmojis(allocator);
defer allocator.free(cached_all_emojis_alias);
const cached_emojis = try client.listCachedGuildEmojis(allocator, guild_id);
defer allocator.free(cached_emojis);
const cached_emojis_alias = try client.cachedGuildEmojis(allocator, guild_id);
defer allocator.free(cached_emojis_alias);
const cached_all_stickers = try client.listCachedStickers(allocator);
defer allocator.free(cached_all_stickers);
const cached_all_stickers_alias = try client.cachedStickers(allocator);
defer allocator.free(cached_all_stickers_alias);
const cached_stickers = try client.listCachedGuildStickers(allocator, guild_id);
defer allocator.free(cached_stickers);
const cached_stickers_alias = try client.cachedGuildStickers(allocator, guild_id);
defer allocator.free(cached_stickers_alias);
const cached_all_events = try client.listCachedScheduledEvents(allocator);
defer allocator.free(cached_all_events);
const cached_all_events_alias = try client.cachedScheduledEvents(allocator);
defer allocator.free(cached_all_events_alias);
const cached_events = try client.listCachedGuildScheduledEvents(allocator, guild_id);
defer allocator.free(cached_events);
const cached_events_alias = try client.cachedGuildScheduledEvents(allocator, guild_id);
defer allocator.free(cached_events_alias);
const cached_all_stage_instances = try client.listCachedStageInstances(allocator);
defer allocator.free(cached_all_stage_instances);
const cached_all_stage_instances_alias = try client.cachedStageInstances(allocator);
defer allocator.free(cached_all_stage_instances_alias);
const cached_stage_instances = try client.listCachedGuildStageInstances(allocator, guild_id);
defer allocator.free(cached_stage_instances);
const cached_stage_instances_alias = try client.cachedGuildStageInstances(allocator, guild_id);
defer allocator.free(cached_stage_instances_alias);
const cached_invites = try client.listCachedInvites(allocator);
defer allocator.free(cached_invites);
const cached_invites_alias = try client.cachedInvites(allocator);
defer allocator.free(cached_invites_alias);
const cached_guild_invites = try client.listCachedGuildInvites(allocator, guild_id);
defer allocator.free(cached_guild_invites);
const cached_guild_invites_alias = try client.cachedGuildInvites(allocator, guild_id);
defer allocator.free(cached_guild_invites_alias);
const cached_channel_invites = try client.listCachedChannelInvites(allocator, channel_id);
defer allocator.free(cached_channel_invites);
const cached_channel_invites_alias = try client.cachedChannelInvites(allocator, channel_id);
defer allocator.free(cached_channel_invites_alias);
const cached_all_presences = try client.listCachedPresences(allocator);
defer allocator.free(cached_all_presences);
const cached_all_presences_alias = try client.cachedPresences(allocator);
defer allocator.free(cached_all_presences_alias);
const cached_presences = try client.listCachedGuildPresences(allocator, guild_id);
defer allocator.free(cached_presences);
const cached_presences_alias = try client.cachedGuildPresences(allocator, guild_id);
defer allocator.free(cached_presences_alias);
const cached_all_voice_states = try client.listCachedVoiceStates(allocator);
defer allocator.free(cached_all_voice_states);
const cached_all_voice_states_alias = try client.cachedVoiceStates(allocator);
defer allocator.free(cached_all_voice_states_alias);
const cached_voice_states = try client.listCachedGuildVoiceStates(allocator, guild_id);
defer allocator.free(cached_voice_states);
const cached_voice_states_alias = try client.cachedGuildVoiceStates(allocator, guild_id);
defer allocator.free(cached_voice_states_alias);
```

Collectors provide small stateful filters for message and interaction flows:

```zig
var collector = discord.Collectors.MessageCollector.init(.{
    .guild_id = guild_id,
    .channel_id = channel_id,
    .author_id = user_id,
    .contains = "confirm",
    .max = 1,
    .time_ms = 30_000,
    .idle_ms = 10_000,
});

if (client.getCachedMessage(message_id)) |message| {
    _ = collector.collectAt(message, now_ms);
}

_ = try collector.collectDispatchAt(gateway_dispatch, now_ms);
_ = collector.tick(now_ms);
const last_message_id = collector.last_message_id;

var interaction_collector = discord.Collectors.InteractionCollector.init(.{
    .guild_id = guild_id,
    .channel_id = channel_id,
    .user_id = user_id,
    .custom_id = "confirm",
    .max = 1,
    .time_ms = 30_000,
    .idle_ms = 10_000,
});

_ = try interaction_collector.collectDispatchAt(gateway_dispatch, now_ms);
_ = interaction_collector.tick(now_ms);
const last_interaction_id = interaction_collector.last_interaction_id;
```

Collectors keep only counters, status, timestamps, and the last collected snowflake so callers can drive simple flows without retaining payloads.

`examples/ping-bot.zig` uses an in-memory transport so it can run without a real bot token. `examples/slash-bot.zig` is an offline cookbook for slash commands: it defines and validates a command, routes an interaction through the `InteractionRouter` to a typed handler, and builds an ephemeral reply and a colored embed.

For live REST calls, initialize the client with its owned HTTP transport:

```zig
var client = try discord.Client.initHttp(allocator, .{
    .token = "Bot real-token",
    .intents = discord.Intents.add(discord.Intents.defaultNonPrivileged(), discord.Intents.message_content),
    .cache_policy = .{ .max_messages = 500 },
});
defer client.deinit();

const has_required_intents = discord.Intents.hasAll(client.config.intents, discord.Intents.guilds | discord.Intents.message_content);
const has_any_dm_intent = discord.Intents.hasAny(client.config.intents, discord.Intents.direct_messages | discord.Intents.direct_message_reactions);
const missing_intents = discord.Intents.missing(client.config.intents, discord.Intents.guild_members | discord.Intents.message_content);
```

Cache can also be minimized for memory-sensitive bots:

```zig
var client = discord.Client.init(allocator, .{
    .token = "Bot token",
    .cache_policy = discord.CachePolicy.noMessages(),
});
defer client.deinit();
// `destroy()` is available as a Discord.js-style alias for `deinit()`.
```

Responses returned by the live `HttpTransport` own their body and copied headers. Release them with `discord.Http.responseDeinit(allocator, response)` after you are done with the raw response.

Permission helpers can resolve guild role permissions and channel overwrites without allocating:

```zig
const guild_roles = [_]discord.Permissions.RolePermissions{
    .{ .id = role_id.value, .permissions = discord.Permissions.add(discord.Permissions.send_messages, discord.Permissions.pin_messages) },
};
const guild_permissions = discord.Permissions.resolveGuild(&.{role_id.value}, &guild_roles);

const overwrites = [_]discord.Permissions.Overwrite{
    discord.Permissions.Overwrite.role(guild_id.value, 0, discord.Permissions.send_messages),
    discord.Permissions.Overwrite.member(user_id.value, discord.Permissions.send_messages, 0),
};

const effective = discord.Permissions.resolveChannel(
    guild_permissions,
    guild_id.value,
    user_id.value,
    &.{role_id.value},
    &overwrites,
);
const can_send_and_pin = discord.Permissions.hasAll(effective, discord.Permissions.send_messages | discord.Permissions.pin_messages);
const can_moderate_any = discord.Permissions.hasAny(effective, discord.Permissions.manage_messages | discord.Permissions.moderate_members);
const missing_permissions = discord.Permissions.missing(effective, discord.Permissions.send_messages | discord.Permissions.pin_messages);
```

Gateway sessions use an injectable text-frame transport, so the protocol state machine stays testable and can be backed by any WebSocket implementation:

```zig
var session = client.createGatewaySession(websocket_transport);
_ = try client.fetchGateway();
_ = try client.fetchGatewayBot();
const shard_id = try discord.Gateway.shardIdForGuild(guild_id, 8);
const identify_bucket = try discord.Gateway.identifyRateLimitKey(shard_id, 2);
_ = identify_bucket;
try session.identify();
try session.sendHeartbeat();
try client.updatePresence(&session, discord.Gateway.Presence.init(.idle));
try client.setPresence(&session, discord.Gateway.Presence.init(.dnd));
try client.setActivity(&session, "Zig bots", discord.SetActivityOptions.init(.watching));
try client.updateVoiceState(
    &session,
    discord.Gateway.VoiceStateUpdate.init(guild_id).withChannel(voice_channel_id),
);
try client.requestGuildMembers(
    &session,
    discord.Gateway.RequestGuildMembers.init(guild_id).withQuery("helper").withLimit(25),
);
try client.requestSoundboardSounds(&session, discord.Gateway.RequestSoundboardSounds.init(&.{guild_id}));
try client.requestChannelInfo(
    &session,
    discord.Gateway.RequestChannelInfo.init(guild_id, &.{ .status, .voice_start_time }),
);
```

For live Gateway connections, use the built-in WSS transport:

```zig
var gateway_transport = discord.GatewayTransport.Transport.init(allocator);
defer gateway_transport.deinit();

try gateway_transport.connect(.{});

var gateway = client.createGatewayRunner(gateway_transport.sessionTransport());
defer gateway.deinit();

_ = try gateway.step(now_ms); // handles HELLO, sends IDENTIFY, schedules heartbeat
_ = try gateway.step(later_ms); // sends heartbeat or dispatches events/cache updates

if (!gateway.reconnectReady(now_ms)) {
    const retry_at = gateway.reconnectAfterMs().?;
    _ = retry_at;
}
const can_resume = gateway.canResume();
const session_id = gateway.sessionId();
const sequence = gateway.sequence();
const next_heartbeat = gateway.nextHeartbeatMs();
const heartbeat_interval = gateway.heartbeatIntervalMs();
const waiting_for_ack = gateway.awaitingHeartbeatAck();
```

For event loops that should not sleep inside the library, use the nonblocking runtime adapter. It reports whether the caller should connect, wait, or handle a Gateway step:

```zig
var runtime = discord.GatewayRuntime.NonblockingRuntime.init(&client, gateway_transport.sessionTransport());
defer runtime.deinit();

const runtime_connected = runtime.isConnected();
const reconnect_pending = runtime.isReconnectPending();
const reconnect_at = runtime.reconnectAfterMs();

switch (try runtime.step(now_ms)) {
    .stopped => return,
    .connect_required => {
        try gateway_transport.connect(.{});
        runtime.markConnected();
    },
    .wait_reconnect_ms => |delay_ms| _ = delay_ms,
    .gateway => |step| _ = step,
}
```

For a simple blocking bot process, the runtime adapter owns the live Gateway transport and reconnect sleeps:

```zig
try discord.GatewayRuntime.login(allocator, &client, .{});
```

Use the explicit runtime when you need lifecycle hooks or a shutdown signal:

```zig
var runtime = discord.GatewayRuntime.BlockingRuntime.init(allocator, &client);
defer runtime.deinit();

// Call runtime.stop() from your shutdown hook to break the run loop.
try runtime.run(.{});
```

The WebSocket codec exposes deterministic helpers for transport implementations:

```zig
var request = std.Io.Writer.Allocating.init(allocator);
defer request.deinit();

try discord.WebSocket.writeClientHandshakeRequest(
    "gateway.discord.gg",
    "/?v=10&encoding=json",
    websocket_key,
    &request.writer,
);
```

It also includes client frame writers and server frame decoding:

```zig
try discord.WebSocket.writeTextFrame(payload, mask_key, &writer);
const decoded = try discord.WebSocket.decodeFramePrefix(allocator, bytes);
defer discord.WebSocket.frameDeinit(allocator, decoded.frame);
```

Slash command definitions can be streamed directly into the REST command sync helpers:

```zig
const choices = [_]discord.Interactions.CommandChoice{
    discord.Interactions.CommandChoice.string("Public", "public"),
    discord.Interactions.CommandChoice.string("Private", "private"),
};

const options = [_]discord.Interactions.ApplicationCommandOption{
    discord.Interactions.ApplicationCommandOption
        .string("visibility", "Who can see the reply", false)
        .requiredOption()
        .withChoices(&choices),
    discord.Interactions.ApplicationCommandOption.number("ratio", "Scale factor", false),
    discord.Interactions.ApplicationCommandOption.role("role", "Role to notify", false),
    discord.Interactions.ApplicationCommandOption.mentionable("target", "User or role", false),
    discord.Interactions.ApplicationCommandOption.attachment("file", "File to process", false),
};

const name_localizations = [_]discord.Interactions.Localization{
    .{ .locale = "tr", .value = "profil" },
};

const user_option = discord.Interactions.ApplicationCommandOption
    .user("target", "User to inspect", false)
    .withNameLocalizations(&name_localizations)
    .requiredOption();

_ = try client.registerGlobalApplicationCommand(
    application_id,
    discord.Interactions.ApplicationCommand
        .chatInput("ping", "Replies with pong")
        .withDefaultMemberPermissions(8)
        .dmPermissionState(false),
);
_ = try client.setGlobalApplicationCommands(application_id, &.{
    discord.Interactions.ApplicationCommand
        .chatInput("echo", "Echoes text")
        .withOptions(&options),
    discord.Interactions.ApplicationCommand
        .chatInput("profile", "Shows a profile")
        .withOption(&user_option)
        .withNameLocalizations(&name_localizations),
});
_ = try client.fetchGlobalApplicationCommand(application_id, command_id);
_ = try client.updateGlobalApplicationCommand(
    application_id,
    command_id,
    discord.Interactions.EditApplicationCommand
        .init()
        .withDescription("Updated command")
        .clearDefaultMemberPermissions(),
);
_ = try client.renameGlobalApplicationCommand(application_id, command_id, "pong");
_ = try client.setGlobalApplicationCommandDescription(application_id, command_id, "Replies with pong");
_ = try client.removeGlobalApplicationCommand(application_id, command_id);

_ = try client.registerGuildApplicationCommand(
    application_id,
    guild_id,
    discord.Interactions.ApplicationCommand.chatInput("ping", "Replies with pong"),
);
_ = try client.setGuildApplicationCommands(application_id, guild_id, &.{
    discord.Interactions.ApplicationCommand
        .chatInput("echo", "Echoes text")
        .withOptions(&options),
});
_ = try client.fetchGuildApplicationCommand(application_id, guild_id, command_id);

_ = try client.editGuildApplicationCommand(
    application_id,
    guild_id,
    command_id,
    discord.Interactions.EditApplicationCommand.init()
        .withDescription("Echoes the supplied text")
        .withOptions(&options),
);
_ = try client.updateGuildApplicationCommand(
    application_id,
    guild_id,
    command_id,
    discord.Interactions.EditApplicationCommand.init().withDescription("Updated guild command"),
);
_ = try client.renameGuildApplicationCommand(application_id, guild_id, command_id, "guild-pong");
_ = try client.setGuildApplicationCommandDescription(application_id, guild_id, command_id, "Guild command");
_ = try client.removeGuildApplicationCommand(application_id, guild_id, command_id);
```

Builder and message payload limits can be checked locally before a REST
round-trip, turning a guaranteed Discord `400` into an allocation-free error:

```zig
try discord.Interactions.ApplicationCommand
    .chatInput("echo", "Echoes text")
    .withOptions(&options)
    .validate();

const row_components = [_]discord.Interactions.Component{
    .{ .button = discord.Interactions.Button.primary("confirm", "Confirm") },
};
const rows = [_]discord.Interactions.Component{
    discord.Interactions.Component.actionRow(&row_components),
};
try discord.Interactions.Component.validateLayout(&rows);

const embed_fields = [_]discord.Types.EmbedField{
    discord.Types.EmbedField.init("Status", "ok"),
};
const embeds = [_]discord.Types.Embed{
    discord.Types.Embed.init().withFields(&embed_fields),
};
try embeds[0].validate();

try discord.Types.CreateMessage.init("ready")
    .withEmbeds(&embeds)
    .withComponents(&rows)
    .validate();
try discord.Types.EditMessage.init()
    .withContent("updated")
    .validate();
```

Application command permissions use Discord's Bearer-token flow:

```zig
const permissions = [_]discord.Interactions.ApplicationCommandPermission{
    discord.Interactions.ApplicationCommandPermission.role(role_id, true),
    discord.Interactions.ApplicationCommandPermission.channel(channel_id, false),
};

_ = try client.editApplicationCommandPermissions(
    "Bearer user-oauth-token",
    application_id,
    guild_id,
    command_id,
    &permissions,
);
_ = try client.fetchGuildApplicationCommandPermissions(
    "Bearer user-oauth-token",
    application_id,
    guild_id,
);
_ = try client.fetchApplicationCommandPermissions(
    "Bearer user-oauth-token",
    application_id,
    guild_id,
    command_id,
);
```

Incoming interaction payloads expose typed option accessors:

```zig
var interaction = try discord.Interactions.parseInteraction(allocator, payload);
defer interaction.deinit();

const data = interaction.data.?;
const text = try data.getString("text");
const target = try data.getSnowflake("target");
```

Small interaction routers can dispatch parsed commands and components by name or `custom_id`:

```zig
const commands = [_]discord.Interactions.CommandRoute{
    .{ .name = "echo", .handler = discord.Interactions.parsedHandler(&state, State.onEcho) },
};
const components = [_]discord.Interactions.ComponentRoute{
    .{ .custom_id = "confirm", .handler = discord.Interactions.parsedHandler(&state, State.onConfirm) },
};
const router = discord.Interactions.InteractionRouter{
    .commands = &commands,
    .components = &components,
};

_ = try router.dispatch(&interaction);
```

Autocomplete responses reuse the same command choice model:

```zig
const suggestions = [_]discord.Interactions.CommandChoice{
    discord.Interactions.CommandChoice.string("Public", "public"),
    discord.Interactions.CommandChoice.string("Private", "private"),
};

_ = try client.createInteractionResponse(
    interaction_id,
    token,
    discord.Interactions.InteractionResponse.autocomplete(&suggestions),
);
_ = try client.autocompleteInteraction(interaction_id, token, &suggestions);

_ = try client.replyInteraction(
    interaction_id,
    token,
    discord.Interactions.InteractionResponse.message("Done").ephemeralState(true),
);
_ = try client.deferInteractionReply(interaction_id, token, true);
_ = try client.deferInteractionUpdate(interaction_id, token);
_ = try client.updateInteractionMessage(
    interaction_id,
    token,
    discord.Interactions.InteractionResponse.updateMessage("Updated"),
);
```

Message components and modal responses are built with the same streaming JSON model:

```zig
const buttons = [_]discord.Interactions.Component{
    .{ .button = discord.Interactions.Button.success("confirm", "Confirm") },
    .{ .button = discord.Interactions.Button.danger("cancel", "Cancel") },
};
const rows = [_]discord.Interactions.Component{
    discord.Interactions.Component.actionRow(&buttons),
};

_ = try client.createInteractionResponse(
    interaction_id,
    token,
    discord.Interactions.InteractionResponse.message("Choose an action").withComponents(&rows),
);

const visibility_options = [_]discord.Interactions.SelectOption{
    discord.Interactions.SelectOption.init("Public", "public").withDescription("Visible to everyone"),
    discord.Interactions.SelectOption.init("Private", "private").defaultState(true),
};
const visibility_select = [_]discord.Interactions.Component{
    .{ .string_select = discord.Interactions.StringSelect.init("visibility", &visibility_options) },
};
const visibility_rows = [_]discord.Interactions.Component{
    discord.Interactions.Component.actionRow(&visibility_select),
};
_ = try client.updateInteractionMessage(
    interaction_id,
    token,
    discord.Interactions.InteractionResponse.updateMessage("Pick visibility").withComponents(&visibility_rows),
);

const name_input = [_]discord.Interactions.Component{
    .{ .text_input = discord.Interactions.TextInput.short("name", "Name") },
};
const modal_rows = [_]discord.Interactions.Component{
    discord.Interactions.Component.actionRow(&name_input),
};
_ = try client.showModal(
    interaction_id,
    token,
    discord.Interactions.InteractionResponse.modal("profile", "Edit profile", &modal_rows),
);

_ = try client.fetchOriginalInteractionResponse(application_id, token);
_ = try client.editOriginalInteractionResponse(application_id, token, discord.Types.EditMessage.init().withContent("Updated"));
_ = try client.createFollowupMessage(application_id, token, discord.Types.ExecuteWebhook.init("Follow-up"));
_ = try client.createFollowupMessageWithContent(application_id, token, "Follow-up");
_ = try client.fetchFollowupMessage(application_id, token, followup_message_id);
_ = try client.deleteFollowupMessage(application_id, token, followup_message_id);
_ = try client.fetchInteractionReply(token);
_ = try client.editInteractionReply(token, discord.Types.EditMessage.init().withContent("Updated"));
_ = try client.followUpInteraction(token, discord.Types.ExecuteWebhook.init("Follow-up"));
_ = try client.followUpInteractionWithContent(token, "Follow-up");
_ = try client.fetchFollowUpInteraction(token, followup_message_id);
_ = try client.editFollowUpInteraction(token, followup_message_id, discord.Types.EditMessage.init().withContent("Edited follow-up"));
_ = try client.deleteFollowUpInteraction(token, followup_message_id);
_ = try client.deleteInteractionReply(token);
```

Component and modal submit payloads expose `component_data`, including selected values and text input values:

```zig
var interaction = try discord.Interactions.parseInteraction(allocator, payload);
defer interaction.deinit();

const value = interaction.component_data.?.find("name").?.firstValue().?;
```

## Components V2

Components V2 lets a message be built entirely from layout components (text
displays, sections, media galleries, files, separators, and containers) instead
of plain content. Set the components-v2 flag and validate the layout before
sending:

```zig
const headings = [_]discord.Interactions.TextDisplay{
    discord.Interactions.TextDisplay.init("Ships with batteries included."),
};
const shots = [_]discord.Interactions.MediaGalleryItem{
    discord.Interactions.MediaGalleryItem.init("https://cdn.example/shot.png"),
};
const layout = [_]discord.Interactions.Component{
    .{ .text_display = discord.Interactions.TextDisplay.init("# Changelog") },
    .{ .section = discord.Interactions.Section.withThumbnail(
        &headings,
        discord.Interactions.Thumbnail.init("https://cdn.example/icon.png"),
    ) },
    .{ .media_gallery = discord.Interactions.MediaGallery.init(&shots) },
    .{ .separator = discord.Interactions.Separator.init() },
};
const body = [_]discord.Interactions.Component{
    .{ .container = discord.Interactions.Container.init(&layout).withAccentColor(0x5865F2) },
};
try discord.Interactions.Component.validateLayout(&body);
_ = try client.send(channel_id, discord.Types.CreateMessage.init("")
    .withFlags(discord.Types.MessageFlags.is_components_v2)
    .withComponents(&body));
```

## Collections

`discord.Collection(K, V)` is an insertion-ordered map with the functional
helpers a Discord.js `Collection` provides:

```zig
var members = discord.Collection(u64, []const u8).init(allocator);
defer members.deinit();
try members.set(1, "ada");
try members.set(2, "linus");

_ = members.get(1);
_ = members.first();
_ = members.size();
var bots = try members.filter(allocator, {}, isBot);
defer bots.deinit();
```

## Markdown formatting

Markdown helpers return caller-owned strings, matching the mention builders:

```zig
const title = try discord.Formatters.heading(allocator, 1, "Welcome");
defer allocator.free(title);
const link = try discord.Formatters.hyperlink(allocator, "docs", "https://discord.com/developers");
defer allocator.free(link);
const command = try discord.Formatters.slashCommandMention(allocator, "ping", command_id);
defer allocator.free(command);
```

## Sharding

The shard manager parses the `GET /gateway/bot` payload and coordinates per-shard
lifecycle state and guild routing:

```zig
var info = try discord.Sharding.GatewayBotInfo.parse(allocator, gateway_bot_json);
defer info.deinit(allocator);

var shards = try discord.Sharding.ShardManager.initFromGatewayBot(allocator, info);
defer shards.deinit();

const shard_id = try shards.shardIdForGuild(guild_id);
try shards.setState(shard_id, .ready);
_ = shards.allReady();
```

## Voice gateway

The voice gateway protocol layer builds and parses control-plane payloads. The
audio media plane (Opus + libsodium + UDP) requires external native dependencies
and is intentionally left to a separate integration:

```zig
var identify = std.Io.Writer.Allocating.init(allocator);
defer identify.deinit();
try discord.Voice.writeIdentify(server_id, user_id, "session-id", "voice-token", &identify.writer);

const offered = [_][]const u8{"aead_aes256_gcm_rtpsize"};
const mode = discord.Voice.EncryptionMode.preferredMode(&offered);
```

## Status

This is a dependency-light Zig foundation for common Discord.js bot workloads rather than a one-to-one class-model port. REST, Gateway, interactions, interaction router registries, command registries/modules/manifests/annotations, components, cache updates, validation helpers, forum thread starters, group DM recipients, webhook multipart sends, richer collections, subscription/rate-limit events, Discord.js-style builder aliases, template/webhook link helpers, expanded CDN asset helpers, voice gateway bootstrap/control-plane helpers, encrypted RTP receive helpers, SSRC-to-user receive buffering, Opus frame validation, PCM mixing, pluggable Opus codec adapters, owned encoded-Opus resources, pre-encoded Opus audio player packetization, shard identify/cluster/latency/process-spec/supervisor/IPC router/broadcast helpers, and emoji/premium component builders are covered for practical bot usage; bundled native Opus codecs, advanced process-manager clustering, decorators, and exhaustive framework-style Discord.js class parity stay outside the core boundary. See `STATUS.md` and `DISCORDJS_COMPARISON.md` for the current coverage map.
