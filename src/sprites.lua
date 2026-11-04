local Map = require("src.map")

local Sprites = {}

-- Taille d'un pixel de sprite en unités monde.
Sprites.unitsPerPixel = 0.5

-- Types de sprites
local spriteFiles = {
    barrel = "/assets/sprites/bar1a0.png",
    lamp = "/assets/sprites/colua0.png",
    tailLamp = "/assets/sprites/tlmpa0.png",
    column = "/assets/sprites/col1a0.png",
}

local types = {}
Sprites.list = {}

function Sprites.load()
    for name, path in pairs(spriteFiles) do
        local img = love.graphics.newImage(path)
        img:setFilter("nearest", "nearest")
        local iw, ih = img:getDimensions()

        local quads = {}
        for col = 0, iw - 1 do
            quads[col] = love.graphics.newQuad(col, 0, 1, ih, iw, ih)
        end

        types[name] = { image = img, quads = quads, width = iw, height = ih }
    end
end

-- Ajoute un sprite dans la case (col, row) de la carte
function Sprites.add(typeName, col, row)
    table.insert(Sprites.list, {
        type = typeName,
        x = (col - 0.5) * Map.tileSize,
        y = (row - 0.5) * Map.tileSize,
    })
end

function Sprites.draw(player, zbuffer, projDist, fadeDist)
    local w, h = love.graphics.getDimensions()
    local halfW, halfH = w / 2, h / 2
    local camHeight = Map.tileSize / 2

    local cos, sin = math.cos(player.angle), math.sin(player.angle)

    -- Passer chaque sprite dans le repère caméra
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
    table.sort(visible, function(a, b) return a.depth < b.depth end)

    -- Dessiner
    for _, v in ipairs(visible) do
        local t = types[v.sprite.type]
        if t then
            local scale = projDist / v.depth
            local spriteW = t.width * Sprites.unitsPerPixel * scale
            local spriteH = t.height * Sprites.unitsPerPixel * scale

            local centerX = halfW + v.side * scale
            local left = centerX - spriteW / 2
            local floorY = halfH + camHeight * scale
            local top = floorY - spriteH

            local shade = math.max(0.25, 1 - v.depth / fadeDist)
            love.graphics.setColor(shade, shade, shade)

            local firstCol = math.max(0, math.floor(left))
            local lastCol = math.min(w - 1, math.ceil(left + spriteW) - 1)
            for sx = firstCol, lastCol do
                -- Le sprite n'est visible dans cette colonne que s'il est devant le mur
                if v.depth < zbuffer[sx] then
                    local texCol = math.floor((sx - left) / spriteW * t.width)
                    if texCol >= 0 and texCol < t.width then
                        love.graphics.draw(t.image, t.quads[texCol], sx, top, 0, 1, spriteH / t.height)
                    end
                end
            end
        end
    end
end

return Sprites
