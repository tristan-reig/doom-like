local Pickups = {}

Pickups.maxHealth = 100
Pickups.maxArmor = 100
Pickups.maxAmmo = { bullets = 200, shells = 50 }

-- Ajout de munitions
local function giveAmmo(p, kind, amount)
    if p.ammo[kind] >= Pickups.maxAmmo[kind] then return false end
    p.ammo[kind] = math.min(Pickups.maxAmmo[kind], p.ammo[kind] + amount)
    return true
end

-- Donne une arme au joueur
local function giveWeapon(p, weapon, ammoKind, amount)
    local isNew = not p.weapons[weapon]
    local gotAmmo = giveAmmo(p, ammoKind, amount)
    p.weapons[weapon] = true
    return isNew or gotAmmo, isNew
end

local effects = {
    stimpack = function (p)
        if p.health >= Pickups.maxHealth then return nil end
        p.health = math.min(Pickups.maxHealth, p.health + 10)
        return "Vous avez ramassé un stimpack."
    end,

    medikit = function (p)
        if p.health >= Pickups.maxHealth then return nil end
        local critical = p.health < 25
        p.health = math.min(Pickups.maxHealth, p.health + 25)
        if critical then
            return "Vous avez ramassé une trousse de soins dont vous aviez VRAIMENT besoin !"
        end
        return "Vous avez ramassé une trousse de soins."
    end,

    armor = function (p)
        if p.armor >= Pickups.maxArmor then return nil end
        p.armor = Pickups.maxArmor
        return "Vous avez ramassé l'armure"
    end,

    -- Munitions
    clip = function(p, dropped)
        if not giveAmmo(p, "bullets", dropped and 5 or 10) then return nil end
        return "Vous avez ramassé un chargeur."
    end,

    ammoBox = function(p)
        if not giveAmmo(p, "bullets", 50) then return nil end
        return "Vous avez ramassé une boîte de balles."
    end,

    shells = function(p)
        if not giveAmmo(p, "shells", 4) then return nil end
        return "Vous avez ramassé 4 cartouches."
    end,

    shellBox = function(p)
        if not giveAmmo(p, "shells", 20) then return nil end
        return "Vous avez ramassé une boîte de cartouches."
    end,

    -- Cartes d'accès
    redKey = function(p)
        p.keys.red = true
        return "Vous avez la carte rouge."
    end,
    yellowKey = function(p)
        p.keys.yellow = true
        return "Vous avez la carte jaune."
    end,
    blueKey = function(p)
        p.keys.blue = true
        return "Vous avez la carte bleue."
    end,

    shotgun = function(p, dropped)
        local taken, isNew = giveWeapon(p, "shotgun", "shells", dropped and 4 or 8)
        if not taken then return nil end
        return "Vous avez trouvé le fusil à pompe !", isNew and "shotgun" or nil
    end,

    chaingun = function(p, dropped)
        local taken, isNew = giveWeapon(p, "chaingun", "bullets", dropped and 10 or 20)
        if not taken then return nil end
        return "Vous avez trouvé la mitrailleuse !", isNew and "chaingun" or nil
    end,
}

-- Applique un objet au joueur
function Pickups.apply(player, kind, dropped)
    local effect = effects[kind]
    assert(effect, "Objet inconnu : " .. tostring(kind))
    return effect(player, dropped)
end

-- Calcule les dégâts reçus, en tenant compte de l'armure.
function Pickups.absorb(player, amount)
    if player.armor > 0 then
        local saved = math.floor(amount / 3)
        if saved > player.armor then saved = player.armor end
        player.armor = player.armor - saved
        amount = amount - saved
    end
    return amount
end

return Pickups
