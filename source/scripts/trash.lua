import "CoreLibs/animator"
import "CoreLibs/object"
import "scripts/store"

local gfx <const> = playdate.graphics

local nextTrashID = 1

class("Trash").extends()

function Trash:init(name, data)
    self.name = name
    self.id = nextTrashID
    nextTrashID += 1
    self.value = data["value"] or 1

    self.stageCt = data["stages"] or 1
    self.stage   = 1
    self.img = nil
    self.sprite = nil
    if self.stageCt == 1 then
        self.img = gfx.image.new("images/Trash/"..data["img"])
        self.sprite = gfx.sprite.new(self.img)
    else
        self.img = gfx.imagetable.new("images/Trash/"..data["img"])
        self.sprite = gfx.sprite.new(self.img[1])
    end
    self.sprite:setGroups({3})
    
    self.rotation = 0
    self.shape = {}
    local shapeData  = nil
    local centerData = nil
    if self.stageCt == 1 then
        shapeData  = data["shape"]
        centerData = data["center"]
    else
        self.shapeList  = data["shape"]
        self.centerList = data["center"] 
        shapeData  = data["shape"][self.stage]
        centerData = data["center"][self.stage]
    end

    for _,r in ipairs(shapeData) do
        local newRow = {}
        for _,v in ipairs(r) do
            table.insert(newRow, v)
        end
        table.insert(self.shape, newRow)
    end
    self.center = {centerData[1], centerData[2]}

    self.response = data["response"]

    -- Conveyor belt movement parameters
    self.beltTargetX = 0
    self.beltTargetY = 0
    self.beltPosAnimator = nil
    -- Incinerator physics parameters
    self.velocity = {(math.random()-0.5)*0.25,0}
end

function Trash:checkResponse(other)
    if self.response then
        for k,r in pairs(self.response) do
            print(k, other.name)
            if k == other.name then
                if r == "stack" then
                    local newStage = math.min(self.stageCt, self.stage + other.stage)

                    if other.stage >= self.stageCt or self.stage >= self.stageCt then 
                        return false, nil, nil, nil 
                    end

                    local newShape = self.shapeList[newStage]
                    local newCenter = self.centerList[newStage]
                    for i=1, self.rotation, 1 do
                        Rotate90(newShape)
                    end
                    return true, newStage, newShape, newCenter
                end
            end
        end
    end
    return false, nil, nil, nil
end

function Trash:SetStage(stage, s, c)
    self.stage = stage
    self.shape = s
    self.center = c
    self.sprite:setCenter(self.center[1], self.center[2])
    self.sprite:setImage(self.img[self.stage])
end

function Trash:Purchased()
    local sellValue = self.value
    print(self.name)
    if self.name == "cottoncandy" then
        store.SweetenTrash(self.stage)
    end
    return sellValue
end

function Trash:getSprite()
    return self.sprite
end
function Trash:add()
    self.sprite:add()
end
function Trash:remove()
    self.sprite:remove()
end
function Trash:moveTo(x,y)
    self.sprite:moveTo(x,y)
end
function Trash:moveBy(x,y)
    self.sprite:moveBy(x,y)
end
function Trash:SetBeltPosition(x,y,time)
    time = time or 250
    self.beltTargetX = x
    self.beltTargetY = y
    local curX, curY = self.sprite:getPosition()
    local moveLine = playdate.geometry.lineSegment.new(curX,curY,x,y)
    self.beltPosAnimator = gfx.animator.new(time, moveLine, playdate.easingFunctions.inOutCubic)
end
function Trash:UpdateBeltPosition()
    self.sprite:moveTo(self.beltPosAnimator:currentValue())
    return self.beltPosAnimator:ended()
end

function Trash:moveWithCollisions(x,y)
    return self.sprite:moveWithCollisions(x,y)
end
function Trash:updateVelocity(x,y)
    self.velocity[1] += x
    self.velocity[2] += y
end
function Trash:setZIndex(z)
    self.sprite:setZIndex(z)
end
function Trash:setScale(s)
    self.sprite:setScale(s)
end
function Trash:setRotation(r)
    self.sprite:setRotation(r)
end
function Trash:setCenter(x,y)
    self.sprite:setCenter(x,y)
end
function Trash:rotateClockwise()
    self.rotation += 1
    self.sprite:setRotation(self.sprite:getRotation()+90)
    if self.sprite:getRotation() == 0 then
        self.rotation = 0
        self.sprite:setRotation(0)
        self.sprite:setCenter(self.center[1], self.center[2])
    end

    Rotate90(self.shape)
end

function Rotate90(mat)
    -- Rotate the shape matrix
    local debugStr = ""
    for i=1,#mat,1 do
        for j=1,#mat,1 do
            debugStr = debugStr..mat[i][j].." "
        end
        debugStr = debugStr.."\n"
    end
    print(debugStr)

    -- transpose
    for i=1,#mat,1 do
        for j=i,#mat[i],1 do
            local temp = mat[i][j]
            mat[i][j] = mat[j][i]
            mat[j][i] = temp
        end
    end
    -- reverse rows
    for i=1,#mat,1 do
        for j=1,#mat[i]//2,1 do
            local temp = mat[i][j]
            mat[i][j] = mat[i][#mat-j+1]
            mat[i][#mat-j+1] = temp
        end
    end

    debugStr = ""
    for i=1,#mat,1 do
        for j=1,#mat,1 do
            debugStr = debugStr..mat[i][j].." "
        end
        debugStr = debugStr.."\n"
    end
    print(debugStr)
end

function Trash:getPosition()
    return self.sprite.x, self.sprite.y
end
function Trash:getSize()
    return self.sprite:getSize()
end

function Trash:setCollideRect(x,y,w,h)
    self.sprite:setCollideRect(x,y,w,h)
    self.sprite:setCollidesWithGroups({1,2,3})
    self.sprite.collisionResponse = function(other)
        if other:getGroupMask() == 1 then
            return gfx.sprite.kCollisionTypeSlide
        else
            return gfx.sprite.kCollisionTypeFreeze
        end
    end
end

function Trash:incineratorCollision(x, y, collisions, length)
    if length > 0 then
        --self.velocity[1] += (math.random()-0.5)
        self.velocity[2] *= -0.25
    end
end