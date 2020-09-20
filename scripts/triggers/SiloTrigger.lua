SiloTrigger = {};

local SiloTrigger_mt = Class(SiloTrigger);

function SiloTrigger:onCreate(id)
    table.insert(g_currentMission.siloTriggers, SiloTrigger:new(id));
    --print("created tip trigger, id: ", id);
end;

function SiloTrigger:new(id, customMt)

    local instance = {};
    if customMt ~= nil then
        setmetatable(instance, customMt);
    else
        setmetatable(instance, SiloTrigger_mt);
    end;

    instance.deleteListenerId = addDeleteListener(id, "delete", instance);

    instance.triggerIds = {};
    table.insert(instance.triggerIds, id);
    addTrigger(id, "triggerCallback", instance);
    for i=1, 3 do
        local child = getChildAt(id, i-1);
        table.insert(instance.triggerIds, child);
        addTrigger(child, "triggerCallback", instance);
    end;

    instance.fillType = Trailer.FILLTYPE_WHEAT;
    if Utils.getNoNil(getUserAttribute(id, "fillTypeWheat"), true) then
        instance.fillType = Trailer.FILLTYPE_WHEAT;
    elseif Utils.getNoNil(getUserAttribute(id, "fillTypeGrass"), false) then
        instance.fillType = Trailer.FILLTYPE_GRASS;
    end;

    local particlePositionStr = getUserAttribute(id, "particlePosition");
    if particlePositionStr ~= nil then
        local x,y,z = Utils.getVectorFromString(particlePositionStr);
        if x ~= nil and y ~= nil and z ~= nil then
            instance.particlePosition = {x,y,z};
        end;
    end;

    instance.isEnabled = true;

    instance.fill = 0;
    instance.siloTrailerId = 0;
    instance.fillDone = false;

    self.siloParticleSystemRoot = loadI3DFile("data/vehicles/particleSystems/wheatParticleSystemLong.i3d");
    local x,y,z = getTranslation(id);
    if instance.particlePosition ~= nil then
        x = x + instance.particlePosition[1];
        y = y + instance.particlePosition[2];
        z = z + instance.particlePosition[3];
    end;
    setTranslation(self.siloParticleSystemRoot, x,y,z);
    link(getParent(id), self.siloParticleSystemRoot);

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

    return instance;
end;

-- note: this is called as soon as the trigger entity is deleted
function SiloTrigger:delete()

    for i=1, table.getn(self.triggerIds) do
        removeTrigger(self.triggerIds[i]);
    end;
    removeDeleteListener(self.triggerId, self.deleteListenerId);
end;

function SiloTrigger:update(dt)

    if self.fill >= 4 and self.siloTrailer ~= nil and not self.fillDone then
        local trailer = self.siloTrailer;
        local fillLevel = trailer.fillLevel;
        local siloAmount = g_currentMission:getSiloAmount(self.fillType);
        local deltaFillLevel = math.min(dt/2, siloAmount);
        trailer:setFillLevel(fillLevel+deltaFillLevel, self.fillType);
        local newFillLevel = trailer.fillLevel;
        g_currentMission:setSiloAmount(self.fillType, math.max(siloAmount-(newFillLevel-fillLevel), 0));
        if fillLevel == newFillLevel then
            self.fillDone = true;
        end;
    end;

    if self.siloParticleSystem ~= nil then
        setEmittingState(self.siloParticleSystem, self.fill >= 4 and self.siloTrailer ~= nil and not self.fillDone);
    end;

end;

function SiloTrigger:triggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)

    if self.isEnabled then
        local trailer = g_currentMission.objectToTrailer[otherShapeId];
        if trailer ~= nil and trailer:allowFillType(self.fillType) then
            if onEnter then
                self.fill = self.fill+1;
                self.siloTrailer = trailer;
                self.fillDone = false;
            elseif onLeave then
                self.fill = self.fill-1;
                self.siloTrailer = nil;
                self.fillDone = false;
            end;
        end;
    end;
end;
