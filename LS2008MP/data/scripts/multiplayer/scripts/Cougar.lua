--the first external custom script for LS2008MP ever on the world
--created on 18.12.2020, 23:37 by Morc
print("[LS2008MP] adding Cougar")
MPcustomScripts[#MPcustomScripts+1] = "Cougar"
function MPCougarScriptUpdate()
	original.CougarUpdate = Cougar.update
	original.CougarkeyEvent = Cougar.keyEvent
	Cougar.update = MPCougarUpdate
	Cougar.keyEvent = MPCougarkeyEvent
	scriptState = true
end


function MPCougarUpdate(self, dt)
	MPCougarOriginalUpdate(self, dt)
		
	if self.MPsitting then
		if self.MPinputEvent == "transport" then
			self.MPinputEvent = ""
            if self.MPeventState == "true" then
            	self.transport = true;
            else
            	self.transport = false
            end
		elseif self.MPinputEvent == "globalDown" then
			self.MPinputEvent = ""
            if self.MPeventState == "true" then
            	self.globalDown		  = true;
				self.BackMowerLeft    = true;
				self.BackMowerRight   = true;
				self.MiddleMowerLeft  = true;
				self.MiddleMowerRight = true;
				self.FrontMower		  = true;
				self.delay = 10;
            else
            	self.globalDown		  = false
				self.BackMowerLeft    = false;
				self.BackMowerRight   = false;
				self.MiddleMowerLeft  = false;
				self.MiddleMowerRight = false;
				self.FrontMower		  = false;
				self.delay = 10;
            end
		elseif self.MPinputEvent == "BackMowerRight" then
			self.MPinputEvent = ""
            if self.MPeventState == "true" then
            	self.BackMowerRight = true;
            else
            	self.BackMowerRight = false
            end
		elseif self.MPinputEvent == "BackMowerLeft" then
			self.MPinputEvent = ""
            if self.MPeventState == "true" then
            	self.BackMowerLeft = true;
            else
            	self.BackMowerLeft = false
            end
        elseif self.MPinputEvent == "MiddleMowerLeft" then
			self.MPinputEvent = ""
            if self.MPeventState == "true" then
            	self.MiddleMowerLeft = true;
            else
            	self.MiddleMowerLeft = false
            end
        elseif self.MPinputEvent == "MiddleMowerRight" then
			self.MPinputEvent = ""
            if self.MPeventState == "true" then
            	self.MiddleMowerRight = true;
            else
            	self.MiddleMowerRight = false
            end
        elseif self.MPinputEvent == "FrontMower" then
			self.MPinputEvent = ""
            if self.MPeventState == "true" then
            	self.FrontMower = true;
            else
            	self.FrontMower = false
            end
		elseif self.MPinputEvent == "activeMower" then
			self.MPinputEvent = ""
            if self.MPeventState == "true" then
            	self.activeMower = true;
            else
            	self.activeMower = false
            end
		end

		if y < 0.1 then
			self.dummyVar = true;			
		else
			self.dummyVar = false;
		end;
	
		if self.transport then
			invertAxis = 1;
		else
			invertAxis = -1;
		end;	
		
		local xtemp3, ytemp3, ztemp3 = getRotation(self.rotationPart.node);
		
		if not self.activeMower then
			self.BackMowerLeft    = false;
			self.BackMowerRight   = false;
			self.MiddleMowerLeft  = false;
			self.MiddleMowerRight = false;
			self.FrontMower		  = false;	
		end;
	
		if self.kabine ~= nil then
			local x, y, z = getRotation(self.kabine.node);
			local rot = {x,y,z};
			local newRot = Utils.getMovedLimitedValues(rot, self.kabine.maxRot, self.kabine.minRot, 3, self.kabine.rotTime, dt, self.transport);
			setRotation(self.kabine.node, unpack(newRot));
		end;
	
		if self.activeMower then
			if self.delay == 0 then
				if self.rotationPart ~= nil then
					local x, y, z = getRotation(self.rotationPart.node);
					local rot = {x,y,z};
					local newRot = Utils.getMovedLimitedValues(rot, self.rotationPart.maxRot, self.rotationPart.workingRot, 3, 2500 , dt, not self.BackMowerLeft);
					setRotation(self.rotationPart.node, unpack(newRot));
				end;
				if self.rotationPart2 ~= nil then
					local x, y, z = getRotation(self.rotationPart2.node);
					local rot = {x,y,z};
					local newRot = Utils.getMovedLimitedValues(rot, self.rotationPart2.maxRot, self.rotationPart2.workingRot, 3, 2500, dt, not self.BackMowerRight);
					setRotation(self.rotationPart2.node, unpack(newRot));
				end;
			else
				self.delay = self.delay - 1;
			end;
			if self.rotationPart7 ~= nil then
				local x, y, z = getRotation(self.rotationPart7.node);
				local rot = {x,y,z};
				local newRot = Utils.getMovedLimitedValues(rot, self.rotationPart7.maxRot, self.rotationPart7.workingRot, 3, 2500, dt, not self.MiddleMowerLeft);
				setRotation(self.rotationPart7.node, unpack(newRot));
			end;
			
			if self.rotationPart8 ~= nil then
				local x, y, z = getRotation(self.rotationPart8.node);
				local rot = {x,y,z};
				local newRot = Utils.getMovedLimitedValues(rot, self.rotationPart8.maxRot, self.rotationPart8.workingRot, 3, 2500, dt, not self.MiddleMowerRight);
				setRotation(self.rotationPart8.node, unpack(newRot));
			end;
			
			if self.rotationPart9 ~= nil then
				local x, y, z = getRotation(self.rotationPart9.node);
				local rot = {x,y,z};
				local newRot = Utils.getMovedLimitedValues(rot, self.rotationPart9.maxRot, self.rotationPart9.minRot, 3, 2500, dt, not self.FrontMower);
				setRotation(self.rotationPart9.node, unpack(newRot));
			end;		
		else			
			local xtemp2, ytemp2, ztemp2 = getRotation(self.rotationPart.node);
			if ztemp2 < -1.134464025497 and not self.transport then

				if self.rotationPart ~= nil then
					local x, y, z = getRotation(self.rotationPart.node);
					local rot = {x,y,z};
					local newRot = Utils.getMovedLimitedValues(rot, self.rotationPart.maxRot, self.rotationPart.workingRot, 3, 2500, dt, not self.BackMowerLeft);
					setRotation(self.rotationPart.node, unpack(newRot));
				end;
				if self.rotationPart2 ~= nil then
					local x, y, z = getRotation(self.rotationPart2.node);
					local rot = {x,y,z};
					local newRot = Utils.getMovedLimitedValues(rot, self.rotationPart2.maxRot, self.rotationPart2.workingRot, 3, 2500, dt, not self.BackMowerRight);
					setRotation(self.rotationPart2.node, unpack(newRot));
				end;

				if self.rotationPart7 ~= nil then
					local x, y, z = getRotation(self.rotationPart7.node);
					local rot = {x,y,z};
					local newRot = Utils.getMovedLimitedValues(rot, self.rotationPart7.maxRot, self.rotationPart7.workingRot, 3, 2500, dt, not self.MiddleMowerLeft);
					setRotation(self.rotationPart7.node, unpack(newRot));
				end;
				
				if self.rotationPart8 ~= nil then
					local x, y, z = getRotation(self.rotationPart8.node);
					local rot = {x,y,z};
					local newRot = Utils.getMovedLimitedValues(rot, self.rotationPart8.maxRot, self.rotationPart8.workingRot, 3, 2500, dt, not self.MiddleMowerRight);
					setRotation(self.rotationPart8.node, unpack(newRot));
				end;
				
				if self.rotationPart9 ~= nil then
					local x, y, z = getRotation(self.rotationPart9.node);
					local rot = {x,y,z};
					local newRot = Utils.getMovedLimitedValues(rot, self.rotationPart9.maxRot, self.rotationPart9.minRot, 3, 2500, dt, not self.FrontMower);
					setRotation(self.rotationPart9.node, unpack(newRot));
				end;
			else		
				if self.rotationPart ~= nil then
					local x, y, z = getRotation(self.rotationPart.node);
					local rot = {x,y,z};
					local newRot = Utils.getMovedLimitedValues(rot, self.rotationPart.workingRot, self.rotationPart.minRot, 3, self.rotationPart.rotTime, dt, self.transport);
					setRotation(self.rotationPart.node, unpack(newRot));
				end;

				if self.rotationPart2 ~= nil then
					local x, y, z = getRotation(self.rotationPart2.node);
					local rot = {x,y,z};
					local newRot = Utils.getMovedLimitedValues(rot, self.rotationPart2.workingRot, self.rotationPart2.minRot, 3, self.rotationPart2.rotTime, dt, self.transport);
					setRotation(self.rotationPart2.node, unpack(newRot));
				end;
				
				if self.rotationPart3 ~= nil then
					local x, y, z = getRotation(self.rotationPart3.node);
					local rot = {x,y,z};
					local newRot = Utils.getMovedLimitedValues(rot, self.rotationPart3.maxRot, self.rotationPart3.minRot, 3, self.rotationPart3.rotTime, dt, self.transport);
					setRotation(self.rotationPart3.node, unpack(newRot));
				end;
				
				if self.rotationPart4 ~= nil then
					local x, y, z = getRotation(self.rotationPart4.node);
					local rot = {x,y,z};
					local newRot = Utils.getMovedLimitedValues(rot, self.rotationPart4.maxRot, self.rotationPart4.minRot, 3, self.rotationPart4.rotTime, dt, self.transport);
					setRotation(self.rotationPart4.node, unpack(newRot));
				end;
				
				if self.rotationPart5 ~= nil then
					local x, y, z = getRotation(self.rotationPart5.node);
					local rot = {x,y,z};
					local newRot = Utils.getMovedLimitedValues(rot, self.rotationPart5.maxRot, self.rotationPart5.minRot, 3, self.rotationPart5.rotTime, dt, self.transport);
					setRotation(self.rotationPart5.node, unpack(newRot));
				end;
					
				if self.rotationPart6 ~= nil then
					local x, y, z = getRotation(self.rotationPart6.node);
					local rot = {x,y,z};
					local newRot = Utils.getMovedLimitedValues(rot, self.rotationPart6.maxRot, self.rotationPart6.minRot, 3, self.rotationPart6.rotTime, dt, self.transport);
					setRotation(self.rotationPart6.node, unpack(newRot));
				end;
				
				if self.rotationPart7 ~= nil then
					local x, y, z = getRotation(self.rotationPart7.node);
					local rot = {x,y,z};
					local newRot = Utils.getMovedLimitedValues(rot, self.rotationPart7.workingRot, self.rotationPart7.minRot, 3, self.rotationPart7.rotTime, dt, self.transport);
					setRotation(self.rotationPart7.node, unpack(newRot));
				end;
				
				if self.rotationPart8 ~= nil then
					local x, y, z = getRotation(self.rotationPart8.node);
					local rot = {x,y,z};
					local newRot = Utils.getMovedLimitedValues(rot, self.rotationPart8.workingRot, self.rotationPart8.minRot, 3, self.rotationPart8.rotTime, dt, self.transport);
					setRotation(self.rotationPart8.node, unpack(newRot));
				end;
				
				if self.Arm1 ~= nil then
					local x, y, z = getTranslation(self.Arm1.node);
					local trans = {x,y,z};
					local newTrans = Utils.getMovedLimitedValues(trans, self.Arm1.maxHeight, self.Arm1.minHeight, 3, self.Arm1.moveTime, dt, self.transport);
					setTranslation(self.Arm1.node, unpack(newTrans));
				end;
				
				if self.Arm2 ~= nil then
					local x, y, z = getTranslation(self.Arm2.node);
					local trans = {x,y,z};
					local newTrans = Utils.getMovedLimitedValues(trans, self.Arm2.maxHeight, self.Arm2.minHeight, 3, self.Arm2.moveTime, dt, self.transport);
					setTranslation(self.Arm2.node, unpack(newTrans));
				end;
			end;
		end;
		
		if self.activeMower then
			if self.drumNode1 ~= nil then
	            rotate(self.drumNode1, self.drumRotationScale * 2.2*100, 0, 0);
	        end;
			if self.drumNode2 ~= nil then
	            rotate(self.drumNode2, self.drumRotationScale * 2.2*100, 0, 0);
	        end;
			if self.drumNode3 ~= nil then
	            rotate(self.drumNode3, self.drumRotationScale * 2.2*100, 0, 0);
	        end;
			if self.drumNode4 ~= nil then
	            rotate(self.drumNode4, self.drumRotationScale * 2.2*100, 0, 0);
	        end;
			if self.drumNode5 ~= nil then
	            rotate(self.drumNode5, self.drumRotationScale * 2.2*100, 0, 0);
	        end;
			
			self.wasToFast = false;
			local toFast = self.lastSpeed*3600 > 31;
			
			local lastAreaFrontMower = 0;
			local lastAreaMiddleMowerLeft = 0;
			local lastAreaMiddleMowerRight = 0;
			local lastAreaBackMowerLeft = 0;
			local lastAreaBackMowerRight = 0;
			for i=1, table.getn(self.cuttingAreas) do
				local x,y,z = getWorldTranslation(self.cuttingAreas[i].start);
				local x1,y1,z1 = getWorldTranslation(self.cuttingAreas[i].width);
				local x2,y2,z2 = getWorldTranslation(self.cuttingAreas[i].height);				
				if i==1 then
					local xtemp,ytemp,ztemp = getRotation(self.rotationPart9.node);
					if xtemp < -0.42 and not toFast then
						Utils.updateMeadowArea(x, z, x1, z1, x2, z2);
						lastAreaFrontMower = Utils.updateCuttedMeadowArea(x, z, x1, z1, x2, z2);
					end;
				elseif i==2 then
					if lastAreaFrontMower > 0 and not toFast then
						Utils.putHayAt(x, z, x1, z1, x2, z2);
					end;
				elseif i==3 then
					local xtemp,ytemp,ztemp = getRotation(self.rotationPart8.node);
					if ztemp < -1.56 and not toFast then
						Utils.updateMeadowArea(x, z, x1, z1, x2, z2);
						lastAreaMiddleMowerLeft = Utils.updateCuttedMeadowArea(x, z, x1, z1, x2, z2);	
					end;
				elseif i==4 then
					if lastAreaMiddleMowerLeft > 0 and not toFast then
						Utils.putHayAt(x, z, x1, z1, x2, z2);
					end;
				elseif i==5 then
					local xtemp,ytemp,ztemp = getRotation(self.rotationPart7.node);
					if ztemp > 1.56 and not toFast then
						Utils.updateMeadowArea(x, z, x1, z1, x2, z2);
						lastAreaMiddleMowerRight = Utils.updateCuttedMeadowArea(x, z, x1, z1, x2, z2);
					end;
				elseif i==6 then
					if lastAreaMiddleMowerRight > 0 and not toFast then
						Utils.putHayAt(x, z, x1, z1, x2, z2);
					end;
				elseif i==7 then
					local xtemp,ytemp,ztemp = getRotation(self.rotationPart2.node);
					if ztemp > 1.49 and not toFast then
						Utils.updateMeadowArea(x, z, x1, z1, x2, z2);
						lastAreaBackMowerLeft = Utils.updateCuttedMeadowArea(x, z, x1, z1, x2, z2);						
					end;
				elseif i==8 then
					if lastAreaBackMowerLeft > 0 and not toFast then
						Utils.putHayAt(x, z, x1, z1, x2, z2);
					end;
				elseif i==9 then
					local xtemp,ytemp,ztemp = getRotation(self.rotationPart.node);
					if ztemp < -1.49 and not toFast then
						Utils.updateMeadowArea(x, z, x1, z1, x2, z2);
						lastAreaBackMowerRight = Utils.updateCuttedMeadowArea(x, z, x1, z1, x2, z2);
					end;
				elseif i==10 then
					if lastAreaBackMowerRight > 0 and not toFast then
						Utils.putHayAt(x, z, x1, z1, x2, z2);
					end;
				end;				
			end;
			self.wasToFast = toFast;
		end;
	end
	
	if self.isEntered then
		if self.dummyVar then
			if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
				for i=1, table.getn(g_currentMission.vehicles) do
        			if g_currentMission.vehicles[i] == g_currentMission.controlledVehicle then
        				MPSend("bc1;vehEvent;activeMower;"..MPplayerName..";"..i..";"..tostring(self.activeMower))
					end
				end
			end;
		end;
	end
end
function MPCougarkeyEvent(self, unicode, sym, modifier, isDown)
	original.CougarkeyEvent(self, unicode, sym, modifier, isDown)
	
	if self.isEntered then
		local xtemp3, ytemp3, ztemp3 = getRotation(self.rotationPart.node);
    	if isDown then
    		if sym == Input.KEY_x and self.lastSpeed < 0.0001 and not self.activeMower and ztemp3 > -1.1345 then
				for i=1, table.getn(g_currentMission.vehicles) do
        			if g_currentMission.vehicles[i] == g_currentMission.controlledVehicle then
        				MPSend("bc1;vehEvent;transport;"..MPplayerName..";"..i..";"..tostring(self.transport))
					end
				end
			elseif sym == Input.KEY_space and self.activeMower then
    		    for i=1, table.getn(g_currentMission.vehicles) do
        			if g_currentMission.vehicles[i] == g_currentMission.controlledVehicle then
        				MPSend("bc1;vehEvent;globalDown;"..MPplayerName..";"..i..";"..tostring(self.globalDown))
					end
				end
			elseif sym == Input.KEY_n and self.activeMower then
    		    for i=1, table.getn(g_currentMission.vehicles) do
        			if g_currentMission.vehicles[i] == g_currentMission.controlledVehicle then
        				MPSend("bc1;vehEvent;BackMowerRight;"..MPplayerName..";"..i..";"..tostring(self.BackMowerRight))
					end
				end
			elseif sym == Input.KEY_m and self.activeMower then
    		    for i=1, table.getn(g_currentMission.vehicles) do
        			if g_currentMission.vehicles[i] == g_currentMission.controlledVehicle then
        				MPSend("bc1;vehEvent;BackMowerLeft;"..MPplayerName..";"..i..";"..tostring(self.BackMowerLeft))
					end
				end
			elseif sym == Input.KEY_j and self.activeMower then
    		    for i=1, table.getn(g_currentMission.vehicles) do
        			if g_currentMission.vehicles[i] == g_currentMission.controlledVehicle then
        				MPSend("bc1;vehEvent;MiddleMowerLeft;"..MPplayerName..";"..i..";"..tostring(self.MiddleMowerLeft))
					end
				end
			elseif sym == Input.KEY_l and self.activeMower then
    	 	   for i=1, table.getn(g_currentMission.vehicles) do
        			if g_currentMission.vehicles[i] == g_currentMission.controlledVehicle then
        				MPSend("bc1;vehEvent;MiddleMowerRight;"..MPplayerName..";"..i..";"..tostring(self.MiddleMowerRight))
					end
				end
			elseif sym == Input.KEY_k and self.activeMower then
    		    for i=1, table.getn(g_currentMission.vehicles) do
        			if g_currentMission.vehicles[i] == g_currentMission.controlledVehicle then
        				MPSend("bc1;vehEvent;FrontMower;"..MPplayerName..";"..i..";"..tostring(self.FrontMower))
					end
				end
			end;
		end
	end
end
