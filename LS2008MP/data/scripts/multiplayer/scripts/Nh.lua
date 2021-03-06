-- Nh (ModAgri v2 script) MP script
--v1
--
function MPNhScriptUpdate()
	original.NhkeyEvent = Nh.keyEvent
	original.NhUpdate = Nh.update
	Nh.keyEvent = MPNhkeyEvent
	Nh.update = MPNhUpdate
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
