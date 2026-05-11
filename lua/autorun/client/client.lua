include("autorun/magic_stuff.lua")

First_time = true
Navmesh_status = Statuscode.SUCCESS

--chat.AddText(Color(255,255,255), "Hello, World!")

Messages = {
  ["vim"] = true,
  [":wq"] = true,
  [":qa!"] = true,
  [":%d"] = true,
  [":score"] = true
}

function RequestNavmeshStatus()
  net.Start("RequestConnection")
  net.WriteUInt(Requests.NAVMESH, Net_request_size)
  net.SendToServer()

end

net.Receive("ErrorConnection", function(length) 
  Navmesh_status = net.ReadInt(Net_uccerr_size)
end)

function RequestScoreboard()
  net.Start("RequestConnection")
  net.WriteUInt(Requests.SCORE, Net_request_size)
  net.SendToServer()
end


net.Receive("BoardConnection", function(length)
  local data = net.ReadTable()
  local scoreboard = {}
  for i, v in pairs(data) do
    if(not IsValid(Player(i))) then continue end
    local entry = {plyid = i, scr = v}
    table.insert(scoreboard, entry)
  end
  table.sort(scoreboard, function(a,b) return a.scr > b.scr end)
  --print("---SCOREBOARD---")
  timer.Simple(0, function() 
    chat.AddText(Color(0xff,0xff,0xff), "---SCOREBOARD---")
    for i, v in ipairs(scoreboard) do
      chat.AddText(Color(0xff,0xff,0xff), string.format("%-12s %d",Player(v.plyid):Nick(),v.scr))
    end
  end)
end)

function ViolenceQuote()
  chat.AddText(
    Color(255, 255, 255), "THE WORLD IS YOUR BUFFER\nSO TAKE UP YOUR ", 
    Color(255,128,0), "CROWBAR\n",
    Color(255,255,255),"AND PAINT\nTHE WORLD\n",
    Color(255,10,10), "0 x F F 0 0 0 0"
  )
end

function InitialErrorMsg()
  chat.AddText(
    Color(255,255,255), "ULTRACOPYCAT couldn't find a navmesh for the map.\n",
    "It means that the addon won't work. Try generating the mesh if you will,\n",
    "or try another map."
  )
end


hook.Add("OnPlayerChat","QuoteViolence", function(ply, text)
  if string.lower(text) == Magic_word then
    if ( First_time or DEBUG) then
      RequestNavmeshStatus()
      print(Navmesh_status)
      timer.Simple(0.125, function ()
        if (Navmesh_status == Statuscode.SUCCESS) then 
          ViolenceQuote()
        else
          InitialErrorMsg()
        end
        First_time = false
      end)
    else
      timer.Simple(0, function()
        if (Navmesh_status == Statuscode.SUCCESS) then 
          chat.AddText(Color(255,10,10), "H A V E  F U N .")
        else 
          chat.AddText(Color(0xff,0xff,0xff), Navmesh_not_found_msg)
        end
      end)
    end
  elseif text == Stop_word then
    timer.Simple(0, function()
      if (Navmesh_status == Statuscode.SUCCESS) then
        chat.AddText(Color(255,10,10), "I  W I L L  B E  W A I T I N G .")
      else
        return 
      end
    end)
  elseif text == Force_exit_word then
    timer.Simple(0, function()
      if (Navmesh_status == Statuscode.SUCCESS) then 
        chat.AddText(Color(255,10,10), "D I S A P P O I N T I N G .")
      else 
        return
      end
    end)
  elseif text == Cleanup_word then 
    timer.Simple(0, function()
      if (Navmesh_status == Statuscode.SUCCESS) then
        chat.AddText(Color(0xff,0xa,0xa), "A V E R A G E  L O A D  T O O  H I G H ?")
      end
    end)
  elseif text == Score_word then
    RequestScoreboard()
  end
end)

Colors = {
  WHITE = Color(255,255,255),
  GREEN = Color(37,255,73),
  ORANGE = Color(255,128,0),
  RED = Color(255,0,0),
  PURPLE = Color(166,0,255),
  BLUE = Color(0,162,255)
}

Styles = {
  [Events.KILL] = {clr = Colors.WHITE, str = "+KILL"}, --kill a cop
  [Events.EXPLOSION] = { clr = Colors.WHITE, str = "+FIREWORKS"}, --kill a cop with a grenade
  [Events.FRIENDLYFIRE] = {clr = Colors.GREEN, str = "+FRIENDLYFIRE"}, --witness a cop kill a cop
  [Events.HL3CONFIRMED] = {clr = Colors.ORANGE, str = "+HL3 CONFIRMED"}, --kill a cop with the crowbar
  [Events.RAGDOLL] = {clr = Colors.GREEN, str = "+SMELLS LIKE VERDUN"}, --witness a cop be killed by a ragdoll
  [Events.ANGRY] = {clr = Colors.RED, str = "+TOO ANGRY TO DIE"}, --kill while hp <= 20 and alive
  [Events.WORLDSPAWN] = {clr = Colors.PURPLE, str = "-MR. NEWTON SENDS HIS REGARDS"}, --die to fall damage
  [Events.BETRAYAL] = {clr = Colors.PURPLE, str = "+BETRAYAL"}, --kill a player
  [Events.AFTERDEATH] = {clr = Colors.RED, str = "+SCHRÖDINGER'S KILL"}, --kill a cop while dead
  [Events.CLOSEKILL] = {clr = Colors.BLUE, str = "+BETTER SAFE THAN SORRY"}, --kill at distance < 2m not with the crowbar
  [Events.FARKILL] = {clr = Colors.BLUE, str = "+SHARPSHOOTER"}, --kill at distance > 12m not with a grenade
  [Events.WILDWEST] = {clr = Colors.BLUE, str = "+THE WILD WEST"}, --kill a cop wielding a revolver with a revolver at a distance
  [Events.SUICIDE] = {clr = Colors.PURPLE, str = "-STOP HITTING YOURSELF"}, --kys
  [Events.COMBINEBALL] = {clr = Colors.WHITE, str = "+BIG BANG THEORY"}, --kill a cop with a combine ball
  [Events.ANTLION] = {clr = Colors.BLUE, str = "+PEST CONTROL"}, --kill an antlion guard
  [Events.COIN] = {clr = Colors.WHITE, str = "+CAPITALISM"} --kill a cop with a coin /// requires "ULTRAKILL Coin Mechanics" addon
}

net.Receive("Connection", function(length)
  local event = net.ReadUInt(Net_int_size)
  if Styles[event] then
    local style = Styles[event]
    chat.AddText(style.clr, style.str)
  else
    chat.AddText(Colors.PURPLE, "what?")
  end
end)

net.Receive("ScoreConnection", function(length)
  local score = net.ReadInt(Net_score_size)
  if DEBUG then print(score) end
  chat.AddText(Colors.WHITE, "Your score: " .. score)
end)