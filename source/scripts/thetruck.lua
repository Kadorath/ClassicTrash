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
    truck.Dump()
end

function truck.Dump()
    local trashBag = {}
    for _,id in pairs(trashIDs) do
        local trash = trashdata[id]
        for i=1, trash.bagCount, 1 do
            local newTrash = Trash(id, trash)
            table.insert(trashBag, newTrash)
        end
    end

    while #trashBag > 0 do
        local idx = math.random(1, #trashBag)
        conveyor.AddToDepot(trashBag[idx])
        table.remove(trashBag, idx)
    end
end