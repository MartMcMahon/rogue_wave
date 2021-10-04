local lg = love.graphics
local t = 0

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


    wave_pos = {50, 90}
    wave = Wave:new(wave_pos[1], wave_pos[2])
    amp_slider = Slider:new(130, 320, 1, 100, "amplitude", 40)
    freq_slider = Slider:new(130, 340, 0, .0628, "freq", 0.01)
    phase_slider = Slider:new(130, 360, 0, 6, "phase", 0)

    amp_slider.wave = wave
    freq_slider.wave = wave
    phase_slider.wave = wave
end

function love.keypressed(key) --, scancode, isrepeat).
  -- if key == "space" then
  --   qs:queue(tone)
  --   qs:play()
  -- end
end

function love.update(dt)
  t = t + dt

  freq_slider:update(dt)
  amp_slider:update(dt)
  phase_slider:update(dt)
  wave:update(dt)
end

function love.draw()
  love.graphics.setColor(255, 255, 255, 1)
  wave:draw(t)

  amp_slider:draw()
  freq_slider:draw()
  phase_slider:draw()
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
  self.amplitude = 1
  self.freq = 1
  self.phase = 0
  return self
end
function Wave:update(dt)

  print('amp', self.amplitude)
  print('freq', self.freq)
  print('phase', self.phase)

  self.vals = {}
  for x=0,3000 do
    -- x = x/1000
    graph_x = x/3000
    graph_y = -self.amplitude * math.sin(self.freq/100 * (graph_x + self.phase))

    -- print("---------------------")
    -- print(" | " .. graph_x .. " | ")
    -- print(" | " .. graph_y .. " | ")
    -- print("---------------------")

    -- new_x, new_y = graph_to_pixel(graph_x, graph_y, 300, 200)
    -- table.insert(self.vals, graph_x*100 + self.x)
    -- table.insert(self.vals, new_y + self.y)

    table.insert(self.vals, self.x + graph_x*300)
    table.insert(self.vals, -self.amplitude * math.sin(self.freq * (x + self.phase*3000)) + self.y)
  end

end
function Wave:draw(t)
  col = (t/3 % 1) * 10
  -- lg.setColor(col, col, col, t
  lg.setColor(1, 1, 1, (t % 1/2) +.3)
  lg.points(self.vals)
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
  print(self.wave)

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

