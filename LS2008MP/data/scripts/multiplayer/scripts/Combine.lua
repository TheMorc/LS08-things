--Combine (original game script) MP script
--
function MPCombineScriptUpdate()
	original.attachCutter = Combine.attachCutter
	original.detachCurrentCutter = Combine.detachCurrentCutter
	original.combineUpdate = Combine.update
	Combine.attachCutter = MPsyncAttachCutter
	Combine.detachCurrentCutter = MPsyncDetachCurrentCutter
	Combine.update = MPcombineUpdate
end

function MPsyncAttachCutter(self, cutter)
	original.attachCutter(self, cutter)
	for i=1, #g_currentMission.cutters do
      	if g_currentMission.cutters[i] == cutter then
    		MPSend("bc1;attachCutter;"..MPplayerName..";"..i)
        end 	
    end
end
function MPsyncDetachCurrentCutter(self)
	MPSend("bc1;detachCurrentCutter;"..MPplayerName)	
	
	original.detachCurrentCutter(self)
end
function MPcombineUpdate(self, dt, isActive)
	original.combineUpdate(self, dt, isActive)
	
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
		end
		
		--isEntered part of the combine code that needed to be stolen otherwise it wouldn't update just like the bit of code above
		if self.attachedCutter ~= nil then
		
			--stop on full
			if self.grainTankFillLevel == self.grainTankCapacity then
        	    self.attachedCutter:onStopReel();
        	end
		
			--lowering
			jointDesc = self.cutterAttacherJoint;
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

			--calculate add to tank
        	if self.chopperActivated and self.attachedCutter.reelStarted and self.attachedCutter.lastArea > 0 then
            chopperEmitState = true;

            local literPerPixel = 8000/1200 / 6 / (2*2);

            literPerPixel = literPerPixel*1.5;

            self.grainTankFillLevel = self.grainTankFillLevel+self.attachedCutter.lastArea*literPerPixel*self.threshingScale;
            self:setGrainTankFillLevel(self.grainTankFillLevel);
        	end;
			
			--rotate chopper
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

			--open close pipe
        	local pipeRotationSpeed = 0.0006;
        	local pipeMinRotY = -105*3.1415/180.0;
        	local pipeMaxRotX = 10*3.1415/180.0;
        	local pipeXRotationSpeed = 0.00006;
        	if self.pipe ~= nil then
            local x,y,z = getRotation(self.pipe);
            if self.pipeOpening then
                y = y-dt*pipeRotationSpeed;
                if y < pipeMinRotY then
                    y = pipeMinRotY;
                end;
                x = x+dt*pipeXRotationSpeed;
                if x > pipeMaxRotX then
                    x = pipeMaxRotX;
                end;
            else
                y = y+dt*pipeRotationSpeed;
                if y > 0.0 then
                    y = 0.0;
                end;
                x = x-dt*pipeXRotationSpeed;
                if x < 0.0 then
                    x = 0.0;
                end;
            end;
            setRotation(self.pipe, x, y, z);
            self.pipeOpen = (math.abs(pipeMinRotY-y) < 0.01);
        end;
		end
	end
	
	if self.isEntered then
		if InputBinding.hasEvent(InputBinding.LOWER_IMPLEMENT) then
           	if self.attachedCutter ~= nil then
       			MPSend("bc1;vehEvent;lowerCutter;"..MPplayerName..";"..self.MPindex..";"..tostring(self.cutterAttacherJointMoveDown))
			end
		elseif InputBinding.hasEvent(InputBinding.ACTIVATE_THRESHING) then
          	if self.attachedCutter ~= nil then
        		MPSend("bc1;vehEvent;threshing;"..MPplayerName..";"..self.MPindex..";"..tostring(self.attachedCutter:isReelStarted()))
			end
        elseif InputBinding.hasEvent(InputBinding.EMPTY_GRAIN) then
        	MPSend("bc1;vehEvent;pipe;"..MPplayerName..";"..self.MPindex..";"..tostring(self.pipeOpening))
		end
	end
	
end