--Sowing_maize (mod script)
--author: Richard Gráčik
--v1 - 21.12.2020
--
function MPSowing_maizeScriptUpdate()
	original.Sowing_maizeUpdate = Sowing_maize.update
	original.Sowing_maizekeyEvent = Sowing_maize.keyEvent
	Sowing_maize.keyEvent = MPSowing_maizekeyEvent
	Sowing_maize.update = MPSowing_maizeUpdate
end


function MPSowing_maizekeyEvent(self, unicode, sym, modifier, isDown)
	original.Sowing_maizekeyEvent(self, unicode, sym, modifier, isDown)
	
	if sym == Input.KEY_KP_2 or sym == Input.KEY_k then
		for i=1, #g_currentMission.attachables do
      		if g_currentMission.attachables[i] == self then
    			MPSend("bc1;impEvent;left;"..MPplayerName..";"..i)
    		end
    	end
	elseif sym == Input.KEY_KP_3 or sym == Input.KEY_l then
		for i=1, #g_currentMission.attachables do
      		if g_currentMission.attachables[i] == self then
    			MPSend("bc1;impEvent;right;"..MPplayerName..";"..i)
    		end
    	end
	elseif sym == Input.KEY_KP_1 or sym == Input.KEY_j then
		for i=1, #g_currentMission.attachables do
      		if g_currentMission.attachables[i] == self then
    			MPSend("bc1;impEvent;nomark;"..MPplayerName..";"..i)
    		end
    	end
	elseif isDown and sym == Input.KEY_KP_0 then
		for i=1, #g_currentMission.attachables do
      		if g_currentMission.attachables[i] == self then
    			MPSend("bc1;impEvent;tramline;"..MPplayerName..";"..i..";"..tostring(self.tramline))
    		end
    	end
	elseif isDown and sym == Input.KEY_KP_4 then
		for i=1, #g_currentMission.attachables do
      		if g_currentMission.attachables[i] == self then
    			MPSend("bc1;impEvent;maize;"..MPplayerName..";"..i..";"..tostring(self.maize))
    		end
    	end
	elseif isDown and sym == Input.KEY_n then
		for i=1, #g_currentMission.attachables do
      		if g_currentMission.attachables[i] == self then
    			MPSend("bc1;impEvent;maize;"..MPplayerName..";"..i..";"..tostring(self.maize))
    		end
    	end
	end;
end

function MPSowing_maizeUpdate(self, dt)
	original.Sowing_maizeUpdate(self, dt)
	
	if self.MPinputEvent == "maize" then
		self.MPinputEvent = ""
        if self.MPeventState == "true" then
       		self.maize = true;
    	else
        	self.maize = false
        end
	elseif self.MPinputEvent == "tramline" then
		self.MPinputEvent = ""
        if self.MPeventState == "true" then
       		self.tramline = true;
    	else
        	self.tramline = false
        end
    elseif self.MPinputEvent == "right" then
		self.MPinputEvent = ""
        self.leftmarker = false;
		self.rightmarker = true;
		self.rotationMax = true;
		self.rotationMax2 = false;
    elseif self.MPinputEvent == "left" then
		self.MPinputEvent = ""
        
        self.leftmarker = true;
		self.rightmarker = false;		
		self.rotationMax = false;
		self.rotationMax2 = true;
    elseif self.MPinputEvent == "nomark" then
		self.MPinputEvent = ""
        self.leftmarker = false;
		self.rightmarker = false;
		self.rotationMax = false;
		self.rotationMax2 = false;
    end
end