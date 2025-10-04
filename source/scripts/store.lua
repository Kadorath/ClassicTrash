import "CoreLibs/ui"
import "CoreLibs/nineslice"

import "scripts/cQueue"

store = {}

local gfx <const> = playdate.graphics

-- Store grid and item map
local itemMap = {}
local trashInStore = {}
local fallingTrash = {}

local storeX, storeY = 64,81
local storeGrid = playdate.ui.gridview.new(32,32)
storeGrid:setNumberOfColumns(8)
storeGrid:setNumberOfRowsInSection(1,4)
storeGrid:setSelection(0,0,0)

function storeGrid:drawCell(section, row, column, selected, x, y, width, height)
    gfx.setColor(gfx.kColorBlack)
    if selected then gfx.setLineWidth(3)
    else gfx.setLineWidth(1) end
    if itemMap[(row-1)*8 + column] == 0 then
        gfx.drawRect(x,y,width,height)
    else
        gfx.fillRect(x,y,width,height)
    end
end

for i=1,storeGrid:getNumberOfColumns(),1 do
    for j=1,storeGrid:getNumberOfRowsInSection(1),1 do
        table.insert(itemMap, 0)
    end
end

-- local bgNineSlice = gfx.nineSlice.new("images/storebg", 16, 16, 32, 32)
-- local bgImg = gfx.image.new(276,148)
-- gfx.pushContext(bgImg)
-- bgNineSlice:drawInRect(0,0,276,148)
-- gfx.popContext()
-- local bgSpr = gfx.sprite.new(bgImg)
-- bgSpr:setCenter(0,0)
-- bgSpr:setZIndex(1)
-- bgSpr:moveTo(storeX-12, storeY-12)
-- bgSpr:add()

-- Store grid functions
function store.UpdatePosition(dX,dY)
    storeGrid.needsDisplay = true
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

function store.GetAvailableSpace(trash)
    for i=1,10,1 do
        local r,c = math.random(1,4), math.random(1,8)
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
end

function store.DropIntoStore(trash, targetR, targetC)
    trash:SetStoreFallAnimator(targetR, targetC)
    trash:setRotation(0)
    trash:setScale(1)
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

    local debugStr = ""
    for i=1,#itemMap,1 do
        debugStr = debugStr..itemMap[i].." "
        if i%8 == 0 then debugStr = debugStr.."\n" end
    end
    print(debugStr)
    trash.storeRow, trash.storeCol = r, c
    return true, itemToSwap
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
                elseif itemMap[newToChangeInd] < 0 and itemMap[newToChangeInd] ~= -trash.id then
                    return nil, nil
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
    n = math.min(n, #trashInStore)

    for i=1, n, 1 do
        returnTable[i] = trashInStore[i]
    end

    for i=n+1, #trashInStore, 1 do
        local r = math.random(1, i)
        if r <= n then
            returnTable[r] = trashInStore[i]
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
            print (wR, wC)
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
    local targetTrash = ReservoirSample(trashInStore, n)
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

-- Customer functions
function store.update()
    cQueue.update(trashInStore)
    --storeGrid:drawInRect(storeX, storeY, 276, 148)

    for _,trash in ipairs(trashInStore) do
        trash:update()
    end

    local i = 1

    while #fallingTrash > 0 and i <= #fallingTrash do
        local t = fallingTrash[i]
        t:moveTo(t.storeFallAnimator:currentValue())

        if t.storeFallAnimator:ended() then
            for idx,v in ipairs(fallingTrash) do
                if v == t then
                    table.remove(fallingTrash, idx)
                    i -= 1
                    t:setZIndex(2)
                    store.PlaceTrash(t, 1, t.storeTargetR, t.storeTargetC)
                    break
                end
            end
        end

        i += 1
    end
end