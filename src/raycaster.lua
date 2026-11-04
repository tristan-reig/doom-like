local Map = require("src.map")

local Raycaster = {}

Raycaster.fov = math.rad(66)

-- Lance un rayon depuis (px, py) dans la direction "angle".
function Raycaster.castRay(px, py, angle)
    local ts = Map.tileSize

    local posX, posY = px / ts, py / ts
    local dirX, dirY = math.cos(angle), math.sin(angle)

    local mapX, mapY = math.floor(posX), math.floor(posY)

    -- Distance que le rayon parcourt pour traverser une case entière en X ou en Y
    local deltaX= (dirX == 0) and 1e30 or math.abs(1 / dirX)
    local deltaY= (dirY == 0) and 1e30 or math.abs(1 / dirY)

    -- Sens du pas et distance jusqu'à la première ligne de la grille
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

    -- On avance jusqu'à toucher un mur
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

    return dist * ts, tile, side
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

        local dist, tile, side = Raycaster.castRay(player.x, player.y, rayAngle)

        -- Correction de l'effet "fish-eye"
        local perpDist = dist * math.cos(offset)
        if perpDist < 0.0001 then perpDist = 0.0001 end

        -- Plus le mur est loin, plus il est petit
        local wallH = Map.tileSize * projDist / perpDist

        -- Couleur du mur, assombrie selon le côté et la distance
        local c = Map.colors[tile] or {1, 1, 1}
        local shade = (side == 1) and 0.7 or 1.0
        shade = shade * math.max(0.25, 1 - perpDist / 900)
        love.graphics.setColor(c[1] * shade, c[2] * shade, c[3] * shade)

        love.graphics.rectangle("fill", x, halfH - wallH / 2, 1, wallH)
    end
end

return Raycaster
