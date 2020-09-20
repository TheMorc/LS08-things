--
-- Overlay based GUI (see http://gdn.giants.ch for further details)
--
-- @author  Christian Ammann (mailto:cammann@giants.ch)
-- @date  30/12/06


function checkOverlayOverlap(posX, posY, overlay)
    return posX >= overlay.x and posX <= overlay.x+overlay.width and posY >= overlay.y and posY <= overlay.y+overlay.height;
end;

OverlayMenu = {};

local OverlayMenu_mt = Class(OverlayMenu);

function OverlayMenu:new()
    return setmetatable({items = {}}, OverlayMenu_mt);
end;

function OverlayMenu:addItem(item)
    table.insert(self.items, item);
end;

function OverlayMenu:mouseEvent(posX, posY, isDown, isUp, button)
    for i=1, table.getn(self.items) do
        self.items[i]:mouseEvent(posX, posY, isDown, isUp, button);
    end;
end;

function OverlayMenu:reset()
    for i=1, table.getn(self.items) do
        self.items[i]:reset();
    end;    
end;

function OverlayMenu:keyEvent(unicode, sym, modifier, isDown)
end;

function OverlayMenu:update(dt)
end;

function OverlayMenu:render()
    for i=1, table.getn(self.items) do
        self.items[i]:render();
    end;
end;


Overlay = {};
local Overlay_mt = Class(Overlay);

function Overlay:new(name, overlayFilename, x, y, width, height)
    if overlayFilename ~= nil then
        tempOverlayId = createOverlay(name, overlayFilename);
    end;
    return setmetatable( {overlayId=tempOverlayId, x=x, y=y, width=width, height=height, visible=true, r=1.0, g=1.0, b=1.0, a=1.0}, Overlay_mt);
end;

function Overlay:delete()
    if self.overlayId ~= nil then
        delete(self.overlayId);
    end;
end;

function Overlay:setColor(r, g, b, a)
    self.r, self.g, self.b, self.a = r, g, b, a;
end;

function Overlay:setPosition(x, y)
    self.x = x;
    self.y = y;
end;

function Overlay:setDimension(width, height)
    self.width = width;
    self.height = height;
end;

function Overlay:mouseEvent(posX, posY, isDown, isUp, button)

end;

function Overlay:render()
    if self.visible then
        setOverlayColor(self.overlayId, self.r, self.g, self.b, self.a);
        renderOverlay(self.overlayId, self.x, self.y, self.width, self.height);
    end;
end;

function Overlay:reset()

end;

function Overlay:setIsVisible(visible)
    self.visible = visible;
end;



OverlayButton = {};
local OverlayButton_mt = Class(OverlayButton);

function OverlayButton:new(overlay, onClick)
    return setmetatable( {overlay=overlay, onClick=onClick}, OverlayButton_mt);
end;

function OverlayButton:delete()
    self.overlay:delete();
end;

function OverlayButton:mouseEvent(posX, posY, isDown, isUp, button)

    if checkOverlayOverlap(posX, posY, self.overlay) then
        self.overlay:setColor(1.0, 1.0, 1.0, 1.0);

        if isDown and button == Input.MOUSE_BUTTON_LEFT and self.onClick ~= nil then
            self.onClick();
        end;

    else
        self:reset();
    end;

end;

function OverlayButton:render()
    self.overlay:render();
end;

function OverlayButton:reset()
    self.overlay:setColor(1.0, 1.0, 1.0, 0.85);
end;

OverlayCheckbox = {};
local OverlayCheckbox_mt = Class(OverlayCheckbox);

function OverlayCheckbox:new(overlayOn, overlayOff, state, onClick)
    overlayOn:setIsVisible(state);
    overlayOff:setIsVisible(not state);
    return setmetatable( {overlayOn=overlayOn, overlayOff=overlayOff, state=state, onClick=onClick}, OverlayCheckbox_mt);
end;

function OverlayCheckbox:mouseEvent(posX, posY, isDown, isUp, button)

    if checkOverlayOverlap(posX, posY, self.overlayOn) or checkOverlayOverlap(posX, posY, self.overlayOff) then

        self.overlayOn:setColor(1.0, 1.0, 1.0, 1.0)
        self.overlayOff:setColor(1.0, 1.0, 1.0, 1.0)
        
        if isDown and button == Input.MOUSE_BUTTON_LEFT then
            self.state = not self.state;
            self.onClick(self.state);

            if self.state then
                self.overlayOn:setIsVisible(true);
                self.overlayOff:setIsVisible(false);
            else
                self.overlayOn:setIsVisible(false);
                self.overlayOff:setIsVisible(true);
            end;
            
        end;

    else
        self:reset();
    end;

end;

function OverlayCheckbox:render()
    self.overlayOn:render();
    self.overlayOff:render();
end;

function OverlayCheckbox:reset()
    self.overlayOn:setColor(1.0, 1.0, 1.0, 0.6);
    self.overlayOff:setColor(1.0, 1.0, 1.0, 0.6);
end;

function OverlayCheckbox:setState(state)
    self.state = state;
    self.overlayOn:setIsVisible(state);
    self.overlayOff:setIsVisible(not state);
end;

OverlayMultiTextOption = {};
local OverlayMultiTextOption_mt = Class(OverlayMultiTextOption);

function OverlayMultiTextOption:new(overlayMultiText, buttonDown, buttonUp, x, y, s, state, onClick)
    return setmetatable( {overlayMultiText=overlayMultiText, buttonDown=buttonDown, buttonUp=buttonUp, x=x, y=y, s=s, state=state, onClick=onClick}, OverlayMultiTextOption_mt);
end;

function OverlayMultiTextOption:mouseEvent(posX, posY, isDown, isUp, button)

    self.buttonDown:mouseEvent(posX, posY, isDown, isUp, button);
    self.buttonUp:mouseEvent(posX, posY, isDown, isUp, button);

    if isDown and button == Input.MOUSE_BUTTON_LEFT then
        
        local oldState = self.state;
        
        if checkOverlayOverlap(posX, posY, self.buttonDown.overlay) then
            self.state = self.state-1;
            if self.state <= 0 then
                self.state = 1;
            end;
        end;
        
        if checkOverlayOverlap(posX, posY, self.buttonUp.overlay) then
            self.state = self.state+1;
            if self.state > table.getn(self.overlayMultiText) then
            	self.state = table.getn(self.overlayMultiText);
            end;
        end;

        --print(self.state, " ", self.overlayMultiText[self.state]);
    
        if self.onClick ~= nil and oldState ~= self.state then
            self.onClick(self.state);
        end;
    end;

end;

function OverlayMultiTextOption:render()
    self.buttonDown:render();
    self.buttonUp:render();
    setTextBold(true);
    renderText(self.x, self.y, self.s, self.overlayMultiText[self.state]);
    setTextBold(false);
end;

function OverlayMultiTextOption:reset()
    self.buttonDown:reset();
    self.buttonUp:reset();
end;
