local Settings = {
    sensitivity = 0.002, -- sensibilité de la souris
    volume = 1, -- volume général
    skill = 3 -- difficulté
}

local FILE = "settings.txt"

function Settings.load()
    local content = love.filesystem.read(FILE)
    if content then
        for name, value in content:gmatch("(%w+)=([%d%.]+)") do
            if Settings[name] ~= nil and type(Settings[name]) == "number" then
                Settings[name] = tonumber(value)
            end
        end
    end
    Settings.apply()
end

function Settings.save()
    local lines = {}
    for _, name in ipairs({ "sensitivity", "volume", "skill" }) do
        table.insert(lines, name .. "=" .. tostring(Settings[name]))
    end
    love.filesystem.write(FILE, table.concat(lines, "\n") .. "\n")
end

function Settings.apply()
    love.audio.setVolume(Settings.volume)
end

return Settings
