include("autorun/magic_stuff.lua")

TrashClasses = {
    "weapon_pistol",
    "weapon_smg1",
    "weapon_357",
    "weapon_shotgun",
    "weapon_ar2",
    "item_healthvial",
    "npc_grenade_frag",
    "item_ammo_ar2_altfire" --combine balls
}

function RemoveTrash()
    for i, entry in ipairs(TrashClasses) do
        for k, obj in ipairs(ents.FindByClass(entry)) do 
            if (obj != nil and not IsValid(obj:GetOwner())) then 
                obj:Remove()
            end
        end
    end
    print("Cleaned the map up.")
end

concommand.Add("ucc_clear",RemoveTrash)