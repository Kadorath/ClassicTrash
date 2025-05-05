import "scripts/incinerator"

conveyor = {}

local gfx <const> = playdate.graphics

local depot = {}

local speed = 60
local capacity = 4
local belt = {}
for i=1, capacity, 1 do
    table.insert(belt, -1)
end

local selection = 1

local beltX = 32
local beltY = 72

local needsDisplay = true

local elapsedFrames = 0
function conveyor.update()
    if needsDisplay then
        for i,trash in ipairs(belt) do
            if trash ~= -1 then
                trash:moveTo(beltX, beltY + i*32)
            end
        end
        needsDisplay = false
    end

    elapsedFrames += 1
    if #depot > 0 and elapsedFrames >= speed then
        conveyor.AddToBelt(table.remove(depot))
        elapsedFrames = 0
    end
end

function conveyor.AddToDepot(trash)
    table.insert(depot, 1, trash)
end

function conveyor.AddToBelt(trash, idx)
    idx = idx or 1
    local oldItem = trash
    for i,v in ipairs(belt) do
        belt[i] = oldItem
        oldItem = v
        if oldItem == -1 then
            break
        end
    end

    belt[1] = trash
    trash:add()
    trash:moveTo(-100,-100)
    trash:setZIndex(0)
    trash:setScale(0.5)
    if oldItem ~= -1 then
        incinerator.AddToIncinerator(oldItem)
    end

    needsDisplay = true
end

function conveyor.TakeFromBelt()
    local selectedTrash = nil
    if belt[selection] ~= -1 then
        selectedTrash = belt[selection]
        selectedTrash:setScale(1)
        selectedTrash:setCenter(selectedTrash.center[1], selectedTrash.center[2])
        belt[selection] = -1
        needsDisplay = true
    end

    return selectedTrash
end

function conveyor.UpdateSelection(d)
    selection += d
    selection = math.max(math.min(selection, capacity), 1)
    needsDisplay = true

    return beltX, beltY + (selection-1)*32 + 18
end

function conveyor.SetSelection(s)
    selection = math.max(math.min(s, capacity), 1)
    needsDisplay = true

    return beltX, beltY + (selection-1)*32 + 18
end

function conveyor.GetSelection()
    return selection
end