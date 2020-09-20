--
-- Cultivator
-- Class for all cultivators
--
-- @author  Stefan Geiger (mailto:sgeiger@giants.ch)
-- @date  04/02/08

Cultivator = {};

function Cultivator:new(configFile, positionX, offsetY, positionZ, rotationY, customMt)

    if Cultivator_mt == nil then
        Cultivator_mt = Class(Cultivator, Implement);
    end;

    local mt = customMt;
    if mt == nil then
        mt = Cultivator_mt;
    end;
    local instance = Implement:new(configFile, positionX, offsetY, positionZ, rotationY, mt);

    local xmlFile = loadXMLFile("TempConfig", configFile);
    
    instance.drumNode = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, "vehicle.drum#index"));
    instance.drumRotationScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.drum#rotationScale"), 1);

    delete(xmlFile);

    instance.hasGroundContact = false;

    instance.speedViolationMaxTime = 2500;
    instance.speedViolationTimer = instance.speedViolationMaxTime;

    return instance;
end;

function Cultivator:delete()
    removeContactReport(self.rootNode);
    Cultivator:superClass().delete(self);
end;

function Cultivator:mouseEvent(posX, posY, isDown, isUp, button)
    Cultivator:superClass().mouseEvent(self, posX, posY, isDown, isUp, button);
end;

function Cultivator:keyEvent(unicode, sym, modifier, isDown)
    Cultivator:superClass().keyEvent(self, unicode, sym, modifier, isDown);
end;

function Cultivator:update(dt)

    if self.isAttached and self.hasGroundContact then
        for i=1, table.getn(self.cuttingAreas) do
            local x,y,z = getWorldTranslation(self.cuttingAreas[i].start);
            local x1,y1,z1 = getWorldTranslation(self.cuttingAreas[i].width);
            local x2,y2,z2 = getWorldTranslation(self.cuttingAreas[i].height);
            Utils.updateCultivatorArea(x, z, x1, z1, x2, z2); --, 0, 1.0, 1, 0.0);
            --Utils.updateGrassAt(x, z, x1, z1, x2, z2, 0.0);
            --Utils.updateWheatArea(x, z, x1, z1, x2, z2, 0.0);
        end;

        if self.attacherVehicle.lastSpeed*3600 > 20 then
            self.speedViolationTimer = self.speedViolationTimer - dt;
            if self.speedViolationTimer < 0 then
                self.attacherVehicle:detachImplementByObject(self);
            end;
        else
            self.speedViolationTimer = self.speedViolationMaxTime;
        end;
        
        if self.drumNode ~= nil then
            rotate(self.drumNode, self.drumRotationScale * self.attacherVehicle.lastSpeed * self.attacherVehicle.movingDirection, 0, 0);
        end;
    else
        self.speedViolationTimer = self.speedViolationMaxTime;
    end;

    _=[[for i=1, table.getn(self.wheels) do

        local x,y,z = getRotation(self.wheels[i].repr);
        if self.firstTimeRun then
            local newX, newY, newZ = getWheelShapePosition(self.wheels[i].node, self.wheels[i].wheelShape);
            setTranslation(self.wheels[i].repr, newX, newY, newZ);
            local axleSpeed = getWheelShapeAxleSpeed(self.wheels[i].node, self.wheels[i].wheelShape)*3.14159/180;
            x = x+axleSpeed*dt/1000.0;
            setRotation(self.wheels[i].repr, x, steeringAngle, z);
        end;
    end;]]

    Cultivator:superClass().update(self, dt);
end;

function Cultivator:draw()
    Cultivator:superClass().keyEvent(self);
    
    if math.abs(self.speedViolationTimer - self.speedViolationMaxTime) > 2 then
        g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), "1", InputBinding.getButtonKeyName(InputBinding.SPEED_LEVEL1)), 0.07+0.022, 0.019+0.029);
    end;
end;

function Cultivator:onAttach(attacherVehicle)
    Cultivator:superClass().onAttach(self, attacherVehicle);

    addContactReport(self.rootNode, "groundContactReport", self);
end;

function Cultivator:onDetach()
    Cultivator:superClass().onDetach(self);
    
    self.speedViolationTimer = self.speedViolationMaxTime;

    removeContactReport(self.rootNode);
end;

function Cultivator:onActivate()
    Cultivator:superClass().onActivate(self);
end;

function Cultivator:onDeactivate()
    Cultivator:superClass().onDeactivate(self);
end;

function Cultivator:groundContactReport(objectId, otherObjectId, isStart, normalForce, tangentialForce)

    if otherObjectId == g_currentMission.terrainRootNode then
        self.hasGroundContact = normalForce > 0 or tangentialForce > 0;
    end;

end;
