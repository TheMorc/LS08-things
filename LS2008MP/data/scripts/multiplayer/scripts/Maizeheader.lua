--Maizeheader (mod script)
--author: Richard Gráčik
--v1 - 21.12.2020
--
function MPMaizeheaderScriptUpdate()
	original.MaizeheaderUpdate = Maizeheader.update
	Maizeheader.update = MPMaizeheaderUpdate
end


function MPMaizeheaderUpdate(self, dt)
	original.MaizeheaderUpdate(self, dt)
	
	if self.MPinputEvent == "1" then
		self.MPinputEvent = ""
		self.keystate_x = false;
	elseif self.MPinputEvent == "2" then
		self.MPinputEvent = ""
		if self.MPeventState == "true" then
			self.keystate_x = true;
			self.ausklapp = true;
		else
			self.keystate_x = true;
			self.ausklapp = false;
		end
	elseif self.MPinputEvent == "3" then
		self.MPinputEvent = ""
		self.keystate_g = false;
	elseif self.MPinputEvent == "4" then
		self.MPinputEvent = ""
		if self.MPeventState == "true" then
			self.keystate_g = true;
			self.turnon = true;
		else
			self.keystate_g = true;
			self.turnon = false;
		end
	end
	
	if self.isAttached then
		if not Input.isKeyPressed(Input.KEY_x) and self.keystate_x and self.turnon ~= true  then
			for i=1, #g_currentMission.cutters do
      			if g_currentMission.cutters[i] == self then
    				MPSend("bc1;impEvent;1;"..MPplayerName..";"..i)
				end
			end
		end;
		
		if Input.isKeyPressed(Input.KEY_x) and not self.keystate_x and self.turnon ~= true then
			for i=1, #g_currentMission.cutters do
      			if g_currentMission.cutters[i] == self then
    				MPSend("bc1;impEvent;2;"..MPplayerName..";"..i..";"..tostring(self.ausklapp))
				end
			end
		end; 
        
        if not Input.isKeyPressed(Input.KEY_g) and self.keystate_g and self.ausklapp ~= false then
			for i=1, #g_currentMission.cutters do
      			if g_currentMission.cutters[i] == self then
    				MPSend("bc1;impEvent;3;"..MPplayerName..";"..i)
				end
			end
		end;

      	if Input.isKeyPressed(Input.KEY_g) and not self.keystate_g and self.ausklapp ~= false then
			for i=1, #g_currentMission.cutters do
      			if g_currentMission.cutters[i] == self then
    				MPSend("bc1;impEvent;4;"..MPplayerName..";"..i..";"..tostring(self.turnon))
				end
			end
		end; 
      
        if self.ausklapp ~= false then
			for i=1, table.getn(self.rotationParts) do
				local rot = {getRotation(self.rotationParts[i].index)};
				local newRot = Utils.getMovedLimitedValues(rot, self.rotationParts[i].maxRot, self.rotationParts[i].minRot, 3, self.rotationParts[i].rotTime, dt, not self.ausklapp);
				setRotation(self.rotationParts[i].index, unpack(newRot));
			end; 
		end
		
		self.turnon = false; 	
		for i=1, table.getn(self.rotationParts) do
			local rot = {getRotation(self.rotationParts[i].index)};
			local newRot = Utils.getMovedLimitedValues(rot, self.rotationParts[i].maxRot, self.rotationParts[i].minRot, 3, self.rotationParts[i].rotTime, dt, not self.ausklapp);
			setRotation(self.rotationParts[i].index, unpack(newRot));
		end   	
	end
end