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
import "scripts/cQueue"

local gfx <const> = playdate.graphics
local sfx <const> = playdate.sound
-- Sound
local landfillAmb = sfx.sampleplayer.new("audio/Ambience Landfill")
local gameplayBGM = sfx.sampleplayer.new("audio/inmytrash")

-- STRASH = Store Trash
-- CTRASH = Customer Trash
-- BTRASH = Backing Trash
-- FTRASH = Falling Trash
-- HTRASH = Held Trash
RenderLayer = {
    BG = 0,
    GRID = 1,
    STRASH = 2,
    CTRASH = 3,
    PAWS = 4,
    BACKING = 5,
    BTRASH = 6,
    BORDERS = 7,
    FTRASH = 8,
    HTRASH = 9,
    PLAYER = 10,
}

local gridSpr = gfx.sprite.new(gfx.image.new('images/BGs/griddots'))
gridSpr:setCenter(0,0)
gridSpr:moveTo(0,0)
gridSpr:setZIndex(RenderLayer.GRID)

local storeBG = gfx.sprite.new(gfx.image.new("images/BGs/storeBG"))
storeBG:setCenter(0,0)
storeBG:moveTo(0,0)
storeBG:setZIndex(RenderLayer.BG)

local beltBG = gfx.sprite.new(gfx.image.new("images/BGs/beltBG"))
beltBG:setCenter(0,0)
beltBG:moveTo(0,0)
beltBG:setZIndex(RenderLayer.BACKING)

local bordersBG = gfx.sprite.new(gfx.image.new("images/BGs/bordersBG"))
bordersBG:setCenter(0,0)
bordersBG:moveTo(0,0)
bordersBG:setZIndex(RenderLayer.BORDERS)

local startmenuBG = gfx.sprite.new(gfx.image.new("images/BGs/startmenuBG"))
startmenuBG:setCenter(0,0)
startmenuBG:moveTo(0,0)
startmenuBG:setZIndex(-1)
startmenuBG:add()

deltaTime = 0

gameState = 1

gameTime = 0

function GameStart()
    cQueue.Init()
    bus.Init()
    store.Init()
    conveyor.Init()
    player.Init()
    cashregister.Init()
    startmenuBG:remove()
    storeBG:add()
    beltBG:add()
    bordersBG:add()
    gridSpr:add()
    gameState = 2
    gameTime = 0

    landfillAmb:play(0)
    gameplayBGM:play(0)
end

function GameOver()
    gameState = 3
    gfx.sprite.removeAll()
end

function playdate.update()
    deltaTime = playdate.getElapsedTime()
    playdate.resetElapsedTime()
    gfx.animation.blinker.updateAll()
    gfx.sprite.update()

    if gameState == 1 then
        if playdate.buttonJustPressed(playdate.kButtonA) then
            GameStart()
        end
    elseif gameState == 2 then
        gameTime += deltaTime
        player.update()
        conveyor.update()
        store.update()
        incinerator.update()
        cashregister.update()
    elseif gameState == 3 then
        gfx.setColor(gfx.kColorBlack)
        gfx.drawTextAligned("Game over!", 200, 90, kTextAlignment.center)
        gfx.drawTextAligned(string.format("score: %i", cashregister.GetMoney()), 200, 112, kTextAlignment.center)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            GameStart()
        end
    end

    if gameState == 2 then
        gfx.drawText(cashregister.GetMoney(), 72, 224)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(330, 2, 50, 16)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawText(string.format("%.2f", gameTime), 340, 4)
    end

    playdate.timer.updateTimers()
end

function GetDifficultyLevel()
    return math.floor(gameTime/60)
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