import "CoreLibs/ui"

local gfx <const> = playdate.graphics
local sfx <const> = playdate.sound

mainmenu = {}

local startmenuBG = gfx.sprite.new(gfx.image.new("images/BGs/startmenuBG"))
startmenuBG:setCenter(0,0)
startmenuBG:moveTo(0,0)
startmenuBG:setZIndex(-1)

local menuRect = playdate.geometry.rect.new(23, 130, 150, 104)
local menuImg = gfx.image.new(menuRect.width, menuRect.height)
local menuSpr = gfx.sprite.new(menuImg)
local menuOptionTitles = {"Start", "Options", "Exit"}
local menuOptions = {
    [menuOptionTitles[1]] = function() GameStart() end, 
    [menuOptionTitles[2]] = function() print("Not Implemented") end, 
    [menuOptionTitles[3]] = function() playdate.exitToLauncher() end 
}
local menuview = playdate.ui.gridview.new(0, 24)
menuview:setNumberOfRows(#menuOptionTitles)
menuview:setCellPadding(0, 0, 0, 8)
menuview:setContentInset(4, 4, 4, 4)
function menuview:drawCell(section, row, column, selected, x, y, width, height)
    gfx.setColor(gfx.kColorBlack)
    if selected then
        gfx.fillRect(x, y, width, height)
    else
        gfx.drawRect(x, y, width, height)
    end

    gfx.setImageDrawMode(gfx.kDrawModeNXOR)
    gfx.drawTextAligned(menuOptionTitles[row], x+width/2, y+2, kTextAlignment.center)
end

menuSpr:setCenter(0, 0)
menuSpr:moveTo(menuRect.x, menuRect.y)

function mainmenu.Open()
    startmenuBG:add()
    menuSpr:add()
    menuview.needsDisplay = true
end

function mainmenu.Close()
    startmenuBG:remove()
    menuSpr:remove()
end

function mainmenu.update()
    if menuview.needsDisplay then
        gfx.lockFocus(menuImg)
        gfx.clear()
        menuview:drawInRect(0, 0, menuImg:getSize())
        gfx.unlockFocus()
    end

    if playdate.buttonJustPressed(playdate.kButtonDown) then
        menuview:selectNextRow(true)
    end
    if playdate.buttonJustPressed(playdate.kButtonUp) then
        menuview:selectPreviousRow(true)
    end

    if playdate.buttonJustPressed(playdate.kButtonA) then
        local menuSelection = menuview:getSelectedRow()
        
        local responseFn = menuOptions[menuOptionTitles[menuSelection]]
        if responseFn then responseFn() end
    end
end