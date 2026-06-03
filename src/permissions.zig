const std = @import("std");

pub const Bit = u64;

pub const create_instant_invite: Bit = 1 << 0;
pub const kick_members: Bit = 1 << 1;
pub const ban_members: Bit = 1 << 2;
pub const administrator: Bit = 1 << 3;
pub const manage_channels: Bit = 1 << 4;
pub const manage_guild: Bit = 1 << 5;
pub const add_reactions: Bit = 1 << 6;
pub const view_audit_log: Bit = 1 << 7;
pub const priority_speaker: Bit = 1 << 8;
pub const stream: Bit = 1 << 9;
pub const view_channel: Bit = 1 << 10;
pub const send_messages: Bit = 1 << 11;
pub const send_tts_messages: Bit = 1 << 12;
pub const manage_messages: Bit = 1 << 13;
pub const embed_links: Bit = 1 << 14;
pub const attach_files: Bit = 1 << 15;
pub const read_message_history: Bit = 1 << 16;
pub const mention_everyone: Bit = 1 << 17;
pub const use_external_emojis: Bit = 1 << 18;
pub const view_guild_insights: Bit = 1 << 19;
pub const connect: Bit = 1 << 20;
pub const speak: Bit = 1 << 21;
pub const mute_members: Bit = 1 << 22;
pub const deafen_members: Bit = 1 << 23;
pub const move_members: Bit = 1 << 24;
pub const use_vad: Bit = 1 << 25;
pub const change_nickname: Bit = 1 << 26;
pub const manage_nicknames: Bit = 1 << 27;
pub const manage_roles: Bit = 1 << 28;
pub const manage_webhooks: Bit = 1 << 29;
pub const manage_guild_expressions: Bit = 1 << 30;
pub const use_application_commands: Bit = 1 << 31;
pub const request_to_speak: Bit = 1 << 32;
pub const manage_events: Bit = 1 << 33;
pub const manage_threads: Bit = 1 << 34;
pub const create_public_threads: Bit = 1 << 35;
pub const create_private_threads: Bit = 1 << 36;
pub const use_external_stickers: Bit = 1 << 37;
pub const send_messages_in_threads: Bit = 1 << 38;
pub const use_embedded_activities: Bit = 1 << 39;
pub const moderate_members: Bit = 1 << 40;
pub const view_creator_monetization_analytics: Bit = 1 << 41;
pub const use_soundboard: Bit = 1 << 42;
pub const create_guild_expressions: Bit = 1 << 43;
pub const create_events: Bit = 1 << 44;
pub const use_external_sounds: Bit = 1 << 45;
pub const send_voice_messages: Bit = 1 << 46;
pub const set_voice_channel_status: Bit = 1 << 48;
pub const send_polls: Bit = 1 << 49;
pub const use_external_apps: Bit = 1 << 50;
pub const pin_messages: Bit = 1 << 51;
pub const bypass_slowmode: Bit = 1 << 52;

pub fn has(mask: Bit, permission: Bit) bool {
    return (mask & administrator) == administrator or (mask & permission) == permission;
}

pub fn hasAll(mask: Bit, permissions: Bit) bool {
    return (mask & administrator) == administrator or (mask & permissions) == permissions;
}

pub fn hasAny(mask: Bit, permissions: Bit) bool {
    return (mask & administrator) == administrator or (mask & permissions) != 0;
}

pub fn missing(mask: Bit, permissions: Bit) Bit {
    if ((mask & administrator) == administrator) return 0;
    return permissions & ~mask;
}

pub fn add(mask: Bit, permission: Bit) Bit {
    return mask | permission;
}

pub fn remove(mask: Bit, permission: Bit) Bit {
    return mask & ~permission;
}

pub fn all(permissions: []const Bit) Bit {
    var mask: Bit = 0;
    for (permissions) |permission| mask |= permission;
    return mask;
}

const Permissions = @This();

pub const PermissionInfo = struct { bit: Bit, name: []const u8 };

/// All known permission bits paired with their Discord.js flag names, in bit
/// order. Used by the name/lookup helpers below.
pub const all_permissions = [_]PermissionInfo{
    .{ .bit = create_instant_invite, .name = "CreateInstantInvite" },
    .{ .bit = kick_members, .name = "KickMembers" },
    .{ .bit = ban_members, .name = "BanMembers" },
    .{ .bit = administrator, .name = "Administrator" },
    .{ .bit = manage_channels, .name = "ManageChannels" },
    .{ .bit = manage_guild, .name = "ManageGuild" },
    .{ .bit = add_reactions, .name = "AddReactions" },
    .{ .bit = view_audit_log, .name = "ViewAuditLog" },
    .{ .bit = priority_speaker, .name = "PrioritySpeaker" },
    .{ .bit = stream, .name = "Stream" },
    .{ .bit = view_channel, .name = "ViewChannel" },
    .{ .bit = send_messages, .name = "SendMessages" },
    .{ .bit = send_tts_messages, .name = "SendTTSMessages" },
    .{ .bit = manage_messages, .name = "ManageMessages" },
    .{ .bit = embed_links, .name = "EmbedLinks" },
    .{ .bit = attach_files, .name = "AttachFiles" },
    .{ .bit = read_message_history, .name = "ReadMessageHistory" },
    .{ .bit = mention_everyone, .name = "MentionEveryone" },
    .{ .bit = use_external_emojis, .name = "UseExternalEmojis" },
    .{ .bit = view_guild_insights, .name = "ViewGuildInsights" },
    .{ .bit = connect, .name = "Connect" },
    .{ .bit = speak, .name = "Speak" },
    .{ .bit = mute_members, .name = "MuteMembers" },
    .{ .bit = deafen_members, .name = "DeafenMembers" },
    .{ .bit = move_members, .name = "MoveMembers" },
    .{ .bit = use_vad, .name = "UseVAD" },
    .{ .bit = change_nickname, .name = "ChangeNickname" },
    .{ .bit = manage_nicknames, .name = "ManageNicknames" },
    .{ .bit = manage_roles, .name = "ManageRoles" },
    .{ .bit = manage_webhooks, .name = "ManageWebhooks" },
    .{ .bit = manage_guild_expressions, .name = "ManageGuildExpressions" },
    .{ .bit = use_application_commands, .name = "UseApplicationCommands" },
    .{ .bit = request_to_speak, .name = "RequestToSpeak" },
    .{ .bit = manage_events, .name = "ManageEvents" },
    .{ .bit = manage_threads, .name = "ManageThreads" },
    .{ .bit = create_public_threads, .name = "CreatePublicThreads" },
    .{ .bit = create_private_threads, .name = "CreatePrivateThreads" },
    .{ .bit = use_external_stickers, .name = "UseExternalStickers" },
    .{ .bit = send_messages_in_threads, .name = "SendMessagesInThreads" },
    .{ .bit = use_embedded_activities, .name = "UseEmbeddedActivities" },
    .{ .bit = moderate_members, .name = "ModerateMembers" },
    .{ .bit = view_creator_monetization_analytics, .name = "ViewCreatorMonetizationAnalytics" },
    .{ .bit = use_soundboard, .name = "UseSoundboard" },
    .{ .bit = create_guild_expressions, .name = "CreateGuildExpressions" },
    .{ .bit = create_events, .name = "CreateEvents" },
    .{ .bit = use_external_sounds, .name = "UseExternalSounds" },
    .{ .bit = send_voice_messages, .name = "SendVoiceMessages" },
    .{ .bit = set_voice_channel_status, .name = "SetVoiceChannelStatus" },
    .{ .bit = send_polls, .name = "SendPolls" },
    .{ .bit = use_external_apps, .name = "UseExternalApps" },
    .{ .bit = pin_messages, .name = "PinMessages" },
    .{ .bit = bypass_slowmode, .name = "BypassSlowmode" },
};

/// Discord.js flag name for a single permission bit, or null if unknown.
pub fn name(permission: Bit) ?[]const u8 {
    for (all_permissions) |info| {
        if (info.bit == permission) return info.name;
    }
    return null;
}

/// Permission bit for a Discord.js flag name, or null if unrecognized.
pub fn fromName(text: []const u8) ?Bit {
    for (all_permissions) |info| {
        if (std.mem.eql(u8, info.name, text)) return info.bit;
    }
    return null;
}

/// Number of distinct known permissions present in `mask`.
pub fn countNames(mask: Bit) usize {
    var total: usize = 0;
    for (all_permissions) |info| {
        if ((mask & info.bit) == info.bit) total += 1;
    }
    return total;
}

/// Streams the names of the known permissions present in `mask`, joined by
/// `separator`, in bit order. Allocation-free.
pub fn writeNames(mask: Bit, separator: []const u8, writer: anytype) !void {
    var first = true;
    for (all_permissions) |info| {
        if ((mask & info.bit) == info.bit) {
            if (!first) try writer.writeAll(separator);
            try writer.writeAll(info.name);
            first = false;
        }
    }
}

/// Chainable wrapper around a permission bitmask, mirroring the ergonomics of
/// the Discord.js `PermissionsBitField`. Every mutating method returns a new
/// `Set`, so calls compose without aliasing.
pub const Set = struct {
    bits: Bit = 0,

    pub fn init(bits: Bit) Set {
        return .{ .bits = bits };
    }

    pub fn fromList(permissions: []const Bit) Set {
        return .{ .bits = all(permissions) };
    }

    pub fn has(self: Set, permission: Bit) bool {
        return Permissions.has(self.bits, permission);
    }

    pub fn hasAll(self: Set, permissions: Bit) bool {
        return Permissions.hasAll(self.bits, permissions);
    }

    pub fn hasAny(self: Set, permissions: Bit) bool {
        return Permissions.hasAny(self.bits, permissions);
    }

    pub fn missing(self: Set, permissions: Bit) Bit {
        return Permissions.missing(self.bits, permissions);
    }

    pub fn add(self: Set, permission: Bit) Set {
        return .{ .bits = self.bits | permission };
    }

    pub fn remove(self: Set, permission: Bit) Set {
        return .{ .bits = self.bits & ~permission };
    }

    pub fn equals(self: Set, other: Set) bool {
        return self.bits == other.bits;
    }

    pub fn isEmpty(self: Set) bool {
        return self.bits == 0;
    }

    pub fn isAdministrator(self: Set) bool {
        return (self.bits & administrator) == administrator;
    }

    pub fn value(self: Set) Bit {
        return self.bits;
    }

    pub fn writeNames(self: Set, separator: []const u8, writer: anytype) !void {
        return Permissions.writeNames(self.bits, separator, writer);
    }
};

pub const OverwriteType = enum(u8) {
    role = 0,
    member = 1,
};

pub const Overwrite = struct {
    id: u64,
    type: OverwriteType,
    allow: Bit = 0,
    deny: Bit = 0,

    pub fn role(id: u64, allow: Bit, deny: Bit) Overwrite {
        return .{ .id = id, .type = .role, .allow = allow, .deny = deny };
    }

    pub fn member(id: u64, allow: Bit, deny: Bit) Overwrite {
        return .{ .id = id, .type = .member, .allow = allow, .deny = deny };
    }
};

pub const RolePermissions = struct {
    id: u64,
    permissions: Bit,
};

pub fn resolveGuild(role_ids: []const u64, roles: []const RolePermissions) Bit {
    var resolved: Bit = 0;
    for (roles) |role| {
        if (containsRole(role_ids, role.id)) resolved |= role.permissions;
    }
    if ((resolved & administrator) == administrator) return std.math.maxInt(Bit);
    return resolved;
}

pub fn applyOverwrite(base: Bit, overwrite: Overwrite) Bit {
    return (base & ~overwrite.deny) | overwrite.allow;
}

pub fn resolveChannel(
    guild_permissions: Bit,
    guild_id: u64,
    member_id: u64,
    role_ids: []const u64,
    overwrites: []const Overwrite,
) Bit {
    if ((guild_permissions & administrator) == administrator) return guild_permissions;

    var resolved = guild_permissions;

    for (overwrites) |overwrite| {
        if (overwrite.type == .role and overwrite.id == guild_id) {
            resolved = applyOverwrite(resolved, overwrite);
            break;
        }
    }

    var role_allow: Bit = 0;
    var role_deny: Bit = 0;
    for (overwrites) |overwrite| {
        if (overwrite.type != .role or overwrite.id == guild_id) continue;
        if (containsRole(role_ids, overwrite.id)) {
            role_allow |= overwrite.allow;
            role_deny |= overwrite.deny;
        }
    }
    resolved = (resolved & ~role_deny) | role_allow;

    for (overwrites) |overwrite| {
        if (overwrite.type == .member and overwrite.id == member_id) {
            resolved = applyOverwrite(resolved, overwrite);
            break;
        }
    }

    return resolved;
}

fn containsRole(role_ids: []const u64, role_id: u64) bool {
    for (role_ids) |candidate| {
        if (candidate == role_id) return true;
    }
    return false;
}

test "administrator grants all permission checks" {
    try @import("std").testing.expect(has(administrator, manage_messages));
}

test "permission helpers combine and apply overwrites" {
    const base = all(&.{ view_channel, send_messages, read_message_history });
    try std.testing.expect(has(base, send_messages));
    try std.testing.expect(hasAll(base, view_channel | send_messages));
    try std.testing.expect(hasAny(base, manage_messages | send_messages));
    try std.testing.expect(!hasAll(base, manage_messages | send_messages));
    try std.testing.expectEqual(manage_messages, missing(base, manage_messages | send_messages));
    try std.testing.expectEqual(@as(Bit, 0), missing(administrator, manage_messages | send_messages));

    const denied = applyOverwrite(base, Overwrite.role(10, manage_messages, send_messages));
    try std.testing.expect(!has(denied, send_messages));
    try std.testing.expect(has(denied, manage_messages));
}

test "current high permission bits match Discord values" {
    try std.testing.expectEqual(@as(Bit, 1) << 43, create_guild_expressions);
    try std.testing.expectEqual(@as(Bit, 1) << 44, create_events);
    try std.testing.expectEqual(@as(Bit, 1) << 45, use_external_sounds);
    try std.testing.expectEqual(@as(Bit, 1) << 46, send_voice_messages);
    try std.testing.expectEqual(@as(Bit, 1) << 48, set_voice_channel_status);
    try std.testing.expectEqual(@as(Bit, 1) << 49, send_polls);
    try std.testing.expectEqual(@as(Bit, 1) << 50, use_external_apps);
    try std.testing.expectEqual(@as(Bit, 1) << 51, pin_messages);
    try std.testing.expectEqual(@as(Bit, 1) << 52, bypass_slowmode);
}

test "resolve guild permissions from member roles" {
    const member_roles = [_]u64{ 10, 20 };
    const roles = [_]RolePermissions{
        .{ .id = 10, .permissions = view_channel },
        .{ .id = 20, .permissions = send_messages },
        .{ .id = 30, .permissions = manage_messages },
    };

    const resolved = resolveGuild(&member_roles, &roles);
    try std.testing.expect(has(resolved, view_channel));
    try std.testing.expect(has(resolved, send_messages));
    try std.testing.expect(!has(resolved, manage_messages));
}

test "administrator role resolves all permissions" {
    const member_roles = [_]u64{10};
    const roles = [_]RolePermissions{
        .{ .id = 10, .permissions = administrator },
    };

    const resolved = resolveGuild(&member_roles, &roles);
    try std.testing.expectEqual(std.math.maxInt(Bit), resolved);
    try std.testing.expect(has(resolved, manage_messages));
}

test "resolve channel permission overwrites in Discord order" {
    const guild_id: u64 = 1;
    const member_id: u64 = 2;
    const roles = [_]u64{ 10, 11 };
    const overwrites = [_]Overwrite{
        Overwrite.role(guild_id, 0, send_messages),
        Overwrite.role(10, send_messages, 0),
        Overwrite.role(11, 0, attach_files),
        Overwrite.member(member_id, attach_files, manage_messages),
    };

    const resolved = resolveChannel(
        all(&.{ view_channel, send_messages, attach_files, manage_messages }),
        guild_id,
        member_id,
        &roles,
        &overwrites,
    );

    try std.testing.expect(has(resolved, view_channel));
    try std.testing.expect(has(resolved, send_messages));
    try std.testing.expect(has(resolved, attach_files));
    try std.testing.expect(!has(resolved, manage_messages));
}

test "permission name mapping and chainable set" {
    try std.testing.expectEqualStrings("Administrator", name(administrator).?);
    try std.testing.expectEqual(@as(?Bit, manage_messages), fromName("ManageMessages"));
    try std.testing.expect(fromName("DoesNotExist") == null);
    // Bit 1<<47 is not assigned a permission by Discord.
    try std.testing.expect(name(@as(Bit, 1) << 47) == null);

    try std.testing.expectEqual(@as(usize, 2), countNames(view_channel | send_messages));

    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();
    try writeNames(view_channel | send_messages, ", ", &out.writer);
    try std.testing.expectEqualStrings("ViewChannel, SendMessages", out.written());

    const set = Set.fromList(&.{ view_channel, send_messages }).add(embed_links).remove(view_channel);
    try std.testing.expect(set.has(send_messages));
    try std.testing.expect(set.has(embed_links));
    try std.testing.expect(!set.has(view_channel));
    try std.testing.expect(set.hasAll(send_messages | embed_links));
    try std.testing.expect(set.hasAny(view_channel | embed_links));
    try std.testing.expectEqual(view_channel, set.missing(view_channel | send_messages));
    try std.testing.expect(!set.isEmpty());

    // Administrator short-circuits every check.
    const admin = Set.init(administrator);
    try std.testing.expect(admin.has(ban_members));
    try std.testing.expect(admin.isAdministrator());
    try std.testing.expectEqual(@as(Bit, 0), admin.missing(manage_messages | send_messages));
}
