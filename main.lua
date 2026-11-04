local Map = require("src.map")
local Player = require("src.player")
local Raycaster = require("src.raycaster")

local player
local showMap = true

local mouseSensitivity = 0.002
local mouseCaptured = false

local function setMouseCaptured(captured)
    mouseCaptured = captured
    love.mouse.setRelativeMode(captured)
end

function love.load()
    player = Player.new(1.5 * Map.tileSize, 1.5 * Map.tileSize, 0)
    Raycaster.load()
    setMouseCaptured(true)
end

-- Appelée à chaque mouvement de souris
function love.mousemoved(x, y, dx, dy)
    if mouseCaptured then
        player.angle = player.angle + dx * mouseSensitivity
    end
end

-- Un clic dans la fenêtre recapture la souris
function love.mousepressed(x, y, button)
    if not mouseCaptured then
        setMouseCaptured(true)
    end
end

function love.focus(focused)
    if not focused then
        setMouseCaptured(false)
    end
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
    love.graphics.print("ZQSD/WASD : bouger   Souris/Flèches : tourner   Tab : minimap   Échap : libérer la souris / quitter", 10, 620)
end

function love.keypressed(key)
    if key == "escape" then
        if mouseCaptured then
            setMouseCaptured(false)
        else
            love.event.quit()
        end
    elseif key == "tab" then
        showMap = not showMap
    end
end
