const std = @import("std");
const str = @import("str");
const RocStr = str.RocStr;
const testing = std.testing;
const expectEqual = testing.expectEqual;
const expect = testing.expect;

comptime {
    // This is a workaround for https://github.com/ziglang/zig/issues/8218
    // which is only necessary on macOS.
    //
    // Once that issue is fixed, we can undo the changes in
    // 177cf12e0555147faa4d436e52fc15175c2c4ff0 and go back to passing
    // -fcompiler-rt in link.rs instead of doing this. Note that this
    // workaround is present in many host.zig files, so make sure to undo
    // it everywhere!
    if (std.builtin.os.tag == .macos) {
        _ = @import("compiler_rt");
    }
}

const Align = extern struct { a: usize, b: usize };
extern fn malloc(size: usize) callconv(.C) ?*align(@alignOf(Align)) c_void;
extern fn realloc(c_ptr: [*]align(@alignOf(Align)) u8, size: usize) callconv(.C) ?*c_void;
extern fn free(c_ptr: [*]align(@alignOf(Align)) u8) callconv(.C) void;

export fn roc_alloc(size: usize, alignment: u32) callconv(.C) ?*c_void {
    _ = alignment;

    return malloc(size);
}

export fn roc_realloc(c_ptr: *c_void, new_size: usize, old_size: usize, alignment: u32) callconv(.C) ?*c_void {
    _ = old_size;
    _ = alignment;

    return realloc(@alignCast(@alignOf(Align), @ptrCast([*]u8, c_ptr)), new_size);
}

export fn roc_dealloc(c_ptr: *c_void, alignment: u32) callconv(.C) void {
    _ = alignment;

    free(@alignCast(@alignOf(Align), @ptrCast([*]u8, c_ptr)));
}

export fn roc_panic(c_ptr: *c_void, tag_id: u32) callconv(.C) void {
    _ = tag_id;
    const stderr = std.io.getStdErr().writer();
    const msg = @ptrCast([*:0]const u8, c_ptr);
    stderr.print("Application crashed with message\n\n    {s}\n\nShutting down\n", .{msg}) catch unreachable;
    std.process.exit(0);
}

const mem = std.mem;
const Allocator = mem.Allocator;

extern fn roc__mainForHost_1_exposed(*RocCallResult) void;

const RocCallResult = extern struct { flag: u64, content: RocStr };

const Unit = extern struct {};

pub fn main() u8 {
    const stdout = std.io.getStdOut().writer();
    const stderr = std.io.getStdErr().writer();

    // make space for the result
    var callresult = RocCallResult{ .flag = 0, .content = RocStr.empty() };

    // start time
    var ts1: std.os.timespec = undefined;
    std.os.clock_gettime(std.os.CLOCK_REALTIME, &ts1) catch unreachable;

    // actually call roc to populate the callresult
    roc__mainForHost_1_exposed(&callresult);

    // stdout the result
    stdout.print("{s}\n", .{callresult.content.asSlice()}) catch unreachable;

    callresult.content.deinit();

    // end time
    var ts2: std.os.timespec = undefined;
    std.os.clock_gettime(std.os.CLOCK_REALTIME, &ts2) catch unreachable;

    const delta = to_seconds(ts2) - to_seconds(ts1);

    stderr.print("runtime: {d:.3}ms\n", .{delta * 1000}) catch unreachable;

    return 0;
}

fn to_seconds(tms: std.os.timespec) f64 {
    return @intToFloat(f64, tms.tv_sec) + (@intToFloat(f64, tms.tv_nsec) / 1_000_000_000.0);
}
