include("autorun/magic_stuff.lua")

function ProbeNavmesh()
  local areas = navmesh.GetNavAreaCount()
  if ( areas > 0) then
    return Statuscode.SUCCESS
  else
    return Statuscode.NAVMESH
  end
end
