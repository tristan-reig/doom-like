local Sound = require("src.audio.sound")

local Doors = {}

Doors.speed = 1
Doors.waitTime = 4
Doors.passable = 0.75

Doors.list = {}

function Doors.clear()
    Doors.list = {}
end

function Doors.add(col, row, key)
    Doors.list[row] = Doors.list[row] or {}
    Doors.list[row][col] = {
        col = col, row = row, key = key,
        open = 0,
        state = "closed",
        timer = 0,
    }
end

function Doors.get(col, row)
    return Doors.list[row] and Doors.list[row][col]
end

function Doors.openness(col, row)
    local d = Doors.get(col, row)
    return d and d.open
end

function Doors.isPassable(col, row)
    local d = Doors.get(col, row)
    return d ~= nil and d.open >= Doors.passable
end

local function center(d, tileSize)
    return (d.col - 0.5) * tileSize, (d.row - 0.5) * tileSize
end

-- Ouverture / Fermeture de la porte
function Doors.use(col, row, player, tileSize, byMonster)
    local d = Doors.get(col, row)
    if not d then return false end

    if d.key and d.state == "closed" then
        if byMonster then return false end
        if not (player.keys and player.keys[d.key]) then return false, "locked", d.key end
    end

    if d.state == "closed" or d.state == "closing" then
        d.state = "opening"
        local x, y = center(d, tileSize)
        Sound.playAt("doorOpen", x, y, player)
        return true
    elseif d.state == "open" and not byMonster then
        d.state = "closing" -- le joueur peut refermer une porte ouverte
        local x, y = center(d, tileSize)
        Sound.playAt("doorClose", x, y, player)
        return true
    end
    return false
end

-- Y a-t-il quelque chose devant la porte ?
function Doors.update(dt, player, tileSize, isOccupied)
    for _, row in pairs(Doors.list) do
        for _, d in pairs(row) do
            if d.state == "opening" then
                d.open = math.min(1, d.open + Doors.speed * dt)
                if d.open >= 1 then
                    d.state = "open"
                    d.timer = Doors.waitTime
                end

            elseif d.state == "open" then
                d.timer = d.timer - dt
                if d.timer <= 0 then
                    if isOccupied(d.col, d.row) then
                        d.timer = 1
                    else
                        d.state = "closing"
                        local x, y = center(d, tileSize)
                        Sound.playAt("doorClose", x, y, player)
                    end
                end

            elseif d.state == "closing" then
                if isOccupied(d.col, d.row) then
                    d.state = "opening"
                    local x, y = center(d, tileSize)
                    Sound.playAt("doorOpen", x, y, player)
                else
                    d.open = math.max(0, d.open - Doors.speed * dt)
                    if d.open <= 0 then d.state = "closed" end
                end
            end
        end
    end
end

return Doors
