const std = @import("std");
const Allocator = std.mem.Allocator;

const mod = @import("root.zig");
const httpz = mod.httpz;
const HttpzServer = mod.HttpzServer;
const JsonData = mod.json_data.JsonData;
const LRUCache = mod.lru.LRUCache;
const RouteData = mod.RouteData;
const RequestContext = mod.RequestContext;
const NamespaceData = mod.Namespace.NamespaceData;

const Self = @This();
const IdMap = std.StringHashMap([]const u8);
const Cache = LRUCache([]const u8, IdMap);
const IdObject = struct {
    id: []const u8,
};

io: std.Io,
allocator: Allocator,
service: *JsonData,
cache: Cache,

_router_data: RouteData,
_url_path_all: []const u8 = undefined,
_url_path_id: []const u8 = undefined,

pub fn init(
    io: std.Io,
    allocator: Allocator,
    service: *JsonData,
    capacity: usize,
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
            .deinitKeyFn = Cache.DefaultFns.deinitString,
            .initValueFn = (struct {
                fn init(a: Allocator, old: IdMap) !IdMap {
                    var new = IdMap.init(a);
                    errdefer Self.deinitIdMap(a, &new);

                    try new.ensureTotalCapacity(old.count());
                    var iter = old.iterator();
                    while (iter.next()) |entry| {
                        const self_key = try a.dupe(u8, entry.key_ptr.*);
                        errdefer a.free(self_key);
                        const self_value = try a.dupe(u8, entry.value_ptr.*);
                        errdefer a.free(self_value);
                        try new.put(self_key, self_value);
                    }

                    return new;
                }
            }).init,
            .deinitValueFn = (struct {
                fn deinit(a: Allocator, map: IdMap) void {
                    var mut = map;
                    Self.deinitIdMap(a, &mut);
                }
            }).deinit,
        }),
        ._router_data = .{ .restricted = true },
    };
}

pub fn registerRouter(
    self: *Self,
    server: *HttpzServer,
    prefix_path: []const u8,
    comptime name: []const u8,
    middlewares: []const httpz.Middleware(*mod.Handler),
) !void {
    self._router_data.data = self;
    var router = try server.router(.{ .middlewares = middlewares });

    self._url_path_all = try std.fmt.allocPrint(self.allocator, "{s}/:namespace/" ++ name, .{prefix_path});
    std.debug.print("Register [GET/POST] request path: {s}\n", .{self._url_path_all});
    router.get(self._url_path_all, getAction, .{ .data = &self._router_data });
    router.post(self._url_path_all, insertAction, .{ .data = &self._router_data });

    self._url_path_id = try std.fmt.allocPrint(self.allocator, "{s}/:namespace/" ++ name ++ "/:id", .{prefix_path});
    std.debug.print("Register [GET/PUT/DELETE] request path: {s}\n", .{self._url_path_id});
    router.get(self._url_path_id, getByIdAction, .{ .data = &self._router_data });
    router.put(self._url_path_id, putByIdAction, .{ .data = &self._router_data });
    router.delete(self._url_path_id, deleteByIdAction, .{ .data = &self._router_data });
}

pub fn deinit(self: *Self) void {
    self.cache.deinit();
    self.allocator.free(self._url_path_all);
    self.allocator.free(self._url_path_id);
}

fn idMapToJson(allocator: Allocator, map: *const IdMap) !std.ArrayList(u8) {
    var buf = try std.ArrayList(u8).initCapacity(allocator, 2048);
    try buf.append(allocator, '[');
    var iter = map.valueIterator();
    var not_first = false;
    while (iter.next()) |item| {
        if (not_first) {
            try buf.append(allocator, ',');
        } else {
            not_first = true;
        }
        try buf.appendSlice(allocator, item.*);
    }
    try buf.append(allocator, ']');
    try buf.shrinkToLen(allocator);
    return buf;
}

fn jsonToIdMap(allocator: Allocator, json: []const u8) !IdMap {
    const parsed = try std.json.parseFromSlice([]std.json.Value, allocator, json, .{});
    defer parsed.deinit();

    var map = IdMap.init(allocator);
    errdefer deinitIdMap(allocator, &map);

    for (parsed.value) |e| {
        const entry = try std.fmt.allocPrint(allocator, "{f}", .{std.json.fmt(e, .{})});
        errdefer allocator.free(entry);

        const id_obj_parsed = try std.json.parseFromSlice(
            IdObject,
            allocator,
            entry,
            .{ .ignore_unknown_fields = true },
        );
        defer id_obj_parsed.deinit();

        const id = try allocator.dupe(u8, id_obj_parsed.value.id);
        errdefer allocator.free(id);

        try map.put(id, entry);
    }
    return map;
}

fn deinitIdMap(allocator: Allocator, map: *IdMap) void {
    var iter = map.iterator();
    while (iter.next()) |entry| {
        allocator.free(entry.key_ptr.*);
        allocator.free(entry.value_ptr.*);
    }
    map.deinit();
}

fn loadJsonMap(self: *Self, ns: *const NamespaceData) !*IdMap {
    const namespace = ns.namespace;
    var json = try self.service.get(self.allocator, namespace);
    if (json.len == 0) {
        self.allocator.free(json);
        var json_mut = try self.allocator.alloc(u8, 2);
        json_mut[0] = '[';
        json_mut[1] = ']';
        json = json_mut;
    }
    defer self.allocator.free(json);

    var id_map = try jsonToIdMap(self.allocator, json);
    defer deinitIdMap(self.allocator, &id_map);

    const ret = try self.cache.putAndGet(namespace, id_map);
    if (ret.evicted) |evicted| {
        defer evicted.deinit();

        var map = evicted.value;
        var json_buf = try idMapToJson(self.allocator, &map);
        defer json_buf.deinit(self.allocator);

        try self.service.set(self.allocator, evicted.key, json_buf.items);
    }
    return ret.value;
}

fn getAction(ctx: *RequestContext, _: *httpz.Request, res: *httpz.Response) !void {
    var self: *Self = @ptrCast(@alignCast(ctx.ctx_handler.?));
    const ns = ctx.namespace.?;
    const result = self.cache.getPtr(ns.namespace) orelse try self.loadJsonMap(ns);

    res.body = (try idMapToJson(res.arena, result)).items;
    res.content_type = .JSON;
}

fn insertAction(ctx: *RequestContext, req: *httpz.Request, res: *httpz.Response) !void {
    var self: *Self = @ptrCast(@alignCast(ctx.ctx_handler.?));

    if (req.body()) |others_body| {
        const ns = ctx.namespace.?;
        const parsed = try std.json.parseFromSlice(
            IdObject,
            self.allocator,
            others_body,
            .{ .ignore_unknown_fields = true },
        );
        defer parsed.deinit();

        const id = parsed.value.id;
        if (id.len > 0) {
            _ = self.cache.get(ns.namespace) orelse try self.loadJsonMap(ns);
            _ = try self.cache.fetchGet(
                ns.namespace,
                (struct {
                    pub fn f(cache: *Cache, map: *IdMap, id_final: []const u8, others_body_final: []const u8) !void {
                        if (!map.contains(id_final)) {
                            const self_id = try cache.allocator.dupe(u8, id_final);
                            errdefer cache.allocator.free(self_id);
                            const self_body = try cache.allocator.dupe(u8, others_body_final);
                            errdefer cache.allocator.free(self_body);

                            try map.put(self_id, self_body);
                        }
                    }
                }).f,
                .{ id, others_body },
            );
        }
    }
    res.setStatus(.ok);
}

fn getByIdAction(ctx: *RequestContext, req: *httpz.Request, res: *httpz.Response) !void {
    var self: *Self = @ptrCast(@alignCast(ctx.ctx_handler.?));

    if (req.param("id")) |id| {
        const ns = ctx.namespace.?;
        var result = self.cache.getPtr(ns.namespace) orelse try self.loadJsonMap(ns);

        if (result.get(id)) |value| {
            res.body = try res.arena.dupe(u8, value);
            res.content_type = .JSON;
        } else {
            res.setStatus(.not_found);
        }
    }
}

fn deleteByIdAction(ctx: *RequestContext, req: *httpz.Request, res: *httpz.Response) !void {
    var self: *Self = @ptrCast(@alignCast(ctx.ctx_handler.?));

    if (req.param("id")) |id| {
        const ns = ctx.namespace.?;
        const result = self.cache.getPtr(ns.namespace) orelse try self.loadJsonMap(ns);

        res.setStatus(self.deleteById(result, id));
    }
}

fn putByIdAction(ctx: *RequestContext, req: *httpz.Request, res: *httpz.Response) !void {
    var self: *Self = @ptrCast(@alignCast(ctx.ctx_handler.?));

    if (req.param("id")) |id| {
        if (req.body()) |body| {
            const ns = ctx.namespace.?;
            var result = self.cache.getPtr(ns.namespace) orelse try self.loadJsonMap(ns);

            // make sure object always include 'id' field and be identical.
            const parsed = try std.json.parseFromSlice(
                std.json.Value,
                self.allocator,
                body,
                .{ .ignore_unknown_fields = true },
            );
            defer parsed.deinit();

            var value = parsed.value;
            if (value != .object) {
                // TODO
                res.setStatus(.bad_request);
                return;
            }
            try value.object.put(parsed.arena.allocator(), "id", .{ .string = id });

            const new_body = try std.fmt.allocPrint(res.arena, "{f}", .{std.json.fmt(value, .{})});
            errdefer res.arena.free(new_body);

            const self_id = blk: {
                if (result.fetchRemove(id)) |kv| {
                    self.allocator.free(kv.value);
                    break :blk .{ false, kv.key };
                } else break :blk .{ true, try result.allocator.dupe(u8, id) };
            };
            errdefer if (self_id.@"0") result.allocator.free(self_id.@"1");

            const self_body = try result.allocator.dupe(u8, new_body);
            errdefer result.allocator.free(self_body);

            try result.put(self_id.@"1", self_body);
            res.body = new_body;
            res.content_type = .JSON;
            res.setStatus(.ok);
        }
    }
}

fn deleteById(_: *Self, map: *IdMap, id: []const u8) std.http.Status {
    if (map.fetchRemove(id)) |kv| {
        map.allocator.free(kv.key);
        map.allocator.free(kv.value);
        return .ok;
    } else {
        return .not_found;
    }
}

pub fn writeBackCache(self: *Self) !void {
    var iter = self.cache.map.iterator();
    while (iter.next()) |entry| {
        var list = try idMapToJson(self.allocator, &entry.value_ptr.*.value);
        defer list.deinit(self.allocator);
        try self.service.set(self.allocator, entry.key_ptr.*, list.items);
    }
}
