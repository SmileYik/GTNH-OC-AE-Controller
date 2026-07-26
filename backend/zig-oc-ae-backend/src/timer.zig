const std = @import("std");

const Self = @This();

const STOPPED = 0;
const RUNNING = 1;

pub const Callback = fn (ctx: *anyopaque) anyerror!void;
pub const ErrorHandler = fn (ctx: *anyopaque, err: anyerror) bool;

io: std.Io,
ctx: *anyopaque,
callback: *const Callback,
on_error: ?*const ErrorHandler = null,
clock: std.Io.Clock = .awake,
delay: ?std.Io.Duration = null,
period: std.Io.Duration,
fixed_period: bool = true,

_running: std.atomic.Value(u32) = .init(STOPPED),
_thread: std.Thread = undefined,

pub fn start(self: *Self) !void {
    self._running.store(RUNNING, .release);
    self._thread = try std.Thread.spawn(.{}, tick, .{self});
}

pub fn stop(self: *Self) void {
    self._running.store(STOPPED, .release);
    self.io.futexWake(u32, &self._running.raw, 1);
    self._thread.join();
}

/// if need stop then return `true`
fn sleep(self: *Self, timeout: std.Io.Timeout) bool {
    const deadline = timeout.toTimestamp(self.io) orelse return false;
    while (true) {
        self.io.futexWaitTimeout(
            u32,
            &self._running.raw,
            RUNNING,
            .{ .deadline = deadline },
        ) catch |err|
            switch (err) {
                std.Io.Cancelable.Canceled => return true,
            };

        // awake by stop
        if (self._running.load(.acquire) == STOPPED) return true;

        // check false awake
        const duration = deadline.untilNow(self.io);
        if (duration.raw.nanoseconds >= 0) {
            return false;
        }
    }
    return false;
}

fn runCallback(self: *Self) !void {
    self.callback(self.ctx) catch |e| {
        const throw =
            if (self.on_error) |handler|
                handler(self.ctx, e)
            else
                true;
        if (throw) return e;
    };
}

fn tick(self: *Self) !void {
    if (self.delay) |d| {
        const timeout: std.Io.Timeout = .{
            .duration = .{
                .clock = self.clock,
                .raw = d,
            },
        };
        if (self.sleep(timeout))
            return;
    }
    return if (self.fixed_period)
        self.fixed()
    else
        self.rate();
}

fn fixed(self: *Self) !void {
    const timeout: std.Io.Timeout = .{
        .duration = .{
            .clock = self.clock,
            .raw = self.period,
        },
    };
    while (self._running.load(.acquire) == RUNNING) {
        try self.runCallback();
        if (self.sleep(timeout)) return;
    }
}

fn rate(self: *Self) !void {
    var last_deadline: std.Io.Timestamp = .now(self.io, self.clock);
    while (self._running.load(.acquire) == RUNNING) {
        const next_deadline = last_deadline.addDuration(self.period);

        try self.runCallback();
        const now = self.clock.now(self.io);
        if (now.nanoseconds > next_deadline.nanoseconds) {
            last_deadline = now;
            continue;
        }

        if (self.sleep(.{
            .deadline = .{
                .clock = self.clock,
                .raw = next_deadline,
            },
        })) return;
        last_deadline = next_deadline;
    }
}

test "period 1s and stop at 5s" {
    const S = struct {
        fn callback(_: *anyopaque) !void {
            std.debug.print("test\n", .{});
        }
    };
    var s: S = .{};
    var timer: Self = .{
        .callback = &S.callback,
        .ctx = &s,
        .io = std.testing.io,
        .fixed_period = true,
        .clock = .awake,
        .period = .fromSeconds(1),
    };
    try timer.start();
    try std.testing.io.sleep(.fromMilliseconds(5500), .real);
    timer.stop();
}
