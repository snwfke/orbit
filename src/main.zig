const std = @import("std");
const orbit = @import("orbit.zig");

fn usage() !void {
    const stderr = std.io.getStdErr().writer();
    try stderr.print(
        "Usage:\n  orbit build -F <file> [-o <output>]\n  orbit build --string=<source> [-o <output>]\n",
        .{},
    );
}

pub fn main() !void {
    const process_allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(process_allocator);
    defer std.process.argsFree(process_allocator, args);

    if (args.len < 2) {
        try usage();
        return;
    }

    const command = args[1];
    if (std.mem.eql(u8, command, "build")) {
        var file_path: ?[]const u8 = null;
        var source_string: ?[]const u8 = null;
        var out_path: ?[]const u8 = null;

        var i: usize = 2;
        while (i < args.len) : (i += 1) {
            const arg = args[i];
            if (std.mem.eql(u8, arg, "-F") or std.mem.eql(u8, arg, "--file")) {
                if (i + 1 >= args.len) return usage();
                file_path = args[i + 1];
                i += 1;
                continue;
            }
            if (std.mem.startsWith(u8, arg, "--string=")) {
                source_string = arg[std.mem.indexOf(u8, arg, "=").? + 1 ..];
                continue;
            }
            if (std.mem.eql(u8, arg, "-o") or std.mem.eql(u8, arg, "--out")) {
                if (i + 1 >= args.len) return usage();
                out_path = args[i + 1];
                i += 1;
                continue;
            }
            return usage();
        }

        if (file_path == null and source_string == null) {
            try usage();
            return;
        }

        var lua_code: []const u8 = undefined;
        var lvm = try orbit.Lvm.init(&std.heap.page_allocator, .{});
        defer lvm.deinit();
        if (file_path) |path| {
            lua_code = try lvm.buildFile(path);
        } else {
            lua_code = try lvm.build(source_string.?);
        }

        if (out_path) |path| {
            const file = try std.fs.cwd().createFile(path, .{});
            defer file.close();
            try file.writeAll(lua_code);
        } else {
            try std.io.getStdOut().writer().writeAll(lua_code);
        }
    } else {
        try usage();
    }
}
