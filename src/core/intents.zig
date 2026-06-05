pub const Bit = u32;

pub const none: Bit = 0;
pub const guilds: Bit = 1 << 0;
pub const guild_members: Bit = 1 << 1;
pub const guild_moderation: Bit = 1 << 2;
pub const guild_bans: Bit = guild_moderation;
pub const guild_expressions: Bit = 1 << 3;
pub const guild_emojis_and_stickers: Bit = guild_expressions;
pub const guild_integrations: Bit = 1 << 4;
pub const guild_webhooks: Bit = 1 << 5;
pub const guild_invites: Bit = 1 << 6;
pub const guild_voice_states: Bit = 1 << 7;
pub const guild_presences: Bit = 1 << 8;
pub const guild_messages: Bit = 1 << 9;
pub const guild_message_reactions: Bit = 1 << 10;
pub const guild_message_typing: Bit = 1 << 11;
pub const direct_messages: Bit = 1 << 12;
pub const direct_message_reactions: Bit = 1 << 13;
pub const direct_message_typing: Bit = 1 << 14;
pub const message_content: Bit = 1 << 15;
pub const guild_scheduled_events: Bit = 1 << 16;
pub const auto_moderation_configuration: Bit = 1 << 20;
pub const auto_moderation_execution: Bit = 1 << 21;
pub const guild_message_polls: Bit = 1 << 24;
pub const direct_message_polls: Bit = 1 << 25;

pub fn has(mask: Bit, bit: Bit) bool {
    return (mask & bit) == bit;
}

pub fn hasAll(mask: Bit, bits: Bit) bool {
    return (mask & bits) == bits;
}

pub fn hasAny(mask: Bit, bits: Bit) bool {
    return (mask & bits) != 0;
}

pub fn missing(mask: Bit, bits: Bit) Bit {
    return bits & ~mask;
}

pub fn add(mask: Bit, bit: Bit) Bit {
    return mask | bit;
}

pub fn remove(mask: Bit, bit: Bit) Bit {
    return mask & ~bit;
}

pub fn defaultNonPrivileged() Bit {
    return guilds |
        guild_moderation |
        guild_expressions |
        guild_integrations |
        guild_webhooks |
        guild_invites |
        guild_voice_states |
        guild_messages |
        guild_message_reactions |
        guild_message_typing |
        direct_messages |
        direct_message_reactions |
        direct_message_typing |
        guild_scheduled_events |
        auto_moderation_configuration |
        auto_moderation_execution |
        guild_message_polls |
        direct_message_polls;
}

pub fn privileged() Bit {
    return guild_members |
        guild_presences |
        message_content;
}

pub fn all() Bit {
    return defaultNonPrivileged() | privileged();
}

test "intent masks" {
    const mask = add(guilds, guild_messages);
    try @import("std").testing.expect(has(mask, guilds));
    try @import("std").testing.expect(has(mask, guild_messages));
    try @import("std").testing.expect(hasAll(mask, guilds | guild_messages));
    try @import("std").testing.expect(hasAny(mask, guild_members | guild_messages));
    try @import("std").testing.expect(!hasAll(mask, guild_members | guild_messages));
    try @import("std").testing.expectEqual(guild_members, missing(mask, guild_members | guild_messages));
    try @import("std").testing.expect(!has(remove(mask, guilds), guilds));
}

test "intent aliases and aggregate helpers match Discord values" {
    const std = @import("std");

    try std.testing.expectEqual(guild_moderation, guild_bans);
    try std.testing.expectEqual(guild_expressions, guild_emojis_and_stickers);
    try std.testing.expectEqual(@as(Bit, 1) << 20, auto_moderation_configuration);
    try std.testing.expectEqual(@as(Bit, 1) << 21, auto_moderation_execution);
    try std.testing.expectEqual(@as(Bit, 1) << 24, guild_message_polls);
    try std.testing.expectEqual(@as(Bit, 1) << 25, direct_message_polls);
    try std.testing.expectEqual(guild_members | guild_presences | message_content, privileged());
    try std.testing.expect(!has(defaultNonPrivileged(), guild_members));
    try std.testing.expect(!has(defaultNonPrivileged(), guild_presences));
    try std.testing.expect(!has(defaultNonPrivileged(), message_content));
    try std.testing.expect(has(all(), guild_members));
    try std.testing.expect(has(all(), guild_message_polls));
}
