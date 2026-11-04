local Weapon = {}
Weapon.__index = Weapon

local TIC = 1 / 35

local frameDefs = {
    A = { file = "shtga0", x = 123, y = 139 }, -- repos
    B = { file = "shtgb0", x = 74,  y = 91  }, -- pompe 1
    C = { file = "shtgc0", x = 35,  y = 59  }, -- pompe 2
    D = { file = "shtgd0", x = 43,  y = 81  }, -- pompe 3
}
local flashDefs = {
    { file = "shtfa0", x = 143, y = 130, tics = 4 },
    { file = "shtfb0", x = 132, y = 122, tics = 3 },
}

-- Séquence de tir
local fireSequence = {
    { "A", 3 },
    { "A", 7, fire = true },
    { "B", 3 }, { "C", 5 }, { "D", 4 }, { "C", 5 }, { "B", 5 },
    { "A", 3 }, { "A", 7 },
}

local function loadImage(name)
    local img = love.graphics.newImage("assets/sprites/" .. name .. ".png")
    img:setFilter("nearest", "nearest")
    return img
end

function Weapon.new()
    local self = setmetatable({}, Weapon)

    self.images = {}
    for key, def in pairs(frameDefs) do
        self.images[key] = loadImage(def.file)
    end
    for _, def in ipairs(flashDefs) do
        def.image = loadImage(def.file)
    end

    self.firing = false
    self.seqIndex = 1
    self.seqTimer = 0
    self.flashTime = nil -- pas de flash en cours

    -- Balancement de l'arme en marchant
    self.bobPhase = 0
    self.bobAmount = 0
    self.lastX, self.lastY = nil, nil

    return self
end

-- Renvoie vrai au moment ou le coup part
function Weapon:update(dt, player, wantFire)
    local fired = false

    if self.lastX then
        local moved = math.sqrt((player.x - self.lastX) ^ 2 + (player.y - self.lastY) ^ 2)
        local target = (moved > 0.01) and 1 or 0
        -- On fait varier l'amplitude en douceur
        self.bobAmount = self.bobAmount + (target - self.bobAmount) * math.min(1, dt * 8)
        if target == 1 then
            self.bobPhase = self.bobPhase + dt * 8
        end
    end
    self.lastX, self.lastY = player.x, player.y

    -- Démarrer un tir
    if not self.firing and wantFire then
        self.firing = true
        self.seqIndex = 1
        self.seqTimer = 0
    end

    -- Faire avancer l'animation de tir
    if self.firing then
        self.seqTimer = self.seqTimer + dt
        while self.firing and self.seqTimer >= fireSequence[self.seqIndex][2] * TIC do
            self.seqTimer = self.seqTimer - fireSequence[self.seqIndex][2] * TIC
            self.seqIndex = self.seqIndex + 1
            if self.seqIndex > #fireSequence then
                self.firing = false
                self.seqIndex = 1
            elseif fireSequence[self.seqIndex].fire then
                fired = true
                self.flashTime = 0
            end
        end
    end

    -- Faire avancer le flash
    if self.flashTime then
        self.flashTime = self.flashTime + dt
        local total = 0
        for _, f in ipairs(flashDefs) do total = total + f.tics * TIC end
        if self.flashTime >= total then self.flashTime = nil end
    end

    return fired
end

-- Affichage du flash
function Weapon:currentFlash()
    if not self.flashTime then return nil end
    local t = 0
    for _, f in ipairs(flashDefs) do
        t = t + f.tics * TIC
        if self.flashTime < t then return f end
    end
    return nil
end

function Weapon:draw()
    local w, h = love.graphics.getDimensions()
    local scale = w / 320

    local function toScreen(x, y)
        return w / 2 + (x - 160) * scale, h - (200 - y) * scale
    end

    -- Pas de balancement pendant le tir
    local bobX, bobY = 0, 0
    if not self.firing then
        bobX = math.cos(self.bobPhase) * 6 * self.bobAmount
        bobY = math.abs(math.sin(self.bobPhase)) * 6 * self.bobAmount
    end

    love.graphics.setColor(1, 1, 1)

    local key = fireSequence[self.seqIndex][1]
    local def = frameDefs[key]
    local sx, sy = toScreen(def.x + bobX, def.y + bobY)
    love.graphics.draw(self.images[key], sx, sy, 0, scale, scale)

    -- Le flash est dessiné par-dessus l'arme
    local flash = self:currentFlash()
    if flash then
        local fx, fy = toScreen(flash.x, flash.y)
        love.graphics.draw(flash.image, fx, fy, 0, scale, scale)
    end
end

return Weapon
