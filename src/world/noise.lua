local Map = require("src.world.map")
local Doors = require("src.world.doors")

local Noise = {}

Noise.maxSteps = 20

-- Le son peut-il passer par cette case
local function soundPasses(col, row)
    local tile = Map.grid[row] and Map.grid[row][col]
    if tile == nil then return false end
    if tile == 0 then return true end
    if tile == Map.DOOR then
        local open = Doors.openness(col, row)
        return open ~= nil and open > 0
    end
    return false
end

-- Propage un bruit depuis le point (x, y).
function Noise.propagate(x, y)
    local startCol, startRow = Map.cellAt(x, y)
    local reached = { [startRow] = { [startCol] = 0 } }
    local queue = { { startCol, startRow } }
    local head = 1

    while head <= #queue do
        local col, row = queue[head][1], queue[head][2]
        head = head + 1
        local steps = reached[row][col]

        if steps < Noise.maxSteps then
            for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
                local c, r = col + d[1], row + d[2]
                if soundPasses(c, r) and not (reached[r] and reached[r][c]) then
                    reached[r] = reached[r] or {}
                    reached[r][c] = steps + 1
                    table.insert(queue, { c, r })
                end
            end
        end
    end

    return reached
end

-- La case qui contient le point a-t-elle été atteinte par le bruit ?
function Noise.heard(reached, x, y)
    local col, row = Map.cellAt(x, y)
    return reached[row] ~= nil and reached[row][col] ~= nil
end

return Noise
