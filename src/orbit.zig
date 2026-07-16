const std = @import("std");
const lexer = @import("lexer.zig");
const parser = @import("parser.zig");
const codegen = @import("codegen.zig");

pub const Error = error{UnsupportedBuildInput};

pub const Lvm = struct {
    allocator: *const std.mem.Allocator,

    pub fn init(allocator: *const std.mem.Allocator, options: anytype) !Lvm {
        _ = options;
        return Lvm{ .allocator = allocator };
    }

    pub fn deinit(self: *Lvm) void {
        self.* = undefined;
    }

    pub fn build(self: *Lvm, source: []const u8) ![]const u8 {
        return try transpileSource(self.allocator, source);
    }

    pub fn buildFile(self: *Lvm, path: []const u8) ![]const u8 {
        return try transpileFile(self.allocator, path);
    }

    pub fn parse(self: *Lvm, source: []const u8) ![]const u8 {
        return try self.build(source);
    }

    pub fn lua(self: *Lvm, source: []const u8) ![]const u8 {
        _ = self;
        return source;
    }
};

pub fn transpileSource(allocator: *const std.mem.Allocator, source: []const u8) ![]const u8 {
    const tokens = try lexer.lex(allocator, source);
    defer lexer.freeTokens(allocator, tokens);

    var program = try parser.parse(allocator, tokens);
    defer program.deinit();

    return try codegen.generate(allocator, program);
}

pub fn transpileFile(allocator: *const std.mem.Allocator, path: []const u8) ![]const u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    const source = try file.readToEndAlloc(allocator.*, 4096);
    defer allocator.*.free(source);
    return try transpileSource(allocator, source);
}
