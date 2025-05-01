import "CoreLibs/object"

local gfx <const> = playdate.graphics

local nextTrashID = 1

class("Trash").extends()

function Trash:init(name, img)
    self.name = name
    self.id = nextTrashID
    nextTrashID += 1
    local newImg = gfx.image.new("images/Trash/"..img)
    self.sprite = gfx.sprite.new(newImg)
    self.shape = {{0,0,0},{1,1,1},{0,0,0}}
    self.center = {1,1}
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
function Trash:setZIndex(z)
    self.sprite:setZIndex(z)
end