const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn LRUCache(comptime K: type, comptime V: type) type {
    const is_string_key = switch (@typeInfo(K)) {
        .array => |arr| arr.child == u8,
        .pointer => |ptr| ptr.size == .slice and ptr.child == u8,
        else => false,
    };

    const List = std.DoublyLinkedList;
    const kv_type = struct {
        key: K,
        value: V,
        node: List.Node = .{},
    };
    const Map = if (is_string_key) std.StringHashMap(*kv_type) else std.AutoHashMap(K, *kv_type);

    return struct {
        const Self = @This();
        pub const KV = kv_type;
        pub const EvictedKV = struct {
            key: K,
            value: V,

            /// 如果是相同 Key 淘汰下来的旧键值对, 则该字段为 `true`,
            /// 这时候代表这个相同的 Key 还会继续被使用, 所以不能释放这个 Key.
            is_same_key: bool = false,

            _ctx: *Self,

            pub fn deinit(self: EvictedKV) void {
                if (!self.is_same_key) {
                    self._ctx.deinitKey(self.key);
                }
                self._ctx.deinitValue(self.value);
            }
        };
        pub const ValueAndEvictedKV = struct {
            value: *V,
            /// 如果存在淘汰的KV, 则会为此赋值
            evicted: ?EvictedKV = null,
        };

        pub const InitKeyFn = *const fn (allocator: Allocator, key: K) anyerror!K;
        pub const DeinitKeyFn = *const fn (allocator: Allocator, key: K) void;
        pub const InitValueFn = *const fn (allocator: Allocator, value: V) anyerror!V;
        pub const DeinitValueFn = *const fn (allocator: Allocator, value: V) void;
        pub const DefaultFns = struct {
            /// dupe a same string
            pub fn initDupeString(allocator: Allocator, key: []const u8) ![]const u8 {
                return try allocator.dupe(u8, key);
            }

            /// just free a string
            pub fn deinitString(allocator: Allocator, key: []const u8) void {
                allocator.free(key);
            }

            /// just return origin key
            pub fn initKeyJustReturn(_: Allocator, key: K) !K {
                return key;
            }

            /// do noting, free nothing,
            pub fn deinitKeyNoting(_: Allocator, _: K) void {}

            /// just return origin value
            pub fn initValueJustReturn(_: Allocator, value: V) !V {
                return value;
            }

            /// do noting, free noting
            pub fn deinitValueNoting(_: Allocator, _: V) void {}
        };

        pub const Init = struct {
            allocator: Allocator,
            io: std.Io,
            capacity: usize,
            initKeyFn: InitKeyFn = &DefaultFns.initKeyJustReturn,
            deinitKeyFn: DeinitKeyFn = &DefaultFns.deinitKeyNoting,
            initValueFn: InitValueFn = &DefaultFns.initValueJustReturn,
            deinitValueFn: DeinitValueFn = &DefaultFns.deinitValueNoting,
        };

        allocator: Allocator,
        io: std.Io,
        map: Map,
        list: List,
        capacity: usize,
        mutex: std.Io.Mutex = .init,

        initKeyFn: InitKeyFn,
        deinitKeyFn: DeinitKeyFn,
        initValueFn: InitValueFn,
        deinitValueFn: DeinitValueFn,

        pub fn init(opt: Init) !Self {
            return .{
                .io = opt.io,
                .allocator = opt.allocator,
                .capacity = opt.capacity,
                .map = Map.init(opt.allocator),
                .list = List{},
                .initKeyFn = opt.initKeyFn,
                .deinitKeyFn = opt.deinitKeyFn,
                .initValueFn = opt.initValueFn,
                .deinitValueFn = opt.deinitValueFn,
            };
        }

        pub fn deinit(self: *Self) void {
            defer self.map.deinit();
            var iter = self.map.valueIterator();
            while (iter.next()) |kvp| {
                var kv = kvp.*;
                self.list.remove(&kv.node);
                self.deinitKV(kv);
                self.allocator.destroy(kv);
            }
        }

        fn lock(self: *Self) void {
            self.mutex.lockUncancelable(self.io);
        }

        fn unlock(self: *Self) void {
            self.mutex.unlock(self.io);
        }

        pub fn initKey(self: *Self, key: K) !K {
            return try self.initKeyFn(self.allocator, key);
        }

        pub fn deinitKey(self: *Self, key: K) void {
            self.deinitKeyFn(self.allocator, key);
        }

        pub fn initValue(self: *Self, value: V) !V {
            return try self.initValueFn(self.allocator, value);
        }

        pub fn deinitValue(self: *Self, value: V) void {
            self.deinitValueFn(self.allocator, value);
        }

        pub fn deinitKV(self: *Self, kv: *KV) void {
            self.deinitKey(kv.key);
            self.deinitValue(kv.value);
        }

        pub fn has(self: *Self, key: K) bool {
            self.lock();
            defer self.unlock();

            return self.map.contains(key);
        }

        pub fn get(self: *Self, key: K) ?V {
            return if (self.getPtr(key)) |ret|
                ret.*
            else
                null;
        }

        pub fn getPtr(self: *Self, key: K) ?*V {
            self.lock();
            defer self.unlock();

            if (self.map.getPtr(key)) |pptr| {
                var ptr = pptr.*;

                self.list.remove(&ptr.node);
                self.list.prepend(&ptr.node);
                return &ptr.value;
            }
            return null;
        }

        pub fn fetchGet(self: *Self, key: K, function: anytype, args: anytype) !?V {
            self.lock();
            defer self.unlock();

            if (self.map.getPtr(key)) |pptr| {
                var ptr = pptr.*;

                self.list.remove(&ptr.node);
                self.list.prepend(&ptr.node);
                try @call(.auto, function, .{ self, &ptr.value } ++ args);
                return ptr.value;
            }
            return null;
        }

        pub fn fetchPut(self: *Self, key: K, value: V, callback: anytype, args: anytype) !?EvictedKV {
            const ret = try self.putAndGet(key, value);
            defer if (ret.evicted) |*evicted| {
                evicted.deinit();
            };

            self.lock();
            defer self.unlock();

            try @call(.auto, callback, .{ self, ret.value } ++ args);

            return ret.evicted;
        }

        pub fn putAndGet(self: *Self, key: K, value: V) !ValueAndEvictedKV {
            self.lock();
            defer self.unlock();

            // same key
            if (self.map.getPtr(key)) |pptr| {
                var ptr = pptr.*;
                const old_key = ptr.key;
                const old_value = ptr.value;
                ptr.value = try self.initValue(value);
                self.list.remove(&ptr.node);
                self.list.prepend(&ptr.node);

                return .{
                    .value = &ptr.value,
                    .evicted = .{
                        ._ctx = self,
                        .key = old_key,
                        .value = old_value,
                        .is_same_key = true,
                    },
                };
            }

            // check capacity and evict last node.
            var evicted: ?EvictedKV = null;
            if (self.map.count() >= self.capacity) {
                evicted = self.evictUnlocked();
            }
            errdefer if (evicted) |kv| kv.deinit();

            // add new node
            const kv = try self.allocator.create(KV);
            errdefer self.allocator.destroy(kv);
            const self_key = try self.initKey(key);
            errdefer self.deinitKey(self_key);
            const self_value = try self.initValue(value);
            errdefer self.deinitValue(self_value);

            kv.* = .{ .key = self_key, .value = self_value };
            try self.map.put(self_key, kv);
            self.list.prepend(&kv.node);

            return .{
                .value = &kv.value,
                .evicted = evicted,
            };
        }

        /// 替换出来的KV不会释放, 需要自己按需释放
        pub fn put(self: *Self, key: K, value: V) !?EvictedKV {
            return (try self.putAndGet(key, value)).evicted;
        }

        /// 不会释放 Key / Value, 调用者可能会用到, 所以调用者自己用相应的释放方法释放.
        pub fn evict(self: *Self) ?EvictedKV {
            self.mutex.lockUncancelable(self.io);
            defer self.mutex.unlock(self.io);
            return self.evictUnlocked();
        }

        fn evictUnlocked(self: *Self) ?EvictedKV {
            if (self.list.pop()) |last| {
                const prev: *KV = @fieldParentPtr("node", last);
                defer self.allocator.destroy(prev);
                _ = self.map.remove(prev.key);
                return .{
                    ._ctx = self,
                    .key = prev.key,
                    .value = prev.value,
                    .is_same_key = false,
                };
            }
            return null;
        }

        pub fn count(self: *Self) usize {
            self.lock();
            defer self.unlock();

            return self.map.count();
        }
    };
}

test "simple string LRU" {
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;
    const expectEqual = std.testing.expectEqual;
    const Map = LRUCache([]const u8, usize);
    var map = try Map.init(.{
        .io = std.testing.io,
        .allocator = allocator,
        .capacity = 2,
    });
    defer map.deinit();

    var kv: *Map.KV = undefined;
    var evicted = try map.put("a", 1);
    try expectEqual(1, map.count());
    try expect(map.list.first != null);
    try expect(evicted == null);

    evicted = try map.put("b", 2);
    try expectEqual(2, map.count());
    try expect(map.list.first != null);
    kv = @fieldParentPtr("node", map.list.first.?);
    try expectEqual(2, kv.value);
    try expect(evicted == null);

    evicted = try map.put("a", 3);
    try expectEqual(2, map.count());
    try expect(map.list.first != null);
    kv = @fieldParentPtr("node", map.list.first.?);
    try expectEqual(3, kv.value);
    try expect(evicted != null);
    try expectEqual(1, evicted.?.value);
    evicted.?.deinit();

    const v = map.get("b");
    try expect(v != null);
    try expectEqual(2, v.?);
    try expectEqual(2, map.count());
    try expect(map.list.first != null);
    kv = @fieldParentPtr("node", map.list.first.?);
    try expectEqual(2, kv.value);

    // "a" out
    evicted = try map.put("c", 4);
    try expectEqual(2, map.count());
    try expect(map.list.first != null);
    kv = @fieldParentPtr("node", map.list.first.?);
    try expectEqual(4, kv.value);
    try expect(evicted != null);
    try expectEqual(3, evicted.?.value);
    evicted.?.deinit();
}

test "dupe string key LRU" {
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;
    const expectEqual = std.testing.expectEqual;
    const Map = LRUCache([]const u8, usize);
    var map = try Map.init(.{
        .io = std.testing.io,
        .allocator = allocator,
        .capacity = 2,
        .deinitKeyFn = Map.DefaultFns.deinitString,
        .initKeyFn = Map.DefaultFns.initDupeString,
    });
    defer map.deinit();

    var kv: *Map.KV = undefined;
    var evicted = try map.put("a", 1);
    try expectEqual(1, map.count());
    try expect(map.list.first != null);
    try expect(evicted == null);

    evicted = try map.put("b", 2);
    try expectEqual(2, map.count());
    try expect(map.list.first != null);
    kv = @fieldParentPtr("node", map.list.first.?);
    try expectEqual(2, kv.value);
    try expect(evicted == null);

    evicted = try map.put("a", 3);
    try expectEqual(2, map.count());
    try expect(map.list.first != null);
    kv = @fieldParentPtr("node", map.list.first.?);
    try expectEqual(3, kv.value);
    try expect(evicted != null);
    try expectEqual(1, evicted.?.value);
    evicted.?.deinit();

    const v = map.get("b");
    try expect(v != null);
    try expectEqual(2, v.?);
    try expectEqual(2, map.count());
    try expect(map.list.first != null);
    kv = @fieldParentPtr("node", map.list.first.?);
    try expectEqual(2, kv.value);

    // "a" out
    evicted = try map.put("c", 4);
    try expectEqual(2, map.count());
    try expect(map.list.first != null);
    kv = @fieldParentPtr("node", map.list.first.?);
    try expectEqual(4, kv.value);
    try expect(evicted != null);
    try expectEqual(3, evicted.?.value);
    evicted.?.deinit();
}
