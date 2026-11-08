-- Données des monstres (zombie, imp)
return {
    zombie = {
        health = 20, radius = 10, solid = true, painChance = 200 / 256,
        monster = true, speed = 35, sightSound = "zombieSight",
        drop = "shells",
        states = {
            idle = { { "possa", 10, action = "look" }, { "possb", 10, action = "look" }, loop = true },
            chase = {
                { "possa", 4, action = "chase" }, { "possa", 4, action = "chase" },
                { "possb", 4, action = "chase" }, { "possb", 4, action = "chase" },
                { "possc", 4, action = "chase" }, { "possc", 4, action = "chase" },
                { "possd", 4, action = "chase" }, { "possd", 4, action = "chase" },
                loop = true,
            },
            missile = {
                { "posse", 10, action = "face" },
                { "possf", 8, bright = true, action = "shoot" },
                { "posse", 8 },
                next = "chase",
            },
            pain = { { "possg", 3 }, { "possg", 3, sound = "zombiePain" }, next = "chase" },
            death = {
                { "possh0", 5 },
                { "possi0", 5, sound = "zombieDeath" },
                { "possj0", 5, notSolid = true },
                { "possk0", 5 },
                { "possl0", -1 },
            },
            gib = {
                { "possm0", 5 },
                { "possn0", 5, sound = "gib" },
                { "posso0", 5, notSolid = true },
                { "possp0", 5 }, { "possq0", 5 }, { "possr0", 5 },
                { "posss0", 5 }, { "posst0", 5 },
                { "possu0", -1 },
            },
        },
    },

    imp = {
        health = 60, radius = 10, solid = true, painChance = 200 / 256,
        monster = true, speed = 35, meleeRange = 34,
        sightSound = { "impSight1", "impSight2" },
        states = {
            idle = { { "trooa", 10, action = "look" }, { "troob", 10, action = "look" }, loop = true },
            chase = {
                { "trooa", 3, action = "chase" }, { "trooa", 3, action = "chase" },
                { "troob", 3, action = "chase" }, { "troob", 3, action = "chase" },
                { "trooc", 3, action = "chase" }, { "trooc", 3, action = "chase" },
                { "trood", 3, action = "chase" }, { "trood", 3, action = "chase" },
                loop = true,
            },
            missile = {
                { "trooe", 8, action = "face" },
                { "troof", 8, action = "face" },
                { "troog", 6, action = "impAttack" },
                next = "chase",
            },
            pain = { { "trooh", 2 }, { "trooh", 2, sound = "zombiePain" }, next = "chase" },
            death = {
                { "trooi0", 8 },
                { "trooj0", 8, sound = { "impDeath1", "impDeath2" } },
                { "trook0", 6 },
                { "trool0", 6, notSolid = true },
                { "troom0", -1 },
            },
            gib = {
                { "troon0", 5 },
                { "trooo0", 5, sound = "gib" },
                { "troop0", 5, notSolid = true },
                { "trooq0", 5 }, { "troor0", 5 }, { "troos0", 5 }, { "troot0", 5 },
                { "troou0", -1 },
            },
        },
    },
}
