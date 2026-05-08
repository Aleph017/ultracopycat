include("autorun/magic_stuff.lua")

function ProbeNavmesh()
  local area = navmesh.GetAllNavAreas()
  if (#area < 1) then
    return Statuscode.NAVMESH
  else
    return Statuscode.SUCCESS
  end
end
