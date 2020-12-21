--Mower (original addon game script) MP script
--v1
--
function MPMowerScriptUpdate()
	original.mowerUpdate = Mower.update
	Mower.update = MPmowerUpdate
end


function MPmowerUpdate(self, dt)
	original.mowerUpdate(self, dt)
	
	if self.MPinputEvent == "act" then
		self.MPinputEvent = ""
        if self.MPeventState == "true" then
       		self.isActive = true
    	else
        	self.isActive = false
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