import "CoreLibs/animator"
import "CoreLibs/object"
import "scripts/store"

local gfx <const> = playdate.graphics

nextTrashID = 1

class("Trash").extends()

function Trash:init(name, data)
    self.name = name
    self.id = nextTrashID
    nextTrashID += 1
    self.value = data["value"] or 1
    self.bonus = 0
    self.tags = copy(data["tags"]) or {}

    self.stageCt = data["stages"] or 1
    self.stage   = 1
    self.minsellstage = data["minsellstage"] or 1
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
    
    self.displayVFX = true
    self.vfxAnim = nil
    self.vfxImgTable = nil
    self.vfxSpr = gfx.sprite.new()
    self.vfxSpr:add()

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
        shapeData  = copy(data["shape"][self.stage])
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
    self.storeRow = nil
    self.storeCol = nil
    self.heldOffX = 0
    self.heldOffY = 0

    self.response = data["response"]

    -- Conveyor belt movement parameters
    self.beltTargetX = 0
    self.beltTargetY = 0
    self.beltPosAnimator = nil
    -- Incinerator physics parameters
    self.velocity = {(math.random()-0.5)*0.25,0}
    -- Store Grid animators
    self.storeTargetR = nil
    self.storeTargetC = nil
    self.storeFallAnimator = nil

    -- Effects
    self.splashed = false
    for _,tag in ipairs(self.tags) do
        if tag == "smelly" then
            self:AddEffect("smelly")
        elseif tag == "wet" then
            self:AddEffect("wet")
        end
    end
end

function Trash:update()
    if self.displayVFX and self.vfxAnim then
        self.vfxSpr:setImage(self.vfxAnim:image())
        self.vfxSpr:moveTo(self.sprite:getPosition())
        self.vfxSpr:setZIndex(self.sprite:getZIndex())
    end
end

function Trash:checkResponse(other)
    if self.response then
        for k,r in pairs(self.response) do
            -- print(k, other.name)
            if k == other.name then
                if r == "stack" then
                    local newStage = math.min(self.stageCt, self.stage + other.stage)

                    if other.stage >= self.stageCt or self.stage >= self.stageCt then 
                        return false, nil, nil, nil 
                    end

                    local newShape = copy(self.shapeList[newStage])
                    local newCenter = self.centerList[newStage]
                    local newRot = self.rotation
                    if other.stage > self.stage then newRot = other.rotation end
                    for i=1, newRot, 1 do
                        Rotate90(newShape)
                    end
                    return true, newStage, newShape, newCenter, newRot
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
    if self.name == "cottoncandy" then
        store.SweetenTrash(self.stage)
    end

    if self.tags ~= nil then
        for _,tag in ipairs(self.tags) do
            if tag == "wet" then
                store.WetTrash(self)
            elseif tag == "sparky" then
                print('sparky')
            end
        end
    end

    return sellValue, self.bonus
end

function Trash:setDisplayVFX(display)
    self.displayVFX = display

    if self.vfxAnim == nil then return end
    if display then
        self.vfxSpr:add()
    else
        self.vfxSpr:remove()
    end
end

-- TODO: Effect sprite rotation not correct on sweetened trash that
-- has been rotated off center
local vfx = {
    ["sweet"] = gfx.imagetable.new("images/Effects/sparkle"),
    ["smelly"] = gfx.imagetable.new("images/Effects/smelly"),
    ["wet"] = gfx.imagetable.new("images/Effects/wet")
}
local memoizedFXImgTables = {}
function CreateEffectImageTable(trash, fxName)
    local memoKey = trash.name..fxName
    if memoizedFXImgTables[memoKey] ~= nil then
        return memoizedFXImgTables[memoKey]
    end

    local fx = vfx[fxName]
    local shape = trash.shape
    local newImgTable = gfx.imagetable.new(#fx, #shape*32, #shape*32)
    for i=1,#newImgTable,1 do
        newImgTable[i] = gfx.image.new(#shape*32, #shape*32)
    end

    for r,row in ipairs(shape) do
        for c,v in ipairs(row) do
            if v == 1 then
                for i=1,#newImgTable,1 do
                    local img = newImgTable[i]
                    gfx.lockFocus(img)
                    gfx.setImageDrawMode(gfx.kDrawModeCopy)
                    fx[i]:draw((c-1)*32, (r-1)*32)
                    gfx.unlockFocus()
                end
            end
        end
    end

    memoizedFXImgTables[memoKey] = newImgTable
    print("Created new effect image for: ", memoKey)
    return newImgTable
end

function Trash:AddEffect(effect)
    if effect == "sweeten" then
        self.vfxImgTable = CreateEffectImageTable(self, "sweet")
        self.vfxAnim = gfx.animation.loop.new(150, self.vfxImgTable)
        self.bonus += 1
    elseif effect == "smelly" then
        self.vfxImgTable = CreateEffectImageTable(self, "smelly")
        self.vfxAnim = gfx.animation.loop.new(350, self.vfxImgTable)
    elseif effect == "wet" then
        self.vfxImgTable = CreateEffectImageTable(self, "wet")
        self.vfxAnim = gfx.animation.loop.new(150, self.vfxImgTable)
    end
end

function Trash:Splash()
    if self.splashed then return end
    self.splashed = true
    print("Splashed: "..self.name, self.id)

    if self.name == "cottoncandy" then
        local sellValue = self:Purchased()
        store.RemoveTrashFromStore(self.id)
        self:remove()
        cashregister.score(sellValue)
    end
end

function Trash:getSprite()
    return self.sprite
end
function Trash:add()
    self.sprite:add()
end
function Trash:remove()
    self.sprite:remove()
    self.vfxSpr:remove()
end
function Trash:moveTo(x,y)
    self.sprite:moveTo(x,y)
    if self.vfxSpr then self.vfxSpr:moveTo(x,y)end
end
function Trash:moveBy(x,y)
    self.sprite:moveBy(x,y)
end

-- Belt Functions
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

function Trash:setStoreTarget(r,c)
    self.storeTargetR = r
    self.storeTargetC = c
end
function Trash:SetStoreFallAnimator(targetX, targetY)
    local fallLine = playdate.geometry.lineSegment.new(targetX, -64, targetX, targetY)
    self.storeFallAnimator = gfx.animator.new(1000, fallLine, playdate.easingFunctions.outBounce)
end

function Trash:moveWithCollisions(x,y)
    return self.sprite:moveWithCollisions(x,y)
end
function Trash:updateVelocity(x,y)
    self.velocity[1] += x
    self.velocity[2] += y
end

function Trash:rotateClockwise()
    offX = self.heldOffX
    offY = self.heldOffY

    self.rotation += 1
    self.sprite:setRotation(self.sprite:getRotation()+90)
    self.vfxSpr:setRotation(self.sprite:getRotation())
    if offX == 0 and offY == 0 then
        if self.sprite:getRotation() == 0 then
            self.rotation = 0
            self.sprite:setRotation(0)
            self.sprite:setCenter(self.center[1], self.center[2])
        end
        Rotate90(self.shape)
    else
        print("ROTATING WITH OFFSET OF ", offX, offY)
        Rotate90OffCenter(self.shape, offX, offY)
        self.heldOffX = -offY
        self.heldOffY = offX
    end
end

function Rotate90OffCenter(mat, offX, offY)
    local expandedShape = {}
    local bufferSize = (#mat-1) / 2
    local expandedSize = #mat+bufferSize*2
    for i=1,expandedSize,1 do
        local newRow = {}
        for j=1,expandedSize,1 do
            newRow[j] = 0
        end
        expandedShape[i] = newRow
    end

    for i=1,#mat,1 do
        for j=1,#mat,1 do
            if mat[i][j] == 1 then
                expandedShape[i+bufferSize + offY][j+bufferSize - offX] = 1
            end
        end
    end

    Rotate90(expandedShape)

    for i=1,#mat,1 do
        for j=1,#mat,1 do
            mat[i][j] = expandedShape[i + bufferSize - offX][j + bufferSize - offY]
        end
    end

    DEBUGPRINTMAT(mat)
end

-- Rotate the shape matrix
function Rotate90(mat)
    DEBUGPRINTMAT(mat)

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

    DEBUGPRINTMAT(mat)
end

function DEBUGPRINTMAT(mat)
    debugStr = ""
    for i=1,#mat,1 do
        for j=1,#mat,1 do
            debugStr = debugStr..mat[i][j].." "
        end
        debugStr = debugStr.."\n"
    end
    print(debugStr)
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

-- Setters
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

-- Getters
function Trash:getPosition()
    return self.sprite.x, self.sprite.y
end
function Trash:getSize()
    return self.sprite:getSize()
end