--
-- Sprayer
-- Class for all sprayers
--
-- @author  Stefan Geiger (mailto:sgeiger@giants.ch)
-- @date  24/02/08

Sprayer = {};

function Sprayer:new(configFile, positionX, offsetY, positionZ, rotationY, customMt)

    if Sprayer_mt == nil then
        Sprayer_mt = Class(Sprayer, Implement);
    end;

    local mt = customMt;
    if mt == nil then
        mt = Sprayer_mt;
    end;
    local instance = Implement:new(configFile, positionX, offsetY, positionZ, rotationY, mt);

    local xmlFile = loadXMLFile("TempConfig", configFile);

    instance.sprayValves = {};

    local psFile = getXMLString(xmlFile, "vehicle.sprayParticleSystem#file");
    if psFile ~= nil then

        local i=0;
        while true do
            local baseName = string.format("vehicle.sprayValves.sprayValve(%d)", i);
            local node = getXMLString(xmlFile, baseName.. "#index");
            if node == nil then
                break;
            end;
            node = Utils.indexToObject(instance.rootNode, node);
            if node ~= nil then
                local sprayValve = {};
                sprayValve.particleSystems = {};
                local shape = loadI3DFile(psFile);
                link(node, shape);
                for i=0, getNumOfChildren(shape)-1 do
                    local child = getChildAt(shape, i);
                    if getClassName(child) == "Shape" then
                        local geometry = getGeometry(child);
                        if geometry ~= 0 then
                            if getClassName(geometry) == "ParticleSystem" then
                                table.insert(sprayValve.particleSystems, geometry);
                                setEmittingState(geometry, false);
                            end;
                        end;
                    end;
                end;
                table.insert(instance.sprayValves, sprayValve);
            end;
            i = i+1;
        end;

    end;

    delete(xmlFile);

    instance.isActive = false;
    instance.needLowering = false;
    instance.speedViolationMaxTime = 2500;
    instance.speedViolationTimer = instance.speedViolationMaxTime;

    return instance;
end;

function Sprayer:delete()
    Implement.delete(self);
end;

function Sprayer:mouseEvent(posX, posY, isDown, isUp, button)
    Implement.mouseEvent(self, posX, posY, isDown, isUp, button);
end;

function Sprayer:keyEvent(unicode, sym, modifier, isDown)
    Implement.keyEvent(self, unicode, sym, modifier, isDown);
end;

function Sprayer:update(dt)

    if self.isAttached and self.isSelected then
        if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
            self:setActive(not self.isActive);
        end;
    end;

    if self.isAttached and self.isActive then

        if self.attacherVehicle.lastSpeed*3600 > 31 then
            self.speedViolationTimer = self.speedViolationTimer - dt;
        else
            self.speedViolationTimer = self.speedViolationMaxTime;
        end;

        if self.speedViolationTimer > 0 then
            for i=1, table.getn(self.cuttingAreas) do
                local x,y,z = getWorldTranslation(self.cuttingAreas[i].start);
                local x1,y1,z1 = getWorldTranslation(self.cuttingAreas[i].width);
                local x2,y2,z2 = getWorldTranslation(self.cuttingAreas[i].height);
                Utils.updateSprayArea(x, z, x1, z1, x2, z2);
            end;
        end;
    else
        self.speedViolationTimer = self.speedViolationMaxTime;
    end;

    Implement.update(self, dt);
end;

function Sprayer:draw()
    Implement.draw(self);

    if self.isActive then
        g_currentMission:addHelpButtonText(self.name .. " " .. g_i18n:getText("turn_off"), InputBinding.IMPLEMENT_EXTRA);
    else
        g_currentMission:addHelpButtonText(self.name .. " " .. g_i18n:getText("turn_on"), InputBinding.IMPLEMENT_EXTRA);
    end;

    if math.abs(self.speedViolationTimer - self.speedViolationMaxTime) > 2 then
        g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), "2", InputBinding.getButtonKeyName(InputBinding.SPEED_LEVEL2)), 0.07+0.022, 0.019+0.029);
    end;
end;

function Sprayer:onAttach(attacherVehicle)
    Implement.onAttach(self, attacherVehicle);
end;

function Sprayer:onDetach()
    Implement.onDetach(self);

    self.speedViolationTimer = self.speedViolationMaxTime;

    self:setActive(false)
end;

function Sprayer:setActive(active)
    self.isActive = active;
    for i=1, table.getn(self.sprayValves) do
        local sprayValve = self.sprayValves[i];
        for j=1, table.getn(sprayValve.particleSystems) do
            setEmittingState(sprayValve.particleSystems[j], self.isActive);
        end;
    end;
    self.speedViolationTimer = self.speedViolationMaxTime;
end;