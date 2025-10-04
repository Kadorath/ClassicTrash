import "scripts/incinerator"

conveyor = {}

local gfx <const> = playdate.graphics

local depot = {}

local speed = 60
local capacity = 4
local onBelt = 0
local belt = {}
local oldBelt = {}
for i=1, capacity, 1 do
    table.insert(belt, -1)
    table.insert(oldBelt, -1)
end

local toIncineratorItem = nil

local selection = 1
local lagTime = 10

local beltX = 26
local beltY = 56

local needsDisplay = true

local elapsedFrames = 0
function conveyor.update()
    for i,trash in ipairs(belt) do
        if trash ~= -1 then
            trash:UpdateBeltPosition()
        end
    end
    if toIncineratorItem then
        if toIncineratorItem:UpdateBeltPosition() then
            -- if not incinerator.IsFull() and elapsedFrames > lagTime then
            --     incinerator.AddToIncinerator(toIncineratorItem)
            --     toIncineratorItem = nil
            -- end
            local r,c,x,y = store.GetAvailableSpace(toIncineratorItem)
            if r ~= nil then
                print("found available space")
                store.ReserveSpace(toIncineratorItem, 1, r, c)
                toIncineratorItem:setStoreTarget(r,c)
                toIncineratorItem:setZIndex(4)
                store.DropIntoStore(toIncineratorItem,x,y)
                toIncineratorItem = nil
            end
        end
    end

    elapsedFrames += 1
    if #depot > 0 and elapsedFrames >= speed and 
        (toIncineratorItem == nil or onBelt < capacity-1) then
        conveyor.AddToBelt(table.remove(depot))
        elapsedFrames = 0
    end
end

function conveyor.AddToDepot(trash)
    table.insert(depot, 1, trash)
end

function conveyor.AddToBelt(trash, idx)
    idx = idx or 1

    for i,v in ipairs(belt) do
        oldBelt[i] = v
    end

    trash:moveTo(beltX,0)
    trash:setZIndex(2)
    trash:setScale(0.5)
    trash:setRotation(math.random(1,360))

    local oldItem = trash
    for i,v in ipairs(belt) do
        oldItem:SetBeltPosition(beltX, beltY + i*32, 400)
        belt[i] = oldItem
        oldItem = v
        if oldItem == -1 then
            break
        end
    end

    trash:add()
    if oldItem ~= -1 then
        oldItem:SetBeltPosition(beltX, 262, 400)
        toIncineratorItem = oldItem
        onBelt -= 1
    end

    onBelt += 1
    needsDisplay = true
end

-- PRINT STATEMENT THAT MIGHT BE USEFUL LATER
-- local str = "\n"..targetBelt[selection].name.."\nOldBelt: "
-- for _,v in ipairs(oldBelt) do 
--     if v ~= -1 then
--         str = str..v.name.." : " 
--     else 
--         str = str.."nil : " 
--     end
-- end
-- str = str.."\nCurBelt: "
-- for _,v in ipairs(belt) do 
--     if v ~= -1 then
--         str = str..v.name.." : " 
--     else 
--         str = str.."nil : " 
--     end
-- end
-- print("swapping out from belt", str)
function conveyor.TakeFromBelt(trashToSwap)
    local selectedTrash = nil
    local lagAdjust = ((elapsedFrames < lagTime)) and 1 or 0
    if oldBelt[selection-lagAdjust] == -1 then 
        lagAdjust = 0 
    elseif oldBelt[selection] == -1 and belt[selection] ~= -1 and trashToSwap then 
        lagAdjust = 0 
    end
    local targetBelt = (lagAdjust == 1 and oldBelt) or belt

    if trashToSwap then
        trashToSwap:setScale(0.5)
        trashToSwap:setCenter(0.5,0.5)
        trashToSwap:setZIndex(2)
        trashToSwap:SetBeltPosition(beltX, beltY + (selection+lagAdjust)*32, 0)
        onBelt += 1 
    end

    if targetBelt[selection] ~= -1 then
        if selection+lagAdjust <= capacity then
            selectedTrash = belt[selection+lagAdjust]
            belt[selection+lagAdjust] = trashToSwap or -1
            selectedTrash:setScale(1)
            selectedTrash:setCenter(selectedTrash.center[1], selectedTrash.center[2])
        else
            selectedTrash = toIncineratorItem
            toIncineratorItem = trashToSwap

            if selectedTrash then
                selectedTrash:setScale(1)
                selectedTrash:setCenter(selectedTrash.center[1], selectedTrash.center[2])
            end
        end
        onBelt -= 1
    elseif trashToSwap then
        if selection+lagAdjust <= capacity then
            belt[selection+lagAdjust] = trashToSwap
        else
            if toIncineratorItem then
                selectedTrash = toIncineratorItem
            end
            toIncineratorItem = trashToSwap
        end
    end

    if lagAdjust == 1 then
        oldBelt[selection] = trashToSwap or -1
    end

    if onBelt == 0 and #depot > 0 then
        conveyor.AddToBelt(table.remove(depot))
        elapsedFrames = 0
    end

    return selectedTrash
end

function conveyor.UpdateSelection(d)
    selection += d
    selection = math.max(math.min(selection, capacity), 1)
    needsDisplay = true

    return beltX+16, beltY + (selection-1)*32+32
end

function conveyor.SetSelection(s)
    selection = math.max(math.min(s, capacity), 1)
    needsDisplay = true

    return beltX+16, beltY + (selection-1)*32+32
end

function conveyor.GetSelection()
    return selection
end