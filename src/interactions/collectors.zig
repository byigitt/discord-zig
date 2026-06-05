const std = @import("std");
const Snowflake = @import("../core/snowflake.zig").Snowflake;
const Types = @import("../models/types.zig");
const Interactions = @import("mod.zig");
const Gateway = @import("../gateway/protocol.zig");

pub const CollectorStatus = enum {
    collecting,
    completed,
    timed_out,
    stopped,
};

pub const MessageCollectOptions = struct {
    guild_id: ?Snowflake = null,
    channel_id: ?Snowflake = null,
    author_id: ?Snowflake = null,
    contains: ?[]const u8 = null,
    max: ?usize = null,
    time_ms: ?u64 = null,
    idle_ms: ?u64 = null,
};

pub const MessageCollector = struct {
    options: MessageCollectOptions = .{},
    collected: usize = 0,
    last_message_id: ?Snowflake = null,
    started_at_ms: u64 = 0,
    last_collected_at_ms: ?u64 = null,
    status: CollectorStatus = .collecting,

    pub fn init(options: MessageCollectOptions) MessageCollector {
        return .{ .options = options };
    }

    pub fn initAt(options: MessageCollectOptions, now_ms: u64) MessageCollector {
        return .{ .options = options, .started_at_ms = now_ms };
    }

    pub fn collect(self: *MessageCollector, message: Types.Message) bool {
        return self.collectAt(message, self.started_at_ms);
    }

    pub fn collectAt(self: *MessageCollector, message: Types.Message, now_ms: u64) bool {
        if (self.tick(now_ms)) return false;
        if (self.status != .collecting) return false;
        if (!self.matches(message)) return false;

        self.collected += 1;
        self.last_message_id = message.id;
        self.last_collected_at_ms = now_ms;
        self.completeIfFull();
        return true;
    }

    pub fn collectDispatch(self: *MessageCollector, dispatch: Gateway.ParsedDispatch) !bool {
        return self.collectDispatchAt(dispatch, self.started_at_ms);
    }

    pub fn collectDispatchAt(self: *MessageCollector, dispatch: Gateway.ParsedDispatch, now_ms: u64) !bool {
        if (dispatch.event != .MESSAGE_CREATE) return false;
        return self.collectAt(try messageFromJson(dispatch.data), now_ms);
    }

    pub fn stop(self: *MessageCollector) void {
        self.status = .stopped;
    }

    pub fn reset(self: *MessageCollector) void {
        self.resetAt(0);
    }

    pub fn resetAt(self: *MessageCollector, now_ms: u64) void {
        self.collected = 0;
        self.last_message_id = null;
        self.started_at_ms = now_ms;
        self.last_collected_at_ms = null;
        self.status = .collecting;
    }

    pub fn tick(self: *MessageCollector, now_ms: u64) bool {
        if (self.status != .collecting) return self.isDone();
        if (self.hasTimedOut(now_ms)) {
            self.status = .timed_out;
            return true;
        }
        return false;
    }

    pub fn isDone(self: MessageCollector) bool {
        return self.status != .collecting;
    }

    pub fn matches(self: MessageCollector, message: Types.Message) bool {
        if (self.options.guild_id) |guild_id| {
            const message_guild_id = message.guild_id orelse return false;
            if (message_guild_id.value != guild_id.value) return false;
        }
        if (self.options.channel_id) |channel_id| {
            if (message.channel_id.value != channel_id.value) return false;
        }
        if (self.options.author_id) |author_id| {
            const author = message.author orelse return false;
            if (author.id.value != author_id.value) return false;
        }
        if (self.options.contains) |needle| {
            if (std.mem.indexOf(u8, message.content, needle) == null) return false;
        }
        return true;
    }

    fn completeIfFull(self: *MessageCollector) void {
        if (self.options.max) |max| {
            if (self.collected >= max) self.status = .completed;
        }
    }

    fn hasTimedOut(self: MessageCollector, now_ms: u64) bool {
        if (elapsedAtLeast(self.started_at_ms, now_ms, self.options.time_ms)) return true;
        const idle_base = self.last_collected_at_ms orelse self.started_at_ms;
        return elapsedAtLeast(idle_base, now_ms, self.options.idle_ms);
    }
};

pub const InteractionCollectOptions = struct {
    guild_id: ?Snowflake = null,
    channel_id: ?Snowflake = null,
    user_id: ?Snowflake = null,
    interaction_type: ?Interactions.InteractionType = null,
    custom_id: ?[]const u8 = null,
    command_name: ?[]const u8 = null,
    max: ?usize = null,
    time_ms: ?u64 = null,
    idle_ms: ?u64 = null,
};

pub const InteractionCollector = struct {
    options: InteractionCollectOptions = .{},
    collected: usize = 0,
    last_interaction_id: ?Snowflake = null,
    started_at_ms: u64 = 0,
    last_collected_at_ms: ?u64 = null,
    status: CollectorStatus = .collecting,

    pub fn init(options: InteractionCollectOptions) InteractionCollector {
        return .{ .options = options };
    }

    pub fn initAt(options: InteractionCollectOptions, now_ms: u64) InteractionCollector {
        return .{ .options = options, .started_at_ms = now_ms };
    }

    pub fn collect(self: *InteractionCollector, interaction: Interactions.ParsedInteraction) bool {
        return self.collectAt(interaction, self.started_at_ms);
    }

    pub fn collectAt(self: *InteractionCollector, interaction: Interactions.ParsedInteraction, now_ms: u64) bool {
        if (self.tick(now_ms)) return false;
        if (self.status != .collecting) return false;
        if (!self.matches(interaction)) return false;

        self.collected += 1;
        self.last_interaction_id = interaction.interaction.id;
        self.last_collected_at_ms = now_ms;
        self.completeIfFull();
        return true;
    }

    pub fn collectDispatch(self: *InteractionCollector, dispatch: Gateway.ParsedDispatch) !bool {
        return self.collectDispatchAt(dispatch, self.started_at_ms);
    }

    pub fn collectDispatchAt(self: *InteractionCollector, dispatch: Gateway.ParsedDispatch, now_ms: u64) !bool {
        if (dispatch.event != .INTERACTION_CREATE) return false;
        if (self.tick(now_ms)) return false;
        if (self.status != .collecting) return false;
        if (!try self.matchesDispatchData(dispatch.data)) return false;

        self.collected += 1;
        self.last_interaction_id = try snowflakeField(try objectValue(dispatch.data), "id");
        self.last_collected_at_ms = now_ms;
        self.completeIfFull();
        return true;
    }

    pub fn stop(self: *InteractionCollector) void {
        self.status = .stopped;
    }

    pub fn reset(self: *InteractionCollector) void {
        self.resetAt(0);
    }

    pub fn resetAt(self: *InteractionCollector, now_ms: u64) void {
        self.collected = 0;
        self.last_interaction_id = null;
        self.started_at_ms = now_ms;
        self.last_collected_at_ms = null;
        self.status = .collecting;
    }

    pub fn tick(self: *InteractionCollector, now_ms: u64) bool {
        if (self.status != .collecting) return self.isDone();
        if (self.hasTimedOut(now_ms)) {
            self.status = .timed_out;
            return true;
        }
        return false;
    }

    pub fn isDone(self: InteractionCollector) bool {
        return self.status != .collecting;
    }

    pub fn matches(self: InteractionCollector, interaction: Interactions.ParsedInteraction) bool {
        if (self.options.guild_id) |guild_id| {
            const interaction_guild_id = interaction.interaction.guild_id orelse return false;
            if (interaction_guild_id.value != guild_id.value) return false;
        }
        if (self.options.channel_id) |channel_id| {
            const interaction_channel_id = interaction.interaction.channel_id orelse return false;
            if (interaction_channel_id.value != channel_id.value) return false;
        }
        if (self.options.user_id) |user_id| {
            const interaction_user_id = interaction.interaction.user_id orelse return false;
            if (interaction_user_id.value != user_id.value) return false;
        }
        if (self.options.interaction_type) |expected| {
            if (interaction.interaction.type != expected) return false;
        }
        if (self.options.custom_id) |custom_id| {
            const data = interaction.component_data orelse return false;
            if (!std.mem.eql(u8, data.custom_id, custom_id)) return false;
        }
        if (self.options.command_name) |command_name| {
            const data = interaction.data orelse return false;
            if (!std.mem.eql(u8, data.name, command_name)) return false;
        }
        return true;
    }

    fn matchesDispatchData(self: InteractionCollector, data: std.json.Value) !bool {
        const object = try objectValue(data);
        if (self.options.guild_id) |guild_id| {
            const interaction_guild_id = if (object.get("guild_id")) |value| try snowflakeValue(value) else return false;
            if (interaction_guild_id.value != guild_id.value) return false;
        }
        if (self.options.channel_id) |channel_id| {
            const interaction_channel_id = if (object.get("channel_id")) |value| try snowflakeValue(value) else return false;
            if (interaction_channel_id.value != channel_id.value) return false;
        }
        if (self.options.user_id) |user_id| {
            const interaction_user_id = (try interactionUserId(object)) orelse return false;
            if (interaction_user_id.value != user_id.value) return false;
        }
        if (self.options.interaction_type) |expected| {
            const raw_type: u8 = @intCast(try integerField(object, "type"));
            if (raw_type != @intFromEnum(expected)) return false;
        }
        if (self.options.custom_id) |custom_id| {
            const interaction_data = try objectValue(object.get("data") orelse return error.MissingField);
            const actual = try stringField(interaction_data, "custom_id");
            if (!std.mem.eql(u8, actual, custom_id)) return false;
        }
        if (self.options.command_name) |command_name| {
            const interaction_data = try objectValue(object.get("data") orelse return error.MissingField);
            const actual = try stringField(interaction_data, "name");
            if (!std.mem.eql(u8, actual, command_name)) return false;
        }
        return true;
    }

    fn completeIfFull(self: *InteractionCollector) void {
        if (self.options.max) |max| {
            if (self.collected >= max) self.status = .completed;
        }
    }

    fn hasTimedOut(self: InteractionCollector, now_ms: u64) bool {
        if (elapsedAtLeast(self.started_at_ms, now_ms, self.options.time_ms)) return true;
        const idle_base = self.last_collected_at_ms orelse self.started_at_ms;
        return elapsedAtLeast(idle_base, now_ms, self.options.idle_ms);
    }
};

fn elapsedAtLeast(start_ms: u64, now_ms: u64, limit_ms: ?u64) bool {
    const limit = limit_ms orelse return false;
    return now_ms >= start_ms and now_ms - start_ms >= limit;
}

fn messageFromJson(value: std.json.Value) !Types.Message {
    const object = try objectValue(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .channel_id = try snowflakeField(object, "channel_id"),
        .guild_id = if (object.get("guild_id")) |field| try snowflakeValue(field) else null,
        .author = if (object.get("author")) |author| try userFromJson(author) else null,
        .content = try stringField(object, "content"),
        .timestamp = if (object.get("timestamp")) |field| try stringValue(field) else null,
    };
}

fn userFromJson(value: std.json.Value) !Types.User {
    const object = try objectValue(value);
    return .{
        .id = try snowflakeField(object, "id"),
        .username = try stringField(object, "username"),
        .discriminator = if (object.get("discriminator")) |field| try stringValue(field) else null,
        .global_name = if (object.get("global_name")) |field| if (field == .null) null else try stringValue(field) else null,
        .bot = if (object.get("bot")) |field| try boolValue(field) else false,
    };
}

fn interactionUserId(root: std.json.ObjectMap) !?Snowflake {
    if (root.get("member")) |member_value| {
        const member = try objectValue(member_value);
        if (member.get("user")) |user_value| {
            const user = try objectValue(user_value);
            return try snowflakeField(user, "id");
        }
    }
    if (root.get("user")) |user_value| {
        const user = try objectValue(user_value);
        return try snowflakeField(user, "id");
    }
    return null;
}

fn objectValue(value: std.json.Value) !std.json.ObjectMap {
    return switch (value) {
        .object => |object| object,
        else => error.InvalidField,
    };
}

fn snowflakeField(object: std.json.ObjectMap, field: []const u8) !Snowflake {
    return snowflakeValue(object.get(field) orelse return error.MissingField);
}

fn snowflakeValue(value: std.json.Value) !Snowflake {
    return Snowflake.parse(try stringValue(value));
}

fn stringField(object: std.json.ObjectMap, field: []const u8) ![]const u8 {
    return stringValue(object.get(field) orelse return error.MissingField);
}

fn stringValue(value: std.json.Value) ![]const u8 {
    return switch (value) {
        .string => |string| string,
        else => error.InvalidField,
    };
}

fn integerField(object: std.json.ObjectMap, field: []const u8) !i64 {
    return integerValue(object.get(field) orelse return error.MissingField);
}

fn integerValue(value: std.json.Value) !i64 {
    return switch (value) {
        .integer => |integer| @intCast(integer),
        else => error.InvalidField,
    };
}

fn boolValue(value: std.json.Value) !bool {
    return switch (value) {
        .bool => |boolean| boolean,
        else => error.InvalidField,
    };
}

test "message collector filters and completes" {
    const author = Types.User{ .id = Snowflake.init(20), .username = "baris" };
    var collector = MessageCollector.init(.{
        .guild_id = Snowflake.init(5),
        .channel_id = Snowflake.init(10),
        .author_id = Snowflake.init(20),
        .contains = "pong",
        .max = 2,
    });

    try std.testing.expect(!collector.collect(.{
        .id = Snowflake.init(1),
        .channel_id = Snowflake.init(99),
        .author = author,
        .content = "pong",
    }));

    try std.testing.expect(!collector.collect(.{
        .id = Snowflake.init(5),
        .guild_id = Snowflake.init(6),
        .channel_id = Snowflake.init(10),
        .author = author,
        .content = "pong",
    }));

    try std.testing.expect(collector.collect(.{
        .id = Snowflake.init(2),
        .guild_id = Snowflake.init(5),
        .channel_id = Snowflake.init(10),
        .author = author,
        .content = "pong one",
    }));
    try std.testing.expectEqual(@as(usize, 1), collector.collected);
    try std.testing.expectEqual(@as(u64, 2), collector.last_message_id.?.value);
    try std.testing.expectEqual(CollectorStatus.collecting, collector.status);

    try std.testing.expect(collector.collect(.{
        .id = Snowflake.init(3),
        .guild_id = Snowflake.init(5),
        .channel_id = Snowflake.init(10),
        .author = author,
        .content = "pong two",
    }));
    try std.testing.expectEqual(CollectorStatus.completed, collector.status);
    try std.testing.expectEqual(@as(u64, 3), collector.last_message_id.?.value);
    try std.testing.expect(!collector.collect(.{
        .id = Snowflake.init(4),
        .guild_id = Snowflake.init(5),
        .channel_id = Snowflake.init(10),
        .author = author,
        .content = "pong three",
    }));
}

test "message collector accepts gateway dispatch payloads" {
    var collector = MessageCollector.init(.{
        .guild_id = Snowflake.init(5),
        .channel_id = Snowflake.init(10),
        .author_id = Snowflake.init(20),
        .contains = "confirm",
        .max = 1,
    });

    var ignored = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"MESSAGE_UPDATE\",\"d\":{\"id\":\"1\",\"channel_id\":\"10\",\"content\":\"confirm\",\"author\":{\"id\":\"20\",\"username\":\"baris\"}}}",
    );
    defer ignored.deinit();
    try std.testing.expect(!try collector.collectDispatch(ignored));

    var wrong_guild = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"MESSAGE_CREATE\",\"d\":{\"id\":\"2\",\"guild_id\":\"6\",\"channel_id\":\"10\",\"content\":\"please confirm\",\"author\":{\"id\":\"20\",\"username\":\"baris\"}}}",
    );
    defer wrong_guild.deinit();
    try std.testing.expect(!try collector.collectDispatch(wrong_guild));

    var matched = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"MESSAGE_CREATE\",\"d\":{\"id\":\"3\",\"guild_id\":\"5\",\"channel_id\":\"10\",\"content\":\"please confirm\",\"author\":{\"id\":\"20\",\"username\":\"baris\"}}}",
    );
    defer matched.deinit();
    try std.testing.expect(try collector.collectDispatch(matched));
    try std.testing.expectEqual(@as(usize, 1), collector.collected);
    try std.testing.expectEqual(@as(u64, 3), collector.last_message_id.?.value);
    try std.testing.expectEqual(CollectorStatus.completed, collector.status);
    collector.reset();
    try std.testing.expectEqual(@as(usize, 0), collector.collected);
    try std.testing.expect(collector.last_message_id == null);
    try std.testing.expectEqual(CollectorStatus.collecting, collector.status);
}

test "message collector supports time and idle limits" {
    const author = Types.User{ .id = Snowflake.init(20), .username = "baris" };
    var collector = MessageCollector.initAt(.{
        .channel_id = Snowflake.init(10),
        .time_ms = 100,
        .idle_ms = 50,
    }, 1000);

    try std.testing.expect(!collector.tick(1029));
    try std.testing.expect(collector.collectAt(.{
        .id = Snowflake.init(1),
        .channel_id = Snowflake.init(10),
        .author = author,
        .content = "pong",
    }, 1030));
    try std.testing.expectEqual(@as(u64, 1030), collector.last_collected_at_ms.?);
    try std.testing.expect(!collector.tick(1079));
    try std.testing.expect(collector.tick(1080));
    try std.testing.expectEqual(CollectorStatus.timed_out, collector.status);
    try std.testing.expect(!collector.collectAt(.{
        .id = Snowflake.init(2),
        .channel_id = Snowflake.init(10),
        .author = author,
        .content = "late",
    }, 1081));

    collector.resetAt(2000);
    try std.testing.expectEqual(CollectorStatus.collecting, collector.status);
    try std.testing.expectEqual(@as(u64, 2000), collector.started_at_ms);
    try std.testing.expect(collector.last_collected_at_ms == null);
    try std.testing.expect(collector.tick(2100));
    try std.testing.expectEqual(CollectorStatus.timed_out, collector.status);
}

test "interaction collector filters components commands and stop state" {
    var component = try Interactions.parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"guild_id\":\"5\",\"channel_id\":\"10\",\"member\":{\"user\":{\"id\":\"20\",\"username\":\"baris\"}},\"data\":{\"custom_id\":\"confirm\",\"component_type\":2}}",
    );
    defer component.deinit();

    var component_collector = InteractionCollector.init(.{
        .guild_id = Snowflake.init(5),
        .channel_id = Snowflake.init(10),
        .user_id = Snowflake.init(20),
        .interaction_type = .message_component,
        .custom_id = "confirm",
        .max = 1,
    });
    var wrong_channel_component = try Interactions.parseInteraction(
        std.testing.allocator,
        "{\"id\":\"2\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"guild_id\":\"5\",\"channel_id\":\"11\",\"member\":{\"user\":{\"id\":\"20\",\"username\":\"baris\"}},\"data\":{\"custom_id\":\"confirm\",\"component_type\":2}}",
    );
    defer wrong_channel_component.deinit();
    try std.testing.expect(!component_collector.collect(wrong_channel_component));
    var wrong_user_component = try Interactions.parseInteraction(
        std.testing.allocator,
        "{\"id\":\"3\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"guild_id\":\"5\",\"channel_id\":\"10\",\"member\":{\"user\":{\"id\":\"21\",\"username\":\"other\"}},\"data\":{\"custom_id\":\"confirm\",\"component_type\":2}}",
    );
    defer wrong_user_component.deinit();
    try std.testing.expect(!component_collector.collect(wrong_user_component));
    try std.testing.expect(component_collector.collect(component));
    try std.testing.expectEqual(@as(u64, 1), component_collector.last_interaction_id.?.value);
    try std.testing.expectEqual(CollectorStatus.completed, component_collector.status);

    var command = try Interactions.parseInteraction(
        std.testing.allocator,
        "{\"id\":\"4\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"guild_id\":\"5\",\"channel_id\":\"10\",\"member\":{\"user\":{\"id\":\"20\",\"username\":\"baris\"}},\"data\":{\"id\":\"4\",\"name\":\"echo\",\"type\":1}}",
    );
    defer command.deinit();

    var command_collector = InteractionCollector.init(.{ .guild_id = Snowflake.init(5), .user_id = Snowflake.init(20), .command_name = "echo" });
    try std.testing.expect(command_collector.collect(command));
    try std.testing.expectEqual(@as(u64, 4), command_collector.last_interaction_id.?.value);
    command_collector.stop();
    try std.testing.expect(command_collector.isDone());
    try std.testing.expect(!command_collector.collect(command));
}

test "interaction collector accepts gateway dispatch payloads" {
    var component_collector = InteractionCollector.init(.{
        .guild_id = Snowflake.init(5),
        .channel_id = Snowflake.init(10),
        .user_id = Snowflake.init(20),
        .interaction_type = .message_component,
        .custom_id = "confirm",
        .max = 1,
    });

    var ignored = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"MESSAGE_CREATE\",\"d\":{\"id\":\"1\",\"channel_id\":\"10\",\"content\":\"confirm\",\"author\":{\"id\":\"20\",\"username\":\"baris\"}}}",
    );
    defer ignored.deinit();
    try std.testing.expect(!try component_collector.collectDispatch(ignored));

    var wrong_guild = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":2,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"2\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"guild_id\":\"6\",\"channel_id\":\"10\",\"member\":{\"user\":{\"id\":\"20\",\"username\":\"baris\"}},\"data\":{\"custom_id\":\"confirm\",\"component_type\":2}}}",
    );
    defer wrong_guild.deinit();
    try std.testing.expect(!try component_collector.collectDispatch(wrong_guild));

    var wrong_user = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"3\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"guild_id\":\"5\",\"channel_id\":\"10\",\"member\":{\"user\":{\"id\":\"21\",\"username\":\"other\"}},\"data\":{\"custom_id\":\"confirm\",\"component_type\":2}}}",
    );
    defer wrong_user.deinit();
    try std.testing.expect(!try component_collector.collectDispatch(wrong_user));

    var component = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":4,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"1\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"guild_id\":\"5\",\"channel_id\":\"10\",\"member\":{\"user\":{\"id\":\"20\",\"username\":\"baris\"}},\"data\":{\"custom_id\":\"confirm\",\"component_type\":2}}}",
    );
    defer component.deinit();
    try std.testing.expect(try component_collector.collectDispatch(component));
    try std.testing.expectEqual(@as(u64, 1), component_collector.last_interaction_id.?.value);
    try std.testing.expectEqual(CollectorStatus.completed, component_collector.status);
    component_collector.reset();
    try std.testing.expectEqual(@as(usize, 0), component_collector.collected);
    try std.testing.expect(component_collector.last_interaction_id == null);
    try std.testing.expectEqual(CollectorStatus.collecting, component_collector.status);

    var command_collector = InteractionCollector.init(.{ .command_name = "echo" });
    var command = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":3,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"3\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"4\",\"name\":\"echo\",\"type\":1}}}",
    );
    defer command.deinit();
    try std.testing.expect(try command_collector.collectDispatch(command));
    try std.testing.expectEqual(@as(u64, 3), command_collector.last_interaction_id.?.value);
}

test "interaction collector supports timed raw dispatch collection" {
    var collector = InteractionCollector.initAt(.{
        .custom_id = "confirm",
        .time_ms = 100,
        .idle_ms = 40,
    }, 5000);

    var component = try Gateway.parseDispatch(
        std.testing.allocator,
        "{\"op\":0,\"s\":1,\"t\":\"INTERACTION_CREATE\",\"d\":{\"id\":\"10\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"data\":{\"custom_id\":\"confirm\",\"component_type\":2}}}",
    );
    defer component.deinit();
    try std.testing.expect(try collector.collectDispatchAt(component, 5030));
    try std.testing.expectEqual(@as(u64, 10), collector.last_interaction_id.?.value);
    try std.testing.expectEqual(@as(u64, 5030), collector.last_collected_at_ms.?);
    try std.testing.expect(!collector.tick(5069));
    try std.testing.expect(collector.tick(5070));
    try std.testing.expectEqual(CollectorStatus.timed_out, collector.status);

    collector.resetAt(6000);
    try std.testing.expectEqual(CollectorStatus.collecting, collector.status);
    try std.testing.expect(collector.tick(6100));
    try std.testing.expectEqual(CollectorStatus.timed_out, collector.status);
}
