local Map = require("src.map")
local Player = require("src.player")
local Raycaster = require("src.raycaster")

local player
local showMap = true

function love.load()
    player = Player.new(1.5 * Map.tileSize, 1.5 * Map.tileSize, 0)
end

function love.update(dt)
    player:update(dt)
end

function love.draw()
    -- 1. La vue 3D
    Raycaster.draw(player)

    -- 2. La minimap
    if showMap then
        Map.draw(0.25)
        player:draw(0.25)
    end

    -- 3. Les infos
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 620 - 20)
    love.graphics.print("ZQSD/WASD : bouger   Flèches : tourner   Tab : minimap   Échap : quitter", 10, 620)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "tab" then
        showMap = not showMap
    end
end
