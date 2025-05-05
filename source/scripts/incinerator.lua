incinerator = {}

local gfx <const> = playdate.graphics
local g <const> = .98
trashBag = {}

local incinX = 330
local incinY = 74
local incinW = 60
local incinH = 160

local floorCol = gfx.sprite.new()
floorCol:setSize(incinW, 6)
floorCol:setCenter(0,0)
floorCol:moveTo(incinX, incinY+incinH)
floorCol:setCollideRect(0,0,floorCol:getSize())
floorCol:add()

local burnProgress = 0

function incinerator.AddToIncinerator(trash)
    table.insert(trashBag, trash)
    trash:moveTo(incinX + incinW/2, incinY-98)
    trash:setCollideRect(0,0,trash:getSize())
end

function incinerator.update()
    --gfx.drawRect(incinX, incinY, incinW, incinH)
    for _,trash in ipairs(trashBag) do
        trash:updateVelocity(0,g)
        local x,y = trash:getPosition()
        trash:incineratorCollision(
            trash:moveWithCollisions(x+trash.velocity[1],y+trash.velocity[2])
        )
    end

    local crankD = math.abs(playdate.getCrankChange())
    burnProgress += crankD
    if #trashBag > 0 and burnProgress >= 180 then
        local burnedTrash = table.remove(trashBag, 1)
        burnedTrash:remove()
        burnProgress = 0
    end

    --gfx.drawText(burnProgress, incinX, incinY-24)
end