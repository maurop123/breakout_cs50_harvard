Powerup = Class{}

function Powerup:init(x, y, lockedBrickPresent)
    self.x = x
    self.y = y
    self.dy = 0

    self.width = 16
    self.height = 16

    -- add a timer for random powerup spawns
    self.start = love.timer.getTime()
    self.timerInterval = math.random(5, 10)

    if lockedBrickPresent and math.random(0, 10) < 5 then
        self.powerupType = 2
    else
        self.powerupType = 1
    end
end

function Powerup:update(dt)
    self.dy = POWERUP_SPEED
    self.y = self.y + self.dy * dt
end

function Powerup:render()
    if self.powerupType == 2 then
        -- brick unlock powerup
        love.graphics.draw(gTextures['main'], gFrames['powerups'][2], self.x, self.y)
    else
        -- multiple balls powerup
        love.graphics.draw(gTextures['main'], gFrames['powerups'][1], self.x, self.y)
    end
end
