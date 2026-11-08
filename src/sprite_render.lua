local Map = require("src.map")
local SpriteImages = require("src.sprite_images")
local Lighting = require("src.lighting")

local SpriteRender = {}

-- Taille d'un pixel en unités monde.
SpriteRender.unitsPerPixel = 0.5

-- Choisit l'image d'un sprite à 8 directions selon l'angle sous lequel on le voit.
local function rotationFor(s, player)
    local toViewer = math.atan2(player.y - s.y, player.x - s.x)
    local rel = toViewer - s.angle
    local idx = math.floor((-rel + math.pi / 8) / (math.pi / 4)) % 8
    return idx + 1
end

-- Dessine les objets.
function SpriteRender.draw(list, typeDefs, player, zbuffer, projDist, fadeDist, doorbuffer, pass)
    local w, h = love.graphics.getDimensions()
    local halfW, halfH = w / 2, h / 2
    local camHeight = Map.tileSize / 2
    local cos, sin = math.cos(player.angle), math.sin(player.angle)
    local upp = SpriteRender.unitsPerPixel

    -- Passer chaque objet dans le repère caméra
    local visible = {}
    for _, s in ipairs(list) do
        local dx, dy = s.x - player.x, s.y - player.y
        local depth = dx * cos + dy * sin
        local side = -dx * sin + dy * cos
        if depth > 1 then
            table.insert(visible, { sprite = s, depth = depth, side = side })
        end
    end

    -- Trier du plus loin au plus proche : les proches sont dessinés par-dessus
    table.sort(visible, function(a, b) return a.depth > b.depth end)

    -- Dessiner
    for _, v in ipairs(visible) do
        local s = v.sprite
        local name = s.frame[1]
        if SpriteImages.isRotated(name) then name = name .. rotationFor(s, player) end
        local t = SpriteImages.get(name)

        local scale = projDist / v.depth
        local pxScale = upp * scale
        local spriteW = t.width * pxScale
        local spriteH = t.height * pxScale

        local centerX = halfW + v.side * scale
        local floorY = halfH + (camHeight - (typeDefs[s.type].height or 0)) * scale
        local left = centerX - t.offX * pxScale
        local top = floorY - t.offY * pxScale

        local shade = s.frame.bright and 1 or Lighting.shade(v.depth, fadeDist)
        love.graphics.setColor(shade, shade, shade)

        local firstCol = math.max(0, math.floor(left))
        local lastCol = math.min(w - 1, math.ceil(left + spriteW) - 1)
        for sx = firstCol, lastCol do
            local shown = v.depth < zbuffer[sx]
            local door = doorbuffer and doorbuffer[sx]
            if pass == "behind" then
                shown = shown and (not door or v.depth > door)
            elseif pass == "front" then
                shown = door and v.depth < door
            end
            if shown then
                local texCol = math.floor((sx - left) / spriteW * t.width)
                if t.mirrored then texCol = t.width - 1 - texCol end
                if texCol >= 0 and texCol < t.width then
                    love.graphics.draw(t.image, t.quads[texCol], sx, top, 0, 1, spriteH / t.height)
                end
            end
        end
    end
end

return SpriteRender
