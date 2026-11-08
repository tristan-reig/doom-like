local defs = require("src.things.weapons")

local Weapon = {}
Weapon.__index = Weapon

local TIC = 1 / 35
local MOVE_SPEED = 6 * 35 -- vitesse pour changer d'arme
local LOWERED = 96

Weapon.defs = defs

local function loadImage(name)
    local img = love.graphics.newImage("assets/sprites/" .. name .. ".png")
    img:setFilter("nearest", "nearest")
    return img
end

function Weapon.new(startWeapon)
    local self = setmetatable({}, Weapon)

    self.images = {}
    for _, name in ipairs(defs.order) do
        local def = defs[name]
        for _, f in pairs(def.frames) do self.images[f[1]] = loadImage(f[1]) end
        for _, flash in ipairs(def.flashes) do
            for _, f in ipairs(flash) do self.images[f[1]] = loadImage(f[1]) end
        end
    end

    self.current = startWeapon
    self.pending = nil
    self.state = "ready"
    self.lowerY = 0
    self.firing = false
    self.refire = false
    self.seqIndex = 1
    self.seqTimer = 0
    self.flash = nil

    -- Balancement de l'arme quand on marche
    self.bobPhase = 0
    self.bobAmount = 0
    self.lastX, self.lastY = nil, nil

    return self
end

function Weapon:def()
    return defs[self.current]
end

-- Changement d'arme
function Weapon:select(name)
    if name ~= self.current or self.state == "lowering" then
        self.pending = name
    end
end

-- Renvoie vrai quand le coup part
function Weapon:update(dt, player, wantFire, canFire, onFire)
    if self.lastX then
        local moved = math.sqrt((player.x - self.lastX) ^ 2 + (player.y - self.lastY) ^ 2)
        local target = (moved > 0.01) and 1 or 0
        self.bobAmount = self.bobAmount + (target - self.bobAmount) * math.min(1, dt * 8)
        if target == 1 then self.bobPhase = self.bobPhase + dt * 8 end
    end
    self.lastX, self.lastY = player.x, player.y

    -- Flash du coup de feu
    if self.flash then
        self.flash.time = self.flash.time + dt
        local total = 0
        for _, f in ipairs(self.flash.list) do total = total + f[4] * TIC end
        if self.flash.time >= total then self.flash = nil end
    end

    local def = self:def()

    if self.state == "ready" then
        if self.pending then
            self.state = "lowering"
        elseif wantFire and canFire(def) then
            self:startFiring(def, player, canFire, onFire, false)
        end

    elseif self.state == "firing" then
        self.seqTimer = self.seqTimer + dt
        while self.state == "firing" and self.seqTimer >= def.fire[self.seqIndex][2] * TIC do
            self.seqTimer = self.seqTimer - def.fire[self.seqIndex][2] * TIC
            self.seqIndex = self.seqIndex + 1
            if self.seqIndex > #def.fire then
                if wantFire and canFire(def) and not self.pending then
                    self:startFiring(def, player, canFire, onFire, true)
                else
                    self.state = "ready"
                    self.seqIndex = 1
                    self.refire = false
                end
            else
                self:enterFrame(def, canFire, onFire)
            end
        end

    elseif self.state == "lowering" then
        self.lowerY = self.lowerY + MOVE_SPEED * dt
        if self.lowerY >= LOWERED then
            self.lowerY = LOWERED
            self.current = self.pending
            self.pending = nil
            self.state = "raising"
        end

    elseif self.state == "raising" then
        self.lowerY = self.lowerY - MOVE_SPEED * dt
        if self.lowerY <= 0 then
            self.lowerY = 0
            self.state = "ready"
        end
    end

    self.firing = (self.state == "firing")
end

function Weapon:startFiring(def, player, canFire, onFire, refire)
    self.state = "firing"
    self.refire = refire
    self.seqIndex = 1
    self.seqTimer = 0
    self:enterFrame(def, canFire, onFire)
end

function Weapon:enterFrame(def, canFire, onFire)
    local frame = def.fire[self.seqIndex]
    if frame.fire and canFire(def) then
        onFire(def, self.refire)
        if frame.flash then
            self.flash = { list = def.flashes[frame.flash], time = 0 }
        end
    end
end

-- Affichage du flash
function Weapon:currentFlash()
    if not self.flash then return nil end
    local t = 0
    for _, f in ipairs(self.flash.list) do
        t = t + f[4] * TIC
        if self.flash.time < t then return f end
    end
    return nil
end

-- Lumière ajoutée par le flash
function Weapon:currentLight()
    local flash = self:currentFlash()
    return flash and (flash[5] or 1) or 0
end

function Weapon:draw()
    local w, h = love.graphics.getDimensions()
    local scale = w / 320

    local function toScreen(x, y)
        return w / 2 + (x - 160) * scale, h - (200 - y) * scale
    end

    -- Pas de balancement pendant le tir
    local bobX, bobY = 0, 0
    if self.state == "ready" then
        bobX = math.cos(self.bobPhase) * 6 * self.bobAmount
        bobY = math.abs(math.sin(self.bobPhase)) * 6 * self.bobAmount
    end

    love.graphics.setColor(1, 1, 1)

    local def = self:def()
    local key = (self.state == "firing") and def.fire[self.seqIndex][1] or def.fire[1][1]
    local f = def.frames[key]
    local sx, sy = toScreen(f[2] + bobX, f[3] + bobY + self.lowerY)
    love.graphics.draw(self.images[f[1]], sx, sy, 0, scale, scale)

    -- Le flash est dessiné par-dessus l'arme
    local flash = self:currentFlash()
    if flash then
        local fx, fy = toScreen(flash[2], flash[3] + self.lowerY)
        love.graphics.draw(self.images[flash[1]], fx, fy, 0, scale, scale)
    end
end

return Weapon
