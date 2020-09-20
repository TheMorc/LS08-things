Environment = {}

local Environment_mt = Class(Environment);

function Environment:onCreateSunLight(id)
    g_currentMission.environment.sunLightId = id;
end;

function Environment:onCreateUnderwaterFog(id)
    g_currentMission.environment.underwaterFog = id;
end;

function Environment:onCreateWater(id)
    g_currentMission.environment.water = id;

    local env = g_currentMission.environment;
    -- set default values
    setShaderParameter(id, "distanceFogInfo", env.waterFogColorR, env.waterFogColorG, env.waterFogColorB, 0.0005);
end;

function Environment:new(skyI3DFilename, dayNightCycle, startHour, allowRain, autoRain)
    local instance = {};
    setmetatable(instance, Environment_mt);

    instance.skyRootId = loadI3DFile(skyI3DFilename);
    link(getRootNode(), instance.skyRootId);
    instance.skyId = getChildAt(instance.skyRootId, 0);

    instance.sunLightId = nil;

    instance.frameCount = 0;

    instance.dayTime = 0;
    if startHour ~= nil then
        instance.dayTime = startHour*60*60*1000;
    end;

    instance.waterFogColorR = 237/255;
    instance.waterFogColorG = 247/255;
    instance.waterFogColorB = 255/255;

    instance.dayNightCycle = dayNightCycle;

    instance.timeScale = 60;

    if dayNightCycle then

        instance.ambientCurve = AnimCurve:new(linearInterpolator3);
        instance.ambientCurve:addKeyframe({x=0.075, y=0.075, z=0.125, time = 0*60});
        instance.ambientCurve:addKeyframe({x=0.075, y=0.075, z=0.125, time = 5*60});
        instance.ambientCurve:addKeyframe({x=0.125, y=0.125, z=0.175, time = 6*60});
        instance.ambientCurve:addKeyframe({x=0.225, y=0.225, z=0.225, time = 12*60});
        instance.ambientCurve:addKeyframe({x=0.225, y=0.225, z=0.225, time = 18*60});
        instance.ambientCurve:addKeyframe({x=0.125, y=0.125, z=0.175, time = 21*60});
        instance.ambientCurve:addKeyframe({x=0.075, y=0.075, z=0.125, time = 24*60});

        instance.diffuseCurve = AnimCurve:new(linearInterpolator3);
        instance.diffuseCurve:addKeyframe({x=0.0,   y=0,    z=0, time = 0*60});
        instance.diffuseCurve:addKeyframe({x=0.0,   y=0,    z=0, time = 5*60});
        instance.diffuseCurve:addKeyframe({x=0.05,  y=0.05, z=0.1, time = 6*60});
        instance.diffuseCurve:addKeyframe({x=1.0,   y=1.0,  z=0.95, time = 12*60});
        instance.diffuseCurve:addKeyframe({x=1.0,   y=1.0,  z=0.95, time = 14*60});
        instance.diffuseCurve:addKeyframe({x=0.05,  y=0.05, z=0.1, time = 19*60});
        instance.diffuseCurve:addKeyframe({x=0.0,   y=0,    z=0, time = 21*60});
        instance.diffuseCurve:addKeyframe({x=0,     y=0,    z=0, time = 24*60});

        instance.rotCurve = AnimCurve:new(linearInterpolator1);
        instance.rotCurve:addKeyframe({v=Utils.degToRad(-90), time = 0*60});
        instance.rotCurve:addKeyframe({v=Utils.degToRad(-75), time = 5*60+30});
        instance.rotCurve:addKeyframe({v=Utils.degToRad(-138), time = 12*60});
        instance.rotCurve:addKeyframe({v=Utils.degToRad(-75), time = 20*60+30});
        instance.rotCurve:addKeyframe({v=Utils.degToRad(-90), time = 24*60});

        instance.skyCurve = AnimCurve:new(linearInterpolator4);
        instance.skyCurve:addKeyframe({x=0.0, y=0.0, z=1.0, w=0.0, time = 0*60});
        instance.skyCurve:addKeyframe({x=0.0, y=0.0, z=1.0, w=0.0, time = 5*60});
        instance.skyCurve:addKeyframe({x=0.0, y=0.0, z=0.0, w=1.0, time = 6*60});
        instance.skyCurve:addKeyframe({x=0.0, y=0.0, z=0.0, w=1.0, time = 7*60});
        instance.skyCurve:addKeyframe({x=1.0, y=0.0, z=0.0, w=0.0, time = 8*60});
        instance.skyCurve:addKeyframe({x=1.0, y=0.0, z=0.0, w=0.0, time = 17*60});
        instance.skyCurve:addKeyframe({x=0.0, y=1.0, z=0.0, w=0.0, time = 19*60});
        instance.skyCurve:addKeyframe({x=0.0, y=1.0, z=0.0, w=0.0, time = 20*60});
        instance.skyCurve:addKeyframe({x=0.0, y=0.0, z=1.0, w=0.0, time = 22*60});
        instance.skyCurve:addKeyframe({x=0.0, y=0.0, z=1.0, w=0.0, time = 24*60});

        instance.skyDayTimeStart = 6*60;
        instance.skyDayTimeEnd = 19*60;

        instance.volumeFogCurve = AnimCurve:new(linearInterpolator3);
        instance.volumeFogCurve:addKeyframe({x=0.184314*0.1, y=0.258824*0.1, z=0.337255*0.1, time = 0*60});
        instance.volumeFogCurve:addKeyframe({x=0.184314*0.1, y=0.258824*0.1, z=0.337255*0.1, time = 5*60});
        instance.volumeFogCurve:addKeyframe({x=0.184314*0.7, y=0.258824*0.7, z=0.337255*0.7, time = 6*60});
        instance.volumeFogCurve:addKeyframe({x=0.184314*0.7, y=0.258824*0.7, z=0.337255*0.7, time = 7*60});
        instance.volumeFogCurve:addKeyframe({x=0.184314, y=0.258824, z=0.337255, time = 8*60});
        instance.volumeFogCurve:addKeyframe({x=0.184314, y=0.258824, z=0.337255, time = 17*60});
        instance.volumeFogCurve:addKeyframe({x=0.184314*0.7, y=0.258824*0.7, z=0.337255*0.8, time = 19*60});
        instance.volumeFogCurve:addKeyframe({x=0.184314*0.7, y=0.258824*0.7, z=0.337255*0.8, time = 20*60});
        instance.volumeFogCurve:addKeyframe({x=0.184314*0.1, y=0.258824*0.1, z=0.337255*0.1, time = 22*60});
        instance.volumeFogCurve:addKeyframe({x=0.184314*0.1, y=0.258824*0.1, z=0.337255*0.1, time = 24*60});

        instance.distanceFogCurve = AnimCurve:new(linearInterpolator3);
        instance.distanceFogCurve:addKeyframe({x=26/255, y=25/255, z=29/255, time = 0*60});
        instance.distanceFogCurve:addKeyframe({x=26/255, y=25/255, z=29/255, time = 5*60});
        instance.distanceFogCurve:addKeyframe({x=143/255, y=121/255, z=108/255, time = 6*60});
        instance.distanceFogCurve:addKeyframe({x=143/255, y=121/255, z=108/255, time = 7*60});
        instance.distanceFogCurve:addKeyframe({x=237/255, y=247/255, z=255/255, time = 8*60});
        instance.distanceFogCurve:addKeyframe({x=237/255, y=247/255, z=255/255, time = 17*60});
        instance.distanceFogCurve:addKeyframe({x=91/255, y=66/255, z=82/255, time = 19*60});
        instance.distanceFogCurve:addKeyframe({x=91/255, y=66/255, z=82/255, time = 20*60});
        instance.distanceFogCurve:addKeyframe({x=26/255, y=25/255, z=29/255, time = 22*60});
        instance.distanceFogCurve:addKeyframe({x=26/255, y=25/255, z=29/255, time = 24*60});

    else
        setVolumeFog("exp", 0.5, 0, 82.113, 0.184314, 0.258824, 0.337255);
    end;

    instance.allowRain = allowRain ~= nil and allowRain == true;
    instance.autoRain = instance.allowRain and autoRain ~= nil and autoRain;
    instance.rainTypes = {};
    instance.timeSinceLastRain = 9999999;
    instance.lastRainScale = 0;
    if instance.allowRain then
        instance:loadRainType("data/sky/rain.i3d", "data/maps/sounds/rain.wav");
        instance:loadRainType("data/sky/hail.i3d", "data/maps/sounds/hail.wav");
        _=[[local rainType = {};
        rainType.rainId = loadI3DFile("data/sky/rain.i3d");
        link(getRootNode(), instance.rainId);
        setCullOverride(instance.rainId, true);
        instance.rainGeometries = {};
        for i=1, getNumOfChildren(instance.rainId) do
            local child = getChildAt(instance.rainId, i-1);
            if getClassName(child) == "Shape" then
                local geometry = getGeometry(child);
                if geometry ~= 0 and getClassName(geometry) == "Precipitation" then
                    table.insert(instance.rainGeometries, geometry);
                end;
            end;
        end;
        setVisibility(instance.rainId, false);

        instance.hailId = loadI3DFile("data/sky/hail.i3d");
        link(getRootNode(), instance.hailId);
        setCullOverride(instance.hailId, true);
        instance.hailGeometries = {};
        for i=1, getNumOfChildren(instance.hailId) do
            local child = getChildAt(instance.hailId, i-1);
            if getClassName(child) == "Shape" then
                local geometry = getGeometry(child);
                if geometry ~= 0 and getClassName(geometry) == "Precipitation" then
                    table.insert(instance.hailGeometries, geometry);
                end;
            end;
        end;
        setVisibility(instance.hailId, false);]]

        instance.minRainInterval = 0.5*24*60;
        instance.maxRainInterval = 2*24*60;
        instance.minRainDuration = 2*60;
        instance.maxRainDuration = 5*60;
        instance.rainTime = 0;
        instance.nextRainType = 0;

        if instance.autoRain then
            instance:setNextRain();
        else
            instance.rainTime = 2*instance.maxRainDuration;
            instance.timeUntilNextRain = 0;
            instance.nextRainDuration = 0;
        end;

        instance.rainFadeCurve = AnimCurve:new(linearInterpolator3);
        instance.rainFadeCurve:addKeyframe({x=1.0,  y=0,   z=0,   time = 0});
        instance.rainFadeCurve:addKeyframe({x=0.6,  y=0.5, z=0,   time = 10});
        instance.rainFadeCurve:addKeyframe({x=0.55, y=1,   z=0,   time = 20});
        instance.rainFadeCurve:addKeyframe({x=0.55, y=1,   z=0.5, time = 25});
        instance.rainFadeCurve:addKeyframe({x=0.55, y=1,   z=1.0, time = 30});
        instance.rainFadeDuration = 30;
    end;

	instance.isSunOn = true;
	
    return instance;
end;

function Environment:destroy()

    delete(self.skyRootId);
    _=[[if self.rainId ~= nil then
        delete(self.rainId);
    end;
    if self.rainSample ~= nil then
        delete(self.rainSample);
    end;
    if self.hailSample ~= nil then
        delete(self.hailSample);
    end;]]
    for i=1, table.getn(self.rainTypes) do
        if self.rainTypes[i].sample ~= nil then
            delete(self.rainTypes[i].sample);
        end;
        if self.rainTypes[i].rootNode ~= nil then
            delete(self.rainTypes[i].rootNode);
        end;
    end;

    setVolumeFog("none", 0, 0, 0, 0, 0, 0);
end;

function Environment:update(dt)

    local dtMinutes = dt/(1000*60)*self.timeScale;
    local sunThreshold = 0.04;
    self.dayTime = self.dayTime + dt*self.timeScale;

    if self.dayTime > 1000*60*60*24 then
        self.dayTime = 0;
    end;

    local lightScale=1;
    local rainSkyScale=0;
    local rainScale = 0;
    local rainParamsChanged = false;
    if self.allowRain then
        self.timeSinceLastRain = self.timeSinceLastRain + dtMinutes;
        self.timeUntilNextRain = self.timeUntilNextRain - dtMinutes;

        if self.timeUntilNextRain <= 0 then

            self.rainTime = self.rainTime + dtMinutes;

            if self.rainTime <= self.nextRainDuration then
                if self.rainTime > self.nextRainDuration-self.rainFadeDuration then
                    lightScale, rainSkyScale, rainScale = self.rainFadeCurve:get(self.nextRainDuration-self.rainTime);
                else
                    lightScale, rainSkyScale, rainScale = self.rainFadeCurve:get(self.rainTime);
                end;
                rainParamsChanged = true;
            end;
        end;

        if rainScale > 0 then
            self.timeSinceLastRain = 0;
            local rainType = self:getRainType();
            setVisibility(rainType.rootNode, true);
            for i=1, table.getn(rainType.geometries) do
                setDropCountScale(rainType.geometries[i], rainScale);
            end;

            if rainType.sample == nil then
                rainType.sample = createSample("rainSample");
                loadSample(rainType.sample, rainType.sampleFilename, false);
            end;
            if not rainType.sampleRunning then
                playSample(rainType.sample, 0, rainScale, 0);
                rainType.sampleRunning = true;
            end;
            setSampleVolume(rainType.sample, math.min(1, rainScale));
        else
            self:disableRainEffect();
        end;

        if self.rainTime > self.nextRainDuration and self.autoRain then
            self:setNextRain();
        end;
    end;
    self.lastRainScale = rainScale;

    if self.dayNightCycle then

        local dayMinutes = self.dayTime/(1000*60);

        local x,y,z,w = self.skyCurve:get(dayMinutes);
        if self.allowRain then
            x = x * (1-rainSkyScale);
            y = y * (1-rainSkyScale);
            z = z * (1-rainSkyScale);
            w = w * (1-rainSkyScale);
        end;
        setShaderParameter(self.skyId, "partScale", x, y, z, w);

        if self.sunLightId ~= nil then

            local rx = self.rotCurve:get(dayMinutes);
            setRotation(self.sunLightId, rx, Utils.degToRad(-63), Utils.degToRad(25));

            local dr,dg,db = self.diffuseCurve:get(dayMinutes);
            dr = dr*lightScale;
            dg = dg*lightScale;
            db = db*lightScale;
            if dr < sunThreshold and dg < sunThreshold and db < sunThreshold then
                self.isSunOn = false;
				setVisibility(self.sunLightId, false);
            else
                setLightDiffuseColor(self.sunLightId, dr, dg, db);
                setLightSpecularColor(self.sunLightId, dr, dg, db);
                self.isSunOn = true;
				setVisibility(self.sunLightId, true);
            end;

            local ar,ag,ab = self.ambientCurve:get(dayMinutes);
            ar = ar*lightScale;
            ag = ag*lightScale;
            ab = ab*lightScale;
            setAmbientColor(ar, ag, ab);
        end;

        --setFog("linear", 400, 490, 1, 1, 1);
        --setFog("linear", 400, 1500, 138/255.0, 153/255.0, 184/255.0);
        --setFog("exp2", 0.0007, 1, 220/255.0, 240/255.0, 240/255.0);
        local vr, vg, vb = self.volumeFogCurve:get(dayMinutes);
        setVolumeFog("exp", 0.5, 0, 82.113, vr, vg, vb);
        if self.underwaterFog ~= nil then
            setShaderParameter(self.underwaterFog, "underwaterColor", vr, vg, vb, 0);
        end;

        if self.water ~= nil then
            local fr, fg, fb = self.distanceFogCurve:get(dayMinutes);
            setShaderParameter(self.water, "distanceFogInfo", fr, fg, fb, 0.0005);
        end;
        --setVolumeFog("exp", 0.5, 0, 82.113, 0.184314, 0.258824, 0.337255);

        if self.allowRain and rainParamsChanged then
            setShaderParameter(self.skyId, "rainScale", rainSkyScale, 0, 0, 0);
        end

    end;


end;

function Environment:setWaterFogColor(r,g,b)
    self.waterFogColorR = r;
    self.waterFogColorG = g;
    self.waterFogColorB = b;
end;

function Environment:setNextRain()

    self:disableRainEffect();
    self.rainTime = 0;
    self.nextRainType = 0;
    if math.random() > 0.7 then
        self.nextRainType = 1;
    end;
    self.timeUntilNextRain = math.random(self.minRainInterval, self.maxRainInterval);
    self.nextRainDuration = math.random(self.minRainDuration, self.maxRainDuration);
    --self.nextRainDuration = 110;
    --self.timeUntilNextRain = 4;
    if self.dayNightCycle then
        self.timeUntilNextRain = self:getNextDayStartTime(self.timeUntilNextRain) + math.random(0, self.skyDayTimeEnd-self.skyDayTimeStart-self.nextRainDuration);
    end;

end;

function Environment:getNextDayStartTime(time)

    if self.dayNightCycle then
        local dayTimeMinutes = self.dayTime/(1000*60)
        local absolutTime = time+dayTimeMinutes;
        local days, minutesOfDay = math.modf(absolutTime/(24*60));
        if minutesOfDay < self.skyDayTimeStart then
            return days*24*60 - dayTimeMinutes + self.skyDayTimeStart;
        else
            return (days+1)*24*60 - dayTimeMinutes + self.skyDayTimeStart;
        end;
    else
        return time;
    end;

end;

function Environment:startRain(duration, rainType, timeUntilStart)
    self:disableRainEffect();
    if timeUntilStart ~= nil then
        self.timeUntilNextRain = timeUntilStart;
    else
        self.timeUntilNextRain = 0;
    end;
    self.rainTime = 0;
    self.nextRainDuration = duration;
    self.nextRainType = 0;
    if rainType ~= nil and rainType == 1 then
        self.nextRainType = 1;
    end
end;

function Environment:disableRainEffect()

    local rainType = self:getRainType();

    setVisibility(rainType.rootNode, false);
    if rainType.sampleRunning then
        stopSample(rainType.sample);
        rainType.sampleRunning = false;
    end;
end;

function Environment:loadRainType(i3d, sampleFilename)

    local rainType = {};
    rainType.rootNode = loadI3DFile(i3d);
    link(getRootNode(), rainType.rootNode);
    setCullOverride(rainType.rootNode, true);
    setVisibility(rainType.rootNode, false);

    rainType.geometries = {};
    for i=1, getNumOfChildren(rainType.rootNode) do
        local child = getChildAt(rainType.rootNode, i-1);
        if getClassName(child) == "Shape" then
            local geometry = getGeometry(child);
            if geometry ~= 0 and getClassName(geometry) == "Precipitation" then
                table.insert(rainType.geometries, geometry);
            end;
        end;
    end;

    rainType.sampleFilename = sampleFilename;
    rainType.sample = nil;
    rainType.sampleRunning = false;

    table.insert(self.rainTypes, rainType);

end;

function Environment:getRainType()

    if self.nextRainType == 1 then
        return self.rainTypes[2];
    else
        return self.rainTypes[1];
    end;
end;
