import "scripts/customer"
import "scripts/cQueue"

bus = {}

local customerdata <const> = assert(json.decodeFile("data/customerdata.json"))

local busTimer = nil

function bus.Init()
    busTimer = playdate.timer.performAfterDelay(2000, bus.FerryCustomers, 2)
    for i=1,2,1 do
        local startX = math.random(210, 260)
        local startY = math.random(58, 64)
        local newCustomer = cQueue.AddCustomerToQueue(Customer(customerdata["rodent"], startX, startY))
        newCustomer:setState(2)
        newCustomer:SetMoveTarget(startX, startY)
    end
end

function bus.FerryCustomers(n)
    cQueue.AddCustomerToQueue(Customer(customerdata["rodent"], -48, 64))
    for i=1, n-1, 1 do
        playdate.timer.performAfterDelay(i*500, cQueue.AddCustomerToQueue, Customer(customerdata["rodent"], -48, 64))
    end

    busTimer = playdate.timer.performAfterDelay(12500, bus.FerryCustomers, math.random(2, 4) + GetDifficultyLevel())
end