const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const pthread = b.addLibrary(.{
        .name = "pthread",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    var flags: std.ArrayList([]const u8) = .init(b.allocator);
    defer flags.deinit();
    try flags.appendSlice(&.{
        "-std=c99",
        "-D__PTW32_BUILD_INLINED",
        "-D__PTW32_STATIC_LIB",
        "-DHAVE_CONFIG_H",
    });
    try flags.appendSlice(switch (target.result.cpu.arch) {
        .arm => &.{ "-D__PTW32_ARCHARM", "-D_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE=1" },
        .aarch64 => &.{ "-D__PTW32_ARCHARM64", "-D_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE=1" },
        .x86_64 => &.{"-D__PTW32_ARCHAMD64"},
        .x86 => &.{"-D__PTW32_ARCHX86"},
        else => blk: {
            pthread.step.dependOn(&b.addFail("pthreads4w is unsupported on the target architecture").step);
            break :blk &.{};
        },
    });
    if (target.result.os.tag != .windows) {
        pthread.step.dependOn(&b.addFail("pthreads4w is unsupported on the target os").step);
    }
    const config = b.addConfigHeader(.{}, .{
        .__PTW32_CONFIG_H = 1,
        .__PTW32_BUILD = 1,
        .HAVE_CPU_AFFINITY = 1,
        .HAVE_SIGNAL_H = 1,
        .HAVE_TASM32 = 1,
        .HAVE_STDINT_H = 1,
    });
    pthread.addConfigHeader(config);
    pthread.installConfigHeader(config);
    pthread.addIncludePath(b.path("."));
    for ([_][]const u8{ "_ptw32.h", "pthread.h", "sched.h", "semaphore.h" }) |header| {
        pthread.installHeader(b.path(header), header);
    }
    pthread.addCSourceFile(.{
        .file = b.path("pthread.c"),
        .flags = flags.items,
    });
    b.installArtifact(pthread);

    const test_step = b.step("test", "Run pthread4w's tests");
    for (test_sources) |test_source| {
        const test_exe = b.addExecutable(.{
            .name = test_source,
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });
        test_exe.linkLibrary(pthread);
        test_exe.addCSourceFile(.{
            .file = b.path("tests").path(b, test_source),
            .flags = &.{"-std=c99"},
        });
        const run_test = b.addRunArtifact(test_exe);
        run_test.expectExitCode(0);
        test_step.dependOn(&run_test.step);
    }
}

const test_sources: []const []const u8 = &.{
    "affinity1.c",
    "affinity2.c",
    "affinity3.c",
    "affinity4.c",
    "affinity5.c",
    "affinity6.c",
    "barrier1.c",
    "barrier2.c",
    "barrier3.c",
    "barrier4.c",
    "barrier5.c",
    "barrier6.c",
    "cancel1.c",
    "cancel2.c",
    "cancel3.c",
    "cancel4.c",
    "cancel5.c",
    "cancel6a.c",
    "cancel6d.c",
    "cancel7.c",
    "cancel8.c",
    "cleanup0.c",
    "cleanup1.c",
    "cleanup2.c",
    "cleanup3.c",
    "condvar1_1.c",
    "condvar1_2.c",
    "condvar1.c",
    "condvar2_1.c",
    "condvar2.c",
    "condvar3_1.c",
    "condvar3_2.c",
    "condvar3_3.c",
    "condvar3.c",
    "condvar4.c",
    "condvar5.c",
    "condvar6.c",
    "condvar7.c",
    "condvar8.c",
    "condvar9.c",
    "context1.c",
    "count1.c",
    "create1.c",
    "create2.c",
    "create3.c",
    "delay1.c",
    "delay2.c",
    "detach1.c",
    "equal0.c",
    "equal1.c",
    "errno0.c",
    "errno1.c",
    "exception1.c",
    "exception2.c",
    "exception3_0.c",
    "exception3.c",
    "exit1.c",
    "exit2.c",
    "exit3.c",
    "exit4.c",
    "exit5.c",
    "exit6.c",
    "eyal1.c",
    "inherit1.c",
    "join0.c",
    "join1.c",
    "join2.c",
    "join3.c",
    "join4.c",
    "kill1.c",
    "mutex1.c",
    "mutex1e.c",
    "mutex1n.c",
    "mutex1r.c",
    "mutex2.c",
    "mutex2e.c",
    "mutex2r.c",
    "mutex3.c",
    "mutex3e.c",
    "mutex3r.c",
    "mutex4.c",
    "mutex5.c",
    "mutex6.c",
    "mutex6e.c",
    "mutex6es.c",
    "mutex6n.c",
    "mutex6r.c",
    "mutex6rs.c",
    "mutex6s.c",
    "mutex7.c",
    "mutex7e.c",
    "mutex7n.c",
    "mutex7r.c",
    "mutex8.c",
    "mutex8e.c",
    "mutex8n.c",
    "mutex8r.c",
    "name_np1.c",
    "name_np2.c",
    "once1.c",
    "once2.c",
    "once3.c",
    "once4.c",
    "priority1.c",
    "priority2.c",
    "reinit1.c",
    "reuse1.c",
    "reuse2.c",
    "robust1.c",
    "robust2.c",
    "robust3.c",
    "robust4.c",
    "robust5.c",
    "rwlock1.c",
    "rwlock2.c",
    "rwlock2_t.c",
    "rwlock3.c",
    "rwlock3_t.c",
    "rwlock4.c",
    "rwlock4_t.c",
    "rwlock5.c",
    "rwlock5_t.c",
    "rwlock6.c",
    "rwlock6_t2.c",
    "rwlock6_t.c",
    "self1.c",
    "self2.c",
    "semaphore1.c",
    "semaphore2.c",
    "semaphore3.c",
    "semaphore4.c",
    "semaphore4t.c",
    "semaphore5.c",
    "sequence1.c",
    "sizes.c",
    "spin1.c",
    "spin2.c",
    "spin3.c",
    "spin4.c",
    "stress1.c",
    "timeouts.c",
    "tryentercs.c",
    "tsd1.c",
    "tsd2.c",
    "tsd3.c",
    "valid1.c",
    "valid2.c",
};
