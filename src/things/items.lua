-- Objets ramassables
return {
    stimpack = { radius = 10, pickup = "stimpack", states = { idle = { { "stima0", -1 } } } },
    medikit = { radius = 10, pickup = "medikit",  states = { idle = { { "media0", -1 } } } },
    shells = { radius = 10, pickup = "shells",   states = { idle = { { "shela0", -1 } } } },
    shellBox = { radius = 10, pickup = "shellBox", states = { idle = { { "sboxa0", -1 } } } },

    armor = {
        radius = 10, pickup = "armor",
        states = { idle = { { "arm1a0", 6 }, { "arm1b0", 6, bright = true }, loop = true } },
    },
}
