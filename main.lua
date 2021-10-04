local TITLE_TEXT = [[
██████╗  ██████╗  ██████╗ ██╗   ██╗███████╗    ██╗    ██╗ █████╗ ██╗   ██╗███████╗
██╔══██╗██╔═══██╗██╔════╝ ██║   ██║██╔════╝    ██║    ██║██╔══██╗██║   ██║██╔════╝
██████╔╝██║   ██║██║  ███╗██║   ██║█████╗      ██║ █╗ ██║███████║██║   ██║█████╗
██╔══██╗██║   ██║██║   ██║██║   ██║██╔══╝      ██║███╗██║██╔══██║╚██╗ ██╔╝██╔══╝
██║  ██║╚██████╔╝╚██████╔╝╚██████╔╝███████╗    ╚███╔███╔╝██║  ██║ ╚████╔╝ ███████╗
╚═╝  ╚═╝ ╚═════╝  ╚═════╝  ╚═════╝ ╚══════╝     ╚══╝╚══╝ ╚═╝  ╚═╝  ╚═══╝  ╚══════╝
]]
TITLE_SML = "Rogue Wave"
TITLE_UPPER = "ROGUE WAVE"

local GREEN = {20/255, 209/255, 6/255, 1}

local denver = require 'denver'
local lg = love.graphics
local t = 0

local State = {
  MENU = 1,
  PLAYING = 2,
  PAUSED = 3,
  LOSE = 4,
  WIN = 5,
}
local wave_matched = false
local level = 1

AMP_MAX = 100
FREQ_MAX = 0.0628
PHASE_MAX = 6

screen_x = 110
screen_y = 100
screen_width = 390
screen_height = 200


sound = {}
sound.rate = 44100  --sample rate
sound.bits = 16     --bit rate
sound.channel = 1
sound.initialPhase = 0
tau = math.pi*2

function lerp(a, b, t) return a + (b - a) * t end -- linear interpolation

function love.load()
    love.window.setMode(600, 400, { vsync = true, highdpi = true, resizable = true })

    -- qs = love.audio.newQueueableSource(tone:getSampleRate(), tone:getBitDepth(), tone:getChannelCount())

    game_state = State.MENU

    -- load font
    -- unispace_font = lg.newFont("unispace/unispace rg.ttf", 60)
    -- captain = lg.newFont("captain-lethargic-font/CaptainLethargic.ttf", 60)
    unicode_font = lg.newFont("unifont-14.0.01.ttf", 8)

    unicode_title = lg.newText(unicode_font, TITLE_TEXT)
    -- unispace_title = lg.newText(unispace_font, TITLE_SML)
    -- captain_title = lg.newText(captain, TITLE_SML)

    -- load audio
    menu_music = love.audio.newSource("menu.mp3", "stream")
    game_music = love.audio.newSource("game.mp3", "stream")

    wave_pos = {110, 200}
    player_wave = Wave:new(wave_pos[1], wave_pos[2])
    player_wave.isPlayer = true
    amp_slider = Slider:new(130, 320, 1, 100, "amplitude", 40)
    freq_slider = Slider:new(130, 340, 0, .0628, "freq", 0.01)
    phase_slider = Slider:new(130, 360, 0, 6, "phase", 0)
    amp_slider.wave = player_wave
    freq_slider.wave = player_wave
    phase_slider.wave = player_wave

    target_wave = Wave:new(wave_pos[1], wave_pos[2])

    -- seed star list
    -- (star seeds if you will)
    stars = {}
    for x=1,100 do
      table.insert(stars, math.random() * 600)
      table.insert(stars, math.random() * 400)
    end


    -- randomize target for init
    target_wave:randomize()
end

function love.keypressed(key) --, scancode, isrepeat).
  -- if key == "space" then
  --   qs:queue(tone)
  --   qs:play()
  -- end
end

function state_change(new_state)
  if new_state == nil then
    game_state = game_state + 1
  else
    game_state = new_state
  end
end

function love.update(dt)
  if game_state == State.MENU then
    MainMenu.update(dt)
  end

  if game_state == State.MENU and not menu_music:isPlaying() then
    love.audio.play(menu_music)
  end
  if game_state == State.PLAYING and not game_music:isPlaying() then
    love.audio.stop(menu_music)
    love.audio.play(game_music)
  end

  t = t + dt

  freq_slider:update(dt)
  amp_slider:update(dt)
  phase_slider:update(dt)
  player_wave:update(dt)

  target_wave:update(dt)
  target_wave.phase = target_wave.phase + dt/math.pi
  -- math.random(2, ) 2

  -- update star list
  for i=1,#stars do
    if i % 2 == 0 then
      math.randomseed(i)
      stars[i] = (stars[i] + 1 + math.random()) % 400
    end
  end
  math.randomseed(os.time())

  -- check win condition
  -- one off for amp is fine
  -- 3 decimals for freq is all you need
  -- phase is an anomoly
  -- print(math.floor(player_wave.freq * 1000))
  if player_wave.amplitude >= 0.8 * target_wave.amplitude
    and player_wave.amplitude <= 1.2 * target_wave.amplitude
    and math.floor(player_wave.freq * 1000) == math.floor(target_wave.freq * 1000)  then
    -- and player_wave.phase == target_wave.phase then

    -- play a sinus of 1sec at 440Hz

    if level > 0 then
      local sine = denver.get({waveform='sinus', frequency=player_wave.freq * 12000, length=1})
      love.audio.play(sine)
    end

    -- play a F#2 (available os)
    -- local square = denver.get({waveform='square', frequency='F#2', length=1})
    -- love.audio.play(square)

    wave_matched = true
  else
    wave_matched = false
  end

  -- if t % 2 then
  --   target_wave:randomize(dt)
  -- end

  -- check for click on enter button
  if love.mouse.isDown(1) then
    x, y = love.mouse.getPosition()
    if x > enter_button_x and x < enter_button_x + enter_button_width and
      y > enter_button_y and y < enter_button_y + enter_button_height then
      if wave_matched then
        level = level + 1
        print('new level', level)
        target_wave:randomize()
      end
    end
  end


  -- debugging click
  if love.mouse.isDown(1) then
    x, y = love.mouse.getPosition()
    if x > 500 and y < 50 then
      target_wave:randomize()
    end
  end
end


function love.draw()
  -- draw stars
  lg.setColor(1, 1, 1, 1)
  lg.points(stars)

  -- draw ship
  lg.setColor(82/255, 73/255, 62/255, 1)
  lg.rectangle("fill", 100, 300, 400, 100)
  lg.polygon("fill", 100, 300, 0, 360, 0, 400, 100, 400)
  lg.polygon("fill", 510, 300, 600, 360, 600, 400, 500, 400)
  lg.setColor(.1, .1, .1, 1)
  lg.rectangle("fill", 90, 0, 20, 400)
  lg.rectangle("fill", 500, 0, 20, 400)

  -- draw enter button
  enter_button_x = 450
  enter_button_y = 325
  enter_button_width = 25
  enter_button_height = 25

  lg.setColor(181/255, 175/255, 158/255, .6)
  if wave_matched then
    lg.setColor(unpack(GREEN))
  elseif math.floor(t) % 3 == 0 then
    lg.setColor(1, 189/255, 8/255, 1)
  end

  lg.rectangle("fill", enter_button_x, enter_button_y, enter_button_width, enter_button_height, enter_button_width/3, enter_button_height/3)

  -- draw screen
  lg.setColor(.7, .7, .7, 1)
  lg.rectangle("fill", screen_x - 2, screen_y -2, screen_width + 4, screen_height + 4)
  lg.setColor(.05, .08, .05, 1)
  lg.rectangle("fill", screen_x, screen_y, screen_width, screen_height)

  -- draw screen contents
  if game_state == State.MENU then
    MainMenu.draw(t)
  end
  if game_state == State.PLAYING then
    target_wave:draw(t)
    player_wave:draw(t)

    amp_slider:draw()
    freq_slider:draw()
    phase_slider:draw()
  end

  lg.setColor(20/255, 209/255, 6/255, 1)
  -- debugging square
  -- if wave_matched then
  --   lg.setColor(0, 1,0,1)
  -- else
  --   lg.setColor(1, 0,0,1)
  -- end
  lg.rectangle("fill", 500, 50, 50, 50)

  -- print('---------------')
  -- print('player amp', player_wave.amplitude)
  -- print('player freq', player_wave.freq)
  -- print('player phase', player_wave.phase)
  -- print('-----')
  -- print('target amp', target_wave.amplitude)
  -- print('target freq', target_wave.freq)
  -- print('target phase', target_wave.phase)
  -- print('---------------')

end

-- Constructor for a sine wave generator.
sine = function(generator)
    local tau = math.pi*2
    local generator = generator
    local increment = 1.0 / generator.rate --/ generator.channels
    local phase = generator.initialPhase
    return function(freq)
        phase = phase + increment
        generator.phase = phase
        local x = phase * freq
        -- 2 ops: 1 mul, 1 trig
        return math.sin(tau * x)
    end
end


-- Wave
Wave = {}
Wave.__index = Wave
function Wave:new(x, y)
  local self = {}
  setmetatable(self, Wave)
  self.x = x
  self.y = y
  self.vals = {}
  self.amplitude = 30
  self.freq = 0.01
  self.phase = 0
  self.isPlayer = false
  return self
end
function Wave:update(dt)

  -- print('amp', self.amplitude)
  -- print('freq', self.freq)
  -- print('phase', self.phase)
  --

  self.vals = {}
  for x=0,3900 do
    -- x = x/1000
    graph_x = x/3900
    -- graph_y = -self.amplitude * math.sin(self.freq/100 * (graph_x + self.phase))

    table.insert(self.vals, self.x + graph_x*390)
    table.insert(self.vals, -self.amplitude * math.sin(self.freq * (x + self.phase*3000)) + self.y)
  end
end
function Wave:draw(t)
  col = (t/3 % 1) * 10
  if self.isPlayer then
    lg.setColor(1, 1, 1, (t % 1/2) +.3)
  else
    lg.setColor(0, 1, 0, (t % 1/2) + .3)
  end
  lg.points(self.vals)
end
function Wave:randomize()
  self.amplitude = math.random() * AMP_MAX
  self.freq = math.random() * FREQ_MAX
  self.phase = math.random() * PHASE_MAX
  -- print('amp', self.amplitude)
  -- print('freq', self.freq)
  -- print('phase', self.phase)

end



-- function graph_to_pixel(graph_x, graph_y, window_x, window_y)
--   x = (graph_x / 6.28) * window_x
--   y = (graph_y / 100) * window_y
--   return x, y
-- end




-- Slider
size = {300, 10}
Slider = {}
Slider.__index = Slider
function Slider:new(x, y, min, max, type, val)
  local self = {}
  setmetatable(self, Slider)
  self.x = x
  self.y = y
  self.min = min
  self.max = max
  self.val = val or 0
  self.ball_x = self.x + (self.val / self.max) * (self.max - self.min)
  self.ball_y = self.y
  self.type = type
  self.wave = {amplitude = nil, freq = nil, phase = nil}

  if not self.max then
    print('nothing for max')
    self.max = 100
  end
  return self
end
function Slider:update(dt)
  if love.mouse.isDown(1) then
    x, y = love.mouse.getPosition()
    if x > self.x and x < self.x + size[1] and y > self.y and y < self.y + size[2] then
      self:move(x, y)
    end
  end
  if self.type == "amplitude" then
    self.wave.amplitude = self.val
  elseif self.type == "freq" then
    self.wave.freq = self.val
  elseif self.type == "phase" then
    self.wave.phase = self.val
  end
end
function Slider:move(x, y)
  self.val = self.max * (x - self.x) / size[1]
  self.ball_x  = x
end
function Slider:draw(dt)
  lg.setColor(1, 1, 1, 0.5)
  lg.rectangle("fill", self.x, self.y, size[1], size[2])
  lg.rectangle("fill", self.ball_x, self.ball_y, 3, 9)
  -- lg.circle("fill", self.ball_x, self.ball_y, 5)
end




start_button_x = 0
start_button_y = 0
start_button_width = 0
start_button_height = 0
MainMenu = {}
function MainMenu.update(dt)
  if love.mouse.isDown(1) then
      print("start")
    x, y = love.mouse.getPosition()
    if x > start_button_x and x < start_button_x + start_button_width
      and y > start_button_y and y < start_button_y + start_button_height then
      print("start")
      game_state = State.PLAYING
    end
  end
end
function MainMenu.draw(t)
  -- menu_buttons = { {screen_x + screen_width/4, screen_y + 100}, }
  start_button_width = 1.2 * screen_width/2
  start_button_x = screen_x + screen_width/2 - start_button_width/2
  start_button_y = screen_y + 100
  start_button_height = 60

  lg.setColor(.2, .7, .2, .8)
  lg.rectangle("line", start_button_x, start_button_y, start_button_width, start_button_height)
  -- lg.setColor(0, 138/255, 2/255, 1)
  lg.setColor(unpack(GREEN))

  lg.rectangle("fill", start_button_x, start_button_y, start_button_width, start_button_height)

  lg.draw(unicode_title, screen_x + 30, screen_y + 1)
  start_text = lg.newText(unicode_font, BLOCK_START_TEXT)
  lg.setColor(0, 0, 0, 1)
  lg.draw(start_text, start_button_x + 33, start_button_y + 3)
end

BLOCK_START_TEXT = [[
███████╗████████╗ █████╗ ██████╗ ████████╗
██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝
███████╗   ██║   ███████║██████╔╝   ██║
╚════██║   ██║   ██╔══██║██╔══██╗   ██║
███████║   ██║   ██║  ██║██║  ██║   ██║
╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝
]]
