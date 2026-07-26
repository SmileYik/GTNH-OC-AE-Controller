const mod = @import("root.zig");
const httpz = mod.httpz;
const Cors = httpz.middleware.Cors;
pub const Config = Cors.Config;

const Self = @This();

cors: Cors,

pub fn init(config: Config, mw_config: httpz.MiddlewareConfig) !Self {
    return .{
        .cors = try Cors.init(config, mw_config),
    };
}

pub fn execute(self: *const Self, req: *httpz.Request, res: *httpz.Response, executor: anytype) !void {
    req.headers.add("sec-fetch-mode", "cors");
    try self.cors.execute(req, res, executor);
}
