import "CoreLibs/ui"
import "CoreLibs/nineslice"

store = {}

local gfx <const> = playdate.graphics

local itemMap = {}
local trashInStore = {}

local storeX, storeY = 88,84
local storeGrid = playdate.ui.gridview.new(32,32)
storeGrid:setNumberOfColumns(7)
storeGrid:setNumberOfRowsInSection(1,4)
storeGrid:setSelection(0,0,0)

function storeGrid:drawCell(section, row, column, selected, x, y, width, height)
    gfx.setColor(gfx.kColorBlack)
    if selected then gfx.setLineWidth(3)
    else gfx.setLineWidth(1) end
    gfx.drawRect(x,y,width,height)
end

for i=1,storeGrid:getNumberOfColumns(),1 do
    for j=1,storeGrid:getNumberOfRowsInSection(1),1 do
        table.insert(itemMap, 0)
    end
end

local bgNineSlice = gfx.nineSlice.new("images/storebg", 16, 16, 32, 32)
local bgImg = gfx.image.new(248,152)
gfx.pushContext(bgImg)
bgNineSlice:drawInRect(0,0,248,152)
gfx.popContext()
local bgSpr = gfx.sprite.new(bgImg)
bgSpr:setCenter(0,0)
bgSpr:setZIndex(1)
bgSpr:moveTo(storeX-12, storeY-12)
bgSpr:add()

function store.update()
end

function store.UpdatePosition(dX,dY)
    storeGrid.needsDisplay = true
    local s,r,c = storeGrid:getSelection()
    storeGrid:setSelection(s,math.min(math.max(r+dY,1),4),math.min(math.max(c+dX, 0), 7))
    s,r,c = storeGrid:getSelection()
    local x,y = storeGrid:getCellBounds(s,r,c)
    print(c)
    if c <= 0 then
        return x+storeX+16,y+storeY-12, true
    else
        return x+storeX+16,y+storeY-12, false
    end
end

function store.SetPosition(x,y)
    storeGrid.needsDisplay = true
    storeGrid:setSelection(1,y,x)
    local x,y = storeGrid:getCellBounds(storeGrid:getSelection())
    return x+storeX+16,y+storeY-12
end

function store.GetSelection()
    return storeGrid:getSelection()
end

function store.PlaceTrash(trash, rot)
    rot = rot or 1
    local w = storeGrid:getNumberOfColumns()
    local h = storeGrid:getNumberOfRowsInSection(1)
    local cX = trash.center[1]
    local cY = trash.center[2]
    local _,r,c = storeGrid:getSelection()
    r -= 1
    
    local toChange = {}
    for i,row in ipairs(trash.shape) do
        for j,col in ipairs(row) do
            if col == 1 then
                local newToChangeInd = -1
                local x = -1
                local y = -1
                if rot == 1 then
                    x = (c+j-1-cX)
                    y = (r+i-1-cY)
                elseif rot == 2 then
                    x = (c-i+1+cX)
                    y = (r+j-1-cY)
                elseif rot == 3 then
                    x = (c-j+1+cX)
                    y = (r-i+1+cY)
                elseif rot == 4 then
                    x = (c+i-1-cX)
                    y = (r-j+1+cY)
                end
                print(x,y)
                if y >= h or y < 0 or x > w or x < 1 then return false end 
                newToChangeInd = y*w + x
                if itemMap[newToChangeInd] > 0 then return false end

                table.insert(toChange, newToChangeInd)
            end
        end
    end

    for _,v in ipairs(toChange) do
        itemMap[v] = trash.id
    end
    table.insert(trashInStore, trash)

    local debugStr = ""
    for i=1,#itemMap,1 do
        debugStr = debugStr..itemMap[i].." "
        if i%7 == 0 then debugStr = debugStr.."\n" end
    end
    print(debugStr)

    return true
end