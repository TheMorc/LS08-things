RandomSound = {};

RandomSound.STATE_WAITING = 0;
RandomSound.STATE_PLAYING = 1;

local RandomSound_mt = Class(RandomSound);

function RandomSound:onCreate(id)
    table.insert(g_currentMission.sounds, RandomSound:new(id));
end;

function RandomSound:new(id, customMt)

    local instance = {};
    if customMt ~= nil then
        setmetatable(instance, customMt);
    else
        setmetatable(instance, RandomSound_mt);
    end;

    instance.soundId = id;
    instance.deleteListenerId = addDeleteListener(id, "delete", instance);
    instance.randomMin = Utils.getNoNil(getUserAttribute(id, "randomMin"), 1000);
    instance.randomMax = Utils.getNoNil(getUserAttribute(id, "randomMax"), 2000);
    instance.playTime = getSampleDuration(getAudioSourceSample(id));

    --print(instance.playTime, " ", getName(self.soundId));

    setVisibility(id, false);
    instance.playState = RandomSound.STATE_WAITING;
    instance.timerId = addTimer(instance:getRandomTime(), "timerCallback", instance);

    return instance;
end;

-- note: this is called as soon as the trigger entity is deleted
function RandomSound:delete()

    removeDeleteListener(self.soundId, self.deleteListenerId);
    removeTimer(self.timerId);
end;

function RandomSound:timerCallback()
    if self.playState == RandomSound.STATE_WAITING then

        --if self.soundId == 1323 then
        --    print("play id:", self.soundId, " min:", self.randomMin, " max:", self.randomMax, " time:", self.playTime);
        --    print("     timerId:", self.timerId);
        --end;

        --print("dayTime ", g_currentMission.environment.dayTime/1000, " S ", 5*60*60, " E ", 22*60*60);

        if g_currentMission == nil or (g_currentMission.environment.dayTime > 5*60*60*1000 and g_currentMission.environment.dayTime < 22*60*60*1000) then
            --print("true");
            setVisibility(self.soundId, true);
            setTimerTime(self.timerId, self.playTime);
        else
            --print("false");
            setVisibility(self.soundId, false);
            setTimerTime(self.timerId, 10*1000);
        end;

        self.playState = RandomSound.STATE_PLAYING;

    else
        setVisibility(self.soundId, false);
        local randomDelay = self:getRandomTime();
        setTimerTime(self.timerId, randomDelay);
        self.playState = RandomSound.STATE_WAITING;

        --if self.soundId == 1323 then
        --    print("wait id:", self.soundId, " randomDelay:", randomDelay);
        --    print("     timerId:", self.timerId);
        --end;
    end;
    
    --print("");
    
    return true;
end;

function RandomSound:getRandomTime()
    return math.random(self.randomMin, self.randomMax);
end;