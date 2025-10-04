import "scripts/store"
import "scripts/cashregister"
cQueue = {}

local gfx <const> = playdate.graphics

local customerQueue   = {}
local customerLeaving = {}
local queueRect = playdate.geometry.rect.new(98, 58, 212, 16)

local scoreBlinkerAnim = gfx.animation.blinker.new(300, 50, true)
scoreBlinkerAnim:start()
local scoreBlinkers = {}

local customerPawImg = gfx.image.new("images/Paw.png")
local customerPawImg_diagonal = gfx.image.new("images/Paw_diagonal.png")
local customerPaws = {}

function cQueue.update(trashInStore)
    local idx = 1
    while idx <= #customerQueue do
        local customer = customerQueue[idx]
        
        if customer.state == 2 then
            for i,trash in ipairs(trashInStore) do
                if trash.name == customer.request and trash.stage >= trash.minsellstage then
                    CustomerPurchase(i, trash, customer)
                    table.remove(customerQueue, idx)
                    idx -= 1
                    break
                end
            end

            customer.patience -= 1
            if customer.patience <= 0 then
                CustomerStormOff(idx, customer)
                idx -= 1
            end
        end

        customer:update()

        if customer.moveDir.dx == 0 and customer.moveDir.dy == 0 then
            customer:SetMoveTarget(math.random(queueRect.x, queueRect.x+queueRect.w), 
                                   math.random(queueRect.y, queueRect.y+queueRect.h), 0.5)
        end

        idx += 1
    end

    idx = 1
    while idx <= #customerLeaving do
        local customer = customerLeaving[idx]
        customer:update()
        if customer.sprite.x > 424 then
            customer:remove()
            table.remove(customerLeaving, idx)
            idx -= 1
        end
        
        idx += 1
    end

    UpdateCustomerPaws()
    UpdateScoreUI()

    gfx.drawRect(queueRect)
end

function cQueue.AddCustomerToQueue(c)
    table.insert(customerQueue, c)
    print("Adding request: ", c.request)
    table.insert(truck.cRequests, c.request)
    c:SetMoveTarget(212, 64, 2)
end

function CustomerStormOff(idx, c)
    print("Customer "..idx.." stormed off")
    table.remove(customerQueue, idx)
    table.insert(customerLeaving, c)

    for i,v in ipairs(truck.cRequests) do
        if v == c.request then
            table.remove(truck.cRequests, i)
            break
        end
    end

    c:SetMoveTarget(432, 48, 2)
end

-- Scoring is done in UpdateCustomerPaws, when the trash is grabbbed by the paw
function CustomerPurchase(idx, trash, c)
    store.RemoveTrashFromStore(trash.id, idx)
    AddPawSwiper(trash)
    table.insert(customerLeaving, c)
    c:SetMoveTarget(432, 48, 2)
    c:SetState(3)

    for i,v in ipairs(truck.cRequests) do
        if v == trash.name then
            table.remove(truck.cRequests, i)
            break
        end
    end
end

function AddScoreBlinkerUI(xPos, yPos, v)
    local newBlinkerUI = {
        score = v,
        x = xPos,
        y = yPos,
        ttl = 1
    }
    table.insert(scoreBlinkers, newBlinkerUI)
end

function AddPawSwiper(trash)
    -- Initialize paw sprite
    local pawSpr = gfx.sprite.new(customerPawImg)
    pawSpr:setZIndex(3)
    pawSpr:add()

    -- Set up paw movement animator
    local targetX, targetY = trash:getPosition()
    local pawLine
    if (targetX > 200) then
        pawLine = playdate.geometry.lineSegment.new(450, targetY, targetX, targetY)
    else
        pawLine = playdate.geometry.lineSegment.new(-50, targetY, targetX, targetY)
        pawSpr:setScale(-1,1)
    end
    pawSpr:setCenter(0, 0.5)
    local pawAnim = gfx.animator.new(600, pawLine, playdate.easingFunctions["inOutQuad"])
    pawAnim.reverses = true
    table.insert(customerPaws, {sprite=pawSpr, anim=pawAnim, targetTrash=trash, grabbed=false})
end

function UpdateCustomerPaws()
    for i=#customerPaws, 1, -1 do
        customerPaws[i].sprite:moveTo(customerPaws[i].anim:currentValue())
        if customerPaws[i].grabbed then
            customerPaws[i].targetTrash.sprite:moveTo(customerPaws[i].sprite:getPosition())
        end
        if not customerPaws[i].grabbed and 
          math.abs(customerPaws[i].sprite.x - customerPaws[i].targetTrash.sprite.x) < 4 then
            customerPaws[i].grabbed = true
            local sellValue = customerPaws[i].targetTrash:Purchased()
            local xPos, yPos = customerPaws[i].targetTrash:getPosition()
            AddScoreBlinkerUI(xPos, yPos-24, sellValue)
            cashregister.score(sellValue)
        end

        if customerPaws[i].anim:ended() then
            customerPaws[i].sprite:remove()
            customerPaws[i].targetTrash.sprite:remove()
            table.remove(customerPaws, i)
        end
    end
end

function UpdateScoreUI()
    for i=#scoreBlinkers, 1, -1 do
        if scoreBlinkerAnim.on then
            gfx.setColor(gfx.kColorBlack)
            gfx.drawText(scoreBlinkers[i].score, scoreBlinkers[i].x, scoreBlinkers[i].y)
        end
        scoreBlinkers[i].ttl -= deltaTime
        scoreBlinkers[i].y -= 0.25
        if scoreBlinkers[i].ttl <= 0 then
            table.remove(scoreBlinkers, i)
        end
    end
end

function cQueue.GetCustomerCount()
    return #customerQueue
end