-- MP main.lua injector
-- a part of the LS2008MP project

-- @author  Richard Gráčik (mailto:r.gracik@gmail.com)
-- @date  10.11.2020

--LS2008MP related stuff
isMPinjected = false
MPversion = 0.06

--LuaSocket stuff
MPsocket = require("socket")
MPip, MPport = "127.0.0.1", 2008
MPudp = socket.udp()
MPudp:settimeout(0)
MPcurrClientIP = "127.0.0.1"
MPcurrClientPort = 0
clientTCP = assert(socket.tcp())
MPtcp = assert(socket.bind("*", 2008))
MPtcp:settimeout(10)
clientTCP:settimeout(10)

--MP server-client variables
MPstate = "none"  --text state
MPHeartbeat = nil --MPServer or ClientHeartbeat function
MPenabled = false --MP enabled state (not connected)
MPinitSrvCli = false --server/client init/connect
MPupdateStart = os.time()
MPupdateEnd = MPupdateStart
MPupdateTick = 0
MPticking = true --used when syncing new players (just like in LS2011 and newer)

--MP chat veriables
MPchat = false --chat view status
MPchatText = ""
MPchatHistory = {" ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", ""}
MPrenderHistory = false;
MPrenderHistoryCounterStart = os.time()
MPrenderHistoryCounterEnd = MPrenderHistoryCounterStart+20  

--MP player list
MPcurrPlayerNameList = {}
MPcurrPlayerIPList = {}
MPcurrPlayerPortList = {}

--MP GUI things
MPsettingsMenuSelected = ""
MPsettingsMenuxPos = 1-0.03-0.02-0.02-0.15*3

MPclientsavegame = {}
MPclientDir = ""

--original functions from game
original = {  --(they are replaced with functions from this injector but a copy is left here)
	 drawing = draw,
	 update = update,
	 keyEvent = keyEvent,
	 playerUpdate = nil,
	 vehicleUpdate = nil
}

--MP main function used to inject main.lua
function init()
	if isMPinjected == false then --try loading the multiplayer mod
		print("LS2008MP v" .. MPversion .. " init")
		print("LS2008MP main.lua injector - load and init original")
		source("data/scripts/main.lua")
		init() --exec init from original main.lua
		
		--write functions to the "original" class
		original.drawing = draw
		original.update = update
		original.keyEvent = keyEvent
		original.playerUpdate = Player.update
		original.vehicleUpdate = Vehicle.update
		
		--rewrite update and draw functions with MP versions
		update = MPupdate
		draw = MPdraw
		keyEvent = MPkeyEvent
		Player.update = MPfakeUpdate
		
		isMPinjected = true --done!
		print("LS2008MP main.lua injector - finished")
	end
	
	print("LS2008MP loading multiplayer settings")
	require("multiplayer")
	if MPplayerNameRndNums ~= true then
		MPplayerName = MPplayerName
	else
		MPplayerName = MPplayerName .. math.random (150)
	end
	print("LS2008MP your server IP: " .. MPip)
	print("LS2008MP your player name: " .. MPplayerName) 
	
	print("LS2008MP loading additional MP scripts") 
	source("data/scripts/multiplayer/serverMenu.lua")
	gameMenuSystem.serverMenu = serverMenu:new(gameMenuSystem.bgOverlay)
	source("data/scripts/multiplayer/serverLoading.lua")
	
	print("LS2008MP adding GUI and HUD") 
	--chat overlays
	hudMPchatHistory = Overlay:new("hudMPchatHistory", "data/missions/hud_help_base.png", 0.001, 0.485, 0.34, 0.477)
	hudMPchatTextField = Overlay:new("hudMPchatTextField", "data/missions/please_wait_background.png", 0.001, 0.45, 0.34, 0.03)
	
	--main menu buttons
	gameMenuSystem.mainMenu:addItem(OverlayButton:new(Overlay:new("GUIMPclientButton", MPclientButtonPath, 0.21, 0.5, 0.15, 0.06), MPopenClientMenu));
	gameMenuSystem.mainMenu:addItem(OverlayButton:new(Overlay:new("GUIMPserverButton", MPserverButtonPath, 0.21, 0.43, 0.15, 0.06), MPopenServerMenu));
	
	--client connect menu
	gameMenuSystem.MPsettingsMenu = OverlayMenu:new();
    gameMenuSystem.MPsettingsMenu:addItem(Overlay:new("background01",  "data/menu/background01".. g_languageSuffix .. ".png", 0, 0, 1, 1));
    gameMenuSystem.MPsettingsMenu:addItem(Overlay:new("main_logo", "data/menu/main_logo".. g_languageSuffix .. ".png", 0.1, 0.575, 0.8, 0.4));
	gameMenuSystem.MPsettingsMenu:addItem(Overlay:new("GUIMPsettingsBackground", "data/menu/settings_background.png", 0.02, 0.5-(0.07*7+0.01*2)+0.09, 0.95, (0.07*7+0.01*2)));
	MPsettingsMenuxPos = 1-0.03-0.02-0.02-0.15*3
    gameMenuSystem.MPsettingsMenu:addItem(OverlayButton:new(Overlay:new("GUIMPsettingsBackButton", "data/menu/back_button".. g_languageSuffix .. ".png", MPsettingsMenuxPos, 0.02, 0.15, 0.06), OnserverMenuBack));
    MPsettingsMenuxPos = MPsettingsMenuxPos + 0.15+0.02;
    gameMenuSystem.MPsettingsMenu:addItem(OverlayButton:new(Overlay:new("GUIMPsettingsSaveButton", "data/menu/save_button".. g_languageSuffix .. ".png", MPsettingsMenuxPos, 0.02, 0.15, 0.06), MPsettingsMenuSave));
    MPsettingsMenuxPos = MPsettingsMenuxPos + 0.15+0.02;
	gameMenuSystem.MPsettingsMenu:addItem(OverlayButton:new(Overlay:new("GUIMPclientPlayButton", "data/menu/ingame_play_button".. g_languageSuffix .. ".png", MPsettingsMenuxPos, 0.02, 0.15, 0.06), MPclientMenuConnect)); --client only button showing up in settings
	MPsettingsMenuxPos = MPsettingsMenuxPos + 0.15+0.02;
    gameMenuSystem.MPsettingsMenu:addItem(OverlayButton:new(Overlay:new("GUIMPsettingsSelectName", "data/menu/missionmenu_background.png", 0.35, 0.512, 0.55, 0.06), MPsettingsMenuSelectName));
	gameMenuSystem.MPsettingsMenu:addItem(OverlayButton:new(Overlay:new("GUIMPsettingsSelectIP", "data/menu/missionmenu_background.png", 0.35, 0.442, 0.55, 0.06), MPsettingsMenuSelectIP));
	gameMenuSystem.MPsettingsMenu:addItem(OverlayButton:new(Overlay:new("GUIMPsettingsSelectPort", "data/menu/missionmenu_background.png", 0.35, 0.372, 0.55, 0.06), MPsettingsMenuSelectPort));



	print("LS2008MP v" .. MPversion .. " init finished sucessfully") 
	
	
end

function MPopenServerMenu()
	print("LS2008MP server selected using GUI button")
	MPstate = "Server"
	MPHeartbeat = MPServerHeartbeat
	gameMenuSystem.serverMenu:reset();
    gameMenuSystem.currentMenu = gameMenuSystem.serverMenu;
end;

function MPopenClientMenu()
	print("LS2008MP client selected using GUI button")
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
	print("LS2008MP settings selected using GUI button")
	--MPsettingsMenuxPos = 1-0.03-0.02-0.02-0.15*2
	gameMenuSystem.MPsettingsMenu:reset();
	--[[if #gameMenuSystem.MPsettingsMenu.items == 9 then
		delete(gameMenuSystem.MPsettingsMenu.items,9)
    end]] --TODO: fix this
    gameMenuSystem.currentMenu = gameMenuSystem.MPsettingsMenu;
end;

function MPclientMenuConnect()
	MPinitSrvCli = false
	MPenabled = not MPenabled
	
	MPclientsavegame = gameMenuSystem.serverMenu.savegames[6];

    MPclientDir = gameMenuSystem.serverMenu:getSavegameDirectory(6);

    createFolder(MPclientDir);

	MPClientHeartbeat()
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

end
function MPsettingsMenuSave()
	print("LS2008MP client menu save settings")
	modifyMPSettings(MPplayerName, MPip, MPport)
end

function MPsettingsMenuSelectName()
	MPsettingsMenuSelected = "name"
	print("LS2008MP client menu name selected")
end

function MPsettingsMenuSelectIP()
	MPsettingsMenuSelected = "ip"
	print("LS2008MP client menu ip selected")
end

function MPsettingsMenuSelectPort()
	MPsettingsMenuSelected = "port"
	print("LS2008MP client menu port selected")
end

--MP player/vehicle fake update
function MPfakeUpdate(dt)
	return
end

--MP mission update
function MPmissionUpdate(dt)
	if gameMenuSystem:isMenuActive() then
		g_currentMission:update(dt)
		g_currentMission.isRunning = true
		Vehicle.update = MPfakeUpdate
	else
		original.playerUpdate(dt)
		Vehicle.update = original.vehicleUpdate
	end
end

--MP update function
function MPupdate(dt)
	
	if MPenabled and MPstate == "Client" then
		MPHeartbeat()
	end
	
	if g_currentMission ~= nil and MPenabled then
	
		if MPticking then
			MPmissionUpdate(dt)
		else
			g_currentMission.isRunning = false
		end
		
		MPHeartbeat()
    	
		--if os.time() >= MPupdateEnd then
		--	MPupdateStart = os.time()
		--	MPupdateEnd = MPupdateStart+.2
			--MPPing()
			--for i,line in ipairs(MPcurrPlayerNameList) do
				--print(i .. line .. MPcurrPlayerIPList[i] .. MPcurrPlayerPortList[i])
			--end
			if MPupdateTick == 1 then
				for i=1,#g_currentMission.vehicles do
					if g_currentMission.vehicles[i].isEntered and (g_currentMission.vehicles[i].lastSpeed*3600) >= 1 then
						local tempTX, tempTY, tempTZ = getTranslation(g_currentMission.vehicles[i].rootNode)
						local tempRX, tempRY, tempRZ = getRotation(g_currentMission.vehicles[i].rootNode)
						UDPmoverot = "broadcast;moverot;"..MPplayerName.. ";" .. i..";"..(tempTX+0)..";"..(tempTY+0)..";"..(tempTZ+0) .. ";" ..(tempRX+0)..";"..(tempRY+0)..";"..(tempRZ+0)
					
						if MPstate == "Client" then
							MPudp:send(UDPmoverot)
						else
							handleUDPmessage(UDPmoverot, MPip, MPport)
						end
					
					end
				end
				MPupdateTick = 0
			else
				MPupdateTick = MPupdateTick + 1
			end
		--end
	
	end
	
	
	original.update(dt)
	
end

--MP draw function
function MPdraw()
	
	setTextBold(true);
	local MPgameText = ""
	if MPrenderDebugText ~= true then
		MPgameText = "LS2008MP v" .. MPversion
	else
		MPgameText = "LS2008MP v" .. MPversion .. " | " .. MPstate .. " | enabled: " .. tostring(MPenabled) .. " | running: " .. tostring(MPinitSrvCli) .. " | Player Name: " .. MPplayerName
		renderText(0.0, 0.96, 0.02, "IP: " .. MPip .. ":" .. MPport);
	end
	renderText(0.0, 0.98, 0.02, MPgameText);
	setTextBold(false);
	
	
	if MPchat then
		hudMPchatTextField:render() 
		renderText(0.0, 0.45, 0.03, MPchatText);
	end
	
	
	if MPrenderHistory then
		--hudMPchatHistory:render()
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
		if MPmainMenuButtonsText ~= true then
		else
			setTextBold(true);
			renderText(0.225, 0.5, 0.06, "Client");
			renderText(0.218, 0.43, 0.06, "Server");
			setTextBold(false);
		end
	elseif gameMenuSystem.currentMenu == gameMenuSystem.MPsettingsMenu then
		--gameMenuSystem.clientMenu:addItem(Overlay:new("settings_resolution", "data/menu/settings_resolution".. g_languageSuffix .. ".png", 0.21, 0.5, 0.48*0.75, 0.06));
		setTextBold(true);
		renderText(0.1, 0.512,0.06, "Player name")
		renderText(0.1, 0.442,0.06, "  IP address")
		renderText(0.1, 0.372,0.06, "Port number")
		setTextBold(false);
		renderText(0.35, 0.51,0.06, MPplayerName)
		renderText(0.35, 0.44,0.06, MPip)
		renderText(0.35, 0.37,0.06, MPport.." ")
	end
	
		
end

--MP keyEvent function
function MPkeyEvent(unicode, sym, modifier, isDown)
	
	if gameMenuSystem.currentMenu == gameMenuSystem.MPsettingsMenu then
		if MPclientMenuSelected == "name" and isDown then
			if sym == 8 then --backspace
				MPplayerName = string.sub(MPplayerName,1, -2)
				return
			elseif sym == Input.KEY_return then
				MPclientMenuSelected = ""
			else --nothing from above, lets assume it is a normal letter and deSDLify it
				MPplayerName = MPplayerName .. string.char(sym)
				return
			end
		elseif MPclientMenuSelected == "ip" and isDown then
			if sym == 8 then --backspace
				MPip = string.sub(MPip,1, -2)
				return
			elseif sym == Input.KEY_return then
				MPclientMenuSelected = ""
			else --nothing from above, lets assume it is a normal letter and deSDLify it
				MPip = MPip .. string.char(sym)
				return
			end
		elseif MPclientMenuSelected == "port" and isDown then
			if sym == 8 then --backspace
				MPport = string.sub(MPport,1, -2)
				return
			elseif sym == Input.KEY_return then
				MPclientMenuSelected = ""
			else --nothing from above, lets assume it is a normal letter and deSDLify it
				MPport = MPport .. string.char(sym)
				return
			end
		end
	end
	
	if gameMenuSystem:isMenuActive() then
		if not MPchat then
			if sym == Input.KEY_c and isDown then
				print("LS2008MP client selected using keyboard")
				MPstate = "Client"
				MPHeartbeat = MPClientHeartbeat
			end;
	
			if sym == Input.KEY_s and isDown then
				print("LS2008MP server selected using keyboard")
				MPstate = "Server"
				MPHeartbeat = MPServerHeartbeat
			end;
		
			if sym == Input.KEY_x and isDown then
				MPinitSrvCli = false
				MPenabled = not MPenabled
			end
		end
	end
	
	if isDown and MPchat and MPenabled then
		if sym == Input.KEY_esc then --escape to close the chat
			MPchat = false
			print("LS2008MP closing chat in-game chat")
			MPchatText = ""
			return
		elseif sym == Input.KEY_return then --enter/return to send the message
			print("LS2008MP sending a chat message")
			
			if MPstate == "Client" then
				MPudp:send("broadcast;chat;"..MPplayerName.. ": " .. MPchatText)
			else
				handleUDPmessage("broadcast;chat;"..MPplayerName.. ": " .. MPchatText, MPip, MPport)
			end
			
			MPchat = false
			MPchatText = ""
		elseif sym == 8 then --backspace
			MPchatText = string.sub(MPchatText,1, -2)
			return
		else --nothing from above, lets assume it is a normal letter and deSDLify it
			MPchatText = MPchatText .. string.char(unicode)
			return
		end
	end
	
	if sym == Input.KEY_t and isDown and MPenabled then --open the chat
		MPrenderHistory = true
		MPchat = true
		print("LS2008MP opening in-game chat")
		return
	end;
	
	original.keyEvent(unicode, sym, modifier, isDown)
	--it's handling TAB, ESC but not input bindings for some weird reason, those are in update..
end


--heartbeat functions for server and client
function MPClientHeartbeat()
	if not MPinitSrvCli then
		MPinitSrvCli = true
		print("LS2008MP starting client - connecting to " .. MPip .. ":" .. MPport)
		--local translatedIP = socket.try(socket.dns.toip(MPip))
		MPudp:setpeername(MPip, MPport)
		MPudp:send("login;".. MPplayerName)
		MPcurrPlayerNameList[#MPcurrPlayerNameList+1] = MPplayerName
		MPcurrPlayerIPList[#MPcurrPlayerIPList+1] = "local"
		MPcurrPlayerPortList[#MPcurrPlayerPortList+1] = MPport
	end
	
	data = MPudp:receive()
	if data then
		handleUDPmessage(data, MPip, MPport)
	end
end
function MPServerHeartbeat()
	if not MPinitSrvCli then
		MPinitSrvCli = true
		print("LS2008MP starting server on port " .. MPport)
		MPudp:setsockname("*", MPport)
		MPcurrPlayerNameList[#MPcurrPlayerNameList+1] = MPplayerName
		MPcurrPlayerIPList[#MPcurrPlayerIPList+1] = "local"
		MPcurrPlayerPortList[#MPcurrPlayerPortList+1] = MPport
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

function split(s, delimiter)
	result = {}
	for match in (s..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(result, match)
	end
	return result
end

function handleUDPmessage(msg, msgIP, msgPort)
	local p = split(msg, ';')
	if p[1] == "chat" then --CLIENT print message on client
		print("LS2008MP chat: " .. p[2])
		printChat(p[2])
		
	elseif p[1] == "server" then --CLIENT return the player list to the new connected client
		print("LS2008MP you are playing with " .. p[2] .. " on server " .. msgIP .. ":" .. msgPort)
		printChat("You are playing with " .. p[2])
		
		MPcurrPlayerNameList[#MPcurrPlayerNameList+1] = p[2]
		MPcurrPlayerIPList[#MPcurrPlayerIPList+1] = msgIP
		MPcurrPlayerPortList[#MPcurrPlayerPortList+1] = msgPort
		
	elseif p[1] == "move" then --CLIENT recieve and move vehicle
		--print("LS2008MP " .. p[2] .. " moved in " .. p[3] .. " x:" .. p[4]+0 .. " y:" .. p[5]+0 .. " z:" .. p[6]+0)
		if MPplayerName ~= p[2] then
			setTranslation(g_currentMission.vehicles[p[3]+0].rootNode, p[4]+0, p[5]+0, p[6]+0)
		end
		
		
	elseif p[1] == "rot" then --CLIENT recieve and move vehicle
		--print("LS2008MP " .. p[2] .. " rotated in " .. p[3] .. " x:" .. p[4]+0 .. " y:" .. p[5]+0 .. " z:" .. p[6]+0)
		if MPplayerName ~= p[2] then
			--local vehicleHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, p[4], 0,  p[6]);
			--print(p[4])
			--print(p[5])
			--print(p[6])
			setRotation(g_currentMission.vehicles[p[3]+0].rootNode, p[4]+0, p[5]+0, p[6]+0)
			--local tempX, tempY, tempZ = getTranslation(g_currentMission.vehicles[p[3]+0].rootNode)
			--print(tempX)
			--print(tempY)
			--print(tempZ)
		end
		
		
	elseif p[1] == "moverot" then --CLIENT recieve and move vehicle
		if MPplayerName ~= p[2] then
			setTranslation(g_currentMission.vehicles[p[3]+0].rootNode, p[4]+0, p[5]+0, p[6]+0)
			setRotation(g_currentMission.vehicles[p[3]+0].rootNode, p[7]+0, p[8]+0, p[9]+0)
		end	
		
	elseif p[1] == "startTCP" then --startTCP used to transfer density files and vehicles.xml to the correct savegame folder from the server
		clientTCP:connect(MPip, MPport);
		while true do
    		local file, status, partial = clientTCP:receive()
    		if file ~= nil then
    			local receivedFile = split(file, ';')
				print("LS2008MP receiving file ".. receivedFile[1])
    			MPfileSave = assert(io.open(gameMenuSystem.quickPlayMenu:getSavegameDirectory(6).."/"..receivedFile[1], "wb"))
				MPfileSave:write(b64dec(receivedFile[2]))
    		end
    		if status == "closed" then
    			print("LS2008MP saying bye to the TCP file server") 
				clientTCP:close();
    			break
    		end
		end
		
		MPclientMenuConnContinue()
	
	--  SSSSS EEEEE RRRR  V   V EEEEE RRRR
	--  S     E     R   R V   V E     R   R
	--  SSSSS EEEE  RRRR  V   V EEEE  RRRR
	--      S E     R  R   V V  E     R  R
	--  SSSSS EEEEE R   R   V   EEEEE R   R
	
	elseif p[1] == "broadcast" then --SERVER broadcast the message to all clients
		--print("LS2008MP " .. p[2] .. " broadcasted from " .. msgIP .. ":" .. msgPort)
		
		for i,player in ipairs(MPcurrPlayerNameList) do
			if i>1 then
				MPudp:sendto(string.sub(msg, 11), MPcurrPlayerIPList[i], MPcurrPlayerPortList[i])
			end
		end
		handleUDPmessage(string.sub(msg, 11), MPip, MPport)
	
	elseif p[1] == "login" then --SERVER broadcast that a new player has arrived and add him to player list
		print("LS2008MP " .. p[2] .. " joined from " .. msgIP .. ":" .. msgPort)
		handleUDPmessage("broadcast;chat;"..p[2] .. " joined the game", msgIP, msgPort)
		
		MPcurrPlayerNameList[#MPcurrPlayerNameList+1] = p[2]
		MPcurrPlayerIPList[#MPcurrPlayerIPList+1] = msgIP
		MPcurrPlayerPortList[#MPcurrPlayerPortList+1] = msgPort
		
		
		playerList = ""
		if #MPcurrPlayerNameList<=2 then
			playerList = MPcurrPlayerNameList[1]
		else
			playerList = MPcurrPlayerNameList[1]
			for i=2,#MPcurrPlayerNameList-1 do
				playerList = playerList .. ", " .. MPcurrPlayerNameList[i]
			end
		end
		MPudp:sendto("server;"..playerList, msgIP, msgPort)
		
		--starting TCP listener
		MPudp:sendto("startTCP", msgIP, msgPort)
		
		--saving the game before sending data
		gameMenuSystem.quickPlayMenu:saveSelectedGame();
		
		
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
				print("LS2008MP sending file " .. v)
				--MPtcpClient:send(string.len(v .. ";" .. MPfileData .. "\n"))
				MPtcpClient:send(v .. ";" .. MPfileData .. "\r\n")
			end	
			MPtcpClient:close()
    	end
		
    	
	else
		print("LS2008MP undefined UDP message received from " .. msgIP .. ":" .. msgPort ..  ": " .. msg)
	end
end

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

function modifyMPSettings(newName, newIP, newPort)
	print("LS2008 saving multiplayer.lua with these values " .. newName .. " " .. newIP .. ":" .. newPort)
	local file = io.open(getAppBasePath() .. "multiplayer.lua", 'r')
    local fileContent = {}
    for line in file:lines() do
        table.insert (fileContent, line)
    end
    io.close(file)

	for i=1,#fileContent do
		print(fileContent[i])
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

local b64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+_'
-- encoding
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

-- decoding
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