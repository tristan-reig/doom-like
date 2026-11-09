local Map = require("src.world.map")
local Doors = require("src.world.doors")

local Level = {}

-- Murs
local walls = {
    ["#"] = 1, -- briques
    ["T"] = 2, -- tuyaux
    ["M"] = 3, -- métal
    ["C"] = 4, -- caisses
    ["E"] = Map.EXIT, -- interrupteur de sortie
    ["D"] = Map.DOOR, -- porte
    ["R"] = Map.DOOR_RED, -- porte rouge
    ["Y"] = Map.DOOR_YELLOW, -- porte jaune
    ["B"] = Map.DOOR_BLUE, -- porte bleue
}

-- Objets et monstres
local things = {
    ["Z"] = "zombie",
    ["I"] = "imp",
    ["X"] = "demon",
    ["b"] = "barrel",
    ["l"] = "lamp",
    ["L"] = "tallLamp",
    ["c"] = "column",
    ["+"] = "stimpack",
    ["H"] = "medikit",
    ["s"] = "shells",
    ["S"] = "shellBox",
    ["A"] = "armor",
    ["a"] = "clip",
    ["m"] = "ammoBox",
    ["3"] = "shotgunPickup",
    ["4"] = "chaingunPickup",
    ["r"] = "redKey",
    ["y"] = "yellowKey",
    ["u"] = "blueKey",
}

-- Départ du joueur
local starts = {
    [">"] = 0,
    ["v"] = math.pi / 2,
    ["<"] = math.pi,
    ["^"] = -math.pi / 2,
}

-- Lit le fichier et renvoie le niveau
function Level.load(path)
    local content = assert(love.filesystem.read(path), "Niveau introuvable : " .. path)

    local level = { name = path, grid = {}, things = {}, start = nil }
    local lines = {}

    for line in (content .. "\n"):gmatch("(.-)\r?\n") do
        local name = line:match("^;%s*nom%s*:%s*(.-)%s*$")
        if name then
            level.name = name
        elseif not line:match("^;") and line ~= "" then
            table.insert(lines, line)
        end
    end

    local width = 0
    for _, line in ipairs(lines) do width = math.max(width, #line) end

    for row, line in ipairs(lines) do
        level.grid[row] = {}
        for col = 1, width do
            local ch = line:sub(col, col)
            if ch == "" then ch = "#" end

            if walls[ch] then
                level.grid[row][col] = walls[ch]
            else
                level.grid[row][col] = 0 -- tout le reste est du sol
                if things[ch] then
                    -- Les monstres regardent dans une direction au hasard
                    local angle = math.random(0, 3) * math.pi / 2
                    table.insert(level.things, { type = things[ch], col = col, row = row, angle = angle })
                elseif starts[ch] then
                    level.start = { col = col, row = row, angle = starts[ch] }
                elseif ch ~= "." and ch ~= " " then
                    error(string.format("%s : caractère inconnu '%s' (ligne %d, colonne %d)", path, ch, row, col))
                end
            end
        end
    end

    assert(level.start, path .. " : pas de départ du joueur (> v < ^)")
    return level
end

function Level.start(level, player, Sprites, monsterRatio)
    monsterRatio = monsterRatio or 1
    Map.setGrid(level.grid)

    -- Créer les portes du niveau
    Doors.clear()
    for row, line in ipairs(level.grid) do
        for col, tile in ipairs(line) do
            if Map.isDoor(tile) then Doors.add(col, row, Map.doorKeys[tile]) end
        end
    end

    Sprites.clear()
    local monsterCount = 0
    for _, t in ipairs(level.things) do
        local keep = true
        if Sprites.getDefByName(t.type).monster then
            monsterCount = monsterCount + 1
            keep = math.floor(monsterCount * monsterRatio) > math.floor((monsterCount - 1) * monsterRatio)
        end
        if keep then Sprites.add(t.type, t.col, t.row, t.angle) end
    end
    Sprites.countTotals()

    player.x = (level.start.col - 0.5) * Map.tileSize
    player.y = (level.start.row - 0.5) * Map.tileSize
    player.angle = level.start.angle
end

return Level
