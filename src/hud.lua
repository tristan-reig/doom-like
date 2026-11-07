local Hud = {}

local bigFont, hugeFont, smallFont
local flash = 0 -- intensité du flash rouge
local pickupFlash = 0 -- petit flash jaune quand on ramasse un objet
local messageText, messageTime = nil, 0

function Hud.load()
    bigFont = love.graphics.newFont(32)
    hugeFont = love.graphics.newFont(56)
    smallFont = love.graphics.newFont(18)
end

-- Le joueur vient de perdre des points de vie
function Hud.hurt(amount)
    flash = math.min(1, flash + amount / 25)
end

-- Affiche un message en haut de l'écran
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

    if messageText and messageTime > 0 then
        love.graphics.setFont(smallFont)
        love.graphics.setColor(1, 1, 1, math.min(1, messageTime)) -- s'efface à la fin
        love.graphics.printf(messageText, 0, 12, w, "center")
    end

    -- Écran de mort
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

local function percent(done, total)
    if total == 0 then return 100 end
    return math.floor(done / total * 100)
end

-- Écran de fin de niveau avec les statistiques
function Hud.drawIntermission(info)
    local w, h = love.graphics.getDimensions()
    local previousFont = love.graphics.getFont()

    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, w, h)

    love.graphics.setColor(1, 0.3, 0.2)
    love.graphics.setFont(hugeFont)
    love.graphics.printf(info.name, 0, h * 0.18, w, "center")
    love.graphics.setFont(bigFont)
    love.graphics.printf("TERMINÉ", 0, h * 0.18 + 70, w, "center")

    local minutes = math.floor(info.time / 60)
    local seconds = math.floor(info.time % 60)
    local lines = {
        { "ENNEMIS", percent(info.kills, info.totalKills) .. " %" },
        { "OBJETS", percent(info.items, info.totalItems) .. " %" },
        { "TEMPS", string.format("%d:%02d", minutes, seconds) },
    }
    love.graphics.setColor(1, 1, 1)
    for i, line in ipairs(lines) do
        local y = h * 0.45 + (i - 1) * 50
        love.graphics.printf(line[1], 0, y, w / 2 - 20, "right")
        love.graphics.printf(line[2], w / 2 + 20, y, w, "left")
    end

    love.graphics.setFont(smallFont)
    love.graphics.setColor(1, 1, 1, 0.8)
    local next = info.last and "Appuyez sur Espace" or "Appuyez sur Espace pour le niveau suivant"
    love.graphics.printf(next, 0, h * 0.85, w, "center")

    love.graphics.setFont(previousFont)
end

-- Écran de victoire
function Hud.drawVictory()
    local w, h = love.graphics.getDimensions()
    local previousFont = love.graphics.getFont()

    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(1, 0.85, 0.2)
    love.graphics.setFont(hugeFont)
    love.graphics.printf("VICTOIRE !", 0, h / 2 - 80, w, "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(smallFont)
    love.graphics.printf("Vous avez terminé tous les niveaux.\nAppuyez sur Espace pour recommencer.", 0, h / 2 + 10, w, "center")

    love.graphics.setFont(previousFont)
end

return Hud
