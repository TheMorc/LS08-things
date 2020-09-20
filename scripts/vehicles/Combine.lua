Combine = {};

function Combine:new(configFile, positionX, positionY, positionZ, yRot, customMt)

    if Combine_mt == nil then
        Combine_mt = Class(Combine, Vehicle);
    end;

    local mt = customMt;
    if mt == nil then
        mt = Combine_mt;
    end;
    local instance = Combine:superClass():new(configFile, positionX, positionY, positionZ, yRot, mt);

    local xmlFile = loadXMLFile("TempConfig", configFile);

    local threshingSound = getXMLString(xmlFile, "vehicle.threshingSound#file");
    if threshingSound ~= nil and threshingSound ~= "" then
        instance.threshingSound = createSample("threshingSound");
        loadSample(instance.threshingSound, threshingSound, false);
        instance.threshingSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.threshingSound#pitchOffset"), 1);
        instance.threshingSoundPitchScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.threshingSound#pitchScale"), 0);
        instance.threshingSoundPitchMax = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.threshingSound#pitchMax"), 2.0);
    end;

    instance.attachedCutter = nil;
    --instance.cutterPos = 0;
    _=[[local cutterHolderIndex = getXMLInt(xmlFile, "vehicle.cutterHolder#index");
    if cutterHolderIndex ~= nil then
        instance.cutterHolder = getChildAt(instance.rootNode, cutterHolderIndex);
    end;]]
    local cutterJoint = {};
    cutterJoint.jointTransform = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, "vehicle.cutterAttacherJoint#index"));
    if cutterJoint.jointTransform ~= nil then

        local rotationNode = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, "vehicle.cutterAttacherJoint#rotationNode"));
        if rotationNode ~= nil then
            cutterJoint.rotationNode = rotationNode;
            local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, "vehicle.cutterAttacherJoint#maxRot"));
            cutterJoint.maxRot = {};
            cutterJoint.maxRot[1] = Utils.degToRad(Utils.getNoNil(x, 0));
            cutterJoint.maxRot[2] = Utils.degToRad(Utils.getNoNil(y, 0));
            cutterJoint.maxRot[3] = Utils.degToRad(Utils.getNoNil(z, 0));

            x, y, z = getRotation(rotationNode);
            cutterJoint.minRot = {x,y,z};
        end;
        local rotationNode2 = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, "vehicle.cutterAttacherJoint#rotationNode2"));
        if rotationNode2 ~= nil then
            cutterJoint.rotationNode2 = rotationNode2;
            local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, "vehicle.cutterAttacherJoint#maxRot2"));
            cutterJoint.maxRot2 = {};
            cutterJoint.maxRot2[1] = Utils.degToRad(Utils.getNoNil(x, 0));
            cutterJoint.maxRot2[2] = Utils.degToRad(Utils.getNoNil(y, 0));
            cutterJoint.maxRot2[3] = Utils.degToRad(Utils.getNoNil(z, 0));

            x, y, z = getRotation(rotationNode2);
            cutterJoint.minRot2 = {x,y,z};
        end;
        cutterJoint.moveTime = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.cutterAttacherJoint#moveTime"), 0.5)*1000;
        cutterJoint.jointIndex = 0;

        instance.cutterAttacherJoint = cutterJoint;
    end;

    instance.cutterAttacherJointMoveDown = false;

    local chopperBlindIndex = getXMLInt(xmlFile, "vehicle.chopperBlind#index")
    if chopperBlindIndex ~= nil then
        instance.chopperBlind = getChildAt(instance.rootNode, chopperBlindIndex);
    end;

    instance.pipeParticleSystems = {};
    local pipeIndexStr = getXMLString(xmlFile, "vehicle.pipe#index");
    if pipeIndexStr ~= nil then
        instance.pipe = Utils.indexToObject(instance.rootNode, pipeIndexStr);

        local posStr = getXMLString(xmlFile, "vehicle.pipeParticleSystem#position");
        local rotStr = getXMLString(xmlFile, "vehicle.pipeParticleSystem#rotation");
        if posStr ~= nil and rotStr ~= nil then
            local posX, posY, posZ = Utils.getVectorFromString(posStr);
            local rotX, rotY, rotZ = Utils.getVectorFromString(rotStr);
            rotX = Utils.degToRad(rotX);
            rotY = Utils.degToRad(rotY);
            rotZ = Utils.degToRad(rotZ);
            local psFile = getXMLString(xmlFile, "vehicle.pipeParticleSystem#file");
            if psFile == nil then
                psFile = "data/vehicles/particleSystems/wheatParticleSystem.i3d";
            end;
            instance.pipeParticleSystemRoot = loadI3DFile(psFile);
            link(instance.pipe, instance.pipeParticleSystemRoot);
            setTranslation(instance.pipeParticleSystemRoot, posX, posY, posZ);
            setRotation(instance.pipeParticleSystemRoot, rotX, rotY, rotZ);
            for i=0, getNumOfChildren(instance.pipeParticleSystemRoot)-1 do
                local child = getChildAt(instance.pipeParticleSystemRoot, i);
                if getClassName(child) == "Shape" then
                    local geometry = getGeometry(child);
                    if geometry ~= 0 then
                        if getClassName(geometry) == "ParticleSystem" then
                            table.insert(instance.pipeParticleSystems, geometry);
                            setEmittingState(geometry, false);
                        end;
                    end;
                end;
            end;
        end;
    end;

    instance.pipeLight = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, "vehicle.pipeLight#index"));

    instance.grainTankCapacity = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.grainTankCapacity"), 200);
    instance.grainTankUnloadingCapacity = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.grainTankUnloadingCapacity"), 10);
    --instance.grainTankFillLevel = 0.0;
    instance.grainTankCrowded = false;

    instance.grainPlane = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, "vehicle.grainPlane#index"));

    instance.grainPlaneMinY, instance.grainPlaneMaxY = Utils.getVectorFromString(getXMLString(xmlFile, "vehicle.grainPlane#minMaxY"));
    if instance.grainPlaneMinY == nil or instance.grainPlaneMaxY == nil then
        instance.grainPlaneMinY = 0;
        instance.grainPlaneMaxY = 0;
    end;

    instance.grainPlaneWindow = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, "vehicle.grainPlane#windowIndex"));

    instance.grainPlaneWindowMinY, instance.grainPlaneWindowMaxY = Utils.getVectorFromString(getXMLString(xmlFile, "vehicle.grainPlane#windowMinMaxY"));
    if instance.grainPlaneWindowMinY == nil or instance.grainPlaneWindowMaxY == nil then
        instance.grainPlaneWindowMinY = 0;
        instance.grainPlaneWindowMaxY = 0;
    end;
    instance.grainPlaneWindowStartY = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.grainPlane#windowStartY"), 0.0);

    instance.chopperParticleSystems = {};
    local posStr = getXMLString(xmlFile, "vehicle.chopperParticleSystem#position");
    local rotStr = getXMLString(xmlFile, "vehicle.chopperParticleSystem#rotation");
    if posStr ~= nil and rotStr ~= nil then
        local posX, posY, posZ = Utils.getVectorFromString(posStr);
        local rotX, rotY, rotZ = Utils.getVectorFromString(rotStr);
        rotX = Utils.degToRad(rotX);
        rotY = Utils.degToRad(rotY);
        rotZ = Utils.degToRad(rotZ);
        local psFile = getXMLString(xmlFile, "vehicle.chopperParticleSystem#file");
        if psFile == nil then
            psFile = "data/vehicles/particleSystems/threshingChopperParticleSystem.i3d";
        end;
        instance.chopperParticleSystemRoot = loadI3DFile(psFile);
        link(instance.rootNode, instance.chopperParticleSystemRoot);
        setTranslation(instance.chopperParticleSystemRoot, posX, posY, posZ);
        for i=0, getNumOfChildren(instance.chopperParticleSystemRoot)-1 do
            local child = getChildAt(instance.chopperParticleSystemRoot, i);
            if getClassName(child) == "Shape" then
                local geometry = getGeometry(child);
                if geometry ~= 0 then
                    if getClassName(geometry) == "ParticleSystem" then
                        table.insert(instance.chopperParticleSystems, geometry);
                        setEmittingState(geometry, false);
                    end;
                end;
            end;
        end;
    end;

    instance.combineSize = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.combineSize"), 1);

    delete(xmlFile);

    instance.chopperActivated = false;
    instance.pipeOpening = false;
    instance.pipeOpen = false;
    instance.pipeParticleActivated = false;

    instance.threshingScale = 1;

    instance:setGrainTankFillLevel(0.0);

    instance.drawFillLevel = true;

    return instance;
end;

function Combine:delete()

    self:detachCurrentCutter();

    if self.threshingSound ~= nil then
        delete(self.threshingSound);
    end;
    Combine:superClass().delete(self);

end;

function Combine:keyEvent(unicode, sym, modifier, isDown)
    Combine:superClass().keyEvent(self, unicode, sym, modifier, isDown);
end;

function Combine:update(dt, isActive)
    Combine:superClass().update(self, dt, isActive);

    if self.attachedCutter ~= nil then
        self.attachedCutter:update(dt);
    end;

    if self.isEntered then
        --if isDown and sym == Input.KEY_x then
        if InputBinding.hasEvent(InputBinding.ATTACH) then
            if self.attachedCutter == nil then

                local cutter = g_currentMission.cutterInMountRange;
                if cutter ~= nil then
                    self:playAttachSound();
                    self:attachCutter(cutter);
                end;
            else
                self:playAttachSound();
                self:detachCurrentCutter();
            end;
        end;

        if self.grainTankFillLevel < self.grainTankCapacity then
            if InputBinding.hasEvent(InputBinding.ACTIVATE_THRESHING) then
                if self.attachedCutter ~= nil then
                    if self.attachedCutter:isReelStarted() then
                        self:stopThreshing();
                    else
                        self:startThreshing();
                    end;
                end;
            end;
        end;

        if InputBinding.hasEvent(InputBinding.LOWER_IMPLEMENT) then
            if self.attachedCutter ~= nil then
                self.cutterAttacherJointMoveDown = not self.cutterAttacherJointMoveDown;
            end;
        end;

        --if isDown and sym == Input.KEY_3 then
        --    self.chopperActivated = not self.chopperActivated;
        --end;

        --if isDown and sym == Input.KEY_r then
        _=[[if InputBinding.hasEvent(InputBinding.OPEN_PIPE) then
            self.pipeOpening = not self.pipeOpening;
            self.pipeParticleActivated = self.pipeParticleActivated and self.pipeOpening;
        end;]]

        --if isDown and sym == Input.KEY_t then
        if InputBinding.hasEvent(InputBinding.EMPTY_GRAIN) then
            self.pipeOpening = not self.pipeOpening;
            _=[[if self.pipeOpening then
                if not self.pipeParticleActivated then
                    if self.grainTankFillLevel > 0.0 then
                        self.pipeParticleActivated = true;
                    end;
                else
                    self.pipeParticleActivated = false;
                end;
            end;]]
        end;

        if self.grainTankFillLevel == self.grainTankCapacity and self.attachedCutter ~= nil then
            self.attachedCutter:onStopReel();
        end;
    end;

    --if self.pipeParticleActivated then
    --if self.pipeOpening
    self.pipeParticleActivated = false;
    if self.pipeOpen then
        self.pipeParticleActivated = true;
        -- test if we should drain the grain tank
        self.trailerFound = 0;
        local x,y,z = getWorldTranslation(self.pipeParticleSystemRoot);
        raycastClosest(x, y, z, 0, -1, 0, "findTrailerRaycastCallback", 10, self);
        
        local trailer = g_currentMission.objectToTrailer[self.trailerFound];
        if self.trailerFound == 0 or not trailer:allowFillType(Trailer.FILLTYPE_WHEAT) then
            --self.noTrailerWarning = true;
            self.pipeParticleActivated = false;
        else
            --self.noTrailerWarning = false;

            local deltaLevel = self.grainTankUnloadingCapacity*dt/1000.0;
            deltaLevel = math.min(deltaLevel, trailer.capacity - trailer.fillLevel);

            self.grainTankFillLevel = self.grainTankFillLevel-deltaLevel;
            if self.grainTankFillLevel <= 0.0 then
                deltaLevel = deltaLevel+self.grainTankFillLevel;
                self.grainTankFillLevel = 0.0;
                self.pipeParticleActivated = false;
            end;
            if deltaLevel == 0 then
                self.pipeParticleActivated = false;
            end;
            self:setGrainTankFillLevel(self.grainTankFillLevel);
            trailer:setFillLevel(trailer.fillLevel+deltaLevel, Trailer.FILLTYPE_WHEAT);
        end;
    end;
    Utils.setEmittingState(self.pipeParticleSystems, self.pipeParticleActivated);

    _=[[for i=1, table.getn(self.pipeParticleSystems) do
        setEmittingState(self.pipeParticleSystems[i], self.pipeParticleActivated);
    end;]]

    local chopperEmitState = false;
    if self.isEntered then

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


        if self.chopperActivated and self.attachedCutter ~= nil and self.attachedCutter.reelStarted and self.attachedCutter.lastArea > 0 then
            chopperEmitState = true;

            -- 8000/1200 = 6.66 liter/meter
            -- 8000/1200 / 6 = 1.111 liter/m^2
            -- 8000/1200 / 6 / 2^2 = 0.277777 liter / density pixel (density is 4096^2, on a area of 2048m^2
            local literPerPixel = 8000/1200 / 6 / (2*2);

            literPerPixel = literPerPixel*1.5;

            self.grainTankFillLevel = self.grainTankFillLevel+self.attachedCutter.lastArea*literPerPixel*self.threshingScale;
            self:setGrainTankFillLevel(self.grainTankFillLevel);
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

        _=[[if self.pipeLight ~= nil then
            local pipeLightActive = self.lightsActive and self.pipeOpening;
            setVisibility(self.pipeLight, pipeLightActive);
        end;]]

        if self.motor.speedLevel == 1 then
            self.speedDisplayScale = 0.5;
        elseif self.motor.speedLevel == 2 then
            self.speedDisplayScale = 0.6;
        else
            self.speedDisplayScale = 1.0;
        end;
    end;
    Utils.setEmittingState(self.chopperParticleSystems, chopperEmitState)

end;

function Combine:attachCutter(cutter)
    if self.attachedCutter == nil then
        -- attach
        local jointDesc = self.cutterAttacherJoint;

        if jointDesc.rotationNode ~= nil then
            setRotation(jointDesc.rotationNode, unpack(jointDesc.maxRot));
        end;
        if jointDesc.rotationNode2 ~= nil then
            setRotation(jointDesc.rotationNode2, unpack(jointDesc.maxRot2));
        end;
        self.cutterAttacherJointMoveDown = false;

        self.attachedCutter = cutter;

        local constr = JointConstructor:new();
        constr:setActors(self.rootNode, cutter.rootNode);
        constr:setJointTransforms(jointDesc.jointTransform, cutter.attacherJoint);
        --constr:setBreakable(20, 10);

        for i=1, 3 do
            constr:setRotationLimit(i-1, 0, 0);
            constr:setTranslationLimit(i-1, true, 0, 0);
        end;

        jointDesc.jointIndex = constr:finalize();

        self.attachedCutter:onAttach(self);
    end;
end;

function Combine:detachCurrentCutter()
    self.chopperActivated = false;
    if self.attachedCutter ~= nil then
        _=[[local cx, cy, cz = localToWorld(self.cutterHolder, 0, 0, 0.4);
        setTranslation(self.attachedCutter.rootNode, cx, cy, cz);
        setRotation(self.attachedCutter.rootNode, getWorldRotation(self.attachedCutter.rootNode));
        link(getRootNode(), self.attachedCutter.rootNode);
        setRigidBodyType(self.attachedCutter.rootNode, "Dynamic");
        self.attachedCutter:onDetach();
        self.attachedCutter = nil;]]

        local jointDesc = self.cutterAttacherJoint;
        removeJoint(jointDesc.jointIndex);
        jointDesc.jointIndex = 0;

        self.attachedCutter:onDetach();
        self.attachedCutter = nil;

        if self.threshingSound ~= nil then
            stopSample(self.threshingSound);
        end;
    end;
end;

function Combine:setGrainTankFillLevel(fillLevel)
    self.grainTankFillLevel = fillLevel;
    if self.grainTankFillLevel > self.grainTankCapacity then
        self.grainTankFillLevel = self.grainTankCapacity;
    end;
    if self.grainTankFillLevel < 0 then
        self.grainTankFillLevel = 0;
    end;
    if self.grainPlane ~= nil then
        local m = (self.grainPlaneMaxY - self.grainPlaneMinY) / self.grainTankCapacity;
        local xPos, yPos, zPos = getTranslation(self.grainPlane);
        setTranslation(self.grainPlane, xPos, m*self.grainTankFillLevel + self.grainPlaneMinY, zPos);
        setVisibility(self.grainPlane, self.grainTankFillLevel ~= 0);
        if self.grainPlaneWindow ~= nil then
            local startFillLevel = (self.grainPlaneWindowStartY-self.grainPlaneMinY)/m;
            local windowXPos, windowYPos, windowZPos = getTranslation(self.grainPlaneWindow);
            local yTranslation = math.min(m*(self.grainTankFillLevel-startFillLevel)+self.grainPlaneWindowMinY, self.grainPlaneWindowMaxY);
            setTranslation(self.grainPlaneWindow, windowXPos, yTranslation, windowZPos);
            setVisibility(self.grainPlaneWindow, self.grainTankFillLevel >= startFillLevel);
        end;
    end;
end;

function Combine:findTrailerRaycastCallback(transformId, x, y, z, distance)

    self.trailerFound = 0;
    if getUserAttribute(transformId, "vehicleType") == 2 then
        self.trailerFound = transformId;
    end;

    return false;

end;

function Combine:onLeave()
    Combine:superClass().onLeave(self);
    _=[[if self.pipeLight ~= nil then
        setVisibility(self.pipeLight, false);
    end;]]
    if self.threshingSound ~= nil then
        stopSample(self.threshingSound);
    end;
end;

function Combine:draw()
    Combine:superClass().draw(self);
    local percent = self.grainTankFillLevel/self.grainTankCapacity*100;
    if self.drawFillLevel then
        --if percent > 95 then
        --    setTextColor(1.0, 0.0, 0.0, 1.0);
        --else
        --    setTextColor(1.0, 1.0, 1.0, 1.0);
        --end;
        --renderText(0.015, 0.95, 0.03, string.format("Füllstand: %.0f (%d%%)", self.grainTankFillLevel, percent));
        Combine:superClass().drawGrainLevel(self, self.grainTankFillLevel, self.grainTankCapacity, 95);
    end;
    if self.pipeOpen and not self.pipeParticleActivated and self.grainTankFillLevel > 0 then
        g_currentMission:addExtraPrintText(g_i18n:getText("Move_the_pipe_over_a_trailer"));
    elseif self.grainTankFillLevel == self.grainTankCapacity then
        g_currentMission:addExtraPrintText(g_i18n:getText("Dump_corn_to_continue_threshing"));
    end;
    if self.attachedCutter ~= nil then
        if self.attachedCutter:isReelStarted() then
            g_currentMission:addHelpButtonText(g_i18n:getText("Turn_off_cutter"), InputBinding.ACTIVATE_THRESHING);
        else
            g_currentMission:addHelpButtonText(g_i18n:getText("Turn_on_cutter"), InputBinding.ACTIVATE_THRESHING);
        end;
    end;
    if self.pipeOpening then
        g_currentMission:addHelpButtonText(g_i18n:getText("Pipe_in"), InputBinding.EMPTY_GRAIN);
    else
        if percent > 80 then
            g_currentMission:addHelpButtonText(g_i18n:getText("Dump_corn"), InputBinding.EMPTY_GRAIN);
        end;
    end;

    if self.attachedCutter ~= nil then
        self.attachedCutter:draw();
    end;
end;

function Combine:startThreshing()
    if self.attachedCutter ~= nil then
        self.attachedCutter:setReelSpeed(0.003);
        self.attachedCutter:onStartReel();
        self.chopperActivated = true;
        self.cutterAttacherJointMoveDown = true;
        if self.threshingSound ~= nil then
            setSamplePitch(self.threshingSound, math.min(self.threshingSoundPitchOffset + self.threshingSoundPitchScale*math.abs(self.lastSoundSpeed), self.threshingSoundPitchMax));
            playSample(self.threshingSound, 0, 1, 0);
        end;
    end;
end;

function Combine:stopThreshing()
    if self.attachedCutter ~= nil then
        self.attachedCutter:onStopReel();
        self.chopperActivated = false;
        self.cutterAttacherJointMoveDown = false;
        if self.threshingSound ~= nil then
            stopSample(self.threshingSound);
        end;
    end;
end;