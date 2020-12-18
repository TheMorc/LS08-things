print("[LS2008MP] adding Lexion400AP")

function MPLexion400APkeyEvent(self, unicode, sym, modifier, isDown)
	original.Lexion400APkeyEvent(self, unicode, sym, modifier, isDown)
	if self.attachedCutter ~= nil then
    	if self.attachedCutter.autoPilotPresent and sym == Input.KEY_p and isDown then
        	self.autoPilotEnabled = false; --LS2008MP doesn't support autopilot yet so i'm disabling it after pressing P on keyboard
            if self.attachedCutter.autoPilotAreaLeft.available then
            	self.attachedCutter.autoPilotAreaLeft.active = false;
    		end
    		if self.attachedCutter.autoPilotAreaRight.available then
           		self.attachedCutter.autoPilotAreaRight.active = false;
        	end;
			self.autoRotateBackSpeed = self.autoRotateBackSpeedBackup;
        	printChat("Autopilot is not currently supported")
        end
    end      
       
    if self.isEntered then
    	if isDown and sym == Input.KEY_o then
			for i=1, table.getn(g_currentMission.vehicles) do
        		if g_currentMission.vehicles[i] == g_currentMission.controlledVehicle then
        			MPSend("bc1;vehEvent;frontduals;"..MPplayerName..";"..i..";"..tostring(self.frontduals))
				end
			end
		end; 
	end
end
function MPLexion400APUpdate(self, dt)
	original.Lexion400APUpdate(self, dt)
	
	if self.MPsitting then
		if self.MPinputEvent == "frontduals" then
			self.MPinputEvent = ""
            if self.MPeventState == "true" then
            	self.frontduals = true
            else
            	self.frontduals = false
            end
			setVisibility(self.dual1, self.frontduals);
			setVisibility(self.dual2, self.frontduals);
			setVisibility(self.single1, not self.frontduals);
			setVisibility(self.single2, not self.frontduals);
        end
        
        for i=1,table.getn(self.rotationParts) do
            local x, y, z = getRotation(self.rotationParts[i].index);
            local rot = {x,y,z};
            local newRot = Utils.getMovedLimitedValues(rot, self.rotationParts[i].maxRot, self.rotationParts[i].minRot, 3, self.rotationParts[i].rotTime, dt, not self.GrainTankIsOpen);
            setRotation(self.rotationParts[i].index, unpack(newRot));
        end;
        
        rotate(self.cooler.node,dt*0.4,0,0);
        
        if self.attachedCutter ~= nil then
        	rotate(self.graintankauger.node,0,0,-dt*0.4);
			rotate(self.chaffspreader1.node,0,dt*0.3,0);
			rotate(self.chaffspreader2.node,0,-dt*0.3,0);
        	self.GrainTankIsOpen = true;
       	else
        	if self.grainTankFillLevel < (self.grainTankCapacity*0.25) then
				self.GrainTankIsOpen = false;
        	end;
    	end;
		
		if self.frontduals then
			self.ladderIsOpened = false;
		else
			if self.GrainTankIsOpen then
				self.ladderIsOpened = true;
			else
				self.ladderIsOpened = false
			end
		end
		
		if self.stopped then	
			self.stopped=false;
		end;
    end
end