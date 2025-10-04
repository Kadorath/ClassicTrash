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

truck.cRequests = {}

function truck.Init()
    truckTimer = playdate.timer.performAfterDelay(1, truck.Dump)
end

function truck.Dump()
    local tName = trashIDs[1]
    if #truck.cRequests > 0 and math.random() < 0.75 then
        tName = truck.cRequests[math.random(#truck.cRequests)]
    else
        tName = trashIDs[math.random(#trashIDs)]
    end
    tName = "fishbones"
    if math.random() < 0.75 then tName = "cottoncandy" end

    local rTrash = trashdata[tName]
    local newTrash = Trash(tName, rTrash)
    conveyor.AddToDepot(newTrash)
    truckTimer = playdate.timer.performAfterDelay(1000, truck.Dump)
end