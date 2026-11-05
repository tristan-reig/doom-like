local Map = {}

Map.tileSize = 64

Map.EXIT = 5
Map.EXIT_ON = 6

Map.grid = { { 1 } }
Map.rows = 1
Map.cols = 1

function Map.setGrid(grid)
    Map.grid = grid
    Map.rows = #grid
    Map.cols = #grid[1]
end

-- Renvoie la valeur de la case contenant le point (x, y) en coordonnées monde.
function Map.getTileAt(x, y)
    local col = math.floor(x / Map.tileSize) + 1
    local row = math.floor(y / Map.tileSize) + 1
    if row < 1 or row > Map.rows or col < 1 or col > Map.cols then
        return 1
    end
    return Map.grid[row][col]
end

-- Change la valeur de la case qui contient le point (x, y)
function Map.setTileAt(x, y, value)
    local col = math.floor(x / Map.tileSize) + 1
    local row = math.floor(y / Map.tileSize) + 1
    if Map.grid[row] and Map.grid[row][col] then
        Map.grid[row][col] = value
    end
end

function Map.isWall(x, y)
    return Map.getTileAt(x, y) ~= 0
end

Map.colors = {
    [1] = {0.55, 0.55, 0.55},
    [2] = {0.70, 0.25, 0.20},
    [3] = {0.25, 0.45, 0.70},
    [4] = {0.55, 0.40, 0.20},
    [5] = {0.90, 0.10, 0.10},
    [6] = {0.10, 0.90, 0.10},
}

-- Dessin vue de dessus
function Map.draw(scale)
    scale = scale or 1
    local s = Map.tileSize * scale
    for row = 1, Map.rows do
        for col = 1, Map.cols do
            local tile = Map.grid[row][col]
            if tile ~= 0 then
                love.graphics.setColor(Map.colors[tile] or {1, 1, 1})
            else
                love.graphics.setColor(0.1, 0.1, 0.1)
            end
            love.graphics.rectangle("fill", (col - 1) * s, (row - 1) * s, s - 1, s - 1)
        end
    end
end

return Map
