const std = @import("std");
const Allocator = std.mem.Allocator;

pub const JsonDataVTable = struct {
    getFn: *const fn (ctx: *anyopaque, gpa: Allocator, namespace: []const u8, key: []const u8) anyerror![]const u8,
    setFn: *const fn (ctx: *anyopaque, gpa: Allocator, namespace: []const u8, key: []const u8, json: []const u8) anyerror!void,
};

pub const JsonData = struct {
    ctx: *anyopaque,
    vtable: *const JsonDataVTable,
    key: []const u8,

    pub fn get(self: JsonData, gpa: Allocator, namespace: []const u8) ![]const u8 {
        return self.vtable.getFn(self.ctx, gpa, namespace, self.key);
    }

    pub fn set(self: JsonData, gpa: Allocator, namespace: []const u8, json: []const u8) !void {
        return self.vtable.setFn(self.ctx, gpa, namespace, self.key, json);
    }
};

pub const JsonDataFile = struct {
    io: std.Io,
    base_dir: []const u8,
    allocator: Allocator,

    pub const vtable: JsonDataVTable = .{
        .getFn = get,
        .setFn = set,
    };

    fn get(ctx: *anyopaque, gpa: Allocator, namespace: []const u8, key: []const u8) anyerror![]const u8 {
        var self: *JsonDataFile = @ptrCast(@alignCast(ctx));

        const path = try self.getPath(self.allocator, namespace, key);
        defer self.allocator.free(path);

        const cwd = std.Io.Dir.cwd();
        try createNewFile(self.io, cwd, path);
        return try cwd.readFileAlloc(self.io, path, gpa, .unlimited);
    }

    fn set(ctx: *anyopaque, _: Allocator, namespace: []const u8, key: []const u8, json: []const u8) anyerror!void {
        var self: *JsonDataFile = @ptrCast(@alignCast(ctx));

        const path = try self.getPath(self.allocator, namespace, key);
        defer self.allocator.free(path);

        const cwd = std.Io.Dir.cwd();
        try createNewFile(self.io, cwd, path);
        try cwd.writeFile(self.io, .{
            .sub_path = path,
            .data = json,
        });
    }

    fn getPath(self: JsonDataFile, gpa: Allocator, namespace: []const u8, key: []const u8) ![]const u8 {
        if (std.mem.indexOfAny(u8, namespace, "/\\.") != null or
            std.mem.indexOfAny(u8, key, "/\\.") != null)
        {
            return error.InvalidPathCharacter;
        }

        const filename = try std.fmt.allocPrint(gpa, "{s}.json", .{key});
        defer gpa.free(filename);

        return try std.fs.path.join(gpa, &.{
            self.base_dir,
            namespace,
            filename,
        });
    }

    fn createNewFile(io: std.Io, cwd: std.Io.Dir, path: []const u8) !void {
        if (std.fs.path.dirname(path)) |dir| {
            try cwd.createDirPath(io, dir);
        }
        const file = try cwd.createFile(io, path, .{ .truncate = false });
        file.close(io);
    }
};

test "getPath_test" {
    const p: JsonDataFile = .{
        .allocator = std.testing.allocator,
        .base_dir = "./test/users",
        .io = std.testing.io,
    };
    const path = try p.getPath(p.allocator, "abcd", "efg");
    defer p.allocator.free(path);
    std.debug.print("\n{s}\n", .{path});
}

test "set_json_file_test" {
    var json_data_file = JsonDataFile{
        .allocator = std.testing.allocator,
        .base_dir = "./test/users",
        .io = std.testing.io,
    };
    const json_data: JsonData = .{
        .ctx = &json_data_file,
        .key = "test",
        .vtable = &JsonDataFile.vtable,
    };
    try json_data.set(std.testing.allocator, "abc", "{}");
}

test "get_json_file_test" {
    var json_data_file = JsonDataFile{
        .allocator = std.testing.allocator,
        .base_dir = "./test/users",
        .io = std.testing.io,
    };
    const json_data: JsonData = .{
        .ctx = &json_data_file,
        .key = "test",
        .vtable = &JsonDataFile.vtable,
    };
    const data = try json_data.get(std.testing.allocator, "abc");
    defer std.testing.allocator.free(data);
    std.debug.print("{s}\n", .{data});
}
