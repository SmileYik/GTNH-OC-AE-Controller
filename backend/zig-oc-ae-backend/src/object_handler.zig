const std = @import("std");
const Allocator = std.mem.Allocator;

const mod = @import("root.zig");
const httpz = mod.httpz;
const HttpzServer = mod.HttpzServer;
const JsonData = mod.json_data.JsonData;
const RouteData = mod.RouteData;
const RequestContext = mod.RequestContext;

const Self = @This();
const Cache = mod.lru.LRUCache([]const u8, []const u8);

io: std.Io,
allocator: Allocator,
service: *JsonData,
cache: Cache,
router_data: RouteData,

_url_path: []const u8 = undefined,

pub fn init(
    io: std.Io,
    allocator: Allocator,
    service: *JsonData,
    comptime capacity: usize,
) !Self {
    return .{
        .allocator = allocator,
        .io = io,
        .service = service,
        .cache = try Cache.init(.{
            .io = io,
            .allocator = allocator,
            .capacity = capacity,
            .initKeyFn = Cache.DefaultFns.initDupeString,
            .initValueFn = Cache.DefaultFns.initDupeString,
            .deinitKeyFn = Cache.DefaultFns.deinitString,
            .deinitValueFn = Cache.DefaultFns.deinitString,
        }),
        .router_data = .{ .restricted = true },
    };
}

pub fn registerRouter(
    self: *Self,
    server: *HttpzServer,
    prefix_path: []const u8,
    comptime name: []const u8,
    middlewares: []const httpz.Middleware(*mod.Handler),
) !void {
    self.router_data.data = self;
    var router = try server.router(.{ .middlewares = middlewares });
    self._url_path = try std.fmt.allocPrint(self.allocator, "{s}/:namespace/" ++ name, .{prefix_path});
    std.debug.print("Register [GET/PUT] request path: {s}\n", .{self._url_path});
    router.put(
        self._url_path,
        setAction,
        .{ .data = &self.router_data },
    );
    router.get(
        self._url_path,
        getAction,
        .{ .data = &self.router_data },
    );
}

pub fn deinit(self: *Self) void {
    self.cache.deinit();
    self.allocator.free(self._url_path);
}

fn getAction(ctx: *RequestContext, _: *httpz.Request, res: *httpz.Response) !void {
    var self: *Self = @ptrCast(@alignCast(ctx.ctx_handler.?));
    const ns = ctx.namespace.?;
    if (self.cache.get(ns.namespace)) |json| {
        res.body = try res.arena.dupe(u8, json);
        res.content_type = .JSON;
        return;
    }

    var json = try self.service.get(res.arena, ns.namespace);
    if (json.len == 0) {
        res.arena.free(json);
        var json_mut = try res.arena.alloc(u8, 2);
        json_mut[0] = '{';
        json_mut[1] = '}';
        json = json_mut;
    }

    if (try self.cache.put(ns.namespace, json)) |evicted| {
        defer evicted.deinit();
        try self.service.set(self.allocator, evicted.key, evicted.value);
    }
    res.body = json;
    res.content_type = .JSON;
}

fn setAction(ctx: *RequestContext, req: *httpz.Request, res: *httpz.Response) !void {
    var self: *Self = @ptrCast(@alignCast(ctx.ctx_handler.?));

    if (req.body()) |others_body| {
        const body = try res.arena.dupe(u8, others_body);
        const ns = ctx.namespace.?;
        if (try self.cache.put(ns.namespace, body)) |evicted| {
            defer evicted.deinit();
            if (!evicted.is_same_key) {
                try self.service.set(self.allocator, evicted.key, evicted.value);
            }
        }
        res.body = body;
        res.content_type = .JSON;
    }
    res.setStatus(.ok);
}

pub fn writeBackCache(self: *Self) !void {
    var iter = self.cache.map.iterator();
    while (iter.next()) |entry| {
        try self.service.set(self.allocator, entry.key_ptr.*, entry.value_ptr.*.value);
    }
}
