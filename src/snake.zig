use @import("deps/zig-sdl2/src/index.zig");

const std = @import("std");
const warn = std.debug.warn;
const ArrayList = std.ArrayList;
const c_allocator = std.heap.c_allocator;
const DefaultPrng = std.rand.DefaultPrng;

var rng = DefaultPrng.init(0);

const Block = struct {
  pub x: i32,
  pub y: i32
};

const Vec = struct {
  pub x: i32,
  pub y: i32,

  pub fn init(x: i32, y: i32) Vec {
    return Vec {
      .x = x,
      .y = y
    };
  }
};

const InputState = struct {
  const Dir = enum {
    LEFT,
    RIGHT,
    UP,
    DOWN,
    NONE
  };

  pub dir: Dir,

  pub fn init() InputState {
    return InputState {
      .dir = Dir.NONE
    };
  }
};

const GameState = struct {
  pub blockList: ArrayList(Block),
  pub food: Block,
  pub done: bool,
  pub dir: InputState.Dir,

  pub fn init() GameState {
    var gs = GameState {
      .blockList = ArrayList(Block).init(c_allocator),
      .food = Block {
        .x = 1,
        .y = 1
      },
      .done = false,
      .dir = InputState.Dir.RIGHT
    };

    gs.blockList.append(Block {.x = 2, .y = 2 }) catch unreachable;

    return gs;
  }

  pub fn update(self: *GameState, is: InputState) void {
    // Get the current direction.
    const dir = switch(is.dir) {
      InputState.Dir.NONE => self.dir,
      else => is.dir
    };

    // Update the position.
    const updateVec = switch(dir) {
       InputState.Dir.NONE => Vec.init(0, 0),
       InputState.Dir.LEFT => Vec.init(-1, 0),
       InputState.Dir.RIGHT => Vec.init(1, 0),
       InputState.Dir.UP => Vec.init(0, -1),
       InputState.Dir.DOWN => Vec.init(0, 1),
    };

    // Add one to the block list.
    if ((self.blockList.at(0).x + updateVec.x == self.food.x) and
        (self.blockList.at(0).y + updateVec.y == self.food.y)) {
      self.blockList.append(Block { .x = undefined, .y = undefined }) catch unreachable;
      
      self.food.x = @mod(rng.random.int(i32), 32);
      self.food.y = @mod(rng.random.int(i32), 24);
    }

    var blockSlice = self.blockList.toSlice();
    var i: usize = blockSlice.len - 1;
    while (i > 0) {
      blockSlice[i] = blockSlice[i-1];
      i -= 1;
    }

    blockSlice[0].x += updateVec.x;
    blockSlice[0].y += updateVec.y;

    self.dir = dir;
  }

  pub fn deinit(self: GameState) void {
    self.blockList.deinit();
  }
};

pub fn main() u8 {
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) != 0) {
        SDL_Log(c"failed to initialized SDL\n");
        return 1;
    }
    defer SDL_Quit();

    var renderer: *SDL_Renderer = undefined;
    var window: *SDL_Window = undefined;

    var r: SDL_Rect = undefined;

    if (SDL_CreateWindowAndRenderer(640, 480, SDL_WINDOW_SHOWN, &window, &renderer) != 0) {
        SDL_Log(c"failed to initialize window and renderer\n");
        return 1;
    }
    defer SDL_DestroyRenderer(renderer);
    defer SDL_DestroyWindow(window);

    SDL_SetWindowTitle(window, c"Zig Snake");

    var gs = GameState.init();
    defer gs.deinit();

    const frameTime: u32 = 100;
    var t: u32 = SDL_GetTicks();
    var lastFrame: u32 = t;
    while (!gs.done) {
      var is: InputState = InputState.init();

      var event: SDL_Event = undefined;
      while (SDL_PollEvent(&event) != 0) {
        switch(event.type) {
          SDL_QUIT => {
            gs.done = true;
          },
          else => {}
        }
      }
      
      const optional_keys: ?[*]const u8 = SDL_GetKeyboardState(null);

      if (optional_keys) |keys|  {
          if (keys[SDL_SCANCODE_UP] > 0) {
              is.dir = InputState.Dir.UP;
          }
          if (keys[SDL_SCANCODE_DOWN] > 0) {
              is.dir = InputState.Dir.DOWN;
          }
          if (keys[SDL_SCANCODE_LEFT] > 0) {
              is.dir = InputState.Dir.LEFT;
          }
          if (keys[SDL_SCANCODE_RIGHT] > 0) {
              is.dir = InputState.Dir.RIGHT;
          }
      }

      var new_t: u32 = SDL_GetTicks();
      
      // Only process one new "frame" per step.
      if (new_t - lastFrame > frameTime) {
        lastFrame = new_t;

        // Update one step of the simulation.
        gs.update(is);
      }

      t = new_t;

      _ = SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
      _ = SDL_RenderClear(renderer);
      
      const blockSize: i32 = 20;

      // Draw the food block
      _ = SDL_SetRenderDrawColor(renderer, 0, 128, 128, 255);
      r.w = blockSize;
      r.h = blockSize;

      r.x = gs.food.x * blockSize;
      r.y = gs.food.y * blockSize;

      _ = SDL_RenderFillRect(renderer, &r);

      // Draw the snake.
      _ = SDL_SetRenderDrawColor(renderer, 128, 0, 128, 255);
      for (gs.blockList.toSlice()) |block| {
        r.x = block.x * blockSize;
        r.y = block.y * blockSize;
        _ = SDL_RenderFillRect(renderer, &r);
      } 

      _ = SDL_RenderPresent(renderer);
    }

    return 0;
}
