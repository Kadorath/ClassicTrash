import "scripts/customer"
import "scripts/cQueue"

bus = {}

local customerdata <const> = assert(json.decodeFile("data/customerdata.json"))

local busTimer = nil

function bus.Init()
    busTimer = playdate.timer.performAfterDelay(1, bus.FerryCustomers, 1)
end

function bus.FerryCustomers(n)
    for i=1, n, 1 do
        print(i)
        cQueue.AddCustomerToQueue(Customer(customerdata["rodent"], -48, 64))
    end

    busTimer = playdate.timer.performAfterDelay(7500, bus.FerryCustomers, math.random(2))
end