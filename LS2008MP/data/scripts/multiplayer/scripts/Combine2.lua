print("[LS2008MP] adding Combine2")

function MPCombine2keyEvent(self, unicode, sym, modifier, isDown)
	original.Combine2keyEvent(self, unicode, sym, modifier, isDown)
	if self.isEntered then
		if isDown then
			if sym==self.keys.stroh then
				for i=1, table.getn(g_currentMission.vehicles) do
        			if g_currentMission.vehicles[i] == g_currentMission.controlledVehicle then
        				MPSend("bc1;vehEvent;hayOn;"..MPplayerName..";"..i..";"..tostring(self.hayOn))
					end
				end
			elseif sym==self.keys.pipe then
				for i=1, table.getn(g_currentMission.vehicles) do
        			if g_currentMission.vehicles[i] == g_currentMission.controlledVehicle then
        				MPSend("bc1;vehEvent;fPipeOpen;"..MPplayerName..";"..i..";"..tostring(self.fPipeOpen))
					end
				end
			end;
		end
    end          
end
function MPCombine2attachCutter(self, cutter)
	original.Combine2attachCutter(self, cutter)
	for i=1, #g_currentMission.cutters do
      	if g_currentMission.cutters[i] == cutter then
    		MPSend("bc1;attachCutter;"..MPplayerName..";"..i)
        end 	
    end
end
function MPCombine2detachCurrentCutter(self)
	MPSend("bc1;detachCurrentCutter;"..MPplayerName)	
	
	original.Combine2detachCurrentCutter(self)
end
function MPCombine2Update(self, dt, isActive)
	original.Combine2Update(self, dt, isActive)
	
	if self.MPsitting then
		
		if self.MPinputEvent == "threshing" then --used on combines
			self.MPinputEvent = ""
			if self.grainTankFillLevel < self.grainTankCapacity then
                if self.attachedCutter ~= nil then
                    if self.MPeventState == "true" then
                        self:startThreshing();
                    else
                        self:stopThreshing();
                    end;
                end;
            end;
        elseif self.MPinputEvent == "lowerCutter" then
			self.MPinputEvent = ""
            if self.attachedCutter ~= nil then
            	if self.MPeventState == "true" then
                	self.cutterAttacherJointMoveDown = true;
                else
                	self.cutterAttacherJointMoveDown = false
                end
            end;
		elseif self.MPinputEvent == "pipe" then
			self.MPinputEvent = ""
			if self.MPeventState == "true" then
				self.pipeOpening = true;
			else
				self.pipeOpening = false
			end
		elseif self.MPinputEvent == "fPipeOpen" then
			self.MPinputEvent = ""
			if self.MPeventState == "true" then
				self.fPipeOpen = true;
			else
				self.fPipeOpen = false
			end
		elseif self.MPinputEvent == "hayOn" then
			self.MPinputEvent = ""
			if self.MPeventState == "true" then
				self.hayOn = true;
			else
				self.hayOn = false
			end
		end
		
		--isEntered part of the combine code that needed to be stolen otherwise it wouldn't update just like the bit of code above
		if self.attachedCutter ~= nil then
		
			local jointDesc = self.cutterAttacherJoint;
        	if jointDesc.jointIndex ~= 0 then
            if jointDesc.rotationNode ~= nil then
                local x, y, z = getRotation(jointDesc.rotationNode);
                local rot = {x,y,z};
                local newRot = Utils.getMovedLimitedValues(rot, jointDesc.maxRot, jointDesc.minRot, 3, jointDesc.moveTime, dt, not self.cutterAttacherJointMoveDown);
                setRotation(jointDesc.rotationNode, unpack(newRot));
                for i=1, 3 do
                    if math.abs(newRot[i] - rot[i]) > 0.001 then
                        jointFrameInvalid = true;
                    end;
                end;
            end;
            if jointDesc.rotationNode2 ~= nil then
                local x, y, z = getRotation(jointDesc.rotationNode2);
                local rot = {x,y,z};
                local newRot = Utils.getMovedLimitedValues(rot, jointDesc.maxRot2, jointDesc.minRot2, 3, jointDesc.moveTime, dt, not self.cutterAttacherJointMoveDown);
                setRotation(jointDesc.rotationNode2, unpack(newRot));
                for i=1, 3 do
                    if math.abs(newRot[i] - rot[i]) > 0.001 then
                        jointFrameInvalid = true;
                    end;
                end;
            end;
            if jointFrameInvalid then
                setJointFrame(jointDesc.jointIndex, 0, jointDesc.jointTransform);
            end;
        	end;
		
        	local chopperBlindRotationSpeed = 0.001;
        	local minRotX = -83*3.1415/180.0;
        	if self.chopperBlind ~= nil then
            local x,y,z = getRotation(self.chopperBlind);
            if self.chopperActivated then
                x = x-dt*chopperBlindRotationSpeed;
                if x < minRotX then
                    x = minRotX;
                end;
            else
                x = x+dt*chopperBlindRotationSpeed;
                if x > 0.0 then
                    x = 0.0;
                end;
            end;
            setRotation(self.chopperBlind, x, y, z);
        	end;

		end
	end
	
	if self.isEntered then
		if InputBinding.hasEvent(InputBinding.LOWER_IMPLEMENT) then
           	for i=1, table.getn(g_currentMission.vehicles) do
       			if g_currentMission.vehicles[i] == g_currentMission.controlledVehicle then
       				if self.attachedCutter ~= nil then
       					MPSend("bc1;vehEvent;lowerCutter;"..MPplayerName..";"..i..";"..tostring(self.cutterAttacherJointMoveDown))
					end
				end
			end
		elseif InputBinding.hasEvent(InputBinding.ACTIVATE_THRESHING) then
          	for i=1, table.getn(g_currentMission.vehicles) do
        		if g_currentMission.vehicles[i] == g_currentMission.controlledVehicle then
        			if self.attachedCutter ~= nil then
						MPSend("bc1;vehEvent;threshing;"..MPplayerName..";"..i..";"..tostring(self.attachedCutter:isReelStarted()))
					end
				end
			end
        elseif InputBinding.hasEvent(InputBinding.EMPTY_GRAIN) then
        	for i=1, table.getn(g_currentMission.vehicles) do
        		if g_currentMission.vehicles[i] == g_currentMission.controlledVehicle then
        			MPSend("bc1;vehEvent;pipe;"..MPplayerName..";"..i..";"..tostring(self.pipeOpening))
				end
			end
		end
	end
end
