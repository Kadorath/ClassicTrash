import "CoreLibs/ui"
import "CoreLibs/nineslice"

import "scripts/cQueue"
import "scripts/request"

import "main"

store = {}

local gfx <const> = playdate.graphics

-- Store grid and item map
local itemMap = {}
local trashInStore = {}
local fallingTrash = {}
local fallingOffBoard = {}
local goals = {}
local timeSinceLastGoal = 0

store.rows = 4
store.columns = 8
local storeX, storeY = 64,81
local storeGrid = playdate.ui.gridview.new(32,32)
storeGrid:setNumberOfColumns(store.columns)
storeGrid:setNumberOfRowsInSection(1,store.rows)
storeGrid:setSelection(0,0,0)

local storeFXImg = gfx.image.new(400, 240)
local storeFXSpr = gfx.sprite.new(storeFXImg)
storeFXSpr:setCenter(0,0)
storeFXSpr:moveTo(0,0)
storeFXSpr:setZIndex(RenderLayer.STRASH)

function storeGrid:drawCell(section, row, column, selected, x, y, width, height)
    -- Draw borders around the goal shape
    gfx.setLineWidth(2)
    local m = storeGrid:getNumberOfColumns()
    local ind = (row-1)*m + column
    for _,goal in pairs(goals) do
        local goalMap = goal.map
        if goalMap[ind] == 1 then
            gfx.setDitherPattern(0.8, gfx.image.kDitherTypeDiagonalLine)
            gfx.fillRect(x,y,width,height)
            
            gfx.setColor(gfx.kColorBlack)
            -- Right
            if ind+1 <= #goalMap and goalMap[ind+1] == 0 then
                gfx.drawLine(x+width, y, x+width, y+height)
            end
            -- Left
            if ind-1 > 0 and goalMap[ind-1] == 0 then
                gfx.drawLine(x, y, x, y+height)
            end
            -- Down
            if ind+m <= #goalMap and goalMap[ind+m] == 0 then
                gfx.drawLine(x, y+height, x+width, y+height)
            end
            -- Up
            if ind-m > 0 and goalMap[ind-m] == 0 then
                gfx.drawLine(x, y, x+width, y)
            end
        end
    end

    if itemMap[ind] < 0 then
        gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer8x8)
        gfx.fillCircleAtPoint(x+width/2, y+height/2, 12)
    end

    -- Divide the entire store into a grid
    -- if itemMap[(row-1)*8 + column] == 0 then
    --     gfx.drawRect(x,y,width,height)
    -- else
    --     gfx.fillRect(x,y,width,height)
    -- end
end

function CreateRandomStoreGoal(size)
    local newGoal
    if size == nil then
        if (GetDifficultyLevel() >= 1 and math.random() < 0.25) then
            newGoal = Request(3)
            table.insert(goals, newGoal)
        else
            if (math.random() < 0.5) then
                newGoal = Request(2, 1, 4, 1, 4)
                table.insert(goals, newGoal)
            else
                newGoal = Request(1, 1, 4, 1, 2)
                table.insert(goals, newGoal)
                newGoal = Request(1, 1, 4, 3, 4)
                table.insert(goals, newGoal)
            end

            if (math.random() < 0.5) then
                newGoal = Request(2, 5, 8, 1, 4)
                table.insert(goals, newGoal)
            else
                newGoal = Request(1, 5, 8, 1, 2)
                table.insert(goals, newGoal)
                newGoal = Request(1, 5, 8, 3, 4)
                table.insert(goals, newGoal)
            end
        end
    else
        local goalMap = {}
        for i=1,store.columns,1 do
            for j=1,store.rows,1 do
                table.insert(goalMap, 0)
            end
        end
        for _,g in pairs(goals) do
            for i=1,#goalMap,1 do
                if g.map[i] == 1 then
                    goalMap[i] = 1
                end
            end
        end
        
        local minX, maxX, minY, maxY = nil, nil, nil, nil
        local largestN = 0
        local squareEndingAt = {}
        for i=1,store.rows,1 do
            for j=1,store.columns,1 do
                local ind = (i-1)*store.columns + j
                squareEndingAt[ind] = 0
                if goalMap[ind] == 0 then
                    local squareSize = 1
                    if i > 1 and j > 1 then
                        squareSize = math.min(
                            squareEndingAt[(i-2)*store.columns + j],
                            squareEndingAt[(i-1)*store.columns + j-1],
                            squareEndingAt[(i-2)*store.columns + j-1]
                        ) + 1
                    end
                    squareEndingAt[ind] = squareSize

                    if squareSize > largestN then
                        largestN = squareSize
                        minX = j - squareSize + 1
                        maxX = j
                        minY = i - squareSize + 1
                        maxY = i
                    end
                end
            end
        end
        -- print("Largest square:", largestN, "bounds:", minX, maxX, minY, maxY)
        newGoal = Request(math.min(size, largestN-1), minX, maxX, minY, maxY)
        table.insert(goals, newGoal)
    end

    storeGrid.needsDisplay = true
    timeSinceLastGoal = 0
end

function CheckStoreGoals()
    local i = 1
    while i <= #goals do
        local goal = goals[i]
        local goalMet = true

        local trashIDs = {}
        for pos,v in ipairs(goal.map) do
            if v ~= 0 then
                if itemMap[pos] == 0 then
                    goalMet = false
                    break
                else
                    -- If the trash has the "garbage" tag, it is not eligible to complete a goal
                    for k,trash in pairs(trashInStore) do
                        if trash.id == itemMap[pos] and trash.tags ~= nil then
                            for _,tag in ipairs(trash.tags) do
                                if tag == "garbage" then
                                    goalMet = false
                                    break
                                end
                            end
                        end
                    end

                    -- There is valid trash in this position, so record its ID
                    trashIDs[itemMap[pos]] = 1
                end
            end
        end

        -- Check all of the recorded IDs. If any of them have positions outside of the goal zone,
        -- the goal is not met
        for pos,id in ipairs(itemMap) do
            if goal.map[pos] == 0 then
                if trashIDs[id] ~= nil then
                    goalMet = false
                    break
                end
            end
        end

        if goalMet then
            for id,_ in pairs(trashIDs) do
                print("Getting trash ID", id)
                for k,trash in pairs(trashInStore) do
                    if trash.id == id then
                        CustomerPurchase(k, trash)
                        break
                    end
                end
            end

            table.remove(goals, i)
            i -= 1

            OnGoalMet(goal.size)

            storeGrid.needsDisplay = true
            -- Goal completed. If conditions is met to generate new goals, do that after a delay
            if (#goals == 0) then
                print("Full clear!")
                OnFullClear()
                CreateRandomStoreGoal()
            end
        end
        i += 1
    end
end

function OnGoalMet(size)
    cashregister.PlusBonus()
    cQueue.OnGoalMet(size)
end

function OnFullClear()
    cQueue.OnFullClear()
end

-- Store grid functions
function store.UpdatePosition(dX,dY)
    local s,r,c = storeGrid:getSelection()
    
    if c+dX > 8 then
        if playdate.buttonJustPressed(playdate.kButtonRight) then
            return 0,0, true
        end
    end
    
    storeGrid:setSelection(s,math.min(math.max(r+dY,1),4),math.min(math.max(c+dX, 0), 8))
    s,r,c = storeGrid:getSelection()
    local x,y = storeGrid:getCellBounds(s,r,c)
    if c <= 0 then
        return x+storeX+16,y+storeY+16, true
    else
        return x+storeX+16,y+storeY+16, false
    end
end

function store.SetPosition(x,y)
    storeGrid.needsDisplay = true
    storeGrid:setSelection(1,y,x)
    local x,y = storeGrid:getCellBounds(storeGrid:getSelection())
    return x+storeX+16,y+storeY+16
end

function store.GetSelection()
    return storeGrid:getSelection()
end

function store.PlaceTrashRandomly(trash)
    for i=1,10,1 do
        local r,c = math.random(1,4), math.random(1,7)
        local toChange, itemAlreadyThere = GetTrashPosOnGrid(trash, r, c)

        if itemAlreadyThere == nil and toChange ~= nil then
            trash:setRotation(0)
            trash:setScale(1)
            trash:setCenter(trash.center[1], trash.center[2])
            trash:moveTo(storeX + c*32 - 16, storeY + r*32 - 16)
            for _,v in ipairs(toChange) do
                itemMap[v] = trash.id
            end
            trash.storeRow, trash.storeCol = r, c
            table.insert(trashInStore, trash)
            return true
        end
    end

    return false
end

function store.GetAvailableSpace(trash, minX, maxX)
    minX = minX or 1
    maxX = maxX or store.columns
    for i=1,10,1 do
        local r,c = math.random(1,4), math.random(minX,maxX)
        local toChange, itemAlreadyThere = GetTrashPosOnGrid(trash, r, c)
        
        if itemAlreadyThere == nil and toChange ~= nil then
            return r, c, storeX + c*32 - 16, storeY + r*32 - 16
        end
    end

    return nil,nil
end

function store.ReserveSpace(trash, rot, r, c)
    local toChange, itemAlreadyThere = GetTrashPosOnGrid(trash, r, c)
    if itemAlreadyThere == nil and toChange ~= nil then
        for _,v in ipairs(toChange) do
            itemMap[v] = -trash.id
        end
    end

    storeGrid.needsDisplay = true
    print("Reserved Space")
    PrintStoreGrid()
end

function store.UnreserveSpace(trash)
    for k,v in ipairs(itemMap) do
        if v == -trash.id then
            itemMap[k] = 0
        end
    end
    storeGrid.needsDisplay = true
end

function store.DropIntoStore(trash, targetX, targetY)
    trash:SetStoreFallAnimator(targetX, targetY)
    trash:setRotation(0)
    trash:setScale(1)
    trash:setZIndex(RenderLayer.FTRASH)
    trash:setCenter(trash.center[1], trash.center[2])
    table.insert(fallingTrash, trash)
end

function store.PlaceTrash(trash, rot, r, c)
    local newTrash = true
    if r == nil and c == nil then
        _,r,c = storeGrid:getSelection()
    end
    local toChange, itemAlreadyThere = GetTrashPosOnGrid(trash, r, c)
    if toChange == nil then return false, nil end

    local itemToSwap = nil
    if itemAlreadyThere then
        for i,t in ipairs(trashInStore) do
            if t.id == itemAlreadyThere then
                itemToSwap = t
                local responded, stg, shp, cen, rot = itemToSwap:checkResponse(trash)
                if responded then
                    toChange = GetTrashPosOnGrid({["shape"]=shp}, r, c)
                    if toChange == nil then return false, nil end

                    itemToSwap:SetStage(stg, shp, cen)
                    itemToSwap.rotation = rot
                    itemToSwap.sprite:setRotation(90 * rot)
                    newTrash = false
                    trash:remove()
                    trash = itemToSwap
                    itemToSwap = nil
                else
                    store.RemoveTrashFromStore(itemAlreadyThere,i)
                end
                break
            end
        end

        for _,v in ipairs(toChange) do
            itemMap[v] = trash.id
        end

        if newTrash then table.insert(trashInStore, trash) end
    else
        for _,v in ipairs(toChange) do
            itemMap[v] = trash.id
        end

        table.insert(trashInStore, trash)
    end

    CheckStoreGoals()

    PrintStoreGrid()

    trash.storeRow, trash.storeCol = r, c
    return true, itemToSwap
end

function PrintStoreGrid()
    local debugStr = ""
    for i=1,#itemMap,1 do
        debugStr = debugStr..itemMap[i].." "
        if i%8 == 0 then debugStr = debugStr.."\n" end
    end
    print(debugStr)
end

-- TAKES: a Trash, a row, a column, and some optional offsets
-- Checks the shape of the Trash at the given r and column
-- against the current store grid.
-- RETURNS: 
-- toChange: store grid locations that would be occupied by the
-- trash
-- itemAlreadyThere: one trash that it would intersect with, if any
-- If given trash would intersect more than one other trash or
-- has some part that is off the grid, toChange is nil
function GetTrashPosOnGrid(trash, r, c, offX, offY)
    offX = offX or 0
    offY = offY or 0
    local w = storeGrid:getNumberOfColumns()
    local h = storeGrid:getNumberOfRowsInSection(1)
    local cX = #trash.shape//2
    local cY = #trash.shape[1]//2
    r += offY
    c += offX
    r -= 1

    local itemAlreadyThere = nil
    local toChange = {}
    for i=1, #trash.shape, 1 do
        for j=1, #trash.shape[i], 1 do
            if trash.shape[i][j] == 1 then
                local x = c+j-1-cX
                local y = r+i-1-cY
                if y >= h or y < 0 or x > w or x < 1 then return nil, nil end 
                local newToChangeInd = y*w + x
                --print(newToChangeInd, itemMap[newToChangeInd])
                if itemMap[newToChangeInd] > 0 then
                    if not itemAlreadyThere then
                        itemAlreadyThere = itemMap[newToChangeInd]
                    elseif itemMap[newToChangeInd] ~= itemAlreadyThere then
                        return nil, nil
                    end
                -- If item is reserved for another falling item
                elseif itemMap[newToChangeInd] < 0 and itemMap[newToChangeInd] ~= -trash.id then
                    -- return nil, nil
                end
                table.insert(toChange, newToChangeInd)
            end
        end
    end
    return toChange, itemAlreadyThere
end

function store.PickupTrash()
    local _,y,x = storeGrid:getSelection()
    local w = storeGrid:getNumberOfColumns()
    local queryID = itemMap[(y-1)*w + x]
    if queryID > 0 then
        for i,trash in ipairs(trashInStore) do
            if trash.id == queryID then
                store.RemoveTrashFromStore(trash.id, i)
                return trash
            end
        end
    end

    return nil
end

function ReservoirSample(table, n)
    local returnTable = {}
    n = math.min(n, #table)

    for i=1, n, 1 do
        returnTable[i] = table[i]
    end

    for i=n+1, #table, 1 do
        local r = math.random(1, i)
        if r <= n then
            returnTable[r] = table[i]
        end
    end

    return returnTable
end


function store.WetTrash(centerTrash)
    print("WetCenter: ", centerTrash.storeRow, centerTrash.storeCol)
    local wetZone = copy(centerTrash.shape)

    -- Pad wet zone shape matrix with zeroes
    local emptyRow = {}
    for i=1, #wetZone, 1 do table.insert(emptyRow, 0) end
    table.insert(wetZone, 1, copy(emptyRow))
    table.insert(wetZone, copy(emptyRow))
    for _,row in ipairs(wetZone) do
        table.insert(row, 1, 0)
        table.insert(row, 0)
    end

    for i=2, #wetZone-1, 1 do
        local row = wetZone[i]
        for j=2, #row-1, 1 do
            if wetZone[i][j] == 1 then
                if wetZone[i+1][j] == 0 then wetZone[i+1][j] = 2 end
                if wetZone[i-1][j] == 0 then wetZone[i-1][j] = 2 end
                if wetZone[i][j+1] == 0 then wetZone[i][j+1] = 2 end
                if wetZone[i][j-1] == 0 then wetZone[i][j-1] = 2 end
            end
        end
    end

    for i=1, #wetZone, 1 do
        local row = wetZone[i]
        for j=1, #row, 1 do
            if wetZone[i][j] == 2 then wetZone[i][j] = 1 end
        end
    end

    for i=1, #wetZone, 1 do
        local debugStr = ""
        local row = wetZone[i]
        for j=1, #row, 1 do
            if wetZone[i][j] == 2 then wetZone[i][j] = 1 end
            debugStr = debugStr..wetZone[i][j].." "
        end
        print(debugStr)
    end

    -- Splash other trash in wet zone
    local w = storeGrid:getNumberOfColumns()
    local splashedTrashIDs = {}
    for r,row in ipairs(wetZone) do
        for c,_ in ipairs(row) do
            local wR = centerTrash.storeRow + r - (#wetZone // 2) - 1
            local wC = centerTrash.storeCol + c - (#wetZone // 2) - 1
            local trashID = itemMap[(wR-1)*w + wC]
            if trashID ~= nil and trashID ~= 0 and wetZone[r][c] == 1 then
                local alreadySplashed = false
                for _,id in ipairs(splashedTrashIDs) do
                    if id == trashID then
                        alreadySplashed = true
                    end
                end

                if (not alreadySplashed) then
                    table.insert(splashedTrashIDs, trashID)
                    for i,trash in ipairs(trashInStore) do
                        if trash.id == trashID then
                            trash:Splash()
                        end
                    end
                end
            end
        end
    end
end

function store.SweetenTrash(n)
    local classicTrash = {}
    for _,trash in pairs(trashInStore) do
        local isClassic = true
        for _,tag in ipairs(trash.tags) do
            if tag == "garbage" then
                isClassic = false
                break
            end
        end
        if isClassic then
            table.insert(classicTrash, trash)
        end
    end
    local targetTrash = ReservoirSample(classicTrash, n)
    print("Sweetening "..#targetTrash)
    for _,v in ipairs(targetTrash) do
        v:AddEffect("sweeten")
    end
end

function store.RemoveTrashFromStore(id, idx)
    for i=1, #itemMap, 1 do
        if itemMap[i] == id then
            itemMap[i] = 0
        end
    end
    
    if idx ~= nil then
        table.remove(trashInStore, idx)
    else
        for i=1, #trashInStore, 1 do
            if trashInStore[i].id == id then
                table.remove(trashInStore, i)
                break
            end
        end
    end

    -- local debugStr = ""
    -- for i=1,#itemMap,1 do
    --     debugStr = debugStr..itemMap[i].." "
    --     if i%8 == 0 then debugStr = debugStr.."\n" end
    -- end
    -- print(debugStr)

    return true
end

function store.Init()
    itemMap = {}
    trashInStore = {}
    fallingTrash = {}
    fallingOffBoard = {}
    goals = {}
    timeSinceLastGoal = 0

    for i=1,storeGrid:getNumberOfColumns(),1 do
        for j=1,storeGrid:getNumberOfRowsInSection(1),1 do
            table.insert(itemMap, 0)
        end
    end
    storeFXSpr:add()
    CreateRandomStoreGoal()
end

function store.update()
    cQueue.update(trashInStore)
    timeSinceLastGoal += deltaTime
    local maxSize = 2
    if GetDifficultyLevel() > 1 then maxSize = 3 end
    if timeSinceLastGoal > 6 and #goals < math.min(cQueue.GetCrowdPenalty(), GetDifficultyLevel() + 2) then
        CreateRandomStoreGoal(math.random(1, maxSize))
    end

    if (storeGrid.needsDisplay) then
        gfx.lockFocus(storeFXImg)
        storeFXImg:clear(gfx.kColorClear)
        storeGrid:drawInRect(storeX, storeY, 276, 148)
        gfx.unlockFocus()
        storeFXSpr:markDirty()
    end
    -- Trash in store behaviour (e.g., fx animations)
    for _,trash in ipairs(trashInStore) do
        trash:update()
    end

    -- Falling trash behaviour
    local i = 1
    while #fallingTrash > 0 and i <= #fallingTrash do
        local t = fallingTrash[i]
        t:moveTo(t.storeFallAnimator:currentValue())

        if t.storeFallAnimator:ended() then
            table.remove(fallingTrash, i)
            i -= 1
            t:setZIndex(RenderLayer.STRASH)
            
            local _, itemAlreadyThere = GetTrashPosOnGrid(t, t.storeTargetR, t.storeTargetC)
            if itemAlreadyThere == nil then
                store.PlaceTrash(t, 1, t.storeTargetR, t.storeTargetC)
                storeGrid.needsDisplay = true
            -- Falling item would land on newly placed item.
            -- Right now just deletes self. Maybe bounce to incinerator?
            else
                store.UnreserveSpace(t)
                t.storeFallAnimator = gfx.animator.new({200, 500}, 
                    {playdate.geometry.lineSegment.new(t.sprite.x, t.sprite.y, t.sprite.x+10, t.sprite.y-18), playdate.geometry.lineSegment.new(t.sprite.x+10, t.sprite.y-18, t.sprite.x+10, 300)}, 
                    {playdate.easingFunctions.outCubic, playdate.easingFunctions.inCubic})
                table.insert(fallingOffBoard, t)
            end
        end

        i += 1
    end

    i = 1
    while #fallingOffBoard > 0 and i <= #fallingOffBoard do
        local t = fallingOffBoard[i]
        t:moveTo(t.storeFallAnimator:currentValue())

        if t.storeFallAnimator:ended() then
            table.remove(fallingOffBoard, i)
            i -= 1
        end

        i += 1
    end
end