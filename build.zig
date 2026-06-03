const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const discord = b.addModule("discord", .{
        .root_source_file = b.path("src/discord.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib_module = b.createModule(.{
        .root_source_file = b.path("src/discord.zig"),
        .target = target,
        .optimize = optimize,
    });
    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "discord",
        .root_module = lib_module,
    });
    b.installArtifact(lib);

    const test_module = b.createModule(.{
        .root_source_file = b.path("src/discord.zig"),
        .target = target,
        .optimize = optimize,
    });
    const tests = b.addTest(.{
        .root_module = test_module,
    });
    const run_tests = b.addRunArtifact(tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);

    const example_module = b.createModule(.{
        .root_source_file = b.path("examples/ping_bot.zig"),
        .target = target,
        .optimize = optimize,
    });
    example_module.addImport("discord", discord);
    const example = b.addExecutable(.{
        .name = "ping_bot",
        .root_module = example_module,
    });
    b.installArtifact(example);

    const slash_example_module = b.createModule(.{
        .root_source_file = b.path("examples/slash_bot.zig"),
        .target = target,
        .optimize = optimize,
    });
    slash_example_module.addImport("discord", discord);
    const slash_example = b.addExecutable(.{
        .name = "slash_bot",
        .root_module = slash_example_module,
    });
    b.installArtifact(slash_example);

    const discord_token = b.option([]const u8, "discord_token", "Bot token for the e2e_check live test") orelse "";
    const e2e_options = b.addOptions();
    e2e_options.addOption([]const u8, "discord_token", discord_token);
    const e2e_module = b.createModule(.{
        .root_source_file = b.path("examples/e2e_check.zig"),
        .target = target,
        .optimize = optimize,
    });
    e2e_module.addImport("discord", discord);
    e2e_module.addOptions("build_options", e2e_options);
    const e2e_example = b.addExecutable(.{
        .name = "e2e_check",
        .root_module = e2e_module,
    });
    b.installArtifact(e2e_example);
}
