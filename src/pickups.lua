local Pickups = {}

Pickups.maxHealth = 100
Pickups.maxArmor = 100
Pickups.maxAmmo = 50

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

    shells = function (p)
        if p.ammo >= Pickups.maxAmmo then return nil end
        p.ammo = math.min(Pickups.maxAmmo, p.ammo + 4)
        return "Vous avez ramassé 4 cartouches."
    end,

    shellBox = function (p)
        if p.ammo >= Pickups.maxAmmo then return nil end
        p.ammo = math.min(Pickups.maxAmmo, p.ammo + 20)
        return "Vous avez ramassé une boîte de cartouches."
    end,

    armor = function (p)
        if p.armor >= Pickups.maxArmor then return nil end
        p.armor = Pickups.maxArmor
        return "Vous avez ramassé l'armure"
    end,
}

-- Applique un objet au joueur
function Pickups.apply(player, kind)
    local effect = effects[kind]
    assert(effect, "Objet inconnu : " .. tostring(kind))
    return effect(player)
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
