local utf8 = require("utf8")

local Font = {}

local glyphs = {}
local SPACE = 4

local accents = {
    ["à"] = "A", ["â"] = "A", ["ä"] = "A", ["é"] = "E", ["è"] = "E", ["ê"] = "E", ["ë"] = "E",
    ["î"] = "I", ["ï"] = "I", ["ô"] = "O", ["ö"] = "O", ["ù"] = "U", ["û"] = "U", ["ü"] = "U",
    ["ç"] = "C", ["À"] = "A", ["Â"] = "A", ["É"] = "E", ["È"] = "E", ["Ê"] = "E", ["Î"] = "I",
    ["Ô"] = "O", ["Ù"] = "U", ["Û"] = "U", ["Ç"] = "C", ["’"] = "'",
}

function Font.load()
    for _, file in ipairs(love.filesystem.getDirectoryItems("assets/menu")) do
        local code = file:match("^stcfn(%d+)%.png$")
        if code then
            local img = love.graphics.newImage("assets/menu/" .. file)
            img:setFilter("nearest", "nearest")
            glyphs[tonumber(code)] = img
        end
    end
end

local function eachGlyph(text, fn)
    for _, codepoint in utf8.codes(text) do
        local ch = utf8.char(codepoint)
        ch = accents[ch] or ch:upper()
        local img = glyphs[ch:byte()]
        fn(img)
    end
end

function Font.width(text, scale)
    local w = 0
    eachGlyph(text, function(img) w = w + (img and img:getWidth() or SPACE) end)
    return w * scale
end

function Font.height(scale)
    return 7 * scale
end

function Font.print(text, x, y, scale, align)
    if align == "center" then x = x - Font.width(text, scale) / 2 end
    eachGlyph(text, function(img)
        if img then
            love.graphics.draw(img, x, y, 0, scale, scale)
            x = x + img:getWidth() * scale
        else
            x = x + SPACE * scale
        end
    end)
end

return Font