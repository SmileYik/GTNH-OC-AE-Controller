const std = @import("std");
const mod = @import("root.zig");
const httpz = mod.httpz;
const NamespaceService = mod.Namespace.NamespaceService;
const RequestContext = mod.RequestContext;
const RouteData = mod.RouteData;

const Self = @This();

namespace_service: *NamespaceService,

pub fn dispatch(self: *Self, action: httpz.Action(*RequestContext), req: *httpz.Request, res: *httpz.Response) !void {
    const ocaetoken = req.header("ocaetoken");
    const namespace_param = req.param("namespace");
    const namespace =
        if (namespace_param) |param|
            try self.namespace_service.get(res.arena, param)
        else
            null;

    var ctx_handler: ?*anyopaque = undefined;
    if (req.route_data) |rd| {
        const route_data: *const RouteData = @ptrCast(@alignCast(rd));

        ctx_handler = route_data.data;
        if (route_data.restricted) {
            const valid_namespace = blk: {
                if (namespace) |ns| {
                    if (ns.token.len == 0) {
                        break :blk true;
                    } else if (ocaetoken) |token| {
                        break :blk std.mem.eql(u8, token, ns.token);
                    }
                }

                break :blk false;
            };
            if (valid_namespace) {
                try self.namespace_service.renew(namespace.?.namespace);
            } else {
                res.status = 404;
                res.body = "not found";
                return;
            }
        }
    }

    var ctx = RequestContext{
        .namespace = if (namespace) |*ns| ns else null,
        .handler = self,
        .ctx_handler = ctx_handler,
    };

    try action(&ctx, req, res);
}
