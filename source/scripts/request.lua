import "CoreLibs/object"

class("Request").extends()

local requestShapeSmall = {
    {{1, 0}, {0, 0}}, -- Single tile
    {{1, 0}, {1, 1}}, -- Small L
    {{1, 1}, {0, 0}}, -- 2x1
}

local requestShapeMedium = {
    {{1, 1, 0}, {1, 1, 0}, {1, 1, 0}}, -- 3x2
    {{1, 1, 1}, {0, 1, 0}, {0, 1, 0}}, -- T
    {{1, 0, 0}, {1, 0, 0}, {1, 1, 1}}, -- Long L
    {{1, 0, 0}, {1, 0, 0}, {1, 1, 0}}, -- Short L
    {{1, 1, 1}, {1, 0, 1}, {1, 1, 1}}, -- O
    {{1, 1, 0}, {0, 1, 0}, {0, 1, 1}}, -- S
    {{0, 1, 0}, {1, 1, 1}, {0, 1, 0}}, -- Plus
    {{1, 0, 0}, {1, 1, 1}, {1, 1, 1}} -- Fat boy
}

function Request:init(size)
    self.map = {}
    for i=1,store.columns,1 do
        for j=1,store.rows,1 do
            table.insert(self.map, 0)
        end
    end

    self:pickRandomShape(size)
end

function Request:pickRandomShape(size)
    local shapeInd = 0
    local shape = {}
    local x = 0
    local y = 0
    local xBound = 0
    local yBound = 0
    local shapeTable = nil
    if size == 1 then
        shapeTable = requestShapeSmall
    elseif size == 2 then
        shapeTable = requestShapeMedium
    else
        print("Request Warning: Invalid size "..size.." passed to Request:pickRandomShape()")
    end

    shapeInd = math.random(#shapeTable)
    print("Request Sample Small Shape: "..shapeInd)
    shape = shapeTable[shapeInd]

    for r,row in ipairs(shape) do
        for c,v in ipairs(row) do
            if v == 1 then
                if r > yBound then yBound = r end
                if c > xBound then xBound = c end
            end
        end
    end
    
    x = math.random(store.columns - xBound + 1)
    y = math.random(store.rows - yBound + 1)
    print("Placing at ("..x..", "..y..")")
    for r,row in ipairs(shape) do
        for c,v in ipairs(row) do
            local ind = (y+r-2)*store.columns + x+c-1
            if (v == 1) then
                self.map[ind] = 1
            end
        end
    end
end