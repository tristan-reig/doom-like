local Map = require("src.map")

local Player = {}
Player.__index = Player

function Player.new(x, y, angle)
    local self = setmetatable({}, Player)
    self.x = x
    self.y = y
    self.angle = angle or 0
    self.moveSpeed = 180
    self.turnSpeed = math.rad(150)
    self.radius = 12
    return self
end

-- Vérifie si le cercle du joueur, centré en (x, y), touche un mur
local function collides(x, y, r)
    return Map.isWall(x - r, y - r) or Map.isWall(x + r, y - r)
        or Map.isWall(x - r, y + r) or Map.isWall(x + r, y + r)
end

function Player:update(dt)
    local lk = love.keyboard

    -- Rotation : flèches gauche/droite
    if lk.isDown("left") then self.angle = self.angle - self.turnSpeed * dt end
    if lk.isDown("right") then self.angle = self.angle + self.turnSpeed * dt end

    -- Déplacement : ZQSD et WASD
    local forward, strafe = 0, 0
    if lk.isDown("z", "w", "up") then forward = forward + 1 end
    if lk.isDown("s", "down") then forward = forward - 1 end
    if lk.isDown("d") then strafe = strafe + 1 end
    if lk.isDown("q", "a") then strafe = strafe - 1 end

    local cos, sin = math.cos(self.angle), math.sin(self.angle)
    local dx = (cos * forward - sin * strafe)
    local dy = (sin * forward + cos * strafe)

    local len = math.sqrt(dx * dx + dy * dy)
    if len > 0 then
        dx = dx / len * self.moveSpeed * dt
        dy = dy / len * self.moveSpeed * dt
    end

    if not collides(self.x + dx, self.y, self.radius) then
        self.x = self.x + dx
    end
    if not collides(self.x, self.y + dy, self.radius) then
        self.y = self.y + dy
    end
end

function Player:draw(scale)
    scale = scale or 1
    local px, py = self.x * scale, self.y * scale
    love.graphics.setColor(1, 0.9, 0.2)
    love.graphics.circle("fill", px, py, self.radius * scale)
    love.graphics.line(px, py,
        px + math.cos(self.angle) * 30 * scale,
        py + math.sin(self.angle) * 30 * scale)
end

return Player