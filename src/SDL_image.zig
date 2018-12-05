use @import("deps/zig-sdl2/src/index.zig");

const c = @cImport({
    @cInclude("SDL2/SDL_image.h");
});

pub fn main() u8 {
  if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) != 0) {
    SDL_Log(c"failed to initialized SDL\n");
    return 1;
  }
  defer SDL_Quit();

  var renderer: *SDL_Renderer = undefined;
  var window: *SDL_Window = undefined;

  if (SDL_CreateWindowAndRenderer(640, 480, SDL_WINDOW_SHOWN, &window, &renderer) != 0) {
      SDL_Log(c"failed to initialize window and renderer\n");
      return 1;
  }
  defer SDL_DestroyRenderer(renderer);
  defer SDL_DestroyWindow(window);

  SDL_SetWindowTitle(window, c"Zig Image");

  // All of the below ptrCasting is because we have zig versions of the below
  // structs and the ones from the headers..
  // It would be nice to be able to say they are equivalent.
  var opt_renderer: ?*c.SDL_Renderer = @ptrCast(*c.SDL_Renderer, renderer);
  var tex: *SDL_Texture = undefined;
  const c_tex = c.IMG_LoadTexture(opt_renderer, c"assets/cityscape.png") orelse {
    SDL_Log(c"failed to load texture");
    return 1;
  };
  tex = @ptrCast(*SDL_Texture, c_tex);
  defer SDL_DestroyTexture(tex);

  var done: bool = false;
  while (!done) {
    var event: SDL_Event = undefined;
    while (SDL_PollEvent(&event) != 0) {
      switch(event.type) {
        SDL_QUIT => {
          done = true;
        },
        else => {}
      }
    }
    
    _ = SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    _ = SDL_RenderClear(renderer);
    _ = SDL_RenderCopy(renderer, tex, null, null);
    _ = SDL_RenderPresent(renderer);
  }

  return 0;
}
