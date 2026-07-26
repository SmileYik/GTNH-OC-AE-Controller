const std = @import("std");
const mod = @import("root.zig");
const Allocator = std.mem.Allocator;

const Self = @This();

const Config = struct {
    /// server listen port
    port: u16 = 16500,

    /// lru 缓存大小, 超过这个大小的缓存会逐出内存并写回
    lru_capacity: usize = 16,

    /// 除了申领接口以外的所有请求的URL公共前缀
    url_prefix: []const u8 = "/ocae",

    /// httpz 配置
    httpz: HttpzConfig = .{},

    /// 跨域设置
    cors: mod.httpz.middleware.Cors.Config = .{
        .origin = "*",
        .headers = "*",
        .credentials = "true",
    },

    /// 持久化模式, 当前可用的有: `json`
    ///
    /// * **json** 模式代表持久层使用 json 文件存储.
    mode: []const u8 = "json",

    /// **当 `mode` 设置为 `json` 时生效.**
    ///
    /// json数据文件目录持久化存储路径. 为一个目录路径
    json_data_path: []const u8 = "./data",

    /// 数据写回线程多久写回一次数据到硬盘中, 单位为秒
    saver_period_second: i64 = 60,

    /// 命名空间配置.
    namespace: NamespaceConfig = .{},

    /// 申领配置
    apply_handler: ApplyConfig = .{},
};

const HttpzConfig = struct {
    thread_pool: mod.httpz.Config.ThreadPool = .{},
    request: mod.httpz.Config.Request = .{},
    worker: mod.httpz.Config.Worker = .{},
    response: mod.httpz.Config.Response = .{},
    timeout: mod.httpz.Config.Timeout = .{},
};

const NamespaceConfig = struct {
    /// 命名空间持久化模式, 当前可选模式为: `json`
    ///
    /// + **json** 模式代表持久层使用文件存储
    mode: []const u8 = "json",

    /// **仅当 `mode` 设置为 `json` 时生效**
    ///
    /// json 文件存储路径. 为一个文件路径
    json_file: []const u8 = "./data/namespaces.json",

    /// 命名空间租借时间: 租借时间单位为秒
    rental_period_seconds: i64 = 7 * 24 * 60 * 60,

    /// 命名空间随机化生成的长度
    namespace_length: u16 = 32,

    /// 命名空间令牌随机化生产长度
    token_length: u8 = 32,

    /// 是否使用安全随机数生成
    secure_random: bool = true,

    /// 随机词候选, 仅能使用 ASCII 字符, 避免使用与 URL 敏感的字符.
    candidate: []const u8 = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_",
};

const ApplyConfig = struct {
    /// 申领接口URL前缀.
    url_prefix: []const u8 = "",

    /// 同一IP用户在一定时间窗口中(`max_request_count_period_ms`中设定的毫秒数)
    /// 最大申领请求数量
    max_request_count: usize = 1,

    /// 同一IP用户在规定时间内进行限流, 若设置为 `0` 毫秒, 则代表不限流.
    /// 否则在设定的毫秒期间内, 若同一IP用户申领次数超过 `max_request_count`
    /// 所设定的次数, 则会直接拒绝请求
    max_request_count_period_ms: i64 = 60 * 1000,
};

arena: std.heap.ArenaAllocator,
allocator: Allocator,
parsed: ?std.json.Parsed(Config) = null,
data: ?Config = null,

pub fn load(gpa: Allocator, io: std.Io, file_path: []const u8) !Self {
    var arena = std.heap.ArenaAllocator.init(gpa);
    var allocator = arena.allocator();

    var cwd = std.Io.Dir.cwd();
    if (std.fs.path.dirname(file_path)) |dir| {
        try cwd.createDirPath(io, dir);
    }
    {
        var file = try cwd.createFile(io, file_path, .{ .truncate = false });
        file.close(io);
    }
    const data = try cwd.readFileAlloc(io, file_path, allocator, .unlimited);
    defer allocator.free(data);

    const parsed = std.json.parseFromSlice(
        Config,
        allocator,
        data,
        .{
            .allocate = .alloc_always,
            .ignore_unknown_fields = true,
        },
    ) catch {
        const config_data: Config = .{};
        const config_json = try std.fmt.allocPrint(
            allocator,
            "{f}",
            .{
                std.json.fmt(config_data, .{ .whitespace = .indent_4 }),
            },
        );
        defer allocator.free(config_json);
        try cwd.writeFile(io, .{
            .data = config_json,
            .sub_path = file_path,
            .flags = .{},
        });
        return .{
            .allocator = allocator,
            .arena = arena,
            .data = config_data,
        };
    };
    return .{
        .allocator = allocator,
        .arena = arena,
        .parsed = parsed,
    };
}

pub fn config(self: *const Self) *const Config {
    if (self.data) |_| {
        return &self.data.?;
    }
    return &self.parsed.?.value;
}

pub fn deinit(self: *Self) void {
    self.arena.deinit();
}
