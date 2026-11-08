local Lighting = {}

Lighting.extra = 0

Lighting.boostPerLevel = 0.2

function Lighting.shade(dist, fadeDist)
    local shade = math.max(0.25, 1 - dist / fadeDist)
    return math.min(1, shade + Lighting.extra * Lighting.boostPerLevel)
end

return Lighting
