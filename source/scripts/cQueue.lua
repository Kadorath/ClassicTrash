import "scripts/store"
import "scripts/cashregister"
cQueue = {}

local gfx <const> = playdate.graphics

local customerQueue   = {}
local customerLeaving = {}
local queueRect = playdate.geometry.rect.new(180, 58, 112, 16)

local customerPawImg = gfx.image.new("images/Paw.png")
local customerPawImg_diagonal = gfx.image.new("images/Paw_diagonal.png")
local customerPaws = {}

local patience = 120

function cQueue.Init()
    patience = 120
    customerQueue   = {}
    customerLeaving = {}
    customerPaws = {}
end
function cQueue.update(trashInStore)
    local idx = 1
    while idx <= #customerQueue do
        local customer = customerQueue[idx]
        
        if customer.state == 2 then
            for i,trash in ipairs(trashInStore) do
                if trash.name == customer.request and trash.stage >= trash.minsellstage then
                    -- CustomerPurchase(i, trash, customer)
                    -- customer:setState(4)
                    break
                end
            end

            -- customer.patience -= 1
            -- if customer.patience <= 0 then
            --     CustomerStormOff(idx, customer)
            -- end
        end

        customer:update()

        if customer.state == 2 and customer.idleTime <= 0 then
            customer:setState(1)
            customer:SetMoveTarget(math.min(math.max(queueRect.x, customer.sprite.x+math.random(-25, 25)), queueRect.x+queueRect.w), 
                                   math.min(math.max(queueRect.y, customer.sprite.y+math.random(-25, 25)), queueRect.y+queueRect.h), 0.5)
        end

        if customer.state == 4 and customer.moveDir.x == 0 and customer.moveDir.y == 0 then
            customer:setState(5)
            break
        end
        if customer.state == 5 and customer.idleTime <= 0 then
            customer:setState(3)
            table.remove(customerQueue, idx)
            table.insert(customerLeaving, customer)
            customer:SetMoveTarget(432, 48, 1.5)
            break
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

    if #customerQueue == 0 then
        print("Customer queue emptied, immediately ferrying more customers")
        bus.FerryCustomers(math.random(3, 6))
    end

    -- Patience
    local crowdPenalty = cQueue.GetCrowdPenalty()
    patience -= deltaTime * crowdPenalty
    gfx.drawText(string.format("%d: %.1f", crowdPenalty, patience), 128, 224)

    if patience <= 0 then
        GameOver()
    end

    UpdateCustomerPaws()
end

function cQueue.AddCustomerToQueue(c)
    table.insert(customerQueue, c)
    print("Adding request: ", c.request)
    table.insert(truck.cRequests, c.request)
    c:SetMoveTarget(math.random(queueRect.x, queueRect.x+queueRect.w), 
                    math.random(queueRect.y, queueRect.y+queueRect.h))
    return c
end

function cQueue.OnGoalMet(size)
    local customersSentToPurchase = 0
    local customerClearCt = size < 3 and size or math.max(8, math.min(3, (#customerQueue/2)))
    for i=1, #customerQueue, 1 do
        local c = customerQueue[i]
        if c.state <= 2 then
            c:setState(4)
            customersSentToPurchase += 1
        end
        if customersSentToPurchase >= customerClearCt then
            break
        end
    end

    patience += 5*size
end

function cQueue.OnFullClear()
    patience += 20
end

function CustomerStormOff(idx, c)
    print("Customer "..idx.." stormed off")
    table.remove(customerQueue, idx)
    table.insert(customerLeaving, c)
    c:setState(3)
    c:SetMoveTarget(432, 48, 2)
end

-- Scoring is done in UpdateCustomerPaws, when the trash is grabbbed by the paw
function CustomerPurchase(idx, trash, c)
    print("CUSTOMER PURCHASE", idx, trash, c)
    store.RemoveTrashFromStore(trash.id, idx)
    AddPawSwiper(trash)

    for i,v in ipairs(truck.cRequests) do
        if v == trash.name then
            table.remove(truck.cRequests, i)
            break
        end
    end
end

function AddPawSwiper(trash)
    -- Initialize paw sprite
    local pawSpr = gfx.sprite.new(customerPawImg)
    pawSpr:setZIndex(RenderLayer.PAWS)

    -- Set up paw movement animator
    local targetX, targetY = trash:getPosition()
    local pawLine
    local r = math.random()
    if (r < 0.5) then
        if (targetX > 200) then
            pawLine = playdate.geometry.lineSegment.new(450, targetY, targetX, targetY)
        else
            pawLine = playdate.geometry.lineSegment.new(-50, targetY, targetX, targetY)
            pawSpr:setScale(-1,1)
        end
    else
        if (targetY > 145) then
            pawLine = playdate.geometry.lineSegment.new(targetX, 250, targetX, targetY)
            pawSpr:setRotation(90)
        else
            pawLine = playdate.geometry.lineSegment.new(targetX, -50, targetX, targetY)
            pawSpr:setRotation(270)

        end
    end
    pawSpr:setCenter(0, 0.5)
    local pawAnim = gfx.animator.new(600, pawLine, playdate.easingFunctions["inOutQuad"])
    pawAnim.reverses = true
    
    pawSpr:moveTo(-100, -100)
    pawSpr:add()
    table.insert(customerPaws, {sprite=pawSpr, anim=pawAnim, targetTrash=trash, grabbed=false})
end

function UpdateCustomerPaws()
    for i=#customerPaws, 1, -1 do
        customerPaws[i].sprite:moveTo(customerPaws[i].anim:currentValue())
        if customerPaws[i].grabbed then
            customerPaws[i].targetTrash.sprite:moveTo(customerPaws[i].sprite:getPosition())
            customerPaws[i].targetTrash:update()
        end
        local targetDistSqr = math.abs(customerPaws[i].sprite.x - customerPaws[i].targetTrash.sprite.x) 
                            + math.abs(customerPaws[i].sprite.y - customerPaws[i].targetTrash.sprite.y)
        if not customerPaws[i].grabbed and 
          targetDistSqr < 16 then
            customerPaws[i].grabbed = true
            customerPaws[i].targetTrash:setZIndex(RenderLayer.CTRASH)
            local sellValue, plus50s = customerPaws[i].targetTrash:Purchased()
            local xPos, yPos = customerPaws[i].targetTrash:getPosition()
            plus50s += cashregister.score(sellValue)
            for i=1, plus50s, 1 do
                cashregister.AddScoreBlinkerUI(xPos + math.random(-30,30), yPos+math.random(-10,5), 5)
            end
            cashregister.AddScoreBlinkerUI(xPos, yPos-24, sellValue)
        end

        if customerPaws[i].anim:ended() then
            customerPaws[i].sprite:remove()
            customerPaws[i].targetTrash:remove()
            table.remove(customerPaws, i)
        end
    end
end

function cQueue.GetCustomerCount()
    return #customerQueue
end

function cQueue.GetCrowdPenalty()
    local crowdPenalty = (math.floor(#customerQueue / 4)+1)
    if #customerQueue == 0 then crowdPenalty = 0 end
    return crowdPenalty
end