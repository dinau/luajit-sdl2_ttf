local ffi = require"ffi"
--- SDL/image header
local sdl = require"sdl2_ffi"
local img = require"sdl2_image"
local ttf = require"sdl2_ttf"
require"utils"
----------------------------------------

local Input  = {none = 0,left = 1, right = 2, jump = 3 , restart = 4, quit = 5}
local Game   = {}
local Player = {}

--------------
--- newPlayer
--------------
function Player.newPlayer(texture) -- :Player type
  return {
   texture = texture
  }
end

------------
--- newGame
------------
function newGame(renderer)
  local fontName = "DejaVuSans.ttf"
  local f = ttf.OpenFont(fontName, 28)
  if sdlFailIf(f ~= nil,"Font Load: " .. fontName) then os.exit(1) end
  return  {
    renderer = renderer,
    inputs   = {false,false,false, false,false,false},
    player   = Player.newPlayer(img.LoadTexture(renderer,"img/space-400.jpg")),
    font     = f,
    -- method
    handleInput = Game.handleInput,
    render      = Game.render,
    renderText  = Game.renderText
  }
end

-----------
-- toInput
-----------
function toInput(key)
  if key == sdl.SCANCODE_Q or
     key == sdl.SDL_SCANCODE_RETURN or
     key == sdl.SDL_SCANCODE_SPACE or
     key == sdl.SDL_SCANCODE_ESCAPE then
    return Input.quit
  else
    return Input.none
  end
end

--------------------
-- Game:handleInput
--------------------
function Game:handleInput()
  local event = ffi.new("SDL_Event")
  while sdl.pollEvent(event) ~= 0 do
    local kind = event.type
    if kind == sdl.QUIT then
      self.inputs[Input.quit] = true
    elseif kind == sdl.KEYDOWN then
      dprint("keydown")
      self.inputs[toInput(event.key.keysym.scancode)] = true
    elseif kind == sdl.KEYUP then
      dprint("keydup")
      self.inputs[toInput(event.key.keysym.scancode)] = false
    end
  end
end

--------------
--- drawImage
--------------
local angle = ffi.new("double[1]",0)
function drawImage(renderer,texture)
  if 0 > sdl.RenderCopyEx(renderer,texture,nil,nil,angle[0],nil,sdl.FLIP_NONE) then
    print("Error!: RenderCopy() ")
  end
  local speed = 0.05
  angle[0]= angle[0] + speed
end

---------------
--- Game:render
---------------
function Game:render()
  sdl.RenderClear(self.renderer)
  drawImage(self.renderer,self.player.texture)
  local fontColor = ffi.new("SDL_Color",{0xff, 0xff, 0xff, 0xff})
  self:renderText("True Type Font Test", 50, 150, fontColor)
  self:renderText("Quit:    [Q] or [Space]",50, 250, fontColor)
  sdl.RenderPresent(self.renderer)
end

------------------
--- renderTextSub
------------------
function renderTextSub(renderer, font, text, x, y, outline, color)
  ttf.SetFontOutline(font,outline)
  local surface = ttf.RenderUTF8_Blended(font, text, color)
  if sdlFailIf(nil ~= surface,"Could not render text surface") then os.eixt(1) end
  sdl.SetSurfaceAlphaMod(surface, color.a)
  local source = ffi.new("SDL_Rect",{0, 0, surface.w, surface.h})
  local dest   = ffi.new("SDL_Rect",{x - outline, y - outline, surface.w, surface.h})
  local texture = sdl.CreateTextureFromSurface(renderer,surface)
  if sdlFailIf(nil ~= texture,"Could not create texture from rendered text") then os.eixt(1) end
  sdl.FreeSurface(surface)
  sdl.RenderCopyEx(renderer, texture, source, dest, 0.0, nil, sdl.FLIP_NONE)
  sdl.DestroyTexture(texture)
end

---------------
--- renderText
---------------
function Game:renderText(text, x, y, color)
  local outlineColor = ffi.new("SDL_Color",{0, 0, 0, 0x8f})
  renderTextSub(self.renderer, self.font, text, x, y, 2, outlineColor)
  renderTextSub(self.renderer, self.font, text, x, y, 0, color)
end
---------
--- main
---------
function main()
  if sdlFailIf(0 == sdl.init(sdl.INIT_VIDEO + sdl.INIT_TIMER + sdl.INIT_EVENTS),
    "SDL2 initialization failed") then os.exit(1) end
  if sdlFailIf(sdl.TRUE == sdl.SetHint("SDL_RENDER_SCALE_QUALITY", "2"),
     "Linear texture filtering could not be enabled") then os.exit(1) end

  local imgFlags = img.INIT_JPG
  if sdlFailIf(0 ~= img.Init(imgFlags), "SDL2 Image initialization failed") then os.exit(1) end
  if sdlFailIf(0 == ttf.Init(), "SDL2_tff font driver initialization failed") then os.exit(1) end

  local window = sdl.CreateWindow("SDL2_ttf test written in Luajit",
      sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED,
      480, 480, sdl.WINDOW_SHOWN)
  if sdlFailIf(0 ~= window,"Window could not be created") then os.exit(1) end

  local renderer = sdl.CreateRenderer(window,-1,
    sdl.RENDERER_ACCELERATED or sdl.RENDERER_PRESENTVSYNC)
  if sdlFailIf(0 ~= renderer,"Renderer could not be created") then os.exit(1) end

  --sdl.SetRenderDrawColor(renderer,0x08,0x88,0xff,255)
  sdl.SetRenderDrawColor(renderer,0x00,0x0,0x0,255)

  game = newGame(renderer)

  --------------
  --- Main loop
  --------------
  while not game.inputs[Input.quit] do
    game:handleInput()
    game:render()
  end

  --------------
  --- End procs
  --------------
  sdl.DestroyRenderer(renderer)
  sdl.DestroyWindow(window)
  ttf.Quit()
  img.Quit()
  sdl.Quit()
end

---------
--- main
---------
main()
