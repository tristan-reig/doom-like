local Sound = {}

local soundFiles = {
    shotgun = "assets/sounds/dsshotgn.wav",
    barrel = "assets/sounds/dsbarexp.wav"
}

local sources = {}

Sound.maxDistance = 1200

function Sound.load()
    for name, path in pairs(soundFiles) do
        sources[name] = love.audio.newSource(path, "static")
    end
end

local function playCopy(name, volume)
    local src = sources[name]
    if not src then return nil end
    local copy = src:clone()
    copy:setVolume(volume or 1)
    copy:play()
    return copy
end

-- Son venant du joueur
function Sound.play(name)
    playCopy(name)
end

function Sound.playAt(name, x, y, player)
    local dx, dy = x - player.x, y - player.y
    local dist = math.sqrt(dx * dx + dy * dy)

    local volume = 1 - dist / Sound.maxDistance
    if volume <= 0 then return end

    local copy = playCopy(name, volume)
    if not copy then return end

    -- Position relative à l'auditeur
    if dist > 1 then
        local cos, sin = math.cos(player.angle), math.sin(player.angle)
        local depth = (dx * cos + dy * sin) / dist
        local side = (-dx * sin + dy * cos) / dist
        copy:setRelative(true)
        copy:setPosition(side, 0, -depth)
    end
end

return Sound
