print("[LS2008MP] adding ares")
print("[LS2008MP] adding Nh")
print("[LS2008MP] adding case")
print("[LS2008MP] adding renault")
MPcustomScripts[#MPcustomScripts+1] = "ares"
MPcustomScripts[#MPcustomScripts+1] = "Nh"
MPcustomScripts[#MPcustomScripts+1] = "case"
MPcustomScripts[#MPcustomScripts+1] = "renault"
function MParesScriptUpdate()
	original.areskeyEvent = ares.keyEvent
	original.aresUpdate = ares.update
	ares.update = MParesUpdate
	ares.keyEvent = MPareskeyEvent
	scriptState = true
end
function MPNhScriptUpdate()
	original.NhkeyEvent = Nh.keyEvent
	original.NhUpdate = Nh.update
	Nh.keyEvent = MPNhkeyEvent
	Nh.update = MPNhUpdate
	scriptState = true
end
function MPcaseScriptUpdate()
	original.casekeyEvent = case.keyEvent
	original.caseUpdate = case.update
	case.keyEvent = MPcasekeyEvent
	case.update = MPcaseUpdate
	scriptState = true
end
function MPrenaultScriptUpdate()
	original.renaultkeyEvent = renault.keyEvent
	original.renaultUpdate = renault.update
	renault.update = MPrenaultUpdate
	renault.keyEvent = MPrenaultkeyEvent
	scriptState = true
end


function MParesUpdate(self, dt)
	original.aresUpdate(self, dt)
	
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
		elseif self.MPinputEvent == "bigWheels" then
			self.MPinputEvent = ""
            if self.MPeventState == "true" then
            	self.bigWheelsActive = true;
				self.twinWheelsActive = false;
    	    	self.jumWheelsActive = false;
    	    	self.smallWheelsActive = false;
            else
            	self.bigWheelsActive = false;
				self.twinWheelsActive = false;
    	    	self.jumWheelsActive = false;
    	    	self.smallWheelsActive = true;
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
		elseif self.MPinputEvent == "twinWheels" then
			self.MPinputEvent = ""
            if self.MPeventState == "true" then
        		self.twinWheelsActive = true;
				self.bigWheelsActive = false;
        		self.jumWheelsActive = false;
        		self.smallWheelsActive = false;
            else
        		self.twinWheelsActive = false;
				self.bigWheelsActive = false;
        		self.jumWheelsActive = false;
        		self.smallWheelsActive = true;
            end
		end	
				
		if self.twinWheelsActive then
			for i=1, self.numTwinWheels do
				local twinWheel = self.twinWheels[i];
				setVisibility(twinWheel, self.twinWheelsActive);
			end;
		else
			for i=1, self.numTwinWheels do
				local twinWheel = self.twinWheels[i];
				setVisibility(twinWheel, self.twinWheelsActive, false);
			end;
		end;
		
		if self.smallWheelsActive then
			for i=1, self.numSmallWheels do
				local smallWheel = self.smallWheels[i];
				setVisibility(smallWheel, self.smallWheelsActive);
			end;
		else
			for i=1, self.numSmallWheels do
				local smallWheel = self.smallWheels[i];
				setVisibility(smallWheel, self.smallWheelsActive, false);
			end;
		end;
       if not self.bigWheelsActive then
			for i=1, self.numBigWheels do
				local bigWheel = self.bigWheels[i];
				setVisibility(bigWheel, self.bigWheelsActive, false);
			end;
		else
			for i=1, self.numBigWheels do
				local bigWheel = self.bigWheels[i];
				setVisibility(bigWheel, self.bigWheelsActive);
			end;
		end;
        if not self.jumWheelsActive then
			for i=1, self.numjumWheels do
				local jumWheel = self.jumWheels[i];
				setVisibility(jumWheel, self.jumWheelsActive, false);
			end;
		else
			for i=1, self.numjumWheels do
				local jumWheel = self.jumWheels[i];
				setVisibility(jumWheel, self.jumWheelsActive);
			end;
		end;
	end
end
function MPareskeyEvent(self, unicode, sym, modifier, isDown)
	original.areskeyEvent(self, unicode, sym, modifier, isDown)
	
	if self.isEntered then
    	if isDown then
    		if sym == Input.KEY_9 then
				MPSend("bc1;vehEvent;backwindow;"..MPplayerName..";"..self.MPindex..";"..tostring(self.rotationMaxbackwindow))
			end; 

     		if sym == Input.KEY_p then 
				MPSend("bc1;vehEvent;porte;"..MPplayerName..";"..self.MPindex..";"..tostring(self.rotationMaxporte))
			end;
          
			if sym == Input.KEY_6 then
    		    MPSend("bc1;vehEvent;twinWheels;"..MPplayerName..";"..self.MPindex..";"..tostring(self.twinWheelsActive))
			end;
		
			if sym == Input.KEY_7 then
    		    MPSend("bc1;vehEvent;bigWheels;"..MPplayerName..";"..self.MPindex..";"..tostring(self.bigWheelsActive))
			end;

   			 if sym == Input.KEY_8 then
    		    MPSend("bc1;vehEvent;jumWheels;"..MPplayerName..";"..self.MPindex..";"..tostring(self.jumWheelsActive))
			end;
		end
	end
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

function MPcaseUpdate(self, dt)
	original.caseUpdate(self, dt)
	
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
		elseif self.MPinputEvent == "bigWheels" then
			self.MPinputEvent = ""
            if self.MPeventState == "true" then
            	self.bigWheelsActive = true;
				self.twinWheelsActive = false;
    	    	self.jumWheelsActive = false;
    	    	self.smallWheelsActive = false;
            else
            	self.bigWheelsActive = false;
				self.twinWheelsActive = false;
    	    	self.jumWheelsActive = false;
    	    	self.smallWheelsActive = true;
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
				
		if self.smallWheelsActive then
			for i=1, self.numSmallWheels do
				local smallWheel = self.smallWheels[i];
				setVisibility(smallWheel, self.smallWheelsActive);
			end;
		else
			for i=1, self.numSmallWheels do
				local smallWheel = self.smallWheels[i];
				setVisibility(smallWheel, self.smallWheelsActive, false);
			end;
		end;
       if not self.bigWheelsActive then
			for i=1, self.numBigWheels do
				local bigWheel = self.bigWheels[i];
				setVisibility(bigWheel, self.bigWheelsActive, false);
			end;
		else
			for i=1, self.numBigWheels do
				local bigWheel = self.bigWheels[i];
				setVisibility(bigWheel, self.bigWheelsActive);
			end;
		end;
        if not self.jumWheelsActive then
			for i=1, self.numjumWheels do
				local jumWheel = self.jumWheels[i];
				setVisibility(jumWheel, self.jumWheelsActive, false);
			end;
		else
			for i=1, self.numjumWheels do
				local jumWheel = self.jumWheels[i];
				setVisibility(jumWheel, self.jumWheelsActive);
			end;
		end;
	end
end
function MPcasekeyEvent(self, unicode, sym, modifier, isDown)
	original.casekeyEvent(self, unicode, sym, modifier, isDown)
	
	if self.isEntered then
    	if isDown then
    		if sym == Input.KEY_9 then
				MPSend("bc1;vehEvent;backwindow;"..MPplayerName..";"..self.MPindex..";"..tostring(self.rotationMaxbackwindow))
			end; 

     		if sym == Input.KEY_p then 
				MPSend("bc1;vehEvent;porte;"..MPplayerName..";"..self.MPindex..";"..tostring(self.rotationMaxporte))
			end; 

			if sym == Input.KEY_7 then
    	 		MPSend("bc1;vehEvent;bigWheels;"..MPplayerName..";"..self.MPindex..";"..tostring(self.bigWheelsActive))
			end;

   		 	if sym == Input.KEY_8 then
    	    	MPSend("bc1;vehEvent;jumWheels;"..MPplayerName..";"..self.MPindex..";"..tostring(self.jumWheelsActive))
			end
		end;
	end
end

function MPNhUpdate(self, dt)
	original.NhUpdate(self, dt)
	
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
		elseif self.MPinputEvent == "twinWheels" then
			self.MPinputEvent = ""
            if self.MPeventState == "true" then
            	self.twinWheelsActive = true;
				self.bigWheelsActive = false;
        		self.jumWheelsActive = false;
        		self.smallWheelsActive = false;
            else
            	self.twinWheelsActive = false;
				self.bigWheelsActive = false;
        		self.jumWheelsActive = false;
        		self.smallWheelsActive = true;
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

		if self.twinWheelsActive then
			for i=1, self.numTwinWheels do
				local twinWheel = self.twinWheels[i];
				setVisibility(twinWheel, self.twinWheelsActive);
			end;
		else
			for i=1, self.numTwinWheels do
				local twinWheel = self.twinWheels[i];
				setVisibility(twinWheel, self.twinWheelsActive, false);
			end;
		end;
		
		if self.smallWheelsActive then
			for i=1, self.numSmallWheels do
				local smallWheel = self.smallWheels[i];
				setVisibility(smallWheel, self.smallWheelsActive);
			end;
		else
			for i=1, self.numSmallWheels do
				local smallWheel = self.smallWheels[i];
				setVisibility(smallWheel, self.smallWheelsActive, false);
			end;
		end;
       if not self.bigWheelsActive then
			for i=1, self.numBigWheels do
				local bigWheel = self.bigWheels[i];
				setVisibility(bigWheel, self.bigWheelsActive, false);
			end;
		else
			for i=1, self.numBigWheels do
				local bigWheel = self.bigWheels[i];
				setVisibility(bigWheel, self.bigWheelsActive);
			end;
		end;
        if not self.jumWheelsActive then
			for i=1, self.numjumWheels do
				local jumWheel = self.jumWheels[i];
				setVisibility(jumWheel, self.jumWheelsActive, false);
			end;
		else
			for i=1, self.numjumWheels do
				local jumWheel = self.jumWheels[i];
				setVisibility(jumWheel, self.jumWheelsActive);
			end;
		end;
	end
end
function MPNhkeyEvent(self, unicode, sym, modifier, isDown)
	original.NhkeyEvent(self, unicode, sym, modifier, isDown)
	
	if self.isEntered then
    	if isDown then
    		if sym == Input.KEY_9 then
				MPSend("bc1;vehEvent;backwindow;"..MPplayerName..";"..self.MPindex..";"..tostring(self.rotationMaxbackwindow))
			end; 

     		if sym == Input.KEY_p then 
				MPSend("bc1;vehEvent;porte;"..MPplayerName..";"..self.MPindex..";"..tostring(self.rotationMaxporte))
			end; 

			if sym == Input.KEY_8 then
    		    MPSend("bc1;vehEvent;jumWheels;"..MPplayerName..";"..self.MPindex..";"..tostring(self.jumWheelsActive))
			end

   		 	if sym == Input.KEY_6 then
    			MPSend("bc1;vehEvent;twinWheels;"..MPplayerName..";"..self.MPindex..";"..tostring(self.twinWheelsActive))
			end;
		end
	end
end
