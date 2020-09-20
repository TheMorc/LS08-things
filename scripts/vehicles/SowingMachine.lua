--
-- SowingMachine
-- Class for all sowing machines
--
-- @author  Stefan Geiger (mailto:sgeiger@giants.ch)
-- @date  25/02/08

SowingMachine = {};

function SowingMachine:new(configFile, positionX, offsetY, positionZ, rotationY, customMt)

    if SowingMachine_mt == nil then
        SowingMachine_mt = Class(SowingMachine, Implement);
    end;

    local mt = customMt;
    if mt == nil then
        mt = SowingMachine_mt;
    end;
    local instance = Implement:new(configFile, positionX, offsetY, positionZ, rotationY, mt);

    --local xmlFile = loadXMLFile("TempConfig", configFile);
    --delete(xmlFile);

    instance.hasGroundContact = false;
    instance.fixedAttachRotation = true;
    instance.speedViolationMaxTime = 2500;
    instance.speedViolationTimer = instance.speedViolationMaxTime;

    return instance;
end;

function SowingMachine:delete()
    removeContactReport(self.rootNode);
    Implement.delete(self);
end;

function SowingMachine:mouseEvent(posX, posY, isDown, isUp, button)
    Implement.mouseEvent(self, posX, posY, isDown, isUp, button);
end;

function SowingMachine:keyEvent(unicode, sym, modifier, isDown)
    Implement.keyEvent(self, unicode, sym, modifier, isDown);
end;

function SowingMachine:update(dt)

    _=[[if self.isAttached and self.isSelected and not self.attacherVehicle.attachedImplements[self.attacherVehicle.selectedImplement].moveDown then
        self.isActive = false;
    end;]]

    _=[[if self.isAttached and self.isSelected then
        if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
            self.isActive = not self.isActive;
        end;
    end;]]

    if self.isAttached and self.hasGroundContact and self.attacherVehicle.movingDirection > 0 then -- and self.isActive then
        for i=1, table.getn(self.cuttingAreas) do
            local x,y,z = getWorldTranslation(self.cuttingAreas[i].start);
            local x1,y1,z1 = getWorldTranslation(self.cuttingAreas[i].width);
            local x2,y2,z2 = getWorldTranslation(self.cuttingAreas[i].height);
            --Utils.updateCultivatedAreaAt(x, z, x1, z1, x2, z2, 2, 1.0, 0, 0.0, 1, 0.0);
            local area = Utils.updateSowingArea(x, z, x1, z1, x2, z2);

            local pixelToQm = 2048 / 8192 * 2048 / 8192; -- 8192px are mapped to 2048m
            local qm = area*pixelToQm;
            local ha = qm/10000;
            local usage = g_seedUsagePerQm*qm;
            g_currentMission.missionStats.seedUsageTotal = g_currentMission.missionStats.seedUsageTotal + usage;
            g_currentMission.missionStats.seedUsageSession = g_currentMission.missionStats.seedUsageSession + usage;

            g_currentMission.missionStats.hectaresSeededTotal = g_currentMission.missionStats.hectaresSeededTotal + ha;
            g_currentMission.missionStats.hectaresSeededSession = g_currentMission.missionStats.hectaresSeededSession + ha;

            local seedPrice = g_seedPricePerLiter*usage;
            g_currentMission.missionStats.expensesTotal = g_currentMission.missionStats.expensesTotal + seedPrice;
            g_currentMission.missionStats.expensesSession = g_currentMission.missionStats.expensesSession + seedPrice;

            g_currentMission.missionStats.money = g_currentMission.missionStats.money - seedPrice;
            --Utils.updateCropsAt(x, z, x1, z1, x2, z2, 1.0);
            --Utils.updateGrassAt(x, z, x1, z1, x2, z2, 0.0);
            --Utils.updateCropsAt(x, z, x1, z1, x2, z2, 0.0);
        end;
        g_currentMission.missionStats.seedingDurationTotal = g_currentMission.missionStats.seedingDurationTotal + dt/(1000*60);
        g_currentMission.missionStats.seedingDurationSession = g_currentMission.missionStats.seedingDurationSession + dt/(1000*60);

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

    Implement.update(self, dt);
end;

function SowingMachine:draw()
    Implement.draw(self);

    if math.abs(self.speedViolationTimer - self.speedViolationMaxTime) > 2 then
        g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), "1", InputBinding.getButtonKeyName(InputBinding.SPEED_LEVEL1)), 0.07+0.022, 0.019+0.029);
    end;
end;

function SowingMachine:onAttach(attacherVehicle)
    Implement.onAttach(self, attacherVehicle);

    addContactReport(self.rootNode, "groundContactReport", self);
end;

function SowingMachine:onDetach()
    Implement.onDetach(self);

    self.speedViolationTimer = self.speedViolationMaxTime;
    --self.isActive = false;
    removeContactReport(self.rootNode);
end;

function SowingMachine:groundContactReport(objectId, otherObjectId, isStart, normalForce, tangentialForce)

    if otherObjectId == g_currentMission.terrainRootNode then
        self.hasGroundContact = normalForce > 0 or tangentialForce > 0;
    end;

end;
