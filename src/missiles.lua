local Map = require("src.map")

local Missiles = {}

-- Lance un projectiles vers le point (tx, ty)
function Missiles.spawn(Sprites, typeName, owner, tx, ty, spread)
    local def = Sprites.getDefByName(typeName)
    local angle = math.atan2(ty - owner.y, tx - owner.x) + (spread or 0)
    -- Il part du bord du lanceur, pas de son centre
    local startDist = (Sprites.getDef(owner).radius or 10) + def.radius + 1
    local m = Sprites.spawn(typeName,
        owner.x + math.cos(angle) * startDist,
        owner.y + math.sin(angle) * startDist, angle)
    m.owner = owner
    m.vx = math.cos(angle) * def.projectile.speed
    m.vy = math.sin(angle) * def.projectile.speed
    return m
end

-- Collision du projectile avec un objet
local function explode(Sprites, m, target, player)
    if target then
        local dmg = Sprites.getDef(m).projectile.damage
        local amount = math.random(dmg[1], dmg[2])
        if target == player then
            if Sprites.onPlayerHit then Sprites.onPlayerHit(amount) end
        else
            Sprites.damage(target, amount, player)
        end
    end
    m.vx, m.vy = 0, 0
    Sprites.setState(m, "death", player)
end

-- Vol du projectile
function Missiles.move(Sprites, m, dt, player)
    local r = Sprites.getDef(m).radius
    local steps = math.max(1, math.ceil(math.sqrt(m.vx ^ 2 + m.vy ^ 2) * dt / r))
    for _ = 1, steps do
        m.x = m.x + m.vx * dt / steps
        m.y = m.y + m.vy * dt / steps

        if Map.isWall(m.x, m.y) then
            m.x = m.x - m.vx * dt / steps
            m.y = m.y - m.vy * dt / steps
            return explode(Sprites, m, nil, player)
        end

        -- Le joueur
        local pr = (player.radius or 12) + r
        if not player.dead and (m.x - player.x) ^ 2 + (m.y - player.y) ^ 2 < pr * pr then
            return explode(Sprites, m, player, player)
        end

        for _, o in ipairs(Sprites.list) do
            if o ~= m and o ~= m.owner and o.solid then
                local rr = (Sprites.getDef(o).radius or 8) + r
                if (m.x - o.x) ^ 2 + (m.y - o.y) ^ 2 < rr * rr then
                    return explode(Sprites, m, o.health and o or nil, player)
                end
            end
        end
    end
end

return Missiles
