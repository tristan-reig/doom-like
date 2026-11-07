-- Projectiles lancés par les monstres.
return {
    fireball = {
        radius = 6, height = 16,
        projectile = { speed = 175, damage = { 3, 24 } },
        states = {
            idle = { { "bal1a0", 4, bright = true }, { "bal1b0", 4, bright = true }, loop = true },
            death = {
                { "bal1c0", 6, bright = true, sound = "fireballHit" },
                { "bal1d0", 6, bright = true },
                { "bal1e0", 6, bright = true },
                { "bal1e0", 0, remove = true },
            },
        },
    },
}
