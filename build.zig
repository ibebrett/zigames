const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
  const mode = b.standardReleaseOptions();
  const snake = b.addExecutable("snake", "src/snake.zig");
  snake.setBuildMode(mode);
  snake.linkSystemLibrary("SDL2");
  snake.linkSystemLibrary("c");

  b.default_step.dependOn(&snake.step);
  b.installArtifact(snake);
}
