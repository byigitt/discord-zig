# discord.zig vs Discord.js Coverage

This document compares the current `discord.zig` scope with the core Discord.js surface. It is meant as a wrap-up inventory: what is already strong enough for a basic bot, what is partial, and what should remain future work.

## Summary

`discord.zig` already covers the core pieces needed for a practical bot:

- REST routes and high-level client wrappers for common Discord resources.
- Gateway session, runner, runtime adapters, dispatch parsing, and event helpers.
- Message create/edit/delete/reply/reaction/thread/pin flows.
- Slash command create/edit/delete/sync helpers and interaction responses.
- Component, modal, select, button, command option, and autocomplete builders.
- In-memory cache for common gateway models.
- Mentions, embeds, assets, permissions, intents, links, collectors, webhooks, and many guild/channel/member helpers.

The remaining gap is not a single broken feature; it is breadth. Discord.js is a mature full ecosystem with a very large object model, managers, sharding abstractions, voice ecosystem integrations, and extensive resource coverage. `discord.zig` is currently a dependency-light bot core with broad REST/Gateway foundations.

## Coverage Matrix

| Discord.js area | Current discord.zig coverage | Status | Remaining delta |
| --- | --- | --- | --- |
| Client lifecycle | `Client`, `initHttp`, `login`, gateway runner/runtime, cleanup aliases | Strong | Platform-specific shutdown hooks and more production lifecycle polish |
| Gateway connect/resume/heartbeat | Session, runner, heartbeat scheduling, reconnect, invalid-session handling | Strong | More long-running integration tests against real gateway behavior |
| Event handling | Typed raw dispatcher, persistent and one-shot listeners, filtered interaction helpers | Strong | Higher-level typed event payload wrappers for every Discord resource |
| REST routing | API v10 constants, route builders, bucket keys, injectable transport | Strong | Continued endpoint expansion as Discord API grows |
| Messages | Send/edit/delete/reply/forward/fetch/list/bulk delete, reactions, pins, polls, files | Strong | More exhaustive model fields and edge-case validation |
| Embeds | Streaming JSON builder, field/media/footer/author helpers, single-field helper, field-count + per-field + total character-length validation, Discord `Colors` palette | Strong | Richer cross-embed (per-message) aggregate validation |
| Allowed mentions | Parse policies, allowlists, single user/role helpers, replied-user helpers, id-count and parse/allowlist conflict validation | Strong | — |
| Components | Buttons, select menus, text inputs, action rows, modals, Components V2 (text display, section, thumbnail, media gallery, file, separator, container), interaction responses, layout + string-length + count validation | Strong | Newer component variants as Discord adds them |
| Slash commands | Global/guild command CRUD, bulk overwrite, edit/delete aliases, option/choice builders, name/description/option/choice count and length validation | Strong | Full parity with every command metadata field as Discord evolves |
| Command metadata | Localizations (with typed `Locale` + `Localization.of`), default member permissions, DM permission, NSFW metadata, install/integration types, interaction contexts | Strong | — |
| Interactions | Replies, deferred replies/updates, message updates, autocomplete (with focused-option access), modals, follow-ups, context-menu target_id, and typed resolved user/role/channel/member/attachment/message views | Strong | — |
| Interaction router | Command, autocomplete, component, modal dispatch by name/custom ID, exact + prefix custom-id matching, pre-dispatch middleware pipeline, per-route guards, unmatched-interaction fallback | Strong | — |
| Cache | Users, guilds, channels, threads, members, roles, emojis, stickers, events, invites, presences, voice states, messages, message-count + age-based sweep scheduling | Strong | Persistence/serialization hooks |
| Guild management | Guild fetch/edit, bans, members, roles, emojis, stickers, scheduled events, stage, soundboard, templates, onboarding | Broad | Exhaustive field coverage for every lower-priority resource |
| Channels/threads | Fetch/create/edit, permissions, positions, forums/media tags, threads and members, channel-type guards (isThread/isVoiceBased/isTextBased/isDMBased/isThreadOnly/isGuildBased) | Broad | Higher-level per-channel manager objects |
| Webhooks | Channel/guild webhook management, token webhooks, execute/edit/delete messages, thread_name forum posts, wait + thread_id execution query options | Broad | — |
| Invites | Channel/guild invite helpers, optioned fetch, follow aliases, full invite metadata (type, inviter, target type/user/application, approximate counts, expiry, uses/max_uses/max_age, temporary, created_at, scheduled event) | Strong | — |
| OAuth2/application | Current app/auth/token helpers, role connection metadata, SKUs, entitlements, application team/team-member modeling | Broad | — |
| Permissions/intents | Current bits, aliases, bitset all/any/missing, overwrite resolution, flag name<->bit mapping, name streaming, chainable `Set` wrapper | Strong | — |
| Assets/CDN | User/guild/application/member/role/emoji/sticker URL helpers, image size/format validation, nearest-valid-size, animated-hash and dynamic-format helpers | Strong | — |
| Mentions/links | Mention scan/parse/format, message/channel/invite links, OAuth URL, markdown formatters (bold/italic/code/heading/quote/lists/escape/...), slash-command navigation mentions | Strong | — |
| Collectors | Message and interaction collectors with limits and last ID tracking | Usable | Async/event-loop integration patterns beyond the current lightweight model |
| Voice | Voice state update helpers, gateway event models, voice gateway protocol layer (opcodes, payload builders/parsers, encryption-mode negotiation, connection bootstrap), UDP IP-discovery request/response framing, and the media-plane RTP framing + AEAD packet encrypt/decrypt (`aead_aes256_gcm_rtpsize`, `aead_xchacha20_poly1305_rtpsize`) via `std.crypto` | Broad (control plane + packet crypto) | Opus audio codec needs an external native lib (as in Discord.js); the UDP socket is the caller's |
| Sharding | Gateway bot metadata parsing, shard route helpers, shard-manager coordination (per-shard state, guild routing, rate-limit buckets, readiness) | Broad | Full multi-process orchestration and supervision |
| Managers/collections | Client wrappers, cache list aliases, generic ordered `Collection(K, V)` with functional helpers, and cache-backed `collectGuilds`/`collectChannels`/`collectUsers`/`collectRoles` snapshot collections (Discord.js `.cache`-style views) | Broad | Per-resource manager classes are intentionally not mirrored one-to-one |
| Type model breadth | Many core models parsed and cached, channel-type guards, message type and audit-log-event enums, user/application/member flag bitfields, Discord color palette | Broad but incomplete | Full Discord API model parity remains open-ended |
| Developer ergonomics | Streaming builders, aliases, status docs, runnable `ping_bot` (REST) and `slash_bot` (slash command + interaction router) examples, plus `e2e_check` live REST+gateway smoke test | Good | More cookbook-style recipes |

## What Is Done Enough For Basic Bots

- Ping/reply style bots.
- Slash command registration and handling.
- Message create/edit/delete flows.
- Component and modal interactions.
- Guild/member/role/channel administration basics.
- Webhook execution and webhook message management.
- Gateway event dispatch with an in-memory cache.
- REST tests through injectable transports.

## What Should Stay Future Work

- Full Discord.js manager architecture. Zig code should stay simpler and avoid copying JavaScript object-heavy patterns when slices, structs, and explicit allocators are clearer.
- Voice audio **codec** (Opus encode/decode). The voice gateway protocol, IP discovery, RTP framing, AEAD packet encryption, and the send-loop counter are implemented dependency-light; only the Opus codec needs an external native lib (as Discord.js delegates to `@discordjs/opus`), plus the live UDP socket loop.
- Complete resource parity for every low-priority Discord endpoint. The current architecture can grow endpoint-by-endpoint.
- Production process orchestration for large bot fleets: full shard manager, process supervision, metrics exporters, and persistent cache storage.

## Current Wrap-Up Checklist

- Builder validation helpers are complete: embed field count + per-field/total character length, allowed-mention limits/conflicts, component layout + string lengths + select ranges, and command name/description/option/choice trees.
- Keep `STATUS.md` as the short capability index.
- Keep this file as the comparison and remaining-work inventory.
- Before considering the current foundation wrapped, run:

```sh
zig build test
zig build
run the repository marker scan
rm -rf .zig-cache zig-out
```

## Recommendation

Treat `discord.zig` as a strong basic-bot foundation rather than a complete Discord.js clone. The best next milestone is a tagged foundation release after validation passes, with future work handled as focused endpoint/model increments.
