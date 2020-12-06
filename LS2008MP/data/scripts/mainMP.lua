-- LS2008MP - main.lua injector
-- the main part of the LS2008MP project
-- beware!, this is an incredible spaghetti code and although it works somehow i just don't recommend even trying to touch it
-- because it may break out of sudden and not a single person will ever fix it. 
-- @author  Richard Gráčik (mailto:r.gracik@gmail.com)
-- @date  10.11.2020 - 6.12.2020

isMPinjected = false
MPversion = "0.10 luasockets"

--LuaSocket stuff
MPsocket = require("socket")
MPip, MPport = "127.0.0.1", 2008 --temporary ip and port
MPudp = socket.udp()
MPudp:settimeout(0)
MPcurrClientIP = "127.0.0.1"
MPcurrClientPort = 0
MPtcp = assert(socket.bind("*", 2008)) --it's fixed on port 2008 for now
MPtcp:settimeout(10)
clientTCP = assert(socket.tcp())
clientTCP:settimeout(10)

--MP server-client variables
MPstate = "none"  --global state of MP used by functions
MPHeartbeat = nil --MPServer/ClientHeartbeat function
MPenabled = false --MP enabled state (not connected)
MPinitSrvCli = false --server/client init/connect
MPupdateStart = os.time()
MPupdateEnd = MPupdateStart
MPupdateTick1 = 0
MPupdateTick2 = 0
MPticking = true --disabled when syncing new players (just like in LS2011 and newer)

--MP chat veriables
MPchat = false --chat view status
MPchatText = ""
MPchatHistory = {" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " "} --setting 16 empty lines, it was showing garbage before
MPrenderHistory = false;
MPrenderHistoryCounterStart = os.time()
MPrenderHistoryCounterEnd = MPrenderHistoryCounterStart+20  

--MP player list
MPplayers = {}
MPplayerIPs = {}
MPplayerPorts = {}
MPplayerVehicle = {}
MPplayerNode = {}

--MP GUI things
MPsettingsMenuSelected = ""
MPsettingsMenuxPos = 1-0.03-0.02-0.02-0.15*3

--savegame stuff
MPclientsavegame = {}
MPclientDir = ""

--player things
MPshowNewPlayer = false
MPnewPlayerName = ""

--array with original functions from game
original = {}

--MP main function used to inject main.lua
function init()
	print("[LS2008MP v" .. MPversion .. "] init")
	print("[LS2008MP] main.lua injector - load and init original")
	source("data/scripts/main.lua")
	init() --exec init from original main.lua

	--write functions to the "original" class
	original.drawing = draw
	original.update = update
	original.keyEvent = keyEvent
	original.playerUpdate = Player.update
	original.hasEvent = InputBinding.hasEvent
	original.getInputAxis = getInputAxis
	original.OnInGameMenuMenu = OnInGameMenuMenu
	
	--rewrite update and draw functions with MP versions
	update = MPupdate
	draw = MPdraw
	keyEvent = MPkeyEvent
	Player.update = MPfakeUpdate
	BaseMission.onEnterVehicle = MPonEnterVehicle
	BaseMission.onLeaveVehicle = MPonLeaveVehicle
	BaseMission.toggleVehicle = MPtoggleVehicle
	OnInGameMenuMenu = MPOnInGameMenuMenu
	InGameMenu.render = MPInGameMenuRender
		
	isMPinjected = true --done!
	print("[LS2008MP] main.lua injector - finished")
	
	print("[LS2008MP] loading multiplayer settings")
	require("multiplayer") --load /multiplayer.lua settings file
	if MPplayerNameRndNums then
		MPplayerName = MPplayerName .. math.random (150)
	end
	print("[LS2008MP] server address: " .. MPip .. ":" .. MPport)
	print("[LS2008MP] player name: " .. MPplayerName) 
	if MPchatKey == nil then
		MPchatKey = Input.KEY_t
		print("[LS2008MP] no chat key binding in multiplayer.lua, setting it to Input.KEY_t") 
	end
	print("[LS2008MP] current chat key binding: " .. MPchatKey) 
	print("[LS2008MP] loading i18n")
	if MPmenuPlayerText == nil then
		MPmenuPlayerText = "Player name"
		print("[LS2008MP] MPmenuPlayerText not found in multiplayer.lua, defaulting to \"" .. MPmenuPlayerText .. "\"") 
	end
	if MPmenuIPText == nil then
		MPmenuIPText = "  IP address"
		print("[LS2008MP] MPmenuIPText not found in multiplayer.lua, defaulting to \"" .. MPmenuIPText .. "\"") 
	end
	if MPmenuPortText == nil then
		MPmenuPortText = "Port number"
		print("[LS2008MP] MPmenuPortText not found in multiplayer.lua, defaulting to \"" .. MPmenuPortText .. "\"")  
	end
	if MPmenuWaitText == nil then
		MPmenuWaitText = "Wait.."
		print("[LS2008MP] MPmenuWaitText not found in multiplayer.lua, defaulting to \"" .. MPmenuWaitText .. "\"") 
	end
	if MPsyncingDataText == nil then
		MPsyncingDataText = "Syncing game data with %s\n          Please wait..."
		print("[LS2008MP] MPsyncingDataText not found in multiplayer.lua, defaulting to \"" .. MPsyncingDataText .. "\"") 
	end
	print("[LS2008MP] loading additional MP scripts") 
	source("data/scripts/multiplayer/serverMenu.lua")
	gameMenuSystem.serverMenu = serverMenu:new(gameMenuSystem.bgOverlay)
	source("data/scripts/multiplayer/serverLoading.lua")
	
	print("[LS2008MP] adding GUI and HUD") 
	--chat overlays
	hudMPchatHistory = Overlay:new("hudMPchatHistory", "data/menu/MP_chatoverlay.png", 0, 0.485, 0.34, 0.477)
	hudMPchatTextField = Overlay:new("hudMPchatTextField", "data/missions/please_wait_background.png", 0.001, 0.45, 0.34, 0.03)
	
	--main menu buttons
	gameMenuSystem.mainMenu.items[3] = OverlayButton:new(Overlay:new("GUIMPclientButton", MPclientButtonPath, 0.05, 0.5, 0.15, 0.06), MPopenClientMenu)
	gameMenuSystem.mainMenu.items[4] = OverlayButton:new(Overlay:new("GUIMPserverButton", MPserverButtonPath, 0.05, 0.43, 0.15, 0.06), MPopenServerMenu)
	
	--client connect menu
	gameMenuSystem.MPsettingsMenu = OverlayMenu:new();
    gameMenuSystem.MPsettingsMenu:addItem(Overlay:new("background01",  "data/menu/background01".. g_languageSuffix .. ".png", 0, 0, 1, 1));
    if MPuseNewLogo then
		gameMenuSystem.mainMenu.items[2] = Overlay:new("main_logo", "data/menu/MP_logo.png", 0.1, 0.53, 0.8, 0.4)
		gameMenuSystem.settingsMenu.items[2] = Overlay:new("main_logo", "data/menu/MP_logo.png", 0.1, 0.572, 0.8, 0.4)
		gameMenuSystem.MPsettingsMenu:addItem(Overlay:new("main_logo", "data/menu/MP_logo.png", 0.1, 0.53, 0.8, 0.4));
	else
		gameMenuSystem.MPsettingsMenu:addItem(Overlay:new("main_logo", "data/menu/main_logo".. g_languageSuffix .. ".png", 0.1, 0.575, 0.8, 0.4));
	end
    gameMenuSystem.MPsettingsMenu:addItem(Overlay:new("GUIMPsettingsBackground", "data/menu/settings_background.png", 0.02, 0.08, 0.95, 0.44));
	MPsettingsMenuxPos = 1-0.03-0.02-0.02-0.15*3
    gameMenuSystem.MPsettingsMenu:addItem(OverlayButton:new(Overlay:new("GUIMPsettingsBackButton", "data/menu/back_button".. g_languageSuffix .. ".png", MPsettingsMenuxPos, 0.02, 0.15, 0.06), OnserverMenuBack));
    MPsettingsMenuxPos = MPsettingsMenuxPos + 0.15+0.02;
    gameMenuSystem.MPsettingsMenu:addItem(OverlayButton:new(Overlay:new("GUIMPsettingsSaveButton", "data/menu/save_button".. g_languageSuffix .. ".png", MPsettingsMenuxPos, 0.02, 0.15, 0.06), MPsettingsMenuSave));
    MPsettingsMenuxPos = MPsettingsMenuxPos + 0.15+0.02;
	gameMenuSystem.MPsettingsMenu:addItem(OverlayButton:new(Overlay:new("GUIMPclientPlayButton", "data/menu/ingame_play_button".. g_languageSuffix .. ".png", MPsettingsMenuxPos, 0.02, 0.15, 0.06), MPclientMenuConnect)); --client only button showing up in settings
	gameMenuSystem.MPsettingsMenu:addItem(OverlayButton:new(Overlay:new("GUIMPsettingsSelectName", "data/menu/missionmenu_background.png", 0.35, 0.442, 0.55, 0.06), MPsettingsMenuSelectName));
	gameMenuSystem.MPsettingsMenu:addItem(OverlayButton:new(Overlay:new("GUIMPsettingsSelectIP", "data/menu/missionmenu_background.png", 0.35, 0.372, 0.55, 0.06), MPsettingsMenuSelectIP));
	gameMenuSystem.MPsettingsMenu:addItem(OverlayButton:new(Overlay:new("GUIMPsettingsSelectPort", "data/menu/missionmenu_background.png", 0.35, 0.302, 0.55, 0.06), MPsettingsMenuSelectPort));

	
	
	print("[LS2008MP v" .. MPversion .. "] initialized successfully, hooray!") 	
	setCaption("LS2008MP v" .. MPversion)
end

--MP GUI open and button functions
function MPopenServerMenu()
	print("[LS2008MP] server")
	MPstate = "Server"
	MPHeartbeat = MPServerHeartbeat
	gameMenuSystem.serverMenu:reset();
    gameMenuSystem.currentMenu = gameMenuSystem.serverMenu;
end;
function MPopenClientMenu()
	print("[LS2008MP] client")
	MPstate = "Client"
	MPHeartbeat = MPClientHeartbeat
	--MPsettingsMenuxPos = 1-0.03-0.02-0.02-0.15*3
	gameMenuSystem.MPsettingsMenu:reset();
	
    
	--if #gameMenuSystem.MPsettingsMenu.items == 8 then
		--gameMenuSystem.MPsettingsMenu:addItem(OverlayButton:new(Overlay:new("GUIMPclientPlayButton", "data/menu/ingame_play_button".. g_languageSuffix .. ".png", MPsettingsMenuxPos, 0.02, 0.15, 0.06), MPclientMenuConnect)); --client only button showing up in settings
    --end TODO: fix this
    --MPsettingsMenuxPos = MPsettingsMenuxPos + 0.15+0.02;
    gameMenuSystem.currentMenu = gameMenuSystem.MPsettingsMenu;
end;
function MPopenSettingsMenu()
	print("[LS2008MP] settings selected using GUI button")
	--MPsettingsMenuxPos = 1-0.03-0.02-0.02-0.15*2
	gameMenuSystem.MPsettingsMenu:reset();
	--[[if #gameMenuSystem.MPsettingsMenu.items == 9 then
		delete(gameMenuSystem.MPsettingsMenu.items,9)
    end]] --TODO: fix this
    gameMenuSystem.currentMenu = gameMenuSystem.MPsettingsMenu;
end;
function MPsettingsMenuSave()
	print("[LS2008MP] settings menu save settings")
	modifyMPSettings(MPplayerName, MPip, MPport)
end
function MPsettingsMenuSelectName()
	MPsettingsMenuSelected = "name"
end
function MPsettingsMenuSelectIP()
	MPsettingsMenuSelected = "ip"
end
function MPsettingsMenuSelectPort()
	MPsettingsMenuSelected = "port"
end
function MPOnInGameMenuMenu()
	if MPstate == "Client" then
		MPudp:send("logoff;"..MPplayerName)
	else
		handleUDPmessage("logoff;"..MPplayerName, MPip, MPport)
	end
	
	--original.OnInGameMenuMenu()
	restartApplication()
end
function MPclientMenuConnect()
	gameMenuSystem.MPsettingsMenu.items[6] = Overlay:new("GUIMPsettingsBackground", "data/missions/hud_mission_base.png", MPsettingsMenuxPos, 0.02, 0.15, 0.06)
	MPinitSrvCli = false
	MPenabled = true
	
	MPclientsavegame = gameMenuSystem.serverMenu.savegames[6];

    MPclientDir = gameMenuSystem.serverMenu:getSavegameDirectory(6);

    createFolder(MPclientDir);

	MPClientHeartbeat()
	
	MPupdateStart = os.time()
	MPupdateEnd = MPupdateStart+60
	
end;
function MPclientMenuConnContinue()

    setTerrainLoadDirectory(MPclientDir);
    
    g_missionLoaderDesc = {};
    g_missionLoaderDesc.scriptFilename = "data/missions/mission00.lua";
    g_missionLoaderDesc.scriptClass = "Mission00";
    g_missionLoaderDesc.id = 0;
    g_missionLoaderDesc.bronze = 0;
    g_missionLoaderDesc.silver = 0;
    g_missionLoaderDesc.gold = 0;
    g_missionLoaderDesc.overlayBriefing = gameMenuSystem.serverMenu.quickPlayBriefingOverlay;
    g_missionLoaderDesc.backgroundOverlay = gameMenuSystem.serverMenu.quickPlayBriefingBackgroundOverlay;
    g_missionLoaderDesc.overlayBriefingMedals = nil;
    g_missionLoaderDesc.stats = MPclientsavegame.stats;
    g_missionLoaderDesc.vehiclesXML = MPclientsavegame.vehiclesXML;

    stopSample(g_menuMusic);

    gameMenuSystem.loadScreen = serverLoading:new(OnLoadingScreen);
    gameMenuSystem.loadScreen:setScriptInfo(g_missionLoaderDesc.scriptFilename, g_missionLoaderDesc.scriptClass);
    gameMenuSystem.loadScreen:setMissionInfo(g_missionLoaderDesc.id, g_missionLoaderDesc.bronze, g_missionLoaderDesc.silver, g_missionLoaderDesc.gold);
    --gameMenuSystem.loadScreen:addItem(g_missionLoaderDesc.backgroundOverlay);
    gameMenuSystem.loadScreen:addItem(g_missionLoaderDesc.overlayBriefing);
    --self.loadScreen:addItem(g_missionLoaderDesc.overlayBriefingMedals);

    --gameMenuSystem.inGameMenu:setExtraOverlays(g_missionLoaderDesc.overlayBriefing);
    --self.inGameMenu.missionId=g_missionLoaderDesc.id;
    gameMenuSystem.inGameMenu:setMissionId(g_missionLoaderDesc.id);

    gameMenuSystem.currentMenu = gameMenuSystem.loadScreen;
	setCaption("LS2008MP v" .. MPversion .. " | Client | ".. MPplayerName)
end

--MP update and vehicle sync functions
function MPonEnterVehicle(self, vehicle)
	if not vehicle.MPsitting then
		g_currentMission.controlledVehicle = vehicle;
    	g_currentMission.controlledVehicle:onEnter();
    	g_currentMission.controlPlayer = false;
    	Player.onLeave();
    	g_currentMission.currentVehicle = g_currentMission.controlledVehicle;
		for i=1, table.getn(g_currentMission.vehicles) do
    	    if g_currentMission.vehicles[i] == g_currentMission.currentVehicle then
    	    	if MPstate == "Client" then
					MPudp:send("bc1;enteredVehicle;"..MPplayerName..";"..i)
				else
					handleUDPmessage("bc1;enteredVehicle;"..MPplayerName..";"..i, MPip, MPport)
				end
   			end
    	end
    end
end
function MPonLeaveVehicle()
	if g_currentMission.controlledVehicle ~= nil then
        g_currentMission.controlledVehicle:onLeave();
    end;
    g_currentMission.controlPlayer = true;
    cx, cy, cz = getWorldTranslation(g_currentMission.controlledVehicle.exitPoint);
    Player.onEnter();
    Player.moveToAbsolute(cx, cy, cz);
    g_currentMission.currentVehicle = nil;
    for i=1, table.getn(g_currentMission.vehicles) do
        if g_currentMission.vehicles[i] == g_currentMission.controlledVehicle then
        	if MPstate == "Client" then
				MPudp:send("bc1;leftVehicle;"..MPplayerName..";"..i)
			else
				handleUDPmessage("bc1;leftVehicle;"..MPplayerName..";"..i, MPip, MPport)
			end
        end
    end
end
function MPleftVehicle(i, playerName)
	if MPplayerName ~= playerName then
		local MPvehicle = g_currentMission.vehicles[tonumber(MPplayerVehicle[i])]
		
		--stopSample(MPvehicle.motorSound);
    	Utils.setEmittingState(MPvehicle.exhaustParticleSystems, false)
		MPvehicle.MPsitting = false
		for i=1, MPvehicle.numLights do
        	setVisibility(MPvehicle.lights[i], false);
    	end;
    	MPvehicle.lightsActive = false;
			
		for i=1,#MPplayers do
			if playerName == MPplayers[i] then
				setVisibility(MPplayerNode[i], true)
			end
		end
			
	end
end
function MPenterVehicle(i, playerName)
	if MPplayerName ~= playerName then
		local MPvehicle = g_currentMission.vehicles[tonumber(MPplayerVehicle[i])]
		
		MPvehicle.playMotorSound = true
		--playSample(MPvehicle.motorSound, 0, 1, 0); 
    	Utils.setEmittingState(MPvehicle.exhaustParticleSystems, true)
    	MPvehicle.MPsitting = true
    	
    	for i=1,#MPplayers do
			if playerName == MPplayers[i] then
				setVisibility(MPplayerNode[i], false)
			end
		end
    end
end
function MPtoggleVehicle(self)
	
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
            if not self.vehicles[index].isBroken and not self.vehicles[index].MPsitting or index == oldIndex then
                found = true;
            end;
        end;

        self:onEnterVehicle(self.vehicles[index]);

    end;
end

function MPsyncAttachImplement(vehicle, object, index)
	
	original.attachImplement(vehicle, object, index)
	
	for i=1, #g_currentMission.attachables do
      	if g_currentMission.attachables[i] == object then
    		if MPstate == "Client" then
				MPudp:send("bc1;attachImplement;"..MPplayerName..";"..i..";"..index)
			else
				handleUDPmessage("bc1;attachImplement;"..MPplayerName..";"..i..";"..index, MPip, MPport)
			end
        end 	
    end
end
function MPsyncDetachImplement(self, index)
	if MPstate == "Client" then
		MPudp:send("bc1;detachImplement;"..MPplayerName..";"..index)
	else
		handleUDPmessage("bc1;detachImplement;"..MPplayerName..";"..index, MPip, MPport)
	end 	
	
	original.detachImplement(self, index)
end

function MPsyncAttachTrailer(self, trailer)
	original.attachTrailer(self, trailer)
	
	for i=1, #g_currentMission.trailers do
      	if g_currentMission.trailers[i] == trailer then
    		if MPstate == "Client" then
				MPudp:send("bc1;attachTrailer;"..MPplayerName..";"..i)
			else
				handleUDPmessage("bc1;attachTrailer;"..MPplayerName..";"..i, MPip, MPport)
			end
        end 	
    end
end
function MPsyncDetachTrailer(self)
	if MPstate == "Client" then
		MPudp:send("bc1;detachTrailer;"..MPplayerName)
	else
		handleUDPmessage("bc1;detachTrailer;"..MPplayerName, MPip, MPport)
	end 	
	
	original.handleDetachTrailerEvent(self)
end

function MPsyncAttachCutter(self, cutter)
	original.attachCutter(self, cutter)
	for i=1, #g_currentMission.cutters do
      	if g_currentMission.cutters[i] == cutter then
    		if MPstate == "Client" then
				MPudp:send("bc1;attachCutter;"..MPplayerName..";"..i)
			else
				handleUDPmessage("bc1;attachCutter;"..MPplayerName..";"..i, MPip, MPport)
			end
        end 	
    end
end
function MPsyncDetachCurrentCutter(self)
	if MPstate == "Client" then
		MPudp:send("bc1;detachCurrentCutter;"..MPplayerName)
	else
		handleUDPmessage("bc1;detachCurrentCutter;"..MPplayerName, MPip, MPport)
	end 	
	
	original.detachCurrentCutter(self)
end

function MPvehicleUpdate(self, dt, isActive)
	if not gameMenuSystem:isMenuActive() then
		original.vehicleUpdate(self, dt, isActive)
	end
		
	if self.MPsitting then --update that is executed if someone's sitting in a vehicle
		--attached things update
		for i=1, table.getn(self.attachedImplements) do
    		self.attachedImplements[i].object:update(dt);
    	end;
        
    	--lights
		for i=1, self.numLights do
			local light = self.lights[i];
			setVisibility(light, self.lightsActive);
		end
		
		if self.MPinputEvent == "lower" then
			self.MPinputEvent = ""
			if self.selectedImplement ~= 0 then
        		local implement = self.attachedImplements[self.selectedImplement];
        		local jointDesc = self.attacherJoints[implement.jointDescIndex];
            	if self.MPeventState == "true" then
            		jointDesc.moveDown = true;
            	else
            		jointDesc.moveDown = false
            	end
    		end;
		elseif self.MPinputEvent == "lights" then
			self.MPinputEvent = ""
			if self.MPeventState == "true" then
				self.lightsActive = true
			else
				self.lightsActive = false
			end
            for i=1, self.numLights do
                local light = self.lights[i];
                setVisibility(light, self.lightsActive);
            end;
        elseif self.MPinputEvent == "switchImplement" then
        	self.MPinputEvent = ""
            self:setSelectedImplement(tonumber(self.MPeventState));
		end	
			
		--update for vehicle implement lowering
		for i=1, table.getn(self.attachedImplements) do
            local implement = self.attachedImplements[i];
            local jointDesc = self.attacherJoints[implement.jointDescIndex];
            --local jointDesc = self.attacherJoints[self.attachedAttachableIndex];

            local jointFrameInvalid = false;
            if jointDesc.rotationNode ~= nil then
                local x, y, z = getRotation(jointDesc.rotationNode);
                local rot = {x,y,z};
                local newRot = Utils.getMovedLimitedValues(rot, jointDesc.maxRot, jointDesc.minRot, 3, jointDesc.moveTime, dt, not jointDesc.moveDown);
                setRotation(jointDesc.rotationNode, unpack(newRot));
                for i=1, 3 do
                    if math.abs(newRot[i] - rot[i]) > 0.001 then
                        jointFrameInvalid = true;
                    end;
                end;
            end;
            if jointDesc.rotationNode2 ~= nil then
                local x, y, z = getRotation(jointDesc.rotationNode2);
                local rot = {x,y,z};
                local newRot = Utils.getMovedLimitedValues(rot, jointDesc.maxRot2, jointDesc.minRot2, 3, jointDesc.moveTime, dt, not jointDesc.moveDown);
                setRotation(jointDesc.rotationNode2, unpack(newRot));
                for i=1, 3 do
                    if math.abs(newRot[i] - rot[i]) > 0.001 then
                        jointFrameInvalid = true;
                    end;
                end;
            end;
            if jointFrameInvalid then
                setJointFrame(jointDesc.jointIndex, 0, jointDesc.jointTransform);
            end;

            local newRotLimit = {0,0,0};
            if not implement.object.fixedAttachRotation then
                newRotLimit = Utils.getMovedLimitedValues(implement.jointRotLimit, jointDesc.maxRotLimit, {0,0,0}, 3, jointDesc.moveTime, dt, not jointDesc.moveDown);
            end;
            for i=1, 3 do
                if math.abs(newRotLimit[i] - implement.jointRotLimit[i]) > 0.001 then
                    setJointRotationLimit(jointDesc.jointIndex, i-1, true, -newRotLimit[i], newRotLimit[i]);
                end;
            end;
            implement.jointRotLimit = newRotLimit;

            local newTransLimit = Utils.getMovedLimitedValues(implement.jointTransLimit, jointDesc.maxTransLimit, {0,0,0}, 3, jointDesc.moveTime, dt, not jointDesc.moveDown);
            for i=1, 3 do
                if math.abs(newTransLimit[i] - implement.jointTransLimit[i]) > 0.001 then
                    setJointTranslationLimit(jointDesc.jointIndex, i-1, true, -newTransLimit[i], newTransLimit[i]);
                end;
            end;
            implement.jointTransLimit = newTransLimit;
        end;
	end
	
	if self.isEntered then
		--well, this isn't the best way yet
	 	--for i=1, table.getn(g_currentMission.vehicles) do
        --	if g_currentMission.vehicles[i] == g_currentMission.controlledVehicle then
				--[[if (self.lastSpeed*3600) >= 1 then
					local tempTX, tempTY, tempTZ = getTranslation(self.rootNode)
					local tempRX, tempRY, tempRZ = getRotation(self.rootNode)
					UDPmoverot = "broadcast;moverot;"..MPplayerName.. ";" .. i..";"..(tempTX+0)..";"..(tempTY+0)..";"..(tempTZ+0) .. ";" ..(tempRX+0)..";"..(tempRY+0)..";"..(tempRZ+0)
					if MPstate == "Client" then
						MPudp:send(UDPmoverot)
					else
						handleUDPmessage(UDPmoverot, MPip, MPport)
					end
				end]]
		
	
        		if InputBinding.hasEvent(InputBinding.LOWER_IMPLEMENT) then
            		if self.selectedImplement ~= 0 then
        				LIimplement = self.attachedImplements[self.selectedImplement];
        				LIjointDesc = self.attacherJoints[LIimplement.jointDescIndex];
        				for i=1, table.getn(g_currentMission.vehicles) do
        					if g_currentMission.vehicles[i] == g_currentMission.controlledVehicle then
        						if MPstate == "Client" then
									MPudp:send("bc1;vehEvent;lower;"..MPplayerName..";"..i..";"..tostring(LIjointDesc.moveDown))
								else
									handleUDPmessage("bc1;vehEvent;lower;"..MPplayerName..";"..i..";"..tostring(LIjointDesc.moveDown), MPip, MPport)
								end
							end
						end
    				end;
        		elseif InputBinding.hasEvent(InputBinding.TOGGLE_LIGHTS) then
        	    	for i=1, table.getn(g_currentMission.vehicles) do
        				if g_currentMission.vehicles[i] == g_currentMission.controlledVehicle then
        					if MPstate == "Client" then
								MPudp:send("bc1;vehEvent;lights;"..MPplayerName..";"..i..";"..tostring(self.lightsActive))
							else
								handleUDPmessage("bc1;vehEvent;lights;"..MPplayerName..";"..i..";"..tostring(self.lightsActive), MPip, MPport)
							end
						end
					end
				elseif InputBinding.hasEvent(InputBinding.SWITCH_IMPLEMENT) then
					for i=1, table.getn(g_currentMission.vehicles) do
        				if g_currentMission.vehicles[i] == g_currentMission.controlledVehicle then
        					if MPstate == "Client" then
								MPudp:send("bc1;vehEvent;switchImplement;"..MPplayerName..";"..i..";"..tostring(self.selectedImplement))
							else
								handleUDPmessage("bc1;vehEvent;switchImplement;"..MPplayerName..";"..i..";"..tostring(self.selectedImplement), MPip, MPport)
							end
						end
					end
				end
		--	end
		--end
	end
end
function MPcombineUpdate(self, dt, isActive)
	original.combineUpdate(self, dt, isActive)
	
	if self.MPsitting then
		
		if self.MPinputEvent == "threshing" then --used on combines
			self.MPinputEvent = ""
			if self.grainTankFillLevel < self.grainTankCapacity then
                if self.attachedCutter ~= nil then
                    if self.MPeventState == "true" then
                        self:startThreshing();
                    else
                        self:stopThreshing();
                    end;
                end;
            end;
        elseif self.MPinputEvent == "lowerCutter" then
			self.MPinputEvent = ""
            if self.attachedCutter ~= nil then
            	if self.MPeventState == "true" then
                	self.cutterAttacherJointMoveDown = true;
                else
                	self.cutterAttacherJointMoveDown = false
                end
            end;
		elseif self.MPinputEvent == "pipe" then
			self.MPinputEvent = ""
			if self.MPeventState == "true" then
				self.pipeOpening = true;
			else
				self.pipeOpening = false
			end
		end
		
		--isEntered part of the combine code that needed to be stolen otherwise it wouldn't update just like the bit of code above
		if self.attachedCutter ~= nil then
		
			--stop on full
			if self.grainTankFillLevel == self.grainTankCapacity then
        	    self.attachedCutter:onStopReel();
        	end
		
			--lowering
			jointDesc = self.cutterAttacherJoint;
        	if jointDesc.jointIndex ~= 0 then
            if jointDesc.rotationNode ~= nil then
                local x, y, z = getRotation(jointDesc.rotationNode);
                local rot = {x,y,z};
                local newRot = Utils.getMovedLimitedValues(rot, jointDesc.maxRot, jointDesc.minRot, 3, jointDesc.moveTime, dt, not self.cutterAttacherJointMoveDown);
                setRotation(jointDesc.rotationNode, unpack(newRot));
                for i=1, 3 do
                    if math.abs(newRot[i] - rot[i]) > 0.001 then
                        jointFrameInvalid = true;
                    end;
                end;
            end;
            if jointDesc.rotationNode2 ~= nil then
                local x, y, z = getRotation(jointDesc.rotationNode2);
                local rot = {x,y,z};
                local newRot = Utils.getMovedLimitedValues(rot, jointDesc.maxRot2, jointDesc.minRot2, 3, jointDesc.moveTime, dt, not self.cutterAttacherJointMoveDown);
                setRotation(jointDesc.rotationNode2, unpack(newRot));
                for i=1, 3 do
                    if math.abs(newRot[i] - rot[i]) > 0.001 then
                        jointFrameInvalid = true;
                    end;
                end;
            end;
            if jointFrameInvalid then
                setJointFrame(jointDesc.jointIndex, 0, jointDesc.jointTransform);
            end;
        end;

			--calculate add to tank
        	if self.chopperActivated and self.attachedCutter.reelStarted and self.attachedCutter.lastArea > 0 then
            chopperEmitState = true;

            local literPerPixel = 8000/1200 / 6 / (2*2);

            literPerPixel = literPerPixel*1.5;

            self.grainTankFillLevel = self.grainTankFillLevel+self.attachedCutter.lastArea*literPerPixel*self.threshingScale;
            self:setGrainTankFillLevel(self.grainTankFillLevel);
        	end;
			
			--rotate chopper
			local chopperBlindRotationSpeed = 0.001;
        	local minRotX = -83*3.1415/180.0;
        	if self.chopperBlind ~= nil then
            local x,y,z = getRotation(self.chopperBlind);
            if self.chopperActivated then
                x = x-dt*chopperBlindRotationSpeed;
                if x < minRotX then
                    x = minRotX;
                end;
            else
                x = x+dt*chopperBlindRotationSpeed;
                if x > 0.0 then
                    x = 0.0;
                end;
            end;
            setRotation(self.chopperBlind, x, y, z);
        end;

			--open close pipe
        	local pipeRotationSpeed = 0.0006;
        	local pipeMinRotY = -105*3.1415/180.0;
        	local pipeMaxRotX = 10*3.1415/180.0;
        	local pipeXRotationSpeed = 0.00006;
        	if self.pipe ~= nil then
            local x,y,z = getRotation(self.pipe);
            if self.pipeOpening then
                y = y-dt*pipeRotationSpeed;
                if y < pipeMinRotY then
                    y = pipeMinRotY;
                end;
                x = x+dt*pipeXRotationSpeed;
                if x > pipeMaxRotX then
                    x = pipeMaxRotX;
                end;
            else
                y = y+dt*pipeRotationSpeed;
                if y > 0.0 then
                    y = 0.0;
                end;
                x = x-dt*pipeXRotationSpeed;
                if x < 0.0 then
                    x = 0.0;
                end;
            end;
            setRotation(self.pipe, x, y, z);
            self.pipeOpen = (math.abs(pipeMinRotY-y) < 0.01);
        end;
		end
	end
	
	if self.isEntered then
	if InputBinding.hasEvent(InputBinding.LOWER_IMPLEMENT) then
           	for i=1, table.getn(g_currentMission.vehicles) do
       			if g_currentMission.vehicles[i] == g_currentMission.controlledVehicle then
       				if MPstate == "Client" then
						MPudp:send("bc1;vehEvent;lowerCutter;"..MPplayerName..";"..i..";"..tostring(self.cutterAttacherJointMoveDown))
					else
						handleUDPmessage("bc1;vehEvent;lowerCutter;"..MPplayerName..";"..i..";"..tostring(self.cutterAttacherJointMoveDown), MPip, MPport)
					end
				end
			end
		elseif InputBinding.hasEvent(InputBinding.ACTIVATE_THRESHING) then
          	for i=1, table.getn(g_currentMission.vehicles) do
        		if g_currentMission.vehicles[i] == g_currentMission.controlledVehicle then
        			if MPstate == "Client" then
						MPudp:send("bc1;vehEvent;threshing;"..MPplayerName..";"..i..";"..tostring(self.attachedCutter:isReelStarted()))
					else
						handleUDPmessage("bc1;vehEvent;threshing;"..MPplayerName..";"..i..";"..tostring(self.attachedCutter:isReelStarted()), MPip, MPport)
					end
				end
			end
        elseif InputBinding.hasEvent(InputBinding.EMPTY_GRAIN) then
        	for i=1, table.getn(g_currentMission.vehicles) do
        		if g_currentMission.vehicles[i] == g_currentMission.controlledVehicle then
        			if MPstate == "Client" then
						MPudp:send("bc1;vehEvent;pipe;"..MPplayerName..";"..i..";"..tostring(self.pipeOpening))
					else
						handleUDPmessage("bc1;vehEvent;pipe;"..MPplayerName..";"..i..";"..tostring(self.pipeOpening), MPip, MPport)
					end
				end
			end
		end
	end
	
end
function MPplayerUpdate(dt)
	original.playerUpdate(dt)
	
	--manually getting the Y position of player
	--because guess who forgot to update it..
	local xt, yt, zt = getTranslation(Player.playerName);
    Player.lastYPos = yt;
end
function MPploughUpdate(self, dt)
	original.ploughUpdate(self, dt)
	
	if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
    	for i=1, #g_currentMission.attachables do
      		if g_currentMission.attachables[i] == self then
    			if MPstate == "Client" then
					MPudp:send("bc1;ploughRot;"..MPplayerName..";"..i..";"..tostring(self.rotationMax))
				else
					handleUDPmessage("bc1;ploughRot;"..MPplayerName..";"..i..";"..tostring(self.rotationMax), MPip, MPport)
				end
			end
		end
    end;
end
function MPsprayerUpdate(self, dt)
	original.sprayerUpdate(self, dt)
	
	if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
    	for i=1, #g_currentMission.attachables do
      		if g_currentMission.attachables[i] == self then
    			if MPstate == "Client" then
					MPudp:send("bc1;sprayerActive;"..MPplayerName..";"..i..";"..tostring(self.isActive))
				else
					handleUDPmessage("bc1;sprayerActive;"..MPplayerName..";"..i..";"..tostring(self.isActive), MPip, MPport)
				end
			end
		end
    end;
end
function MPmowerUpdate(self, dt)
	original.mowerUpdate(self, dt)
	
	if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
    	for i=1, #g_currentMission.attachables do
      		if g_currentMission.attachables[i] == self then
    			if MPstate == "Client" then
					MPudp:send("bc1;mowerActive;"..MPplayerName..";"..i..";"..tostring(self.isActive))
				else
					handleUDPmessage("bc1;mowerActive;"..MPplayerName..";"..i..";"..tostring(self.isActive), MPip, MPport)
				end
			end
		end
    end;
end
function MPtrailerAttachTrailer(self, trailer)
	original.trailerAttachTrailer(self, trailer)
	
	for i=1, #g_currentMission.trailers do
		for j=1, #g_currentMission.trailers do
      		if g_currentMission.trailers[i] == trailer and g_currentMission.trailers[j] == self then
    			if MPstate == "Client" then
					MPudp:send("bc1;trailerAttachTrailer;"..j..";"..i)
				else
					handleUDPmessage("bc1;trailerAttachTrailer;"..j..";"..i, MPip, MPport)
				end
        	end 	
        end
    end
end
function MPtoggleTipState(self)
	original.toggleTipState(self)
    for i=1, #g_currentMission.trailers do
      	if g_currentMission.trailers[i] == self then
    		if MPstate == "Client" then
				MPudp:send("bc1;toggleTipState;"..MPplayerName..";"..i)
			else
				handleUDPmessage("bc1;toggleTipState;"..MPplayerName..";"..i, MPip, MPport)
			end
		end
	end
end
function MPonStartTip(self)
	original.onStartTip(self)
	g_currentMission.allowSteerableMoving = true;
    g_currentMission.fixedCamera = false;
end

function MPfakeUpdate(dt)
	return
end
function MPfakeFunction()
	return
end
function MPmission00Update(self, dt)
	Mission00:superClass().update(self, dt);

    if self.environment.dayTime > 20*60*60*1000 or self.environment.dayTime < 6*60*60*1000 then
        -- timescale night
        self.environment.timeScale = g_settingsTimeScale;
    else
        -- timescale day
        self.environment.timeScale = g_settingsTimeScale/4;
    end;
    
    
    --the only part of the code that needed to be modified (but i'm still not sure if it won't break with ModAgri)
		for i=1, #self.trailers do	
      		if self.trailers[i].tipState == Trailer.TIPSTATE_OPENING or self.trailers[i].tipState == Trailer.TIPSTATE_OPEN  then
      			local trailer = self.trailers[i] --self.controlledVehicle.attachedTrailer;
            	if trailer.lastFillDelta < 0 then -- and self.currentTipTrigger ~= nil then
                    if trailer.currentFillType == Trailer.FILLTYPE_WHEAT then
                        if self.currentTipTrigger.isFarmTrigger then
                            self.missionStats.farmSiloWheatAmount = self.missionStats.farmSiloWheatAmount - trailer.lastFillDelta;

                            self.missionStats.storedWheatFarmSiloTotal = self.missionStats.storedWheatFarmSiloTotal - trailer.lastFillDelta;
                            self.missionStats.storedWheatFarmSiloSession = self.missionStats.storedWheatFarmSiloSession - trailer.lastFillDelta;
                        else
                            local money = g_wheatPricePerLiter*trailer.lastFillDelta;
                            self.missionStats.money = self.missionStats.money - money;

                            self.missionStats.revenueTotal = self.missionStats.revenueTotal - money;
                            self.missionStats.revenueSession = self.missionStats.revenueSession - money;

                            self.missionStats.soldWheatPortSiloTotal = self.missionStats.soldWheatPortSiloTotal - trailer.lastFillDelta;
                            self.missionStats.soldWheatPortSiloSession = self.missionStats.soldWheatPortSiloSession - trailer.lastFillDelta;
                        end;
                    elseif trailer.currentFillType == Trailer.FILLTYPE_GRASS then
                        local money = g_grassPricePerLiter*trailer.lastFillDelta;
                        self.missionStats.money = self.missionStats.money - money;

                        self.missionStats.revenueTotal = self.missionStats.revenueTotal - money;
                        self.missionStats.revenueSession = self.missionStats.revenueSession - money;
                    end;
                end;
            end;
        end;
end
function MPupdate(dt)
	
	if MPenabled then
		if MPstate == "Client" and g_currentMission == nil then
			MPHeartbeat()
			
			if os.time() >= MPupdateEnd then
				print("[LS2008MP] client connection timed out...")
				printChat("Client connection timed out..")
				gameMenuSystem.MPsettingsMenu.items[6] = OverlayButton:new(Overlay:new("GUIMPclientPlayButton", "data/menu/ingame_play_button".. g_languageSuffix .. ".png", MPsettingsMenuxPos, 0.02, 0.15, 0.06), MPclientMenuConnect)
				MPinitSrvCli = false
				MPenabled = false
			end
		end
	
		if g_currentMission ~= nil then
	
			MPHeartbeat()
    		
    		if MPupdateTick2 == 30 then
				if not MPoneTimeUpdateDone and gameMenuSystem.loadScreen.isLoaded then
						MPoneTimeUpdateDone = true
						if MPstate == "Client" then 
							MPudp:send("syncCurrentMissionToClient;")
							print("[LS2008MP] current mission sync requested")
							MPmodifyVehicleScripts()
						else 
							MPmodifyVehicleScripts()
						end
				end
				
				if gameMenuSystem:isMenuActive() then
					Player.update = MPfakeUpdate
				else
					Player.update = MPplayerUpdate
				end
				
				if MPserverPASG then
					MPserverPASG = false
					--now comes the fun part, it's called
					--sending game data
					--be prepared for crazy things and workarounds...

					--saving the game before sending data
					gameMenuSystem.serverMenu:saveSelectedGame();
					copyFile(gameMenuSystem.quickPlayMenu:getSavegameDirectory(gameMenuSystem.serverMenu.selectedIndex).."/wheat_density.png", gameMenuSystem.quickPlayMenu:getSavegameDirectory(gameMenuSystem.serverMenu.selectedIndex).."/z_MPfake.file", false);
		
					--preparing file list
					dircmd = string.gsub("dir \""..gameMenuSystem.quickPlayMenu:getSavegameDirectory(gameMenuSystem.serverMenu.selectedIndex).."\"", "/", "\\")
					os.execute(dircmd .. " /b > .MPfileList")
					local MPsavegameFiles = {}
					for f in io.lines(".MPfileList") do
  				  		MPsavegameFiles[#MPsavegameFiles+1] = f
					end
		
					--sending files
					MPtcpClient = MPtcp:accept()
  					if MPtcpClient then
  						for i,v in ipairs(MPsavegameFiles) do
							MPfileLoad = assert(io.open(gameMenuSystem.quickPlayMenu:getSavegameDirectory(gameMenuSystem.serverMenu.selectedIndex).."/"..v, "rb"))
							MPfileData = b64enc(MPfileLoad:read("*all"))
							print("[LS2008MP] sending file " .. v .. " to client " .. MPserverPASGip .. ":" .. MPserverPASGport)
							MPtcpClient:send(v .. ";" .. MPfileData .. "\r\n")
						end	
						MPtcpClient:close()
    				end

					handleUDPmessage("bc1;playerConnected;"..MPserverPASGname, MPserverPASGip, MPserverPASGport) --unfreezing the game
				end
				
				MPupdateTick2 = 0
			end
			MPupdateTick2 = MPupdateTick2 + 1
    	
			if not MPticking then
				g_currentMission.isRunning = false
				return
			end
		
			if gameMenuSystem:isMenuActive() then
				g_currentMission:update(dt)
				g_currentMission.isRunning = true
			end
		
			--[[if os.time() >= MPupdateEnd then
				MPupdateStart = os.time()
				MPupdateEnd = MPupdateStart+60
			end]]
			
			if MPupdateTick1 == 3 then
				for i=1,#g_currentMission.vehicles do
					if g_currentMission.vehicles[i].isEntered and (g_currentMission.vehicles[i].lastSpeed*3600) >= 1 then
						local tempTX, tempTY, tempTZ = getTranslation(g_currentMission.vehicles[i].rootNode)
						local tempRX, tempRY, tempRZ = getRotation(g_currentMission.vehicles[i].rootNode)
						UDPmoverot = "bc1;moverot;".."".. ";" .. i..";"..(round(tempTX+0,2))..";"..(round(tempTY+0,2))..";"..(round(tempTZ+0,2)) .. ";" ..(round(tempRX+0,2))..";"..(round(tempRY+0,2))..";"..(round(tempRZ+0,2))
						if MPstate == "Client" then
							MPudp:send(UDPmoverot)
						else
							handleUDPmessage(UDPmoverot, MPip, MPport)
						end
					end
				end
				
				if g_currentMission.controlPlayer then
					if Player.lastXPos ~= currXPos or Player.lastYPos ~= currYPos or Player.lastZPos ~= currZPos then
						UDPmoverot = "bc1;plr;"..MPplayerName..";"..(round(Player.lastXPos+0,2))..";"..(round(Player.lastYPos+0,2))..";"..(round(Player.lastZPos+0,2)) -- .. ";" ..(round(tempRX+0,2))..";"..(round(tempRY+0,2))..";"..(round(tempRZ+0,2))
						if MPstate == "Client" then
							MPudp:send(UDPmoverot)
						else
							handleUDPmessage(UDPmoverot, MPip, MPport)
						end
						--print(UDPmoverot)
					end
					
					if Player.rotX ~= currXRot or Player.rotY ~= currYRot then
						UDPmoverot = "bc1;plrot;"..MPplayerName..";"..(round(Player.rotY+0,2))
						if MPstate == "Client" then
							MPudp:send(UDPmoverot)
						else
							handleUDPmessage(UDPmoverot, MPip, MPport)
						end
					end
					
					currXPos = Player.lastXPos
					currYPos = Player.lastYPos
					currZPos = Player.lastZPos
					currYRot = Player.rotY
				end
				
				MPupdateTick1 = 0
			end
			
			
			MPupdateTick1 = MPupdateTick1 + 1
		end
	end
	
	
	original.update(dt)
	
end

--MP modify vehicle scripts, function called from MPoneTimeUpdate, function that also handles client sync
function MPmodifyVehicleScripts()
	if Mission00 ~= nil then
		original.missionUpdate = Mission00.update
		Mission00.update = MPmission00Update
		print("[LS2008MP] modified game script Mission00")
	else
		print("[LS2008MP] script Mission00 not found, well.. uh? what? how?")
	end
	
	if Vehicle ~= nil then
		original.vehicleUpdate = Vehicle.update	
		original.attachImplement = Vehicle.attachImplement
		original.detachImplement = Vehicle.detachImplement
		original.attachTrailer = Vehicle.attachTrailer
		original.handleDetachTrailerEvent = Vehicle.handleDetachTrailerEvent
		Vehicle.update = MPvehicleUpdate
		Vehicle.attachImplement = MPsyncAttachImplement
		Vehicle.detachImplement = MPsyncDetachImplement
		Vehicle.handleDetachTrailerEvent = MPsyncDetachTrailer
		Vehicle.attachTrailer = MPsyncAttachTrailer
		print("[LS2008MP] modified vehicle script Vehicle")
	else
		print("[LS2008MP] vehicle script Vehicle not found (This might not be a problem)")
	end
	
	if Combine ~= nil then
		original.attachCutter = Combine.attachCutter
		original.detachCurrentCutter = Combine.detachCurrentCutter
		original.combineUpdate = Combine.update
		Combine.attachCutter = MPsyncAttachCutter
		Combine.detachCurrentCutter = MPsyncDetachCurrentCutter
		Combine.update = MPcombineUpdate
		print("[LS2008MP] modified vehicle script Combine")
	else
		print("[LS2008MP] vehicle script Combine not found (This might not be a problem)")
	end

	if Plough ~= nil then
		original.ploughUpdate = Plough.update
		Plough.update = MPploughUpdate
		print("[LS2008MP] modified vehicle script Plough")
	else
		print("[LS2008MP] vehicle script Plough not found (This might not be a problem)")
	end
	
	if Sprayer ~= nil then
		original.sprayerUpdate = Sprayer.update
		Sprayer.update = MPsprayerUpdate
		print("[LS2008MP] modified vehicle script Sprayer")
	else
		print("[LS2008MP] vehicle script Sprayer not found (This might not be a problem)")
	end
	
	if Mower ~= nil then
		original.mowerUpdate = Mower.update
		Mower.update = MPmowerUpdate
		print("[LS2008MP] modified vehicle script Mower")
	else
		print("[LS2008MP] vehicle script Mower not found (This might not be a problem)")
	end
	
	if Trailer ~= nil then
		original.trailerAttachTrailer = Trailer.attachTrailer
		original.toggleTipState = Trailer.toggleTipState
		original.onStartTip = Trailer.onStartTip
		Trailer.attachTrailer = MPtrailerAttachTrailer
		Trailer.toggleTipState = MPtoggleTipState
		Trailer.onStartTip = MPonStartTip
		print("[LS2008MP] modified vehicle script Trailer")
	else
		print("[LS2008MP] vehicle script Trailer not found (This might not be a problem)")
	end
	
	--if ZG ~= nil then
		--print("[LS2008MP] modified custom script ZG")
	--else
	--	print("[LS2008MP] custom script ZG not found (Maybe you just don't have it)")
	--end
	
	print("[LS2008MP] script modification finished")
end

--modified in game menu render function to fix saving and remove save for client
function MPInGameMenuRender(self)
	if self.extraOverlay ~= nil then
        self.extraOverlay:render();
    end;

    if MPstate == "Client" then
    	self.items[1] = Overlay:new("nil", "data/menu/ingame_menu_restart".. g_languageSuffix .. ".png", 0, 0, 0, 0)
    	for i=2, table.getn(self.items) do
       		self.items[i]:render();
    	end;
    else
    	for i=1, table.getn(self.items) do
       		self.items[i]:render();
    	end;
	end

    if self.missionId ~= 0 then
        gameMenuSystem.medalsDisplay:render();
    end;

    if self.doSaveGame then
        self.doSaveGame = false;
        self.doSaveGamePart2 = true;
        self.savingOverlay:render();
    elseif self.doSaveGamePart2 then
        gameMenuSystem.serverMenu:saveSelectedGame();
        self.doSaveGamePart2 = false;
    end;
end

--MP draw function
function MPdraw()
	
	setTextBold(true);
	local MPgameText = "LS2008MP v" .. MPversion
	if MPrenderDebugText == true then
		MPgameText = "LS2008MP v" .. MPversion .. " | " .. MPstate .. " | Name: " .. MPplayerName .. " | IP: " .. MPip .. ":" .. MPport
	end
	renderText(0.0, 0.98, 0.02, MPgameText);
	setTextColor(0,1,1,1)
	if g_currentMission ~= nil then
		for i=1,#MPplayerVehicle do
			if MPplayers[i] ~= MPplayerName and MPplayers[i] ~= "N/A" then
				if MPplayerVehicle[i] ~= "none" then
					local x, y, z = getWorldTranslation(g_currentMission.vehicles[tonumber(MPplayerVehicle[i])].rootNode); 
					--local vx, vy, vz = getWorldTranslation(self.attachables[i].attacherJoint);
                	--local distance = Utils.vector3Length(x-vx, y-vy, z-vz);
    				x, y, z = project(x, y + 3.5, z);
    				if (x<1) and (y<1) and (z<1) and (x>0) and (y>0) and (z>0) then --and distance < 50 then          
    					renderText(x/1-0.04, y+0.01+0.02,0.03,MPplayers[i]);	
    				end;
    			else
    				local x, y, z = getWorldTranslation(tonumber(MPplayerNode[i])); 
					--local vx, vy, vz = getWorldTranslation(self.attachables[i].attacherJoint);
                	--local distance = Utils.vector3Length(x-vx, y-vy, z-vz);
    				x, y, z = project(x, y+0.5, z);
    				if (x<1) and (y<1) and (z<1) and (x>0) and (y>0) and (z>0) then --and distance < 50 then          
    					renderText(x/1-0.04, y+0.01+0.02,0.03,MPplayers[i]);	
    				end;
    			end
			end
		end	
    end
	setTextColor(1,1,1,1)
    setTextBold(false);
	
	if MPchat then
		hudMPchatTextField:render() 
		renderText(0.0, 0.45, 0.03, MPchatText);
	end
	
	if MPshowNewPlayerWarning then
		setTextBold(true);
        g_currentMission.hudWarningBaseOverlay:render();
        renderText(0.07+0.022+0.24, 0.019+0.029+1-0.539, 0.035, string.format(MPsyncingDataText, MPnewPlayerName));
        setTextBold(false);
	end
	
	if MPrenderHistory then
		hudMPchatHistory:render()
		for i=1, 16 do
				renderText(0.0, 0.452+(i*0.03), 0.03, MPchatHistory[#MPchatHistory + 1 - i])
		end	
		if not MPchat then
			if os.time() >= MPrenderHistoryCounterEnd then
				MPrenderHistory = false
			end
		end
	end
	
	original.drawing()
	
	if gameMenuSystem.currentMenu == gameMenuSystem.mainMenu then
		if MPmainMenuButtonsText == true then
			setTextBold(true);
			renderText(0.225, 0.5, 0.06, "Client");
			renderText(0.218, 0.43, 0.06, "Server");
			setTextBold(false);
		end
	elseif gameMenuSystem.currentMenu == gameMenuSystem.MPsettingsMenu then
		--gameMenuSystem.clientMenu:addItem(Overlay:new("settings_resolution", "data/menu/settings_resolution".. g_languageSuffix .. ".png", 0.21, 0.5, 0.48*0.75, 0.06)); fix bug
		setTextBold(true);
		renderText(0.1, 0.442,0.06, MPmenuPlayerText)
		renderText(0.1, 0.372,0.06, MPmenuIPText)
		renderText(0.1, 0.302,0.06, MPmenuPortText)
		if MPinitSrvCli then
			renderText(MPsettingsMenuxPos+0.02, 0.02, 0.06, MPmenuWaitText)
		end
		setTextBold(false);
		renderText(0.35, 0.44,0.06, MPplayerName)
		renderText(0.35, 0.37,0.06, MPip)
		renderText(0.35, 0.30,0.06, MPport.." ")
		
	end
	
		
end

--MP keyEvent function
function MPkeyEvent(unicode, sym, modifier, isDown)
	
	--client/settings menu key handling
	if gameMenuSystem.currentMenu == gameMenuSystem.MPsettingsMenu then
		if MPsettingsMenuSelected == "name" and isDown then
			if sym == 8 then --backspace
				MPplayerName = string.sub(MPplayerName,1, -2)
				return
			elseif sym == Input.KEY_return then
				MPsettingsMenuSelected = ""
			else --nothing from above, lets assume it is a normal letter and deSDLify it
				MPplayerName = MPplayerName .. string.char(sym)
				return
			end
		elseif MPsettingsMenuSelected == "ip" and isDown then
			if sym == 8 then --backspace
				MPip = string.sub(MPip,1, -2)
				return
			elseif sym == Input.KEY_return then
				MPsettingsMenuSelected = ""
			else --nothing from above, lets assume it is a normal letter and deSDLify it
				MPip = MPip .. string.char(sym)
				return
			end
		elseif MPsettingsMenuSelected == "port" and isDown then
			if sym == 8 then --backspace
				MPport = string.sub(MPport,1, -2)
				return
			elseif sym == Input.KEY_return then
				MPsettingsMenuSelected = ""
			else --nothing from above, lets assume it is a normal letter and deSDLify it
				MPport = MPport .. string.char(sym)
				return
			end
		end
	end
	
	--chat key handling
	if isDown and MPchat and MPenabled then
		if sym == Input.KEY_esc then --escape to close the chat
			MPchat = false
			MPchatText = ""
			InputBinding.hasEvent = original.hasEvent
			getInputAxis = original.getInputAxis
			return
		elseif sym == Input.KEY_return then --enter/return to send the message
			InputBinding.hasEvent = original.hasEvent
			getInputAxis = original.getInputAxis
			if string.len(MPchatText) ~= 0 then
				if MPstate == "Client" then
					MPudp:send("bc1;chat;"..MPplayerName.. ": " .. MPchatText)
				else
					handleUDPmessage("bc1;chat;"..MPplayerName.. ": " .. MPchatText, MPip, MPport)
				end
			end
			MPchat = false
			MPchatText = ""
		elseif 31 < unicode and unicode < 127 then 
			MPchatText = MPchatText..string.char(unicode)
		end
		if sym == 8 then
			if MPchatText:len() >= 1 then
				MPchatText = MPchatText:sub(1,MPchatText:len() - 1)
			end
		end
	end
	
	--chat opening
	if sym == MPchatKey and isDown and MPenabled then --open the chat
		MPrenderHistory = true
		MPchat = true
		InputBinding.hasEvent = MPfakeInputBinding --disabling vehicle input bindings
		getInputAxis = MPfakeInputAxis --disabling input axis for movement
		return
	end;
	
	if not MPchat then
		original.keyEvent(unicode, sym, modifier, isDown) --it's handling TAB, ESC and PDA but not input bindings for some weird reason, those are in update functions..
	end
	
end

--fake InputBinding hasEvent and getInputAxis functions for chat
function MPfakeInputBinding(button)
	return nil
end
--i could also use something like g_currentMission.allowSteerableMoving = false but that would only work in vehicles
function MPfakeInputAxis(axis)
	return 0
end

--MP heartbeat functions for server and client
function MPClientHeartbeat()
	if not MPinitSrvCli then
		MPinitSrvCli = true
		print("[LS2008MP] starting client connection to " .. MPip .. ":" .. MPport)
		--local translatedIP = socket.try(socket.dns.toip(MPip))
		MPudp:setpeername(MPip, MPport)
		MPudp:send("login;".. MPplayerName)
		MPaddToPlayerList(MPplayerName)
		MPchangeInPlayerList(#MPplayers,MPplayerName,"local",MPport)
	end
	
	data = MPudp:receive()
	if data then
		handleUDPmessage(data, MPip, MPport)
	end
end
function MPServerHeartbeat()
	if not MPinitSrvCli then
		MPinitSrvCli = true
		print("[LS2008MP] starting server on port " .. MPport)
		MPudp:setsockname("*", MPport)
		MPaddToPlayerList(MPplayerName)
		MPchangeInPlayerList(#MPplayers,MPplayerName,"local",MPport)
	end

	data, msg_or_ip, port_or_nil = MPudp:receivefrom()
	--print(data)
	if data then
		MPcurrClientIP = msg_or_ip
		MPcurrClientPort = port_or_nil
		handleUDPmessage(data, MPcurrClientIP, MPcurrClientPort)
		--MPudp:sendto("this is a server sending data to the client", msg_or_ip, port_or_nil)
	end
end

--the biggest function, the main sncer
function handleUDPmessage(msg, msgIP, msgPort)
	local p = split(msg, ';')
	if p[1] == "chat" then --CLIENT print message on client
		print("[LS2008MP] chat: " .. p[2])
		printChat(p[2])
		
	elseif p[1] == "server" then --CLIENT return the server host and player list to the new connected client
		print("[LS2008MP] you are playing with " .. p[2] .. " on server " .. msgIP .. ":" .. msgPort)
		clientTCP:connect(MPip, MPport);
		while true do
    		local file, status, partial = clientTCP:receive()
    		if file ~= nil then
    			local receivedFile = split(file, ';')
				print("[LS2008MP] receiving file ".. receivedFile[1])
    			MPfileSave = assert(io.open(gameMenuSystem.quickPlayMenu:getSavegameDirectory(6).."/"..receivedFile[1], "wb"))
				MPfileSave:write(b64dec(receivedFile[2]))
    		end
    		if status == "closed" then
    			print("[LS2008MP] saying bye to the TCP file server :(") 
				clientTCP:close();
    			break
    		end
		end
		
		MPaddToPlayerList(p[2]) --add serverhostplayer to the player list of the client
		playerList = ""
		if tonumber(p[3])<=2 then
			playerList = p[4]
		else
			playerList = p[4]
			for i=2,tonumber(p[3])-1 do
				if p[3+i] ~= "N/A" then
					playerList = playerList .. ", " .. p[3+i] --add this player's name to a string
					MPaddToPlayerList(p[3+i]) --add this player to the player list of the client 
				end
			end
		end
		
		MPclientMenuConnContinue()
		printChat("You are playing with " .. playerList) --print the new composed string
		
	elseif p[1] == "moverot" then --CLIENT recieve and move vehicle
		if g_currentMission.vehicles[p[3]+0].MPsitting then
			setTranslation(g_currentMission.vehicles[p[3]+0].rootNode, p[4]+0, p[5]+0, p[6]+0)
			setRotation(g_currentMission.vehicles[p[3]+0].rootNode, p[7]+0, p[8]+0, p[9]+0)
			g_currentMission.vehicles[p[3]+0].movingDirection = 1
		end	
	elseif p[1] == "playerConnecting" then
		MPshowNewPlayerWarning = true
		MPnewPlayerName = p[2]
		MPticking = false
		MPaddToPlayerList(p[2])
	elseif p[1] == "playerConnected" then
		MPshowNewPlayerWarning = false
		MPnewPlayerName = ""
		MPticking = true
	elseif p[1] == "enteredVehicle" then --set current vehicle to entered
		for i=1,#MPplayers do
			if p[2] == MPplayers[i] then
				MPplayerVehicle[i] = p[3]
				MPenterVehicle(i, p[2])
			end
		end
		--print("[LS2008MP] " .. p[2] .. " entered vehicle " .. p[3])
	elseif p[1] == "leftVehicle" then --set current vehicle to none
		for i=1,#MPplayers do
			if p[2] == MPplayers[i] then
				MPleftVehicle(i, p[2])
				MPplayerVehicle[i] = "none"
			end
		end	
		--print("[LS2008MP] " .. p[2] .. " left vehicle " .. p[3])
	elseif p[1] == "setCurrentMission" then
		g_currentMission.environment.dayTime = p[2]	
		g_currentMission.environment.timeUntilNextRain = p[3]
		g_currentMission.environment.nextRainType = p[4]
		g_currentMission.missionStats.money = p[5]
		g_currentMission.environment.timeScale = p[6]
				
	elseif p[1] == "vehEvent" then
		for i=1,#MPplayers do
			if p[3] == MPplayers[i] then
				if MPplayerName ~= p[3] then
					g_currentMission.vehicles[tonumber(MPplayerVehicle[i])].MPinputEvent = p[2]
					if p[5] ~= nil then
						g_currentMission.vehicles[tonumber(MPplayerVehicle[i])].MPeventState = p[5]
					end
				end
			end
		end
	elseif p[1] == "attachImplement" then
		for i=1,#MPplayers do
			if p[2] == MPplayers[i] then
				if MPplayerName ~= p[2] then
					original.attachImplement(g_currentMission.vehicles[tonumber(MPplayerVehicle[i])], g_currentMission.attachables[tonumber(p[3])], tonumber(p[4]))
				end
			end
		end
	elseif p[1] == "detachImplement" then
		for i=1,#MPplayers do
			if p[2] == MPplayers[i] then
				if MPplayerName ~= p[2] then
					original.detachImplement(g_currentMission.vehicles[tonumber(MPplayerVehicle[i])], tonumber(p[3]))
				end
			end
		end
	elseif p[1] == "attachTrailer" then
		for i=1,#MPplayers do
			if p[2] == MPplayers[i] then
				if MPplayerName ~= p[2] then
					original.attachTrailer(g_currentMission.vehicles[tonumber(MPplayerVehicle[i])], g_currentMission.trailers[tonumber(p[3])])
				end
			end
		end
	elseif p[1] == "detachTrailer" then
		for i=1,#MPplayers do
			if p[2] == MPplayers[i] then
				if MPplayerName ~= p[2] then
					original.handleDetachTrailerEvent(g_currentMission.vehicles[tonumber(MPplayerVehicle[i])])
				end
			end
		end
	elseif p[1] == "attachCutter" then
		for i=1,#MPplayers do
			if p[2] == MPplayers[i] then
				if MPplayerName ~= p[2] then
					original.attachCutter(g_currentMission.vehicles[tonumber(MPplayerVehicle[i])], g_currentMission.cutters[tonumber(p[3])])
				end
			end
		end
	elseif p[1] == "ploughRot" then
		for i=1,#MPplayers do
			if p[2] == MPplayers[i] then
				if MPplayerName ~= p[2] then
					if p[4] == "true" then
						g_currentMission.attachables[tonumber(p[3])].rotationMax = true
					else
						g_currentMission.attachables[tonumber(p[3])].rotationMax = false
					end
				end
			end
		end
	elseif p[1] == "sprayerActive" then
		for i=1,#MPplayers do
			if p[2] == MPplayers[i] then
				if MPplayerName ~= p[2] then
					if p[4] == "true" then
						g_currentMission.attachables[tonumber(p[3])].setActive(g_currentMission.attachables[tonumber(p[3])], true)
					else
						g_currentMission.attachables[tonumber(p[3])].setActive(g_currentMission.attachables[tonumber(p[3])], false)
					end
				end
			end
		end
	elseif p[1] == "mowerActive" then
		for i=1,#MPplayers do
			if p[2] == MPplayers[i] then
				if MPplayerName ~= p[2] then
					if p[4] == "true" then
						g_currentMission.attachables[tonumber(p[3])].isActive = true
					else
						g_currentMission.attachables[tonumber(p[3])].isActive = false
					end
				end
			end
		end
	elseif p[1] == "trailerAttachTrailer" then
		original.trailerAttachTrailer(g_currentMission.trailers[tonumber(p[2])], g_currentMission.trailers[tonumber(p[3])])
	elseif p[1] == "toggleTipState" then
		for i=1,#MPplayers do
			if p[2] == MPplayers[i] then
				if MPplayerName ~= p[2] then
					original.toggleTipState(g_currentMission.trailers[tonumber(p[3])])
				end
			end
		end
	elseif p[1] == "detachCurrentCutter" then
		for i=1,#MPplayers do
			if p[2] == MPplayers[i] then
				if MPplayerName ~= p[2] then
					original.detachCurrentCutter(g_currentMission.vehicles[tonumber(MPplayerVehicle[i])])
				end
			end
		end
		
	
	elseif p[1] == "playerDisconnected" then
		for i=1,#MPplayers do
			if MPplayers[i] == p[2] then
				MPplayerVehicle[i] = "none"
				MPchangeInPlayerList(i,"N/A","N/A",msgPort)
				setVisibility(MPplayerNode[i], false)
			end
		end
	elseif p[1] == "plr" then
		if p[2] ~= MPplayerName then
			for i=1,#MPplayers do
				if p[2] == MPplayers[i] then
					setTranslation(MPplayerNode[i], p[3]+0, p[4]+0, p[5]+0)
				end
			end
		end
	elseif p[1] == "plrot" then
		if p[2] ~= MPplayerName then
			for i=1,#MPplayers do
				if p[2] == MPplayers[i] then
					setRotation(MPplayerNode[i], 0, p[3]+0, 0)
				end
			end
		end
	elseif p[1] == "doNotConnect" then
		print("[LS2008MP] uh oh, you're using the same name as the server host...")
		printChat("Uh oh, you're using the same name as the server host. Please change your name and try again.")
		gameMenuSystem.MPsettingsMenu.items[6] = OverlayButton:new(Overlay:new("GUIMPclientPlayButton", "data/menu/ingame_play_button".. g_languageSuffix .. ".png", MPsettingsMenuxPos, 0.02, 0.15, 0.06), MPclientMenuConnect)
		MPinitSrvCli = false
		MPenabled = false
	elseif p[1] == "bc1" then --SERVER broadcast the message to all clients
		for i,player in ipairs(MPplayers) do
			if i>1 then
				if MPplayerIPs[i] ~= "N/A" then
					MPudp:sendto(string.sub(msg, 5), MPplayerIPs[i], MPplayerPorts[i])
				end
			end
		end
		handleUDPmessage(string.sub(msg, 5), MPip, MPport)
	
	elseif p[1] == "login" then --SERVER broadcast that a new player has arrived and add him to player list
		print("[LS2008MP] " .. p[2] .. " is trying to join from " .. msgIP .. ":" .. msgPort)
        if p[2] == MPplayerName then
        	MPudp:sendto("doNotConnect", msgIP, msgPort)
        	print("[LS2008MP] " .. p[2] .. " not connected because he has the same name as you..")
        	return
        end
		handleUDPmessage("bc1;chat;"..p[2] .. " joined the game", msgIP, msgPort)
		handleUDPmessage("bc1;playerConnecting;"..p[2], msgIP, msgPort)
		
		wasPlayerNameThere = false
		for i=1,#MPplayers do
			if MPplayers[i] == p[2] then
				wasPlayerNameThere = true
			end
		end
		
		if not wasPlayerNameThere then
			MPplayers[#MPplayers+1] = p[2]
			MPplayerVehicle[#MPplayerVehicle+1] = "none"
			MPchangeInPlayerList(#MPplayers,p[2],msgIP,msgPort)
		else
			for i=1,#MPplayers do
				if MPplayers[i] == p[2] then
					MPplayerVehicle[i] = "none"
					MPchangeInPlayerList(i,p[2],msgIP,msgPort)
				end
			end
		end
		
		playerList = ""
		if #MPplayers<=2 then
			playerList = MPplayers[1]
		else
			playerList = MPplayers[1]
			for i=2,#MPplayers-1 do
				playerList = playerList .. ";" .. MPplayers[i]
			end
		end
		MPudp:sendto("server;"..MPplayerName..";"..#MPplayers..";"..playerList, msgIP, msgPort)--send the raw player list to the new client
		
		MPserverPASG = true
		MPserverPASGip = msgIP
		MPserverPASGport = msgPort
		MPserverPASGname = p[2]
		MPupdateTick2 = 0

    	
    elseif p[1] == "logoff" then
    	print("[LS2008MP] " .. p[2] .. "left the server.. :(")
    	
    	if p[2] ~= MPplayerName then
    		handleUDPmessage("bc1;chat;"..p[2] .. " left the game", msgIP, msgPort)
    	else
    		handleUDPmessage("bc1;chat;"..p[2] .. " was your server host and left the game, so you can now peacefully leave too.. :(", msgIP, msgPort)
    	end
    	
    	handleUDPmessage("bc1;playerDisconnected;" .. p[2], msgIP, msgPort)
		
    elseif p[1] == "requestEntered" then --called from the new client to server to issue a enteredVehicle broadcast so that it can sync nametags
		for i=1, table.getn(g_currentMission.vehicles) do
       		if g_currentMission.vehicles[i] == g_currentMission.currentVehicle then
				handleUDPmessage("bc1;enteredVehicle;"..MPplayerName..";"..i, MPip, MPport)
			end
		end
	elseif p[1] == "syncCurrentMissionToClient" then
    	handleUDPmessage("bc1;requestEntered;", MPip, MPport)
    	MPudp:sendto("setCurrentMission;"..g_currentMission.environment.dayTime..";"..g_currentMission.environment.timeUntilNextRain..";"..g_currentMission.environment.nextRainType..";"..g_currentMission.missionStats.money..";"..g_currentMission.environment.timeScale, msgIP, msgPort)
    	
	else
		print("[LS2008MP] undefined UDP message(maybe older version of LS2008MP?) received from " .. msgIP .. ":" .. msgPort ..  ": " .. msg)
	end
end

--miscellaneous util functions
function split(s, delimiter)
	result = {}
	for match in (s..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(result, match)
	end
	return result
end

--MP player list modification
function MPaddToPlayerList(hisName)
	wasPlayerNameThere = false
	for i=1,#MPplayers do
		if MPplayers[i] == hisName then
			wasPlayerNameThere = true
		end
	end
		
	if not wasPlayerNameThere then
		MPplayers[#MPplayers+1] = hisName
		MPplayerVehicle[#MPplayerVehicle+1] = "none"
    	MPplayerNode[#MPplayerNode+1] = loadI3DFile("data/scripts/multiplayer/farmer.i3d"); --loading the MP player i3d
    	link(getRootNode(), MPplayerNode[#MPplayerNode]) --linking the i3d to map (??)
	else
		for i=1,#MPplayers do
			if MPplayers[i] == hisName then
				MPplayerVehicle[i] = "none"
				MPchangeInPlayerList(i,hisName,"N/A",MPport)
				MPplayerNode[i] = loadI3DFile("data/scripts/multiplayer/farmer.i3d"); --loading the MP player i3d
    			link(getRootNode(), MPplayerNode[i]) --linking the i3d to map (??)
			end
		end
	end
end
function MPchangeInPlayerList(hisID,hisName,hisIP,hisPort)
	MPplayers[hisID] = hisName
	MPplayerIPs[hisID] = hisIP
	MPplayerPorts[hisID] = hisPort
end

--function used through the code to split and print a message to the chat
function printChat(chatText)
	--38 chars per line
    local s = {}
    for i=1, #chatText, 38 do
        s[#s+1] = chatText:sub(i,i+38 - 1)
    end
	
	for i,separatedLine in ipairs(s) do
		table.insert(MPchatHistory, separatedLine)	
	end

	MPrenderHistoryCounterStart = os.time()
	MPrenderHistoryCounterEnd = MPrenderHistoryCounterStart+20
	MPrenderHistory = true
end

--save settings to multiplayer.lua
function modifyMPSettings(newName, newIP, newPort)
	print("[LS2008MP] saving multiplayer.lua with these values " .. newName .. " " .. newIP .. ":" .. newPort)
	local file = io.open(getAppBasePath() .. "multiplayer.lua", 'r')
    local fileContent = {}
    for line in file:lines() do
        table.insert (fileContent, line)
    end
    io.close(file)

	for i=1,#fileContent do
		--print(fileContent[i])
        if string.starts(fileContent[i], "MPip = ") then
        	fileContent[i] = "MPip = \"".. newIP .. "\""
        elseif string.starts(fileContent[i], "MPport = ") then
        	fileContent[i] = "MPport = ".. newPort
        elseif string.starts(fileContent[i], "MPplayerName = ") then
        	fileContent[i] = "MPplayerName = \"".. newName .. "\""
        end
    end

    file = io.open("multiplayer.lua", 'w')
    for index, value in ipairs(fileContent) do
        file:write(value..'\n')
    end
    io.close(file)
end
function string.starts(str, start)
   return str:sub(1, #start) == start
end

--base64 things used for savegame transfer (code borrowed from StackOverflow, thanks guys)
local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+_'
function b64enc(data)
    return ((data:gsub('.', function(x) 
        local r,b64='',x:byte()
        for i=8,1,-1 do r=r..(b64%2^i-b64%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b64:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end
function b64dec(data)
    data = string.gsub(data, '[^'..b64..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b64:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
    end))
end

function round(num, numDecimalPlaces)
  return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

--[[
The weird thing is that this spaghetti code works
and the even more weird thing is that people are using it
I'm doing all that i could do for LS2008 community.
I also didn't think that adding multiplayer was this weird of a job...
But here you have it, enjoy.

Made with <3 in Biskupová by Morc.

btw, my machine right now is a total shitbox:
Gigabyte Z97-HD3 partially dead
i5-4460
GTX 650
16GB RAM
dead 128GB SSD

and do you know what's interesting?
i didn't take a look in the LS2011 MP code even once
]]