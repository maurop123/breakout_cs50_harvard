--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.balls = {}
    table.insert(self.balls, params.ball)
    self.ball = self.balls[1]
    self.level = params.level

    self.recoverPoints = 5000
    self.growPaddlePoints = 1000

    -- give ball random starting velocity
    self.ball.dx = math.random(-200, 200)
    self.ball.dy = math.random(-50, -60)

    -- add a timer for random powerup spawns
    self.start = love.timer.getTime()
    self.timerInterval = math.random(5, 10)

    -- if bricks has one that is locked
    self.hasLockedBrick = false
    self.unlockBrick = false
end


function PlayState:update(dt)

    -- handle pausing
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

   -- updates for powerup 
    if self.powerup then
        self.powerup:update(dt)
        self.start = love.timer.getTime()

        -- collision detection
        if ABCollision(self.paddle, self.powerup) then
            if self.powerup.powerupType == 1 then
              -- multiple balls powerup
                local ball1 = Ball(math.random(7)) -- random skin
                ball1.x = self.paddle.x + (self.paddle.width / 2) - 4
                ball1.y = self.paddle.y - 8
                ball1.dx = math.random(-200, 200)
                ball1.dy = math.random(-50, -60)
                table.insert(self.balls, ball1)

                local ball2 = Ball()
                ball2.x = self.paddle.x + (self.paddle.width / 2) - 4
                ball2.y = self.paddle.y - 8
                ball2.dx = math.random(-200, 200)
                ball2.dy = math.random(-50, -60)
                ball2.skin = math.random(7)
                table.insert(self.balls, ball2)
            else
              -- locked brick powerup
                self.unlockBrick = true
            end

            self.powerup = nil
        end
    end


    -- update positions based on velocity
    self.paddle:update(dt)

    -- Balls code
    for l, ball in pairs(self.balls) do
      ball:update(dt)

      self.ball = ball

      -- if ball goes below bounds, and it's the last ball in self.balls
      -- revert to serve state and decrease health
      if self.ball.y >= VIRTUAL_HEIGHT then
        if #self.balls == 1 then
          self.health = self.health - 1
          gSounds['hurt']:play()

          -- shrink paddle
          self.paddle:shrink()

          if self.health == 0 then
              gStateMachine:change('game-over', {
                  score = self.score,
                  highScores = self.highScores
              })
          else
              gStateMachine:change('serve', {
                  paddle = self.paddle,
                  bricks = self.bricks,
                  health = self.health,
                  score = self.score,
                  highScores = self.highScores,
                  level = self.level,
                  recoverPoints = self.recoverPoints
              })
          end
        else
          table.remove(self.balls, l)
        end
      end


      -- detect collision across all bricks with the ball
      for k, brick in pairs(self.bricks) do

          -- only check collision if we're in play
          if brick.inPlay and self.ball:collides(brick) then

              if not brick.locked then
                  -- add to score
                  self.score = self.score + (brick.tier * 200 + brick.color * 25)

                  -- trigger the brick's hit function, which removes it from play
                  brick:hit()

                  -- if we have enough points, recover a point of health
                  if self.score > self.recoverPoints then
                      -- can't go above 3 health
                      self.health = math.min(3, self.health + 1)

                      -- multiply recover points by 2
                      self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                      -- play recover sound effect
                      gSounds['recover']:play()
                  end

                  -- grow paddle if score enough points
                  if self.score > self.growPaddlePoints then
                      self.paddle:grow()
                      self.growPaddlePoints = self.growPaddlePoints + 1000
                  end

                  -- go to our victory screen if there are no more bricks left
                  if self:checkVictory() then
                      gSounds['victory']:play()

                      gStateMachine:change('victory', {
                          level = self.level,
                          paddle = self.paddle,
                          health = self.health,
                          score = self.score,
                          highScores = self.highScores,
                          ball = self.ball,
                          recoverPoints = self.recoverPoints
                      })
                  end
              end

              --
                  -- collision code for bricks
                  --
                  -- we check to see if the opposite side of our velocity is outside of the brick;
                  -- if it is, we trigger a collision on that side. else we're within the X + width of
                  -- the brick and should check to see if the top or bottom edge is outside of the brick,
                  -- colliding on the top or bottom accordingly 
                  --

                  -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                  -- so that flush corner hits register as Y flips, not X flips
              -- 
              if self.ball.x + 2 < brick.x and self.ball.dx > 0 then
                  
                  -- flip x velocity and reset position outside of brick
                  self.ball.dx = -self.ball.dx
                  self.ball.x = brick.x - 8
              
              -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
              -- so that flush corner hits register as Y flips, not X flips
              elseif self.ball.x + 6 > brick.x + brick.width and self.ball.dx < 0 then
                  
                  -- flip x velocity and reset position outside of brick
                  self.ball.dx = -self.ball.dx
                  self.ball.x = brick.x + 32
              
              -- top edge if no X collisions, always check
              elseif self.ball.y < brick.y then
                  
                  -- flip y velocity and reset position outside of brick
                  self.ball.dy = -self.ball.dy
                  self.ball.y = brick.y - 8
              
              -- bottom edge if no X collisions or top collision, last possibility
              else
                  
                  -- flip y velocity and reset position outside of brick
                  self.ball.dy = -self.ball.dy
                  self.ball.y = brick.y + 16
              end

              -- slightly scale the y velocity to speed up the game, capping at +- 150
              if math.abs(self.ball.dy) < 150 then
                  self.ball.dy = self.ball.dy * 1.02
              end

              -- Given collision, spawn powerup at brick if timer is up
              local now = love.timer.getTime()
              if (now - self.start) >= self.timerInterval then
                  self.powerup = Powerup(brick.x + 8, brick.y, self.hasLockedBrick)
              end

              -- only allow colliding with one brick, for corners
              break
          end
      end

      -- ball hits the paddle
      if self.ball:collides(self.paddle) then
          -- raise ball above paddle in case it goes below it, then reverse dy
          self.ball.y = self.paddle.y - 8
          self.ball.dy = -self.ball.dy

          --
          -- tweak angle of bounce based on where it hits the paddle
          --

          -- if we hit the paddle on its left side while moving left...
          if self.ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
              self.ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.ball.x))
          
          -- else if we hit the paddle on its right side while moving right...
          elseif self.ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
              self.ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.ball.x))
          end

          gSounds['paddle-hit']:play()
      end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        if brick.locked then
            if self.unlockBrick then
                brick.locked = false
                self.hasLockedBrick = false
            else
                self.hasLockedBrick = true
            end
        end

        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    for l, ball in pairs(self.balls) do
      ball:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end

    -- if self.powerup exists, render
    if self.powerup then
        self.powerup:render()
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end
