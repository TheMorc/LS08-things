--ClassJaguarAP (mod script) MP script
--v1
--
function MPClassJaguarAPScriptUpdate()
	original.ClaasJaguarAPkeyEvent = ClaasJaguarAP.keyEvent
	ClaasJaguarAP.keyEvent = MPClaasJaguarAPkeyEvent --using the same keyevent update as for CombineAP2
end

function MPClaasJaguarAPkeyEvent(self, unicode, sym, modifier, isDown)
	original.ClaasJaguarAPkeyEvent(self, unicode, sym, modifier, isDown)
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