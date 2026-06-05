const std = @import("std");

/// Ordered key/value store modeled on discord.js's `Collection` (a `Map` with
/// extra functional helpers). Insertion order is preserved, so `first`/`last`
/// and index access are well-defined. Keys are hashed with Zig's automatic
/// hashing, so any key type usable with `std.AutoArrayHashMap` works (integers,
/// `Snowflake`, packed composite ids, ...).
pub fn Collection(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();
        const Map = std.array_hash_map.Auto(K, V);

        inner: Map,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{ .inner = .empty, .allocator = allocator };
        }

        pub fn deinit(self: *Self) void {
            self.inner.deinit(self.allocator);
        }

        /// Inserts or replaces the value stored for `key`.
        pub fn set(self: *Self, key: K, value: V) !void {
            try self.inner.put(self.allocator, key, value);
        }

        /// Returns an existing value, or inserts and returns `value` when absent.
        pub fn ensure(self: *Self, key: K, value: V) !V {
            if (self.get(key)) |existing| return existing;
            try self.set(key, value);
            return value;
        }

        pub fn get(self: Self, key: K) ?V {
            return self.inner.get(key);
        }

        pub fn has(self: Self, key: K) bool {
            return self.inner.contains(key);
        }

        /// Removes `key`, preserving the order of the remaining entries. Returns
        /// whether an entry was actually present.
        pub fn delete(self: *Self, key: K) bool {
            return self.inner.orderedRemove(key);
        }

        pub fn clear(self: *Self) void {
            self.inner.clearRetainingCapacity();
        }

        /// Removes every entry that satisfies `predicate` and returns the number
        /// removed. Order of the remaining entries is preserved.
        pub fn sweep(self: *Self, context: anytype, comptime predicate: fn (@TypeOf(context), K, V) bool) usize {
            var removed: usize = 0;
            var index: usize = 0;
            while (index < self.inner.count()) {
                const key = self.inner.keys()[index];
                const value = self.inner.values()[index];
                if (predicate(context, key, value)) {
                    _ = self.inner.orderedRemove(key);
                    removed += 1;
                } else {
                    index += 1;
                }
            }
            return removed;
        }

        pub fn size(self: Self) usize {
            return self.inner.count();
        }

        pub fn isEmpty(self: Self) bool {
            return self.inner.count() == 0;
        }

        /// Live key/value slices in insertion order. They are invalidated by any
        /// mutation, exactly like iterating a discord.js Collection during edits.
        pub fn keys(self: Self) []K {
            return self.inner.keys();
        }

        pub fn values(self: Self) []V {
            return self.inner.values();
        }

        /// Owned snapshot of values in insertion order.
        pub fn toArray(self: Self, allocator: std.mem.Allocator) ![]V {
            return allocator.dupe(V, self.inner.values());
        }

        /// Owned snapshot of keys in insertion order.
        pub fn keyArray(self: Self, allocator: std.mem.Allocator) ![]K {
            return allocator.dupe(K, self.inner.keys());
        }

        pub fn at(self: Self, index: usize) ?V {
            const items = self.inner.values();
            return if (index < items.len) items[index] else null;
        }

        pub fn keyAt(self: Self, index: usize) ?K {
            const items = self.inner.keys();
            return if (index < items.len) items[index] else null;
        }

        pub fn first(self: Self) ?V {
            return self.at(0);
        }

        pub fn firstKey(self: Self) ?K {
            return self.keyAt(0);
        }

        pub fn last(self: Self) ?V {
            const items = self.inner.values();
            return if (items.len == 0) null else items[items.len - 1];
        }

        pub fn lastKey(self: Self) ?K {
            const items = self.inner.keys();
            return if (items.len == 0) null else items[items.len - 1];
        }

        pub fn clone(self: Self, allocator: std.mem.Allocator) !Self {
            var result = Self.init(allocator);
            errdefer result.deinit();
            const ks = self.inner.keys();
            const vs = self.inner.values();
            for (ks, vs) |key, value| try result.set(key, value);
            return result;
        }

        pub fn concat(self: Self, allocator: std.mem.Allocator, others: []const Self) !Self {
            var result = try self.clone(allocator);
            errdefer result.deinit();
            for (others) |other| {
                const ks = other.inner.keys();
                const vs = other.inner.values();
                for (ks, vs) |key, value| try result.set(key, value);
            }
            return result;
        }

        pub fn equals(self: Self, other: Self) bool {
            if (self.size() != other.size()) return false;
            const ks = self.inner.keys();
            const vs = self.inner.values();
            for (ks, vs) |key, value| {
                const other_value = other.get(key) orelse return false;
                if (!std.meta.eql(value, other_value)) return false;
            }
            return true;
        }

        pub fn difference(self: Self, allocator: std.mem.Allocator, other: Self) !Self {
            var result = Self.init(allocator);
            errdefer result.deinit();
            const ks = self.inner.keys();
            const vs = self.inner.values();
            for (ks, vs) |key, value| {
                if (!other.has(key)) try result.set(key, value);
            }
            return result;
        }

        pub fn intersection(self: Self, allocator: std.mem.Allocator, other: Self) !Self {
            var result = Self.init(allocator);
            errdefer result.deinit();
            const ks = self.inner.keys();
            const vs = self.inner.values();
            for (ks, vs) |key, value| {
                if (other.has(key)) try result.set(key, value);
            }
            return result;
        }

        pub fn symmetricDifference(self: Self, allocator: std.mem.Allocator, other: Self) !Self {
            var result = try self.difference(allocator, other);
            errdefer result.deinit();
            const ks = other.inner.keys();
            const vs = other.inner.values();
            for (ks, vs) |key, value| {
                if (!self.has(key)) try result.set(key, value);
            }
            return result;
        }

        /// Returns the first value whose `(key, value)` satisfies `predicate`.
        pub fn find(self: Self, context: anytype, comptime predicate: fn (@TypeOf(context), K, V) bool) ?V {
            const ks = self.inner.keys();
            const vs = self.inner.values();
            for (ks, vs) |key, value| {
                if (predicate(context, key, value)) return value;
            }
            return null;
        }

        /// Returns the first key whose `(key, value)` satisfies `predicate`.
        pub fn findKey(self: Self, context: anytype, comptime predicate: fn (@TypeOf(context), K, V) bool) ?K {
            const ks = self.inner.keys();
            const vs = self.inner.values();
            for (ks, vs) |key, value| {
                if (predicate(context, key, value)) return key;
            }
            return null;
        }

        pub fn some(self: Self, context: anytype, comptime predicate: fn (@TypeOf(context), K, V) bool) bool {
            return self.findKey(context, predicate) != null;
        }

        pub fn every(self: Self, context: anytype, comptime predicate: fn (@TypeOf(context), K, V) bool) bool {
            const ks = self.inner.keys();
            const vs = self.inner.values();
            for (ks, vs) |key, value| {
                if (!predicate(context, key, value)) return false;
            }
            return true;
        }

        pub fn forEach(self: Self, context: anytype, comptime action: fn (@TypeOf(context), K, V) void) void {
            const ks = self.inner.keys();
            const vs = self.inner.values();
            for (ks, vs) |key, value| action(context, key, value);
        }

        /// Builds a new collection holding only the entries that satisfy
        /// `predicate`. The caller owns the result and must `deinit` it.
        pub fn filter(
            self: Self,
            allocator: std.mem.Allocator,
            context: anytype,
            comptime predicate: fn (@TypeOf(context), K, V) bool,
        ) !Self {
            var result = Self.init(allocator);
            errdefer result.deinit();
            const ks = self.inner.keys();
            const vs = self.inner.values();
            for (ks, vs) |key, value| {
                if (predicate(context, key, value)) try result.set(key, value);
            }
            return result;
        }

        /// Maps each entry to an `R` in insertion order. The caller owns the
        /// returned slice and must free it with the same allocator.
        pub fn map(
            self: Self,
            allocator: std.mem.Allocator,
            comptime R: type,
            context: anytype,
            comptime transform: fn (@TypeOf(context), K, V) R,
        ) ![]R {
            const ks = self.inner.keys();
            const vs = self.inner.values();
            const out = try allocator.alloc(R, ks.len);
            for (ks, vs, 0..) |key, value, index| {
                out[index] = transform(context, key, value);
            }
            return out;
        }

        /// Folds the entries into a single accumulator in insertion order.
        pub fn reduce(
            self: Self,
            comptime R: type,
            initial: R,
            context: anytype,
            comptime folder: fn (@TypeOf(context), R, K, V) R,
        ) R {
            var accumulator = initial;
            const ks = self.inner.keys();
            const vs = self.inner.values();
            for (ks, vs) |key, value| {
                accumulator = folder(context, accumulator, key, value);
            }
            return accumulator;
        }
    };
}

const TestHelpers = struct {
    fn isEvenKey(_: void, key: u64, _: []const u8) bool {
        return key % 2 == 0;
    }

    fn startsWithB(_: void, _: u64, value: []const u8) bool {
        return value.len != 0 and value[0] == 'b';
    }

    fn valueLen(_: void, _: u64, value: []const u8) usize {
        return value.len;
    }

    fn sumLen(_: void, accumulator: usize, _: u64, value: []const u8) usize {
        return accumulator + value.len;
    }

    fn isNonEmpty(_: void, _: u64, value: []const u8) bool {
        return value.len != 0;
    }

    fn removeEvenKey(_: void, key: u64, _: []const u8) bool {
        return key % 2 == 0;
    }
};

test "collection stores ordered entries with map semantics" {
    var collection = Collection(u64, []const u8).init(std.testing.allocator);
    defer collection.deinit();

    try std.testing.expect(collection.isEmpty());
    try collection.set(10, "alpha");
    try collection.set(21, "beta");
    try collection.set(32, "gamma");

    try std.testing.expectEqual(@as(usize, 3), collection.size());
    try std.testing.expect(collection.has(21));
    try std.testing.expectEqualStrings("beta", collection.get(21).?);
    try std.testing.expect(collection.get(99) == null);

    // Insertion order is preserved.
    try std.testing.expectEqualStrings("alpha", collection.first().?);
    try std.testing.expectEqualStrings("gamma", collection.last().?);
    try std.testing.expectEqual(@as(u64, 10), collection.firstKey().?);
    try std.testing.expectEqual(@as(u64, 32), collection.lastKey().?);
    try std.testing.expectEqualStrings("beta", collection.at(1).?);
    try std.testing.expect(collection.at(3) == null);

    // Replacing a key keeps its position and updates the value.
    try collection.set(21, "BETA");
    try std.testing.expectEqualStrings("BETA", collection.at(1).?);
    try std.testing.expectEqual(@as(usize, 3), collection.size());
}

test "collection delete preserves order and reports presence" {
    var collection = Collection(u64, []const u8).init(std.testing.allocator);
    defer collection.deinit();

    try collection.set(1, "a");
    try collection.set(2, "b");
    try collection.set(3, "c");

    try std.testing.expect(collection.delete(2));
    try std.testing.expect(!collection.delete(2));
    try std.testing.expectEqual(@as(usize, 2), collection.size());
    try std.testing.expectEqualStrings("a", collection.at(0).?);
    try std.testing.expectEqualStrings("c", collection.at(1).?);

    collection.clear();
    try std.testing.expect(collection.isEmpty());
}

test "collection ensure clone concat equals sweep and snapshots" {
    var collection = Collection(u64, []const u8).init(std.testing.allocator);
    defer collection.deinit();

    try std.testing.expectEqualStrings("one", try collection.ensure(1, "one"));
    try std.testing.expectEqualStrings("one", try collection.ensure(1, "uno"));
    try collection.set(2, "two");

    const values = try collection.toArray(std.testing.allocator);
    defer std.testing.allocator.free(values);
    try std.testing.expectEqualSlices([]const u8, &.{ "one", "two" }, values);

    const keys = try collection.keyArray(std.testing.allocator);
    defer std.testing.allocator.free(keys);
    try std.testing.expectEqualSlices(u64, &.{ 1, 2 }, keys);

    var clone = try collection.clone(std.testing.allocator);
    defer clone.deinit();
    try std.testing.expect(collection.equals(clone));

    var extra = Collection(u64, []const u8).init(std.testing.allocator);
    defer extra.deinit();
    try extra.set(3, "three");
    try extra.set(1, "ONE");
    const others = [_]Collection(u64, []const u8){extra};
    var concatenated = try collection.concat(std.testing.allocator, &others);
    defer concatenated.deinit();
    try std.testing.expectEqual(@as(usize, 3), concatenated.size());
    try std.testing.expectEqualStrings("ONE", concatenated.get(1).?);

    try std.testing.expectEqual(@as(usize, 1), concatenated.sweep({}, TestHelpers.removeEvenKey));
    try std.testing.expect(!concatenated.has(2));
}

test "collection set operations mirror discordjs collection helpers" {
    var left = Collection(u64, []const u8).init(std.testing.allocator);
    defer left.deinit();
    try left.set(1, "one");
    try left.set(2, "two");
    try left.set(3, "three");

    var right = Collection(u64, []const u8).init(std.testing.allocator);
    defer right.deinit();
    try right.set(2, "TWO");
    try right.set(4, "four");

    var diff = try left.difference(std.testing.allocator, right);
    defer diff.deinit();
    try std.testing.expectEqual(@as(usize, 2), diff.size());
    try std.testing.expectEqualStrings("one", diff.get(1).?);
    try std.testing.expectEqualStrings("three", diff.get(3).?);

    var intersection = try left.intersection(std.testing.allocator, right);
    defer intersection.deinit();
    try std.testing.expectEqual(@as(usize, 1), intersection.size());
    try std.testing.expectEqualStrings("two", intersection.get(2).?);

    var symmetric = try left.symmetricDifference(std.testing.allocator, right);
    defer symmetric.deinit();
    try std.testing.expectEqual(@as(usize, 3), symmetric.size());
    try std.testing.expectEqualStrings("one", symmetric.get(1).?);
    try std.testing.expectEqualStrings("three", symmetric.get(3).?);
    try std.testing.expectEqualStrings("four", symmetric.get(4).?);
}

test "collection functional helpers find filter map and reduce" {
    var collection = Collection(u64, []const u8).init(std.testing.allocator);
    defer collection.deinit();

    try collection.set(10, "alpha");
    try collection.set(21, "beta");
    try collection.set(32, "gamma");

    try std.testing.expectEqualStrings("alpha", collection.find({}, TestHelpers.isEvenKey).?);
    try std.testing.expectEqual(@as(u64, 21), collection.findKey({}, TestHelpers.startsWithB).?);
    try std.testing.expect(collection.some({}, TestHelpers.startsWithB));
    try std.testing.expect(collection.every({}, TestHelpers.isNonEmpty));
    try std.testing.expect(!collection.every({}, TestHelpers.isEvenKey));

    var even = try collection.filter(std.testing.allocator, {}, TestHelpers.isEvenKey);
    defer even.deinit();
    try std.testing.expectEqual(@as(usize, 2), even.size());
    try std.testing.expectEqualStrings("alpha", even.at(0).?);
    try std.testing.expectEqualStrings("gamma", even.at(1).?);

    const lengths = try collection.map(std.testing.allocator, usize, {}, TestHelpers.valueLen);
    defer std.testing.allocator.free(lengths);
    try std.testing.expectEqualSlices(usize, &.{ 5, 4, 5 }, lengths);

    try std.testing.expectEqual(@as(usize, 14), collection.reduce(usize, 0, {}, TestHelpers.sumLen));
}
