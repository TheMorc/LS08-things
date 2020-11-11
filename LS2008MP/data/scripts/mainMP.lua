-- MP main.lua injector
-- a part of the LS2008MP project

-- @author  Richard Gráčik (mailto:r.gracik@gmail.com)
-- @date  10.11.2020

--LS2008MP related stuff
isMPinjected = false
MPversion = 0.05

--LuaSocket stuff
MPsocket = require("socket")
MPip, MPport = "127.0.0.1", 2008
MPudp = socket.udp()
MPudp:settimeout(0)
MPcurrClientIP = "127.0.0.1"
MPcurrClientPort = 0

--MP server-client variables
MPstate = "none"  --text state
MPHeartbeat = nil --MPServer or ClientHeartbeat function
MPenabled = false --MP enabled state (not connected)
MPinitSrvCli = false --server/client init/connect
MPupdateStart = os.time()
MPupdateEnd = MPupdateStart

--MP chat veriables
MPchat = false --chat view status
MPchatText = ""
MPchatHistory = {}
MPrenderHistory = false;
MPrenderHistoryCounterStart = os.time()
MPrenderHistoryCounterEnd = MPrenderHistoryCounterStart+20

MPcurrPlayerNameList = {}
MPcurrPlayerIPList = {}
MPcurrPlayerPortList = {}

MPupdateTick = 0

--original functions from main.lua
original = {  --(they are replaced with functions from this injector but a copy is left here)
	 drawing = draw,
	 update = update,
	 keyEvent = keyEvent
}

--MP main function used to inject main.lua
function init()
	if isMPinjected == false then --try loading the multiplayer mod
		print("LS2008MP v" .. MPversion)
		print("LS2008MP main.lua injector - load and init original")
		require("data/scripts/main")
		init() --exec init from original main.lua
		
		--write functions to the "original" class
		original.drawing = draw
		original.update = update
		original.keyEvent = keyEvent
		
		--unload the original main.lua
		print("LS2008MP main.lua injector - unload original")
		package.loaded["data/scripts/main"] = nil
		_G["data/scripts/main"] = nil
		
		--rewrite update and draw functions with MP versions
		update = MPupdate
		draw = MPdraw
		keyEvent = MPkeyEvent
		
		
		isMPinjected = true --done!
		print("LS2008MP main.lua injector - finished")
	end
	
	print("LS2008MP loading multiplayer settings")
	--package.path = package.path .. ";" .. getUserProfileAppPath()
    --copyFile(getAppBasePath() .. "multiplayerTemplate.lua", getUserProfileAppPath() .. "multiplayer.lua", false);
	require("multiplayer")
	MPplayerName = MPplayerName .. math.random (150)
	print("LS2008MP your server IP: " .. MPip)
	print("LS2008MP your player name: " .. MPplayerName)
end

--MP update function
function MPupdate(dt)
	
	if g_currentMission ~= nil and MPenabled then
		MPHeartbeat()
		
		--if os.time() >= MPupdateEnd then
		--	MPupdateStart = os.time()
		--	MPupdateEnd = MPupdateStart+.2
			--MPPing()
			--for i,line in ipairs(MPcurrPlayerNameList) do
				--print(i .. line .. MPcurrPlayerIPList[i] .. MPcurrPlayerPortList[i])
			--end
			if MPupdateTick > 5 then
				for i=1,#g_currentMission.vehicles do
					if g_currentMission.vehicles[i].isEntered then
						local tempTX, tempTY, tempTZ = getTranslation(g_currentMission.vehicles[i].rootNode)
						local tempRX, tempRY, tempRZ = getRotation(g_currentMission.vehicles[i].rootNode)
						UDPmoverot = "broadcast;moverot;"..MPplayerName.. ";" .. i..";"..tempTX..";"..tempTY..";"..tempTZ .. ";" ..tempRX..";"..tempRY..";"..tempRZ
					
						if MPstate == "Client" then
							MPudp:send(UDPmoverot)
						else
							handleUDPmessage(UDPmoverot, MPip, MPport)
							--handleUDPmessage(UDProt, MPip, MPport)
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
	renderText(0.0, 0.98, 0.02, "LS2008MP v" .. MPversion .. " | " .. MPstate .. " | enabled: " .. tostring(MPenabled) .. " | running: " .. tostring(MPinitSrvCli) .. " | Player Name: " .. MPplayerName);
	renderText(0.0, 0.96, 0.02, "IP: " .. MPip .. ":" .. MPport);
	setTextBold(false);
	
	if MPchat then
		renderText(0.0, 0.45, 0.03, "____________________________");
		renderText(0.0, 0.452, 0.03, MPchatText);
	end
	
	if MPrenderHistory then
		for i=1, #MPchatHistory do
				renderText(0.0, 0.452+(i*0.03), 0.03, MPchatHistory[#MPchatHistory + 1 - i])
		end	
		if not MPchat then
			if os.time() >= MPrenderHistoryCounterEnd then
				MPrenderHistory = false
			end
		end
	end
	
	original.drawing()
end

--MP update function
function MPkeyEvent(unicode, sym, modifier, isDown)
	
	if gameMenuSystem:isMenuActive() then
		if not MPchat then
			if sym == Input.KEY_c and isDown then
				print("LS2008MP client selected")
				MPstate = "Client"
				MPHeartbeat = MPClientHeartbeat
			end;
	
			if sym == Input.KEY_s and isDown then
				print("LS2008MP server selected")
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

function MPClientHeartbeat()
	if not MPinitSrvCli then
		MPinitSrvCli = true
		print("LS2008MP starting client - connecting to " .. MPip .. ":" .. MPport)
		MPudp:setpeername(MPip, MPport)
		MPudp:send("login;".. MPplayerName)
		MPcurrPlayerNameList[#MPcurrPlayerNameList+1] = MPplayerName
		MPcurrPlayerIPList[#MPcurrPlayerIPList+1] = "local"
		MPcurrPlayerPortList[#MPcurrPlayerPortList+1] = MPport
	end
	
	data = MPudp:receive()
	if data then
		handleUDPmessage(data, "Server", 2008)
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
		--[[print("LS2008MP chat message from " .. msgIP .. ":" .. msgPort ..  ": " .. p[2])
		messageBy = ""
		for i,plrip in ipairs(MPcurrPlayerIPList) do
			if plrip == msgIP and MPcurrPlayerPortList[i] == msgPort then
				messageBy = tostring(MPcurrPlayerNameList[i])
			end
		end
		]]--
		printChat(p[2])
		
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
		MPudp:sendto("server;"..p[2], msgIP, msgPort)
		
	elseif p[1] == "server" then --CLIENT return the player list to the new connected client
		print("LS2008MP you are playing with " .. p[2] .. " on server " .. msgIP .. ":" .. msgPort)
		printChat("You are playing with " .. p[2])
		
		MPcurrPlayerNameList[#MPcurrPlayerNameList+1] = p[2]
		MPcurrPlayerIPList[#MPcurrPlayerIPList+1] = msgIP
		MPcurrPlayerPortList[#MPcurrPlayerPortList+1] = msgPort
		
	elseif p[1] == "broadcast" then --SERVER broadcast the message to all clients
		print("LS2008MP " .. p[2] .. " broadcasted from " .. msgIP .. ":" .. msgPort)
		
		for i,player in ipairs(MPcurrPlayerNameList) do
			if i>1 then
				MPudp:sendto(string.sub(msg, 11), MPcurrPlayerIPList[i], MPcurrPlayerPortList[i])
			end
		end
		handleUDPmessage(string.sub(msg, 11), MPip, MPport)
		
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
	else
		print("LS2008MP undefined UDP message received from " .. msgIP .. ":" .. msgPort ..  ": " .. msg)
	end
end

function printChat(chatText)
	table.insert(MPchatHistory, chatText)	

	MPrenderHistoryCounterStart = os.time()
	MPrenderHistoryCounterEnd = MPrenderHistoryCounterStart+20
	MPrenderHistory = true
end
