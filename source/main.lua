import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/math"
import "CoreLibs/crank"

import "scripts/player"
import "scripts/conveyor"
import "scripts/store"
import "scripts/trash"

local gfx <const> = playdate.graphics

local test = Trash("testtrash", "trash1")

function playdate.update()
    gfx.sprite.update()
    player.update()
    conveyor.update()
    store.update()

    playdate.timer.updateTimers()
end

function Dump()
    local newTrash = Trash("testtrash", "ibeam")
    conveyor.AddToBelt(newTrash)
    playdate.timer.performAfterDelay(1000, Dump)
end

playdate.timer.performAfterDelay(1000, Dump)
