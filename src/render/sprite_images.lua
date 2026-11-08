local offsets = require("src.render.sprite_offsets")

local SpriteImages = {}

local images = {}

function SpriteImages.isRotated(name)
    return not name:match("%d$")
end

local function fileExists(name)
    return love.filesystem.getInfo("assets/sprites/" .. name .. ".png") ~= nil
end

-- Charge une image et l'enregistre.
local function loadImage(name, file, mirrored)
    if images[name] then return end
    file = file or name
    local src = images[file]
    if src and mirrored then
        images[name] = {
            image = src.image, quads = src.quads, width = src.width, height = src.height,
            offX = src.width - src.offX, offY = src.offY, mirrored = true,
        }
        return
    end
    local img = love.graphics.newImage("assets/sprites/" .. file .. ".png")
    img:setFilter("nearest", "nearest")
    local iw, ih = img:getDimensions()

    local quads = {}
    for col = 0, iw - 1 do
        quads[col] = love.graphics.newQuad(col, 0, 1, ih, iw, ih)
    end

    local off = offsets[file] or { iw / 2, ih }

    images[file] = { image = img, quads = quads, width = iw, height = ih, offX = off[1], offY = off[2] }
    if mirrored then
        loadImage(name, file, true)
    elseif name ~= file then
        images[name] = images[file]
    end
end

-- Charge les 8 directions d'un sprite.
local function loadRotations(base)
    local letter = base:sub(-1)
    for rot = 1, 8 do
        if fileExists(base .. rot) then
            loadImage(base .. rot)
        else
            local a, b = math.min(rot, 10 - rot), math.max(rot, 10 - rot)
            local file = base .. a .. letter .. b
            assert(fileExists(file), "Image manquante pour " .. base .. rot)
            loadImage(base .. rot, file, rot == b)
        end
    end
end

-- Charge toutes les images utilisées par les types d'objets
function SpriteImages.loadAll(typeDefs)
    for _, def in pairs(typeDefs) do
        for _, state in pairs(def.states) do
            for _, frame in ipairs(state) do
                if SpriteImages.isRotated(frame[1]) then
                    loadRotations(frame[1])
                else
                    loadImage(frame[1])
                end
            end
        end
    end
end

-- Renvoie l'image enregistrée sous ce nom
function SpriteImages.get(name)
    return images[name]
end

return SpriteImages
