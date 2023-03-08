Powerup = Class{}

function Powerup:init(x, y)
    self.x = x
    self.y = y
    self.dy = 0

    self.width = 16
    self.height = 16

    -- add a timer for random powerup spawns
    self.start = love.timer.getTime()
    self.timerInterval = math.random(5, 10)
end

function Powerup:update(dt)
    self.dy = POWERUP_SPEED
    self.y = self.y + self.dy * dt
end

function Powerup:render()
    love.graphics.draw(gTextures['main'], gFrames['powerups'][1], self.x, self.y)
end
