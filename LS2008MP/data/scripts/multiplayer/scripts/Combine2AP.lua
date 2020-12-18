print("[LS2008MP] adding CombineAP2")
MPcustomScripts[#MPcustomScripts+1] = "CombineAP2"
function MPCombineAP2ScriptUpdate()
	original.CombineAP2keyEvent = CombineAP2.keyEvent
	CombineAP2.keyEvent = MPCombineAP2keyEvent
	scriptState = true
end

function MPCombineAP2keyEvent(self, unicode, sym, modifier, isDown)
	original.CombineAP2keyEvent(self, unicode, sym, modifier, isDown)
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
end
