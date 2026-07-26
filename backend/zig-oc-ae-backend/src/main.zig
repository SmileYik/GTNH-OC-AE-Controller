const std = @import("std");
const httpz = @import("httpz");
const Allocator = std.mem.Allocator;
const mod = @import("oc_ae_backend");
const builtin = @import("builtin");

pub fn main(init: std.process.Init) !void {
    // var debug_allocator = std.heap.DebugAllocator(.{
    //     .thread_safe = true,
    //     .stack_trace_frames = 999,
    //     .resize_stack_traces = true,
    // }){ .backing_allocator = init.gpa };
    // defer {
    //     _ = debug_allocator.detectLeaks();
    //     const check = debug_allocator.deinit();
    //     std.debug.print("\nmemory leak: {}\n", .{check});
    // }
    const allocator = init.gpa;

    var config = try mod.Config.load(allocator, init.io, "./data/config.json");
    defer config.deinit();
    const c = config.config();

    var default_namespace_generator = mod.Namespace.DefaultNamespaceGenerator.init(.{
        .csprng = blk: {
            if (c.namespace.secure_random) {
                var seed: [std.Random.DefaultCsprng.secret_seed_length]u8 = undefined;
                try init.io.randomSecure(&seed);
                break :blk std.Random.DefaultCsprng.init(seed);
            }
            break :blk null;
        },
        .prng = blk: {
            if (!c.namespace.secure_random) {
                var seed: [8]u8 = undefined;
                init.io.random(&seed);
                const seed_u64 = std.mem.readInt(u64, &seed, .native);
                break :blk std.Random.DefaultPrng.init(seed_u64);
            }
            break :blk null;
        },
        .namespace_len = c.namespace.namespace_length,
        .token_len = c.namespace.token_length,
        .candidate = c.namespace.candidate,
    });
    var namespace_generator: mod.Namespace.NamespaceGenerator = .{
        .ctx = &default_namespace_generator,
        .vtable = &mod.Namespace.DefaultNamespaceGenerator.vtable,
    };
    var namespace_cleaner = (struct {
        const This = @This();

        io: std.Io,
        pub fn clean(ctx: *anyopaque, key: []const u8) !void {
            const self: *This = @ptrCast(@alignCast(ctx));
            var buf: [8192]u8 = undefined;
            @memset(&buf, 0);
            const path = try std.fmt.bufPrint(&buf, "{s}/{s}", .{ "./data", key });
            std.debug.print("Clean namespace path: {s}\n", .{path});
            try std.Io.Dir.cwd().deleteTree(self.io, path);
        }

        pub fn cleanFn(_: *This) *const fn (ctx: *anyopaque, key: []const u8) anyerror!void {
            return &clean;
        }
    }){ .io = init.io };
    var namespace_impl = try mod.Namespace.NamespaceFile.init(.{
        .allocator = allocator,
        .io = init.io,
        .file = c.namespace.json_file,
        .duration_seconds = c.namespace.rental_period_seconds,
        .cleaner = .{
            .ptr = &namespace_cleaner,
            .cleanFn = namespace_cleaner.cleanFn(),
        },
    });
    var namespace_service: mod.Namespace.NamespaceService = .{
        .ctx = &namespace_impl,
        .vtable = &mod.Namespace.NamespaceFile.vtable(),
        .io = init.io,
        .generator = &namespace_generator,
    };
    defer namespace_service.deinit() catch {};

    var handler = mod.Handler{
        .namespace_service = &namespace_service,
    };
    var server = try mod.HttpzServer.init(init.io, allocator, .{
        .address = .all(c.port),
        .request = c.httpz.request,
        .response = c.httpz.response,
        .thread_pool = c.httpz.thread_pool,
        .timeout = c.httpz.timeout,
        .workers = c.httpz.worker,
    }, &handler);
    try setupSignalHandler(&server);
    defer server.deinit();

    var cors = try server.middleware(mod.Middleware.Cors, c.cors);
    defer cors.deinit();

    var apply_handler = try mod.ApplyHandler.init(
        init.io,
        allocator,
        &namespace_service,
        c.namespace.rental_period_seconds,
        c.apply_handler.max_request_count,
        c.apply_handler.max_request_count_period_ms,
        c.url_prefix,
    );
    defer apply_handler.deinit();
    try apply_handler.registerRouter(&server, c.apply_handler.url_prefix, &.{cors});

    const map_names = .{ "task", "items", "essentia", "fluids" };
    var map_handlers: [map_names.len]*ObjectHandler = undefined;
    var map_handler_init_count: u8 = 0;
    defer {
        std.debug.print("clean map handlers", .{});
        for (0..map_handler_init_count) |i| {
            map_handlers[i].handler.writeBackCache() catch {};
            map_handlers[i].handler.deinit();
            allocator.destroy(map_handlers[i]);
        }
    }
    inline for (map_names, 0..) |name, i| {
        map_handlers[i] = try newObjectHandler(init.io, allocator, c.json_data_path, name, 1024);
        try map_handlers[i].handler.registerRouter(&server, c.url_prefix, name, &.{cors});
        map_handler_init_count += 1;
    }

    const array_names = .{"cpus"};
    var array_handlers: [array_names.len]*ArrayHandler = undefined;
    var array_handler_init_count: u8 = 0;
    defer {
        std.debug.print("clean array handlers", .{});
        for (0..array_handler_init_count) |i| {
            array_handlers[i].handler.writeBackCache() catch {};
            array_handlers[i].handler.deinit();
            allocator.destroy(array_handlers[i]);
        }
    }
    inline for (array_names, 0..) |name, i| {
        array_handlers[i] = try newArrayHandler(init.io, allocator, c.json_data_path, name, 1024);
        try array_handlers[i].handler.registerRouter(&server, c.url_prefix, name, &.{cors});
        array_handler_init_count += 1;
    }

    var saver: Saver = .{
        .object_handers = map_handlers[0..],
        .array_handlers = array_handlers[0..],
        .namespace_file_impl = &namespace_impl,
    };
    var saver_timer = mod.Timer{
        .callback = &Saver.callback,
        .ctx = &saver,
        .io = init.io,
        .period = .fromSeconds(c.saver_period_second),
        .delay = .fromSeconds(c.saver_period_second),
    };
    try saver_timer.start();
    defer saver_timer.stop();

    std.debug.print("listening http://localhost:{d}/\n", .{c.port});

    try server.listen();
}

const ObjectHandler = struct {
    vtable: mod.json_data.JsonDataVTable,
    impl: mod.json_data.JsonDataFile,
    service: mod.json_data.JsonData,
    handler: mod.ObjectHandler,
};
fn newObjectHandler(
    io: std.Io,
    allocator: Allocator,
    base_dir: []const u8,
    comptime key: []const u8,
    comptime lru_capacity: usize,
) !*ObjectHandler {
    var s: *ObjectHandler = try allocator.create(ObjectHandler);
    s.vtable = mod.json_data.JsonDataFile.vtable;
    s.impl = mod.json_data.JsonDataFile{
        .allocator = allocator,
        .io = io,
        .base_dir = base_dir,
    };
    s.service = mod.json_data.JsonData{
        .ctx = &s.impl,
        .vtable = &s.vtable,
        .key = key,
    };
    s.handler = try mod.ObjectHandler.init(io, allocator, &s.service, lru_capacity);
    return s;
}

const ArrayHandler = struct {
    vtable: mod.json_data.JsonDataVTable,
    impl: mod.json_data.JsonDataFile,
    service: mod.json_data.JsonData,
    handler: mod.ArrayHandler,
};
fn newArrayHandler(
    io: std.Io,
    allocator: Allocator,
    base_dir: []const u8,
    comptime key: []const u8,
    comptime lru_capacity: usize,
) !*ArrayHandler {
    var s: *ArrayHandler = try allocator.create(ArrayHandler);
    s.vtable = mod.json_data.JsonDataFile.vtable;
    s.impl = mod.json_data.JsonDataFile{
        .allocator = allocator,
        .io = io,
        .base_dir = base_dir,
    };
    s.service = mod.json_data.JsonData{
        .ctx = &s.impl,
        .vtable = &s.vtable,
        .key = key,
    };
    s.handler = try mod.ArrayHandler.init(io, allocator, &s.service, lru_capacity);
    return s;
}

const Saver = struct {
    object_handers: ?[]*ObjectHandler = null,
    array_handlers: ?[]*ArrayHandler = null,
    namespace_file_impl: ?*mod.Namespace.NamespaceFile = null,

    pub fn callback(ctx: *anyopaque) !void {
        var self: *Saver = @ptrCast(@alignCast(ctx));
        self.save();
    }

    fn save(self: *Saver) void {
        std.debug.print("Start save..\n", .{});
        if (self.object_handers) |handlers| for (handlers) |handler| {
            handler.handler.writeBackCache() catch |e| {
                std.log.err("Object handler write back date failed: {any}", .{e});
            };
        };
        if (self.array_handlers) |handlers| for (handlers) |handler| {
            handler.handler.writeBackCache() catch |e| {
                std.log.err("Array handler write back date failed: {any}", .{e});
            };
        };
        if (self.namespace_file_impl) |namespace_file| {
            namespace_file.store() catch |e| {
                std.log.err("Namespace write back date failed: {any}", .{e});
            };
        }
    }
};

var global_server: ?*mod.HttpzServer = null;

fn handlePosixSignal(_: std.os.linux.SIG) callconv(.c) void {
    if (global_server) |s| s.stop();
}

pub fn setupSignalHandler(server_ptr: *mod.HttpzServer) !void {
    global_server = server_ptr;

    if (builtin.target.os.tag == .windows) {} else {
        const signals = .{ std.posix.SIG.INT, std.posix.SIG.TERM };
        inline for (signals) |signal| {
            std.posix.sigaction(
                signal,
                &.{
                    .handler = .{ .handler = handlePosixSignal },
                    .mask = std.posix.sigemptyset(),
                    .flags = 0,
                },
                null,
            );
        }
    }
}
