local Map = require("src.map")
local Sound = require("src.sound")

local Sprites = {}

-- Taille d'un pixel de sprite en unités monde.
Sprites.unitsPerPixel = 0.5

local TIC = 1 / 35

-- Types d'objets.
local typeDefs = {
    barrel = {
        image = "bar1a0",
        shootable = true,
        explode = {
            { "bexpa0", 5 }, { "bexpb0", 5, sound = "barrel" },
            { "bexpc0", 5, bright = true },
            { "bexpd0", 10, bright = true },
            { "bexpe0", 10, bright = true },
        },
    },
    lamp     = { image = "colua0" },
    tallLamp = { image = "tlmpa0" },
    column   = { image = "col1a0" },
}

local images = {}
Sprites.list = {}

local function loadImage(name)
    if images[name] then return end
    local img = love.graphics.newImage("assets/sprites/" .. name .. ".png")
    img:setFilter("nearest", "nearest")
    local iw, ih = img:getDimensions()

    local quads = {}
    for col = 0, iw - 1 do
        quads[col] = love.graphics.newQuad(col, 0, 1, ih, iw, ih)
    end

    images[name] = { image = img, quads = quads, width = iw, height = ih }
end

function Sprites.load()
    for _, def in pairs(typeDefs) do
        loadImage(def.image)
        if def.explode then
            for _, frame in ipairs(def.explode) do loadImage(frame[1]) end
        end
    end
end

function Sprites.add(typeName, col, row)
    table.insert(Sprites.list, {
        type = typeName,
        image = typeDefs[typeName].image,
        x = (col - 0.5) * Map.tileSize,
        y = (row - 0.5) * Map.tileSize,
    })
end

-- Fait avancer les animations et retire les objets détruits
function Sprites.update(dt, player)
    for i = #Sprites.list, 1, -1 do
        local s = Sprites.list[i]
        if s.anim then
            s.animTimer = s.animTimer + dt
            while s.anim and s.animTimer >= s.anim[s.animIndex][2] * TIC do
                s.animTimer = s.animTimer - s.anim[s.animIndex][2] * TIC
                s.animIndex = s.animIndex + 1
                if s.animIndex > #s.anim then
                    table.remove(Sprites.list, i)
                    s.anim = nil
                else
                    local frame = s.anim[s.animIndex]
                    s.image = frame[1]
                    s.bright = frame.bright
                    if frame.sound then
                        Sound.playAt(frame.sound, s.x, s.y, player)
                    end
                end
            end
        end
    end
end

-- Coordonnées d'un objet dans le repère caméra
local function toCamera(player, s)
    local cos, sin = math.cos(player.angle), math.sin(player.angle)
    local dx, dy = s.x - player.x, s.y - player.y
    return dx * cos + dy * sin, -dx * sin + dy * cos
end

-- Tir instantané droit devant (au centre de l'écran).
-- Renvoie l'objet touché le plus proche, ou nil.
-- wallDist : distance du mur au centre de l'écran (on ne tire pas à travers les murs)
function Sprites.hitscan(player, wallDist)
    local best, bestDepth = nil, wallDist
    for _, s in ipairs(Sprites.list) do
        local def = typeDefs[s.type]
        if def.shootable and not s.anim then
            local depth, side = toCamera(player, s)
            local halfWidth = images[s.image].width * Sprites.unitsPerPixel / 2
            if depth > 0 and depth < bestDepth and math.abs(side) < halfWidth then
                best, bestDepth = s, depth
            end
        end
    end
    return best
end

-- Application des dégâts
function Sprites.damage(s)
    local def = typeDefs[s.type]
    if def.explode and not s.anim then
        s.anim = def.explode
        s.animIndex = 1
        s.animTimer = 0
        s.image = s.anim[1][1]
    end
end

-- Dessine tous les objets.
function Sprites.draw(player, zbuffer, projDist, fadeDist)
    local w, h = love.graphics.getDimensions()
    local halfW, halfH = w / 2, h / 2
    local camHeight = Map.tileSize / 2

    -- Passer chaque objet dans le repère caméra
    local visible = {}
    for _, s in ipairs(Sprites.list) do
        local depth, side = toCamera(player, s)
        if depth > 1 then
            table.insert(visible, { sprite = s, depth = depth, side = side })
        end
    end

    -- Trier du plus loin au plus proche
    table.sort(visible, function(a, b) return a.depth > b.depth end)

    -- Dessiner
    for _, v in ipairs(visible) do
        local t = images[v.sprite.image]
        local scale = projDist / v.depth
        local spriteW = t.width * Sprites.unitsPerPixel * scale
        local spriteH = t.height * Sprites.unitsPerPixel * scale

        local centerX = halfW + v.side * scale
        local left = centerX - spriteW / 2
        local floorY = halfH + camHeight * scale
        local top = floorY - spriteH

        -- Eclairage de l'explosion
        local shade = v.sprite.bright and 1 or math.max(0.25, 1 - v.depth / fadeDist)
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
