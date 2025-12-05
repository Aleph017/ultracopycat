include("autorun/magic_stuff.lua")

util.AddNetworkString("Connection")
util.AddNetworkString("ToSendToClient")
Player_table = player.GetAll()
Weapons = {"weapon_pistol", "weapon_smg1", "weapon_shotgun", "weapon_357"} --cops weapon pool
Cops_count = 0
Cops_cap = 25

for i, j in pairs(Player_table) do
  j:ChatPrint("Got the list of players.")
  j:ChatPrint("Greetings, " .. j:Nick() .. "!")
end

function Distance(ent0, ent1)
  local pos0 = ent0:GetPos()
  local pos1 = ent1:GetPos()
  local distance = math.sqrt(
    (pos0.x - pos1.x)^2 +
    (pos0.y - pos1.y)^2 +
    (pos0.z - pos1.z)^2
  )
  return distance
end

function SpawnCops(areas)
  --print("Updating the player list")
  Player_table = player.GetAll()
  --print("Spawning " .. Cops_cap - Cops_count .. " cops.")
  while Cops_count < Cops_cap do
    local area = table.Random(areas)
    if area:IsUnderwater() then
      continue
    end
    local pos = area:GetRandomPoint()
    --find out if the random point is good
    local tr = util.TraceLine({
      start = pos + Vector(0,0,100),
      endpos = pos - Vector(0,0,2000),
      mask = MASK_SOLID_BRUSHONLY
    })

    local npc = ents.Create("npc_metropolice")
    
    npc:SetPos(tr.HitPos + Vector(0,0,10))
    npc:Spawn()
    npc:Give(table.Random(Weapons))
    --ai conditions that help the cops chase the player
    npc:SetCondition(COND.SEE_ENEMY)
    npc:SetCondition(COND.SEE_HATE)
    npc:SetCondition(COND.NPC_UNFREEZE)
    npc:SetCondition(COND.SEE_PLAYER)
    for i, ply in ipairs(Player_table) do
      npc:AddEntityRelationship(ply, D_HT, 99)
    end
    local enemy = table.Random(Player_table)
    npc:SetEnemy(enemy)
    npc:SetLastPosition(enemy:GetPos())
    npc:SetSchedule(SCHED_CHASE_ENEMY)
    npc:SetNPCState(NPC_STATE_ALERT)
    --assign cops to a team
    if ai.GetSquadMemberCount("termination_team0") < 16 then
      npc:SetSquad("termination_team0")
    else
      npc:SetSquad("termination_team1")
    end
    npc:MoveOrder(enemy:GetPos())
    Cops_count = Cops_count+1
  end
  if not timer.Exists("ChaseUpdate") then
    timer.Create("ChaseUpdate", 5, 0, function()
      print("Updating the chase...")
      local cops = ents.FindByClass("npc_metropolice")
      if next(cops) == nil then
        print("All cops are dead, stopped updating the chase.")
        timer.Remove("ChaseUpdate")
        timer.Remove("GiveEmGrenades")
        return
      end
      for i, npc in ipairs(cops) do
        npc:SetCondition(COND.SEE_HATE)
        npc:SetCondition(COND.SEE_PLAYER)
        npc:SetCondition(COND.SEE_ENEMY)
        local enemy = npc:GetEnemy()
        if IsValid(enemy) then npc:SetLastPosition(enemy:GetPos()) end
        npc:SetSchedule(SCHED_CHASE_ENEMY)

        if not npc:IsInWorld() then
          if IsValid(enemy) then
            npc:SetPos(enemy:GetPos() + Vector(math.random(40,80), math.random(40,80),0))
          end
        end

      end
    end)
  end
end

function StartSpawning()
  local areas = navmesh.GetAllNavAreas()
  if not timer.Exists("Spawner") then
    SpawnCops(areas)
    timer.Create("Spawner", 10, 0, function()
      SpawnCops(areas)
    end)
  end
end

hook.Add("PlayerSay","SpawnStuff", function(ply, text)
  if string.lower(text) == Magic_word then
    for i, ply in pairs(Player_table) do
      ply:Give("weapon_crowbar")
    end
    StartSpawning()

    timer.Create("GiveEmGrenades", 15, 0, function() --each 15 seconds give every player grenades until they have at least 3
      for i, ply in pairs(Player_table) do
        ply:Give("weapon_frag")
        local grenades_count = ply:GetAmmoCount("Grenade")
        if grenades_count < 3 then
          ply:GiveAmmo(3 - grenades_count, "Grenade")
        end
      end
    end)

  --stop gently
  elseif text == Stop_word and timer.Exists("Spawner") then
    timer.Remove("Spawner")
  --stop forced
  elseif text == Force_exit_word then
    local cops = ents.FindByClass("npc_metropolice")
    if next(cops) != nil then -- remove all cops if there are any
      for i, npc in ipairs(cops) do
        npc:Remove()
      end
    end

    --stop all timers
    if timer.Exists("Spawner") then timer.Remove("Spawner") end
    if timer.Exists("ChaseUpdate") then timer.Remove("ChaseUpdate") end
    if timer.Exists("GiveEmGrenades") then timer.Remove("GiveEmGrenades") end
    Cops_count = 0 --reset cops count
  end
end)

hook.Add("PlayerSpawn", "GiveEmACrowbar", function(ply, transiton)
  ply:Give("weapon_crowbar")
end)

hook.Add("OnNPCKilled", "DeathHandler", function (npc,attacker,inflictor)
  --print(attacker:GetClass(), inflictor:GetClass()) --debug print
  if npc:GetClass() == "npc_metropolice" then
    Cops_count = Cops_count-1

    -- angry section
    -- send angry style bonus to the client that killed a metrocop if they have 20 or less hp and alive
    if attacker:IsPlayer() and attacker:Health() <= 20 and attacker:Alive() then
      net.Start("Connection")
      net.WriteUInt(Events.ANGRY, Net_int_size)
      net.Send(attacker)
    -- send schroedinger's style bonus if the client killed a metrocop while it was dead
    elseif attacker:IsPlayer() and not attacker:Alive() then
      net.Start("Connection")
      net.WriteUInt(Events.AFTERDEATH, Net_int_size)
      net.Send(attacker)
    end

    -- weapon section
    -- select one style bonus depending on what was used to kill
    -- default to +KILL
    if inflictor:GetClass() == "weapon_crowbar" then
      if attacker:IsPlayer() then
        net.Start("Connection")
        net.WriteUInt(Events.HL3CONFIRMED, Net_int_size)
        net.Send(attacker)
      end
    elseif inflictor:GetClass() == "npc_grenade_frag" then
      if attacker:IsPlayer() then
        net.Start("Connection")
        net.WriteUInt(Events.EXPLOSION, Net_int_size)
        net.Send(attacker)
      end
    elseif attacker:GetClass() == "prop_ragdoll" then
      net.Start("Connection")
      net.WriteUInt(Events.RAGDOLL, Net_int_size)
      net.Broadcast()
    elseif inflictor:GetClass() == "weapon_physgun" then
      if attacker:IsPlayer() then
        net.Start("Connection")
        net.WriteUInt(Events.PROPPHYS, Net_int_size)
        net.Send(attacker)
      end
    elseif inflictor:GetClass() == "weapon_357" and npc:GetActiveWeapon():GetClass() == "weapon_357" then
      local dist = Distance(attacker,npc)
      if dist < 480 and dist > 160  then
        if attacker:IsPlayer() then
          net.Start("Connection")
          net.WriteUInt(Events.WILDWEST, Net_int_size)
          net.Send(attacker)
        end
      else --this section is janky but i haven't come up with any other way to handle this, otherwise it doesn't send a signal at all.
        if attacker:IsPlayer() then
          net.Start("Connection")
          net.WriteUInt(Events.KILL, Net_int_size)
          net.Send(attacker)
        end
      end
    elseif attacker:IsPlayer() then
      net.Start("Connection")
      net.WriteUInt(Events.KILL, Net_int_size)
      net.Send(attacker)
    end

    --distance section
    --send Events.CLOSEKILL if distance < 80 h units (2m) and the weapon isn't crowbar
    --send Events.FARKILL if distance > 480 h units (12m) and the weapon isn't greande
    --send only if a player killed a cop
    if attacker:IsPlayer() then
      if Distance(attacker, npc) < 80 and inflictor:GetClass() != "weapon_crowbar" then
        net.Start("Connection")
        net.WriteUInt(Events.CLOSEKILL, Net_int_size)
        net.Send(attacker)
      elseif Distance(attacker,npc) > 480 and inflictor:GetClass() != "npc_grenade_frag" then 
        net.Start("Connection")
        net.WriteUInt(Events.FARKILL, Net_int_size)
        net.Send(attacker)
      end
    end

    -- friendly fire section
    -- send to all clients "+FRIENDLY FIRE" style bonus if a metrocop was killed by another metrocop
    if attacker:GetClass() == "npc_metropolice" then
      net.Start("Connection")
      net.WriteUInt(Events.FRIENDLYFIRE, Net_int_size)
      net.Broadcast()
    end
  end
end)

-- Player death handling
hook.Add("PlayerDeath", "PlayerDeathHandler", function(victim,inflictor,attacker)
  --print(victim:GetClass(),inflictor:GetClass(),attacker:GetClass())
  if attacker:IsPlayer() then 
    if attacker != victim then
      net.Start("Connection")
      net.WriteUInt(Events.BETRAYAL, Net_int_size)
      net.Send(attacker)
    else
      net.Start("Connection")
      net.WriteUInt(Events.SUICIDE, Net_int_size)
      net.Send(attacker)
    end
  end
  if attacker:GetClass() == "worldspawn" then
    net.Start("Connection")
    net.WriteUInt(Events.WORLDSPAWN, Net_int_size)
    net.Send(victim)
  end
end)
