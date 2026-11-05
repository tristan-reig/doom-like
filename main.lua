local Map = require("src.map")
local Player = require("src.player")
local Raycaster = require("src.raycaster")
local Sprites = require("src.sprites")
local Weapon = require("src.weapon")
local Sound = require("src.sound")
local Hud = require("src.hud")
local Pickups = require("src.pickups")
local Level = require("src.level")

local levels = {
    "levels/e1m1.txt",
    "levels/e1m2.txt"
}

local player
local weapon
local showMap = true
local targetInSight = false
local wasPressingFire = false

local gameState = "playing"
local levelIndex = 1
local levelName = ""
local levelTime = 0
local exitTimer = 0

local mouseSensitivity = 0.002
local mouseCaptured = false

local function setMouseCaptured(captured)
    mouseCaptured = captured
    love.mouse.setRelativeMode(captured)
end

local function damagePlayer(amount)
    if player.dead then return end
    amount = Pickups.absorb(player, amount)
    player.health = math.max(0, player.health - amount)
    Hud.hurt(amount)
    if player.health <= 0 then
        player.dead = true
        Sound.play("playerDeath")
    else
        Sound.play("playerPain")
    end
end

local function pickUp(kind)
    local message = Pickups.apply(player, kind)
    if not message then return false end
    Sound.play("itemUp")
    Hud.message(message)
    return true
end

-- Charge et démarre le niveau
local function startLevel(index)
    levelIndex = index
    local level = Level.load(levels[index])
    Level.start(level, player, Sprites)
    levelName = level.name
    levelTime = 0
    gameState = "playing"
    Hud.message(level.name)
end

local function use()
    local dist, tile = Raycaster.castRay(player.x, player.y, player.angle)
    if tile == Map.EXIT and dist < 48 then
        -- Point touché par le rayon, un peu enfoncé dans le mur pour tomber dans la bonne case
        local hx = player.x + math.cos(player.angle) * (dist + 1)
        local hy = player.y + math.sin(player.angle) * (dist + 1)
        Map.setTileAt(hx, hy, Map.EXIT_ON) -- l'interrupteur passe au vert
        Sound.play("exitSwitch")
        gameState = "exiting"
        exitTimer = 1 -- une seconde avant l'écran de fin
    end
end

function love.load()
    player = Player.new(0, 0, 0)
    player.health = 100
    player.dead = false
    player.armor = 0
    player.ammo = 20

    Hud.load()
    Sprites.onPlayerHit = damagePlayer
    Sprites.onPickup = pickUp
    Raycaster.load()
    Sprites.load()
    Sound.load()
    weapon = Weapon.new()

    startLevel(1)
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
    Hud.update(dt)

    if gameState == "intermission" or gameState == "victory" then return end

    if gameState == "exiting" then
        exitTimer = exitTimer - dt
        if exitTimer <= 0 then gameState = "intermission" end
        return
    end

    if not player.dead then
        levelTime = levelTime + dt
        local oldX, oldY = player.x, player.y
        player:update(dt)
        Sprites.collide(player, oldX, oldY)
    end

    -- Clic gauche pour tirer
    local wantFire = not player.dead and mouseCaptured
        and (love.mouse.isDown(1) or love.keyboard.isDown("lctrl", "rctrl"))

    if wantFire and player.ammo <= 0 and not weapon.firing and not wasPressingFire then
        Sound.play("noAmmo")
    end
    wasPressingFire = wantFire

    if weapon:update(dt, player, wantFire and player.ammo > 0) then
        player.ammo = player.ammo - 1
        Sound.play("shotgun")
        Sprites.alert(player)
        for _ = 1, 7 do
            local spread = (math.random() - math.random()) * math.rad(5.6)
            local wallDist = Raycaster.castRay(player.x, player.y, player.angle + spread)
            local hit = Sprites.hitscan(player, wallDist, spread)
            if hit then
                Sprites.damage(hit, 5 * math.random(1, 3), player) -- Dégâts aléatoires
            end
        end
    end

    -- Y a-t-il une cible dans le viseur ?
    local centerCol = math.floor(love.graphics.getWidth() / 2)
    targetInSight = Sprites.hitscan(player, Raycaster.zbuffer[centerCol] or math.huge) ~= nil

    Sprites.update(dt, player)
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
    if not player.dead then
        weapon:draw()
        drawCrosshair()
    end

    -- La minimap
    if showMap then
        local scale = math.min(0.25, 240 / (Map.cols * Map.tileSize))
        Map.draw(scale)
        player:draw(scale)
    end

    -- Le HUD
    Hud.draw(player)

    -- FPS et aide
    local w = love.graphics.getWidth()
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.printf("FPS: " .. love.timer.getFPS(), 0, 40, w - 10, "right")
    love.graphics.printf("ZQSD : bouger   Souris : tourner   Clic/Ctrl : tirer   E : utiliser\nTab : minimap   Échap : souris / quitter", 0, 58, w - 10, "right")
 
    -- Écrans de fin
    if gameState == "intermission" then
        local stats = Sprites.stats
        Hud.drawIntermission({
            name = levelName,
            kills = stats.kills, totalKills = stats.totalKills,
            items = stats.items, totalItems = stats.totalItems,
            time = levelTime,
            last = levelIndex == #levels,
        })
    elseif gameState == "victory" then
        Hud.drawVictory()
    end
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
    elseif gameState == "intermission" and key == "space" then
        if levelIndex < #levels then
            startLevel(levelIndex + 1)
        else
            gameState = "victory"
        end
    elseif gameState == "victory" and key == "space" then
        love.event.quit("restart")
    elseif player.dead and key == "space" then
        love.event.quit("restart")
    elseif gameState == "playing" and not player.dead and (key == "e" or key == "space") then
        use()
    end
end
