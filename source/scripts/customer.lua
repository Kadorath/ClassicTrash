import "CoreLibs/object"

local gfx <const> = playdate.graphics

local nextTrashID = 1

class("Customer").extends()

function Customer:init(data)
    self.name = data["name"]
    self.img = gfx.image.new("images/Customers/"..data["img"])
    self.sprite = gfx.sprite.new(self.img)
    self.request = data["wants"][math.random(#data["wants"])]
    print(self.request)
    self.patience = data["patience"]
end