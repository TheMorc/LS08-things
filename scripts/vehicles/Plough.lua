--
-- Plough
-- Class for all ploughs
--
-- @author  Stefan Geiger (mailto:sgeiger@giants.ch)
-- @date  04/02/08

Plough = {};

function Plough:new(configFile, positionX, offsetY, positionZ, rotationY, customMt)

    if Plough_mt == nil then
        Plough_mt = Class(Plough, Implement);
    end;

    local mt = customMt;
    if mt == nil then
        mt = Plough_mt;
    end;
    local instance = Implement:new(configFile, positionX, offsetY, positionZ, rotationY, mt);

    local xmlFile = loadXMLFile("TempConfig", configFile);

    local rotationPartNode = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, "vehicle.rotationPart#index"));
    if rotationPartNode ~= nil then
        instance.rotationPart = {};
        instance.rotationPart.node = rotationPartNode;
        local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, "vehicle.rotationPart#minRot"));
        instance.rotationPart.minRot = {};
        instance.rotationPart.minRot[1] = Utils.degToRad(Utils.getNoNil(x, 0));
        instance.rotationPart.minRot[2] = Utils.degToRad(Utils.getNoNil(y, 0));
        instance.rotationPart.minRot[3] = Utils.degToRad(Utils.getNoNil(z, 0));

        x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, "vehicle.rotationPart#maxRot"));
        instance.rotationPart.maxRot = {};
        instance.rotationPart.maxRot[1] = Utils.degToRad(Utils.getNoNil(x, 0));
        instance.rotationPart.maxRot[2] = Utils.degToRad(Utils.getNoNil(y, 0));
        instance.rotationPart.maxRot[3] = Utils.degToRad(Utils.getNoNil(z, 0));

        instance.rotationPart.rotTime = Utils.getNoNil(getXMLString(xmlFile, "vehicle.rotationPart#rotTime"), 2)*1000;
        instance.rotationPart.touchRotLimit = Utils.degToRad(Utils.getNoNil(getXMLString(xmlFile, "vehicle.rotationPart#touchRotLimit"), 10));
    end;
    delete(xmlFile);

    instance.hasGroundContact = false;
    instance.rotationMax = false;
    instance.speedViolationMaxTime = 2500;
    instance.speedViolationTimer = instance.speedViolationMaxTime;

    return instance;
end;

function Plough:delete()
    removeContactReport(self.rootNode);
    Implement.delete(self);
end;

function Plough:mouseEvent(posX, posY, isDown, isUp, button)
    Implement.mouseEvent(self, posX, posY, isDown, isUp, button);
end;

function Plough:keyEvent(unicode, sym, modifier, isDown)
    Implement.keyEvent(self, unicode, sym, modifier, isDown);
end;

function Plough:update(dt)

    if self.isAttached and self.isSelected then
        if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
            self.rotationMax = not self.rotationMax;
        end;
    end;

    if self.isAttached and self.hasGroundContact then
        local updateDensity = true;
        if self.rotationPart ~= nil then
            local x, y, z = getRotation(self.rotationPart.node);
            local maxRot = self.rotationPart.maxRot;
            local minRot = self.rotationPart.minRot;
            local eps = self.rotationPart.touchRotLimit;
            if (math.abs(x-maxRot[1]) > eps and math.abs(x-minRot[1]) > eps) or
               (math.abs(y-maxRot[2]) > eps and math.abs(y-minRot[2]) > eps) or
               (math.abs(z-maxRot[3]) > eps and math.abs(z-minRot[3]) > eps) then
                updateDensity = false;
            end;
        end;
        if updateDensity then
            for i=1, table.getn(self.cuttingAreas) do
                local x,y,z = getWorldTranslation(self.cuttingAreas[i].start);
                local x1,y1,z1 = getWorldTranslation(self.cuttingAreas[i].width);
                local x2,y2,z2 = getWorldTranslation(self.cuttingAreas[i].height);
                Utils.updatePloughArea(x, z, x1, z1, x2, z2); --, 1, 1.0, 0, 0.0);
                --Utils.updateGrassAt(x, z, x1, z1, x2, z2, 0.0);
                --Utils.updateWheatArea(x, z, x1, z1, x2, z2, 0.0);
            end;
        end;

        if self.attacherVehicle.lastSpeed*3600 > 20 then
            self.speedViolationTimer = self.speedViolationTimer - dt;
            if self.speedViolationTimer < 0 then
                self.attacherVehicle:detachImplementByObject(self);
            end;
        else
            self.speedViolationTimer = self.speedViolationMaxTime;
        end;
    else
        self.speedViolationTimer = self.speedViolationMaxTime;
    end;

    if self.rotationPart ~= nil then

        local x, y, z = getRotation(self.rotationPart.node);
        local rot = {x,y,z};
        local newRot = Utils.getMovedLimitedValues(rot, self.rotationPart.maxRot, self.rotationPart.minRot, 3, self.rotationPart.rotTime, dt, not self.rotationMax);
        setRotation(self.rotationPart.node, unpack(newRot));
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

    Implement.update(self, dt);
end;

function Plough:draw()
    Implement.draw(self);

    --g_currentMission:addHelpButtonText("Pflug drehen", InputBinding.IMPLEMENT_EXTRA);
    g_currentMission:addHelpButtonText(g_i18n:getText("Turn_plough"), InputBinding.IMPLEMENT_EXTRA);
    
    if math.abs(self.speedViolationTimer - self.speedViolationMaxTime) > 2 then
        --g_currentMission:addWarning("Fahren Sie nicht zu schnell\nTempomat Stufe 1: Taste 1", 0.07+0.022, 0.019+0.029);
        --g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast"), 0.07+0.022, 0.019+0.029);
        g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), "1", InputBinding.getButtonKeyName(InputBinding.SPEED_LEVEL1)), 0.07+0.022, 0.019+0.029);
    end;
end;

function Plough:onAttach(attacherVehicle)
    Implement.onAttach(self, attacherVehicle);

    addContactReport(self.rootNode, "groundContactReport", self);
end;

function Plough:onDetach()
    Implement.onDetach(self);

    self.speedViolationTimer = self.speedViolationMaxTime;

    removeContactReport(self.rootNode);
end;

function Plough:groundContactReport(objectId, otherObjectId, isStart, normalForce, tangentialForce)

    if otherObjectId == g_currentMission.terrainRootNode then
        self.hasGroundContact = normalForce > 0 or tangentialForce > 0;
    end;

end;
