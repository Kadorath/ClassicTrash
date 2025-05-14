import "CoreLibs/object"
import "CoreLibs/animation"

local gfx <const> = playdate.graphics
local geo <const> = playdate.geometry

local nextTrashID = 1

class("Customer").extends()

function Customer:init(data, x, y)
    self.name = data["name"]
    self.img = gfx.imagetable.new("images/Customers/"..data["img"])
    self.sprite = gfx.sprite.new(self.img:getImage(1))
    self.animator = gfx.animation.loop.new(150, self.img)
    self.sprite:setZIndex(0)
    self.sprite:setCenter(0.5, 1)
    self.sprite:moveTo(x, y)
    self.sprite:add()

    self.request = data["wants"][math.random(#data["wants"])]
    self.requestImg = gfx.image.new("images/Trash/"..self.request)
    self.requestSpr = gfx.sprite.new(self.requestImg)
    self.requestSpr:setScale(0.5)
    self.requestSpr:moveTo(x,y-48)
    self.requestSpr:setZIndex(0)
    self.requestSpr:add()

    self.patience = data["patience"]

    self.speed      = 2
    self.moveTarget = nil
    self.moveDir    = nil
    
    -- 1: Entering, 2: Waiting, 3: Exiting
    self.state = 1
end

function Customer:SetMoveTarget(x,y,s)
    self.speed = s or self.speed
    self.moveTarget = {x,y}
    self.moveDir = geo.vector2D.new(self.moveTarget[1]-self.sprite.x, self.moveTarget[2]-self.sprite.y)
    self.moveDir:normalize()
    self.moveDir:scale(self.speed)
end

function Customer:SetState(s)
    self.state = s

    if self.state == 3 then
        self.requestSpr:remove()
    end
end

function Customer:update()
    if self.moveDir then
        self.sprite:moveBy(self.moveDir:unpack())
        local sqrDistToTarget = ((self.sprite.x-self.moveTarget[1])^2 + (self.sprite.y-self.moveTarget[2])^2)
        if sqrDistToTarget < 12 then
            self.moveDir = geo.vector2D.new(0,0)
            if self.state == 1 then
                self.state += 1
            end
        end
        self.requestSpr:moveTo(self.sprite.x,self.sprite.y-48)
    end

    self.sprite:setImage(self.animator:image())
end

function Customer:remove()
    self.sprite:remove()
    self.requestSpr:remove()
end