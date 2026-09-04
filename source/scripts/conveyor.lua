import "scripts/incinerator"
import "scripts/thetruck"

conveyor = {}

local gfx <const> = playdate.graphics

local depot = {}

-- 60
local elapsedFrames = 0
local speed = 60
local capacity = 4
local onBelt = 0
local belt = {}
local oldBelt = {}

local pushedOffBeltItem = nil
local dropTarget_R,dropTarget_C,dropTarget_X,dropTarget_Y

local selection = 1
local lagTime = 10

local beltX = 26
local beltY = 56

local needsDisplay = true

function conveyor.Init()
    depot = {}
    elapsedFrames = 0
    onBelt = 0
    belt = {}
    oldBelt = {}
    dropTarget_R,dropTarget_C,dropTarget_X,dropTarget_Y = nil
    pushedOffBeltItem = nil
    for i=1, capacity, 1 do
        table.insert(belt, -1)
        table.insert(oldBelt, -1)
    end

    truck.Init()

    conveyor.AddToBelt(table.remove(depot))
    conveyor.AddToBelt(table.remove(depot))
    conveyor.AddToBelt(table.remove(depot))

    -- Drop some initial trash into the store
    for i=1, 2, 1 do
        local startingTrash = table.remove(depot)
        if startingTrash == nil then break end

        dropTarget_R,dropTarget_C,dropTarget_X,dropTarget_Y = store.GetAvailableSpace(startingTrash, (i-1)*4 + 1, i*4 - 1)
        startingTrash:setStoreTarget(dropTarget_R, dropTarget_C)
        startingTrash:setZIndex(RenderLayer.BTRASH)
        startingTrash:add()
        store.ReserveSpace(startingTrash, 1, dropTarget_R, dropTarget_C)
        store.DropIntoStore(startingTrash, dropTarget_X, dropTarget_Y)
        dropTarget_R = nil
    end
end

function conveyor.update()
    for i,trash in ipairs(belt) do
        if trash ~= -1 then
            trash:UpdateBeltPosition()
        end
    end
    if pushedOffBeltItem ~= nil then
        if pushedOffBeltItem:UpdateBeltPosition() and dropTarget_R ~= nil then
            pushedOffBeltItem:setStoreTarget(dropTarget_R, dropTarget_C)
            pushedOffBeltItem:setZIndex(RenderLayer.BTRASH)
            store.DropIntoStore(pushedOffBeltItem, dropTarget_X, dropTarget_Y)
            pushedOffBeltItem = nil
            dropTarget_R = nil
        end
    end

    elapsedFrames += 1
    local difficultyAdjustedSpeed = speed - (math.min(35, 10*GetDifficultyLevel()))
    -- Every speed ticks elapsed, when there are items to push
    if #depot > 0 and elapsedFrames >= difficultyAdjustedSpeed then
        -- Belt is not full yet, push item onto belt
        if (onBelt < capacity) then
            print("CONVEYOR: Adding item to belt")
            conveyor.AddToBelt(table.remove(depot))
            elapsedFrames = 0
        elseif (onBelt == capacity and pushedOffBeltItem == nil) then
            print("CONVEYOR: Belt at capacity, trying to push off belt")
            dropTarget_R,dropTarget_C,dropTarget_X,dropTarget_Y = store.GetAvailableSpace(belt[capacity])
            if (dropTarget_R ~= nil and dropTarget_C ~= nil) then
                conveyor.AddToBelt(table.remove(depot))
                store.ReserveSpace(pushedOffBeltItem, 1, dropTarget_R, dropTarget_C)
                elapsedFrames = 0
            else
                -- Rechecks slightly more often. Perhaps make this just check immediately when
                -- an item is removed from the store?
                elapsedFrames = 45
            end
        end
    end

    if #depot == 0 then
        truck.Dump()
    end
end

function conveyor.AddToDepot(trash)
    table.insert(depot, 1, trash)
end

-- Add a new item onto the conveyor belt
function conveyor.AddToBelt(trash)
    -- Store the belt before the new trash is added in oldBelt
    for i,v in ipairs(belt) do
        oldBelt[i] = v
    end

    -- Position trash sprite
    trash:moveTo(beltX,0)
    trash:setZIndex(RenderLayer.BTRASH)
    trash:setScale(0.5)
    trash:setRotation(math.random(1,360))

    -- Each item on the belt advances one belt slot forward, starting with 
    -- the trash being added.
    local oldItem = trash
    for i,v in ipairs(belt) do
        oldItem:SetBeltPosition(beltX, beltY + i*32, 400)
        belt[i] = oldItem
        oldItem = v
        -- If the next item on the belt is an empty space (-1), stop pushing trash forward
        if oldItem == -1 then
            break
        end
    end

    -- Now that trash has its positions set, add to sprite render list
    trash:add()

    -- If we've pushed all trash that should be pushed forward, and we still have an
    -- item stored in oldItem, then oldItem should be pushed off of the belt.
    if oldItem ~= -1 then
        oldItem:SetBeltPosition(beltX, 262, 400)
        pushedOffBeltItem = oldItem
        onBelt -= 1
    end

    -- Item has been added to belt, track accordingly
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
        trashToSwap:setZIndex(RenderLayer.HTRASH)
        trashToSwap:SetBeltPosition(beltX, beltY + (selection+lagAdjust)*32, 0)
        onBelt += 1 
    end

    if targetBelt[selection] ~= -1 then
        if selection+lagAdjust <= capacity then
            selectedTrash = belt[selection+lagAdjust]
            if (selectedTrash == nil) then
                print("ERROR: selectedTrash was nil at line 167")
                return nil
            end
            belt[selection+lagAdjust] = trashToSwap or -1
            selectedTrash:setScale(1)
            selectedTrash:setCenter(selectedTrash.center[1], selectedTrash.center[2])
            onBelt -= 1
        else
            selectedTrash = pushedOffBeltItem
            pushedOffBeltItem = trashToSwap
            dropTarget_R = nil
            if selectedTrash then
                selectedTrash:setScale(1)
                selectedTrash:setCenter(selectedTrash.center[1], selectedTrash.center[2])
                store.UnreserveSpace(selectedTrash)
            end
        end
    elseif trashToSwap then
        if selection+lagAdjust <= capacity then
            belt[selection+lagAdjust] = trashToSwap
        else
            if pushedOffBeltItem then
                selectedTrash = pushedOffBeltItem
            end
            pushedOffBeltItem = trashToSwap
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