local Map = require("src.map")
local Raycaster = require("src.raycaster")
local Sound = require("src.sound")

local AI = {}

-- Les 8 directions de déplacement possibles
local DIRS = {}
for i = 0, 7 do DIRS[i] = i * math.pi / 4 end

local function distance(ax, ay, bx, by)
    return math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
end

-- Le monstre voit-il le joueur ?
function AI.canSee(s, player)
    if player.dead then return false end
    local dist = distance(s.x, s.y, player.x, player.y)
    local angle = math.atan2(player.y - s.y, player.x - s.x)
    local wallDist = Raycaster.castRay(s.x, s.y, angle)
    return wallDist > dist
end

-- La position (x, y) est-elle bloquée ?
function AI.isBlocked(s, x, y, Sprites, player)
    local r = Sprites.getDef(s).radius or 10

    -- Murs
    if Map.isWall(x - r, y - r) or Map.isWall(x + r, y - r)
        or Map.isWall(x - r, y + r) or Map.isWall(x + r, y + r) then
        return true
    end

    -- Autres objets solides
    for _, o in ipairs(Sprites.list) do
        if o ~= s and o.solid then
            local rr = r + (Sprites.getDef(o).radius or 8)
            if (x - o.x) ^ 2 + (y - o.y) ^ 2 < rr * rr then return true end
        end
    end

    -- Le joueur
    if not player.dead then
        local rr = r + (player.radius or 12)
        if (x - player.x) ^ 2 + (y - player.y) ^ 2 < rr * rr then return true end
    end

    return false
end

-- Choisit une nouvelle direction de marche vers le joueur.
function AI.newChaseDir(s, player, Sprites)
    local target = math.atan2(player.y - s.y, player.x - s.x)
    local turnaround = s.moveDir and ((s.moveDir + 4) % 8) or nil

    -- Trier les 8 directions de la plus proche à la plus éloignée de la cible
    local candidates = {}
    for i = 0, 7 do
        local diff = math.abs((DIRS[i] - target + math.pi) % (2 * math.pi) - math.pi)
        table.insert(candidates, { dir = i, score = diff + math.random() * 0.3 })
    end
    table.sort(candidates, function(a, b) return a.score < b.score end)

    local step = 16
    local function free(dir)
        return not AI.isBlocked(s, s.x + math.cos(DIRS[dir]) * step,
                                   s.y + math.sin(DIRS[dir]) * step, Sprites, player)
    end

    for _, c in ipairs(candidates) do
        if c.dir ~= turnaround and free(c.dir) then
            s.moveDir = c.dir
            s.angle = DIRS[c.dir]
            s.moveCount = math.random(0, 15)
            return
        end
    end
    if turnaround and free(turnaround) then
        s.moveDir = turnaround
        s.angle = DIRS[turnaround]
        s.moveCount = math.random(0, 15)
        return
    end
    s.moveDir = nil -- complètement coincé
end

-- Le monstre se réveille et part en chasse
function AI.wake(s, player, Sprites)
    if s.awake or s.dead then return end
    s.awake = true
    s.reactionTime = 8
    local def = Sprites.getDef(s)
    if def.sightSound then Sound.playAt(def.sightSound, s.x, s.y, player) end
    Sprites.setState(s, "chase", player)
end

-- Déplacement continu, appelé à chaque image pendant la poursuite
function AI.move(s, dt, player, Sprites)
    if not s.moveDir then return end
    local speed = Sprites.getDef(s).speed or 35
    local nx = s.x + math.cos(DIRS[s.moveDir]) * speed * dt
    local ny = s.y + math.sin(DIRS[s.moveDir]) * speed * dt
    if AI.isBlocked(s, nx, ny, Sprites, player) then
        AI.newChaseDir(s, player, Sprites) -- changement de direction
    else
        s.x, s.y = nx, ny
    end
end

local function wantsToShoot(s, player)
    local dist = distance(s.x, s.y, player.x, player.y) * 2 - 64 -- en unités Doom
    dist = math.max(0, math.min(dist, 200))
    return math.random(0, 255) >= dist
end

AI.actions = {}

-- Cherche le joueur du regard
function AI.actions.look(s, player, Sprites)
    if not AI.canSee(s, player) then return end
    local toPlayer = math.atan2(player.y - s.y, player.x - s.x)
    local diff = math.abs((toPlayer - s.angle + math.pi) % (2 * math.pi) - math.pi)
    local dist = distance(s.x, s.y, player.x, player.y)
    if diff < math.pi / 2 or dist < 64 then
        AI.wake(s, player, Sprites)
    end
end

function AI.actions.chase(s, player, Sprites)
    if s.reactionTime > 0 then s.reactionTime = s.reactionTime - 1 end

    local def = Sprites.getDef(s)
    if def.states.missile and s.reactionTime <= 0
        and AI.canSee(s, player) and wantsToShoot(s, player) then
        s.moveDir = nil
        Sprites.setState(s, "missile", player)
        return
    end

    s.moveCount = (s.moveCount or 0) - 1
    if not s.moveDir or s.moveCount < 0 then
        AI.newChaseDir(s, player, Sprites)
    end
end

-- Tourne le monstre vers le joueur
function AI.actions.face(s, player)
    s.angle = math.atan2(player.y - s.y, player.x - s.x)
end

function AI.actions.shoot(s, player, Sprites)
    AI.actions.face(s, player)
    Sound.playAt("zombieShoot", s.x, s.y, player)
    if not AI.canSee(s, player) then return end

    local spread = (math.random() - math.random()) * math.rad(22.5)
    local dist = distance(s.x, s.y, player.x, player.y)
    local hitAngle = math.atan((player.radius or 12) / dist)
    if math.abs(spread) < hitAngle and Sprites.onPlayerHit then
        Sprites.onPlayerHit(3 * math.random(1, 5)) -- dégâts aléatoires
    end
end

return AI
