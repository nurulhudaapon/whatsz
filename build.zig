const std = @import("std");
const zx = @import("zx");

pub fn build(b: *std.Build) !void {
    // --- Target and Optimize from `zig build` arguments ---
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // --- Root Module ---
    const mod = b.addModule("root_mod", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const mcp_mod = b.addModule("mcp_mod", .{
        .root_source_file = b.path("src/mcp.zig"),
        .target = target,
        .optimize = optimize,
    });

    // --- ZX Setup (sets up ZX, dependencies, executables and `serve` step) ---
    const site_exe = b.addExecutable(.{
        .name = "zx_site",
        .root_module = b.createModule(.{
            .root_source_file = b.path("site/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "root_mod", .module = mod },
            },
        }),
    });

    _ = try zx.init(b, site_exe, .{
        .experimental = .{ .enabled_csr = true },
    });

    // --- MCP Exe --- //
    const mcp_exe = b.addExecutable(.{
        .name = "whatz_mcp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "mcp_mod", .module = mcp_mod },
            },
        }),
    });

    const zqlite = b.dependency("zqlite", .{
        .target = target,
        .optimize = optimize,
    });

    mcp_exe.linkLibC();
    mcp_exe.linkSystemLibrary("sqlite3");
    mcp_exe.root_module.addImport("zqlite", zqlite.module("zqlite"));

    b.installArtifact(mcp_exe);
    const run_mcp = b.addRunArtifact(mcp_exe);
    run_mcp.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_mcp.addArgs(args);
    }
    const run_step = b.step("run", "Run the MCP executable");
    run_step.dependOn(&run_mcp.step);
}
