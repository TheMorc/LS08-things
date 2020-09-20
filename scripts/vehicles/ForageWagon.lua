--
-- ForageWagon
-- Class for all ForageWagons
--
-- @author  Stefan Geiger (mailto:sgeiger@giants.ch)
-- @date  25/06/08

ForageWagon = {};

function ForageWagon:new(configFile, positionX, offsetY, positionZ, rotationY, customMt)

    if ForageWagon_mt == nil then
        ForageWagon_mt = Class(ForageWagon, Trailer);
    end;

    local mt = customMt;
    if mt == nil then
        mt = ForageWagon_mt;
    end;
    local instance = Trailer:new(configFile, positionX, offsetY, positionZ, rotationY, mt);

    local xmlFile = loadXMLFile("TempConfig", configFile);

    instance.fillScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.fillScale#value"), 1);

    delete(xmlFile);

    --instance.wasToFast = false;

    return instance;
end;

function ForageWagon:delete()
    Trailer.delete(self);
end;

function ForageWagon:mouseEvent(posX, posY, isDown, isUp, button)
    Trailer.mouseEvent(self, posX, posY, isDown, isUp, button);
end;

function ForageWagon:keyEvent(unicode, sym, modifier, isDown)
    Trailer.keyEvent(self, unicode, sym, modifier, isDown);
end;

function ForageWagon:update(dt)

    --self.wasToFast = false;
    if self.attacherVehicle ~= nil and self:allowFillType(Trailer.FILLTYPE_GRASS) and self.capacity > self.fillLevel then
        --local toFast = self.attacherVehicle.lastSpeed*3600 > 29;
        --if not toFast then
            for i=1, table.getn(self.cuttingAreas) do
                local x,y,z = getWorldTranslation(self.cuttingAreas[i].start);
                local x1,y1,z1 = getWorldTranslation(self.cuttingAreas[i].width);
                local x2,y2,z2 = getWorldTranslation(self.cuttingAreas[i].height);

                local area = Utils.updateCuttedMeadowArea(x, z, x1, z1, x2, z2);

                local literPerPixel = 8000/1200 / 6 / (2*2) *12;

                local deltaLevel = area * literPerPixel * self.fillScale;

                self:setFillLevel(self.fillLevel+deltaLevel, Trailer.FILLTYPE_GRASS);
            end;
        --end;
        --self.wasToFast = toFast;
    end;

    Trailer.update(self, dt);
end;

function ForageWagon:draw()
    Trailer.draw(self);

    --if self.wasToFast then
    --    g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), "2", InputBinding.getButtonKeyName(InputBinding.SPEED_LEVEL1)), 0.07+0.022, 0.019+0.029);
    --end;
end;


function ForageWagon:onDetach()
    Trailer.onDetach(self);

    self.wasToFast = false;
end;

