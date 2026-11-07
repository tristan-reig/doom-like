local Map = require("src.map")
local Sound = require("src.sound")
local SpriteImages = require("src.sprite_images")
local SpriteRender = require("src.sprite_render")
local Missiles = require("src.missiles")
local AI = require("src.ai")
local Noise = require("src.noise")

local Sprites = {}

local TIC = 1 / 35

local typeDefs = {}
for _, category in ipairs({ "monsters", "projectiles", "items", "decorations" }) do
    for name, def in pairs(require("src.things." .. category)) do
        assert(not typeDefs[name], "Type défini deux fois : " .. name)
        typeDefs[name] = def
    end
end

Sprites.list = {}
-- Statistiques du niveau
Sprites.stats = { kills = 0, totalKills = 0, items = 0, totalItems = 0 }

function Sprites.clear()
    Sprites.list = {}
    Sprites.stats = { kills = 0, totalKills = 0, items = 0, totalItems = 0 }
end

function Sprites.countTotals()
    for _, s in ipairs(Sprites.list) do
        local def = typeDefs[s.type]
        if def.monster then
            Sprites.stats.totalKills = Sprites.stats.totalKills + 1
        elseif def.pickup then
            s.countsAsItem = true
            Sprites.stats.totalItems = Sprites.stats.totalItems + 1
        end
    end
end

function Sprites.load()
    SpriteImages.loadAll(typeDefs)
end

-- Applique les effets de l'image courante
local function enterFrame(s, player)
    local frame = typeDefs[s.type].states[s.state][s.frameIndex]
    s.frame = frame
    if frame.sound then
        local snd = frame.sound
        if type(snd) == "table" then snd = snd[math.random(#snd)] end
        Sound.playAt(snd, s.x, s.y, player)
    end
    if frame.notSolid then s.solid = false end
    if frame.explode then Sprites.radiusDamage(s, 128, player) end
    if frame.remove then s.removed = true end
    if frame.action then AI.actions[frame.action](s, player, Sprites) end
end

function Sprites.getDef(s)
    return typeDefs[s.type]
end

function Sprites.getDefByName(typeName)
    return typeDefs[typeName]
end

function Sprites.setState(s, stateName, player)
    s.state = stateName
    s.frameIndex = 1
    s.timer = 0
    enterFrame(s, player)
end

-- Ajoute un objet dans la carte.
function Sprites.add(typeName, col, row, angle)
    return Sprites.spawn(typeName, (col - 0.5) * Map.tileSize, (row - 0.5) * Map.tileSize, angle)
end

-- Crée un objet en (x, y)
function Sprites.spawn(typeName, x, y, angle)
    local def = typeDefs[typeName]
    assert(def, "Type de sprite inconnu : " .. tostring(typeName))

    local s = {
        type = typeName,
        x = x,
        y = y,
        angle = angle or 0,
        health = def.health,
        solid = def.solid,
        dead = false,
    }
    s.state = "idle"
    s.frameIndex = 1
    s.timer = 0
    s.frame = def.states.idle[1]
    table.insert(Sprites.list, s)
    return s
end
-- Lance un projectile depuis l'objet "owner" vers le point
function Sprites.spawnMissile(typeName, owner, tx, ty, spread)
    return Missiles.spawn(Sprites, typeName, owner, tx, ty, spread)
end

-- Fait avancer les animations et retire les objets détruits
function Sprites.update(dt, player)
    for _, s in ipairs(Sprites.list) do
        local states = typeDefs[s.type].states
        s.timer = s.timer + dt
        while not s.removed and s.frame[2] >= 0 and s.timer >= s.frame[2] * TIC do
            s.timer = s.timer - s.frame[2] * TIC
            local state = states[s.state]
            if s.frameIndex < #state then
                s.frameIndex = s.frameIndex + 1
                enterFrame(s, player)
            elseif state.loop then
                s.frameIndex = 1
                enterFrame(s, player)
            elseif state.next then
                Sprites.setState(s, state.next, player)
            else
                break
            end
        end

        -- Les monstres en chasse avancent en continu
        if s.state == "chase" and not s.dead and not s.removed then
            AI.move(s, dt, player, Sprites)
        end

        -- Les projectiles en vol avancent
        if s.vx and s.state == "idle" and not s.removed then
            Missiles.move(Sprites, s, dt, player)
        end
    end

    -- Le joueur ramasse les objets sur lesquels il marche
    if not player.dead and Sprites.onPickup then
        for _, s in ipairs(Sprites.list) do
            local kind = typeDefs[s.type].pickup
            if kind and not s.removed then
                local r = (player.radius or 12) + typeDefs[s.type].radius
                if (s.x - player.x) ^ 2 + (s.y - player.y) ^ 2 < r * r then
                    if Sprites.onPickup(kind) then
                        s.removed = true
                        if s.countsAsItem then Sprites.stats.items = Sprites.stats.items + 1 end
                    end
                end
            end
        end
    end

    -- Retirer les objets supprimés
    for i = #Sprites.list, 1, -1 do
        if Sprites.list[i].removed then table.remove(Sprites.list, i) end
    end
end

-- Application des dégâts
function Sprites.damage(s, amount, player)
    local def = typeDefs[s.type]
    if s.dead or not s.health then return end
 
    s.health = s.health - (amount or 10)
    if s.health <= 0 then
        s.dead = true
        if def.monster then Sprites.stats.kills = Sprites.stats.kills + 1 end
        if def.drop then Sprites.spawn(def.drop, s.x, s.y) end
        if def.states.gib and s.health < -def.health then
            Sprites.setState(s, "gib", player)
        else
            Sprites.setState(s, "death", player)
        end
    else
        -- Un monstre est blessé en sommeil, il se réveille directement
        if def.monster and not s.awake then
            s.awake = true
            s.reactionTime = 0
        end
        if def.painChance and def.states.pain and math.random() < def.painChance then
            Sprites.setState(s, "pain", player)
        elseif def.monster and s.state == "idle" then
            Sprites.setState(s, "chase", player)
        end
    end
end

function Sprites.alert(player)
    local reached = Noise.propagate(player.x, player.y)
    for _, s in ipairs(Sprites.list) do
        if typeDefs[s.type].monster and not s.dead and not s.awake 
            and Noise.heard(reached, s.x, s.y) then
            AI.wake(s, player, Sprites)
        end
    end
end

-- Dégâts autour d'un objet (plus forts au centre)
function Sprites.radiusDamage(source, power, player)
    for _, s in ipairs(Sprites.list) do
        if s ~= source and not s.dead and s.health then
            local dist = math.sqrt((s.x - source.x) ^ 2 + (s.y - source.y) ^ 2)
            dist = math.max(0, dist - (typeDefs[s.type].radius or 8))
            local dmg = power - dist * 2
            if dmg > 0 then
                Sprites.damage(s, dmg, player)
            end
        end
    end

    -- Le joueur peut aussi prendre des dégâts de l'explosion
    if player and not player.dead and Sprites.onPlayerHit then
        local dist = math.sqrt((player.x - source.x) ^ 2 + (player.y - source.y) ^ 2)
        dist = math.max(0, dist - (player.radius or 12))
        local dmg = power - dist * 2
        if dmg > 0 then Sprites.onPlayerHit(math.floor(dmg)) end
    end
end

Sprites.onPlayerHit = nil
Sprites.onPickup = nil

-- Tir instantané depuis le joueur.
function Sprites.hitscan(player, wallDist, angleOffset)
    local a = player.angle + (angleOffset or 0)
    local cos, sin = math.cos(a), math.sin(a)
    local best, bestDepth = nil, wallDist
    for _, s in ipairs(Sprites.list) do
        if s.health and not s.dead then
            local dx, dy = s.x - player.x, s.y - player.y
            local depth = dx * cos + dy * sin
            local side = -dx * sin + dy * cos
            local radius = typeDefs[s.type].radius or 8
            if depth > 0 and depth < bestDepth and math.abs(side) < radius then
                best, bestDepth = s, depth
            end
        end
    end
    return best
end

function Sprites.collide(player, oldX, oldY)
    local pr = player.radius or 12
    local function blocked(x, y)
        for _, s in ipairs(Sprites.list) do
            if s.solid then
                local r = pr + (typeDefs[s.type].radius or 8)
                if (x - s.x) ^ 2 + (y - s.y) ^ 2 < r * r then return true end
            end
        end
        return false
    end

    local newX, newY = player.x, player.y
    if blocked(newX, oldY) then newX = oldX end
    if blocked(newX, newY) then newY = oldY end
    player.x, player.y = newX, newY
end

-- Quelqu'un se trouve-t-il dans la case (col, row) ?
function Sprites.cellOccupied(col, row, player)
    local ts = Map.tileSize
    local x1, y1 = (col - 1) * ts, (row - 1) * ts
    local function overlaps(x, y, r)
        return x + r > x1 and x - r < x1 + ts and y + r > y1 and y - r < y1 + ts
    end
    if not player.dead and overlaps(player.x, player.y, player.radius or 12) then return true end
    for _, s in ipairs(Sprites.list) do
        if s.solid and overlaps(s.x, s.y, typeDefs[s.type].radius or 8) then return true end
    end
    return false
end

-- Dessine tous les objets
function Sprites.draw(player, zbuffer, projDist, fadeDist, doorbuffer, pass)
    SpriteRender.draw(Sprites.list, typeDefs, player, zbuffer, projDist, fadeDist, doorbuffer, pass)
end

return Sprites
