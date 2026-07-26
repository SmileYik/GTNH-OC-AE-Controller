const std = @import("std");
const Allocator = std.mem.Allocator;
const json = std.json;
const RwLock = std.Io.RwLock;

pub const NamespaceData = struct {
    allocator: ?Allocator = null,
    namespace: []const u8,
    token: []const u8,
    expire_time: i64,

    pub const Json = struct {
        namespace: []const u8,
        token: []const u8,
        expire_time: i64,
    };

    pub fn deinit(self: NamespaceData) void {
        defer if (self.allocator) |allocator| {
            allocator.free(self.namespace);
            allocator.free(self.token);
        };
    }

    pub fn isExpire(self: NamespaceData, io: std.Io) bool {
        const now = std.Io.Timestamp.now(io, .real).toMilliseconds();
        return now > self.expire_time;
    }

    pub fn renew(self: *NamespaceData, io: std.Io, duration_seconds: i64) void {
        const next_expire_time = std.Io.Timestamp.now(io, .real).addDuration(.fromSeconds(duration_seconds)).toMilliseconds();
        self.expire_time = next_expire_time;
    }

    pub fn dupe(self: NamespaceData, gpa: Allocator) !NamespaceData {
        const namespace = try gpa.dupe(u8, self.namespace);
        errdefer gpa.free(namespace);
        const token = try gpa.dupe(u8, self.token);
        errdefer gpa.free(token);
        return .{
            .allocator = gpa,
            .namespace = namespace,
            .token = token,
            .expire_time = self.expire_time,
        };
    }

    pub fn jsonStringify(self: NamespaceData, jws: anytype) !void {
        try jws.beginObject();
        try jws.objectField("namespace");
        try jws.write(self.namespace);
        try jws.objectField("token");
        try jws.write(self.token);
        try jws.objectField("expire_time");
        try jws.write(self.expire_time);
        try jws.endObject();
    }

    pub fn format(self: NamespaceData, writer: *std.Io.Writer) !void {
        try writer.print(
            "NamespaceData {{ .namespace = {s}, .token = {s}, .expire_time = {d} }}",
            .{ self.namespace, self.token, self.expire_time },
        );
    }
};

pub const NamespaceVTable = struct {
    getFn: *const fn (self: *anyopaque, gpa: Allocator, namespace: []const u8) anyerror!?NamespaceData,
    putFn: *const fn (self: *anyopaque, namespace: *const NamespaceData) anyerror!bool,
    renew: *const fn (self: *anyopaque, namespace: []const u8) anyerror!void,
    deinitFn: *const fn (self: *anyopaque) anyerror!void,
};

pub const NamespaceService = struct {
    const Self = @This();

    io: std.Io,
    ctx: *anyopaque,
    vtable: *const NamespaceVTable,
    generator: *NamespaceGenerator,

    pub fn newNamespace(self: Self, gpa: Allocator, duration_seconds: i64) !NamespaceData {
        const namespace = try self.generator.nextNamespace(gpa);
        errdefer gpa.free(namespace);
        const token = try self.generator.nextToken(gpa);
        errdefer gpa.free(token);
        return .{
            .namespace = namespace,
            .token = token,
            .expire_time = std.Io.Timestamp.now(self.io, .real).addDuration(.fromSeconds(duration_seconds)).toMilliseconds(),
            .allocator = gpa,
        };
    }

    pub fn get(self: *Self, gpa: Allocator, namespace: []const u8) !?NamespaceData {
        return self.vtable.getFn(self.ctx, gpa, namespace);
    }

    pub fn put(self: *Self, namespace: *const NamespaceData) !bool {
        return self.vtable.putFn(self.ctx, namespace);
    }

    pub fn renew(self: *Self, namespace: []const u8) !void {
        return self.vtable.renew(self.ctx, namespace);
    }

    pub fn deinit(self: *Self) !void {
        return self.vtable.deinitFn(self.ctx);
    }
};

pub const NamespaceFile = struct {
    const Self = @This();
    pub const Namespaces = std.StringHashMap(NamespaceData);
    pub const NamespaceList = std.ArrayList(NamespaceData);
    pub const Cleaner = struct {
        ptr: *anyopaque,
        cleanFn: ?*const fn (ptr: *anyopaque, key: []const u8) anyerror!void = null,
    };
    pub const Init = struct {
        allocator: Allocator,
        io: std.Io,
        file: []const u8,
        duration_seconds: i64 = 7 * 24 * 60 * 60,
        cleaner: ?Cleaner = null,
    };

    allocator: Allocator,
    io: std.Io,
    file: []const u8,
    namespaces: Namespaces,
    duration_seconds: i64,
    cleaner: ?Cleaner = null,

    mutex: RwLock = RwLock.init,

    fn get(self: *Self, gpa: Allocator, namespace: []const u8) !?NamespaceData {
        self.mutex.lockSharedUncancelable(self.io);
        defer self.mutex.unlockShared(self.io);

        return if (self.namespaces.getPtr(namespace)) |ptr|
            try ptr.dupe(gpa)
        else
            null;
    }

    /// will copy a same one hold by self.
    fn put(self: *Self, namespace: *const NamespaceData) !bool {
        {
            self.mutex.lockUncancelable(self.io);
            defer self.mutex.unlock(self.io);

            if (self.namespaces.contains(namespace.namespace)) {
                return false;
            }

            var elem = try namespace.dupe(self.allocator);
            errdefer elem.deinit();

            try self.namespaces.put(elem.namespace, elem);
        }
        try self.store();

        return true;
    }

    fn renew(self: *Self, namespace: []const u8) !void {
        self.mutex.lockUncancelable(self.io);
        defer self.mutex.unlock(self.io);

        if (self.namespaces.getPtr(namespace)) |ns|
            ns.renew(self.io, self.duration_seconds);
    }

    fn deinit(self: *Self) !void {
        try self.store();
        self.freeNamespaces();
        self.namespaces.deinit();
    }

    pub fn vtable() NamespaceVTable {
        const t = struct {
            fn get(ctx: *anyopaque, gpa: Allocator, namespace: []const u8) anyerror!?NamespaceData {
                var self: *Self = @ptrCast(@alignCast(ctx));
                return try self.get(gpa, namespace);
            }

            fn put(ctx: *anyopaque, namespace: *const NamespaceData) !bool {
                var self: *Self = @ptrCast(@alignCast(ctx));
                return try self.put(namespace);
            }

            fn renew(ctx: *anyopaque, namespace: []const u8) !void {
                var self: *Self = @ptrCast(@alignCast(ctx));
                return try self.renew(namespace);
            }

            fn deinit(ctx: *anyopaque) !void {
                var self: *Self = @ptrCast(@alignCast(ctx));
                try self.deinit();
            }
        };
        return .{
            .getFn = t.get,
            .putFn = t.put,
            .renew = t.renew,
            .deinitFn = t.deinit,
        };
    }

    pub fn init(config: Init) !NamespaceFile {
        var instance = NamespaceFile{
            .allocator = config.allocator,
            .io = config.io,
            .file = config.file,
            .namespaces = Namespaces.init(config.allocator),
            .duration_seconds = config.duration_seconds,
            .cleaner = config.cleaner,
        };
        try instance.load();
        return instance;
    }

    pub fn store(self: *Self) !void {
        try self.initFile();

        var list = try NamespaceList.initCapacity(self.allocator, self.namespaces.capacity());
        defer list.deinit(self.allocator);

        var wait_remove = try std.ArrayList([]const u8).initCapacity(self.allocator, self.namespaces.capacity());
        defer wait_remove.deinit(self.allocator);

        {
            self.mutex.lockSharedUncancelable(self.io);
            defer self.mutex.unlockShared(self.io);

            var iter = self.namespaces.iterator();
            while (iter.next()) |entry| {
                if (entry.value_ptr.isExpire(self.io)) {
                    try wait_remove.append(self.allocator, entry.key_ptr.*);
                } else {
                    try list.append(self.allocator, entry.value_ptr.*);
                }
            }
        }

        const tmp_file = try std.fmt.allocPrint(self.allocator, "{s}.tmp", .{self.file});
        defer self.allocator.free(tmp_file);

        const cwd = std.Io.Dir.cwd();
        {
            const file = try cwd.createFile(self.io, tmp_file, .{ .truncate = true });
            file.close(self.io);
        }

        var file = try cwd.openFile(self.io, tmp_file, .{ .mode = .write_only });
        defer file.close(self.io);

        var buf: [8192]u8 = undefined;
        @memset(&buf, 0);
        var writer = file.writerStreaming(self.io, &buf);

        try std.Io.Writer.print(&writer.interface, "{f}", .{json.fmt(list.items, .{})});
        try writer.end();
        try cwd.rename(tmp_file, cwd, self.file, self.io);

        if (wait_remove.items.len > 0) {
            self.mutex.lockUncancelable(self.io);
            defer self.mutex.unlock(self.io);

            for (wait_remove.items) |key| {
                if (self.namespaces.getPtr(key)) |ns| {
                    if (ns.isExpire(self.io)) {
                        if (self.cleaner) |c| {
                            if (c.cleanFn) |fn_ptr| {
                                try fn_ptr(c.ptr, ns.namespace);
                            }
                        }

                        if (self.namespaces.fetchRemove(key)) |kv| {
                            kv.value.deinit();
                        }
                    }
                }
            }
        }
    }

    fn load(self: *Self) !void {
        try self.initFile();
        const data = try std.Io.Dir.cwd().readFileAlloc(self.io, self.file, self.allocator, .unlimited);
        defer self.allocator.free(data);

        self.freeNamespaces();
        if (data.len != 0) {
            const parsed = try json.parseFromSlice([]NamespaceData.Json, self.allocator, data, .{
                .allocate = .alloc_if_needed,
                .ignore_unknown_fields = true,
            });
            defer parsed.deinit();

            errdefer self.freeNamespaces();
            for (parsed.value) |elem| {
                const no_json = NamespaceData{
                    .namespace = elem.namespace,
                    .token = elem.token,
                    .expire_time = elem.expire_time,
                };
                var namespace = try no_json.dupe(self.allocator);
                errdefer namespace.deinit();
                try self.namespaces.put(namespace.namespace, namespace);
            }
        }
    }

    fn freeNamespaces(self: *Self) void {
        var iter = self.namespaces.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.deinit();
        }
        self.namespaces.clearAndFree();
    }

    fn initFile(self: Self) !void {
        const cwd = std.Io.Dir.cwd();
        const parent = std.fs.path.dirname(self.file);
        if (parent) |dir| {
            try cwd.createDirPath(self.io, dir);
        }

        const file = try cwd.createFile(self.io, self.file, .{ .truncate = false });
        file.close(self.io);
    }

    test "init" {
        const seed: u64 = @intCast(std.Io.Timestamp.now(std.testing.io, .real).toMilliseconds());
        var default_g = DefaultNamespaceGenerator.init(.{
            .prng = std.Random.DefaultPrng.init(seed),
            .namespace_len = 32,
            .token_len = 16,
        });
        var generator: NamespaceGenerator = .{
            .ctx = &default_g,
            .vtable = &DefaultNamespaceGenerator.vtable,
        };
        var namespace_file = try NamespaceFile.init(.{
            .allocator = std.testing.allocator,
            .io = std.testing.io,
            .file = "./test/namespaces.json",
        });
        var namespace_service: NamespaceService = .{
            .ctx = &namespace_file,
            .vtable = &NamespaceFile.vtable(),
            .io = std.testing.io,
            .generator = &generator,
        };
        defer namespace_service.deinit() catch |e| {
            std.log.debug("{any}", .{e});
        };

        var new_namespace = try namespace_service.newNamespace(namespace_file.allocator, 24 * 3600);
        defer new_namespace.deinit();

        std.debug.print("{f}\n", .{new_namespace});

        _ = try namespace_service.put(&new_namespace);
    }
};

pub const NamespaceGeneratorVTable = struct {
    nextTokenFn: *const fn (ctx: *anyopaque, gpa: Allocator) anyerror![]const u8,
    nextNamespaceFn: *const fn (ctx: *anyopaque, gpa: Allocator) anyerror![]const u8,
};

pub const NamespaceGenerator = struct {
    ctx: *anyopaque,
    vtable: *const NamespaceGeneratorVTable,

    const Self = @This();

    pub fn nextToken(self: Self, gpa: Allocator) ![]const u8 {
        return self.vtable.nextTokenFn(self.ctx, gpa);
    }

    pub fn nextNamespace(self: Self, gpa: Allocator) ![]const u8 {
        return self.vtable.nextNamespaceFn(self.ctx, gpa);
    }
};

pub const DefaultNamespaceGenerator = struct {
    pub const vtable = NamespaceGeneratorVTable{
        .nextNamespaceFn = nextNamespace,
        .nextTokenFn = nextToken,
    };
    const Self = @This();

    pub const Config = struct {
        candidate: []const u8 = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_",
        // a random instance
        csprng: ?std.Random.DefaultCsprng = null,
        prng: ?std.Random.DefaultPrng = null,
        token_len: u8 = 16,
        namespace_len: u16 = 32,
    };

    candidate: []const u8,
    csprng: ?std.Random.DefaultCsprng,
    prng: ?std.Random.DefaultPrng,
    token_len: u8,
    namespace_len: u16,

    pub fn init(config: Config) DefaultNamespaceGenerator {
        return .{
            .candidate = config.candidate,
            .prng = config.prng,
            .csprng = config.csprng,
            .token_len = config.token_len,
            .namespace_len = config.namespace_len,
        };
    }

    pub fn nextToken(ctx: *anyopaque, gpa: Allocator) ![]const u8 {
        var self: *DefaultNamespaceGenerator = @ptrCast(@alignCast(ctx));
        return self.next(gpa, self.token_len);
    }

    pub fn nextNamespace(ctx: *anyopaque, gpa: Allocator) ![]const u8 {
        var self: *DefaultNamespaceGenerator = @ptrCast(@alignCast(ctx));
        return self.next(gpa, self.namespace_len);
    }

    fn next(self: *Self, gpa: Allocator, len: u32) ![]const u8 {
        const buf: []u8 = try gpa.alloc(u8, len);
        errdefer gpa.free(buf);

        const rand = try self.random();
        std.Random.bytes(rand, buf);

        const candidate_len = self.candidate.len;
        for (buf) |*byte| {
            byte.* = self.candidate[std.Random.uintLessThan(rand, usize, candidate_len)];
        }

        return buf;
    }

    fn random(self: *Self) !std.Random {
        return if (self.csprng) |*csprng|
            csprng.random()
        else if (self.prng) |*prng|
            prng.random()
        else
            error.NoRandom;
    }

    test "next token" {
        const seed: u64 = @intCast(std.Io.Timestamp.now(std.testing.io, .real).toMilliseconds());
        var default_g = DefaultNamespaceGenerator.init(.{
            .prng = std.Random.DefaultPrng.init(seed),
            .namespace_len = 32,
            .token_len = 16,
        });
        var generator: NamespaceGenerator = .{ .ctx = &default_g, .vtable = &DefaultNamespaceGenerator.vtable };
        const token = try generator.nextToken(std.testing.allocator);
        defer std.testing.allocator.free(token);
        std.debug.print("{s}\n", .{token});
    }

    test "next namespace" {
        const seed: u64 = @intCast(std.Io.Timestamp.now(std.testing.io, .real).toMilliseconds());
        var default_g = DefaultNamespaceGenerator.init(.{
            .prng = std.Random.DefaultPrng.init(seed),
            .namespace_len = 32,
            .token_len = 16,
        });
        var generator: NamespaceGenerator = .{ .ctx = &default_g, .vtable = &DefaultNamespaceGenerator.vtable };
        const namespace = try generator.nextNamespace(std.testing.allocator);
        defer std.testing.allocator.free(namespace);
        std.debug.print("{s}\n", .{namespace});
    }

    test "next namespace and token" {
        const seed: u64 = @intCast(std.Io.Timestamp.now(std.testing.io, .real).toMilliseconds());
        var default_g = DefaultNamespaceGenerator.init(.{
            .prng = std.Random.DefaultPrng.init(seed),
            .namespace_len = 32,
            .token_len = 16,
        });
        var generator: NamespaceGenerator = .{ .ctx = &default_g, .vtable = &DefaultNamespaceGenerator.vtable };
        const namespace = try generator.nextNamespace(std.testing.allocator);
        defer std.testing.allocator.free(namespace);
        const token = try generator.nextToken(std.testing.allocator);
        defer std.testing.allocator.free(token);
        std.debug.print("{s}: {s}\n", .{ namespace, token });
    }
};

test "test" {
    std.testing.refAllDecls(DefaultNamespaceGenerator);
    std.testing.refAllDecls(NamespaceFile);
}
