--PloughWithDrum (mod script) MP script
--v1
--
function MPPloughWithDrumScriptUpdate()
	original.PloughWithDrumUpdate = PloughWithDrum.update
	PloughWithDrum.update = MPPloughWithDrumUpdate
end

function MPPloughWithDrumUpdate(self, dt)
	original.PloughWithDrumUpdate(self, dt)
	
	if self.MPinputEvent == "rot" then
		self.MPinputEvent = ""
        if self.MPeventState == "true" then
       		self.rotationMax = true;
    	else
        	self.rotationMax = false
        end
    end
	
	if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
    	for i=1, #g_currentMission.attachables do
      		if g_currentMission.attachables[i] == self then
    			MPSend("bc1;impEvent;rot;"..MPplayerName..";"..i..";"..tostring(self.rotationMax))
			end
		end
    end
end

