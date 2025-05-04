import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/math"
import "CoreLibs/crank"

import "scripts/player"
import "scripts/conveyor"
import "scripts/store"
import "scripts/trash"

local gfx <const> = playdate.graphics
local trashdata <const> = assert(json.decodeFile("data/trashdata.json"))
local trashIDs = {}
for id,_ in pairs(trashdata) do
    table.insert(trashIDs, id)
end

function playdate.update()
    gfx.sprite.update()
    player.update()
    conveyor.update()
    store.update()
    incinerator.update()

    playdate.timer.updateTimers()
end

local ct = 1
function Dump()
    local rTrash = trashdata[trashIDs[ct]]
    local name = trashIDs[ct]
    ct += 1
    if ct > #trashIDs then ct = 1 end
    local newTrash = Trash(name, rTrash)
    conveyor.AddToBelt(newTrash)
    playdate.timer.performAfterDelay(3000, Dump)
end

playdate.timer.performAfterDelay(1000, Dump)
