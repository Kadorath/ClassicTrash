import "scripts/conveyor"
import "scripts/store"
import "scripts/cQueue"

player = {}

local gfx <const> = playdate.graphics

local moveSFX  = playdate.sound.sampleplayer.new("audio/UIMove")
local errorSFX = playdate.sound.sampleplayer.new("audio/Error")
local placeSFX = playdate.sound.sampleplayer.new("audio/UISelect")

local pawSpr = gfx.sprite.new(gfx.image.new("images/paw"))
local x,y = conveyor.UpdateSelection(0)
pawSpr:setZIndex(100)
pawSpr:moveTo(x,y)
pawSpr:add()

local heldTrash = nil
local rotation  = 1

local section = 1

function player.update()
    if section == 1 then
        if playdate.buttonJustPressed(playdate.kButtonUp) then
            local x,y = conveyor.UpdateSelection(-1)
            MovePaw(x,y)
        elseif playdate.buttonJustPressed(playdate.kButtonDown) then
            local x,y = conveyor.UpdateSelection(1)
            MovePaw(x,y)
        elseif playdate.buttonJustPressed(playdate.kButtonRight) then
            local x,y = store.SetPosition(1,conveyor.GetSelection())
            MovePaw(x,y)
            section += 1 
        elseif playdate.buttonJustPressed(playdate.kButtonA) then
            local newTrash = conveyor.TakeFromBelt()
            rotation = 1
            if newTrash then 
                newTrash:setZIndex(2)
                heldTrash = newTrash 
            end
        end
    elseif section == 2 then
        if playdate.buttonJustPressed(playdate.kButtonUp) then
            local x,y = store.UpdatePosition(0,-1)
            MovePaw(x,y)
        elseif playdate.buttonJustPressed(playdate.kButtonDown) then
            local x,y = store.UpdatePosition(0,1)
            MovePaw(x,y)
        elseif playdate.buttonJustPressed(playdate.kButtonRight) then
            local x,y = store.UpdatePosition(1,0)
            MovePaw(x,y)
        elseif playdate.buttonJustPressed(playdate.kButtonLeft) then
            local x,y,toConveyor = store.UpdatePosition(-1,0)
            if not toConveyor then
                MovePaw(x,y)
            else
                local _,r,_ = store.GetSelection()
                x,y = conveyor.SetSelection(r)
                MovePaw(x,y)
                section -= 1
            end
        elseif playdate.buttonJustPressed(playdate.kButtonA) then
            if heldTrash then
                local placed, swappedItem = store.PlaceTrash(heldTrash, rotation)
                if placed then
                    placeSFX:play(1)
                    heldTrash:setZIndex(1)
                    heldTrash = swappedItem
                    if heldTrash then
                        heldTrash:setZIndex(2)
                    end
                    PutTrashInPaw()
                else
                    errorSFX:play(1)
                end
            else 
                local pickup = store.PickupTrash()
                if pickup then
                    heldTrash = pickup
                    heldTrash:setZIndex(2)
                    PutTrashInPaw()
                end
            end
        end
    end

    if heldTrash then
        if playdate.buttonJustPressed(playdate.kButtonB) then
            rotation += 1
            heldTrash:rotateClockwise()
            if rotation > 4 then rotation = 1 end

            PutTrashInPaw()
        end
    end

    gfx.drawText(cQueue.GetCustomerCount(), 32,32)
end

function MovePaw(x,y)
    moveSFX:play(1)
    pawSpr:moveTo(x,y)
    PutTrashInPaw()
end

function PutTrashInPaw()
    local x, y = pawSpr:getPosition()
    if heldTrash then
        heldTrash:moveTo(x,y+28)
    end
end