cashregister = {}

local gfx <const> = playdate.graphics
local sfx <const> = playdate.sound

local scoreSFX = sfx.sampleplayer.new("audio/Cash Register Ding")

local money = 0

local mult = 1
local combo = false
local elapsedTime = 0

function cashregister.score(n)
    if not combo then 
        combo = true
        elapsedTime = 0
    else
        mult += 0.2
    end
    money += n*mult
    scoreSFX:play()
end

function cashregister.update()
    elapsedTime += deltaTime
    if elapsedTime > 3 then 
        combo = false
        mult = 1
    end
    gfx.drawText(mult, 120, 12)
end

function cashregister.GetMoney()
    return money
end