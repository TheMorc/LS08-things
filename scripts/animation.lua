AnimCurve = {};

function linearInterpolator1(first, second, alpha)
    return (first.v*alpha + second.v*(1-alpha));
end;

function linearInterpolator2(first, second, alpha)
    local oneMinusAlpha = 1-alpha;
    return (first.x*alpha + second.x*oneMinusAlpha), (first.y*alpha + second.y*oneMinusAlpha);
end;

function linearInterpolator3(first, second, alpha)
    local oneMinusAlpha = 1-alpha;
    return (first.x*alpha + second.x*oneMinusAlpha), (first.y*alpha + second.y*oneMinusAlpha), (first.z*alpha + second.z*oneMinusAlpha);
end;

function linearInterpolator4(first, second, alpha)
    local oneMinusAlpha = 1-alpha;
    return (first.x*alpha + second.x*oneMinusAlpha), (first.y*alpha + second.y*oneMinusAlpha), (first.z*alpha + second.z*oneMinusAlpha), (first.w*alpha + second.w*oneMinusAlpha);
end;


local AnimCurve_mt = Class(AnimCurve);

function AnimCurve:new(interpolator)

    local instance = {};
    setmetatable(instance, AnimCurve_mt);
    
    instance.keyframes = {};
    instance.interpolator = interpolator;
    instance.currentTime = 0;
    instance.maxTime = 0;

    return instance;
end;

function AnimCurve:delete()
end;

function AnimCurve:addKeyframe(keyframe)

    local numKeys = table.getn(self.keyframes);
    if numKeys > 0 and keyframe.time < self.keyframes[numKeys].time then
        print("Error: keyframes not strictly monotonic increasing");
        return;
    end;

    table.insert(self.keyframes, keyframe);
    self.maxTime = keyframe.time;
end;

function AnimCurve:get(time)

    local numKeys = table.getn(self.keyframes);
    if numKeys == 0 then
        return;
    end;

    --local time = self.currentTime;
    local first,second=nil,nil;
    if numKeys >= 2 and self.keyframes[1].time <= time then
        if self.maxTime > time then
            for i=2, numKeys do
                second = self.keyframes[i];
                if second.time >= time then
                    first = self.keyframes[i-1];
                    break;
                end;
            end;
        else
            first = self.keyframes[numKeys];
            second = first;
        end;
    else
        first = self.keyframes[1];
        second = first;
    end;
    local time0 = first.time;
    local time1 = second.time;

    --print(time, " ", time0, " ", time1);


    local alpha;
    if time0 < time1 then
        alpha = (time1 - time)/(time1 - time0);
    else
        alpha = time0;
    end;


    return self.interpolator(first, second, alpha);

end;