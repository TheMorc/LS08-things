Mission00 = {}

local Mission00_mt = Class(Mission00, BaseMission);


function Mission00:new()
    local instance = Mission00:superClass():new(Mission00_mt);

    instance.playerStartX = 175;
    instance.playerStartY = 0.5;
    instance.playerStartZ = 180;
    instance.playerRotX = 0;
    instance.playerRotY = Utils.degToRad(0);

    instance.renderTime = true;

    instance.isFreePlayMission = true;

    instance.fill = 0;
    instance.siloTrailerId = 0;

    return instance;
end;

function Mission00:delete()

    removeTrigger(getChild(self.siloTriggerMap, "farm_silo01_trigger1"));
    removeTrigger(getChild(self.siloTriggerMap, "farm_silo01_trigger2"));
    removeTrigger(getChild(self.siloTriggerMap, "farm_silo01_trigger3"));
    removeTrigger(getChild(self.siloTriggerMap, "farm_silo01_trigger4"));

    Mission00:superClass().delete(self);


end;

function Mission00:load()

    --self.environment = Environment:new("data/sky/sky_overcast.i3d", false, 8);
    --self.environment = Environment:new("data/sky/sky_day.i3d", false, 8);
    self.environment = Environment:new("data/sky/sky_day_night.i3d", true, 8, true, true);
    self.showWeatherForecast = true;

    self:loadMap("map01.i3d");

    self.siloTriggerMap = self:loadMissionMap("farm_silo01_trigger.i3d");

    local triggerId1 = getChild(self.siloTriggerMap, "farm_silo01_trigger1");
    addTrigger(triggerId1, "siloTrigger", self);
    local triggerId2 = getChild(self.siloTriggerMap, "farm_silo01_trigger2");
    addTrigger(triggerId2, "siloTrigger", self);
    local triggerId3 = getChild(self.siloTriggerMap, "farm_silo01_trigger3");
    addTrigger(triggerId3, "siloTrigger", self);
    local triggerId4 = getChild(self.siloTriggerMap, "farm_silo01_trigger4");
    addTrigger(triggerId4, "siloTrigger", self);

    self.siloParticleSystemRoot = loadI3DFile("data/vehicles/particleSystems/wheatParticleSystemLong.i3d");
    setTranslation(self.siloParticleSystemRoot, 223.04, 92.3, 224.61);
    link(self.siloTriggerMap, self.siloParticleSystemRoot);

    for i=0, getNumOfChildren(self.siloParticleSystemRoot)-1 do
        local child = getChildAt(self.siloParticleSystemRoot, i);
        if getClassName(child) == "Shape" then
            local geometry = getGeometry(child);
            if geometry ~= 0 then
                if getClassName(geometry) == "ParticleSystem" then
                    self.siloParticleSystem = geometry;
                end;
            end;
        end;
    end;

    if self.siloParticleSystem ~= nil then
        setEmittingState(self.siloParticleSystem, false);
    end;

    local xmlFile = loadXMLFile("TempConfig", g_missionLoaderDesc.vehiclesXML);
    print("[LS2008MP] originalMission00 loading from " .. g_missionLoaderDesc.vehiclesXML)

    local vehicleI = 0;
    while true do
        local key = string.format("careerVehicles.vehicle(%d)", vehicleI);
        local filename = getXMLString(xmlFile, key.."#filename");
        local xPosition = getXMLFloat(xmlFile, key.."#xPosition");
        local yOffset = getXMLFloat(xmlFile, key.."#yOffset");
        local zPosition = getXMLFloat(xmlFile, key.."#zPosition");
        local yRotation = getXMLFloat(xmlFile, key.."#yRotation");
        local isAbsolute = Utils.getNoNil(getXMLBool(xmlFile, key.."#absolute"), false);
        local xRotation = getXMLFloat(xmlFile, key.."#xRotation");
        local zRotation = getXMLFloat(xmlFile, key.."#zRotation");
        local yPosition = getXMLFloat(xmlFile, key.."#yPosition");
        
        local fillLevel = getXMLFloat(xmlFile, key.."#fillLevel");
        local fillType = getXMLInt(xmlFile, key.."#fillType");
        
        if filename == nil or xPosition == nil or zPosition == nil or zPosition == nil or yRotation == nil then
            break;
        end;
        if isAbsolute then
            if xRotation == nil or zRotation == nil or yPosition == nil then
                break;
            end;
        else
            if yOffset== nil then
                break;
            end;
        end;
        local vehicle = nil;
        if isAbsolute then
            vehicle = self:loadVehicle(filename, 0, 0, 0, 0);
            if vehicle ~= nil then
                vehicle:setWorldPosition(xPosition, yPosition, zPosition, xRotation,yRotation, zRotation);
            end;
        else
            vehicle = self:loadVehicle(filename, xPosition, yOffset, zPosition, Utils.degToRad(yRotation));
        end;
        if vehicle ~= nil and vehicle.setFillLevel ~= nil and fillLevel ~= nil and fillType ~= nil then
            vehicle:setFillLevel(fillLevel, fillType);
        end;
        vehicleI = vehicleI +1;
    end;

    delete(xmlFile);

    self.environment.dayTime = g_missionLoaderDesc.stats.dayTime*1000*60;
    if g_missionLoaderDesc.stats.nextRainValid then
        self.environment.timeUntilNextRain = g_missionLoaderDesc.stats.timeUntilNextRain;
        self.environment.rainTime = g_missionLoaderDesc.stats.rainTime;
        self.environment.nextRainDuration = g_missionLoaderDesc.stats.nextRainDuration;
        self.environment.nextRainType = g_missionLoaderDesc.stats.nextRainType;
    end;

    Mission00:superClass().load(self);

end

function Mission00:mouseEvent(posX, posY, isDown, isUp, button)

    Mission00:superClass().mouseEvent(self, posX, posY, isDown, isUp, button);

end;

function Mission00:keyEvent(unicode, sym, modifier, isDown)

    Mission00:superClass().keyEvent(self, unicode, sym, modifier, isDown);

end;

function Mission00:draw()
    Mission00:superClass().draw(self);
end;

function Mission00:siloTrigger(triggerId, otherId, onEnter, onLeave, onStay)

    if onEnter then
        self.fill = self.fill+1;
        self.siloTrailerId = otherId;
        self.fillDone = false;
    elseif onLeave then
        self.fill = self.fill-1;
        self.siloTrailerId = 0;
        self.fillDone = false;
    end;
end;