cashregister = {}

local gfx <const> = playdate.graphics
local sfx <const> = playdate.sound

local scoreSFX = sfx.sampleplayer.new("audio/Cash Register Ding")
local bonusSFX = sfx.sampleplayer.new("audio/Scoreblip")

local money = 0

local bonus = 0
local bonusFalloffTime = 4
local combo = false
local elapsedTime = bonusFalloffTime

function cashregister.Init()
    money = 0
    bonus = 0
    elapsedTime = bonusFalloffTime
    combo = false
end

function cashregister.score(n)
    money += 500*n + 50*bonus
    scoreSFX:play()
    if bonus > 0 then
        bonusSFX:setRate(1.0 + 0.2*(bonus-1))
        bonusSFX:play()    
    end

    return bonus
end

function cashregister.PlusBonus()
    if not combo then 
        combo = true
        bonusFalloffTime = 4
        elapsedTime = 0
        bonus = 1
    else
        bonus += 1
        bonusFalloffTime = 4
        elapsedTime = 0
    end

end

function cashregister.update()
    elapsedTime += deltaTime
    if combo and elapsedTime > bonusFalloffTime then 
        bonus -= 1
        bonusFalloffTime = math.max(1, bonusFalloffTime - 1)
        fastDecay = true
        elapsedTime = 0
        if bonus <= 0 then
            elapsedTime = bonusFalloffTime
            bonus = 0
            combo = false
        end
    end

    UpdateScoreUI()
    gfx.drawText(bonus, 200, 224)
    gfx.setColor(gfx.kColorBlack)
    local bonusBarRect = playdate.geometry.rect.new(216, 226, 80, 12)
    gfx.drawRect(bonusBarRect)
    bonusBarRect:inset(2, 2)
    bonusBarRect.width = math.max(0, 76 * (1 - elapsedTime / bonusFalloffTime))
    gfx.fillRect(bonusBarRect)
end

function cashregister.GetMoney()
    return money
end


local scoreBlinkerAnim = gfx.animation.blinker.new(500, 150, true)
scoreBlinkerAnim:start()
local scoreBlinkers = {}

local score500Img = gfx.image.new("images/ScoreUI/500")
local score1000Img = gfx.image.new("images/ScoreUI/1000")
local score1500Img = gfx.image.new("images/ScoreUI/1500")
local score2000Img = gfx.image.new("images/ScoreUI/2000")
local score50Img = gfx.image.new("images/ScoreUI/50")
local scoreImgs = { score500Img, score1000Img, score1500Img, score2000Img, score50Img }
function cashregister.AddScoreBlinkerUI(xPos, yPos, v)
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
        ttl = 1.25
    }
    table.insert(scoreBlinkers, newBlinkerUI)
end

function UpdateScoreUI()
    for i=#scoreBlinkers, 1, -1 do
        scoreBlinkers[i].sprite:moveTo(scoreBlinkers[i].x, scoreBlinkers[i].y)
        if (scoreBlinkers[i].score == 5) then
            scoreBlinkers[i].sprite:setVisible(scoreBlinkerAnim.on)
        end
        scoreBlinkers[i].ttl -= deltaTime
        scoreBlinkers[i].y -= 0.25
        if scoreBlinkers[i].ttl <= 0 then
            scoreBlinkers[i].sprite:remove()
            table.remove(scoreBlinkers, i)
        end
    end
end