# Discord.js Comparison

This project targets the common bot-development surface people usually reach for in Discord.js, but it does so with Zig-native APIs: explicit allocator ownership, value builders, caller-owned slices, injectable transports, and streaming JSON.

## Covered for common bot usage

| Area | discord.zig status |
| --- | --- |
| Client setup | `discord.Client.init`, `initHttp`, owned HTTP transport, cache policy, Discord.js-style partial option masks, current user/application state, readiness and gateway metrics |
| Login/runtime | `discord.GatewayRuntime.login`, blocking runtime, nonblocking runtime, reconnect backoff, resumable Gateway sessions, shard identify bucket grouping, shard cluster plans, shard state counts, shard latency aggregation, worker/cluster process spec generation, shard IPC payload/router/broadcast helpers, and native shard spawn/wait/kill supervision with restart-policy classification |
| Gateway events | Typed dispatcher for Discord.js v14 gateway dispatches including message, guild, channel, member, interaction, voice-state/server/effect, presence, poll, invite, webhook, moderation, entitlement, subscription, soundboard, role, emoji, sticker, scheduled-event, stage, thread, rate-limit, and runtime events, plus Discord.js-style `Events` aliases and string lookup helpers for matching events |
| REST | Route builders and helpers for messages, channels, guild lifecycle/template creation/deletion, group DM recipients, webhook multipart execution, guilds, members, roles, emojis, stickers, webhooks, invites, scheduled events, stage instances, auto moderation, applications, OAuth2, users, Gateway metadata, and related resources |
| Messages | Send/edit/reply/forward/delete/bulk-delete, reactions, typing, pins, polls, text threads, forum/media thread starter payloads, embeds, attachments, stickers, allowed mentions, components, webhook sends with attachments, and message payload validation |
| Slash commands | Command builders, option/choice builders, localizations, install contexts, default permissions, command CRUD, bulk sync, permission payloads, Discord.js-style builder aliases, command registries that combine syncable definitions with interaction routes, command modules, command manifests, declarative command annotations, and annotation manifests |
| Interactions | Replies, defers, updates, autocomplete, modals, follow-ups, parsed interaction data, resolved entity lookup, command/component/modal routing, middleware, fallback handlers, and incremental router-builder registration |
| Components | Buttons with emoji/link/premium styles, select menus with option emoji, text inputs, action rows, modals, single-item helpers, validation, Components V2 layout components, and Discord.js-style builder aliases |
| Collections | Ordered `discord.Collection(K, V)` with lookup, delete, iteration, ensure, clone, concat, equals, difference, intersection, symmetric difference, snapshots, sweep, find, filter, map, and reduce helpers |
| Intents, partials, and permissions | Current bit constants, Discord.js-compatible aliases, aggregate helpers, overwrite resolution, permission sets, partial masks, and name mapping |
| Utilities | Formatters, timestamp/hide-link helpers, targeted markdown escape helpers, mention aliases, guild-template/webhook links, OAuth authorization URLs, expanded asset/CDN URL helpers, snowflakes, and JSON escaping |
| Voice control/media | Client join/leave voice-state commands, voice gateway v8 URL/identify/heartbeat helpers, DAVE identify option/opcodes/binary frame helpers, heartbeat ACK parsing, voice-server update parser, websocket URL normalization, bootstrap correlation for the gateway VOICE_STATE_UPDATE + VOICE_SERVER_UPDATE pair, encrypted RTP packet receiving, SSRC-to-user receive routing, per-user receive buffering, pluggable Opus codec adapter interface, Opus frame TOC validation, owned encoded-Opus resources from PCM through pluggable codecs, PCM saturation mixing, and dependency-light pre-encoded Opus resource/player packetization |
| Caching | Policy-controlled in-memory cache with current identity hydration, guild/channel/message/member and related object updates, stats, membership checks, and explicit eviction |
| Examples | Offline ping, slash-command, rich-message examples; live echo bot; live e2e API check |

## Intentional differences from Discord.js

- No implicit global client state. Allocators, transports, and cache policy are explicit.
- Builders are plain values. Slice fields are caller-owned, so the API avoids hidden allocations and object graphs.
- REST methods return raw `Rest.Response` values; callers decide when to parse and when to free response bodies.
- Gateway and runtime layers are separable, making the protocol state machine testable without a socket.
- Cache behavior is configurable rather than always-on for every model.

## Still outside the core replacement boundary

- Bundled native Opus codec equivalent to Discord.js voice adapters backed by native codecs
- Advanced process-manager clustering policies equivalent to every Discord.js `ShardingManager` integration
- Decorators and file-system conventions

## Practical replacement guidance

Use `discord.zig` when the bot needs a fast Zig foundation for REST, Gateway, slash commands, interactions, components, caching, and common event handling. Keep Discord.js or a dedicated subsystem when the primary requirement is mature voice/media behavior, Node ecosystem plugins, or process-manager abstractions.
