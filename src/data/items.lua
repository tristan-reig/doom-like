return {
    stimpack = { radius = 10, pickup = "stimpack", states = { idle = { { "stima0", -1 } } } },
    medikit = { radius = 10, pickup = "medikit",  states = { idle = { { "media0", -1 } } } },
    shells = { radius = 10, pickup = "shells",   states = { idle = { { "shela0", -1 } } } },
    shellBox = { radius = 10, pickup = "shellBox", states = { idle = { { "sboxa0", -1 } } } },
    clip = { radius = 10, pickup = "clip",     states = { idle = { { "clipa0", -1 } } } },
    ammoBox = { radius = 10, pickup = "ammoBox",  states = { idle = { { "ammoa0", -1 } } } },

    redKey = { radius = 10, pickup = "redKey",
                  states = { idle = { { "rkeya0", 10 }, { "rkeyb0", 10, bright = true }, loop = true } } },
    yellowKey = { radius = 10, pickup = "yellowKey",
                  states = { idle = { { "ykeya0", 10 }, { "ykeyb0", 10, bright = true }, loop = true } } },
    blueKey = { radius = 10, pickup = "blueKey",
                  states = { idle = { { "bkeya0", 10 }, { "bkeyb0", 10, bright = true }, loop = true } } },

    shotgunPickup = { radius = 10, pickup = "shotgun",  states = { idle = { { "shota0", -1 } } } },
    chaingunPickup = { radius = 10, pickup = "chaingun", states = { idle = { { "mguna0", -1 } } } },

    armor = {
        radius = 10, pickup = "armor",
        states = { idle = { { "arm1a0", 6 }, { "arm1b0", 6, bright = true }, loop = true } },
    },
}
