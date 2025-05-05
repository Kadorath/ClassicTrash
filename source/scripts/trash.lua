import "CoreLibs/animator"
import "CoreLibs/object"

local gfx <const> = playdate.graphics

local nextTrashID = 1

class("Trash").extends()

function Trash:init(name, data)
    self.name = name
    self.id = nextTrashID
    nextTrashID += 1
    local newImg = gfx.image.new("images/Trash/"..data["img"])
    self.sprite = gfx.sprite.new(newImg)
    self.sprite:setGroups({3})
    
    self.shape = {}
    for _,r in ipairs(data["shape"]) do
        local newRow = {}
        for _,v in ipairs(r) do
            table.insert(newRow, v)
        end
        table.insert(self.shape, newRow)
    end
    self.center = {data["center"][1], data["center"][2]}

    -- Conveyor belt movement parameters
    self.beltTargetX = 0
    self.beltTargetY = 0
    self.beltPosAnimator = nil
    -- Incinerator physics parameters
    self.velocity = {(math.random()-0.5)*0.25,0}
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
function Trash:setCenter(x,y)
    self.sprite:setCenter(x,y)
end
function Trash:rotateClockwise()
    self.sprite:setRotation(self.sprite:getRotation()+90)
    if self.sprite:getRotation() == 0 then
        self.sprite:setRotation(0)
        self.sprite:setCenter(self.center[1], self.center[2])
    end
    
    -- Rotate the shape matrix
    local debugStr = ""
    for i=1,#self.shape,1 do
        for j=1,#self.shape,1 do
            debugStr = debugStr..self.shape[i][j].." "
        end
        debugStr = debugStr.."\n"
    end
    print(debugStr)

    for i=1,#self.shape,1 do
        for j=i,#self.shape[i],1 do
            local temp = self.shape[i][j]
            self.shape[i][j] = self.shape[j][i]
            self.shape[j][i] = temp
        end
    end
    for i=1,#self.shape,1 do
        local temp = self.shape[i][1]
        self.shape[i][1] = self.shape[i][3]
        self.shape[i][3] = temp
    end

    debugStr = ""
    for i=1,#self.shape,1 do
        for j=1,#self.shape,1 do
            debugStr = debugStr..self.shape[i][j].." "
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