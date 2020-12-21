--Tedder (mod script) MP script
--v1
--
function MPTedderScriptUpdate()
	original.TedderUpdate = Tedder.update
	original.TedderkeyEvent = Tedder.keyEvent
	Tedder.update = MPTedderUpdate
	Tedder.keyEvent = MPTedderkeyEvent
end


function MPTedderUpdate(self, dt)
	original.TedderUpdate(self, dt)
	
	if self.MPinputEvent == "rotation" then
		self.MPinputEvent = ""
        if self.MPeventState == "true" then
           	self.rotationMaxRight = true
			self.rotationMaxLeft  = true
        else
           	self.rotationMaxRight = false
			self.rotationMaxLeft  = false
    	end
	elseif self.MPinputEvent == "haying" then
		self.MPinputEvent = ""
        if self.MPeventState == "true" then
           	self.haying = true
        else
           	self.haying = false
    	end
	end		
	
	if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
		for i=1, #g_currentMission.attachables do
     		if g_currentMission.attachables[i] == self then
       			MPSend("bc1;impEvent;haying;"..MPplayerName..";"..i..";"..tostring(self.rotationMaxRight))
			end
		end
	end;
end
function MPTedderkeyEvent(self, unicode, sym, modifier, isDown)
	original.TedderkeyEvent(self, unicode, sym, modifier, isDown)
	
    if isDown and sym == Input.KEY_n then
		for i=1, #g_currentMission.attachables do
     			if g_currentMission.attachables[i] == self then
       			MPSend("bc1;impEvent;rotation;"..MPplayerName..";"..i..";"..tostring(self.rotationMaxRight))
			end
		end
	end
end
