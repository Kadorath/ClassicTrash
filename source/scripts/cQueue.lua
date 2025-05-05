import "scripts/store"

cQueue = {}

local customerQueue = {}

function cQueue.update(trashInStore)
    local idx = 1
    while idx <= #customerQueue do
        local customer = customerQueue[idx]
        
        for i,trash in ipairs(trashInStore) do
            if trash.name == customer.request then
                CustomerPurchase(i, trash, c)
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

        idx += 1
    end
end

function cQueue.AddCustomerToQueue(c)
    table.insert(customerQueue, c)
end

function CustomerStormOff(idx, c)
    print("Customer "..idx.." stormed off")
    table.remove(customerQueue, idx)
end

function CustomerPurchase(idx, trash, c)
    store.RemoveTrashFromStore(trash.id, idx)
    trash:remove()
end

function cQueue.GetCustomerCount()
    return #customerQueue
end