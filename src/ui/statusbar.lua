local Pickups = require("src.player.pickups")

local StatusBar = {}

local TIC = 1 / 35
local images = {}

local faceOffsets = {
    stfdead0 = { -5, -1 },
    stfevl0 = { -5, -2 },
    stfevl1 = { -5, -2 },
    stfevl2 = { -5, -2 },
    stfevl3 = { -5, -2 },
    stfevl4 = { -5, -2 },
    stfkill0 = { -5, -2 },
    stfkill1 = { -5, -2 },
    stfkill2 = { -5, -2 },
    stfkill3 = { -5, -2 },
    stfkill4 = { -5, -2 },
    stfouch0 = { -5, -1 },
    stfouch1 = { -5, -1 },
    stfouch2 = { -5, -1 },
    stfouch3 = { -5, -1 },
    stfouch4 = { -5, -1 },
    stfst00 = { -5, -2 },
    stfst01 = { -5, -2 },
    stfst02 = { -5, -2 },
    stfst10 = { -5, -2 },
    stfst11 = { -5, -2 },
    stfst12 = { -5, -2 },
    stfst20 = { -5, -2 },
    stfst21 = { -5, -2 },
    stfst22 = { -5, -2 },
    stfst30 = { -5, -1 },
    stfst31 = { -5, -1 },
    stfst32 = { -5, -1 },
    stfst40 = { -5, -1 },
    stfst41 = { -5, -1 },
    stfst42 = { -5, -1 },
    stftl00 = { -5, -1 },
    stftl10 = { -5, -2 },
    stftl20 = { -4, -1 },
    stftl30 = { -2, -1 },
    stftl40 = { -1, -1 },
    stftr00 = { -3, -2 },
    stftr10 = { -3, -2 },
    stftr20 = { -4, -1 },
    stftr30 = { -3, -2 },
    stftr40 = { -3, -2 },
}

local function img(name)
    return images[name]
end

function StatusBar.load()
    local files = love.filesystem.getDirectoryItems("assets/hud")
    for _, file in ipairs(files) do
        local name = file:match("^(.+)%.png$")
        if name then
            local i = love.graphics.newImage("assets/hud/" .. file)
            i:setFilter("nearest", "nearest")
            images[name] = i
        end
    end
end

-- Visage du joueur
local face = {
    look = 1,         -- regard : 0, 1 ou 2 pour droite, face ou gauche
    lookTimer = 0,
    hurtTimer = 0,
    hurtFace = nil,
    ouchTimer = 0,
    fireTime = 0,
    evilTimer = 0,
}

function StatusBar.grin()
    face.evilTimer = 2
end

function StatusBar.hurt(amount, source, player)
    if amount > 20 then
        face.ouchTimer = 1
    end
    if source and source.x then
        local toSource = math.atan2(source.y - player.y, source.x - player.x)
        local diff = (toSource - player.angle + math.pi) % (2 * math.pi) - math.pi
        if math.abs(diff) < math.pi / 4 then
            face.hurtFace = "front"
        elseif diff > 0 then
            face.hurtFace = "right"
        else
            face.hurtFace = "left"
        end
        face.hurtTimer = 1
    end
end

-- Réaction quand le joueur tire
function StatusBar.update(dt, player, firing)
    face.lookTimer = face.lookTimer - dt
    if face.lookTimer <= 0 then
        face.look = math.random(0, 2)
        face.lookTimer = 17 * TIC
    end
    face.hurtTimer = math.max(0, face.hurtTimer - dt)
    face.ouchTimer = math.max(0, face.ouchTimer - dt)
    face.evilTimer = math.max(0, face.evilTimer - dt)
    face.fireTime = firing and (face.fireTime + dt) or 0
end

-- Nom de l'image du visage à afficher
local function faceImage(player)
    if player.dead then return "stfdead0" end

    local health = math.max(0, math.min(100, player.health))
    local pain = math.min(4, math.floor((100 - health) * 5 / 101))

    if face.evilTimer > 0 then return "stfevl" .. pain end
    if face.ouchTimer > 0 then return "stfouch" .. pain end
    if face.hurtTimer > 0 then
        if face.hurtFace == "front" then return "stfkill" .. pain end
        if face.hurtFace == "right" then return "stftr" .. pain .. "0" end
        return "stftl" .. pain .. "0"
    end
    -- S'il tire trop longtemps, son regard change
    if face.fireTime > 2 then return "stfkill" .. pain end
    return "stfst" .. pain .. face.look
end

-- Dessine une image aux coordonnées (x, y)
local function draw(name, x, y, s, ox, oy)
    local i = img(name)
    if i then love.graphics.draw(i, ox + x * s, oy + y * s, 0, s, s) end
end

local function drawNumber(prefix, value, x, y, s, ox, oy)
    local text = tostring(math.max(0, math.floor(value)))
    local digitW = img(prefix .. "0"):getWidth()
    for i = #text, 1, -1 do
        x = x - digitW
        draw(prefix .. text:sub(i, i), x, y, s, ox, oy)
    end
end

-- Hauteur de la barre à l'écran, en pixels
function StatusBar.height()
    return 32 * love.graphics.getWidth() / 320
end

function StatusBar.draw(player, ownedWeapons, currentAmmo)
    local w, h = love.graphics.getDimensions()
    local s = w / 320
    local ox, oy = 0, h - 200 * s

    love.graphics.setColor(1, 1, 1)
    draw("stbar", 0, 168, s, ox, oy)
    draw("starms", 104, 168, s, ox, oy)

    -- Munitions de l'arme en main, santé et armure
    drawNumber("sttnum", currentAmmo or 0, 44, 171, s, ox, oy)
    drawNumber("sttnum", player.health or 0, 90, 171, s, ox, oy)
    draw("sttprcnt", 90, 171, s, ox, oy)
    drawNumber("sttnum", player.armor or 0, 221, 171, s, ox, oy)
    draw("sttprcnt", 221, 171, s, ox, oy)

    -- Armes possédées
    for slot = 2, 7 do
        local i = slot - 2
        local prefix = (ownedWeapons and ownedWeapons[slot]) and "stysnum" or "stgnum"
        draw(prefix .. slot, 111 + (i % 3) * 12, 172 + math.floor(i / 3) * 10, s, ox, oy)
    end

    -- Visage du personnage
    local name = faceImage(player)
    local off = faceOffsets[name] or { 0, 0 }
    draw(name, 143 - off[1], 168 - off[2], s, ox, oy)

    -- Affichage des cartes
    if player.keys then
        if player.keys.blue then draw("stkeys0", 239, 171, s, ox, oy) end
        if player.keys.yellow then draw("stkeys1", 239, 181, s, ox, oy) end
        if player.keys.red then draw("stkeys2", 239, 191, s, ox, oy) end
    end

    -- Tableau des munitions
    local ammo = {
        { player.ammo.bullets, Pickups.maxAmmo.bullets },
        { player.ammo.shells, Pickups.maxAmmo.shells },
        { 0, 50 },
        { 0, 300 },
    }
    for i, a in ipairs(ammo) do
        local y = 173 + (i - 1) * 6
        drawNumber("stysnum", a[1], 288, y, s, ox, oy)
        drawNumber("stysnum", a[2], 314, y, s, ox, oy)
    end
end

return StatusBar
