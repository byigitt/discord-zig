pub const Bit = u16;

pub const none: Bit = 0;
pub const user: Bit = 1 << 0;
pub const channel: Bit = 1 << 1;
pub const guild_member: Bit = 1 << 2;
pub const message: Bit = 1 << 3;
pub const reaction: Bit = 1 << 4;
pub const guild_scheduled_event: Bit = 1 << 5;
pub const thread_member: Bit = 1 << 6;
pub const poll: Bit = 1 << 7;
pub const poll_answer: Bit = 1 << 8;
pub const soundboard_sound: Bit = 1 << 9;

pub const User = user;
pub const Channel = channel;
pub const GuildMember = guild_member;
pub const Message = message;
pub const Reaction = reaction;
pub const GuildScheduledEvent = guild_scheduled_event;
pub const ThreadMember = thread_member;
pub const Poll = poll;
pub const PollAnswer = poll_answer;
pub const SoundboardSound = soundboard_sound;

pub fn has(mask: Bit, partial: Bit) bool {
    return (mask & partial) == partial;
}

pub fn hasAll(mask: Bit, partials: Bit) bool {
    return (mask & partials) == partials;
}

pub fn hasAny(mask: Bit, partials: Bit) bool {
    return (mask & partials) != 0;
}

pub fn missing(mask: Bit, partials: Bit) Bit {
    return partials & ~mask;
}

pub fn add(mask: Bit, partial: Bit) Bit {
    return mask | partial;
}

pub fn remove(mask: Bit, partial: Bit) Bit {
    return mask & ~partial;
}

pub fn all() Bit {
    return user |
        channel |
        guild_member |
        message |
        reaction |
        guild_scheduled_event |
        thread_member |
        poll |
        poll_answer |
        soundboard_sound;
}

test "partial masks and Discord.js aliases" {
    const std = @import("std");

    const mask = add(user | message, poll);
    try std.testing.expect(has(mask, user));
    try std.testing.expect(has(mask, User));
    try std.testing.expect(has(mask, Message));
    try std.testing.expect(has(mask, Poll));
    try std.testing.expect(hasAll(mask, user | message));
    try std.testing.expect(hasAny(mask, channel | poll));
    try std.testing.expectEqual(channel, missing(mask, channel | message));
    try std.testing.expect(!has(remove(mask, user), user));

    try std.testing.expectEqual(user, User);
    try std.testing.expectEqual(channel, Channel);
    try std.testing.expectEqual(guild_member, GuildMember);
    try std.testing.expectEqual(guild_scheduled_event, GuildScheduledEvent);
    try std.testing.expectEqual(thread_member, ThreadMember);
    try std.testing.expectEqual(poll_answer, PollAnswer);
    try std.testing.expectEqual(soundboard_sound, SoundboardSound);
    try std.testing.expect(hasAll(all(), user | channel | guild_member | message | reaction));
    try std.testing.expect(hasAll(all(), guild_scheduled_event | thread_member | poll | poll_answer | soundboard_sound));
}
