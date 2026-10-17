import "scripts/customer"
import "scripts/cQueue"

bus = {}

local customerdata <const> = assert(json.decodeFile("data/customerdata.json"))
bus.customers = {}
local busTimer = nil

function bus.Init()
    bus.customers = {customerdata["cat"], customerdata["dog"], customerdata["bunny"], customerdata["squirrel"]}
    busTimer = playdate.timer.performAfterDelay(2000, bus.FerryCustomers, 2)
    for i=1,2,1 do
        local startX = math.random(210, 260)
        local startY = math.random(58, 64)
        local newCustomer = cQueue.AddCustomerToQueue(Customer(bus.customers[math.random(1, #bus.customers)], startX, startY))
        newCustomer:setState(2)
        newCustomer:SetMoveTarget(startX, startY)
    end
end

function bus.FerryCustomers(n)
    cQueue.AddCustomerToQueue(Customer(bus.customers[math.random(1, #bus.customers)], -48, 64))
    for i=1, n-1, 1 do
        playdate.timer.performAfterDelay(i*500, cQueue.AddCustomerToQueue, Customer(bus.customers[math.random(1, #bus.customers)], -48, 64))
    end

    busTimer = playdate.timer.performAfterDelay(12500, bus.FerryCustomers, math.random(2, 4) + GetDifficultyLevel())
end

function bus.SampleRequestType()
    local r = math.random(1, #bus.customers)
    local want = bus.customers[r].wants
    if want == "" or want == nil then want = "default" end
    return want
end