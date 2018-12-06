const std = @import("std");

pub fn main() !void {
  // Load a text file.
  var f = try std.os.File.openRead("assets/map.txt");
  defer f.close();

  // Read it in 100 bytes a time.
  var buff : [100]u8 = undefined;
  _ = f.read(&buff);

  // ... Eventually figure out how to parse it in some way.
  std.debug.warn("{}", buff);
}
