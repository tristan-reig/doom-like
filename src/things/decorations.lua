-- Décors du niveaux (tonneaux, lampes, colonnes)
return {
    barrel = {
        health = 20, radius = 6, solid = true,
        states = {
            idle = { { "bar1a0", -1 } },
            death = {
                { "bexpa0", 5 },
                { "bexpb0", 5, sound = "barrel" },
                { "bexpc0", 5, bright = true, explode = true, notSolid = true },
                { "bexpd0", 10, bright = true },
                { "bexpe0", 10, bright = true },
                { "bexpe0", 0, remove = true },
            },
        },
    },

    lamp     = { radius = 8, solid = true, states = { idle = { { "colua0", -1 } } } },
    tallLamp = { radius = 8, solid = true, states = { idle = { { "tlmpa0", -1 } } } },
    column   = { radius = 8, solid = true, states = { idle = { { "col1a0", -1 } } } },
}
