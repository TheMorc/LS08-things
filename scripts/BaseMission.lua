BaseMission = {};

local BaseMission_mt = Class(BaseMission);

BaseMission.STATE_INTRO = 0;
BaseMission.STATE_READY = 1;
BaseMission.STATE_RUNNING = 2;
BaseMission.STATE_FINISHED = 3;
BaseMission.STATE_FAILED = 5;

function BaseMission:new(customMt)

    local instance = {};
    if customMt ~= nil then
        setmetatable(instance, customMt);
    else
        setmetatable(instance, BaseMission_mt);
    end;

    instance.steerables = {};
    instance.triggeredSteerables = {};
    --instance.triggeredCutters = {};
    instance.tipTriggers = {};
    instance.siloTriggers = {};
    instance.gasStations = {};
    instance.barriers = {};
    instance.windmills = {};
    instance.ships = {};
    instance.nightlights = {};
    instance.currentTipTrigger = nil;

    instance.trailerTipTriggers = {};
    
    instance.currentVehicle = nil;
    instance.environment = nil;
    instance.tipTriggerRangeThreshold = 1.0;
    instance.isTipTriggerInRange = false;
    instance.state = BaseMission.STATE_INTRO;
    instance.minTime = 0;
    instance.endDelayTime = 5*1000;
    instance.endTimeStamp = 0;
    instance.bronzeTime = 0
    instance.silverTime = 0;
    instance.goldTime = 0;
    instance.record = 0;

    instance.medalOverlay = nil;

    instance.sunk = false;

    instance.isFreePlayMission = false;

    instance.cutterRangeThreshold = 1.5;

    instance.isRunning = false;
    instance.allowSteerableMoving = true;
    instance.fixedCamera = false;

    instance.sounds = {};

    instance.controlledVehicle = nil;
    instance.controlPlayer = true;

    instance.vehicles = {};
    instance.trailers = {};
    instance.objectToTrailer = {};
    instance.cutters = {};
    instance.attachables = {};

    instance.missionMaps = {};

    instance.mountThreshold = 6;

    instance.preSimulateTime = 3*1000;

    instance.time = 0;
    instance.missionTime = 0;

    instance.extraPrintTexts = {};
    instance.warnings = {};
    instance.warningsNumLines = {};
    instance.warningsOffsetsX = {};
    instance.warningsOffsetsY = {};
    instance.helpButtonTexts = {};

    instance.renderTime = false;

    instance.missionCompletedOverlayId = nil;
    instance.missionFailedOverlayId = nil;

    instance.hudBasePosX = 0.8325;
    instance.hudBasePosY = 1-0.094;
    instance.hudBaseWidth = 0.16;
    instance.hudBaseHeight = 0.099-0.018;
    instance.hudBaseWeatherPosX = instance.hudBasePosX+0.925-0.8325;
    instance.hudBaseWeatherPosY = instance.hudBasePosY+0.004;
    instance.hudBaseWeatherWidth = 0.977-0.922;
    instance.hudBaseWeatherHeight = 0.095-0.023;

    instance.hudMissionBasePosX = 0.012;
    instance.hudMissionBaseWidth = 0.437-0.012;

    instance.hudMissionBasePosX = 0.012;
    instance.hudMissionBaseWidth = 0.437-0.012;

    instance.hudHelpBasePosY = 1-0.99;
    instance.hudHelpBaseHeight = 0.1625;

    instance.hudWarningBasePosX = 0.25;
    instance.hudWarningBasePosY = 1-0.539;
    instance.hudWarningBaseWidth = 0.506;
    instance.hudWarningBaseHeight = 0.1;

    instance.completeDisplayX = 0.313;
    instance.completeDisplayY = 1-0.6275;
    instance.completeDisplayWidth = 0.374;
    instance.completeDisplayHeight = 0.382;

    instance.hudBaseOverlay = Overlay:new("hudBaseOverlay", "data/missions/hud_env_base.png", instance.hudBasePosX, instance.hudBasePosY, instance.hudBaseWidth, instance.hudBaseHeight);
    instance.hudBaseSunOverlay = Overlay:new("hudBaseSunOverlay", "data/missions/hud_sun.png", instance.hudBaseWeatherPosX, instance.hudBaseWeatherPosY, instance.hudBaseWeatherWidth, instance.hudBaseWeatherHeight);
    instance.hudBaseRainOverlay = Overlay:new("hudBaseRainOverlay", "data/missions/hud_rain.png", instance.hudBaseWeatherPosX, instance.hudBaseWeatherPosY, instance.hudBaseWeatherWidth, instance.hudBaseWeatherHeight);
    instance.hudBaseHailOverlay = Overlay:new("hudBaseHailOverlay", "data/missions/hud_hail.png", instance.hudBaseWeatherPosX, instance.hudBaseWeatherPosY, instance.hudBaseWeatherWidth, instance.hudBaseWeatherHeight);
    instance.hudMissionBaseOverlay = Overlay:new("hudBaseHailOverlay", "data/missions/hud_mission_base.png", instance.hudMissionBasePosX, instance.hudBasePosY, instance.hudMissionBaseWidth, instance.hudBaseHeight);
    instance.hudHelpBaseOverlay = Overlay:new("hudHelpBaseOverlay", "data/missions/hud_help_base.png", instance.hudMissionBasePosX, instance.hudHelpBasePosY, instance.hudMissionBaseWidth, instance.hudHelpBaseHeight);
    instance.hudWarningBaseOverlay = Overlay:new("hudHelpBaseOverlay", "data/missions/hud_warning_base.png", instance.hudWarningBasePosX, instance.hudWarningBasePosY, instance.hudWarningBaseWidth, instance.hudWarningBaseHeight);

    instance.showWeatherForecast = false;
    instance.showHudMissionBase = false;

    instance.showHudEnv = true;

    instance.money = 0;

    instance.missionStats = MissionStats:new();

    return instance;
end;

function BaseMission:delete()

    for i=1, table.getn(self.vehicles) do
        local vehicle = self.vehicles[i];
        vehicle:delete();
    end;
    for i=1, table.getn(self.cutters) do
        local cutter = self.cutters[i];
        cutter:delete();
    end;
    for i=1, table.getn(self.trailers) do
        local trailer = self.trailers[i];
        trailer:delete();
    end;
    for i=1, table.getn(self.attachables) do
        self.attachables[i]:delete();
    end;
    setCamera(g_defaultCamera);
    Player.destroy();


    for i=1, table.getn(self.missionMaps) do
        local missionMap = self.missionMaps[i];
        delete(missionMap);
    end;

    delete(self.rootNode);

    if self.environment ~= nil then
        self.environment:destroy();
        self.environment = nil;
    end;

    if self.missionCompletedOverlayId ~= nil then
        delete(self.missionCompletedOverlayId);
    end;
    if self.missionFailedOverlayId ~= nil then
        delete(self.missionFailedOverlayId);
    end;

    self.hudBaseOverlay:delete();
    self.hudBaseSunOverlay:delete();
    self.hudBaseRainOverlay:delete();
    self.hudBaseHailOverlay:delete();
    self.hudMissionBaseOverlay:delete();
    self.hudWarningBaseOverlay:delete();

    if self.medalOverlay ~= nil then
        self.medalOverlay:delete();
    end;

    self.missionStats:delete();

	g_currentMission = nil;

end;

function BaseMission:load()

    Player.create(self.playerStartX, self.playerStartY, self.playerStartZ, self.playerRotX, self.playerRotY);

    self.controlPlayer = true;
    self.controlledVehicle = nil;

    simulatePhysics(true);
    if self.preSimulateTime > 0 then
        extraUpdatePhysics(self.preSimulateTime);
    end;

    --self.isRunning = true;

end;

function BaseMission:loadMap(filename)
    self.rootNode = loadI3DFile("data/maps/" .. filename);
    link(getRootNode(), self.rootNode);
    self.terrainRootNode = getChild(self.rootNode, "terrain");

    self.terrainDetailId = getChild(self.terrainRootNode, "terrainDetail");
    self.wheatId = getChild(self.terrainRootNode, "wheat");
    self.cuttedWheatId = getChild(self.terrainRootNode, "cuttedWheat");
    self.grassId = getChild(self.terrainRootNode, "grass");
    self.meadowId = getChild(self.terrainRootNode, "meadow");
    self.cuttedMeadowId = getChild(self.terrainRootNode, "cuttedMeadow");

    self.cultivatorChannel = 0;
    self.ploughChannel = 1;
    self.sowingChannel = 2;
    self.sprayChannel = 3;
end;

function BaseMission:loadMissionMap(filename)
    local node = loadI3DFile("data/maps/missions/" .. filename);
    table.insert(self.missionMaps, node);
    link(getRootNode(), node);
    return node;
end;


function BaseMission:loadCutter(filename, x, yOffset, z, yRot)
    local cutter = Cutter:new(filename, x, yOffset, z, yRot);
    table.insert(self.cutters, cutter);
    return cutter;
end;

function BaseMission:loadTractor(filename, x, yOffset, z, yRot)
    local vehicle = Vehicle:new(filename, x, yOffset, z, yRot);
    table.insert(self.vehicles, vehicle);
    return vehicle;
end;

function BaseMission:loadCombine(filename, x, yOffset, z, yRot)
    local combine = Combine:new(filename, x, yOffset, z, yRot);
    table.insert(self.vehicles, combine);
    return combine;
end;

function BaseMission:loadTrailer(filename, x, yOffset, z, yRot)
    local trailer = Trailer:new(filename, x, yOffset, z, yRot)
    table.insert(self.trailers, trailer);
    self.objectToTrailer[trailer.fillRootNode] = trailer;
    return trailer;
end;

function BaseMission:loadCultivator(filename, x, yOffset, z)
    local cultivator = Cultivator:new(filename, x, yOffset, z, yRot);
    table.insert(self.attachables, cultivator);
    return cultivator;
end;

function BaseMission:loadVehicle(filename, x, yOffset, z, yRot)
    local xmlFile = loadXMLFile("TempConfig", filename);
    local typeName = getXMLString(xmlFile, "vehicle#type");
    delete(xmlFile);
    local ret = nil;
    if typeName == nil then
        print("Error loadVehicle: invalid vehicle config file '"..filename.."', no type specified");
    else
        local typeDef = g_vehicleTypes[typeName];
        if typeDef == nil then
            print("Error loadVehicle: unknown type '"..typeName.."' in '"..filename.."'");
        else
            local callString = "vehicle = " .. typeDef.className .. ":new(\""..filename.."\", "..x..", "..yOffset..", "..z..", "..yRot..");";
            loadstring(callString)();
            if vehicle ~= nil then
                if typeDef.intern == "implements" then
                    table.insert(self.attachables, vehicle);
                elseif typeDef.intern == "steerables" then
                    table.insert(self.vehicles, vehicle);
                elseif typeDef.intern == "trailers" then
                    table.insert(self.trailers, vehicle);
                    self.objectToTrailer[vehicle.fillRootNode] = vehicle;
                elseif typeDef.intern == "cutters" then
                    table.insert(self.cutters, vehicle);
                end;
            end;
            ret = vehicle;
            vehicle = nil;
        end;
    end;
    return ret;
end;

function BaseMission:pauseGame()

    self.isRunning = false;

end;

function BaseMission:unpauseGame()

    self.isRunning = true;

end;

function BaseMission:toggleVehicle()

    if self.fixedCamera or not self.allowSteerableMoving or (self.currentVehicle ~= nil and self.currentVehicle.doRefuel) then
        return;
    end
    local numVehicles = table.getn(self.vehicles);
    if numVehicles > 1 then

        local index = 0;

        if not self.controlPlayer then

            for i=1, table.getn(self.vehicles) do
                if self.currentVehicle == self.vehicles[i] then
                    --print("hit ", i);
                    index = i;
                end;
            end;

            --print("index ", index);

            self:onLeaveVehicle();
        end;

        local oldIndex = index;
        local found = false;
        while not found do
            index = index +1;
            if index > numVehicles then
                index = 1;
            end;
            if not self.vehicles[index].isBroken or index == oldIndex then
                found = true;
            end;
        end;

        self:onEnterVehicle(self.vehicles[index]);

    end;
end;

function BaseMission:mouseEvent(posX, posY, isDown, isUp, button)

    if self.isRunning then
        self.missionStats:mouseEvent(posX, posY, isDown, isUp, button);

        if self.controlPlayer then
            Player.mouseEvent(posX, posY, isDown, isUp, button);
        else
            self.controlledVehicle:mouseEvent(posX, posY, isDown, isUp, button);
        end;
    end;
end;

function BaseMission:keyEvent(unicode, sym, modifier, isDown)




    if self.isRunning then
        self.missionStats:keyEvent(unicode, sym, modifier, isDown);

        _=[[if sym == Input.KEY_p and isDown then
            -- Port
            Player.moveTo(600, 15, -120);
        end;
        if sym == Input.KEY_o and isDown then
            -- Cloister
            Player.moveTo(-129, 0.5, -840);
        end;
        if sym == Input.KEY_l and isDown then
            -- village1
            Player.moveTo(150, 0.5, -216);
        end;
        if sym == Input.KEY_u and isDown then
            -- farm1
            Player.moveTo(173, 0.5, 173);
        end;]]

        if sym == Input.KEY_tab  and isDown then
            self:toggleVehicle();
        end;


        _=[[if sym == Input.KEY_e and isDown then

            if self.controlPlayer then
                if self.vehicleInMountRange ~= nil then
                    self.controlledVehicle = self.vehicleInMountRange;
                    self.controlledVehicle:onEnter();
                    self.controlPlayer = false;
                    g_currentMission.currentVehicle = self.controlledVehicle;
                end;
            else
                if self.controlledVehicle ~= nil then
                    self.controlledVehicle:onLeave();
                end;
                self.controlPlayer = true;
                cx, cy, cz = getWorldTranslation(self.controlledVehicle.exitPoint);
                Player.onEnter();
                --Player.moveTo(cx, 0.5, cz);
                Player.moveToAbsolute(cx, cy+0.2, cz);
                g_currentMission.currentVehicle = nil;
            end;
        end;]]

        if not self.controlPlayer then
            self.controlledVehicle:keyEvent(unicode, sym, modifier, isDown);
        end;
    end;
end;

function BaseMission:update(dt)

    if not self.isRunning then
        return;
    end;

    self.time = self.time + dt;

    self.missionStats:update(dt);

    if InputBinding.hasEvent(InputBinding.ENTER) then

        if self.controlPlayer then
            if self.vehicleInMountRange ~= nil then
                self:onEnterVehicle(self.vehicleInMountRange)
            end;
        else
            self:onLeaveVehicle();
        end;
    end;

    for i=1, table.getn(self.vehicles) do
        local vehicle = self.vehicles[i];
        vehicle:update(dt, (self.controlledVehicle == vehicle) and (not self.controlPlayer));
    end;

    if self.controlPlayer then
        Player.update(dt);
    end;

    _=[[for i=1, table.getn(self.cutters) do
        local cutter = self.cutters[i];
        cutter:update(dt);
    end;]]

    for i=1, table.getn(self.trailers) do
        local trailer = self.trailers[i];
        trailer:update(dt);
    end;

    for i=1, table.getn(self.barriers) do
        local barriers = self.barriers[i];
        barriers:update(dt);
    end;

    self.vehicleInMountRange = self:getSteerableInRange();
    self.trailerInMountRange, self.trailerInMountRangeVehicle = self:getTrailerInRange();
    --self.isTipTriggerInRange = self:getIsTipTriggerInRange();
    self.trailerInTipRange, self.currentTipTrigger = self:getTrailerInTipRange();
    self.isTipTriggerInRange = self.trailerInTipRange ~= nil; -- this is here for backwards compatibility
    self.cutterInMountRange = self:getCutterInRange();
    self.attachableInMountRange, self.attachableInMountRangeIndex = self:getAttachableInRange();

	if self.environment ~= nil then
        self.environment:update(dt);
    end;
	
    for i=1, table.getn(self.windmills) do
        local windmill = self.windmills[i];
        windmill:update(dt);
    end;

    for i=1, table.getn(self.ships) do
        local ship = self.ships[i];
        ship:update(dt);
    end;

    for i=1, table.getn(self.nightlights) do
        local nightlight = self.nightlights[i];
        nightlight:update(dt);
    end;
    
    for i=1, table.getn(self.siloTriggers) do
        self.siloTriggers[i]:update(dt);
    end;
    
    for i=1, table.getn(self.tipTriggers) do
        self.tipTriggers[i]:update(dt);
    end;

    if not self.controlPlayer and self.controlledVehicle ~= nil and self.controlledVehicle.attachedTrailer ~= nil then
        if self.trailerInTipRange ~= nil and self.currentTipTrigger ~= nil then
            local trailer = self.trailerInTipRange;
            if trailer.tipState == Trailer.TIPSTATE_OPENING or trailer.tipState == Trailer.TIPSTATE_OPEN then
                if trailer.lastFillDelta < 0 then
                    self.currentTipTrigger:updateMoving(-trailer.lastFillDelta);
                end;
            end;
        end;
    end;

end;

function BaseMission:draw()

    if self.isRunning then

        if self.showHudEnv then
            self.hudBaseOverlay:render();
        end;

        if self.showHudMissionBase then
            self.hudMissionBaseOverlay:render();
        end;

        self.missionStats:draw();

        if self.currentVehicle ~= nil then
            self.currentVehicle:draw();
        end;

        if g_settingsHelpText then

            local renderTextsLeft = {};
            local renderTextsRight = {};

            local printText;
            local printButton;
            if self.currentVehicle ~= nil then
                -- we are in a vehicle
                --if self.isTipTriggerInRange and self.currentVehicle.attachedTrailer ~= nil then
                if self.trailerInTipRange ~= nil then
                    printText = g_i18n:getText("Dump");
                    printButton = InputBinding.ATTACH;
                elseif (self.trailerInMountRange ~= nil and self.trailerInMountRangeVehicle ~= nil and self.trailerInMountRangeVehicle.attachedTrailer == nil) or
                       (self.attachableInMountRange ~= nil and self.currentVehicle.attacherJoints[self.attachableInMountRangeIndex].jointIndex == 0) or
                       (self.cutterInMountRange ~= nil and self.currentVehicle.attachedCutter == nil) then
                    printText = g_i18n:getText("Attach");
                    printButton = InputBinding.ATTACH;
                elseif self.currentVehicle.selectedImplement ~= 0 then
                    local implement = self.currentVehicle.attachedImplements[self.currentVehicle.selectedImplement];
                    local jointDesc = self.currentVehicle.attacherJoints[implement.jointDescIndex];
                    if jointDesc.moveDown then
                        printText = string.format(g_i18n:getText("lift_OBJECT"), implement.object.name);
                    else
                        if implement.object.needLowering then
                            printText = string.format(g_i18n:getText("lower_OBJECT"), implement.object.name);
                        end;
                    end;
                    printButton = InputBinding.LOWER_IMPLEMENT;
                end;
            else
                if self.vehicleInMountRange ~= nil and self.controlPlayer then
                    printText = g_i18n:getText("Enter");
                    printButton = InputBinding.ENTER;
                end;
            end;

            if printText ~= nil and printButton ~= nil then
                table.insert(renderTextsLeft, (g_i18n:getText("Key") .. " " .. InputBinding.getButtonKeyName(printButton).." " .. g_i18n:getText("or") .. " " .. g_i18n:getText("Button") .. " "..InputBinding.getButtonName(printButton)..":"));
                table.insert(renderTextsRight, (printText));
            end;

            for i=1, table.getn(self.helpButtonTexts) do
                local button = self.helpButtonTexts[i].button;
                table.insert(renderTextsLeft, (g_i18n:getText("Key") .. " " ..InputBinding.getButtonKeyName(button).." " .. g_i18n:getText("or") .. " " .. g_i18n:getText("Button") .. " "..InputBinding.getButtonName(button)..":"));
                table.insert(renderTextsRight, self.helpButtonTexts[i].text);
            end;
            self.helpButtonTexts = {};

            if self.environment ~= nil and self.environment.dayNightCycle and
              (self.environment.dayTime > (20.5*1000*60*60) or self.environment.dayTime < (5.5*1000*60*60)) and
              self.currentVehicle ~= nil and not self.currentVehicle.lightsActive then
                table.insert(renderTextsLeft, (g_i18n:getText("Key") .. " "..InputBinding.getButtonKeyName(InputBinding.TOGGLE_LIGHTS).." " .. g_i18n:getText("or") .. " " .. g_i18n:getText("Button") .. " "..InputBinding.getButtonName(InputBinding.TOGGLE_LIGHTS)..":"));
                table.insert(renderTextsRight, g_i18n:getText("Turn_on_lights"));
            end;
            setTextColor(1.0, 1.0, 1.0, 1.0);
            setTextBold(false);
            for i=1, table.getn(self.extraPrintTexts) do
                --renderText(0.30, printYOffset, 0.025, self.extraPrintTexts[i]);
                --printYOffset = printYOffset + 0.04;

                table.insert(renderTextsLeft, (self.extraPrintTexts[i]));
                table.insert(renderTextsRight, "");

            end;
            self.extraPrintTexts = {};


            _=[[table.insert(renderTextsLeft, "Filler1");
            table.insert(renderTextsRight, "Test 1 2 3");
            table.insert(renderTextsLeft, "Filler2");
            table.insert(renderTextsRight, "Test 1 2 3");
            table.insert(renderTextsLeft, "Filler3");
            table.insert(renderTextsRight, "Test 1 2 3");
            table.insert(renderTextsLeft, "Filler4");
            table.insert(renderTextsRight, "Test 1 2 3");
            table.insert(renderTextsLeft, "Filler5");
            table.insert(renderTextsRight, "Test 1 2 3");]]

            local num = math.min(4, table.getn(renderTextsLeft));


            if table.getn(renderTextsLeft) >= 1 then
                self.hudHelpBaseOverlay:render();
            end;


            for i=1, num do
                local left = renderTextsLeft[i];
                local right = renderTextsRight[i];
                renderText(0.03, (4-i)*0.03+(1-0.97), 0.025, left);
                renderText(0.221, (4-i)*0.03+(1-0.97), 0.025, right);
            end;
        end;

        if table.getn(self.warnings) >= 1 then
            setTextColor(1.0, 0.0, 0.0, 1.0);
            self.hudWarningBaseOverlay:render();
            renderText(self.hudWarningBasePosX+self.warningsOffsetsX[1], self.hudWarningBasePosY+self.warningsOffsetsY[1], 0.035, self.warnings[1]);
            setTextColor(1.0, 1.0, 1.0, 1.0);
        end;
        self.warnings = {};
        self.warningsOffsetsX = {};
        self.warningsOffsetsY = {};

        if self.environment ~= nil then
            if self.renderTime then
                setTextColor(1.0, 1.0, 1.0, 1.0);
                self:drawTime(false, self.environment.dayTime/(1000*60*60));
            end;
            if self.showWeatherForecast then
                if (self.environment.timeUntilNextRain < 12*60) then
                    if self.environment.nextRainType == 1 then
                        self.hudBaseHailOverlay:render();
                    else
                        self.hudBaseRainOverlay:render();
                    end;
                else
                    self.hudBaseSunOverlay:render();
                end;
            end;
        end;
    end;
end;

function BaseMission:onEnterVehicle(vehicle)
    self.controlledVehicle = vehicle;
    self.controlledVehicle:onEnter();
    self.controlPlayer = false;
    Player.onLeave();
    g_currentMission.currentVehicle = self.controlledVehicle;
end;

function BaseMission:onLeaveVehicle()
    if self.controlledVehicle ~= nil then
        self.controlledVehicle:onLeave();
    end;
    self.controlPlayer = true;
    cx, cy, cz = getWorldTranslation(self.controlledVehicle.exitPoint);
    Player.onEnter();
    Player.moveToAbsolute(cx, cy, cz);
    g_currentMission.currentVehicle = nil;
end;

_=[[function BaseMission:getIsTipTriggerInRange()

    if self.currentTipTrigger ~= nil and self.currentVehicle ~= nil and self.currentVehicle.attachedTrailer ~= nil then
        local trailerX, trailerY, trailerZ = getWorldTranslation(self.currentVehicle.attachedTrailer.tipReferencePoint);
        local triggerX, triggerY, triggerZ = getWorldTranslation(self.currentTipTrigger.triggerId);
        --print("distance: ", Utils.vector2Length(trailerX-triggerX, trailerZ-triggerZ));
        --if Utils.vector2Length(trailerX-triggerX, trailerY-triggerY, trailerZ-triggerZ) < self.tipTriggerRangeThreshold then
        if Utils.vector2Length(trailerX-triggerX, trailerZ-triggerZ) < self.tipTriggerRangeThreshold then
            return true;
        end;
    end;

    return false;

end;]]

function BaseMission:getTrailerInTipRange(trailer, minDistance)
    if minDistance == nil then
        minDistance = self.tipTriggerRangeThreshold;
    end
    local ret = nil;
    local retTrigger = nil;
    if trailer == nil then
        if self.currentVehicle ~= nil and self.currentVehicle.attachedTrailer ~= nil then
            ret, retTrigger = self:getTrailerInTipRange(self.currentVehicle.attachedTrailer, minDistance);
        end;
    else
        local trailerX, trailerY, trailerZ = getWorldTranslation(trailer.tipReferencePoint);
        local triggers = self.trailerTipTriggers[trailer];
        if triggers ~= nil then
            for i=1, table.getn(triggers) do
                local tipTrigger = triggers[i];
                local triggerX, triggerY, triggerZ = getWorldTranslation(tipTrigger.triggerId);
                local distance = Utils.vector2Length(trailerX-triggerX, trailerZ-triggerZ);
                if distance < minDistance then
                    ret = trailer;
                    retTrigger = tipTrigger;
                    minDistance = distance;
                end;
            end;
        end;
        if trailer.attachedTrailer ~= nil then
            local tempRet, tempRetTrigger = self:getTrailerInTipRange(trailer.attachedTrailer, minDistance);
            if tempRet ~= nil and tempRetTrigger ~= nil then
                ret = tempRet;
                retTrigger = tempRetTrigger;
            end;
        end;
    end;

    _=[[if trailer == nil or tipTrigger == nil then
        if self.currentTipTrigger ~= nil and self.currentVehicle ~= nil and self.currentVehicle.attachedTrailer ~= nil then
            ret = self:getTrailerInTipRange(self.currentVehicle.attachedTrailer, self.currentTipTrigger);
        end;
    else
        local trailerX, trailerY, trailerZ = getWorldTranslation(trailer.tipReferencePoint);
        local triggerX, triggerY, triggerZ = getWorldTranslation(tipTrigger.triggerId);
        if Utils.vector2Length(trailerX-triggerX, trailerZ-triggerZ) < self.tipTriggerRangeThreshold then
            ret = trailer;
        elseif trailer.attachedTrailer ~= nil then
            ret = self:getTrailerInTipRange(trailer.attachedTrailer, tipTrigger);
        end;
    end;
    return ret;]]
    return ret, retTrigger;
end;

function BaseMission:getCutterInRange()

    _=[[local nearestCutter = nil;

    if self.currentVehicle ~= nil and self.currentVehicle.cutterHolder ~= nil then
        local numCutters = table.getn(self.triggeredCutters);

        local vehicleX, vehicleY, vehicleZ = getWorldTranslation(self.currentVehicle.cutterHolder);

        local nearestDistance = self.cutterRangeThreshold;
        for i=1, numCutters do
            local cutter = self.triggeredCutters[i];
            local cutterX, cutterY, cutterZ = getWorldTranslation(cutter.rootNode);
            local distance = Utils.vector2Length(cutterX-vehicleX, cutterZ-vehicleZ);
            if distance <= nearestDistance then
                nearestDistance = distance;
                nearestCutter = cutter;
            end;
        end;
    end;
    return nearestCutter;]]

    if self.currentVehicle ~= nil and self.currentVehicle.cutterAttacherJoint ~= nil then
        local px, py, pz = getWorldTranslation(self.currentVehicle.cutterAttacherJoint.jointTransform);
        local nearestCutter = nil;
        local nearestDistance = 0.4;

        for i=1, table.getn(self.cutters) do
            local vx, vy, vz = getWorldTranslation(self.cutters[i].attacherJoint);
            local distance = Utils.vector2Length(px-vx, pz-vz);
            if distance < nearestDistance then
                nearestCutter = self.cutters[i];
                nearestDistance = distance;
            end;
        end;

        return nearestCutter;
    end;
    return nil;
end;

function BaseMission:getSteerableInRange()
    return self:getVehicleInRange(self.mountThreshold, self.vehicles, Player.playerName);
end;

function BaseMission:getTrailerInRange(vehicle)
    if vehicle == nil then
        vehicle = self.currentVehicle;
    end;
    if vehicle ~= nil then
        if vehicle.attachedTrailer ~= nil then
            local retTrailer, retVehicle = self:getTrailerInRange(vehicle.attachedTrailer);
            return retTrailer, retVehicle;
        end;
        if vehicle.trailerAttacherJoint ~= nil then
            local px, py, pz = getWorldTranslation(vehicle.trailerAttacherJoint);
            local nearestTrailer = nil;
            local nearestDistance = 0.4;

            for i=1, table.getn(self.trailers) do
                local vx, vy, vz = getWorldTranslation(self.trailers[i].attacherJoint);
                local distance = Utils.vector2Length(px-vx, pz-vz);
                if distance < nearestDistance then
                    nearestTrailer = self.trailers[i];
                    nearestDistance = distance;
                end;
            end;

            return nearestTrailer, vehicle;
        end;
    end;
    return nil;
end;

function BaseMission:getAttachableInRange()
    local nearestVehicle = nil;
    local nearestIndex = 0;
    if self.currentVehicle ~= nil then
        local nearestDistance = 0.4;
        for j=1, table.getn(self.currentVehicle.attacherJoints) do
            local jointDesc = self.currentVehicle.attacherJoints[j];
            local px, py, pz = getWorldTranslation(jointDesc.jointTransform);

            for i=1, table.getn(self.attachables) do
                if not self.attachables[i].isAttached then
                    local vx, vy, vz = getWorldTranslation(self.attachables[i].attacherJoint);
                    local distance = Utils.vector2Length(px-vx, pz-vz);
                    if distance < nearestDistance then
                        nearestVehicle = self.attachables[i];
                        nearestDistance = distance;
                        nearestIndex = j;
                    end;
                end;
            end;
        end;
    end;
    return nearestVehicle, nearestIndex;
end;

function BaseMission:getVehicleInRange(threshold, vehicles, referenceId)
    local px, py, pz = getWorldTranslation(referenceId);
    local nearestVehicle = nil;
    local nearestDistance = threshold;

    for i=1, table.getn(vehicles) do
        if not vehicles[i].isBroken then
            local vx, vy, vz = getWorldTranslation(vehicles[i].rootNode);
            local distance = Utils.vector2Length(px-vx, pz-vz);
            if distance < nearestDistance then
                nearestVehicle = vehicles[i];
                nearestDistance = distance;
            end;
        end;
    end;
    return nearestVehicle;

end;

function BaseMission:drawTime(big, timeHoursF)
    local timeHours = math.floor(timeHoursF);
    local timeMinutes = math.floor((timeHoursF-timeHours)*60);
    setTextBold(true);

    local offsetX = 0;
    local offsetY = 0;
    local fontSize = 0.04;
    if big then
        offsetX = 0.0125;
        offsetY = -0.01;
        fontSize = 0.06;
    end;

    renderText(self.hudBasePosX+0.007+offsetX, self.hudBasePosY+0.02+offsetY, fontSize, string.format("%02d:%02d", timeHours, timeMinutes));
end;

function BaseMission:drawMissionCompleted()

    if self.missionFailedOverlayId == nil then
        self.missionCompletedOverlayId = createOverlay("mission_completed", "data/missions/mission_completed" .. g_languageSuffix .. ".png");
    end;

    renderOverlay(self.missionCompletedOverlayId, self.completeDisplayX, self.completeDisplayY, self.completeDisplayWidth, self.completeDisplayHeight);


    if self.medalOverlay ~= nil then
        self.medalOverlay:render();
    end;

    local timePosX = self.completeDisplayX+self.completeDisplayWidth*0.275;
    local timePosY = self.completeDisplayY+self.completeDisplayHeight*0.25;

    setTextBold(true);
    local time = self.record/(60*1000);
    local timeHours = math.floor(time);
    local timeMinutes = math.floor((time-timeHours)*60);
    --renderText(timePosX, timePosY, 0.045, string.format("Zeit: %02d:%02d", timeHours, timeMinutes));
    renderText(timePosX, timePosY, 0.045, g_i18n:getText("Time") .. string.format(": %02d:%02d", timeHours, timeMinutes));
    setTextBold(false);

end;

function BaseMission:drawMissionFailed()
    if self.missionFailedOverlayId == nil then
        self.missionFailedOverlayId = createOverlay("mission_failed", "data/missions/mission_failed" .. g_languageSuffix .. ".png");
    end;
    BaseMission:drawCentered(self.missionFailedOverlayId, 0.5, 0.175);
end;

function BaseMission:drawCentered(overlayId, width, height)
    renderOverlay(overlayId, 0.5-(width/2), 0.5-(height/2), width, height);
end;

function BaseMission:onSunkVehicle()
    if not self.isFreePlayMission then
        self.sunk = true;
    end;
end;


function BaseMission:finishMission(record)

    --print("self.missionId", self.missionId);
    if g_finishedMissions[self.missionId] == nil then
        g_finishedMissions[self.missionId] = 1;
    end;

    if g_finishedMissionsRecord[self.missionId] == nil or record < g_finishedMissionsRecord[self.missionId] then
        g_finishedMissionsRecord[self.missionId] = record;
    end;

    local finishedStr = "";
    local recordStr = "";
    for k,v in pairs(g_finishedMissions) do
        finishedStr = finishedStr .. k .. " ";
        recordStr = recordStr .. math.floor(g_finishedMissionsRecord[k]) .. " ";
    end;
    setXMLString(g_savegameXML, "savegames.missions#finished", finishedStr);
    setXMLString(g_savegameXML, "savegames.missions#record", recordStr);

    saveXMLFile(g_savegameXML);

    local medalPosX = self.completeDisplayX+self.completeDisplayWidth*0.295;
    local medalPosY = self.completeDisplayY+self.completeDisplayHeight*0.38;
    local medalHeight = 0.204;

    --print("record ", record);
    --print(self.bronzeTime, " ", self.silverTime, " ", self.goldTime);
    
    self.record = record;

    local recordFloor = math.floor(record);

    local timeMinutesF = record/(1000*60);
    local timeMinutes = math.floor(timeMinutesF);
    local timeSeconds = math.floor((timeMinutesF-timeMinutes)*60);
    local recordFloor = (timeSeconds+60*timeMinutes)*1000;    
    
    local filename = "data/missions/empty_medal.png";
    if recordFloor <= self.bronzeTime then
        filename = "data/missions/bronze_medal.png";
    end;
    if recordFloor <= self.silverTime then
        filename = "data/missions/silver_medal.png";
    end;
    if recordFloor <= self.goldTime then
        filename = "data/missions/gold_medal.png";
    end;


    --print("filename ", filename);

    self.medalOverlay = Overlay:new("emptyMedalOverlay", filename, medalPosX, medalPosY, medalHeight*0.75, medalHeight);

end;

function BaseMission:setMissionInfo(missionId, bronzeTime, silverTime, goldTime)
    self.missionId = missionId;
    self.minTime = bronzeTime;
    self.bronzeTime = bronzeTime;
    self.silverTime = silverTime;
    self.goldTime = goldTime;

    --print(self.bronzeTime, " ", self.silverTime, " ", self.goldTime);
    
    
end;

function BaseMission:addHelpButtonText(text, button)
    table.insert(self.helpButtonTexts, {text=text, button=button});
    --self.implementExtraText = text;
    --self.implementExtraButton = button;
end;

function BaseMission:addExtraPrintText(text)
    table.insert(self.extraPrintTexts, text);
end;

function BaseMission:addWarning(text, offsetX, offsetY)
    table.insert(self.warnings, text);
    table.insert(self.warningsOffsetsX, offsetX);
    table.insert(self.warningsOffsetsY, offsetY);
end;

function BaseMission:getSiloAmount(fillType)
    if fillType == Trailer.FILLTYPE_WHEAT then
        return self.missionStats.farmSiloWheatAmount;
    elseif fillType == Trailer.FILLTYPE_GRASS then
        return 0;
    else
        return 0;
    end;
end;

function BaseMission:setSiloAmount(fillType, amount)
    if fillType == Trailer.FILLTYPE_WHEAT then
        self.missionStats.farmSiloWheatAmount = amount;
    elseif fillType == Trailer.FILLTYPE_GRASS then
        -- do nothing
    end;
end;