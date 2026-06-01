const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const exe = b.addExecutable(.{
        .name = "orbit",
        .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = "src/main.zig" } },
        .target = target,
    });
    b.installArtifact(exe);

    // Add test_theory executable
    const test_exe = b.addExecutable(.{
        .name = "test_theory",
        .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = "src/test_theory.zig" } },
        .target = target,
    });
    b.installArtifact(test_exe);

    const test_step = b.step("test-theory", "Run THEORY.md example test");
    const test_run = b.addRunArtifact(test_exe);
    test_step.dependOn(&test_run.step);
}
