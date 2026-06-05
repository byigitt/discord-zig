const std = @import("std");
const Api = @import("../core/api.zig");
const Json = @import("../core/json.zig");
const Snowflake = @import("../core/snowflake.zig").Snowflake;

pub const Opcode = enum(u8) {
    dispatch = 0,
    heartbeat = 1,
    identify = 2,
    presence_update = 3,
    voice_state_update = 4,
    @"resume" = 6,
    reconnect = 7,
    request_guild_members = 8,
    invalid_session = 9,
    hello = 10,
    heartbeat_ack = 11,
    request_soundboard_sounds = 31,
    request_channel_info = 43,
};

pub const CloseCode = enum(u16) {
    unknown_error = 4000,
    unknown_opcode = 4001,
    decode_error = 4002,
    not_authenticated = 4003,
    authentication_failed = 4004,
    already_authenticated = 4005,
    invalid_sequence = 4007,
    rate_limited = 4008,
    session_timed_out = 4009,
    invalid_shard = 4010,
    sharding_required = 4011,
    invalid_api_version = 4012,
    invalid_intents = 4013,
    disallowed_intents = 4014,
};

pub fn closeCodeFromInt(value: u16) ?CloseCode {
    return switch (value) {
        4000 => .unknown_error,
        4001 => .unknown_opcode,
        4002 => .decode_error,
        4003 => .not_authenticated,
        4004 => .authentication_failed,
        4005 => .already_authenticated,
        4007 => .invalid_sequence,
        4008 => .rate_limited,
        4009 => .session_timed_out,
        4010 => .invalid_shard,
        4011 => .sharding_required,
        4012 => .invalid_api_version,
        4013 => .invalid_intents,
        4014 => .disallowed_intents,
        else => null,
    };
}

pub fn closeCodeCanReconnect(code: CloseCode) bool {
    return switch (code) {
        .unknown_error,
        .unknown_opcode,
        .decode_error,
        .not_authenticated,
        .already_authenticated,
        .invalid_sequence,
        .rate_limited,
        .session_timed_out,
        => true,

        .authentication_failed,
        .invalid_shard,
        .sharding_required,
        .invalid_api_version,
        .invalid_intents,
        .disallowed_intents,
        => false,
    };
}

pub const EventName = enum {
    READY,
    RESUMED,
    MESSAGE_CREATE,
    MESSAGE_UPDATE,
    MESSAGE_DELETE,
    MESSAGE_DELETE_BULK,
    MESSAGE_REACTION_ADD,
    MESSAGE_REACTION_REMOVE,
    MESSAGE_REACTION_REMOVE_ALL,
    MESSAGE_REACTION_REMOVE_EMOJI,
    MESSAGE_POLL_VOTE_ADD,
    MESSAGE_POLL_VOTE_REMOVE,
    USER_UPDATE,
    PRESENCE_UPDATE,
    VOICE_STATE_UPDATE,
    INTERACTION_CREATE,
    APPLICATION_COMMAND_PERMISSIONS_UPDATE,
    AUTO_MODERATION_RULE_CREATE,
    AUTO_MODERATION_RULE_UPDATE,
    AUTO_MODERATION_RULE_DELETE,
    AUTO_MODERATION_ACTION_EXECUTION,
    ENTITLEMENT_CREATE,
    ENTITLEMENT_UPDATE,
    ENTITLEMENT_DELETE,
    SUBSCRIPTION_CREATE,
    SUBSCRIPTION_UPDATE,
    SUBSCRIPTION_DELETE,
    GUILD_CREATE,
    GUILD_UPDATE,
    GUILD_DELETE,
    GUILD_AUDIT_LOG_ENTRY_CREATE,
    GUILD_BAN_ADD,
    GUILD_BAN_REMOVE,
    GUILD_INTEGRATIONS_UPDATE,
    INTEGRATION_CREATE,
    INTEGRATION_UPDATE,
    INTEGRATION_DELETE,
    GUILD_MEMBER_ADD,
    GUILD_MEMBER_UPDATE,
    GUILD_MEMBER_REMOVE,
    GUILD_MEMBERS_CHUNK,
    GUILD_ROLE_CREATE,
    GUILD_ROLE_UPDATE,
    GUILD_ROLE_DELETE,
    GUILD_EMOJIS_UPDATE,
    GUILD_STICKERS_UPDATE,
    GUILD_SCHEDULED_EVENT_CREATE,
    GUILD_SCHEDULED_EVENT_UPDATE,
    GUILD_SCHEDULED_EVENT_DELETE,
    GUILD_SCHEDULED_EVENT_USER_ADD,
    GUILD_SCHEDULED_EVENT_USER_REMOVE,
    GUILD_SOUNDBOARD_SOUND_CREATE,
    GUILD_SOUNDBOARD_SOUND_UPDATE,
    GUILD_SOUNDBOARD_SOUND_DELETE,
    GUILD_SOUNDBOARD_SOUNDS_UPDATE,
    SOUNDBOARD_SOUNDS,
    STAGE_INSTANCE_CREATE,
    STAGE_INSTANCE_UPDATE,
    STAGE_INSTANCE_DELETE,
    VOICE_CHANNEL_EFFECT_SEND,
    VOICE_SERVER_UPDATE,
    CHANNEL_CREATE,
    CHANNEL_UPDATE,
    CHANNEL_DELETE,
    CHANNEL_INFO,
    VOICE_CHANNEL_STATUS_UPDATE,
    VOICE_CHANNEL_START_TIME_UPDATE,
    CHANNEL_PINS_UPDATE,
    TYPING_START,
    WEBHOOKS_UPDATE,
    INVITE_CREATE,
    INVITE_DELETE,
    THREAD_CREATE,
    THREAD_UPDATE,
    THREAD_DELETE,
    THREAD_LIST_SYNC,
    THREAD_MEMBER_UPDATE,
    THREAD_MEMBERS_UPDATE,
    RATE_LIMITED,
    unknown,

    pub fn parse(value: []const u8) EventName {
        inline for (@typeInfo(EventName).@"enum".fields) |field| {
            if (comptime std.mem.eql(u8, field.name, "unknown")) continue;
            if (std.mem.eql(u8, value, field.name)) return @field(EventName, field.name);
        }
        return .unknown;
    }
};

pub const ActivityType = enum(u8) {
    playing = 0,
    streaming = 1,
    listening = 2,
    watching = 3,
    custom = 4,
    competing = 5,
};

pub const Activity = struct {
    name: []const u8,
    type: ActivityType,
    url: ?[]const u8 = null,

    pub fn init(name: []const u8, activity_type: ActivityType) Activity {
        return .{ .name = name, .type = activity_type };
    }

    pub fn withUrl(self: Activity, url: []const u8) Activity {
        var activity = self;
        activity.url = url;
        return activity;
    }

    pub fn writeJson(self: Activity, writer: anytype) !void {
        try writer.writeByte('{');
        try writer.writeAll("\"name\":");
        try Json.writeString(self.name, writer);
        try writer.print(",\"type\":{d}", .{@intFromEnum(self.type)});
        if (self.url) |url| {
            try writer.writeAll(",\"url\":");
            try Json.writeString(url, writer);
        }
        try writer.writeByte('}');
    }
};

pub const PresenceStatus = enum {
    online,
    idle,
    dnd,
    invisible,
    offline,

    fn value(self: PresenceStatus) []const u8 {
        return switch (self) {
            .online => "online",
            .idle => "idle",
            .dnd => "dnd",
            .invisible => "invisible",
            .offline => "offline",
        };
    }
};

pub const Presence = struct {
    since: ?u64 = null,
    activities: []const Activity = &.{},
    status: PresenceStatus = .online,
    afk: bool = false,

    pub fn init(status: PresenceStatus) Presence {
        return .{ .status = status };
    }

    pub fn withSince(self: Presence, since: u64) Presence {
        var presence = self;
        presence.since = since;
        return presence;
    }

    pub fn withActivities(self: Presence, activities: []const Activity) Presence {
        var presence = self;
        presence.activities = activities;
        return presence;
    }

    pub fn afkState(self: Presence, afk: bool) Presence {
        var presence = self;
        presence.afk = afk;
        return presence;
    }

    pub fn writeJson(self: Presence, writer: anytype) !void {
        try writer.writeByte('{');
        try writer.writeAll("\"since\":");
        if (self.since) |since| {
            try writer.print("{d}", .{since});
        } else {
            try writer.writeAll("null");
        }
        try writer.writeAll(",\"activities\":");
        try writeActivityArray(self.activities, writer);
        try writer.writeAll(",\"status\":");
        try Json.writeString(self.status.value(), writer);
        try writer.writeAll(",\"afk\":");
        try writer.writeAll(if (self.afk) "true" else "false");
        try writer.writeByte('}');
    }
};

pub const IdentifyOptions = struct {
    token: []const u8,
    intents: u32,
    os: []const u8 = "zig",
    browser: []const u8 = "discord.zig",
    device: []const u8 = "discord.zig",
    presence: ?Presence = null,
};

pub const ResumeOptions = struct {
    token: []const u8,
    session_id: []const u8,
    sequence: u64,
};

pub const RequestGuildMembers = struct {
    guild_id: Snowflake,
    query: ?[]const u8 = null,
    limit: ?u32 = null,
    presences: ?bool = null,
    user_ids: []const Snowflake = &.{},
    nonce: ?[]const u8 = null,

    pub fn init(guild_id: Snowflake) RequestGuildMembers {
        return .{ .guild_id = guild_id };
    }

    pub fn withQuery(self: RequestGuildMembers, query: []const u8) RequestGuildMembers {
        var request = self;
        request.query = query;
        return request;
    }

    pub fn withLimit(self: RequestGuildMembers, limit: u32) RequestGuildMembers {
        var request = self;
        request.limit = limit;
        return request;
    }

    pub fn withPresences(self: RequestGuildMembers, presences: bool) RequestGuildMembers {
        var request = self;
        request.presences = presences;
        return request;
    }

    pub fn withUsers(self: RequestGuildMembers, user_ids: []const Snowflake) RequestGuildMembers {
        var request = self;
        request.user_ids = user_ids;
        return request;
    }

    pub fn withNonce(self: RequestGuildMembers, nonce: []const u8) RequestGuildMembers {
        var request = self;
        request.nonce = nonce;
        return request;
    }

    pub fn writeJson(self: RequestGuildMembers, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.print("\"guild_id\":\"{d}\"", .{self.guild_id.value});
        if (self.query) |query| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"query\":");
            try Json.writeString(query, writer);
        }
        if (self.limit) |limit| {
            try writeComma(writer, &needs_comma);
            try writer.print("\"limit\":{d}", .{limit});
        }
        if (self.presences) |presences| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"presences\":");
            try writer.writeAll(if (presences) "true" else "false");
        }
        if (self.user_ids.len != 0) {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"user_ids\":");
            try writeSnowflakeArray(self.user_ids, writer);
        }
        if (self.nonce) |nonce| {
            try writeComma(writer, &needs_comma);
            try writer.writeAll("\"nonce\":");
            try Json.writeString(nonce, writer);
        }

        try writer.writeByte('}');
    }
};

pub const VoiceStateUpdate = struct {
    guild_id: Snowflake,
    channel_id: ?Snowflake = null,
    self_mute: bool = false,
    self_deaf: bool = false,

    pub fn init(guild_id: Snowflake) VoiceStateUpdate {
        return .{ .guild_id = guild_id };
    }

    pub fn withChannel(self: VoiceStateUpdate, channel_id: Snowflake) VoiceStateUpdate {
        var update = self;
        update.channel_id = channel_id;
        return update;
    }

    pub fn clearChannel(self: VoiceStateUpdate) VoiceStateUpdate {
        var update = self;
        update.channel_id = null;
        return update;
    }

    pub fn muteState(self: VoiceStateUpdate, self_mute: bool) VoiceStateUpdate {
        var update = self;
        update.self_mute = self_mute;
        return update;
    }

    pub fn deafState(self: VoiceStateUpdate, self_deaf: bool) VoiceStateUpdate {
        var update = self;
        update.self_deaf = self_deaf;
        return update;
    }

    pub fn writeJson(self: VoiceStateUpdate, writer: anytype) !void {
        try writer.writeByte('{');
        var needs_comma = false;

        try writeComma(writer, &needs_comma);
        try writer.print("\"guild_id\":\"{d}\"", .{self.guild_id.value});
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"channel_id\":");
        if (self.channel_id) |channel_id| {
            try writer.print("\"{d}\"", .{channel_id.value});
        } else {
            try writer.writeAll("null");
        }
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"self_mute\":");
        try writer.writeAll(if (self.self_mute) "true" else "false");
        try writeComma(writer, &needs_comma);
        try writer.writeAll("\"self_deaf\":");
        try writer.writeAll(if (self.self_deaf) "true" else "false");

        try writer.writeByte('}');
    }
};

pub const RequestSoundboardSounds = struct {
    guild_ids: []const Snowflake,

    pub fn init(guild_ids: []const Snowflake) RequestSoundboardSounds {
        return .{ .guild_ids = guild_ids };
    }

    pub fn writeJson(self: RequestSoundboardSounds, writer: anytype) !void {
        try writer.writeByte('{');
        try writer.writeAll("\"guild_ids\":");
        try writeSnowflakeArray(self.guild_ids, writer);
        try writer.writeByte('}');
    }
};

pub const ChannelInfoField = enum {
    status,
    voice_start_time,

    pub fn value(self: ChannelInfoField) []const u8 {
        return switch (self) {
            .status => "status",
            .voice_start_time => "voice_start_time",
        };
    }
};

pub const RequestChannelInfo = struct {
    guild_id: Snowflake,
    fields: []const ChannelInfoField,

    pub fn init(guild_id: Snowflake, fields: []const ChannelInfoField) RequestChannelInfo {
        return .{ .guild_id = guild_id, .fields = fields };
    }

    pub fn writeJson(self: RequestChannelInfo, writer: anytype) !void {
        try writer.writeByte('{');
        try writer.print("\"guild_id\":\"{d}\",\"fields\":", .{self.guild_id.value});
        try writeChannelInfoFieldArray(self.fields, writer);
        try writer.writeByte('}');
    }
};

pub fn writeIdentifyPayload(options: IdentifyOptions, writer: anytype) !void {
    try writer.writeAll("{\"op\":2,\"d\":{\"token\":");
    try Json.writeString(options.token, writer);
    try writer.print(",\"intents\":{d},\"properties\":{{\"os\":", .{options.intents});
    try Json.writeString(options.os, writer);
    try writer.writeAll(",\"browser\":");
    try Json.writeString(options.browser, writer);
    try writer.writeAll(",\"device\":");
    try Json.writeString(options.device, writer);
    try writer.writeAll("}");
    if (options.presence) |presence| {
        try writer.writeAll(",\"presence\":");
        try presence.writeJson(writer);
    }
    try writer.writeAll("}}");
}

fn writeActivityArray(activities: []const Activity, writer: anytype) !void {
    try writer.writeByte('[');
    for (activities, 0..) |activity, index| {
        if (index != 0) try writer.writeByte(',');
        try activity.writeJson(writer);
    }
    try writer.writeByte(']');
}

fn writeSnowflakeArray(ids: []const Snowflake, writer: anytype) !void {
    try writer.writeByte('[');
    for (ids, 0..) |id, index| {
        if (index != 0) try writer.writeByte(',');
        try writer.print("\"{d}\"", .{id.value});
    }
    try writer.writeByte(']');
}

fn writeChannelInfoFieldArray(fields: []const ChannelInfoField, writer: anytype) !void {
    try writer.writeByte('[');
    for (fields, 0..) |field, index| {
        if (index != 0) try writer.writeByte(',');
        try Json.writeString(field.value(), writer);
    }
    try writer.writeByte(']');
}

fn writeComma(writer: anytype, needs_comma: *bool) !void {
    if (needs_comma.*) try writer.writeByte(',');
    needs_comma.* = true;
}

pub fn writeHeartbeatPayload(sequence: ?u64, writer: anytype) !void {
    try writer.writeAll("{\"op\":1,\"d\":");
    if (sequence) |value| {
        try writer.print("{d}", .{value});
    } else {
        try writer.writeAll("null");
    }
    try writer.writeByte('}');
}

pub fn writePresenceUpdatePayload(presence: Presence, writer: anytype) !void {
    try writer.writeAll("{\"op\":3,\"d\":");
    try presence.writeJson(writer);
    try writer.writeByte('}');
}

pub fn writeVoiceStateUpdatePayload(update: VoiceStateUpdate, writer: anytype) !void {
    try writer.writeAll("{\"op\":4,\"d\":");
    try update.writeJson(writer);
    try writer.writeByte('}');
}

pub fn writeRequestGuildMembersPayload(request: RequestGuildMembers, writer: anytype) !void {
    try writer.writeAll("{\"op\":8,\"d\":");
    try request.writeJson(writer);
    try writer.writeByte('}');
}

pub fn writeRequestSoundboardSoundsPayload(request: RequestSoundboardSounds, writer: anytype) !void {
    try writer.writeAll("{\"op\":31,\"d\":");
    try request.writeJson(writer);
    try writer.writeByte('}');
}

pub fn writeRequestChannelInfoPayload(request: RequestChannelInfo, writer: anytype) !void {
    try writer.writeAll("{\"op\":43,\"d\":");
    try request.writeJson(writer);
    try writer.writeByte('}');
}

pub fn writeResumePayload(options: ResumeOptions, writer: anytype) !void {
    try writer.writeAll("{\"op\":6,\"d\":{\"token\":");
    try Json.writeString(options.token, writer);
    try writer.writeAll(",\"session_id\":");
    try Json.writeString(options.session_id, writer);
    try writer.print(",\"seq\":{d}}}}}", .{options.sequence});
}

pub fn parseHelloIntervalMs(allocator: std.mem.Allocator, payload: []const u8) !u64 {
    var parsed = try std.json.parseFromSlice(std.json.Value, allocator, payload, .{});
    defer parsed.deinit();

    const root = parsed.value.object;
    const op_value = root.get("op") orelse return error.InvalidGatewayPayload;
    if (op_value.integer != @intFromEnum(Opcode.hello)) return error.NotHello;

    const data = root.get("d") orelse return error.InvalidGatewayPayload;
    const interval = data.object.get("heartbeat_interval") orelse return error.InvalidGatewayPayload;
    return @intCast(interval.integer);
}

pub const ParsedDispatch = struct {
    parsed: std.json.Parsed(std.json.Value),
    sequence: ?u64,
    event: EventName,
    data: std.json.Value,

    pub fn deinit(self: *ParsedDispatch) void {
        self.parsed.deinit();
    }
};

pub fn parseDispatch(allocator: std.mem.Allocator, payload: []const u8) !ParsedDispatch {
    var parsed = try std.json.parseFromSlice(std.json.Value, allocator, payload, .{});
    errdefer parsed.deinit();

    const root = parsed.value.object;
    const op_value = root.get("op") orelse return error.InvalidGatewayPayload;
    if (op_value.integer != @intFromEnum(Opcode.dispatch)) return error.NotDispatch;

    const t_value = root.get("t") orelse return error.InvalidGatewayPayload;
    const s_value = root.get("s");
    const d_value = root.get("d") orelse return error.InvalidGatewayPayload;

    const event = EventName.parse(t_value.string);
    const sequence: ?u64 = if (s_value) |s| @intCast(s.integer) else null;
    return .{ .parsed = parsed, .sequence = sequence, .event = event, .data = d_value };
}

pub fn gatewayUrl(allocator: std.mem.Allocator) ![]u8 {
    return std.fmt.allocPrint(
        allocator,
        "wss://gateway.discord.gg/?v={d}&encoding={s}",
        .{ Api.version, Api.gateway_encoding },
    );
}

pub fn shardIdForGuild(guild_id: Snowflake, shard_count: u32) !u32 {
    if (shard_count == 0) return error.InvalidShardCount;
    return @intCast((guild_id.value >> 22) % shard_count);
}

pub fn identifyRateLimitKey(shard_id: u32, max_concurrency: u32) !u32 {
    if (max_concurrency == 0) return error.InvalidMaxConcurrency;
    return shard_id % max_concurrency;
}

test "identify payload includes token and intents" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try writeIdentifyPayload(.{ .token = "Bot abc", .intents = 513 }, &out.writer);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "\"op\":2") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "\"intents\":513") != null);
}

test "gateway opcode and close code constants match Discord values" {
    try std.testing.expectEqual(@as(u8, 31), @intFromEnum(Opcode.request_soundboard_sounds));
    try std.testing.expectEqual(@as(u8, 43), @intFromEnum(Opcode.request_channel_info));

    try std.testing.expectEqual(CloseCode.unknown_error, closeCodeFromInt(4000).?);
    try std.testing.expectEqual(CloseCode.disallowed_intents, closeCodeFromInt(4014).?);
    try std.testing.expectEqual(null, closeCodeFromInt(3999));
    try std.testing.expect(closeCodeCanReconnect(.unknown_opcode));
    try std.testing.expect(closeCodeCanReconnect(.session_timed_out));
    try std.testing.expect(!closeCodeCanReconnect(.authentication_failed));
    try std.testing.expect(!closeCodeCanReconnect(.invalid_intents));
    try std.testing.expect(!closeCodeCanReconnect(.disallowed_intents));
}

test "request channel info payload writes documented fields" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try writeRequestChannelInfoPayload(
        RequestChannelInfo.init(Snowflake.init(10), &.{ .status, .voice_start_time }),
        &out.writer,
    );

    try std.testing.expectEqualStrings(
        "{\"op\":43,\"d\":{\"guild_id\":\"10\",\"fields\":[\"status\",\"voice_start_time\"]}}",
        out.written(),
    );
}

test "identify payload can include presence activities" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const activities = [_]Activity{Activity.init("discord.zig", .watching)};
    try writeIdentifyPayload(.{
        .token = "Bot abc",
        .intents = 513,
        .presence = Presence.init(.idle)
            .withSince(42)
            .withActivities(&activities)
            .afkState(true),
    }, &out.writer);

    try std.testing.expect(std.mem.indexOf(u8, out.written(), "\"presence\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "\"activities\":[{\"name\":\"discord.zig\",\"type\":3}]") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "\"status\":\"idle\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, out.written(), "\"afk\":true") != null);
}

test "presence update payload uses opcode three and presence body" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const activities = [_]Activity{Activity.init("streams", .streaming).withUrl("https://example.com/live")};
    try writePresenceUpdatePayload(Presence.init(.online).withActivities(&activities), &out.writer);

    try std.testing.expectEqualStrings(
        "{\"op\":3,\"d\":{\"since\":null,\"activities\":[{\"name\":\"streams\",\"type\":1,\"url\":\"https://example.com/live\"}],\"status\":\"online\",\"afk\":false}}",
        out.written(),
    );
}

test "voice state update payload supports join and leave" {
    var join = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer join.deinit();

    try writeVoiceStateUpdatePayload(
        VoiceStateUpdate.init(Snowflake.init(10))
            .withChannel(Snowflake.init(20))
            .muteState(true),
        &join.writer,
    );
    try std.testing.expectEqualStrings(
        "{\"op\":4,\"d\":{\"guild_id\":\"10\",\"channel_id\":\"20\",\"self_mute\":true,\"self_deaf\":false}}",
        join.written(),
    );

    var leave = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer leave.deinit();

    try writeVoiceStateUpdatePayload(VoiceStateUpdate.init(Snowflake.init(10)).clearChannel(), &leave.writer);
    try std.testing.expectEqualStrings(
        "{\"op\":4,\"d\":{\"guild_id\":\"10\",\"channel_id\":null,\"self_mute\":false,\"self_deaf\":false}}",
        leave.written(),
    );
}

test "request guild members payload supports query and user ids" {
    var query = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer query.deinit();

    try writeRequestGuildMembersPayload(
        RequestGuildMembers.init(Snowflake.init(10))
            .withQuery("bar")
            .withLimit(25)
            .withPresences(true)
            .withNonce("request-1"),
        &query.writer,
    );
    try std.testing.expectEqualStrings(
        "{\"op\":8,\"d\":{\"guild_id\":\"10\",\"query\":\"bar\",\"limit\":25,\"presences\":true,\"nonce\":\"request-1\"}}",
        query.written(),
    );

    var users = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer users.deinit();

    try writeRequestGuildMembersPayload(
        RequestGuildMembers.init(Snowflake.init(10))
            .withUsers(&.{ Snowflake.init(20), Snowflake.init(30) })
            .withNonce("request-2"),
        &users.writer,
    );
    try std.testing.expectEqualStrings(
        "{\"op\":8,\"d\":{\"guild_id\":\"10\",\"user_ids\":[\"20\",\"30\"],\"nonce\":\"request-2\"}}",
        users.written(),
    );
}

test "request soundboard sounds payload writes guild ids" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try writeRequestSoundboardSoundsPayload(
        RequestSoundboardSounds.init(&.{ Snowflake.init(20), Snowflake.init(30) }),
        &out.writer,
    );
    try std.testing.expectEqualStrings(
        "{\"op\":31,\"d\":{\"guild_ids\":[\"20\",\"30\"]}}",
        out.written(),
    );
}

test "heartbeat and resume payloads" {
    var heartbeat = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer heartbeat.deinit();
    try writeHeartbeatPayload(42, &heartbeat.writer);
    try std.testing.expectEqualStrings("{\"op\":1,\"d\":42}", heartbeat.written());

    var resume_payload = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer resume_payload.deinit();
    try writeResumePayload(.{ .token = "Bot abc", .session_id = "session", .sequence = 7 }, &resume_payload.writer);
    try std.testing.expectEqualStrings(
        "{\"op\":6,\"d\":{\"token\":\"Bot abc\",\"session_id\":\"session\",\"seq\":7}}",
        resume_payload.written(),
    );
}

test "sharding helpers follow Discord gateway formulas" {
    try std.testing.expectEqual(@as(u32, 2), try shardIdForGuild(Snowflake.init((42 << 22) + 1), 5));
    try std.testing.expectEqual(@as(u32, 3), try identifyRateLimitKey(19, 16));
    try std.testing.expectError(error.InvalidShardCount, shardIdForGuild(Snowflake.init(1), 0));
    try std.testing.expectError(error.InvalidMaxConcurrency, identifyRateLimitKey(1, 0));
}

test "parse hello interval" {
    const interval = try parseHelloIntervalMs(
        std.testing.allocator,
        "{\"op\":10,\"d\":{\"heartbeat_interval\":41250}}",
    );
    try std.testing.expectEqual(@as(u64, 41250), interval);
}

test "parse dispatch event" {
    var dispatch = try parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":7,\"t\":\"MESSAGE_CREATE\",\"d\":{\"content\":\"hi\"}}",
    );
    defer dispatch.deinit();

    try std.testing.expectEqual(@as(?u64, 7), dispatch.sequence);
    try std.testing.expectEqual(EventName.MESSAGE_CREATE, dispatch.event);
}

test "identify payload is valid parseable JSON with and without presence" {
    const allocator = std.testing.allocator;

    var plain = std.Io.Writer.Allocating.init(allocator);
    defer plain.deinit();
    try writeIdentifyPayload(.{ .token = "Bot abc", .intents = 513 }, &plain.writer);
    {
        const parsed = try std.json.parseFromSlice(std.json.Value, allocator, plain.written(), .{});
        defer parsed.deinit();
        try std.testing.expectEqual(@as(i64, 2), parsed.value.object.get("op").?.integer);
        const d = parsed.value.object.get("d").?.object;
        try std.testing.expectEqualStrings("Bot abc", d.get("token").?.string);
        try std.testing.expectEqual(@as(i64, 513), d.get("intents").?.integer);
        try std.testing.expect(d.get("properties").?.object.get("os") != null);
    }

    var with_presence = std.Io.Writer.Allocating.init(allocator);
    defer with_presence.deinit();
    try writeIdentifyPayload(.{
        .token = "Bot abc",
        .intents = 513,
        .presence = Presence.init(.online),
    }, &with_presence.writer);
    {
        const parsed = try std.json.parseFromSlice(std.json.Value, allocator, with_presence.written(), .{});
        defer parsed.deinit();
        const d = parsed.value.object.get("d").?.object;
        try std.testing.expect(d.get("presence") != null);
    }
}
