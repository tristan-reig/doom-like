local Hud = {}

local bigFont, hugeFont, smallFont
local flash = 0 -- intensité du flash
local pickupFlash = 0 -- petit flash jaune quand on ramasse un objet
local messageText, messageTime = nil, 0

function Hud.load()
    bigFont = love.graphics.newFont(32)
    hugeFont = love.graphics.newFont(56)
    smallFont = love.graphics.newFont(18)
end

function Hud.hurt(amount)
    flash = math.min(1, flash + amount / 25)
end

function Hud.message(text)
    messageText = text
    messageTime = 3
    pickupFlash = 0.35
end

function Hud.update(dt)
    flash = math.max(0, flash - dt * 1.5)
    pickupFlash = math.max(0, pickupFlash - dt * 2)
    messageTime = math.max(0, messageTime - dt)
end

local function levelColor(value, low, mid)
    if value > mid then
        love.graphics.setColor(0.4, 1, 0.4)
    elseif value > low then
        love.graphics.setColor(1, 0.85, 0.2)
    else
        love.graphics.setColor(1, 0.25, 0.2)
    end
end

function Hud.draw(player)
    local w, h = love.graphics.getDimensions()
    local previousFont = love.graphics.getFont()

    -- Flash rouge quand on est touché
    if flash > 0 then
        love.graphics.setColor(1, 0, 0, flash * 0.45)
        love.graphics.rectangle("fill", 0, 0, w, h)
    end

    -- Flash jaune quand on ramasse un objet
    if pickupFlash > 0 then
        love.graphics.setColor(1, 0.9, 0.3, pickupFlash * 0.4)
        love.graphics.rectangle("fill", 0, 0, w, h)
    end

    -- Barre du bas : munitions à gauche, armure au milieu, santé à droite
    love.graphics.setFont(bigFont)
    local y = h - 50

    levelColor(player.ammo or 0, 0, 5)
    love.graphics.printf("MUNITIONS " .. (player.ammo or 0), 20, y, w, "left")

    local armor = player.armor or 0
    if armor > 0 then
        love.graphics.setColor(0.5, 0.8, 1)
    else
        love.graphics.setColor(0.6, 0.6, 0.6)
    end
    love.graphics.printf("ARMURE " .. math.floor(armor) .. "%", 0, y, w, "center")

    levelColor(player.health or 0, 25, 50)
    love.graphics.printf("SANTÉ " .. math.floor(player.health or 0) .. "%", 0, y, w - 20, "right")

    if messageText and messageTime > 0 then
        love.graphics.setFont(smallFont)
        love.graphics.setColor(1, 1, 1, math.min(1, messageTime))
        love.graphics.printf(messageText, 0, 12, w, "center")
    end

    -- Écran de game over
    if player.dead then
        love.graphics.setColor(0.4, 0, 0, 0.55)
        love.graphics.rectangle("fill", 0, 0, w, h)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(hugeFont)
        love.graphics.printf("VOUS ÊTES MORT", 0, h / 2 - 60, w, "center")
        
        love.graphics.setFont(smallFont)
        love.graphics.printf("Appuyez sur Espace pour recommencer", 0, h / 2 + 10, w, "center")
    end

    love.graphics.setFont(previousFont)
end

return Hud
