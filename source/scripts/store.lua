import "CoreLibs/ui"
import "CoreLibs/nineslice"

import "scripts/cQueue"

store = {}

local gfx <const> = playdate.graphics

-- Store grid and item map
local itemMap = {}
local trashInStore = {}

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

function store.PlaceTrash(trash, rot)
    local newTrash = true
    local toChange, itemAlreadyThere = GetTrashPosOnGrid(trash)
    if toChange == nil then return false, nil end

    local itemToSwap = nil
    if itemAlreadyThere then
        for i,t in ipairs(trashInStore) do
            if t.id == itemAlreadyThere then
                itemToSwap = t
                local responded, stg, shp, cen = itemToSwap:checkResponse(trash)
                if responded then
                    toChange = GetTrashPosOnGrid({["shape"]=shp})
                    if toChange == nil then return false, nil end

                    itemToSwap:SetStage(stg, shp, cen)
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
    
    return true, itemToSwap
end

function GetTrashPosOnGrid(trash, offX, offY)
    offX = offX or 0
    offY = offY or 0
    local w = storeGrid:getNumberOfColumns()
    local h = storeGrid:getNumberOfRowsInSection(1)
    local cX = #trash.shape//2
    local cY = #trash.shape[1]//2
    local _,r,c = storeGrid:getSelection()
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

function store.SweetenTrash(n)
    local targetTrash = ReservoirSample(trashInStore, n)
    print(#targetTrash)
    for _,v in ipairs(targetTrash) do
        print(v.name)
    end
end

function store.RemoveTrashFromStore(id, idx)
    for i=1, #itemMap, 1 do
        if itemMap[i] == id then
            itemMap[i] = 0
        end
    end
    
    table.remove(trashInStore, idx)

    local debugStr = ""
    for i=1,#itemMap,1 do
        debugStr = debugStr..itemMap[i].." "
        if i%8 == 0 then debugStr = debugStr.."\n" end
    end
    print(debugStr)

    return true
end

-- Customer functions
function store.update()
    cQueue.update(trashInStore)
    --storeGrid:drawInRect(storeX, storeY, 276, 148)
end