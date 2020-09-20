--
-- VehicleMotor
--
-- @author  Stefan Geiger (mailto:sgeiger@giants.ch)
-- @date  08/03/08

VehicleMotor = {};

VehicleMotor_mt = Class(VehicleMotor);

function VehicleMotor:new(minRpm, maxRpm, torqueCurve, brakeForce, forwardGearRatio, backwardGearRatio, differentialRatio, rpmFadeOutRange)

    local instance = {};
    setmetatable(instance, VehicleMotor_mt);

    instance.minRpm = minRpm;
    instance.maxRpm = maxRpm;
    instance.torqueCurve = torqueCurve;
    instance.brakeForce = brakeForce

    instance.forwardGearRatio = forwardGearRatio;
    instance.backwardGearRatio = backwardGearRatio;

    instance.differentialRatio = differentialRatio;
    instance.transmissionEfficiency = 1;

    instance.lastMotorRpm = 0;

    instance.rpmFadeOutRange = rpmFadeOutRange;
    instance.speedLevel = 0;

    -- this is not clamped by minRpm
    instance.nonClampedMotorRpm = 0;

    return instance;
end;

function VehicleMotor:getTorque()
    local torque = self.torqueCurve:get(self.lastMotorRpm);

    local maxRpm = self:getMaxRpm();
    if self.nonClampedMotorRpm > maxRpm - self.rpmFadeOutRange then
        torque = math.max(torque - (self.nonClampedMotorRpm-(maxRpm - self.rpmFadeOutRange)) * torque/self.rpmFadeOutRange, 0);
    end;
    return torque;
end;

function VehicleMotor:computeMotorRpm(wheelRpm, acceleration)
    local temp = self:getGearRatio(acceleration) * self.differentialRatio;
    self.nonClampedMotorRpm = wheelRpm * temp;
    self.lastMotorRpm = math.max(self.nonClampedMotorRpm, self.minRpm);
end;

function VehicleMotor:getGearRatio(acceleration)
    if acceleration >= 0 then
        return self.forwardGearRatio;
    else
        return self.backwardGearRatio;
    end;
end;

function VehicleMotor:getMaxRpm()
    if self.speedLevel ~= 0 then
        return self.maxRpm[self.speedLevel];
    else
        return self.maxRpm[3];
    end;
end;

function VehicleMotor:setSpeedLevel(level, force)

    if level ~= 0 and self.speedLevel == level and not force then
        self.speedLevel = 0;
    else
        self.speedLevel = level;
    end;
end;