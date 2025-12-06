include("autorun/magic_stuff.lua")

util.AddNetworkString("Connection")
util.AddNetworkString("ScoreConnection")
Player_table = player.GetAll()
Weapons = {"weapon_pistol", "weapon_smg1", "weapon_shotgun", "weapon_357"} --cops weapon pool
Score = {}
Best_session_score = {}
Cops_count = 0
Cops_cap = 25

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

function ScoreUpdate(ply, points)
  if Score[ply:UserID()] then
    Score[ply:UserID()] = Score[ply:UserID()] + points
  end 
end

Handlers = {
  ["weapon_crowbar"] = function(npc,attacker,inflictor)
    local broadcast = false 
    if attacker:IsPlayer() then 
      return Events.HL3CONFIRMED, broadcast
    end
  end,
  ["npc_grenade_frag"] = function(npc,attacker,inflictor)
    local broadcast = false 
    if attacker:IsPlayer() then 
      return Events.EXPLOSION, broadcast
    end
  end,
  ["prop_ragdoll"] = function(npc,attacker,inflictor)
    local broadcast = true 
    return Events.RAGDOLL, broadcast
  end,
  ["weapon_357"] = function(npc,attacker,inflictor)
    local broadcast = false 
    local dist = Distance(npc,attacker)
    local npc_wep = npc:GetActiveWeapon():GetClass()
    if dist < 480 and dist > 160 and npc_wep == "weapon_357" then
      return Events.WILDWEST, broadcast 
    else 
      return Events.KILL, broadcast
    end
  end
}

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
      if DEBUG then print("Updating the chase...") end
      local cops = ents.FindByClass("npc_metropolice")
      if next(cops) == nil then
        if DEBUG then print("All cops are dead, stopped updating the chase.") end
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
  Player_table = player.GetAll()
  local areas = navmesh.GetAllNavAreas()
  if not timer.Exists("Spawner") then
    SpawnCops(areas)
    timer.Create("Spawner", 10, 0, function()
      SpawnCops(areas)
    end)
  end
end

hook.Add("PlayerInitialSpawn", "UpdateTheList", function()
  Player_table = player.GetAll()
  for i, ply in pairs(Player_table) do
    ply:ChatPrint("A new bastard has connected")
    if not Score[ply:UserID()] then
      Score[ply:UserID()] = 0
    end
  end
end)

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
  if Score[ply:UserID()] then
    net.Start("ScoreConnection")
    net.WriteInt(Score[ply:UserID()], Net_score_size)
    net.Send(ply)
    Score[ply:UserID()] = 0
    if DEBUG then 
      print("Sent stuff(" .. Score[ply:UserID()] .. ") to player " .. ply:UserID()) 
    end
  end
end)

hook.Add("OnNPCKilled", "DeathHandler", function (npc,attacker,inflictor)
  --print(attacker:GetClass(), inflictor:GetClass()) --debug print
  if npc:GetClass() == "npc_metropolice" then
    Cops_count = Cops_count-1

    -- angry section
    -- send angry style bonus to the client that killed a metrocop if they have 20 or less hp and alive
    if attacker:IsPlayer() and attacker:Health() <= 20 and attacker:Alive() then
      ScoreUpdate(attacker, Values[Events.ANGRY])
      net.Start("Connection")
      net.WriteUInt(Events.ANGRY, Net_int_size)
      net.Send(attacker)
    -- send schroedinger's style bonus if the client killed a metrocop while it was dead
    elseif attacker:IsPlayer() and not attacker:Alive() then
      ScoreUpdate(attacker, Values[Events.AFTERDEATH])
      net.Start("Connection")
      net.WriteUInt(Events.AFTERDEATH, Net_int_size)
      net.Send(attacker)
    end

    -- weapon section
    -- select one style bonus depending on what was used to kill
    -- default to +KILL
    local weapon_class = inflictor:GetClass()
    local handler = Handlers[weapon_class]
    if handler then
      local event, broadcast = handler(npc,attacker,inflictor)
      if event and attacker:IsPlayer() then
        if broadcast then
          for i, ply in pairs(Player_table) do
            ScoreUpdate(ply, Values[event])
          end
        else
          if attacker:IsPlayer() then --one little verbose if statement is never too bad 
            ScoreUpdate(attacker, Values[event])
          end
        end
        net.Start("Connection")
        net.WriteUInt(event, Net_int_size)
        if broadcast then 
          net.Broadcast() 
        else 
          net.Send(attacker) 
        end
      end
    -- if no weapon specific handler found default to +KILL
    elseif attacker:IsPlayer() then 
      ScoreUpdate(attacker, Values[Events.KILL])
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
        ScoreUpdate(attacker, Values[Events.CLOSEKILL])
        net.Start("Connection")
        net.WriteUInt(Events.CLOSEKILL, Net_int_size)
        net.Send(attacker)
      elseif Distance(attacker,npc) > 480 and inflictor:GetClass() != "npc_grenade_frag" then 
        ScoreUpdate(attacker, Values[Events.FARKILL])
        net.Start("Connection")
        net.WriteUInt(Events.FARKILL, Net_int_size)
        net.Send(attacker)
      end
    end

    -- friendly fire section
    -- send to all clients "+FRIENDLY FIRE" style bonus if a metrocop was killed by another metrocop
    if attacker:GetClass() == "npc_metropolice" then
      for i, ply in pairs(Player_table) do
        ScoreUpdate(ply, Values[Events.FRIENDLYFIRE])
      end
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
      ScoreUpdate(attacker, Values[Events.BETRAYAL])
      net.Start("Connection")
      net.WriteUInt(Events.BETRAYAL, Net_int_size)
      net.Send(attacker)
    else
      ScoreUpdate(attacker, Values[Events.SUICIDE])
      net.Start("Connection")
      net.WriteUInt(Events.SUICIDE, Net_int_size)
      net.Send(attacker)
    end
  end
  if attacker:GetClass() == "worldspawn" then
    ScoreUpdate(victim, Values[Events.WORLDSPAWN])
    net.Start("Connection")
    net.WriteUInt(Events.WORLDSPAWN, Net_int_size)
    net.Send(victim)
  end
end)
