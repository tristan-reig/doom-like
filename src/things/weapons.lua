return {
    order = { "chaingun", "shotgun", "pistol" },

    pistol = {
        slot = 2, name = "le pistolet", ammo = "bullets", sound = "pistol",
        frames = {
            A = { "pisga0", 135, 132 },
            B = { "pisgb0", 134, 124 },
            C = { "pisgc0", 134, 124 },
        },
        fire = { { "A", 4 }, { "B", 6, fire = true, flash = 1 }, { "C", 4 }, { "B", 5 } },
        flashes = { { { "pisfa0", 145, 111, 7 } } },
        shot = { pellets = 1, spread = 5.6, accurateFirst = true },
    },

    shotgun = {
        slot = 3, name = "le fusil à pompe", ammo = "shells", sound = "shotgun",
        frames = {
            A = { "shtga0", 123, 139 },
            B = { "shtgb0", 74, 91 },
            C = { "shtgc0", 35, 59 },
            D = { "shtgd0", 43, 81 },
        },
        fire = {
            { "A", 3 },
            { "A", 7, fire = true, flash = 1 },
            { "B", 3 }, { "C", 5 }, { "D", 4 }, { "C", 5 }, { "B", 5 },
            { "A", 3 }, { "A", 7 },
        },
        flashes = { { { "shtfa0", 143, 130, 4 }, { "shtfb0", 132, 122, 3 } } },
        shot = { pellets = 7, spread = 5.6 },
    },

    chaingun = {
        slot = 4, name = "la mitrailleuse", ammo = "bullets", sound = "pistol",
        frames = {
            A = { "chgga0", 108, 149 },
            B = { "chggb0", 108, 153 },
        },
        fire = { { "A", 4, fire = true, flash = 1 }, { "B", 4, fire = true, flash = 2 } },
        flashes = { { { "chgfa0", 127, 130, 5 } }, { { "chgfb0", 129, 143, 5 } } },
        shot = { pellets = 1, spread = 5.6, accurateFirst = true },
    },
}
