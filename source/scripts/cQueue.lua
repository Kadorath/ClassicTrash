import "scripts/store"
import "scripts/cashregister"
cQueue = {}

local gfx <const> = playdate.graphics

local customerQueue   = {}
local customerLeaving = {}
local queueRect = playdate.geometry.rect.new(180, 58, 112, 16)

local scoreBlinkerAnim = gfx.animation.blinker.new(400, 100, true)
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
                    customer:SetState(4)
                    break
                end
            end

            customer.patience -= 1
            if customer.patience <= 0 then
                CustomerStormOff(idx, customer)
            end
        end

        customer:update()

        if customer.state == 2 and customer.idleTime <= 0 then
            customer:SetState(1)
            customer:SetMoveTarget(math.min(math.max(queueRect.x, customer.sprite.x+math.random(-25, 25)), queueRect.x+queueRect.w), 
                                   math.min(math.max(queueRect.y, customer.sprite.y+math.random(-25, 25)), queueRect.y+queueRect.h), 0.5)
        end

        if customer.state == 4 and customer.moveDir.x == 0 and customer.moveDir.y == 0 then
            customer:SetState(5)
            break
        end
        if customer.state == 5 and customer.idleTime <= 0 then
            customer:SetState(3)
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

    UpdateCustomerPaws()
    UpdateScoreUI()

    -- gfx.drawRect(queueRect)
end

function cQueue.AddCustomerToQueue(c)
    table.insert(customerQueue, c)
    print("Adding request: ", c.request)
    table.insert(truck.cRequests, c.request)
    c:SetMoveTarget(math.random(queueRect.x, queueRect.x+queueRect.w), 
                    math.random(queueRect.y, queueRect.y+queueRect.h))
end

function CustomerStormOff(idx, c)
    print("Customer "..idx.." stormed off")
    table.remove(customerQueue, idx)
    table.insert(customerLeaving, c)
    c:SetState(3)
    c:SetMoveTarget(432, 48, 2)
end

-- Scoring is done in UpdateCustomerPaws, when the trash is grabbbed by the paw
function CustomerPurchase(idx, trash, c)
    store.RemoveTrashFromStore(trash.id, idx)
    AddPawSwiper(trash)

    for i,v in ipairs(truck.cRequests) do
        if v == trash.name then
            table.remove(truck.cRequests, i)
            break
        end
    end
end

local score500Img = gfx.image.new("images/ScoreUI/500")
local score1000Img = gfx.image.new("images/ScoreUI/1000")
local score1500Img = gfx.image.new("images/ScoreUI/1500")
local score2000Img = gfx.image.new("images/ScoreUI/2000")
local score50Img = gfx.image.new("images/ScoreUI/50")
local scoreImgs = { score500Img, score1000Img, score1500Img, score2000Img, score50Img }
function AddScoreBlinkerUI(xPos, yPos, v)
    local scoreImg = scoreImgs[v] or score50Img
    local blinkerSpr = gfx.sprite.new(scoreImg)
    blinkerSpr:setCenter(0.75,0.5)
    blinkerSpr:setZIndex(RenderLayer.HTRASH)
    blinkerSpr:add()
    local newBlinkerUI = {
        sprite = blinkerSpr,
        score = v,
        x = xPos,
        y = yPos,
        ttl = 1.5
    }
    table.insert(scoreBlinkers, newBlinkerUI)
end

function AddPawSwiper(trash)
    -- Initialize paw sprite
    local pawSpr = gfx.sprite.new(customerPawImg)
    pawSpr:setZIndex(RenderLayer.PAWS)
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
            customerPaws[i].targetTrash:update()
        end
        if not customerPaws[i].grabbed and 
          math.abs(customerPaws[i].sprite.x - customerPaws[i].targetTrash.sprite.x) < 4 then
            customerPaws[i].grabbed = true
            customerPaws[i].targetTrash:setZIndex(RenderLayer.CTRASH)
            local sellValue = customerPaws[i].targetTrash:Purchased()
            local xPos, yPos = customerPaws[i].targetTrash:getPosition()
            local plus50s = cashregister.score(sellValue)
            for i=1, plus50s, 1 do
                AddScoreBlinkerUI(xPos + math.random(-30,30), yPos+math.random(-10,5), 5)
            end
            AddScoreBlinkerUI(xPos, yPos-24, sellValue)
        end

        if customerPaws[i].anim:ended() then
            customerPaws[i].sprite:remove()
            customerPaws[i].targetTrash:remove()
            table.remove(customerPaws, i)
        end
    end
end

function UpdateScoreUI()
    for i=#scoreBlinkers, 1, -1 do
        scoreBlinkers[i].sprite:moveTo(scoreBlinkers[i].x, scoreBlinkers[i].y)
        scoreBlinkers[i].sprite:setVisible(scoreBlinkerAnim.on)
        scoreBlinkers[i].ttl -= deltaTime
        scoreBlinkers[i].y -= 0.25
        if scoreBlinkers[i].ttl <= 0 then
            scoreBlinkers[i].sprite:remove()
            table.remove(scoreBlinkers, i)
        end
    end
end

function cQueue.GetCustomerCount()
    return #customerQueue
end