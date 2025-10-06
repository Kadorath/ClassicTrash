cashregister = {}

local gfx <const> = playdate.graphics
local sfx <const> = playdate.sound

local scoreSFX = sfx.sampleplayer.new("audio/Cash Register Ding")
local bonusSFX = sfx.sampleplayer.new("audio/Scoreblip")

local money = 0

local mult = 0
local combo = false
local elapsedTime = 0

function cashregister.score(n)
    money += 500*n + 50*mult
    scoreSFX:play()
    if mult > 0 then
        bonusSFX:setRate(1.0 + 0.2*(mult-1))
        bonusSFX:play()    
    end

    local oldMult = mult
    if not combo then 
        combo = true
        elapsedTime = 0
        mult = 1
    else
        mult += 1
    end

    return oldMult
end

function cashregister.update()
    elapsedTime += deltaTime
    if elapsedTime > 3 then 
        combo = false
        mult = 0
    end
    -- gfx.drawText(mult, 120, 12)
end

function cashregister.GetMoney()
    return money
end