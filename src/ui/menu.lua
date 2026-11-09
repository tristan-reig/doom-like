local Font = require("src.ui.font")
local Sound = require("src.audio.sound")
local Settings = require("src.settings")
local skills = require("src.data.skills")

Menu = {}

Menu.title = "DOOM-LIKE"
Menu.actions = {}

local images = {}
local page = nil
local selected = 1
local inGame = false
local skullTimer = 0

local TIC = 1 / 35;

-- Un réglage à curseur
local function slider(label, key, min, max, steps)
    return {
        label = label, slider = true, steps = steps,
        get = function() return math.floor((Settings[key] - min) / (max - min) * steps + 0.5) end,
        set = function(n)
            Settings[key] = min + (max - min) * n / steps
            Settings.apply()
            Settings.save()
        end,
    }
end

local pages = {}

local function mainPage()
    local items = {}
    if inGame then
        table.insert(items, { label = "Reprendre", action = function() Menu.actions.resume() end })
    end
    table.insert(items, { label = "Nouvelle partie", action = function() Menu.open("skill") end })
    table.insert(items, { label = "Options", action = function() Menu.open("options") end })
    table.insert(items, { label = "Quitter", action = function() Menu.actions.quit() end })
    return { title = nil, back = inGame and "resume" or nil, items = items }
end

pages.skill = function()
    local items = {}
    for i, skill in ipairs(skills) do
        table.insert(items, { label = skill.name, action = function()
            Settings.skill = i
            Settings.save()
            Menu.actions.newGame(i)
        end })
    end
    return { title = "Choisissez la difficulté", back = "main", items = items, start = Settings.skill }
end

pages.options = function()
    return {
        title = "Options",
        back = "main",
        items = {
            slider("Sensibilité souris", "sensitivity", 0.0005, 0.005, 9),
            slider("Volume", "volume", 0, 1, 10),
            { label = "Retour", action = function() Menu.open("main") end },
        },
    }
end

pages.main = mainPage

function Menu.load()
    for _, name in ipairs({ "m_skull1", "m_skull2", "m_therml", "m_thermm", "m_thermr", "m_thermo" }) do
        local img = love.graphics.newImage("assets/menu/" .. name .. ".png")
        img:setFilter("nearest", "nearest")
        images[name] = img
    end
end

function Menu.open(name, duringGame)
    if duringGame ~= nil then inGame = duringGame end
    page = pages[name]()
    page.name = name
    selected = page.start or 1
end

function Menu.close()
    page = nil
end

function Menu.isOpen()
    return page ~= nil
end

function Menu.keypressed(key)
    if not page then return end
    local item = page.items[selected]

    if key == "up" or key == "z" or key == "w" then
        selected = (selected - 2) % #page.items + 1
        Sound.play("menuMove")
    elseif key == "down" or key == "s" then
        selected = selected % #page.items + 1
        Sound.play("menuMove")
    elseif (key == "left" or key == "q" or key == "a") and item.slider then
        item.set(math.max(0, item.get() - 1))
        Sound.play("menuSlider")
    elseif (key == "right" or key == "d") and item.slider then
        item.set(math.min(item.steps, item.get() + 1))
        Sound.play("menuSlider")
    elseif (key == "return" or key == "kpenter" or key == "space") and item.action then
        Sound.play("menuSelect")
        item.action()
    elseif key == "escape" or key == "backspace" then
        if page.back == "resume" then
            Menu.actions.resume()
        elseif page.back then
            Sound.play("menuBack")
            Menu.open(page.back)
        end
    end
end

function Menu.update(dt)
    skullTimer = skullTimer + dt
end

function Menu.draw()
    if not page then return end
    local w, h = love.graphics.getDimensions()
    local s = math.min(w / 320, h / 200)
    local ox, oy = (w - 320 * s) / 2, (h - 200 * s) / 2
    local function X(x) return ox + x * s end
    local function Y(y) return oy + y * s end

    -- On assombrit le fond
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, w, h)

    -- Titre du jeu ou de la page
    love.graphics.setColor(1, 1, 1)
    if page.name == "main" then
        Font.print(Menu.title, w / 2, Y(28), s * 3, "center")
    else
        Font.print(page.title, w / 2, Y(32), s * 1.5, "center")
    end

    local textScale = s * 1.5
    local lineH = 16
    local x0 = page.name == "skill" and 50 or 110
    local y = 75
    local skullY
    for i, item in ipairs(page.items) do
        if i == selected then skullY = y end
        love.graphics.setColor(i == selected and { 1, 1, 1 } or { 0.6, 0.6, 0.6 })
        Font.print(item.label, X(x0), Y(y), textScale)
        y = y + lineH

        if item.slider then
            love.graphics.setColor(1, 1, 1)
            local tx = x0
            love.graphics.draw(images.m_therml, X(tx), Y(y - 4), 0, s, s)
            for n = 0, item.steps do
                love.graphics.draw(images.m_thermm, X(tx + 6 + n * 8), Y(y - 4), 0, s, s)
            end
            love.graphics.draw(images.m_thermr, X(tx + 6 + (item.steps + 1) * 8), Y(y - 4), 0, s, s)
            love.graphics.draw(images.m_thermo, X(tx + 8 + item.get() * 8), Y(y - 3), 0, s, s)
            y = y + lineH
        end
    end

    love.graphics.setColor(1, 1, 1)
    local skull = (math.floor(skullTimer / (8 * TIC)) % 2 == 0) and images.m_skull1 or images.m_skull2
    love.graphics.draw(skull, X(x0 - 26), Y(skullY - 6), 0, s, s)

    love.graphics.setColor(0.6, 0.6, 0.6)
    local help = "Flèches : choisir    Entrée : valider    Échap : retour"
    if page.items[selected].slider then help = "Gauche / droite : régler    Échap : retour" end
    Font.print(help, w / 2, Y(188), s * 0.75, "center")
end

return Menu
