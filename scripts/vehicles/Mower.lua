--
-- Mower
-- Class for all mowers
--
-- @author  Stefan Geiger (mailto:sgeiger@giants.ch)
-- @date  11/05/08

Mower = {};

function Mower:new(configFile, positionX, offsetY, positionZ, rotationY, customMt)

    if Mower_mt == nil then
        Mower_mt = Class(Mower, Implement);
    end;

    local mt = customMt;
    if mt == nil then
        mt = Mower_mt;
    end;
    local instance = Implement:new(configFile, positionX, offsetY, positionZ, rotationY, mt);

    --local xmlFile = loadXMLFile("TempConfig", configFile);
    --delete(xmlFile);

    instance.isActive = false;
    instance.wasToFast = false;

    return instance;
end;

function Mower:delete()
    Implement.delete(self);
end;

function Mower:mouseEvent(posX, posY, isDown, isUp, button)
    Implement.mouseEvent(self, posX, posY, isDown, isUp, button);
end;

function Mower:keyEvent(unicode, sym, modifier, isDown)
    Implement.keyEvent(self, unicode, sym, modifier, isDown);
end;

function Mower:update(dt)

    if self.isAttached and self.isSelected then
        if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
            self.isActive = not self.isActive;
        end;
    end;

    self.wasToFast = false;
    self.noForageWagon = false;
    if self.isAttached and self.isActive then
        local isLowered = false;
        local implement = self.attacherVehicle:getImplementByObject(self)
        if implement ~= nil and self.attacherVehicle.attacherJoints[implement.jointDescIndex].moveDown then
            isLowered = true;
        end;
        if isLowered then
            local toFast = self.attacherVehicle.lastSpeed*3600 > 31;
            if not toFast then
                --if self.attacherVehicle.attachedTrailer == nil or not self.attacherVehicle.attachedTrailer:allowFillType(Trailer.FILLTYPE_GRASS) then
                --    self.noForageWagon = true;
                --else
                    for i=1, table.getn(self.cuttingAreas) do
                        local x,y,z = getWorldTranslation(self.cuttingAreas[i].start);
                        local x1,y1,z1 = getWorldTranslation(self.cuttingAreas[i].width);
                        local x2,y2,z2 = getWorldTranslation(self.cuttingAreas[i].height);

                        local cutted1, cutted2, cutted3 = Utils.updateMeadowArea(x, z, x1, z1, x2, z2);

                        -- growth states, area, cutted1, cutted2, cutted3
                        --0 1000
                        --1 1100
                        --2 1010
                        --3 1110
                        --4 1001
                        -- count cutted3 4times, cutted2 2times and cutted1 once ((this counts state 4 most and ignores state 0)
                        --local averagedState = cutted1 + 2 * cutted2 + 4*cutted3;

                        --local literPerPixel = 8000/1200 / 6 / (2*2) *4;

                        --local deltaLevel = averagedState * literPerPixel * self.fillScale;

                        --self.attacherVehicle.attachedTrailer:setFillLevel(self.attacherVehicle.attachedTrailer.fillLevel+deltaLevel, Trailer.FILLTYPE_GRASS);
                    end;
                --end;
            end;
            self.wasToFast = toFast;
        end;
    end;

    Implement.update(self, dt);
end;

function Mower:draw()
    Implement.draw(self);

    if self.isActive then
        g_currentMission:addHelpButtonText(g_i18n:getText("Turn_off_mower"), InputBinding.IMPLEMENT_EXTRA);
    else
        g_currentMission:addHelpButtonText(g_i18n:getText("Turn_on_mower"), InputBinding.IMPLEMENT_EXTRA);
    end;

    if self.wasToFast then
        g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), "2", InputBinding.getButtonKeyName(InputBinding.SPEED_LEVEL2)), 0.07+0.022, 0.019+0.029);
    end;
end;


function Mower:onDetach()
    Implement.onDetach(self);

    self.wasToFast = false;
    self.noForageWagon = false;
end;

