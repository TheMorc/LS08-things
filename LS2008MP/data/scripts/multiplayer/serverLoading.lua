serverLoading = {};

local serverLoading_mt = Class(serverLoading);

function serverLoading:new(loadFunction)
    local instance = {};
    setmetatable(instance, serverLoading_mt);
    
    instance.items = {};
    instance.count = 0;
    instance.loadFunction = loadFunction;
    instance.missionId=0;
    instance.scriptClass="dummy";
    instance.isLoaded = false;
    
    instance.renderFrom = 1
    
    instance.pleaseWaitBgOverlay = Overlay:new("background01", "data/missions/please_wait_background.png", 0.05, 0.021, 0.9, 0.065);
    
    return instance;
end;

function serverLoading:delete()
    delete(self.buttonOverlay.overlayId);
    delete(self.pleaseWaitBgOverlay.overlayId);
end;

function serverLoading:addItem(item)
    table.insert(self.items, item);
end;

function serverLoading:mouseEvent(posX, posY, isDown, isUp, button)
    for i=1, table.getn(self.items) do
        self.items[i]:mouseEvent(posX, posY, isDown, isUp, button);
    end;
end;

function serverLoading:keyEvent(unicode, sym, modifier, isDown)
end;

function serverLoading:update(dt)
    self.count = self.count + 1;
    if self.count == 2 then
        self.loadFunction(self.scriptFilename, self.scriptClass, self.missionId, self.bronzeTime, self.silverTime, self.goldTime);
        self.isLoaded = true;
    	g_currentMission.isRunning = true;
    	self.renderFrom = 2
    	self.items[2] = Overlay:new("nil", "data/missions/mission00_briefing".. g_languageSuffix .. ".png", 0, 0, 0, 0) --replacing overlayBriefing with hidden overlay to not spam errors
        self.buttonOverlay = Overlay:new("play_button", "data/menu/ingame_play_button".. g_languageSuffix .. ".png", 0.5-0.15/2, 0.02, 0.15, 0.06);
        self:addItem(OverlayButton:new(self.buttonOverlay, OnserverLoadingFinish));
        MPupdateTick2 = 29 --speedup the tick thing
        MPoneTimeUpdateDone = true --oneTimeUpdateDone moved from MPupdate here, it's just more convenient
		MPmodifyVehicleScripts()
		if MPstate == "Client" then 
			MPudp:send("syncCurrentMissionToClient;")
			print("[LS2008MP] current mission sync requested")
		end
		MPdistanceIndex = Player.playerName
		MPcleanPlrListRefresh()
    end;
end;

function OnserverLoadingFinish()
    gameMenuSystem.currentMenu:delete();
    gameMenuSystem:playMode();
    setShowMouseCursor(false);
end

function serverLoading:render()
    for i=self.renderFrom, table.getn(self.items) do
        self.items[i]:render();
    end;
    
    if not self.isLoaded then
        self.pleaseWaitBgOverlay:render();
        
        setTextBold(true);
        --setTextColor(0,0,0,1);
        
        local str = ""
        if isOriginalGame then
        	str = "Mission wird geladen, bitte warten ...";
        else
        	str = g_i18n:getText("Mission_is_loading_please_wait");
        end
        local offset = 0;
        if self.missionId == 0 then
        	if isOriginalGame then
        		str = "Spiel wird geladen, bitte warten ...";
        	else
        		str = g_i18n:getText("Game_is_loading_please_wait");
        	end
            offset = 0.01;
        end;
        
        renderText(0.225+offset, 0.0275, 0.05, str);
        
        
        setTextColor(1,1,1,1);
        --setTextBold(false);
    end;

end;

function serverLoading:setScriptInfo(scriptFilename, scriptClass)
    self.scriptFilename = scriptFilename;
    self.scriptClass = scriptClass;
end;

function serverLoading:setMissionInfo(missionId, bronzeTime, silverTime, goldTime)
    self.missionId = missionId;
    self.bronzeTime = bronzeTime;
    self.silverTime = silverTime;
    self.goldTime = goldTime;
end;
