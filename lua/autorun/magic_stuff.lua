DEBUG = false 
Net_int_size = 4
Net_score_size = 18
Net_uccerr_size = 4
Net_request_size = 4
Magic_word = "vim"
Stop_word = ":wq"
Force_exit_word = ":qa!"
Cleanup_word = ":%d"
Navmesh_not_found_msg = "Navmesh not found, aborting."
Events = {
  KILL = 0,
  FRIENDLYFIRE = 1,
  EXPLOSION = 2,
  HL3CONFIRMED = 3,
  RAGDOLL = 4,
  ANGRY = 5,
  PROPPHYS = 6,
  BETRAYAL = 7,
  WORLDSPAWN = 8,
  AFTERDEATH = 9,
  CLOSEKILL = 10,
  FARKILL = 11,
  WILDWEST = 12,
  SUICIDE = 13,
  COMBINEBALL = 14,
  ANTLION = 15
}

Values = {
  [Events.KILL] = 100,
  [Events.FRIENDLYFIRE] = 75,
  [Events.EXPLOSION] = 100,
  [Events.HL3CONFIRMED] = 333,
  [Events.RAGDOLL] = 75,
  [Events.ANGRY] = 125,
  [Events.PROPPHYS] = nil,
  [Events.BETRAYAL] = 125,
  [Events.WORLDSPAWN] = -200,
  [Events.AFTERDEATH] = 110,
  [Events.CLOSEKILL] = 125,
  [Events.FARKILL] = 225,
  [Events.WILDWEST] = 250,
  [Events.SUICIDE] = -50,
  [Events.COMBINEBALL] = 90,
  [Events.ANTLION] = 500
}

Requests = {
  NAVMESH = 1
}

Statuscode = {
  SUCCESS = 0,
  NAVMESH = -1
}