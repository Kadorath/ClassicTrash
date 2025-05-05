import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/math"
import "CoreLibs/crank"

import "scripts/player"
import "scripts/conveyor"
import "scripts/store"

import "scripts/thebus"
import "scripts/thetruck"

local gfx <const> = playdate.graphics

local customerQueue = {}

function GameStart()
    truck.Init()
    bus.Init()
end

function playdate.update()
    gfx.sprite.update()
    player.update()
    conveyor.update()
    store.update()
    incinerator.update()

    playdate.timer.updateTimers()
end

GameStart()

local testBG = gfx.sprite.new(gfx.image.new("images/TrialBG1"))
testBG:setCenter(0,0)
testBG:moveTo(0,0)
testBG:setZIndex(-1)
testBG:add()