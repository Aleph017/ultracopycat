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

Colors = {
  WHITE = Color(255,255,255),
  GREEN = Color(37,255,73),
  ORANGE = Color(255,128,0),
  RED = Color(255,0,0),
  PURPLE = Color(166,0,255),
  BLUE = Color(0,162,255)
}

Styles = {
  [Events.KILL] = {clr = Colors.WHITE, str = "+KILL"},
  [Events.EXPLOSION] = { clr = Colors.WHITE, str = "+FIREWORKS"},
  [Events.FRIENDLYFIRE] = {clr = Colors.GREEN, str = "+FRIENDLYFIRE"},
  [Events.HL3CONFIRMED] = {clr = Colors.ORANGE, str = "+HL3 CONFIRMED"},
  [Events.RAGDOLL] = {clr = Colors.GREEN, str = "+SMELLS LIKE VERDUN"},
  [Events.ANGRY] = {clr = Colors.RED, str = "+TOO ANGRY TO DIE"},
  [Events.WORLDSPAWN] = {clr = Colors.PURPLE, str = "-MR. NEWTON SENDS HIS REGARDS"},
  [Events.BETRAYAL] = {clr = Colors.PURPLE, str = "+BETRAYAL"},
  [Events.AFTERDEATH] = {clr = Colors.RED, str = "+SCHRÖDINGER'S KILL"},
  [Events.CLOSEKILL] = {clr = Colors.BLUE, str = "+BETTER SAFE THAN SORRY"},
  [Events.FARKILL] = {clr = Colors.BLUE, str = "+SHARPSHOOTER"},
  [Events.WILDWEST] = {clr = Colors.BLUE, str = "+THE WILD WEST"},
  [Events.SUICIDE] = {clr = Colors.PURPLE, str = "-STOP HITTING YOURSELF"}
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