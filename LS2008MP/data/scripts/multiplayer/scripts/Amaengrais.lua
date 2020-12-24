--Amaengrais (ModAgri v2 script)
--author: Richard Gráčik
--v1 - 21.12.2020
--
function MPAmaengraisScriptUpdate()
	original.AmaengraisUpdate = Amaengrais.update
	Amaengrais.update = MPAmaengraisUpdate
end


function MPAmaengraisUpdate(self, dt)
	original.AmaengraisUpdate(self, dt)
	
	if self.MPinputEvent == "active" then
		self.MPinputEvent = ""
        if self.MPeventState == "true" then
       		Amaengrais:setActive(true)
    	else
        	Amaengrais:setActive(false)
        end
    end
	
	if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
    	for i=1, #g_currentMission.attachables do
      		if g_currentMission.attachables[i] == self then
    			MPSend("bc1;impEvent;active;"..MPplayerName..";"..i..";"..tostring(self.isActive))
			end
		end
    end;
end