local Map = require("src.map")

local Raycaster = {}

Raycaster.fov = math.rad(66)

-- Lance un rayon depuis (px, py) dans la direction "angle".
function Raycaster.castRay(px, py, angle)
    local ts = Map.tileSize

    local posX, posY = px / ts, py / ts
    local dirX, dirY = math.cos(angle), math.sin(angle)

    local mapX, mapY = math.floor(posX), math.floor(posY)

    local deltaX = (dirX == 0) and 1e30 or math.abs(1 / dirX)
    local deltaY = (dirY == 0) and 1e30 or math.abs(1 / dirY)

    local stepX, stepY, sideX, sideY
    if dirX < 0 then
        stepX = -1
        sideX = (posX - mapX) * deltaX
    else
        stepX = 1
        sideX = (mapX + 1 - posX) * deltaX
    end
    if dirY < 0 then
        stepY = -1
        sideY = (posY - mapY) * deltaY
    else
        stepY = 1
        sideY = (mapY + 1 - posY) * deltaY
    end

    local side, tile = 0, 0
    for _ = 1, 100 do
        if sideX < sideY then
            sideX = sideX + deltaX
            mapX = mapX + stepX
            side = 0
        else
            sideY = sideY + deltaY
            mapY = mapY + stepY
            side = 1
        end

        local row = Map.grid[mapY + 1]
        tile = row and row[mapX + 1] or 1
        if tile ~= 0 then break end
    end

    local dist
    if side == 0 then
        dist = sideX - deltaX
    else
        dist = sideY - deltaY
    end

    local wallX
    if side == 0 then
        wallX = posY + dist * dirY
    else
        wallX = posX + dist * dirX
    end
    wallX = wallX - math.floor(wallX)

    -- On retourne la texture sur certaines faces pour qu'elle ne soit pas en miroir
    if (side == 0 and dirX < 0) or (side == 1 and dirY > 0) then
        wallX = 1 - wallX
    end

    return dist * ts, tile, side, wallX
end

-- Textures des murs
local textureFiles = {
    [1] = "assets/textures/brick1.png",
    [2] = "assets/textures/w94_1.png",
    [3] = "assets/textures/wall54_1.png",
    [4] = "assets/textures/rw13_1.png",
}

-- Pour chaque texture : l'image + un "Quad" par colonne de pixels.
local textures = {}

function Raycaster.load()
    for id, path in pairs(textureFiles) do
        local img = love.graphics.newImage(path)
        img:setFilter("nearest", "nearest")
        local tw, th = img:getDimensions()

        local quads = {}
        for col = 0, tw - 1 do
            quads[col] = love.graphics.newQuad(col, 0, 1, th, tw, th)
        end

        textures[id] = { image = img, quads = quads, width = tw, height = th }
    end
end

-- Dessine la vue 3D
function Raycaster.draw(player)
    local w, h = love.graphics.getDimensions()
    local halfW, halfH = w / 2, h / 2

    local projDist = halfW / math.tan(Raycaster.fov / 2)

    -- Plafond et sol
    love.graphics.setColor(0.20, 0.18, 0.16)
    love.graphics.rectangle("fill", 0, 0, w, halfH)
    love.graphics.setColor(0.30, 0.27, 0.22)
    love.graphics.rectangle("fill", 0, halfH, w, halfH)

    for x = 0, w - 1 do
        local offset = math.atan((x - halfW) / projDist)
        local rayAngle = player.angle + offset

        local dist, tile, side, wallX = Raycaster.castRay(player.x, player.y, rayAngle)

        -- Correction de l'effet "fish-eye"
        local perpDist = dist * math.cos(offset)
        if perpDist < 0.0001 then perpDist = 0.0001 end

        -- Plus le mur est loin, plus il est petit
        local wallH = Map.tileSize * projDist / perpDist

        local top = halfH - wallH / 2

        local shade = (side == 1) and 0.7 or 1.0
        shade = shade * math.max(0.25, 1 - perpDist / 900)

        local tex = textures[tile]
        if tex then
            local texCol = math.floor(wallX * tex.width)
            if texCol >= tex.width then texCol = tex.width - 1 end

            love.graphics.setColor(shade, shade, shade)
            love.graphics.draw(tex.image, tex.quads[texCol], x, top, 0, 1, wallH / tex.height)
        else
            -- Pas de texture pour ce type de mur : couleur unie comme avant
            local c = Map.colors[tile] or {1, 1, 1}
            love.graphics.setColor(c[1] * shade, c[2] * shade, c[3] * shade)
            love.graphics.rectangle("fill", x, top, 1, wallH)
        end
    end
end

return Raycaster
