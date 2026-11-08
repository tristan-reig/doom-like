local Map = require("src.map")
local Player = require("src.player")
local Raycaster = require("src.raycaster")
local Sprites = require("src.sprites")
local Weapon = require("src.weapon")
local Sound = require("src.sound")
local Hud = require("src.hud")
local Pickups = require("src.pickups")
local Level = require("src.level")
local Doors = require("src.doors")
local StatusBar = require("src.statusbar")
local Lighting = require("src.lighting")

local levels = {
    "levels/e1m1.txt",
    "levels/e1m2.txt"
}

local player
local weapon
local showMap = true
local targetInSight = false
local wasPressingFire = false
local weaponDefs = Weapon.defs

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

local function damagePlayer(amount, source)
    if player.dead then return end
    amount = Pickups.absorb(player, amount)
    player.health = math.max(0, player.health - amount)
    Hud.hurt(amount)
    StatusBar.hurt(amount, source, player)
    if player.health <= 0 then
        player.dead = true
        Sound.play("playerDeath")
    else
        Sound.play("playerPain")
    end
end

local function pickUp(kind, dropped)
    local message, newWeapon = Pickups.apply(player, kind, dropped)
    if not message then return false end
    Hud.message(message)
    if newWeapon then
        Sound.play("weaponUp")
        StatusBar.grin()
        weapon:select(newWeapon)
    else
        Sound.play("itemUp")
    end
    return true
end

-- Assez de munitions pour tirer avec cette arme ?
local function canFire(def)
    return player.ammo[def.ammo] >= 1
end

-- Conséquences du tirs
local function onFire(def, refire)
    player.ammo[def.ammo] = player.ammo[def.ammo] - 1
    Sound.play(def.sound)
    Sprites.alert(player)
    for _ = 1, def.shot.pellets do
        local spread = 0
        -- Le premier tir du pistolet est très précis
        if not (def.shot.accurateFirst and not refire) then
            spread = (math.random() - math.random()) * math.rad(def.shot.spread)
        end
        local wallDist = Raycaster.castRay(player.x, player.y, player.angle + spread)
        local hit = Sprites.hitscan(player, wallDist, spread)
        if hit then
            Sprites.damage(hit, 5 * math.random(1, 3), player)
        end
    end
end

-- Changement vers la meilleure arme avec des munitions
local function switchToBestWeapon()
    for _, name in ipairs(weaponDefs.order) do
        if player.weapons[name] and name ~= weapon.current and canFire(weaponDefs[name]) then
            weapon:select(name)
            return
        end
    end
end

-- Choisir l'arme d'un slot
local function selectSlot(slot)
    for _, name in ipairs(weaponDefs.order) do
        if weaponDefs[name].slot == slot and player.weapons[name] then
            weapon:select(name)
        end
    end
end

-- Passage à l'arme suivante / précédente
local function cycleWeapon(direction)
    local owned = {}
    for _, name in ipairs(weaponDefs.order) do
        if player.weapons[name] then table.insert(owned, name) end
    end
    table.sort(owned, function(a, b) return weaponDefs[a].slot < weaponDefs[b].slot end)
    local target = weapon.pending or weapon.current
    for i, name in ipairs(owned) do
        if name == target then
            weapon:select(owned[(i - 1 + direction) % #owned + 1])
            return
        end
    end
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

local USE_RANGE = 48

local function pointAhead(dist)
    return player.x + math.cos(player.angle) * (dist + 1),
        player.y + math.sin(player.angle) * (dist + 1)
end

local function use()
    local dist, tile, _, _, door = Raycaster.castRay(player.x, player.y, player.angle, true)

    -- Porte entrouverte
    if door and door.dist < USE_RANGE then
        local col, row = Map.cellAt(pointAhead(door.dist))
        Doors.use(col, row, player, Map.tileSize)
        return
    end
    if dist >= USE_RANGE then return end

    -- Porte fermée
    if tile == Map.DOOR then
        local col, row = Map.cellAt(pointAhead(dist))
        Doors.use(col, row, player, Map.tileSize)

    -- L'interrupteur de sortie
    elseif tile == Map.EXIT then
        local hx, hy = pointAhead(dist)
        Map.setTileAt(hx, hy, Map.EXIT_ON) -- l'interrupteur devient vert
        Sound.play("exitSwitch")
        gameState = "exiting"
        exitTimer = 1
    end
end

function love.load()
    player = Player.new(0, 0, 0)
    player.health = 100
    player.dead = false
    player.armor = 0
    player.ammo = { bullets = 50, shells = 0 }
    player.weapons = { pistol = true }

    Hud.load()
    StatusBar.load()
    Sprites.onPlayerHit = damagePlayer
    Sprites.onPickup = pickUp
    Raycaster.load()
    Sprites.load()
    Sound.load()
    weapon = Weapon.new("pistol")

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

    -- Impossible de tirer sans cartouches
    if wantFire and weapon.state == "ready" and not canFire(weapon:def()) and not weapon.pending then
        if not wasPressingFire then Sound.play("noAmmo") end
        switchToBestWeapon()
    end
    wasPressingFire = wantFire
    StatusBar.update(dt, player, wantFire)

    weapon:update(dt, player, wantFire, canFire, onFire)
    Lighting.extra = weapon:currentLight()

    -- Y a-t-il une cible dans le viseur ?
    local centerCol = math.floor(love.graphics.getWidth() / 2)
    targetInSight = Sprites.hitscan(player, Raycaster.zbuffer[centerCol] or math.huge) ~= nil

    Sprites.update(dt, player)

    -- Les portes s'ouvrent / se ferment (pas sur le joueur)
    Doors.update(dt, player, Map.tileSize, function(col, row)
        return Sprites.cellOccupied(col, row, player)
    end)
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
    Sprites.draw(player, Raycaster.zbuffer, projDist, Raycaster.fadeDist, Raycaster.doorbuffer, "behind")
    Raycaster.drawDoors()
    Sprites.draw(player, Raycaster.zbuffer, projDist, Raycaster.fadeDist, Raycaster.doorbuffer, "front")

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
    local ownedSlots = {}
    for name in pairs(player.weapons) do ownedSlots[weaponDefs[name].slot] = true end
    StatusBar.draw(player, ownedSlots, player.ammo[weapon:def().ammo])
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

function love.wheelmoved(x, y)
    if gameState == "playing" and not player.dead and y ~= 0 then
        cycleWeapon(y > 0 and 1 or -1)
    end
end

function love.keypressed(key, scancode)
    local slot = tonumber(scancode)
    if slot and slot >= 1 and slot <= 7 and gameState == "playing" and not player.dead then
        selectSlot(slot)
        return
    end

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
