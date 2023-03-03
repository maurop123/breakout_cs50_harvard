PowerUp = Class{}

function PowerUp:init(x, y)
    self.x = x
    self.y = y
    self.dy = 0

    -- add a timer for random powerup spawns
    self.start = love.timer.getTime()
    self.timerInterval = math.random(5, 10)
end

function PowerUp:update(dt)
    self.dy = POWERUP_DROP_SPEED
    self.y = self.y + self.dy * dt
end

function PowerUp:render()
    love.graphics.draw(gTextures['main'], gFrames['powerups'][1], self.x, self.y)
end
