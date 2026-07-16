const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    // Accept -Doptimize=<mode> too, so orbit can be consumed as a
    // `b.dependency("orbit", .{ .target = ..., .optimize = ... })` package
    // dependency without the downstream build script tripping over an
    // "invalid option: -Doptimize" error.
    const optimize = b.standardOptimizeOption(.{});

    // Expose orbit.zig as an importable module ("orbit") so downstream
    // build.zig files can do:
    //   const orbit_dep = b.dependency("orbit", .{});
    //   exe.root_module.addImport("orbit", orbit_dep.module("orbit"));
    // This is the module referenced by README.md's "Getting Started" section.
    const orbit_module = b.addModule("orbit", .{
        .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = "src/orbit.zig" } },
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "orbit",
        .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = "src/main.zig" } },
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("orbit", orbit_module);
    b.installArtifact(exe);

    // Add test_theory executable
    const test_exe = b.addExecutable(.{
        .name = "test_theory",
        .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = "src/test_theory.zig" } },
        .target = target,
        .optimize = optimize,
    });
    test_exe.root_module.addImport("orbit", orbit_module);
    b.installArtifact(test_exe);

    const test_step = b.step("test-theory", "Run THEORY.md example test");
    const test_run = b.addRunArtifact(test_exe);
    test_step.dependOn(&test_run.step);
}
