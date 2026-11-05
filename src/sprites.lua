local Map = require("src.map")
local Sound = require("src.sound")
local offsets = require("src.sprite_offsets")
local AI = require("src.ai")

local Sprites = {}

-- Taille d'un pixel de sprite en unités monde.
Sprites.unitsPerPixel = 0.5

local TIC = 1 / 35

-- Types d'objets.
local typeDefs = {
    barrel = {
        health = 20, radius = 6, solid = true,
        states = {
            idle = { { "bar1a0", -1 } },
            death = {
                { "bexpa0", 5 },
                { "bexpb0", 5, sound = "barrel" },
                { "bexpc0", 5, bright = true, explode = true, notSolid = true },
                { "bexpd0", 10, bright = true },
                { "bexpe0", 10, bright = true },
                { "bexpe0", 0, remove = true },
            },
        },
    },
    zombie = {
        health = 20, radius = 10, solid = true, painChance = 200 / 256,
        monster = true, speed = 35, sightSound = "zombieSight",
        states = {
            -- repos (cherche le joueur)
            idle = { { "possa", 10, action = "look" }, { "possb", 10, action = "look" }, loop = true },
            -- poursuite
            chase = {
                { "possa", 4, action = "chase" }, { "possa", 4, action = "chase" },
                { "possb", 4, action = "chase" }, { "possb", 4, action = "chase" },
                { "possc", 4, action = "chase" }, { "possc", 4, action = "chase" },
                { "possd", 4, action = "chase" }, { "possd", 4, action = "chase" },
                loop = true,
            },
            -- animation de tir
            missile = {
                { "posse", 10, action = "face" },
                { "possf", 8, bright = true, action = "shoot" },
                { "posse", 8 },
                next = "chase",
            },
            pain = { { "possg", 3 }, { "possg", 3, sound = "zombiePain" }, next = "chase" },
            death = {
                { "possh0", 5 },
                { "possi0", 5, sound = "zombieDeath" },
                { "possj0", 5, notSolid = true },
                { "possk0", 5 },
                { "possl0", -1 },
            },
            -- mort violente (quand il prend beaucoup de dégâts d'un coup)
            gib = {
                { "possm0", 5 },
                { "possn0", 5, sound = "gib" },
                { "posso0", 5, notSolid = true },
                { "possp0", 5 }, { "possq0", 5 }, { "possr0", 5 },
                { "posss0", 5 }, { "posst0", 5 },
                { "possu0", -1 },
            },
        },
    },
    stimpack = { radius = 10, pickup = "stimpack", states = { idle = { { "stima0", -1 } } } },
    medikit = { radius = 10, pickup = "medikit",  states = { idle = { { "media0", -1 } } } },
    shells = { radius = 10, pickup = "shells",   states = { idle = { { "shela0", -1 } } } },
    shellBox = { radius = 10, pickup = "shellBox", states = { idle = { { "sboxa0", -1 } } } },
    armor = {
        radius = 10, pickup = "armor",
        states = { idle = { { "arm1a0", 6 }, { "arm1b0", 6, bright = true }, loop = true } },
    },

    lamp = { radius = 8, solid = true, states = { idle = { { "colua0", -1 } } } },
    tallLamp = { radius = 8, solid = true, states = { idle = { { "tlmpa0", -1 } } } },
    column = { radius = 8, solid = true, states = { idle = { { "col1a0", -1 } } } },
}

local images = {}
Sprites.list = {}

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

local function isRotated(name)
    return not name:match("%d$")
end

local function loadImage(name)
    if images[name] then return end
    local img = love.graphics.newImage("assets/sprites/" .. name .. ".png")
    img:setFilter("nearest", "nearest")
    local iw, ih = img:getDimensions()

    local quads = {}
    for col = 0, iw - 1 do
        quads[col] = love.graphics.newQuad(col, 0, 1, ih, iw, ih)
    end

    local off = offsets[name] or { iw / 2, ih }

    images[name] = { image = img, quads = quads, width = iw, height = ih, offX = off[1], offY = off[2] }
end

function Sprites.load()
    for _, def in pairs(typeDefs) do
        for _, state in pairs(def.states) do
            for _, frame in ipairs(state) do
                if isRotated(frame[1]) then
                    for rot = 1, 8 do loadImage(frame[1] .. rot) end
                else
                    loadImage(frame[1])
                end
            end
        end
    end
end

-- Applique les effets de l'image courante
local function enterFrame(s, player)
    local frame = typeDefs[s.type].states[s.state][s.frameIndex]
    s.frame = frame
    if frame.sound then Sound.playAt(frame.sound, s.x, s.y, player) end
    if frame.notSolid then s.solid = false end
    if frame.explode then Sprites.radiusDamage(s, 128, player) end
    if frame.remove then s.removed = true end
    if frame.action then AI.actions[frame.action](s, player, Sprites) end
end

function Sprites.getDef(s)
    return typeDefs[s.type]
end

function Sprites.setState(s, stateName, player)
    s.state = stateName
    s.frameIndex = 1
    s.timer = 0
    enterFrame(s, player)
end

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
    end

    -- Le joueur ramasse les objets sur lesquels il marche
    if not player.dead and Sprites.onPickup then
        for _, s in ipairs(Sprites.list) do
            local kind = typeDefs[s.type].pickup
            if kind and not s.removed then
                local r = (player.radius or 12) + typeDefs[s.type].radius
                if (s.x - player.x) ^ 2 + (s.y - player.y) ^ 2 < r * r then
                    if Sprites.onPickup(kind) then s.removed = true end
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
        -- Si le monstre est blessé, il se réveille directement
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

function Sprites.alert(player, radius)
    radius = radius or 1000
    for _, s in ipairs(Sprites.list) do
        if typeDefs[s.type].monster and not s.dead and not s.awake then
            local dist = math.sqrt((s.x - player.x) ^ 2 + (s.y - player.y) ^ 2)
            if dist < radius then AI.wake(s, player, Sprites) end
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

-- Choisit l'image d'un sprite à 8 directions selon l'angle.
local function rotationFor(s, player)
    local toViewer = math.atan2(player.y - s.y, player.x - s.x)
    local rel = toViewer - s.angle
    local idx = math.floor((-rel + math.pi / 8) / (math.pi / 4)) % 8
    return idx + 1
end

-- Dessine tous les objets.
function Sprites.draw(player, zbuffer, projDist, fadeDist)
    local w, h = love.graphics.getDimensions()
    local halfW, halfH = w / 2, h / 2
    local camHeight = Map.tileSize / 2
    local cos, sin = math.cos(player.angle), math.sin(player.angle)
    local upp = Sprites.unitsPerPixel

    -- Passer chaque objet dans le repère caméra
    local visible = {}
    for _, s in ipairs(Sprites.list) do
        local dx, dy = s.x - player.x, s.y - player.y
        local depth = dx * cos + dy * sin
        local side = -dx * sin + dy * cos
        if depth > 1 then
            table.insert(visible, { sprite = s, depth = depth, side = side })
        end
    end

    -- Trier du plus loin au plus proche
    table.sort(visible, function(a, b) return a.depth > b.depth end)

    -- Dessiner
    for _, v in ipairs(visible) do
        local s = v.sprite
        local name = s.frame[1]
        if isRotated(name) then name = name .. rotationFor(s, player) end
        local t = images[name]

        local scale = projDist / v.depth
        local pxScale = upp * scale
        local spriteW = t.width * pxScale
        local spriteH = t.height * pxScale

        local centerX = halfW + v.side * scale
        local floorY = halfH + camHeight * scale
        local left = centerX - t.offX * pxScale
        local top = floorY - t.offY * pxScale

        local shade = s.frame.bright and 1 or math.max(0.25, 1 - v.depth / fadeDist)
        love.graphics.setColor(shade, shade, shade)

        local firstCol = math.max(0, math.floor(left))
        local lastCol = math.min(w - 1, math.ceil(left + spriteW) - 1)
        for sx = firstCol, lastCol do
            -- L'objet n'est visible dans cette colonne que s'il est devant le mur
            if v.depth < zbuffer[sx] then
                local texCol = math.floor((sx - left) / spriteW * t.width)
                if texCol >= 0 and texCol < t.width then
                    love.graphics.draw(t.image, t.quads[texCol], sx, top, 0, 1, spriteH / t.height)
                end
            end
        end
    end
end

return Sprites
