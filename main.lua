local Map = require("src.map")
local Player = require("src.player")
local Raycaster = require("src.raycaster")
local Sprites = require("src.sprites")
local Weapon = require("src.weapon")

local player
local weapon
local showMap = true

local mouseSensitivity = 0.002
local mouseCaptured = false

local targetInSight = false

local function setMouseCaptured(captured)
    mouseCaptured = captured
    love.mouse.setRelativeMode(captured)
end

function love.load()
    player = Player.new(1.5 * Map.tileSize, 1.5 * Map.tileSize, 0)
    Raycaster.load()
    Sprites.load()
    weapon = Weapon.new()

    Sprites.add("barrel", 5, 2)
    Sprites.add("barrel", 6, 2)
    Sprites.add("column", 8, 3)
    Sprites.add("lamp", 2, 7)
    Sprites.add("tallLamp", 13, 2)
    Sprites.add("barrel", 12, 8)
    Sprites.add("lamp", 5, 5)
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

    local wantFire = mouseCaptured and (love.mouse.isDown(1) or love.keyboard.isDown("lctrl", "rctrl"))
    if weapon:update(dt, player, wantFire) then
        -- On cherche ce qu'on touche au centre de l'écran
        local centerCol = math.floor(love.graphics.getWidth() / 2)
        local wallDist = Raycaster.zbuffer[centerCol] or math.huge
        local hit = Sprites.hitscan(player, wallDist)
        if hit then
            Sprites.damage(hit)
        end
    end

    -- Y a-t-il une cible dans l'axe du viseur ?
    local centerCol = math.floor(love.graphics.getWidth() / 2)
    targetInSight = Sprites.hitscan(player, Raycaster.zbuffer[centerCol] or math.huge) ~= nil

    Sprites.update(dt)
end

local function drawCrosshair()
    local w, h = love.graphics.getDimensions()
    local cx, cy = math.floor(w / 2), math.floor(h / 2)

    if targetInSight then
        love.graphics.setColor(1, 0.2, 0.2, 0.9)
    else
        love.graphics.setColor(1, 1, 1, 0.8)
    end

    love.graphics.rectangle("fill", cx - 6, cy, 4, 1)
    love.graphics.rectangle("fill", cx + 3, cy, 4, 1)
    love.graphics.rectangle("fill", cx, cy - 6, 1, 4)
    love.graphics.rectangle("fill", cx, cy + 3, 1, 4)
end

function love.draw()
    -- La vue 3D
    local projDist = Raycaster.draw(player)

    --- Les objets
    Sprites.draw(player, Raycaster.zbuffer, projDist, Raycaster.fadeDist)

    -- L'arme et le viseur
    weapon:draw()
    drawCrosshair()

    -- La minimap
    if showMap then
        Map.draw(0.25)
        player:draw(0.25)
    end

    -- Les infos
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
