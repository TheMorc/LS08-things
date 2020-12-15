serverMenu = {};

serverMenu.densityMapRevision = 2;

local serverMenu_mt = Class(serverMenu);

function serverMenu:new(backgroundOverlay)
    local instance = {};
    setmetatable(instance, serverMenu_mt);

    instance.overlays = {};
    instance.overlayButtons = {};

    table.insert(instance.overlays, Overlay:new("background01",  "data/menu/background01".. g_languageSuffix .. ".png", 0, 0, 1, 1));

    instance.imageSpacing = 0.035;
    --instance.spacingTop = 0.045;
    instance.spacingLeft = 0.225;

    instance.spacingLeftInner = 0.14;

    instance.textSizeTitle = 0.04;
    instance.textSizeDesc = 0.020;
    --instance.textTitleSpacing = 0.003;
    instance.textTitleSpacing = 0.006;

    instance.upDownButtonSpacing = 0.02;
    instance.buttonWidth = 0.15;
    instance.buttonHeight = 0.06;
    instance.largeButtonWidth = 0.3;
    instance.backPlayButtonSpacing = 0.02;

    instance.briefingWidth = 0.825;
    instance.briefingHeigth = 1.025;
    instance.briefingX = (1-instance.briefingWidth)/2;
    instance.briefingY = -0.02;

    instance.imageSize = (1 - (instance.backPlayButtonSpacing + 3*instance.buttonHeight + 2*instance.upDownButtonSpacing + 5*instance.imageSpacing))/4;

    instance.quickPlayBriefingOverlay = Overlay:new("quickPlayOverlayBriefing", "data/missions/mission00_briefing".. g_languageSuffix .. ".png", instance.briefingX, instance.briefingY, instance.briefingWidth, instance.briefingHeigth);
    instance.quickPlayBriefingBackgroundOverlay = Overlay:new("background01",  "data/menu/background01".. g_languageSuffix .. ".png", 0, 0, 1, 1);

    instance.avatars = {};
    table.insert(instance.avatars, Overlay:new("avatar01Overlay", "data/missions/mission00_avatar01.png", 0, 0, instance.imageSize*0.75, instance.imageSize));
    table.insert(instance.avatars, Overlay:new("avatar01Overlay", "data/missions/mission00_avatar02.png", 0, 0, instance.imageSize*0.75, instance.imageSize));
    table.insert(instance.avatars, Overlay:new("avatar01Overlay", "data/missions/mission00_avatar03.png", 0, 0, instance.imageSize*0.75, instance.imageSize));
    table.insert(instance.avatars, Overlay:new("avatar01Overlay", "data/missions/mission00_avatar04.png", 0, 0, instance.imageSize*0.75, instance.imageSize));
    table.insert(instance.avatars, Overlay:new("avatar01Overlay", "data/missions/mission00_avatar05.png", 0, 0, instance.imageSize*0.75, instance.imageSize));
    table.insert(instance.avatars, Overlay:new("avatar01Overlay", "data/missions/mission00_avatar06.png", 0, 0, instance.imageSize*0.75, instance.imageSize));

    instance.doubleClickTime = 0;
    instance.time = 0;

    instance.spacingTop = instance.upDownButtonSpacing + instance.buttonHeight + instance.imageSpacing;

    instance.savegames = {};

    local eof = false;
    local i = 1;
    repeat
        if not instance:loadSavegameFromXML(i) then
            eof = true;
        end;
        i = i+1;
    until eof

    instance.startIndex = 1;
    instance.selectedIndex = 1;

    instance:addButton(OverlayButton:new(Overlay:new("up_button", "data/menu/up_button.png", 0.5-0.5*instance.buttonWidth, 1-instance.upDownButtonSpacing-instance.buttonHeight, instance.buttonWidth, instance.buttonHeight), OnserverMenuScrollUp));
    instance:addButton(OverlayButton:new(Overlay:new("down_button", "data/menu/down_button.png", 0.5-0.5*instance.buttonWidth, instance.upDownButtonSpacing+instance.backPlayButtonSpacing+instance.buttonHeight, instance.buttonWidth, instance.buttonHeight), OnserverMenuScrollDown));

    local buttonSpacingSide = 0.03
    local xPos = 1-buttonSpacingSide-instance.backPlayButtonSpacing-instance.buttonWidth*3  --0.65;
    instance:addButton(OverlayButton:new(Overlay:new("settings_button", "data/menu/main_settings_button".. g_languageSuffix .. ".png", xPos, instance.backPlayButtonSpacing, instance.buttonWidth, instance.buttonHeight), MPopenSettingsMenu));
    xPos = xPos + instance.buttonWidth+instance.backPlayButtonSpacing;
    
    instance:addButton(OverlayButton:new(Overlay:new("back_button", "data/menu/back_button".. g_languageSuffix .. ".png", xPos, instance.backPlayButtonSpacing, instance.buttonWidth, instance.buttonHeight), OnserverMenuBack));
    xPos = xPos + instance.buttonWidth+instance.backPlayButtonSpacing;
    instance:addButton(OverlayButton:new(Overlay:new("play_button", "data/menu/ingame_play_button".. g_languageSuffix .. ".png", xPos, instance.backPlayButtonSpacing, instance.buttonWidth, instance.buttonHeight), OnserverMenuPlay));
    xPos = xPos + instance.buttonWidth+instance.backPlayButtonSpacing;

    instance:addButton(OverlayButton:new(Overlay:new("delete_button", "data/menu/delete_button".. g_languageSuffix .. ".png", buttonSpacingSide, instance.backPlayButtonSpacing, instance.buttonWidth, instance.buttonHeight), OnserverMenuDelete));
    
   	local f=io.open("data/menu/reset_vehicles_button".. g_languageSuffix .. ".png","r")
   	if f~=nil then
   		io.close(f)
   		instance:addButton(OverlayButton:new(Overlay:new("reset_vehicles_button", "data/menu/reset_vehicles_button".. g_languageSuffix .. ".png", buttonSpacingSide+instance.buttonWidth+instance.backPlayButtonSpacing, instance.backPlayButtonSpacing, instance.largeButtonWidth, instance.buttonHeight), OnserverMenuResetVehicles));
   	else
   		print("[LS2008MP] data/menu/reset_vehicles_button".. g_languageSuffix .. ".png is missing but nevermind, i'll not add the button to server menu")
   	end
    
    instance.selectedPositionBase = 2*instance.buttonHeight+instance.backPlayButtonSpacing+instance.upDownButtonSpacing+0.5*instance.imageSpacing;

    table.insert(instance.overlays, Overlay:new("background_overlay", "data/menu/missionmenu_background.png", instance.spacingLeft, instance.selectedPositionBase, 1-instance.spacingLeft*2, 4*(instance.imageSpacing+instance.imageSize)));
    instance.selectedOverlay = Overlay:new("selected_overlay", "data/menu/missionmenu_selected.png", 0, 0, 1-instance.spacingLeft*2, instance.imageSpacing+instance.imageSize);
    table.insert(instance.overlays, instance.selectedOverlay);

    return instance;
end;

function serverMenu:mouseEvent(posX, posY, isDown, isUp, button)
    for i=1, table.getn(self.overlayButtons) do
        self.overlayButtons[i]:mouseEvent(posX, posY, isDown, isUp, button);
    end;

    if isDown then

        if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_LEFT) then

            local lastIndex = self.selectedIndex;
            local clicked = false;
            for i=1, 4 do
                local height = self.imageSpacing+self.imageSize;
                local pos = self.selectedPositionBase + (i-1)*height;
                if posX >= self.spacingLeft*0.5 and posX <= 1-self.spacingLeft and posY >= pos and posY <= pos+height then
                    self.selectedIndex = 4-i + self.startIndex;
                    clicked = true;
                end;
            end;

            if clicked and lastIndex == self.selectedIndex and self.doubleClickTime+500 > self.time then
                OnserverMenuPlay();
            end;
            self.doubleClickTime = self.time;

        else
            if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) then
                OnserverMenuScrollUp();
            else
                if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) then
                    OnserverMenuScrollDown();
                end;
            end;

        end;
    end;

end;

function serverMenu:keyEvent(unicode, sym, modifier, isDown)
end;

function serverMenu:update(dt)

    self.time = self.time + dt;
end;

function serverMenu:render()

    self.selectedOverlay:setPosition(self.spacingLeft, self.selectedPositionBase+(4-self.selectedIndex+(self.startIndex-1))*(self.imageSpacing+self.imageSize));

    local numSavegames = 5;
    for i=1, table.getn(self.overlays) do
        self.overlays[i]:render();
        
    end;

    local textLeft = self.spacingLeft;
    local endIndex = math.min(self.startIndex+3, numSavegames);
    for i=self.startIndex, endIndex do
        local savegame = self.savegames[i];

        local overlay = self.avatars[i];
        overlay:setPosition(self.spacingLeft + 0.015, 1 - (self.spacingTop+(self.imageSize+self.imageSpacing)*(i-self.startIndex) + self.imageSize));
        overlay:render();
        
		local savegameName = ""
		
		if isOriginalGame then --fallback to original game
        	savegameName = "Unknown Language";
        	if g_language == LANGUANGE_DE then
        	    savegameName = "Spielstand " .. i;
        	elseif g_language == LANGUANGE_EN then
        	    savegameName = "Savegame " .. i;
        	end;
		else --addon version of game that has i18n support
			savegameName = g_i18n:getText("Savegame") .. " " .. i;
        end
        
        setTextColor(1.0, 1.0, 1.0, 1.0);
        setTextBold(true);
        renderText(self.spacingLeft+self.spacingLeftInner, 1-(self.spacingTop+(self.imageSize+self.imageSpacing)*(i-self.startIndex) + self.textSizeTitle)+0.005, self.textSizeTitle, savegameName);
        setTextBold(false);

        local desc1;
        local desc2;
        if savegame.valid then
            local timeHoursF = savegame.stats.dayTime/60+0.0001;
            local timeHours = math.floor(timeHoursF);
            local timeMinutes = math.floor((timeHoursF-timeHours)*60);
            local playTimeHoursF = savegame.stats.playTime/60+0.0001;
            local playTimeHours = math.floor(playTimeHoursF);
            local playTimeMinutes = math.floor((playTimeHoursF-playTimeHours)*60);
            if isOriginalGame then --addon version of the game
            	desc1 = "Geld:\n" .. "Kornlager:\n" .. "Uhrzeit im Spiel:\n" .. "Spieldauer:\n"  .. "Speicherdatum:";
            else --original old version of the game
            	desc1 = g_i18n:getText("Money") .. ":\n" .. g_i18n:getText("Corn_storage") .. ":\n" .. g_i18n:getText("In_game_time") .. ":\n" .. g_i18n:getText("Duration") .. ":\n"  .. g_i18n:getText("Save_date") .. ":";
            end
            desc2 = string.format("%d", savegame.stats.money) .. " €\n" ..
                    string.format("%d", savegame.stats.farmSiloWheatAmount) .. " liter\n" ..
                   string.format("%02d:%02d", timeHours, timeMinutes) .. " h\n" ..
                   string.format("%02d:%02d", playTimeHours, playTimeMinutes) .. " hh:mm\n" ..
                   savegame.stats.saveDate;
        else
        	if isOriginalGame then
            	desc1 = "Dieser Spielstand ist zur Zeit unbenutzt";
            else
            	desc1 = g_i18n:getText("This_savegame_is_currently_unused");
            end
            desc2 = "";
        end;
        renderText(self.spacingLeft+self.spacingLeftInner, 1-(self.spacingTop+(self.imageSize+self.imageSpacing)*(i-self.startIndex) + self.textSizeTitle + self.textTitleSpacing + self.textSizeDesc)+0.01, self.textSizeDesc, desc1);
        renderText(self.spacingLeft+self.spacingLeftInner+0.12, 1-(self.spacingTop+(self.imageSize+self.imageSpacing)*(i-self.startIndex) + self.textSizeTitle + self.textTitleSpacing + self.textSizeDesc)+0.01, self.textSizeDesc, desc2);

    end;

end;

function serverMenu:addButton(overlayButton)
    table.insert(self.overlays, overlayButton.overlay);
    table.insert(self.overlayButtons, overlayButton);
end;

function serverMenu:setSelectedIndex(index)
    local numSavegames = 5;
    self.selectedIndex = math.max(math.min(index, numSavegames), 1);

    if self.selectedIndex > self.startIndex+3 then
        self.startIndex = self.selectedIndex-3;
    elseif self.selectedIndex < self.startIndex then
        self.startIndex = self.selectedIndex;
    end;
end;

function serverMenu:startSelectedGame()
    local savegame = self.savegames[self.selectedIndex];

    local dir = self:getSavegameDirectory(self.selectedIndex);

    createFolder(dir);

    local careerVehiclesPath = getAppBasePath() .. "data/careerVehicles.xml";
    local overwrite = not savegame.valid;
    copyFile(careerVehiclesPath, savegame.vehiclesXML, overwrite);


    if savegame.valid then
        setTerrainLoadDirectory(dir);
    else
        setTerrainLoadDirectory("");
    end;

    g_missionLoaderDesc = {};
    if isOriginalGame then
    	g_missionLoaderDesc.scriptFilename = "data/scripts/multiplayer/originalMission00.lua";
    	print("[LS2008MP] loading newer mission00 for vehicle.xml support")
    else
    	g_missionLoaderDesc.scriptFilename = "data/missions/mission00.lua";
    end
    g_missionLoaderDesc.scriptClass = "Mission00";
    g_missionLoaderDesc.id = 0;
    g_missionLoaderDesc.bronze = 0;
    g_missionLoaderDesc.silver = 0;
    g_missionLoaderDesc.gold = 0;
    g_missionLoaderDesc.overlayBriefing = self.quickPlayBriefingOverlay;
    g_missionLoaderDesc.backgroundOverlay = self.quickPlayBriefingBackgroundOverlay;
    g_missionLoaderDesc.overlayBriefingMedals = nil;
    g_missionLoaderDesc.stats = savegame.stats;
    g_missionLoaderDesc.vehiclesXML = savegame.vehiclesXML;

    stopSample(g_menuMusic);

    gameMenuSystem.loadScreen = serverLoading:new(OnLoadingScreen);
    gameMenuSystem.loadScreen:setScriptInfo(g_missionLoaderDesc.scriptFilename, g_missionLoaderDesc.scriptClass);
    gameMenuSystem.loadScreen:setMissionInfo(g_missionLoaderDesc.id, g_missionLoaderDesc.bronze, g_missionLoaderDesc.silver, g_missionLoaderDesc.gold);
    gameMenuSystem.loadScreen:addItem(g_missionLoaderDesc.backgroundOverlay);
    gameMenuSystem.loadScreen:addItem(g_missionLoaderDesc.overlayBriefing);
    gameMenuSystem.inGameMenu:setMissionId(g_missionLoaderDesc.id);

    gameMenuSystem.currentMenu = gameMenuSystem.loadScreen;
    
    
	MPinitSrvCli = false
	MPenabled = not MPenabled
	MPsettingsMenuSelected = "" 
	setCaption("LS2008MP v" .. MPversion .. " | Server | ".. MPplayerName)
end;

function serverMenu:deleteSelectedGame()
    local savegame = self.savegames[self.selectedIndex];
    savegame.valid = false;
    savegame.densityMapRevision = serverMenu.densityMapRevision;
    self:loadStatsDefaults(savegame);

    self:saveSavegameToXML(savegame, self.selectedIndex);

    saveXMLFile(g_savegameXML);
end;

function serverMenu:resetVehiclesOfSelectedGame()

    local savegame = self.savegames[self.selectedIndex];
    local dir = self:getSavegameDirectory(self.selectedIndex);

    createFolder(dir);

    local careerVehiclesPath = getAppBasePath() .. "data/careerVehicles.xml";
    copyFile(careerVehiclesPath, savegame.vehiclesXML, true);
end;

function serverMenu:saveSavegameToXML(savegame, id)
    local baseString = "savegames.quickPlay.savegame"..id;
    setXMLBool(g_savegameXML, baseString.."#valid", savegame.valid);
    
    if not isOriginalGame then
    	setXMLInt(g_savegameXML, baseString.."#densityMapRevision", savegame.densityMapRevision);
	end
	
    self:saveStatsToXML(baseString, savegame);

    -- save vehicle positions
    local vehiclesFile = io.open (savegame.vehiclesXML, "w");
    if vehiclesFile ~= nil then
    	vehiclesFile:write('<?xml version="1.0" encoding="iso-8859-1" standalone="no" ?>\n<careerVehicles>\n');
     	if g_currentMission ~= nil then
  	    	self:writeVehicleListToFile(vehiclesFile, g_currentMission.attachables);
   	       	self:writeVehicleListToFile(vehiclesFile, g_currentMission.vehicles);
   	        self:writeVehicleListToFile(vehiclesFile, g_currentMission.trailers);
   	        self:writeVehicleListToFile(vehiclesFile, g_currentMission.cutters);
     	end;

    	vehiclesFile:write("</careerVehicles>");
    	vehiclesFile:close();
   	end;
   	
end;

function serverMenu:writeVehicleListToFile(file, list)
    for i=1, table.getn(list) do
        local vehicle = list[i];
        local x,y,z = getTranslation(vehicle.rootNode);
        local xRot,yRot,zRot = getRotation(vehicle.rootNode);
        if isOriginalGame then
        	file:write('    <vehicle filename="'.. vehicle.configFileName ..'" xPosition="'..x..'" yPosition="'..y..'" zPosition="'..z..'" xRotation="'..xRot..'" yRotation="'..yRot..'" zRotation="'..zRot..'" absolute="true"');
        	if vehicle.fillLevel ~= nil and vehicle.setFillLevel and vehicle.currentFillType ~= nil then
        	    file:write(' fillLevel="'..vehicle.fillLevel..'" fillType="'..vehicle.currentFillType..'"');
        	end;
        else       	
        	file:write('    <vehicle filename="'.. vehicle.configFileName ..'" xPosition="'..x..'" yPosition="'..y..'" zPosition="'..z..'" xRotation="'..xRot..'" yRotation="'..yRot..'" zRotation="'..zRot..'" absolute="true"');
        	if vehicle.fillLevel ~= nil and vehicle.setFillLevel and vehicle.currentFillType ~= nil then
        	    file:write(' fillLevel="'..vehicle.fillLevel..'" fillType="'..vehicle.currentFillType..'"');
        	end;
        end
        file:write('/>\n');
    end;
end;

function serverMenu:reset()
    for i=1, table.getn(self.overlayButtons) do
        self.overlayButtons[i]:reset();
    end
end;

function serverMenu:saveSelectedGame()
    local savegame = self.savegames[self.selectedIndex];
    savegame.valid = true;
    if not isOriginalGame then
    	savegame.densityMapRevision = serverMenu.densityMapRevision;
    end
    self:getStatsFromMission(savegame);
    self:saveSavegameToXML(savegame, self.selectedIndex);

    saveXMLFile(g_savegameXML);

    local dir = self:getSavegameDirectory(self.selectedIndex);
    createFolder(dir);

    local wheatFilename = getDensityMapFileName(g_currentMission.wheatId);
    saveDensityMapToFile(g_currentMission.wheatId, dir .."/"..wheatFilename);

    local detailFilename = getDensityMapFileName(g_currentMission.terrainDetailId);
    saveDensityMapToFile(g_currentMission.terrainDetailId, dir .."/"..detailFilename);

    local grassFilename = getDensityMapFileName(g_currentMission.grassId);
    saveDensityMapToFile(g_currentMission.grassId, dir .."/"..grassFilename);

    local cuttedWheatFilename = getDensityMapFileName(g_currentMission.cuttedWheatId);
    saveDensityMapToFile(g_currentMission.cuttedWheatId, dir .."/"..cuttedWheatFilename);

    if g_currentMission.meadowId ~= nil then
    	local meadowFilename = getDensityMapFileName(g_currentMission.meadowId);
    	saveDensityMapToFile(g_currentMission.meadowId, dir .."/"..meadowFilename);
	end
	
	if g_currentMission.cuttedMeadowId ~= nil then
    	local cuttedMeadowFilename = getDensityMapFileName(g_currentMission.cuttedMeadowId);
    	saveDensityMapToFile(g_currentMission.cuttedMeadowId, dir .."/"..cuttedMeadowFilename);
    end
    
    if g_currentMission.strawId ~= nil then
    	local strawFilename = getDensityMapFileName(g_currentMission.strawId);
    	saveDensityMapToFile(g_currentMission.strawId, dir .."/"..strawFilename);
	end
	
	if g_currentMission.swathId ~= nil then
		local swathFilename = getDensityMapFileName(g_currentMission.swathId);
    	saveDensityMapToFile(g_currentMission.swathId, dir .."/"..swathFilename);
	end
	
	if g_currentMission.hayShiftingId ~= nil then
		local hayShiftingFilename = getDensityMapFileName(g_currentMission.hayShiftingId);
    	saveDensityMapToFile(g_currentMission.hayShiftingId, dir .."/"..hayShiftingFilename);
    end
end;

function serverMenu:loadSavegameFromXML(index)
    local savegame = {};
    local baseXMLName = "savegames.quickPlay.savegame"..index;
    savegame.valid = getXMLBool(g_savegameXML, baseXMLName .. "#valid");
    if savegame.valid ~= nil then
        savegame.stats = {};
        if savegame.valid then
            self:loadStatsFromXML(baseXMLName, savegame);
        else
            self:loadStatsDefaults(savegame);
        end;

        if not isOriginalGame then
       		savegame.densityMapRevision = Utils.getNoNil(getXMLInt(g_savegameXML, baseXMLName .. "#densityMapRevision"), 1);
		end

        local dir = self:getSavegameDirectory(index);
        savegame.vehiclesXML = dir .. "/vehicles.xml";

        table.insert(self.savegames, savegame);
        return true;
    end;
    return false;
end;

function serverMenu:getSavegameDirectory(index)
    return getUserProfileAppPath() .. "savegame"..index;
end;

function serverMenu:loadStatsDefaults(savegame)
    savegame.stats.fuelUsage = 0;
    savegame.stats.seedUsage = 0;
    savegame.stats.traveledDistance = 0;
    savegame.stats.hectaresSeeded = 0;
    savegame.stats.seedingDuration = 0;
    savegame.stats.hectaresThreshed = 0;
    savegame.stats.threshingDuration = 0;
    savegame.stats.farmSiloWheatAmount = 0;
    if isModAgri then
    	savegame.stats.farmSiloEnsilageAmount = 0;
    	savegame.stats.farmSiloEngraisAmount = 1000000000000000;
    	savegame.stats.farmSiloCurageAmount = 0;
    	savegame.stats.farmSiloFumierAmount = 0;   
    end
    savegame.stats.storedWheatFarmSilo = 0;
    savegame.stats.soldWheatPortSilo = 0;
    savegame.stats.revenue = 0;
    savegame.stats.expenses = 0;
    savegame.stats.playTime = 0;
    savegame.stats.money = 1000;
    -- environment settings
    savegame.stats.dayTime = 480;
    savegame.stats.timeUntilNextRain = 0;
    savegame.stats.rainTime = 0;
    savegame.stats.nextRainDuration = 0;
    savegame.stats.nextRainType = 0;
    savegame.stats.nextRainValid = false;
    savegame.stats.saveDate = "--.--.--";

end;

function serverMenu:loadStatsFromXML(baseXMLName, savegame)

    savegame.stats.fuelUsage = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#fuelUsage"), 0);
    savegame.stats.seedUsage = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#seedUsage"), 0);
    savegame.stats.traveledDistance = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#traveledDistance"), 0);
    savegame.stats.hectaresSeeded = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#hectaresSeeded"), 0);
    savegame.stats.seedingDuration = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#seedingDuration"), 0);
    savegame.stats.hectaresThreshed = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#hectaresThreshed"), 0);
    savegame.stats.threshingDuration = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#threshingDuration"), 0);
    savegame.stats.farmSiloWheatAmount = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#farmSiloWheatAmount"), 0);
    if isModAgri then
    	savegame.stats.farmSiloFumierAmount = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#farmSiloFumierAmount"), 0);  
    	savegame.stats.farmSiloEnsilageAmount = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#farmSiloEnsilageAmount"), 0);
    	savegame.stats.farmSiloEngraisAmount = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#farmSiloEngraisAmount"), 0);
    	savegame.stats.farmSiloCurageAmount = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#farmSiloCurageAmount"), 0);
    end
    savegame.stats.storedWheatFarmSilo = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#storedWheatFarmSilo"), 0);
    savegame.stats.soldWheatPortSilo = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#soldWheatPortSilo"), 0);
    savegame.stats.revenue = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#revenue"), 0);
    savegame.stats.expenses = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#expenses"), 0);
    savegame.stats.playTime = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#playTime"), 0);
    savegame.stats.money = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#money"), 1000);
    -- environment settings
    savegame.stats.dayTime = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#dayTime"), 480);
    savegame.stats.timeUntilNextRain = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#timeUntilNextRain"), 0);
    savegame.stats.rainTime = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#rainTime"), 0);
    savegame.stats.nextRainDuration = Utils.getNoNil(getXMLFloat(g_savegameXML, baseXMLName .. "#nextRainDuration"), 0);
    savegame.stats.nextRainType = Utils.getNoNil(getXMLInt(g_savegameXML, baseXMLName .. "#nextRainType"), 0);
    savegame.stats.nextRainValid = Utils.getNoNil(getXMLBool(g_savegameXML, baseXMLName .. "#nextRainValid"), false);
    savegame.stats.saveDate = Utils.getNoNil(getXMLString(g_savegameXML, baseXMLName .. "#saveDate"), "--.--.--");

end;

function serverMenu:saveStatsToXML(baseXMLName, savegame)

    setXMLFloat(g_savegameXML, baseXMLName .. "#fuelUsage", savegame.stats.fuelUsage);
    setXMLFloat(g_savegameXML, baseXMLName .. "#seedUsage", savegame.stats.seedUsage);
    setXMLFloat(g_savegameXML, baseXMLName .. "#traveledDistance", savegame.stats.traveledDistance);
    setXMLFloat(g_savegameXML, baseXMLName .. "#hectaresSeeded", savegame.stats.hectaresSeeded);
    setXMLFloat(g_savegameXML, baseXMLName .. "#seedingDuration", savegame.stats.seedingDuration);
    setXMLFloat(g_savegameXML, baseXMLName .. "#hectaresThreshed", savegame.stats.hectaresThreshed);
    setXMLFloat(g_savegameXML, baseXMLName .. "#threshingDuration", savegame.stats.threshingDuration);
    setXMLFloat(g_savegameXML, baseXMLName .. "#farmSiloWheatAmount", savegame.stats.farmSiloWheatAmount);
    if isModAgri then
    	setXMLFloat(g_savegameXML, baseXMLName .. "#farmSiloEnsilageAmount", savegame.stats.farmSiloEnsilageAmount);
    	setXMLFloat(g_savegameXML, baseXMLName .. "#farmSiloEngraisAmount", savegame.stats.farmSiloEngraisAmount);
    	setXMLFloat(g_savegameXML, baseXMLName .. "#farmSiloCurageAmount", savegame.stats.farmSiloCurageAmount);
    	setXMLFloat(g_savegameXML, baseXMLName .. "#farmSiloFumierAmount", savegame.stats.farmSiloFumierAmount);  
    end
    setXMLFloat(g_savegameXML, baseXMLName .. "#storedWheatFarmSilo", savegame.stats.storedWheatFarmSilo);
    setXMLFloat(g_savegameXML, baseXMLName .. "#soldWheatPortSilo", savegame.stats.soldWheatPortSilo);
    setXMLFloat(g_savegameXML, baseXMLName .. "#revenue", savegame.stats.revenue);
    setXMLFloat(g_savegameXML, baseXMLName .. "#expenses", savegame.stats.expenses);
    setXMLFloat(g_savegameXML, baseXMLName .. "#playTime", savegame.stats.playTime);
    setXMLFloat(g_savegameXML, baseXMLName .. "#money", savegame.stats.money);
    -- environment settings
    setXMLFloat(g_savegameXML, baseXMLName .. "#dayTime", savegame.stats.dayTime);
    setXMLFloat(g_savegameXML, baseXMLName .. "#timeUntilNextRain", savegame.stats.timeUntilNextRain);
    setXMLFloat(g_savegameXML, baseXMLName .. "#rainTime", savegame.stats.rainTime);
    setXMLFloat(g_savegameXML, baseXMLName .. "#nextRainDuration", savegame.stats.nextRainDuration);
    setXMLInt(g_savegameXML, baseXMLName .. "#nextRainType", savegame.stats.nextRainType);
    setXMLBool(g_savegameXML, baseXMLName .. "#nextRainValid", savegame.stats.nextRainValid);
    setXMLString(g_savegameXML, baseXMLName .. "#saveDate", savegame.stats.saveDate);

end;

function serverMenu:getStatsFromMission(savegame)

    local litersToRefill = 0;
    for i=1, table.getn(g_currentMission.vehicles) do
        litersToRefill = litersToRefill + (g_currentMission.vehicles[i].fuelCapacity-g_currentMission.vehicles[i].fuelFillLevel);
    end;

    savegame.stats.fuelUsage = g_currentMission.missionStats.fuelUsageTotal;
    savegame.stats.seedUsage = g_currentMission.missionStats.seedUsageTotal;
    savegame.stats.traveledDistance = g_currentMission.missionStats.traveledDistanceTotal;
    savegame.stats.hectaresSeeded = g_currentMission.missionStats.hectaresSeededTotal;
    savegame.stats.seedingDuration = g_currentMission.missionStats.seedingDurationTotal;
    savegame.stats.hectaresThreshed = g_currentMission.missionStats.hectaresThreshedTotal;
    savegame.stats.threshingDuration = g_currentMission.missionStats.threshingDurationTotal;
    savegame.stats.farmSiloWheatAmount = g_currentMission.missionStats.farmSiloWheatAmount;
    if isModAgri then
    	savegame.stats.farmSiloEnsilageAmount = g_currentMission.missionStats.farmSiloEnsilageAmount;
    	savegame.stats.farmSiloEngraisAmount = g_currentMission.missionStats.farmSiloEngraisAmount;
    	savegame.stats.farmSiloCurageAmount = g_currentMission.missionStats.farmSiloCurageAmount;
    	savegame.stats.farmSiloFumierAmount = g_currentMission.missionStats.farmSiloFumierAmount;     
    end
    savegame.stats.storedWheatFarmSilo = g_currentMission.missionStats.storedWheatFarmSiloTotal;
    savegame.stats.soldWheatPortSilo = g_currentMission.missionStats.soldWheatPortSiloTotal;
    savegame.stats.revenue = g_currentMission.missionStats.revenueTotal;
    savegame.stats.expenses = g_currentMission.missionStats.expensesTotal + litersToRefill*g_fuelPricePerLiter;
    savegame.stats.playTime = g_currentMission.missionStats.playTime;
    savegame.stats.money = g_currentMission.missionStats.money - litersToRefill*g_fuelPricePerLiter;
    -- environment settings
    savegame.stats.dayTime = g_currentMission.environment.dayTime/(1000*60);
    savegame.stats.timeUntilNextRain = g_currentMission.environment.timeUntilNextRain;
    savegame.stats.rainTime = g_currentMission.environment.rainTime;
    savegame.stats.nextRainDuration = g_currentMission.environment.nextRainDuration;
    savegame.stats.nextRainType = g_currentMission.environment.nextRainType;
    savegame.stats.nextRainValid = true;
    savegame.stats.saveDate = os.date("%d.%m.%Y");

end;

function OnserverMenuBack()
	gameMenuSystem:mainMenuMode();
	MPsettingsMenuSelected = ""
end;

function OnserverMenuPlay()
	gameMenuSystem.serverMenu:startSelectedGame();
	MPsettingsMenuSelected = ""
end;

function OnserverMenuDelete()
	gameMenuSystem.serverMenu:deleteSelectedGame();
end;

function OnserverMenuResetVehicles()
    gameMenuSystem.serverMenu:resetVehiclesOfSelectedGame();
end;

function OnserverMenuScrollUp()
    gameMenuSystem.serverMenu:setSelectedIndex(gameMenuSystem.serverMenu.selectedIndex-1);
end;

function OnserverMenuScrollDown()
    gameMenuSystem.serverMenu:setSelectedIndex(gameMenuSystem.serverMenu.selectedIndex+1);
end;