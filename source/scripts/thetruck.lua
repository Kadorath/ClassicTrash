import "scripts/trash"
import "scripts/conveyor"

truck = {}

truckTimer = nil

local gfx <const> = playdate.graphics
local trashdata <const> = assert(json.decodeFile("data/trashdata.json"))
local trashIDs = {}
for id,_ in pairs(trashdata) do
    table.insert(trashIDs, id)
end

function truck.Init()
    truckTimer = playdate.timer.performAfterDelay(1, truck.Dump)
end

function truck.Dump()
    local tName = trashIDs[math.random(#trashIDs)]

    local rTrash = trashdata[tName]
    local newTrash = Trash(tName, rTrash)
    conveyor.AddToDepot(newTrash)
    truckTimer = playdate.timer.performAfterDelay(1000, truck.Dump)
end