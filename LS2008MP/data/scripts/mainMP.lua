-- MP main.lua injector
-- a part of the LS2008MP project

-- @author  Richard Gráčik (mailto:r.gracik@gmail.com)
-- @date  10.11.2020

--LS2008MP related stuff
isMPinjected = false
MPversion = 0.03

--LuaSocket stuff
MPsocket = require("socket")
MPip, MPport = "176.101.178.133", 2008
MPudp = socket.udp()
MPudp:settimeout(0)
MPcurrClientIP = "127.0.0.1"
MPcurrClientPort = 1234

--MP server-client variables
MPstate = "none"  --text state
MPHeartbeat = nil --MPServer or ClientHeartbeat function
MPrunning = false --MP running/started state
MPinitSrvCli = false --first server/client init

--MP chat veriables
MPchat = false --chat view status
MPchatText = ""
MPchatHistory = {}


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
		
		
		isMPinjected = true --done!lua 
		print("LS2008MP main.lua injector - finished")
	end
end

--MP update function
function MPupdate(dt)
	
	if MPrunning then
		MPHeartbeat()
	end
	
	original.update(dt)
end

--MP draw function
function MPdraw()
	setTextBold(true);
	renderText(0.0, 0.98, 0.02, "LS2008MP v" .. MPversion .. " as " .. MPstate .. " - running: " .. tostring(MPrunning));
	renderText(0.0, 0.96, 0.02, "IP: " .. MPip .. ":" .. MPport);
	setTextBold(false);
	
	if MPchat then
		renderText(0.0, 0.45, 0.04, "____________________________");
		renderText(0.0, 0.452, 0.04, MPchatText);
	end
	
	for i,line in ipairs(MPchatHistory) do
      renderText(0.0, 0.452+(i*0.04), 0.04, MPchatHistory[i]);
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
		if sym == Input.KEY_esc then
			MPchat = false
			print("LS2008MP closing chat in-game chat")
			MPchatText = ""
			return
		elseif sym == Input.KEY_return then
			print("LS2008MP sending a chat message")
			table.insert(MPchatHistory, "Player: " .. MPchatText)
			if MPstate == "Client" then
				MPudp:send("chat;"..MPchatText)
			else
				MPudp:sendto("chat;"..MPchatText, MPcurrClientIP, MPcurrClientPort)
			end
			MPchat = false
			MPchatText = ""
		else
			MPchatText = MPchatText .. sym
			return
		end
	end
	
	if sym == Input.KEY_t and isDown and MPrunning then
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
		MPudp:send("login;Login message")
	end
	
	data = MPudp:receive()
	if data then
		handleUDPmessage(data, "Server", 2008)
	end
	
end

function MPServerHeartbeat()
	if not MPinitSrvCli then
		MPinitSrvCli = true
		print("LS2008MP starting server")
		MPudp:setsockname("*", MPport)
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
	if p[1] == "chat" then
		print("LS2008MP chat message from " .. msgIP .. ":" .. msgPort ..  ": " .. p[2])
		table.insert(MPchatHistory, "Player2: " .. p[2])
	elseif p[1] == "login" then
		print("LS2008MP player joined from " .. msgIP .. ":" .. msgPort ..  ": " .. p[2])
		table.insert(MPchatHistory, "Player2 joined the game")
	else
		print("LS2008MP undefined UDP message received from " .. msgIP .. ":" .. msgPort ..  ": " .. msg)
	end
end