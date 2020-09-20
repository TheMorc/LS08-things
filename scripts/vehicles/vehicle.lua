--
-- Vehicle
-- Base class for all vehicles
--
-- @author  Stefan Geiger (mailto:sgeiger@giants.ch)
-- @date  08/04/07

Vehicle = {};

function Vehicle:new(configFile, positionX, offsetY, positionZ, yRot, customMt)

    if Vehicle_mt == nil then
       Vehicle_mt = Class(Vehicle);
    end;

    local instance = {};
    if customMt ~= nil then
        setmetatable(instance, customMt);
    else
        setmetatable(instance, Vehicle_mt);
    end;
    
    instance.configFileName = configFile;

    local xmlFile = loadXMLFile("TempConfig", configFile);

    local rootNode = loadI3DFile(getXMLString(xmlFile, "vehicle.filename"));
    instance.rootNode = getChildAt(rootNode, 0)
    link(getRootNode(), instance.rootNode);
    delete(rootNode);

    local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, positionX, 300, positionZ);

    setTranslation(instance.rootNode, positionX, terrainHeight+offsetY, positionZ);
    setRotation(instance.rootNode, 0, yRot, 0);

    instance.numWheels = getXMLInt(xmlFile, "vehicle.numWheels");
    if instance.numWheels == nil then
        instance.numWheels = 0;
    end;

    instance.maxRotTime = 0;
    instance.minRotTime = 0;
    instance.autoRotateBackSpeed = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.wheels#autoRotateBackSpeed"), 1.0);
    instance.wheels = {};
    for i=1, instance.numWheels do
        local wheelnamei = string.format("vehicle.wheels.wheel" .. "%d", i);
        instance.wheels[i] = {};
        instance.wheels[i].rotSpeed = Utils.degToRad(getXMLFloat(xmlFile, wheelnamei .. "#rotSpeed"));
        instance.wheels[i].rotMax = Utils.degToRad(getXMLFloat(xmlFile, wheelnamei .. "#rotMax"));
        instance.wheels[i].rotMin = Utils.degToRad(getXMLFloat(xmlFile, wheelnamei .. "#rotMin"));
        instance.wheels[i].driveMode = Utils.getNoNil(getXMLInt(xmlFile, wheelnamei .. "#driveMode"), 0);
        instance.wheels[i].repr = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, wheelnamei .. "#repr"));
        instance.wheels[i].driveNode = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, wheelnamei .. "#driveNode"));
        if instance.wheels[i].driveNode == nil then
            instance.wheels[i].driveNode = instance.wheels[i].repr;
        end;
        local radius = getXMLFloat(xmlFile, wheelnamei .. "#radius");
        radius = Utils.getNoNil(radius, 1);
        _=[[local positionX = getXMLFloat(xmlFile, wheelnamei .. "#positionX");
        positionX = Utils.getNoNil(positionX, 0);
        local positionY = getXMLFloat(xmlFile, wheelnamei .. "#positionY");
        positionY = Utils.getNoNil(positionY, 0);
        local positionZ = getXMLFloat(xmlFile, wheelnamei .. "#positionZ");
        positionZ = Utils.getNoNil(positionZ, 0);]]
        local positionX, positionY, positionZ = getTranslation(instance.wheels[i].repr);
        instance.wheels[i].deltaY = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#deltaY"), 0.0);
        positionY = positionY+instance.wheels[i].deltaY;
        local suspTravel = getXMLFloat(xmlFile, wheelnamei .. "#suspTravel");
        suspTravel = Utils.getNoNil(suspTravel, 0);
        local spring = getXMLFloat(xmlFile, wheelnamei .. "#spring");
        spring = Utils.getNoNil(spring, 0);
        local damper = getXMLFloat(xmlFile, wheelnamei .. "#damper");
        damper = Utils.getNoNil(damper, 0);
        local mass = getXMLFloat(xmlFile, wheelnamei .. "#mass");
        mass = Utils.getNoNil(mass, 0.01);
        --local nodeIndexStr = getXMLString(xmlFile, wheelnamei .. "#node");
        _=[[if nodeIndexStr == nil or nodeIndexStr == "" then
            instance.wheels[i].node = instance.rootNode
        else
            instance.wheels[i].node = Utils.indexToObject(instance.rootNode, nodeIndexStr);
        end;]]
        instance.wheels[i].hasGroundContact = false;
        instance.wheels[i].axleSpeed = 0;
        instance.wheels[i].hasHandbrake = true;
        instance.wheels[i].node = getParent(instance.wheels[i].repr);
        instance.wheels[i].wheelShape = createWheelShape(instance.wheels[i].node, positionX, positionY, positionZ, radius, suspTravel, spring, damper, mass);

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
    
    instance.steering = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, "vehicle.steering#index"));
    if instance.steering ~= nil then
        instance.steeringSpeed = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.steering#rotationSpeed"), 0);
    end;

    local motorMinRpm = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#minRpm"), 1000);
    local motorMaxRpmStr = getXMLString(xmlFile, "vehicle.motor#maxRpm");
    local motorMaxRpm1, motorMaxRpm2, motorMaxRpm3 = Utils.getVectorFromString(motorMaxRpmStr);
    motorMaxRpm1 = Utils.getNoNil(motorMaxRpm1, 800);
    motorMaxRpm2 = Utils.getNoNil(motorMaxRpm2, 1000);
    motorMaxRpm3 = Utils.getNoNil(motorMaxRpm3, 1800);
    local motorMaxRpm = {motorMaxRpm1, motorMaxRpm2, motorMaxRpm3};
    local motorTorque = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#torque"), 15);
    local brakeForce = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#brakeForce"), 10);
    local forwardGearRatio = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#forwardGearRatio"), 1);
    local backwardGearRatio = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#backwardGearRatio"), 1.5);
    local differentialRatio = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#differentialRatio"), 1);
    local rpmFadeOutRange = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#rpmFadeOutRange"), 20);
    local torqueCurve = AnimCurve:new(linearInterpolator1);
    local torqueI = 0;
    while true do
        local key = string.format("vehicle.motor.torque(%d)", torqueI);
        local rpm = getXMLFloat(xmlFile, key.."#rpm");
        local torque = getXMLFloat(xmlFile, key.."#torque");
        if torque == nil or rpm == nil then
            break;
        end;
        torqueCurve:addKeyframe({v=torque, time = rpm});
        torqueI = torqueI +1;
    end;
    _=[[local torqueCurve = AnimCurve:new(linearInterpolator1);
    torqueCurve:addKeyframe({v=2.5, time = 500});
    torqueCurve:addKeyframe({v=4, time = 900});
    torqueCurve:addKeyframe({v=5, time = 1100});
    torqueCurve:addKeyframe({v=5, time = 1400});
    torqueCurve:addKeyframe({v=3, time = 1800});]]
    instance.motor = VehicleMotor:new(motorMinRpm, motorMaxRpm, torqueCurve, brakeForce, forwardGearRatio, backwardGearRatio, differentialRatio, rpmFadeOutRange);
    instance.lastWheelRpm = 0;
    instance.movingDirection = 0;

    instance.fuelCapacity = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.fuelCapacity"), 500);
    instance.fuelUsage = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.fuelUsage"), 0.01);

    instance.downForce = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.downForce"), 2);

    instance.numCameras = getXMLInt(xmlFile, "vehicle.cameras#count");
    if instance.numCameras == nil or instance.numCameras == 0 then
        instance.numCameras = 0;
        print("Error: no cameras in xml file: ", configFile);
    end;
    instance.cameras = {};
    for i=1, instance.numCameras do
        local cameranamei = string.format("vehicle.cameras.camera%d", i);
        local camIndexStr = getXMLString(xmlFile, cameranamei .. "#index");
        local cameraNode = Utils.indexToObject(instance.rootNode, camIndexStr);
        local rotatable = getXMLBool(xmlFile, cameranamei .. "#rotatable");
        local limit = getXMLBool(xmlFile, cameranamei .. "#limit");
        local rotMinX = getXMLFloat(xmlFile, cameranamei .. "#rotMinX");
        local rotMaxX = getXMLFloat(xmlFile, cameranamei .. "#rotMaxX");
        local transMin = getXMLFloat(xmlFile, cameranamei .. "#transMin");
        local transMax = getXMLFloat(xmlFile, cameranamei .. "#transMax");
        local rotateNode = "";
        if rotatable then
            rotateNode = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, cameranamei .. "#rotateNode"));
        end;
        --instance.cameras[i] = getXMLInt(xmlFile, cameranamei .. "#index");
        instance.cameras[i] = VehicleCamera:new(cameraNode, rotatable, rotateNode, limit, rotMinX, rotMaxX, transMin, transMax);
    end;

    instance.exitPoint = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, "vehicle.exitPoint#index"));

    instance.numLights = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.lights#count"), 0);
    instance.lights = {};
    for i=1, instance.numLights do
        local lightnamei = string.format("vehicle.lights.light" .. "%d", i);
        instance.lights[i] = Utils.indexToObject(instance.rootNode, getXMLInt(xmlFile, lightnamei .. "#index"));
        setVisibility(instance.lights[i], false);
    end;

    local numCuttingAreas = getXMLInt(xmlFile, "vehicle.cuttingAreas#count");
    if numCuttingAreas == nil then
        numCuttingAreas = 0;
    end;
    instance.cuttingAreas = {}
    for i=1, numCuttingAreas do
        instance.cuttingAreas[i] = {};
        local areanamei = string.format("vehicle.cuttingAreas.cuttingArea" .. "%d", i);
        local x,y,z = getTranslation(getChildAt(instance.rootNode, getXMLInt(xmlFile, areanamei .. "#startIndex")));
        local widthX, widthY, widthZ = getTranslation(getChildAt(instance.rootNode, getXMLInt(xmlFile, areanamei .. "#widthIndex")));
        local heightX, heightY, heightZ = getTranslation(getChildAt(instance.rootNode, getXMLInt(xmlFile, areanamei .. "#heightIndex")));
        instance.cuttingAreas[i].startX = x;
        instance.cuttingAreas[i].startZ = z;
        instance.cuttingAreas[i].width = widthX-x;
        instance.cuttingAreas[i].height = heightZ-z;
    end;


    local motorStartSound = getXMLString(xmlFile, "vehicle.motorStartSound#file");
    if motorStartSound ~= nil and motorStartSound ~= "" then
        instance.motorStartSound = createSample("motorStartSound");
        loadSample(instance.motorStartSound, motorStartSound, false);
        instance.motorStartSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorStartSound#pitchOffset"), 0);
    end;

    local attachSound = getXMLString(xmlFile, "vehicle.attachSound#file");
    if attachSound ~= nil and attachSound ~= "" then
        instance.attachSound = createSample("attachSound");
        loadSample(instance.attachSound, attachSound, false);
        instance.attachSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.attachSound#pitchOffset"), 0);
    end;

    local motorSound = getXMLString(xmlFile, "vehicle.motorSound#file");
    if motorSound ~= nil and motorSound ~= "" then
        instance.motorSound = createSample("motorSound");
        loadSample(instance.motorSound, motorSound, false);
        instance.motorSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorSound#pitchOffset"), 0);
        instance.motorSoundPitchScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorSound#pitchScale"), 0.05);
        instance.motorSoundPitchMax = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorSound#pitchMax"), 2.0);
    end;

    local reverseDriveSound = getXMLString(xmlFile, "vehicle.reverseDriveSound#file");
    if reverseDriveSound ~= nil and reverseDriveSound ~= "" then
        instance.reverseDriveSound = createSample("reverseDriveSound");
        instance.reverseDriveSoundEnabled = false;
        loadSample(instance.reverseDriveSound, reverseDriveSound, false);
    end;

    _=[[local weight = getXMLFloat(xmlFile, "vehicle.weight");
    if weight ~= nil then
        print("set mass: ", weight);
        setMass(instance.rootNode, weight/1000.0);
    end;]]
    -- this isnt working correctly yet

    --print("mass: ", getMass(instance.rootNode));

    local centerOfMassX = getXMLFloat(xmlFile, "vehicle.centerOfMass#x");
    local centerOfMassY = getXMLFloat(xmlFile, "vehicle.centerOfMass#y");
    local centerOfMassZ = getXMLFloat(xmlFile, "vehicle.centerOfMass#z");
    if centerOfMassX ~= nil and centerOfMassY ~= nil and centerOfMassZ ~= nil then
        setCenterOfMass(instance.rootNode, centerOfMassX, centerOfMassY, centerOfMassZ);
    end

    instance.trailerAttacherJoint = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, "vehicle.attacherJoint#index"));
    instance.trailerAttacherJointIndex = 0;
    instance.attachedTrailer = nil;

    instance.attacherJoints = {};
    local i=0;
    while true do
        local baseName = string.format("vehicle.attacherJoints.attacherJoint(%d)", i);
        local index = getXMLString(xmlFile, baseName.. "#index");
        if index == nil then
            break;
        end;
        local object = Utils.indexToObject(instance.rootNode, index);
        if object ~= nil then
            local entry = {};
            entry.jointTransform = object;
            local x, y, z;
            local rotationNode = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, baseName.. "#rotationNode"));
            if rotationNode ~= nil then
                entry.rotationNode = rotationNode;
                x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName.."#maxRot"));
                entry.maxRot = {};
                entry.maxRot[1] = Utils.degToRad(Utils.getNoNil(x, 0));
                entry.maxRot[2] = Utils.degToRad(Utils.getNoNil(y, 0));
                entry.maxRot[3] = Utils.degToRad(Utils.getNoNil(z, 0));

                x, y, z = getRotation(rotationNode);
                entry.minRot = {x,y,z};
            end;
            local rotationNode2 = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, baseName.. "#rotationNode2"));
            if rotationNode2 ~= nil then
                entry.rotationNode2 = rotationNode2;
                x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName.."#maxRot2"));
                entry.maxRot2 = {};
                entry.maxRot2[1] = Utils.degToRad(Utils.getNoNil(x, 0));
                entry.maxRot2[2] = Utils.degToRad(Utils.getNoNil(y, 0));
                entry.maxRot2[3] = Utils.degToRad(Utils.getNoNil(z, 0));

                x, y, z = getRotation(rotationNode2);
                entry.minRot2 = {x,y,z};
            end;


            x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName.."#maxRotLimit"));
            entry.maxRotLimit = {};
            entry.maxRotLimit[1] = Utils.degToRad(Utils.getNoNil(math.abs(x), 0));
            entry.maxRotLimit[2] = Utils.degToRad(Utils.getNoNil(math.abs(y), 0));
            entry.maxRotLimit[3] = Utils.degToRad(Utils.getNoNil(math.abs(z), 20));

            x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName.."#maxTransLimit"));
            entry.maxTransLimit = {};
            entry.maxTransLimit[1] = Utils.getNoNil(math.abs(x), 0);
            entry.maxTransLimit[2] = Utils.getNoNil(math.abs(y), 1);
            entry.maxTransLimit[3] = Utils.getNoNil(math.abs(z), 0);

            entry.moveTime = Utils.getNoNil(getXMLFloat(xmlFile, baseName.."#moveTime"), 0.5)*1000;

            local rotationNode = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, baseName.. ".topArm#rotationNode"));
            local translationNode = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, baseName.. ".topArm#translationNode"));
            local referenceNode = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, baseName.. ".topArm#referenceNode"));
            if rotationNode ~= nil then
                local topArm = {};
                topArm.rotationNode = rotationNode;
                topArm.rotX, topArm.rotY, topArm.rotZ = getRotation(rotationNode);
                if translationNode ~= nil and referenceNode ~= nil then
                    topArm.translationNode = translationNode;
                    local ax, ay, az = getWorldTranslation(referenceNode);
                    local bx, by, bz = getWorldTranslation(translationNode);
                    topArm.referenceDistance = Utils.vector3Length(ax-bx, ay-by, az-bz);
                end;
                topArm.zScale = Utils.sign(Utils.getNoNil(getXMLFloat(xmlFile, baseName.. ".topArm#zScale"), 1));
                entry.topArm = topArm;
            end;
            local rotationNode = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, baseName.. ".bottomArm#rotationNode"));
            local translationNode = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, baseName.. ".bottomArm#translationNode"));
            local referenceNode = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, baseName.. ".bottomArm#referenceNode"));
            if rotationNode ~= nil then
                local bottomArm = {};
                bottomArm.rotationNode = rotationNode;
                bottomArm.rotX, bottomArm.rotY, bottomArm.rotZ = getRotation(rotationNode);
                if translationNode ~= nil and referenceNode ~= nil then
                    bottomArm.translationNode = translationNode;
                    local ax, ay, az = getWorldTranslation(referenceNode);
                    local bx, by, bz = getWorldTranslation(translationNode);
                    bottomArm.referenceDistance = Utils.vector3Length(ax-bx, ay-by, az-bz);
                end;
                bottomArm.zScale = Utils.sign(Utils.getNoNil(getXMLFloat(xmlFile, baseName.. ".bottomArm#zScale"), 1));
                entry.bottomArm = bottomArm;
            end;
            entry.jointIndex = 0;
            table.insert(instance.attacherJoints, entry);
        end;
        i = i+1;
    end;

    --instance.attachedAttachableIndex = 0;
    instance.attachedImplements = {};
    instance.selectedImplement = 0;

    instance.tipCamera = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, "vehicle.tipCamera#index"));

    instance.exhaustParticleSystems = {};
    local exhaustParticleSystemCount = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.exhaustParticleSystems#count"), 0);
    for i=1, exhaustParticleSystemCount do
        local namei = string.format("vehicle.exhaustParticleSystems.exhaustParticleSystem" .. "%d", i);
        Utils.loadParticleSystem(xmlFile, instance.exhaustParticleSystems, namei, instance.rootNode, false)
    end;


    delete(xmlFile);

    --instance.steeringAngle = 0;
    instance.rotatedTime = 0;
    instance.firstTimeRun = false;
    instance.camIndex = 1;
    instance.isEntered = false;

    instance.lightsActive = false;
    instance.lastPosition = nil; -- = {0,0,0};
    instance.lastSpeed = 0;
    instance.lastMovedDistance = 0;
    instance.speedDisplayDt = 0;
    instance.speedDisplayScale = 1;
    instance.isBroken = false;

    instance.lastSoundSpeed = 0;

    instance.time = 0;

    instance.showWaterWarning = false;

    instance.hasRefuelStationInRange = false;
    instance.doRefuel = false;
    instance:setFuelFillLevel(instance.fuelCapacity);

    instance.waterSplashSample = nil;

    instance.hudBasePoxX = 0.8325;
    instance.hudBasePoxY = (1-0.99);
    instance.hudBaseWidth = 0.16;
    instance.hudBaseHeight = 0.1625;
    instance.hudBaseOverlay = Overlay:new("hudBaseOverlay", "data/missions/hud_vehicle_base.png", instance.hudBasePoxX, instance.hudBasePoxY, instance.hudBaseWidth, instance.hudBaseHeight);

    instance.refuelSampleRunning = false;
    instance.refuelSample = createSample("reverseDriveSound");
    loadSample(instance.refuelSample, "data/maps/sounds/refuel.wav", false);

    return instance;
end;

function Vehicle:delete()
    for i=1, table.getn(self.cameras) do
        self.cameras[i]:delete();
    end;

    if self.attachSound ~= nil then
        delete(self.attachSound);
    end;
    if self.motorSound ~= nil then
        delete(self.motorSound);
    end;
    if self.motorStartSound ~= nil then
        delete(self.motorStartSound);
    end;
    if self.reverseDriveSound ~= nil then
        delete(self.reverseDriveSound);
    end;
    if self.waterSplashSample ~= nil then
        delete(self.waterSplashSample);
    end;
    if self.refuelSample ~= nil then
        delete(self.refuelSample);
    end;
    
    if self.hudBaseOverlay then
        self.hudBaseOverlay:delete();
    end;

    delete(self.rootNode);
end;

function Vehicle:setWorldPosition(x,y,z, xRot,yRot,zRot)
    setTranslation(self.rootNode, x,y,z);
    setRotation(self.rootNode, xRot,yRot,zRot);
end;

function Vehicle:mouseEvent(posX, posY, isDown, isUp, button)
    if self.isEntered then
        self.cameras[self.camIndex]:mouseEvent(posX, posY, isDown, isUp, button);
    end;
end;

function Vehicle:keyEvent(unicode, sym, modifier, isDown)
    if self.isEntered then
        if self.selectedImplement ~= 0 then
            self.attachedImplements[self.selectedImplement].object:keyEvent(unicode, sym, modifier, isDown);
        end;
        if self.attachedTrailer ~= nil then
            self.attachedTrailer:keyEvent(unicode, sym, modifier, isDown);
        end;
    end;
end;

function Vehicle:update(dt, isActive)

    self.time = self.time + dt;

    if self.isEntered then

        local waterY = 79;
        xt,yt,zt = getTranslation(self.rootNode);
        local deltaWater = yt-waterY;
        if deltaWater < 0 then
            self.isBroken = true;
            g_currentMission:onSunkVehicle();
            g_currentMission:onLeaveVehicle();

            local volume = math.min(1, self.lastSpeed*3600/30);
            if self.waterSplashSample == nil then
                self.waterSplashSample = createSample("waterSplashSample");
                loadSample(self.waterSplashSample, "data/maps/sounds/waterSplash.wav", false);
            end;
            playSample(self.waterSplashSample, 1, volume, 0);

        end;
        self.showWaterWarning = deltaWater < 2;

        if self.playMotorSound and self.motorSound ~= nil and self.playMotorSoundTime <= self.time then
            playSample(self.motorSound, 0, 1, 0);
            self.playMotorSound = false;
        end;

        self.speedDisplayDt = self.speedDisplayDt + dt;
        if self.speedDisplayDt > 100 then
            local newX, newY, newZ = getWorldTranslation(self.rootNode);
            if self.lastPosition == nil then
                self.lastPosition = {newX, newY, newZ};
            end;
            self.lastMovedDistance = Utils.vector3Length(newX-self.lastPosition[1], newY-self.lastPosition[2], newZ-self.lastPosition[3]);
            self.lastSpeed = self.lastSpeed*0.3 + (self.lastMovedDistance/self.speedDisplayDt*self.speedDisplayScale)*0.7;
            self.lastPosition = {newX, newY, newZ};
            self.speedDisplayDt = 0;
        end;

        local fuelUsed = self.lastMovedDistance*self.fuelUsage;
        self:setFuelFillLevel(self.fuelFillLevel-fuelUsed);

        g_currentMission.missionStats.fuelUsageTotal = g_currentMission.missionStats.fuelUsageTotal + fuelUsed;
        g_currentMission.missionStats.fuelUsageSession = g_currentMission.missionStats.fuelUsageSession + fuelUsed;
        
        g_currentMission.missionStats.traveledDistanceTotal = g_currentMission.missionStats.traveledDistanceTotal + self.lastMovedDistance*0.001;
        g_currentMission.missionStats.traveledDistanceSession = g_currentMission.missionStats.traveledDistanceSession + self.lastMovedDistance*0.001;

        if InputBinding.hasEvent(InputBinding.SWITCH_IMPLEMENT) then
            local selected = self.selectedImplement;
            local numImplements = table.getn(self.attachedImplements);
            if selected ~= 0 and numImplements > 1 then
                selected = selected+1;
                if selected > numImplements then
                    selected = 1;
                end;
                self:setSelectedImplement(selected);
            end;
        end;

        if not g_currentMission.fixedCamera then
            if InputBinding.hasEvent(InputBinding.CAMERA_SWITCH) then
                self.cameras[self.camIndex]:onDeactivate();
                self.camIndex = self.camIndex + 1;
                if self.camIndex > self.numCameras then
                    self.camIndex = 1;
                end;
                self.cameras[self.camIndex]:onActivate();
            end;
        end;
        if InputBinding.hasEvent(InputBinding.TOGGLE_LIGHTS) then
            self.lightsActive = not self.lightsActive;
            for i=1, self.numLights do
                local light = self.lights[i];
                setVisibility(light, self.lightsActive);
            end;
        end;

        if self.doRefuel and InputBinding.hasEvent(InputBinding.REFUEL) then
            self.doRefuel = false;
        else
            if self.hasRefuelStationInRange and InputBinding.hasEvent(InputBinding.REFUEL) then
                self.doRefuel = true;
            end;
        end;

        if InputBinding.hasEvent(InputBinding.SPEED_LEVEL1) then
            self.motor:setSpeedLevel(1, false);
        elseif InputBinding.hasEvent(InputBinding.SPEED_LEVEL2) then
            self.motor:setSpeedLevel(2, false);
        elseif InputBinding.hasEvent(InputBinding.SPEED_LEVEL3) then
            self.motor:setSpeedLevel(3, false);
        end;

        if InputBinding.hasEvent(InputBinding.ATTACH) then
            self:handleAttachEvent();
        end;

        if InputBinding.hasEvent(InputBinding.LOWER_IMPLEMENT) then
            self:handleLowerImplementEvent();
        end;

        --if self.attachedAttachable ~= nil then
        for i=1, table.getn(self.attachedImplements) do
            self.attachedImplements[i].object:update(dt);
        end;
    end;

    if self.isEntered then

        local acceleration = 0;
        if g_currentMission.allowSteerableMoving and not self.playMotorSound then
            acceleration = -getInputAxis(Input.AXIS_Y);
            if math.abs(acceleration) > 0.8 then
                self.motor:setSpeedLevel(0, true)
            end;
            if self.motor.speedLevel ~= 0 then
                acceleration = 1.0;
            end;
            --acceleration = 0.5;
        end;
        if self.fuelFillLevel == 0 then
            acceleration = 0;
        end;

        local worldX,worldY,worldZ = localDirectionToWorld(self.rootNode, 0, -self.downForce*dt/1000, 0);
        addForce(self.rootNode, worldX, worldY, worldZ, 0, 0, 0, true);


        --if Input.isKeyPressed(Input.KEY_a) then
        local rotScale = math.min(1.0/(self.lastSpeed*50+1), 1);
        local inputAxisX = getInputAxis(0);
        if inputAxisX < 0 then
            self.rotatedTime = math.min(self.rotatedTime - dt/1000*inputAxisX*rotScale, self.maxRotTime);
            --if self.rotatedTime > self.maxRotTime then
            --    self.rotatedTime = self.maxRotTime;
            --end;
        --elseif Input.isKeyPressed(Input.KEY_d) then
        elseif inputAxisX > 0 then
            self.rotatedTime = math.max(self.rotatedTime - dt/1000*inputAxisX*rotScale, self.minRotTime);
            --if self.rotatedTime < self.minRotTime then
            --    self.rotatedTime = self.minRotTime;
            --end;
        else
            if self.autoRotateBackSpeed ~= 0 then
                if self.rotatedTime > 0 then
                    self.rotatedTime = math.max(self.rotatedTime - dt/1000*self.autoRotateBackSpeed*rotScale, 0);
                else
                    self.rotatedTime = math.min(self.rotatedTime + dt/1000*self.autoRotateBackSpeed*rotScale, 0);
                end;
            end;
        end;

        if self.firstTimeRun then
            WheelsUtil.updateWheels(self, dt, self.lastSpeed, acceleration, false, 0)
        end;

        if self.numWheels > 0 then
            if self.motorSound ~= nil then
                --setSamplePitch(self.motorSound, math.min(self.motorSoundPitchOffset + self.motorSoundPitchScale*math.abs(self.lastSoundSpeed), self.motorSoundPitchMax));
                local roundPerSecond = (self.motor.lastMotorRpm-self.motor.minRpm) / 60;
                setSamplePitch(self.motorSound, math.min(self.motorSoundPitchOffset + self.motorSoundPitchScale*math.abs(roundPerSecond), self.motorSoundPitchMax));
                --print(math.min(self.motorSoundPitchOffset + self.motorSoundPitchScale*math.abs(roundPerSecond), self.motorSoundPitchMax));
            end;
        end;
        
        if self.steering ~= nil then
            setRotation(self.steering, 0, self.rotatedTime*self.steeringSpeed, 0);
        end;

        self.doRefuel = self.doRefuel and self.hasRefuelStationInRange;
        if self.doRefuel then
        
            if not self.refuelSampleRunning then
                --print("start");
                playSample(self.refuelSample, 0, 1, 0);
                self.refuelSampleRunning = true;
            end;
        
            local refuelSpeed = 0.01;
            local currentFillLevel = self.fuelFillLevel;
            self:setFuelFillLevel(self.fuelFillLevel+refuelSpeed*dt);
            local delta = (self.fuelFillLevel-currentFillLevel)*g_fuelPricePerLiter;
            
            --print("delta ", delta);
            
            if delta <= 0 then
                self.doRefuel = false;
            end;
            
            g_currentMission.missionStats.expensesTotal = g_currentMission.missionStats.expensesTotal + delta;
            g_currentMission.missionStats.expensesSession = g_currentMission.missionStats.expensesSession + delta;
            g_currentMission.missionStats.money = g_currentMission.missionStats.money - delta;

        else
            if self.refuelSampleRunning then
                --print("stop");
                stopSample(self.refuelSample);
                self.refuelSampleRunning = false;
            end;
        end;
    end;

    _=[[local axleSpeedSum = 0;
    self.lastWheelRpm = 0;
    for i=1, self.numWheels do
        local steeringAngle = 0;
        if self.wheels[i].rotSpeed ~= 0 then
            steeringAngle = self.rotatedTime * self.wheels[i].rotSpeed;
            if steeringAngle > self.wheels[i].rotMax then
                steeringAngle = self.wheels[i].rotMax;
            elseif steeringAngle < self.wheels[i].rotMin then
                steeringAngle = self.wheels[i].rotMin;
            end;
        end;
        local actMotorTorque = motorTorque;
        if self.wheels[i].driveMode == 0 then
            actMotorTorque = 0;
        end;
        setWheelShapeProps(self.wheels[i].node, self.wheels[i].wheelShape, actMotorTorque, brakeForce, steeringAngle);

        local x,y,z = getRotation(self.wheels[i].repr);
        local xDrive,yDrive,zDrive;
        if self.wheels[i].repr == self.wheels[i].driveNode then
            xDrive,yDrive,zDrive = x,y,z;
        else
            xDrive,yDrive,zDrive = getRotation(self.wheels[i].driveNode);
        end;
        if self.firstTimeRun then
            local newX, newY, newZ = getWheelShapePosition(self.wheels[i].node, self.wheels[i].wheelShape);
            setTranslation(self.wheels[i].repr, newX, newY, newZ);
            local axleSpeedDeg = getWheelShapeAxleSpeed(self.wheels[i].node, self.wheels[i].wheelShape);
            local axleSpeed = axleSpeedDeg*3.14159/180;
            axleSpeedSum = axleSpeedSum + axleSpeed;
            self.lastWheelRpm = self.lastWheelRpm + math.abs(axleSpeed)/(math.pi*2) * 60; --math.abs(axleSpeedDeg)/360 * 60;
            --print("axleSpeed", i, ": ", axleSpeed);
            --rotate(self.wheels[i].repr, axleSpeed*dt/1000.0, 0, 0);
            xDrive = xDrive+axleSpeed*dt/1000.0;

            --2*pi*hz = w   rad/s
            --hz = w/(2pi)
        end;
        if self.wheels[i].repr == self.wheels[i].driveNode then
            setRotation(self.wheels[i].repr, xDrive, steeringAngle, z);
        else
            setRotation(self.wheels[i].repr, x, steeringAngle, z);
            setRotation(self.wheels[i].driveNode, xDrive, yDrive, zDrive);
        end;
    end;
    self.lastWheelRpm = self.lastWheelRpm / self.numWheels;
    if axleSpeedSum > 0.01 then
        self.movingDirection = 1;
    elseif axleSpeedSum < -0.01 then
        self.movingDirection = -1;
    else
        self.movingDirection = 0;
    end;

    self.lastSoundSpeed = math.abs(axleSpeedSum/self.numWheels);]]

    --if self.attachedAttachable ~= nil then
    for i=1, table.getn(self.attachedImplements) do
        local implement = self.attachedImplements[i];
        local jointDesc = self.attacherJoints[implement.jointDescIndex];
        --local jointDesc = self.attacherJoints[self.attachedAttachableIndex];
        if jointDesc.topArm ~= nil and implement.object.topReferenceNode ~= nil then
            local ax, ay, az = getWorldTranslation(jointDesc.topArm.rotationNode);
            local bx, by, bz = getWorldTranslation(implement.object.topReferenceNode);

            local x, y, z = worldDirectionToLocal(getParent(jointDesc.topArm.rotationNode), bx-ax, by-ay, bz-az);
            setDirection(jointDesc.topArm.rotationNode, x*jointDesc.topArm.zScale, y*jointDesc.topArm.zScale, z*jointDesc.topArm.zScale, 0, 1, 0);
            if jointDesc.topArm.translationNode ~= nil then
                local distance = Utils.vector3Length(ax-bx, ay-by, az-bz);
                setTranslation(jointDesc.topArm.translationNode, 0, 0, (distance-jointDesc.topArm.referenceDistance)*jointDesc.topArm.zScale);
            end;
        end;
        if jointDesc.bottomArm ~= nil and implement.object.topReferenceNode ~= nil then
            local ax, ay, az = getWorldTranslation(jointDesc.bottomArm.rotationNode);
            local bx, by, bz = getWorldTranslation(implement.object.attacherJoint);

            local x, y, z = worldDirectionToLocal(getParent(jointDesc.bottomArm.rotationNode), bx-ax, by-ay, bz-az);
            setDirection(jointDesc.bottomArm.rotationNode, x*jointDesc.bottomArm.zScale, y*jointDesc.bottomArm.zScale, z*jointDesc.bottomArm.zScale, 0, 1, 0);
            if jointDesc.bottomArm.translationNode ~= nil then
                local distance = Utils.vector3Length(ax-bx, ay-by, az-bz);
                setTranslation(jointDesc.bottomArm.translationNode, 0, 0, (distance-jointDesc.bottomArm.referenceDistance)*jointDesc.bottomArm.zScale);
            end;
        end;
    end;

    if self.isEntered then
        if not g_currentMission.fixedCamera then
            setCamera(self.cameras[self.camIndex].cameraNode);
            self.cameras[self.camIndex]:update(dt);
        else
            -- set fixed tip camera
            if self.tipCamera ~= nil then
                setCamera(self.tipCamera);
            else
                self.cameras[self.camIndex]:resetCamera();
            end;
        end;
        --setCamera(getChildAt(self.rootNode, self.cameras[self.camIndex]));

        --if self.attachedAttachable ~= nil then
        for i=1, table.getn(self.attachedImplements) do
            local implement = self.attachedImplements[i];
            local jointDesc = self.attacherJoints[implement.jointDescIndex];
            --local jointDesc = self.attacherJoints[self.attachedAttachableIndex];

            local jointFrameInvalid = false;
            if jointDesc.rotationNode ~= nil then
                local x, y, z = getRotation(jointDesc.rotationNode);
                local rot = {x,y,z};
                local newRot = Utils.getMovedLimitedValues(rot, jointDesc.maxRot, jointDesc.minRot, 3, jointDesc.moveTime, dt, not jointDesc.moveDown);
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
                local newRot = Utils.getMovedLimitedValues(rot, jointDesc.maxRot2, jointDesc.minRot2, 3, jointDesc.moveTime, dt, not jointDesc.moveDown);
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

            local newRotLimit = {0,0,0};
            if not implement.object.fixedAttachRotation then
                newRotLimit = Utils.getMovedLimitedValues(implement.jointRotLimit, jointDesc.maxRotLimit, {0,0,0}, 3, jointDesc.moveTime, dt, not jointDesc.moveDown);
            end;
            for i=1, 3 do
                if math.abs(newRotLimit[i] - implement.jointRotLimit[i]) > 0.001 then
                    setJointRotationLimit(jointDesc.jointIndex, i-1, true, -newRotLimit[i], newRotLimit[i]);
                end;
            end;
            implement.jointRotLimit = newRotLimit;

            local newTransLimit = Utils.getMovedLimitedValues(implement.jointTransLimit, jointDesc.maxTransLimit, {0,0,0}, 3, jointDesc.moveTime, dt, not jointDesc.moveDown);
            for i=1, 3 do
                if math.abs(newTransLimit[i] - implement.jointTransLimit[i]) > 0.001 then
                    setJointTranslationLimit(jointDesc.jointIndex, i-1, true, -newTransLimit[i], newTransLimit[i]);
                end;
            end;
            implement.jointTransLimit = newTransLimit;
        end;

        if self.reverseDriveSound ~= nil and self.movingDirection == -1 then
            if not self.reverseDriveSoundEnabled then
                playSample(self.reverseDriveSound, 0, 0.7, 0);
                self.reverseDriveSoundEnabled = true;
            end;
        else
            if self.reverseDriveSoundEnabled then
                stopSample(self.reverseDriveSound);
                self.reverseDriveSoundEnabled = false;
            end;
        end;

        -- update crops
        _=[[for i=1, table.getn(self.cuttingAreas) do
            local worldX, worldY, worldZ = localToWorld(self.rootNode, self.cuttingAreas[i].startX, 0, self.cuttingAreas[i].startZ);
            local worldX2, worldY2, worldZ2 = localToWorld(self.rootNode, self.cuttingAreas[i].startX+self.cuttingAreas[i].width, 0, self.cuttingAreas[i].startZ);
            local worldX3, worldY3, worldZ3 = localToWorld(self.rootNode, self.cuttingAreas[i].startX, 0, self.cuttingAreas[i].startZ+self.cuttingAreas[i].height);
            Utils.updateWheatArea(worldX, worldZ, worldX2, worldZ2, worldX3, worldZ3, 0.0);
        end;]]
    end;


    self.firstTimeRun = true;
end;

function Vehicle:drawGrainLevel(level, capacity, warnPercent)

    local percent = level/capacity*100;
    setTextBold(true);

    if percent >= warnPercent then
        setTextColor(1.0, 0.0, 0.0, 1.0);
    else
        setTextColor(1.0, 1.0, 1.0, 1.0);
    end;

    renderText(self.hudBasePoxX+0.031, self.hudBasePoxY+0.006, 0.03, string.format("%d(%d%%)", level, percent));
    if percent >= warnPercent then
        setTextColor(1.0, 1.0, 1.0, 1.0);
    end;
    setTextBold(false);
end;

function Vehicle:draw()

    if self.selectedImplement ~= 0 then
        self.attachedImplements[self.selectedImplement].object:draw();
    end;
    if self.attachedTrailer ~= nil then
        self.attachedTrailer:draw();
        self:drawGrainLevel(self.attachedTrailer.fillLevel, self.attachedTrailer.capacity, 101);
    end;
    if table.getn(self.attachedImplements) > 1 then
        --g_currentMission:addHelpButtonText("Geräteauswahl wechseln", InputBinding.SWITCH_IMPLEMENT);
        g_currentMission:addHelpButtonText(g_i18n:getText("Change_tools"), InputBinding.SWITCH_IMPLEMENT);
    end;

    if self.showWaterWarning then
        --g_currentMission:addWarning("Fahren Sie nicht zu tief ins Wasser", 0.05, 0.025+0.007);
        g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_depth_into_the_water"), 0.05, 0.025+0.007);
        
    end;

    local kmh = self.lastSpeed*3600;
    if self.isEntered then

        self.hudBaseOverlay:render();

        --if kmh >= 1 and kmh < 100 then

         --   setTextColor(1.0, 1.0, 1.0, 1.0);

         --   local textSize = 0.075;
         --   local yPos = 0.05;
         --   setTextBold(true);
          --  renderText(0.79, yPos, textSize, string.format("%d", kmh));
         --   renderText(0.86, yPos, textSize, "km/h");
          --  setTextBold(false);
        --end;
        --setTextColor(1.0, 1.0, 1.0, 1.0);
        --renderText(0.77, 0.12, 0.05, "Diesel: " .. string.format("%d l", self.fuelFillLevel));


        setTextBold(true);
        setTextColor(1.0, 1.0, 1.0, 1.0);
        if kmh > 0 and kmh < 100 then
            renderText(self.hudBasePoxX+0.007, self.hudBasePoxY+0.095, 0.06, string.format("%2d", kmh));
        end;
        renderText(self.hudBasePoxX+0.058, self.hudBasePoxY+0.094, 0.06, "km/h");
        renderText(self.hudBasePoxX+0.031, self.hudBasePoxY+0.071, 0.03, string.format("%d", g_currentMission.missionStats.money));
        
        local fuelWarn = 50;
        if self.fuelFillLevel < fuelWarn then
            setTextColor(1,0,0,1);
        end;
        renderText(self.hudBasePoxX+0.031, self.hudBasePoxY+0.039, 0.03, string.format("%d liter", self.fuelFillLevel));
        if self.fuelFillLevel < fuelWarn then
            setTextColor(1,1,1,1);
        end;
        
        
        setTextBold(false);


        if self.hasRefuelStationInRange and not self.doRefuel and self.fuelFillLevel ~= self.fuelCapacity then
            g_currentMission:addHelpButtonText(g_i18n:getText("Refuel"), InputBinding.REFUEL);
        end;
    end;

    --renderText(0.7, 0.6, 0.03, string.format("rpm: %f", self.motor.lastMotorRpm));

    --local cam = self.cameras[self.camIndex];
    --if cam ~= nil then
    --    renderText(0.4,0.5,0.03,string.format("rot: %f trans: %f", cam.rotX, Utils.vector3Length(cam.transX, cam.transY, cam.transZ)));
    --end;

end;

function Vehicle:onEnter()
    self.isEntered = true;

    local motorSoundOffset = 0;
    if self.motorStartSound ~= nil then
        setSamplePitch(self.motorStartSound, self.motorStartSoundPitchOffset);
        playSample(self.motorStartSound, 1, 1, 0);
        --motorSoundOffset = 800;
        motorSoundOffset = getSampleDuration(self.motorStartSound);
    end;

    self.playMotorSound = true;
    self.playMotorSoundTime = self.time+motorSoundOffset;
    self.reverseDriveSoundEnabled = false;

    self.camIndex = 1;
    self.cameras[self.camIndex]:onActivate();

    Utils.setEmittingState(self.exhaustParticleSystems, true)
end;

function Vehicle:onLeave()
    self.isEntered = false;
    if self.motorSound ~= nil then
        stopSample(self.motorSound);
    end;
    if self.reverseDriveSoundEnabled then
        stopSample(self.reverseDriveSound);
        self.reverseDriveSoundEnabled = false;
    end;
    self.cameras[self.camIndex]:onDeactivate();

    self.doRefuel = false;

    Utils.setEmittingState(self.exhaustParticleSystems, false)
    for i=1, self.numLights do
        setVisibility(self.lights[i], false);
    end;
    self.lightsActive = false;

    for i=1, table.getn(self.wheels) do
        setWheelShapeProps(self.wheels[i].node, self.wheels[i].wheelShape, 0, self.motor.brakeForce, 0);
    end;
end;

function Vehicle:attachImplement(object, index)

    local jointDesc = self.attacherJoints[index];
    local implement = {};
    implement.object = object;
    implement.object:onAttach(self);
    implement.jointDescIndex = index;

    local constr = JointConstructor:new();
    constr:setActors(self.rootNode, implement.object.rootNode);
    constr:setJointTransforms(jointDesc.jointTransform, implement.object.attacherJoint);
    --constr:setBreakable(20, 10);

    implement.jointRotLimit = {};
    implement.jointTransLimit = {};
    for i=1, 3 do
        local rotLimit = jointDesc.maxRotLimit[i];
        if implement.object.fixedAttachRotation then
            rotLimit = 0;
        end;
        constr:setRotationLimit(i-1, -rotLimit, rotLimit);
        implement.jointRotLimit[i] = rotLimit;

        constr:setTranslationLimit(i-1, true, -jointDesc.maxTransLimit[i], jointDesc.maxTransLimit[i]);
        implement.jointTransLimit[i] = jointDesc.maxTransLimit[i];
    end;
    if jointDesc.rotationNode ~= nil then
        setRotation(jointDesc.rotationNode, unpack(jointDesc.maxRot));
    end;
    if jointDesc.rotationNode2 ~= nil then
        setRotation(jointDesc.rotationNode2, unpack(jointDesc.maxRot2));
    end;
    jointDesc.jointIndex = constr:finalize();
    jointDesc.moveDown = false;
    table.insert(self.attachedImplements, implement);

    if self.selectedImplement == 0 then
        self.selectedImplement = 1;
        implement.object:onSelect();
    end;

end;

function Vehicle:detachImplement(index)

    local implement = self.attachedImplements[index];
    local jointDesc = self.attacherJoints[implement.jointDescIndex];

    removeJoint(jointDesc.jointIndex);
    jointDesc.jointIndex = 0;

    if index == self.selectedImplement then
        self.attachedImplements[index].object:onDeselect();
    end;
    implement.object:onDetach();
    implement.object = nil;
    if jointDesc.topArm ~= nil then
        setRotation(jointDesc.topArm.rotationNode, jointDesc.topArm.rotX, jointDesc.topArm.rotY, jointDesc.topArm.rotZ);
        if jointDesc.topArm.translationNode ~= nil then
            setTranslation(jointDesc.topArm.translationNode, 0, 0, 0);
        end;
    end;
    if jointDesc.bottomArm ~= nil then
        setRotation(jointDesc.bottomArm.rotationNode, jointDesc.bottomArm.rotX, jointDesc.bottomArm.rotY, jointDesc.bottomArm.rotZ);
        if jointDesc.bottomArm.translationNode ~= nil then
            setTranslation(jointDesc.bottomArm.translationNode, 0, 0, 0);
        end;
    end;
    if jointDesc.rotationNode ~= nil then
        setRotation(jointDesc.rotationNode, unpack(jointDesc.minRot));
    end;

    table.remove(self.attachedImplements, index);
    self.selectedImplement = math.min(self.selectedImplement, table.getn(self.attachedImplements));
    if self.selectedImplement ~= 0 then
        self.attachedImplements[self.selectedImplement].object:onSelect();
    end;

end;

function Vehicle:detachImplementByObject(object)

    for i=1, table.getn(self.attachedImplements) do
        if self.attachedImplements[i].object == object then
            self:detachImplement(i);
            break;
        end;
    end;

end;

function Vehicle:getImplementByObject(object)
    for i=1, table.getn(self.attachedImplements) do
        if self.attachedImplements[i].object == object then
            return self.attachedImplements[i];
        end;
    end;
    return nil;
end;

function Vehicle:setSelectedImplement(selected)
    if self.selectedImplement ~= 0 then
        self.attachedImplements[self.selectedImplement].object:onDeselect();
    end;
    self.selectedImplement = selected;
    self.attachedImplements[selected].object:onSelect();
end;

function Vehicle:playAttachSound()
    if self.attachSound ~= nil then
        setSamplePitch(self.attachSound, self.attachSoundPitchOffset);
        playSample(self.attachSound, 1, 1, 0);
    end;
end;

function Vehicle:attachTrailer(trailer)
    if self.trailerAttacherJoint ~= nil then
        local constr = JointConstructor:new();
        self.attachedTrailer = trailer;
        self.attachedTrailer:onAttach(self);
        constr:setActors(self.rootNode, self.attachedTrailer.attachRootNode);
        constr:setJointTransforms(self.trailerAttacherJoint, self.attachedTrailer.attacherJoint);
        --constr:setBreakable(40, 40);
        constr:setRotationLimit(0, Utils.degToRad(-10), Utils.degToRad(10));
        constr:setRotationLimit(1, Utils.degToRad(-50), Utils.degToRad(50));
        constr:setRotationLimit(2, Utils.degToRad(-50), Utils.degToRad(50));
        self.trailerAttacherJointIndex = constr:finalize();
    end;
end;

function Vehicle:setFuelFillLevel(newFillLevel)
    self.fuelFillLevel = math.max(math.min(newFillLevel, self.fuelCapacity), 0);
end;

function Vehicle:setSpeedLevel(level)

    if level == 1 then
        --self.maxAcceleration =
    elseif level == 2 then
    elseif level == 3 then
    else
    end;

end;

function Vehicle:handleAttachEvent()

    --if self.attachedTrailer ~= nil and g_currentMission.isTipTriggerInRange then
    --    self.attachedTrailer:toggleTipState();
    if g_currentMission.trailerInTipRange ~= nil then
        g_currentMission.trailerInTipRange:toggleTipState();
    elseif g_currentMission.attachableInMountRange ~= nil and self.attacherJoints[g_currentMission.attachableInMountRangeIndex].jointIndex == 0 then
        self:playAttachSound();
        self:attachImplement(g_currentMission.attachableInMountRange, g_currentMission.attachableInMountRangeIndex);
    elseif self:handleAttachTrailerEvent() then
        self:playAttachSound();
        -- nothing todo
    elseif self.attachedTrailer ~= nil then
        self:handleDetachTrailerEvent()
        self:playAttachSound();
    elseif self.selectedImplement ~= 0 then
        self:playAttachSound();
        self:detachImplement(self.selectedImplement);
    end;
end;

function Vehicle:handleAttachTrailerEvent()
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

function Vehicle:handleDetachTrailerEvent()

    if not self.attachedTrailer:handleDetachTrailerEvent() then
        if self.trailerAttacherJointIndex ~= 0 then
            removeJoint(self.trailerAttacherJointIndex);
            self.trailerAttacherJointIndex = 0;
            self.attachedTrailer:onDetach();
            self.attachedTrailer = nil;
        end;
    end;
end;

function Vehicle:handleLowerImplementEvent()
    if self.selectedImplement ~= 0 then
        local implement = self.attachedImplements[self.selectedImplement];
        local jointDesc = self.attacherJoints[implement.jointDescIndex];
        jointDesc.moveDown = not jointDesc.moveDown;
    end;
end;