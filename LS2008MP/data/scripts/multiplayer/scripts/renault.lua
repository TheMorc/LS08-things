--renault (ModAgri v2 script) MP script
--v1
--
function MPrenaultScriptUpdate()
	original.renaultkeyEvent = renault.keyEvent
	original.renaultUpdate = renault.update
	renault.update = MPrenaultUpdate
	renault.keyEvent = MPrenaultkeyEvent
end


function MPrenaultUpdate(self, dt)
	original.renaultUpdate(self,dt)
	
	if self.MPsitting then
		if self.MPinputEvent == "backwindow" then
			self.MPinputEvent = ""
            if self.MPeventState == "true" then
            	self.rotationMaxbackwindow = true;
            else
            	self.rotationMaxbackwindow = false
            end
        elseif self.MPinputEvent == "porte" then
			self.MPinputEvent = ""
            if self.MPeventState == "true" then
            	self.rotationMaxporte = true;
            else
            	self.rotationMaxporte = false
            end
		elseif self.MPinputEvent == "porte1" then
			self.MPinputEvent = ""
            if self.MPeventState == "true" then
            	self.rotationMaxporte1 = true;
            else
            	self.rotationMaxporte1 = false
            end
		elseif self.MPinputEvent == "jumWheels" then
			self.MPinputEvent = ""
            if self.MPeventState == "true" then
            	self.jumWheelsActive = true;
				self.twinWheelsActive = false;
   		    	self.bigWheelsActive = false;
    	    	self.smallWheelsActive = true;
            else
            	self.jumWheelsActive = false;
				self.twinWheelsActive = false;
   		    	self.bigWheelsActive = false;
    	    	self.smallWheelsActive = true;
            end
		end	
				
		if not self.jumWheelsActive then
			for i=1, self.numjumWheels do
				local jumWheel = self.jumWheels[i];
				setVisibility(jumWheel, self.jumWheelsActive);
			end;
		else
			for i=1, self.numjumWheels do
				local jumWheel = self.jumWheels[i];
				setVisibility(jumWheel, self.jumWheelsActive, false);
			end;
		end;
	end
end
function MPrenaultkeyEvent(self, unicode, sym, modifier, isDown)
	original.renaultkeyEvent(self, unicode, sym, modifier, isDown)
	
	if self.isEntered then
    	if isDown then
    		if sym == Input.KEY_7 then 
				MPSend("bc1;vehEvent;backwindow;"..MPplayerName..";"..self.MPindex..";"..tostring(self.rotationMaxbackwindow))
			end; 

     		if sym == Input.KEY_p then 
				MPSend("bc1;vehEvent;porte;"..MPplayerName..";"..self.MPindex..";"..tostring(self.rotationMaxporte))
			end;
		
			if sym == Input.KEY_o then 
				MPSend("bc1;vehEvent;porte1;"..MPplayerName..";"..self.MPindex..";"..tostring(self.rotationMaxporte1))
			end; 
		
   			if sym == Input.KEY_6 then
    		    MPSend("bc1;vehEvent;jumWheels;"..MPplayerName..";"..self.MPindex..";"..tostring(self.jumWheelsActive))
			end
		end;
	end
end

