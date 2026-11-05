local Hud = {}

local bigFont, hugeFont, smallFont
local flash = 0 -- intensité du flash

function Hud.load()
    bigFont = love.graphics.newFont(32)
    hugeFont = love.graphics.newFont(56)
    smallFont = love.graphics.newFont(18)
end

function Hud.hurt(amount)
    flash = math.min(1, flash + amount / 25)
end

function Hud.update(dt)
    flash = math.max(0, flash - dt * 1.5)
end

function Hud.draw(player)
    local w, h = love.graphics.getDimensions()
    local previousFont = love.graphics.getFont()

    -- Flash rouge quand on est touché
    if flash > 0 then
        love.graphics.setColor(1, 0, 0, flash * 0.45)
        love.graphics.rectangle("fill", 0, 0, w, h)
    end

    -- Affichage de la santé
    local hp = player.health or 0
    if hp > 50 then
        love.graphics.setColor(0.4, 1, 0.4)
    elseif hp > 25 then
        love.graphics.setColor(1, 0.85, 0.2)
    else
        love.graphics.setColor(1, 0.25, 0.2)
    end
    love.graphics.setFont(bigFont)
    love.graphics.printf("SANTÉ " .. math.floor(hp) .. "%", 0, h - 50, w - 20, "right")

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
