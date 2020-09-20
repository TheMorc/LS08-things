TipTrigger = {};

local TipTrigger_mt = Class(TipTrigger);

function TipTrigger:onCreate(id)
    table.insert(g_currentMission.tipTriggers, TipTrigger:new(id));
    --print("created tip trigger, id: ", id);
end;

function TipTrigger:new(id, customMt)

    local instance = {};
    if customMt ~= nil then
        setmetatable(instance, customMt);
    else
        setmetatable(instance, TipTrigger_mt);
    end;

    instance.triggerId = id;
    addTrigger(id, "triggerCallback", instance);
    instance.deleteListenerId = addDeleteListener(id, "delete", instance);

    instance.isFarmTrigger = Utils.getNoNil(getUserAttribute(id, "isFarmTrigger"), false);

    instance.fillTypes = {};
    instance.fillTypes[Trailer.FILLTYPE_WHEAT] = Utils.getNoNil(getUserAttribute(id, "fillTypeWheat"), true);
    instance.fillTypes[Trailer.FILLTYPE_GRASS] = Utils.getNoNil(getUserAttribute(id, "fillTypeGrass"), false);

    local parent = getParent(id);
    local movingIndex = getUserAttribute(id, "movingIndex");
    if movingIndex ~= nil then
        instance.movingId = Utils.indexToObject(parent, movingIndex);
        if instance.movingId ~= nil then
            instance.moveMinY = Utils.getNoNil(getUserAttribute(id, "moveMinY"), 0);
            instance.moveMaxY = Utils.getNoNil(getUserAttribute(id, "moveMaxY"), 0);
            instance.moveScale = Utils.getNoNil(getUserAttribute(id, "moveScale"), 0.001)*0.01;
            instance.moveBackScale = (instance.moveMaxY-instance.moveMinY)/Utils.getNoNil(getUserAttribute(id, "moveBackTime"), 10000);
        end;
    end;

    instance.isEnabled = true;

    return instance;
end;

-- note: this is called as soon as the trigger entity is deleted
function TipTrigger:delete()

    removeTrigger(self.triggerId);
    removeDeleteListener(self.triggerId, self.deleteListenerId);
end;

function TipTrigger:update(dt)
    if self.movingId ~= nil then
        local x,y,z = getTranslation(self.movingId);
        local newY = math.max(y-dt*self.moveBackScale, self.moveMinY);
        setTranslation(self.movingId, x, newY, z);
    end;
end;

function TipTrigger:updateMoving(delta)
    if self.movingId ~= nil then
        local x,y,z = getTranslation(self.movingId);
        local newY = math.min(y+delta*self.moveScale, self.moveMaxY);
        setTranslation(self.movingId, x, newY, z);
    end;
end;

function TipTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)

    if self.isEnabled then
        if onEnter then
            local trailer = g_currentMission.objectToTrailer[otherId];
            if trailer ~= nil and self.fillTypes[trailer.currentFillType] then
                if g_currentMission.trailerTipTriggers[trailer] == nil then
                    g_currentMission.trailerTipTriggers[trailer] = {};
                end;
                table.insert(g_currentMission.trailerTipTriggers[trailer], self);
            end;
        elseif onLeave then
            local trailer = g_currentMission.objectToTrailer[otherId];
            if trailer ~= nil then
                local triggers = g_currentMission.trailerTipTriggers[trailer];
                if triggers ~= nil then
                    for i=1, table.getn(triggers) do
                        if triggers[i] == trailer then
                            table.remove(triggers, i);
                            break;
                        end;
                    end;
                end;
            end;
        end;
    end;

    _=[[if onEnter and self.isEnabled then
        if g_currentMission.currentVehicle ~= nil then
            if g_currentMission.currentVehicle.attachedTrailer ~= nil and g_currentMission.currentVehicle.attachedTrailer.rootNode == otherId then
                g_currentMission.currentTipTrigger = self;
            end;
        end;
    elseif onLeave then
        if g_currentMission.currentVehicle ~= nil then
            if g_currentMission.currentVehicle.attachedTrailer ~= nil and g_currentMission.currentVehicle.attachedTrailer.rootNode == otherId then
                g_currentMission.currentTipTrigger = nil;
            end;
        end;
    end;]]
end;