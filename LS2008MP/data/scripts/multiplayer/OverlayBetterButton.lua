--OverlayBetterButton (used as a replacement for OverlayButton)
--this button thingy has support for arguments a nice thing to have if you want to simplify things
--@author: Richard Gráčik
--@date: 17.1.2021

OverlayBetterButton = {}
local OverlayBetterButton_mt = Class(OverlayBetterButton)

function OverlayBetterButton:new(overlay, onClick, argument)
    return setmetatable( {overlay=overlay, onClick=onClick, argument=argument}, OverlayBetterButton_mt)
end

function OverlayBetterButton:delete()
    self.overlay:delete()
end

function OverlayBetterButton:mouseEvent(posX, posY, isDown, isUp, button)

    if checkOverlayOverlap(posX, posY, self.overlay) then
        self.overlay:setColor(1.0, 1.0, 1.0, 1.0)

        if isDown and button == Input.MOUSE_BUTTON_LEFT and self.onClick ~= nil then
            self.onClick(self.argument)
        end

    else
        self:reset()
    end
end

function OverlayBetterButton:render()
    self.overlay:render()
end

function OverlayBetterButton:reset()
    self.overlay:setColor(1.0, 1.0, 1.0, 0.85)
end