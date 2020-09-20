RaceMission = {};

local RaceMission_mt = Class(RaceMission, BaseMission);



function RaceMission:new(customMt)

    local instance = RaceMission:superClass():new(customMt);

    instance.missionTriggers = {};

    instance.triggerPassed = {};
    instance.triggerNames = {};
    instance.timeAttack = true;
    instance.doContactReport = false;
    instance.contactReportIds = {};
    instance.contactMap = {};
    instance.contacts = 0;
    instance.contactForceThreshold = 30;
    instance.hitSound = nil;
   
    return instance;
end;

function RaceMission:delete()

    if self.doContactReport then
        local contactTransformGroupId = getChild(self.missionMap, self.contactTransformGroupName);
        local numChildren = getNumOfChildren(contactTransformGroupId);
        for i=0, numChildren-1 do
            local id = getChildAt(contactTransformGroupId, i);
            removeContactReport(id);
        end;
    end;
    
    for index=1, self.numTriggers do
        local triggerId = getChild(self.missionMap, self.triggerPrefix .. "0" .. index);
        if triggerId ~= nil then
            removeTrigger(triggerId);
        end;        
    end;


    RaceMission:superClass().delete(self);

end;

function RaceMission:pathTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
    if onEnter then
        --print("trigger:", triggerId);
        self.triggerPassed[triggerId] = self.triggerPassed[triggerId] + 1;
    end;
end;

function RaceMission:createTrigger(parent, index)
    local name = self.triggerPrefix .. "0" .. index;
    local triggerId = getChild(parent, name);
    if triggerId ~= nil then
        addTrigger(triggerId, "pathTriggerCallback", self);
    
        self.triggerPassed[triggerId] = 0;
        self.triggerNames[triggerId] = name;
	
	    --print("createTrigger: ", name, " ", triggerId);
	    table.insert(self.missionTriggers, triggerId);
	else
	    --print("createTrigger failed: ", name);
	end;
end;

-- Contact callback function
function RaceMission:contactReportCallback(objectId, otherObjectId, isStart, normalForce, tangentialForce)

    if normalForce > self.contactForceThreshold then
    
        for i=1, table.getn(self.contactReportIds) do
            if otherObjectId == self.contactReportIds[i] then
                if self.contactMap[objectId] == nil then
                    self.contacts = self.contacts + 1;
                    self.contactMap[objectId] = 1;
                    
                    if self.hitSound ~= nil then
                        playSample(self.hitSound, 1, 1, 0);
                    end;                    
                    
                end;
                break;
            end;
        end;
        
    end;    
end;

function RaceMission:load()

    RaceMission:superClass().load(self);

    for i=1, self.numTriggers do
        self:createTrigger(self.missionMap, i);
    end;
    

    if self.doContactReport then
        local contactTransformGroupId = getChild(self.missionMap, self.contactTransformGroupName);
        local numChildren = getNumOfChildren(contactTransformGroupId);
        for i=0, numChildren-1 do
            local id = getChildAt(contactTransformGroupId, i);
            addContactReport(id, "contactReportCallback", self);
        end;
        
        self.showHudMissionBase = true;        
    end;

    
    self.finishEndTriggerIndex = self.numTriggers;
    self.state = RaceMission.STATE_INTRO;
end

function RaceMission:mouseEvent(posX, posY, isDown, isUp, button)

    RaceMission:superClass().mouseEvent(self, posX, posY, isDown, isUp, button);

end;

function RaceMission:keyEvent(unicode, sym, modifier, isDown)

    if sym ==Input.KEY_9 and isDown then
        self.state = RaceMission.STATE_FINISHED;
        self.endTime = 999;
        RaceMission:superClass().finishMission(self, 999);
    end;


	local controlPlayer = not self.controlPlayer;

    RaceMission:superClass().keyEvent(self, unicode, sym, modifier, isDown);

	if self.state == BaseMission.STATE_INTRO and controlPlayer and not self.controlPlayer then
		self.state = BaseMission.STATE_RUNNING;
	end;
	
end;

function RaceMission:update(dt)

    RaceMission:superClass().update(self, dt);

    if self.isRunning then

        if self.state == BaseMission.STATE_RUNNING then
        
            self.missionTime = self.missionTime + dt;
        
            if self.sunk or self.missionTime > self.minTime or (self.doContactReport and self.contacts >= self.maxContacts) then
                self.state = BaseMission.STATE_FAILED;
                self.endTime = self.missionTime;
                self.endTimeStamp = self.time+self.endDelayTime;
            else
        
                local count = 0;
                for i=1, table.getn(self.missionTriggers) do
                    if self.triggerPassed[self.missionTriggers[i]] >= self.triggerShapeCount then
                        count = count + 1;
                    end;
                end;
           
                -- Clear finish trigger because its the start and end trigger
                if count == 2 then
                    self.triggerPassed[self.missionTriggers[self.finishEndTriggerIndex]] = 0;
                end;
        
                if count == table.getn(self.missionTriggers) then
                    self.state = BaseMission.STATE_FINISHED;
                    self.endTime = self.missionTime;
                    self.endTimeStamp = self.time+self.endDelayTime;
                    RaceMission:superClass().finishMission(self, self.endTime);
                end;
            end;
    
        end;
        
        if (self.state == BaseMission.STATE_FINISHED or self.state == BaseMission.STATE_FAILED) and self.endTimeStamp < self.time then
            OnInGameMenuMenu();
        end;
    end;
end;

function RaceMission:draw()
    RaceMission:superClass().draw(self);
    
    --for i=1, table.getn(self.missionTriggers) do
    --    local triggerId = self.missionTriggers[i];
    --    renderText(0.65, 0.95-i*0.05, 0.03, string.format("%s: %d", self.triggerNames[triggerId], self.triggerPassed[triggerId]));
    --end;

    if self.isRunning then

        if self.timeAttack then
            local time = self.minTime-self.missionTime;
            if time < 10*1000 then
                setTextColor(1.0, 0.0, 0.0, 1.0);
                if time < 0 then
                    time = 0;
                end;
            end;
            RaceMission:superClass().drawTime(self, true, time/(1000*60));
            setTextColor(1.0, 1.0, 1.0, 1.0);
        end;
        if self.doContactReport and self.state ~= RaceMission.STATE_FAILED then
            if self.contacts >= self.maxContacts-1 then
                setTextColor(1.0, 0.0, 0.0, 1.0);
            end;
            
            setTextBold(true);
            --renderText(0.14-0.053, 0.93-0.014, 0.06, string.format("Strohballen %d", self.maxContacts-self.contacts));
            renderText(0.14-0.053, 0.93-0.014, 0.06, g_i18n:getText("mission02Goal") .. string.format(" %d", self.maxContacts-self.contacts));
            setTextBold(false);
            
            setTextColor(1.0, 1.0, 1.0, 1.0);
    
            RaceMission:superClass().drawTime(self, true, self.missionTime/(1000*60));
        end;
        
        if self.state == BaseMission.STATE_FINISHED then
            RaceMission:superClass().drawMissionCompleted(self);
        end;
    
        if self.state == BaseMission.STATE_FAILED then
            RaceMission:superClass().drawMissionFailed(self);
        end;
    end;    
end;

