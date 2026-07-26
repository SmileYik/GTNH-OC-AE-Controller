const std = @import("std");
const Allocator = std.mem.Allocator;

const mod = @import("root.zig");
const httpz = mod.httpz;
const HttpzServer = mod.HttpzServer;
const NamespaceService = mod.Namespace.NamespaceService;
const RouteData = mod.RouteData;
const RequestContext = mod.RequestContext;

const Self = @This();

io: std.Io,
allocator: Allocator,
namespace_service: *NamespaceService,
router_data: RouteData,
duration_seconds: i64,

max_request_count: usize,
max_request_count_period_ms: i64,
renew_timestamp: i64,
data_base_url: []const u8,

_limits: std.StringHashMap(usize),
_mutex: std.Io.Mutex = .init,
_url_path: []const u8 = undefined,

pub fn init(
    io: std.Io,
    allocator: Allocator,
    namespace_service: *NamespaceService,
    duration_seconds: i64,
    max_request_count: usize,
    max_request_count_period_ms: i64,
    data_base_url: []const u8,
) !Self {
    return .{
        .allocator = allocator,
        .io = io,
        .namespace_service = namespace_service,
        .duration_seconds = duration_seconds,
        .max_request_count = max_request_count,
        .max_request_count_period_ms = max_request_count_period_ms,
        .router_data = .{ .restricted = false },
        .renew_timestamp = std.Io.Timestamp.now(io, .real).addDuration(.fromMilliseconds(max_request_count_period_ms)).toMilliseconds(),
        .data_base_url = data_base_url,
        ._limits = std.StringHashMap(usize).init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    var it = self._limits.iterator();
    while (it.next()) |entry| {
        self.allocator.free(entry.key_ptr.*);
    }
    self._limits.deinit();
    self.allocator.free(self._url_path);
}

pub fn registerRouter(
    self: *Self,
    server: *HttpzServer,
    prefix_path: []const u8,
    middlewares: []const httpz.Middleware(*mod.Handler),
) !void {
    self.router_data.data = self;
    var router = try server.router(.{ .middlewares = middlewares });
    self._url_path = try std.fmt.allocPrint(self.allocator, "{s}/apply", .{prefix_path});
    std.debug.print("Register [GET] request path: {s}\n", .{self._url_path});
    router.get(
        self._url_path,
        applyAction,
        .{ .data = &self.router_data },
    );
}

fn formatIPAddress(io: std.Io, gpa: Allocator, address: *std.Io.net.IpAddress) !std.ArrayList(u8) {
    var buf = try std.ArrayList(u8).initCapacity(gpa, 256);
    var writer = std.Io.Writer.fromArrayList(&buf);
    try address.formatResolved(io, &writer);
    try writer.flush();
    buf = writer.toArrayList();
    if (std.mem.findLast(u8, buf.items, ":")) |i| {
        buf.shrinkAndFree(gpa, i);
    }
    return buf;
}

fn applyAction(ctx: *RequestContext, req: *httpz.Request, res: *httpz.Response) !void {
    var self: *Self = @ptrCast(@alignCast(ctx.ctx_handler.?));
    const client_ip =
        req.header("x-forwarded-for") orelse
        (try formatIPAddress(self.io, res.arena, &req.address)).items;

    if (self.max_request_count_period_ms != 0) {
        self._mutex.lock(self.io) catch {
            res.setStatus(.service_unavailable);
            return;
        };
        defer self._mutex.unlock(self.io);

        const now = std.Io.Timestamp.now(self.io, .real);
        if (now.toMilliseconds() > self.renew_timestamp) {
            var it = self._limits.iterator();
            while (it.next()) |entry| {
                self.allocator.free(entry.key_ptr.*);
            }
            self._limits.clearRetainingCapacity();
            self.renew_timestamp = now.addDuration(.fromMilliseconds(self.max_request_count_period_ms)).toMilliseconds();
        }

        const entry = try self._limits.getOrPut(client_ip);
        if (!entry.found_existing) {
            entry.key_ptr.* = try self.allocator.dupe(u8, client_ip);
            entry.value_ptr.* = 1;
        } else {
            if (entry.value_ptr.* >= self.max_request_count) {
                res.setStatus(.too_many_requests);
                return;
            }
            entry.value_ptr.* += 1;
        }
    }

    std.debug.print("Apply a namespace by Cliend  IP: {s}\n", .{client_ip});
    for (0..3) |_| {
        const namespace = try self.namespace_service.newNamespace(req.arena, self.duration_seconds);
        defer namespace.deinit();

        const url = try std.fmt.allocPrint(req.arena, "{s}/{s}", .{ self.data_base_url, namespace.namespace });

        if (try self.namespace_service.put(&namespace)) {
            try res.json(.{
                .code = "200",
                .message = "success",
                .data = .{
                    .url = url,
                    .token = namespace.token,
                },
            }, .{});
            return;
        }
    }
    res.setStatus(.internal_server_error);
}
