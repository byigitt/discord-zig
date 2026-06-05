# discord.zig Status

`discord.zig` is ready as a dependency-light Zig foundation for common Discord bot workloads: REST calls, Gateway sessions, event dispatch, cache-backed client state, slash commands, interactions, components, collectors, and message workflows.

It is not a one-to-one Discord.js port. The API intentionally uses Zig ownership rules, explicit allocators, slices, and streaming JSON writers instead of class-heavy builders.

## Covered surface

- REST client with injectable transports and live `std.http.Client` transport
- Gateway session, runner, blocking runtime, nonblocking runtime, reconnect handling, heartbeat tracking, presence updates, shard identify-bucket helpers, shard worker/cluster process-spec orchestration, native shard process supervisor spawn/wait/kill helpers, restart classification, shard cluster plans, shard IPC payload/broadcast helpers, and shard IPC routers
- Typed event dispatcher with persistent, one-shot, filtered, and clearable handlers, including Discord.js v14 subscription and rate-limit dispatches
- Message create, fetch, list, edit, delete, reply, forward, reaction, poll, pin, text/thread/forum thread, group DM recipient, webhook multipart, and multipart upload helpers
- Slash command create/edit/delete/bulk-sync helpers, command option builders, localizations, install contexts, permission payloads, Discord.js-style builder aliases, application-command registries that pair syncable definitions with routes, command modules, command manifests, declarative command annotations, and annotation manifests
- Interaction reply, defer, update, autocomplete, modal, original-response, follow-up helpers, static routers, and incrementally-built command/component/modal router registries
- Components including action rows, buttons with emoji/link/premium styles, selects with option emoji, text inputs, modals, and Components V2 layout pieces
- Voice gateway control-plane helpers for join/leave voice-state commands, v8 URLs, DAVE-capable identify payloads, DAVE opcodes/binary websocket frames, v8 heartbeat payloads/ACKs, voice-server update parsing, VOICE_STATE_UPDATE/VOICE_SERVER_UPDATE bootstrap correlation, pluggable Opus codec adapter interface, Opus frame TOC validation, owned encoded-Opus resources from PCM through pluggable codecs, PCM saturation mixer, pre-encoded Opus audio resource/player packetization, encrypted RTP packet receiving helpers, and SSRC-to-user receive routing
- Local validation for application commands, options, choices, components, embeds, allowed mentions, and message payload limits
- Cache hydration and updates for current user/application, guilds, channels, messages, members, roles, emojis, stickers, presences, voice states, invites, stage instances, scheduled events, and common dispatches
- Discord.js-like conveniences for common client calls, event registration, richer collections, formatter aliases, template/webhook links, mention aliases, expanded asset/CDN URL helpers, and shard latency/readiness aggregation
- Offline examples plus a live `examples/e2e-check.zig` smoke test for token-backed API checks

## Current boundary

The library is a practical replacement for basic to moderately complex Discord.js bot foundations. It does not try to mirror every Discord.js abstraction or cover every low-priority Discord resource model. Bundled native Opus codecs, advanced process-manager clustering policies, decorators, and platform-specific shutdown integration remain separate subsystems rather than hidden client behavior.

## Source layout

`src/discord.zig` remains the public module root and compatibility export surface. Implementation code is organized by domain under `src/core`, `src/models`, `src/rest`, `src/gateway`, `src/interactions`, `src/client`, and `src/voice` so contributors can navigate to the subsystem they are changing without scanning a flat source directory. Each Zig source file is kept below 1000 lines; file and subdirectory names use short kebab-case path segments with at most two words.

## Validation commands

```sh
zig build test
zig build
```

Both commands are expected to pass before publishing or depending on a new commit.
