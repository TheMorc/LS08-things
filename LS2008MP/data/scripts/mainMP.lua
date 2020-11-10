-- MP main.lua injector
-- a part of the LS2008MP project

-- @author  Richard Gráčik (mailto:r.gracik@gmail.com)
-- @date  10.11.2020

--LS2008MP related stuff
isMPinjected = false
MPversion = 0.04

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
MPrunning = false --MP running/started state
MPinitSrvCli = false --first server/client init
MPpingStart = os.time()
MPpingEnd = MPpingStart+5

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
	print("LS2008MP your server IP: " .. MPip)
	print("LS2008MP your player name: " .. MPplayerName)
end

--MP update function
function MPupdate(dt)
	
	if MPrunning then
		MPHeartbeat()
		
		if os.time() >= MPpingEnd then
			MPpingStart = os.time()
			MPpingEnd = MPpingStart+5	
			--MPPing()
			for i,line in ipairs(MPcurrPlayerNameList) do
				--print(i .. line .. MPcurrPlayerIPList[i] .. MPcurrPlayerPortList[i])
			end
		end
	
	end
	
	original.update(dt)
end

--MP draw function
function MPdraw()
	setTextBold(true);
	renderText(0.0, 0.98, 0.02, "LS2008MP v" .. MPversion .. " | " .. MPstate .. " | running: " .. tostring(MPrunning) .. " | Player Name: " .. MPplayerName);
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
				MPrunning = not MPrunning
			end
		end
	end
	
	if isDown and MPchat and MPrunning then
		if sym == Input.KEY_esc then --escape to close the chat
			MPchat = false
			print("LS2008MP closing chat in-game chat")
			MPchatText = ""
			return
		elseif sym == Input.KEY_return then --enter/return to send the message
			print("LS2008MP sending a chat message")
			
			if MPstate == "Client" then
				MPudp:send("broadcast;"..MPplayerName.. ": " .. MPchatText)
			else
				handleUDPmessage("broadcast;"..MPplayerName.. ": " .. MPchatText, MPcurrClientIP, MPcurrClientPort)
			end
			
			MPchat = false
			MPchatText = ""
		elseif sym == 8 then --backspace
			MPchatText = string.sub(MPchatText,1, -2)
			return
		else --nothing from above, lets assume it is a normal letter and deSDLify it
			MPchatText = MPchatText .. deSDLify(sym)
			return
		end
	end
	
	if sym == Input.KEY_t and isDown and MPrunning then --open the chat
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

function deSDLify(kcd)
	if     kcd == 9		then return ""
	elseif kcd == 32	then return " "
	elseif kcd == 33	then return "!"
	elseif kcd == 42	then return "*"
	elseif kcd == 43	then return "+"
	elseif kcd == 44	then return ","
	elseif kcd == 45	then return "-"
	elseif kcd == 46	then return "."
	elseif kcd == 47	then return "/"
	elseif kcd == 97	then return "a"
	elseif kcd == 98	then return "b"
	elseif kcd == 99	then return "c"
	elseif kcd == 100	then return "d"
	elseif kcd == 101	then return "e"
	elseif kcd == 102	then return "f"
	elseif kcd == 103	then return "g"
	elseif kcd == 104	then return "h"
	elseif kcd == 105	then return "i"
	elseif kcd == 106	then return "j"
	elseif kcd == 107	then return "k"
	elseif kcd == 108	then return "l"
	elseif kcd == 109	then return "m"
	elseif kcd == 110	then return "n"
	elseif kcd == 111	then return "o"
	elseif kcd == 112	then return "p"
	elseif kcd == 113	then return "q"
	elseif kcd == 114	then return "r"
	elseif kcd == 115	then return "s"
	elseif kcd == 116	then return "t"
	elseif kcd == 117	then return "u"
	elseif kcd == 118	then return "v"
	elseif kcd == 119	then return "w"
	elseif kcd == 120	then return "x"
	elseif kcd == 121	then return "y"
	elseif kcd == 122	then return "z"
	else
		print("LS2008MP chat underfined char "..kcd)
		return "?"
	end
end

function handleUDPmessage(msg, msgIP, msgPort)
	local p = split(msg, ';')
	if p[1] == "chat" then
		--[[print("LS2008MP chat message from " .. msgIP .. ":" .. msgPort ..  ": " .. p[2])
		messageBy = ""
		for i,plrip in ipairs(MPcurrPlayerIPList) do
			if plrip == msgIP and MPcurrPlayerPortList[i] == msgPort then
				messageBy = tostring(MPcurrPlayerNameList[i])
			end
		end
		]]--
		printChat(p[2])
		
	elseif p[1] == "login" then --inform players that a new player has arrived and add him to player list
		print("LS2008MP " .. p[2] .. " joined from " .. msgIP .. ":" .. msgPort)
		handleUDPmessage("broadcast;"..p[2] .. " joined the game", msgIP, msgPort)
		
		MPcurrPlayerNameList[#MPcurrPlayerNameList+1] = p[2]
		MPcurrPlayerIPList[#MPcurrPlayerIPList+1] = msgIP
		MPcurrPlayerPortList[#MPcurrPlayerPortList+1] = msgPort
		
		MPudp:sendto("server;"..MPplayerName, msgIP, msgPort)
	elseif p[1] == "server" then --return the player list to the new connected client
		print("LS2008MP you are playing with " .. p[2] .. " on server " .. msgIP .. ":" .. msgPort)
		printChat("You are playing with " .. p[2])
		
		MPcurrPlayerNameList[#MPcurrPlayerNameList+1] = p[2]
		MPcurrPlayerIPList[#MPcurrPlayerIPList+1] = msgIP
		MPcurrPlayerPortList[#MPcurrPlayerPortList+1] = msgPort
	elseif p[1] == "broadcast" then
		print("LS2008MP " .. p[2] .. " broadcasted from " .. msgIP .. ":" .. msgPort)
		printChat(p[2])
		
		for i,player in ipairs(MPcurrPlayerNameList) do
			if i>1 then
				MPudp:sendto("chat;"..p[2], MPcurrPlayerIPList[i], MPcurrPlayerPortList[i])
			end
		end
		
		--MPudp:sendto("server;"..MPplayerName, msgIP, msgPort)
		
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
