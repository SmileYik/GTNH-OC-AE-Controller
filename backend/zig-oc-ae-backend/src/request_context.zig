const NamespaceData = @import("namespace.zig").NamespaceData;
const Handler = @import("handler.zig");

namespace: ?*const NamespaceData = null,
handler: *Handler,
ctx_handler: ?*anyopaque = null,
