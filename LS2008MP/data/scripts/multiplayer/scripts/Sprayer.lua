--Sprayer (original game script) MP script
--v1
--
function MPSprayerScriptUpdate()
	original.sprayerUpdate = Sprayer.update
	Sprayer.update = MPsprayerUpdate
end


function MPsprayerUpdate(self, dt)
	original.sprayerUpdate(self, dt)
	
	if self.MPinputEvent == "act" then
		self.MPinputEvent = ""
        if self.MPeventState == "true" then
       		self:setActive(true)
    	else
        	self:setActive(false)
        end
    end
	
	if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
    	for i=1, #g_currentMission.attachables do
      		if g_currentMission.attachables[i] == self then
    			MPSend("bc1;impEvent;act;"..MPplayerName..";"..i..";"..tostring(self.isActive))
			end
		end
    end
end