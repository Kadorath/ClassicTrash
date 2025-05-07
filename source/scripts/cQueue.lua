import "scripts/store"

cQueue = {}

local gfx <const> = playdate.graphics

local customerQueue   = {}
local customerLeaving = {}
local queueRect = playdate.geometry.rect.new(98, 58, 212, 16) 

function cQueue.update(trashInStore)
    local idx = 1
    while idx <= #customerQueue do
        local customer = customerQueue[idx]
        
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

        customer:update()

        if customer.moveDir.dx == 0 and customer.moveDir.dy == 0 then
            print(queueRect.x, queueRect.x+queueRect.w, queueRect.x, queueRect.y+queueRect.h)
            customer:SetMoveTarget(math.random(queueRect.x, queueRect.x+queueRect.w), 
                                   math.random(queueRect.y, queueRect.y+queueRect.h))
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
    c:SetMoveTarget(212, 64)
end

function CustomerStormOff(idx, c)
    print("Customer "..idx.." stormed off")
    table.remove(customerQueue, idx)
    table.insert(customerLeaving, c)
    c:SetMoveTarget(432, 48)
end

function CustomerPurchase(idx, trash, c)
    store.RemoveTrashFromStore(trash.id, idx)
    trash:remove()
    table.insert(customerLeaving, c)
    c:SetMoveTarget(432, 48)
    money += 4
end

function cQueue.GetCustomerCount()
    return #customerQueue
end