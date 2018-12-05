const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
  const mode = b.standardReleaseOptions();

  const snake = b.addExecutable("snake", "src/snake.zig");
  snake.setBuildMode(mode);
  snake.linkSystemLibrary("SDL2");
  snake.linkSystemLibrary("c");
  b.default_step.dependOn(&snake.step);

  const image = b.addExecutable("image", "src/SDL_image.zig");
  image.setBuildMode(mode);
  image.linkSystemLibrary("SDL2_image");
  image.linkSystemLibrary("SDL2");
  image.linkSystemLibrary("c");

  b.default_step.dependOn(&image.step);
  b.installArtifact(snake);
  b.installArtifact(image);
}
