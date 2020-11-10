-- MP main.lua injector
-- a part of the LS2008MP project

-- @author  Richard Gráčik (mailto:r.gracik@gmail.com)
-- @date  10.11.2020

MPsocket = require("socket")
MPip, MPport = "176.101.178.133", 2008
MPudp = socket.udp()
MPudp:settimeout(0)

isMPloaded = false
MPversion = 0.02

MPstate = "none"
MPHeartbeat = nil
MPstarted = false
MPinitSrvCli = false

original = { 
	 drawing = draw,
	 update = update,
	 keyEvent = keyEvent
}

--MP main function used to inject main.lua
function init()
	if isMPloaded == false then --try loading the multiplayer mod
		print("LS2008MP v" .. MPversion)
		print("LS2008MP main.lua injector - load and init original")
		require("data/scripts/main") --load the original main.lua
		init() --exec init from original main.lua
		
		--write functions to the "original" class
		original.drawing = draw
		original.update = update
		original.keyEvent = keyEvent
		
		--unload main.lua
		print("LS2008MP main.lua injector - unload original")
		package.loaded["data/scripts/main"] = nil
		_G["data/scripts/main"] = nil
		
		--rewrite update and draw functions with MP versions
		update = MPupdate
		draw = MPdraw
		keyEvent = MPkeyEvent
		
		
		isMPloaded = true
		print("LS2008MP main.lua injector - finished")
	end
end

--MP update function
function MPupdate(dt)
	
	if MPstarted then
		MPHeartbeat()
	end
	
	original.update(dt)
end

--MP draw function
function MPdraw()
	setTextBold(true);
	renderText(0.0, 0.98, 0.02, "LS2008MP v" .. MPversion .. " as " .. MPstate .. " - running: " .. tostring(MPstarted));
	renderText(0.0, 0.96, 0.02, "IP: " .. MPip .. ":" .. MPport);
	setTextBold(false);
	
	original.drawing()
end

--MP update function
function MPkeyEvent(unicode, sym, modifier, isDown)
	
	if gameMenuSystem:isMenuActive() then
    
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
			MPstarted = not MPstarted
		end;
		
	end
	
	original.keyEvent(unicode, sym, modifier, isDown)
end

function MPClientHeartbeat()
	if not MPinitSrvCli then
		MPinitSrvCli = true
		print("LS2008MP starting client")
		MPudp:setpeername(MPip, MPport)
	end

	--MPudp:send("this is a client sending data to the server")
	data = MPudp:receive()
	if data then
		print(data)
	end
		
end

function MPServerHeartbeat()
	if not MPinitSrvCli then
		MPinitSrvCli = true
		print("LS2008MP starting client")
		MPudp:setsockname("*", MPport)
	end

	data, msg_or_ip, port_or_nil = MPudp:receivefrom()
	print(data)
	if data then
		--MPudp:sendto("this is a server sending data to the client", msg_or_ip, port_or_nil)
	end
	
end