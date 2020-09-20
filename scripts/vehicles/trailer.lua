--
-- Trailer
-- Base class for all trailers
--
-- @author  Stefan Geiger (mailto:sgeiger@giants.ch)
-- @date  04/11/07

Trailer = {};

Trailer.TIPSTATE_CLOSED = 0;
Trailer.TIPSTATE_OPENING = 1;
Trailer.TIPSTATE_OPEN = 2;
Trailer.TIPSTATE_CLOSING = 3;

Trailer.FILLTYPE_UNKNOWN = 0;
Trailer.FILLTYPE_WHEAT = 1;
Trailer.FILLTYPE_GRASS = 2;

function Trailer:new(configFile, positionX, offsetY, positionZ, rotationY, customMt)

    if Trailer_mt == nil then
        Trailer_mt = Class(Trailer);
    end;

    local instance = {};
    if customMt ~= nil then
        setmetatable(instance, customMt);
    else
        setmetatable(instance, Trailer_mt);
    end;

    instance.configFileName = configFile;

    local xmlFile = loadXMLFile("TempConfig", configFile);

    local rootNode = loadI3DFile(getXMLString(xmlFile, "vehicle.filename"));
    instance.rootNode = getChildAt(rootNode, 0);
    link(getRootNode(), instance.rootNode);
    delete(rootNode);

    local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, positionX, 300, positionZ);

    setTranslation(instance.rootNode, positionX, terrainHeight+offsetY, positionZ);
    rotate(instance.rootNode, 0, rotationY, 0);

    instance.maxRotTime = 0;
    instance.minRotTime = 0;
    instance.autoRotateBackSpeed = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.wheels#autoRotateBackSpeed"), 1.0);
    local numWheels = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.wheels#count"), 0);
    instance.wheels = {};
    for i=1, numWheels do
        local wheelnamei = string.format("vehicle.wheels.wheel" .. "%d", i);
        instance.wheels[i] = {};
        instance.wheels[i].rotSpeed = Utils.degToRad(getXMLFloat(xmlFile, wheelnamei .. "#rotSpeed"));
        instance.wheels[i].rotMax = Utils.degToRad(getXMLFloat(xmlFile, wheelnamei .. "#rotMax"));
        instance.wheels[i].rotMin = Utils.degToRad(getXMLFloat(xmlFile, wheelnamei .. "#rotMin"));
        instance.wheels[i].driveMode = Utils.getNoNil(getXMLInt(xmlFile, wheelnamei .. "#driveMode"), 0);
        instance.wheels[i].repr = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, wheelnamei .. "#repr"));
        if instance.wheels[i].repr ~= nil and instance.wheels[i].repr ~= 0 then
            local radius = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#radius"), 1.0);
            local positionX, positionY, positionZ = getTranslation(instance.wheels[i].repr);
            instance.wheels[i].deltaY = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#deltaY"), 0.0);
            positionY = positionY+instance.wheels[i].deltaY;
            local suspTravel = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#suspTravel"), 0.0);
            local spring = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#spring"), 0.0);
            local damper = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#damper"), 0.0);
            local mass = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#mass"), 0.01);
            instance.wheels[i].node = getParent(instance.wheels[i].repr);
            instance.wheels[i].wheelShape = createWheelShape(instance.wheels[i].node, positionX, positionY, positionZ, radius, suspTravel, spring, damper, mass);

            if instance.wheels[i].rotSpeed ~= 0 then
                local maxRotTime = instance.wheels[i].rotMax/instance.wheels[i].rotSpeed;
                local minRotTime = instance.wheels[i].rotMin/instance.wheels[i].rotSpeed;
                if minRotTime > maxRotTime then
                    local temp = minRotTime;
                    minRotTime = maxRotTime;
                    maxRotTime = temp;
                end;
                if maxRotTime > instance.maxRotTime then
                    instance.maxRotTime = maxRotTime;
                end;
                if minRotTime < instance.minRotTime then
                    instance.minRotTime = minRotTime;
                end;
            end;
        else
            print("Error: invalid wheel representation");
        end;
    end;
    instance.brakeForce = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.brakeForce"), 5);

    local numCuttingAreas = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.cuttingAreas#count"), 0);
    instance.cuttingAreas = {}
    for i=1, numCuttingAreas do
        instance.cuttingAreas[i] = {};
        local areanamei = string.format("vehicle.cuttingAreas.cuttingArea" .. "%d", i);
        local x,y,z = getTranslation(Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, areanamei .. "#startIndex")));
        local widthX, widthY, widthZ = getTranslation(Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, areanamei .. "#widthIndex")));
        local heightX, heightY, heightZ = getTranslation(Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, areanamei .. "#heightIndex")));
        --instance.cuttingAreas[i].startX = x;
        --instance.cuttingAreas[i].startZ = z;
        --instance.cuttingAreas[i].width = widthX-x;
        --instance.cuttingAreas[i].height = heightZ-z;
        instance.cuttingAreas[i].start = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, areanamei .. "#startIndex"));
        instance.cuttingAreas[i].width = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, areanamei .. "#widthIndex"));
        instance.cuttingAreas[i].height = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, areanamei .. "#heightIndex"));
    end;
    instance.lastFillDelta = 0;
    instance.fillLevel = 0;
    instance.capacity = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.capacity"), 0.0);

    instance.fillRootNode = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, "vehicle.fillRootNode#index"));
    if instance.fillRootNode == nil then
        instance.fillRootNode = instance.rootNode;
    end;

    instance.attachRootNode = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, "vehicle.attachRootNode#index"));
    if instance.attachRootNode == nil then
        instance.attachRootNode = instance.rootNode;
    end;

    instance.grainPlane = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, "vehicle.grainPlane#index"));

    instance.grainPlaneMinY, instance.grainPlaneMaxY = Utils.getVectorFromString(getXMLString(xmlFile, "vehicle.grainPlane#minMaxY"));
    if instance.grainPlaneMinY == nil or instance.grainPlaneMaxY == nil then
        local grainAnimCurve = AnimCurve:new(linearInterpolator4);
        local keyI = 0;
        while true do
            local key = string.format("vehicle.grainPlane.key(%d)", keyI);
            local t = getXMLFloat(xmlFile, key.."#time");
            local yValue = getXMLFloat(xmlFile, key.."#y");
            local scaleX,scaleY,scaleZ = Utils.getVectorFromString(getXMLString(xmlFile, key.."#scale"));
            if y == nil or scaleX == nil or scaleY == nil or scaleZ == nil then
                break;
            end;
            grainAnimCurve:addKeyframe({x=scaleX, y=scaleY, z=scaleZ, w=yValue, time = t});
            keyI = keyI +1;
        end;
        if keyI > 0 then
            instance.grainAnimCurve = grainAnimCurve;
        end;
        instance.grainPlaneMinY = 0;
        instance.grainPlaneMaxY = 0;
    end;

    instance.attacherJoint = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, "vehicle.attacherJoint#index"));

    local centerOfMassX = getXMLFloat(xmlFile, "vehicle.centerOfMass#x");
    local centerOfMassY = getXMLFloat(xmlFile, "vehicle.centerOfMass#y");
    local centerOfMassZ = getXMLFloat(xmlFile, "vehicle.centerOfMass#z");
    if centerOfMassX ~= nil and centerOfMassY ~= nil and centerOfMassZ ~= nil then
        setCenterOfMass(instance.fillRootNode, centerOfMassX, centerOfMassY, centerOfMassZ);
        instance.centerOfMass = { centerOfMassX, centerOfMassY, centerOfMassZ };
    end;

    instance.tipDischargeEndTime = getXMLFloat(xmlFile, "vehicle.tipDischargeEndTime#value");

    local tipAnimRootNode = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, "vehicle.tipAnimation#rootNode"));
    instance.tipAnimCharSet = 0;
    if tipAnimRootNode ~= nil and tipAnimRootNode ~= 0 then
        instance.tipAnimCharSet = getAnimCharacterSet(tipAnimRootNode);
        if instance.tipAnimCharSet ~= 0 then
            local clip = getAnimClipIndex(instance.tipAnimCharSet, getXMLString(xmlFile, "vehicle.tipAnimation#clip"));
            assignAnimTrackClip(instance.tipAnimCharSet, 0, clip);
            setAnimTrackLoopState(instance.tipAnimCharSet, 0, false);
            instance.tipAnimSpeedScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.tipAnimation#speedScale"), 1);
            instance.tipAnimDuration = getAnimClipDuration(instance.tipAnimCharSet, clip);
            if instance.tipDischargeEndTime == nil then
                instance.tipDischargeEndTime = instance.tipAnimDuration*2.0;
            end;
        end;
    end;
    instance.tipState = Trailer.TIPSTATE_CLOSED;

    instance.tipReferencePoint = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, "vehicle.tipReferencePoint#index"));
    if instance.tipReferencePoint == nil then
        instance.tipReferencePoint = instance.rootNode;
    end;

    instance.dischargeParticleSystems = {};
    local posStr = getXMLString(xmlFile, "vehicle.dischargeParticleSystem#position");
    local rotStr = getXMLString(xmlFile, "vehicle.dischargeParticleSystem#rotation");
    if posStr ~= nil and rotStr ~= nil then
        local posX, posY, posZ = Utils.getVectorFromString(posStr);
        local rotX, rotY, rotZ = Utils.getVectorFromString(rotStr);
        rotX = Utils.degToRad(rotX);
        rotY = Utils.degToRad(rotY);
        rotZ = Utils.degToRad(rotZ);
        local psFile = getXMLString(xmlFile, "vehicle.dischargeParticleSystem#file");
        local dischargeParticleSystemRoot = loadI3DFile(psFile);
        local psNode = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, "vehicle.dischargeParticleSystem#node"));
        if psNode == nil then
            psNode = instance.rootNode;
        end;
        link(psNode, dischargeParticleSystemRoot);
        setTranslation(dischargeParticleSystemRoot, posX, posY, posZ);
        for i=0, getNumOfChildren(dischargeParticleSystemRoot)-1 do
            local child = getChildAt(dischargeParticleSystemRoot, i);
            if getClassName(child) == "Shape" then
                local geometry = getGeometry(child);
                if geometry ~= 0 then
                    if getClassName(geometry) == "ParticleSystem" then
                        table.insert(instance.dischargeParticleSystems, geometry);
                        setEmittingState(geometry, false);
                    end;
                end;
            end;
        end;
    end;

    _=[[instance.supportWheel = {}
    instance.supportWheel.node = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, "vehicle.supportWheel#index"));
    local supportWheelPos1 = getXMLString(xmlFile, "vehicle.supportWheel#positionEnabled");
    if supportWheelPos1 ~= nil then
        instance.supportWheel.x1, instance.supportWheel.y1, instance.supportWheel.z1 = Utils.getVectorFromString(supportWheelPos1);
    else
        instance.supportWheel.x1, instance.supportWheel.y1, instance.supportWheel.z1 = 0,0,0;
    end;
    local supportWheelPos2 = getXMLString(xmlFile, "vehicle.supportWheel#positionDisabled");
    if supportWheelPos2 ~= nil then
        instance.supportWheel.x2, instance.supportWheel.y2, instance.supportWheel.z2 = Utils.getVectorFromString(supportWheelPos2);
    else
        instance.supportWheel.x2, instance.supportWheel.y2, instance.supportWheel.z2 = 0,0,0;
    end;
    if instance.supportWheel.node ~= nil then
        setTranslation(instance.supportWheel.node, instance.supportWheel.x1, instance.supportWheel.y1, instance.supportWheel.z1);
    end;]]

    instance.trailerAttacherJoint = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, "vehicle.trailerAttacherJoint#index"));
    instance.trailerAttacherJointIndex = 0;
    instance.attachedTrailer = nil;

    instance.fillTypes = {};
    instance.fillTypes[Trailer.FILLTYPE_UNKNOWN] = true;
    instance.fillTypes[Trailer.FILLTYPE_WHEAT] = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.fillTypes#wheat"), true);
    instance.fillTypes[Trailer.FILLTYPE_GRASS] = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.fillTypes#grass"), false);

    instance.currentFillType = Trailer.FILLTYPE_UNKNOWN;

    instance.massScale = 1.3*0.0001*0.0001*0.7 *Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.massScale#value"), 1);

    delete(xmlFile);

    setUserAttribute(instance.fillRootNode, "vehicleType", "Integer", 2);
    instance:setFillLevel(0, Trailer.FILLTYPE_UNKNOWN);

    instance.firstTimeRun = false;

    return instance;
end;

function Trailer:delete()
    delete(self.rootNode);
end;

function Trailer:setWorldPosition(x,y,z, xRot,yRot,zRot)
    setTranslation(self.rootNode, x,y,z);
    setRotation(self.rootNode, xRot,yRot,zRot);
end;

function Trailer:mouseEvent(posX, posY, isDown, isUp, button)
    if self.attachedTrailer ~= nil then
        self.attachedTrailer:mouseEvent(posX, posY, isDown, isUp, button)
    end;
end;

function Trailer:keyEvent(unicode, sym, modifier, isDown)
    if self.attachedTrailer ~= nil then
        self.attachedTrailer:keyEvent(unicode, sym, modifier, isDown)
    end;
end;

function Trailer:update(dt)

    _=[[for i=1, table.getn(self.cuttingAreas) do
        local worldX, worldY, worldZ = localToWorld(self.rootNode, self.cuttingAreas[i].startX, 0, self.cuttingAreas[i].startZ);
        local worldX2, worldY2, worldZ2 = localToWorld(self.rootNode, self.cuttingAreas[i].startX+self.cuttingAreas[i].width, 0, self.cuttingAreas[i].startZ);
        local worldX3, worldY3, worldZ3 = localToWorld(self.rootNode, self.cuttingAreas[i].startX, 0, self.cuttingAreas[i].startZ+self.cuttingAreas[i].height);
        Utils.updateWheatArea(worldX, worldZ, worldX2, worldZ2, worldX3, worldZ3, 0.0);
    end;]]

    for i=1, table.getn(self.wheels) do

        local x,y,z = getRotation(self.wheels[i].repr);
        if self.firstTimeRun then
            local newX, newY, newZ = getWheelShapePosition(self.wheels[i].node, self.wheels[i].wheelShape);
            setTranslation(self.wheels[i].repr, newX, newY, newZ);
            local axleSpeed = getWheelShapeAxleSpeed(self.wheels[i].node, self.wheels[i].wheelShape)*3.14159/180;
            x = x+axleSpeed*dt/1000.0;
            setRotation(self.wheels[i].repr, x, steeringAngle, z);
        end;
    end;

    self.lastFillDelta = 0;
    if self.tipState == Trailer.TIPSTATE_OPENING or self.tipState == Trailer.TIPSTATE_OPEN then
        local m = self.capacity/(self.tipDischargeEndTime/self.tipAnimSpeedScale);
        local curFill = self.fillLevel;
        self:setFillLevel(self.fillLevel - (m* dt), self.currentFillType);
        self.lastFillDelta = self.fillLevel - curFill;

        _=[[for i=1, table.getn(self.dischargeParticleSystems) do
            setEmittingState(self.dischargeParticleSystems[i], self.fillLevel > 0);
        end;]]

        if self.tipState == Trailer.TIPSTATE_OPENING then
            if getAnimTrackTime(self.tipAnimCharSet, 0) > self.tipAnimDuration then
                self.tipState = Trailer.TIPSTATE_OPEN;
            end;
        else
            if getAnimTrackTime(self.tipAnimCharSet, 0) > self.tipDischargeEndTime then

                _=[[for i=1, table.getn(self.dischargeParticleSystems) do
                    setEmittingState(self.dischargeParticleSystems[i], false);
                end;]]
                self:onEndTip();
            end;
        end;
    elseif self.tipState == Trailer.TIPSTATE_CLOSING then

        if getAnimTrackTime(self.tipAnimCharSet, 0) < 0.0 then
            g_currentMission.allowSteerableMoving = true;
            g_currentMission.fixedCamera = false;
            self.tipState = Trailer.TIPSTATE_CLOSED;
        end;
    end;
    for i=1, table.getn(self.dischargeParticleSystems) do
        setEmittingState(self.dischargeParticleSystems[i], self.lastFillDelta < 0);
    end;

    if self.firstTimeRun then
        if self.emptyMass == nil then
            self.emptyMass = getMass(self.fillRootNode);
            self.currentMass = self.emptyMass;
        end;
        local massScale = self.massScale*self.capacity;
        local newMass = self.emptyMass + self.fillLevel*massScale;
        if newMass ~= self.currentMass then
            setMass(self.fillRootNode, newMass);
            self.currentMass = newMass;
            if self.centerOfMass ~= nil then
                setCenterOfMass(self.fillRootNode, self.centerOfMass[1], self.centerOfMass[2], self.centerOfMass[3]);
            end;
        end;
    end;

    self.firstTimeRun = true;
end;

function Trailer:draw()
end;

function Trailer:onAttach(attacherVehicle)
    --local x, y, z = getRotation(self.rootNode);
    --setRotation(self.rootNode, 0, y, z);

    _=[[if self.supportWheel.node ~= nil then
        setTranslation(self.supportWheel.node, self.supportWheel.x2, self.supportWheel.y2, self.supportWheel.z2);
    end;]]
    self.attacherVehicle = attacherVehicle;
    for i=1, table.getn(self.wheels) do
        setWheelShapeProps(self.wheels[i].node, self.wheels[i].wheelShape, 0, 0, 0);
    end;
end;

function Trailer:onDetach()

    _=[[if self.supportWheel.node ~= nil then
        setTranslation(self.supportWheel.node, self.supportWheel.x1, self.supportWheel.y1, self.supportWheel.z1);
    end;]]
    self.attacherVehicle = nil;
    for i=1, table.getn(self.wheels) do
        setWheelShapeProps(self.wheels[i].node, self.wheels[i].wheelShape, 0, 1000, 0);
    end;
end;

function Trailer:toggleTipState()

    if self.tipState == 0 then
        self:onStartTip();
    else
        self:onEndTip();
    end;
end;

function Trailer:onStartTip()

    if self.tipAnimCharSet ~= 0 then
        if getAnimTrackTime(self.tipAnimCharSet, 0) < 0.0 then
            setAnimTrackTime(self.tipAnimCharSet, 0, 0.0);
        end;
        setAnimTrackSpeedScale(self.tipAnimCharSet, 0, self.tipAnimSpeedScale);
        enableAnimTrack(self.tipAnimCharSet, 0);
    end;
    self.tipState = Trailer.TIPSTATE_OPENING;
    g_currentMission.allowSteerableMoving = false;
    g_currentMission.fixedCamera = true;
end;

function Trailer:onEndTip()
    if self.tipAnimCharSet ~= 0 then
        if getAnimTrackTime(self.tipAnimCharSet, 0) > self.tipAnimDuration then
            setAnimTrackTime(self.tipAnimCharSet, 0, self.tipAnimDuration);
        end;
        setAnimTrackSpeedScale(self.tipAnimCharSet, 0, -self.tipAnimSpeedScale);
        enableAnimTrack(self.tipAnimCharSet, 0);
    end;
    self.tipState = Trailer.TIPSTATE_CLOSING;
end;

function Trailer:allowFillType(fillType)

    return self.fillTypes[fillType] == true and (self.currentFillType == fillType or self.currentFillType == Trailer.FILLTYPE_UNKNOWN);
end;

function Trailer:setFillLevel(fillLevel, fillType)
    if not self:allowFillType(fillType) then
        return;
    end;
    self.currentFillType = fillType;
    self.fillLevel = fillLevel;
    if self.fillLevel > self.capacity then
        self.fillLevel = self.capacity;
    end;
    if self.fillLevel < 0 then
        self.fillLevel = 0;
    end;
    if self.grainPlane ~= nil then
        local yTranslation;
        if self.grainAnimCurve then
            local scaleX, scaleY, scaleZ , yTrans = self.grainAnimCurve:get(self.fillLevel/self.capacity);
            yTranslation = yTrans;
            setScale(self.grainPlane, scaleX, scaleY, scaleZ);
        else
            local m = (self.grainPlaneMaxY - self.grainPlaneMinY) / self.capacity;
            yTranslation = m*self.fillLevel + self.grainPlaneMinY;
        end;
            local xPos, yPos, zPos = getTranslation(self.grainPlane);
        setTranslation(self.grainPlane, xPos, yTranslation, zPos);
        setVisibility(self.grainPlane, self.fillLevel ~= 0);
    end;
end;

function Trailer:onBrake()

    for i=1, table.getn(self.wheels) do
        setWheelShapeProps(self.wheels[i].node, self.wheels[i].wheelShape, 0, self.brakeForce, 0);
    end;

end;

function Trailer:onReleaseBrake()

    for i=1, table.getn(self.wheels) do
        setWheelShapeProps(self.wheels[i].node, self.wheels[i].wheelShape, 0, 0, 0);
    end;

end;

function Trailer:handleAttachTrailerEvent()
    if g_currentMission.trailerInMountRange ~= nil then
        if g_currentMission.trailerInMountRangeVehicle == self then
            if self.attachedTrailer == nil then
                self:attachTrailer(g_currentMission.trailerInMountRange);
                return true;
            end;
        elseif self.attachedTrailer ~= nil then
            return self.attachedTrailer:handleAttachTrailerEvent();
        end;
    end;
    return false;
end;

function Trailer:handleDetachTrailerEvent()

    if self.attachedTrailer ~= nil then
        if not self.attachedTrailer:handleDetachTrailerEvent() then
            if self.trailerAttacherJointIndex ~= 0 then
                removeJoint(self.trailerAttacherJointIndex);
                self.trailerAttacherJointIndex = 0;
                self.attachedTrailer:onDetach();
                self.attachedTrailer = nil;
            end;
        end;
        return true;
    end;
    return false;
end;

function Trailer:attachTrailer(trailer)
    if self.trailerAttacherJoint ~= nil then
        local constr = JointConstructor:new();
        self.attachedTrailer = trailer;
        self.attachedTrailer:onAttach(self);
        constr:setActors(self.attachRootNode, self.attachedTrailer.attachRootNode);
        constr:setJointTransforms(self.trailerAttacherJoint, self.attachedTrailer.attacherJoint);
        --constr:setBreakable(40, 40);
        constr:setRotationLimit(0, Utils.degToRad(-10), Utils.degToRad(10));
        constr:setRotationLimit(1, Utils.degToRad(-50), Utils.degToRad(50));
        constr:setRotationLimit(2, Utils.degToRad(-50), Utils.degToRad(50));
        self.trailerAttacherJointIndex = constr:finalize();
    end;
end;
