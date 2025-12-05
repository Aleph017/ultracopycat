include("autorun/magic_stuff.lua")

First_time = true

--chat.AddText(Color(255,255,255), "Hello, World!")

function ViolenceQuote()
  chat.AddText(
    Color(255, 255, 255), "THE WORLD IS YOUR BUFFER\nSO TAKE UP YOUR ", 
    Color(255,128,0), "CROWBAR\n",
    Color(255,255,255),"AND PAINT\nTHE WORLD\n",
    Color(255,10,10), "0 x F F 0 0 0 0"
  )
end

hook.Add("OnPlayerChat","QuoteViolence", function(ply, text)
  if string.lower(text) == Magic_word then
    if First_time then
      timer.Simple(0, function ()
        ViolenceQuote()
        First_time = false
      end)
    else
      timer.Simple(0, function()
        chat.AddText(Color(255,10,10), "H A V E  F U N .")
      end)
    end
  elseif text == Stop_word then
    timer.Simple(0, function()
      chat.AddText(Color(255,10,10), "I  W I L L  B E  W A I T I N G .")
    end)
  elseif text == Force_exit_word then
    timer.Simple(0, function()
      chat.AddText(Color(255,10,10), "D I S A P P O I N T I N G .")
    end)
  end
end)

net.Receive("Connection", function(length)
  local event = net.ReadUInt(Net_int_size)
  if event == Events.KILL then
    chat.AddText(Color(255,255,255), "+KILL") --ordinary cop kill
  elseif event == Events.FRIENDLYFIRE then
    chat.AddText(Color(37,255,73), "+FRIENDLY FIRE") --a cop kills a cop
  elseif event == Events.HL3CONFIRMED then
    chat.AddText(Color(255,128,0), "+HL3 CONFIRMED") --kill a cop with a crowbar
  elseif event == Events.EXPLOSION then
    chat.AddText(Color(255,255,255), "+FIREWORKS") --kill a cop with a grenade
  elseif event == Events.RAGDOLL then
    chat.AddText(Color(37,255,73), "+SMELLS LIKE VERDUN") --a cops is killed with by a ragdoll / possible only if "Keep Corpses" is checked
  elseif event == Events.ANGRY then
    chat.AddText(Color(255,0,0), "+TOO ANGRY TO DIE") --kill a cop while ur hp <= 20
  elseif event == Events.WORLDSPAWN then
    chat.AddText(Color(166,0,255), "-MR. NEWTON SENDS HIS REGARDS") --die due to fall damage
  elseif event == Events.BETRAYAL then
    chat.AddText(Color(166,0,255), "+BETRAYAL") --kill another player
  elseif event == Events.AFTERDEATH then
    chat.AddText(Color(255,0,0), "+SCHRÖDINGER'S KILL") --kill a cop while being dead
  elseif event == Events.CLOSEKILL then
    chat.AddText(Color(0,162,255), "+BETTER SAFE THAN SORRY") --kill a cop within 2m
  elseif event == Events.FARKILL then
    chat.AddText(Color(0,162,255), "+SHARPSHOOTER") --kill a cop at least 12m away
  elseif event == Events.WILDWEST then
    chat.AddText(Color(0,162,255), "+THE WILD WEST") --kill a cop that uses a revolver with revolver while 4m < distance < 12m
  elseif event == Events.SUICIDE then
    chat.AddText(Color(166,0,255), "-STOP HITTING YOURSELF")
  end
end)