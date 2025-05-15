import "scripts/store"
import "scripts/cashregister"
cQueue = {}

local gfx <const> = playdate.graphics

local customerQueue   = {}
local customerLeaving = {}
local queueRect = playdate.geometry.rect.new(98, 58, 212, 16) 

function cQueue.update(trashInStore)
    local idx = 1
    while idx <= #customerQueue do
        local customer = customerQueue[idx]
        
        if customer.state == 2 then
            for i,trash in ipairs(trashInStore) do
                if trash.name == customer.request then
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

    gfx.drawRect(queueRect)
end

function cQueue.AddCustomerToQueue(c)
    table.insert(customerQueue, c)
    c:SetMoveTarget(212, 64, 2)
end

function CustomerStormOff(idx, c)
    print("Customer "..idx.." stormed off")
    table.remove(customerQueue, idx)
    table.insert(customerLeaving, c)
    c:SetMoveTarget(432, 48, 2)
end

function CustomerPurchase(idx, trash, c)
    store.RemoveTrashFromStore(trash.id, idx)
    trash:Purchased()
    trash:remove()
    table.insert(customerLeaving, c)
    c:SetMoveTarget(432, 48, 2)
    c:SetState(3)

    cashregister.score(4)
end

function cQueue.GetCustomerCount()
    return #customerQueue
end