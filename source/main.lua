import "CoreLibs/graphics"
import "CoreLibs/animation"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/math"
import "CoreLibs/crank"

import "scripts/player"
import "scripts/conveyor"
import "scripts/store"

import "scripts/thebus"
import "scripts/thetruck"
import "scripts/cashregister"

local gfx <const> = playdate.graphics
local sfx <const> = playdate.sound
-- Sound
local landfillAmb = sfx.sampleplayer.new("audio/Ambience Landfill")

local storeBG = gfx.sprite.new(gfx.image.new("images/BGs/storeBG"))
storeBG:setCenter(0,0)
storeBG:moveTo(0,0)
storeBG:setZIndex(0)

local beltBG = gfx.sprite.new(gfx.image.new("images/BGs/beltBG"))
beltBG:setCenter(0,0)
beltBG:moveTo(0,18)
beltBG:setZIndex(1)

local bordersBG = gfx.sprite.new(gfx.image.new("images/BGs/bordersBG"))
bordersBG:setCenter(0,0)
bordersBG:moveTo(0,0)
bordersBG:setZIndex(4)

local startmenuBG = gfx.sprite.new(gfx.image.new("images/BGs/startmenuBG"))
startmenuBG:setCenter(0,0)
startmenuBG:moveTo(0,0)
startmenuBG:setZIndex(-1)
startmenuBG:add()

deltaTime = 0

gameState = 1

function GameStart()
    truck.Init()
    bus.Init()
    startmenuBG:remove()
    storeBG:add()
    beltBG:add()
    bordersBG:add()
    gameState = 2

    landfillAmb:play(0)
end

function playdate.update()
    deltaTime = playdate.getElapsedTime()
    
    gfx.animation.blinker.updateAll()
    gfx.sprite.update()

    if gameState == 1 then
        if playdate.buttonJustPressed(playdate.kButtonA) then
            GameStart()
        end
    elseif gameState == 2 then
        player.update()
        conveyor.update()
        store.update()
        incinerator.update()
        cashregister.update()
    end

    if gameState == 2 then
        gfx.drawText(cashregister.GetMoney(), 72, 224)
    end

    playdate.timer.updateTimers()

    playdate.resetElapsedTime()
end

-- Credit: https://stackoverflow.com/a/26367080
function copy(obj, seen)
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
    return res
end