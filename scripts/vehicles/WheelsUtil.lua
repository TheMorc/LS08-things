--
-- Wheels util
-- Util class to manage wheels of a vehicle
--
-- @author  Stefan Geiger (mailto:sgeiger@giants.ch)
-- @date  11/03/08

WheelsUtil = {};

function WheelsUtil.updateWheels(self, dt, currentSpeed, acceleration, doHandbrake, requiredDriveMode)

    local brakeAcc = false;
    if (self.movingDirection*currentSpeed*acceleration) < -0.001 then
        -- do we want to accelerate in the opposite direction of the vehicle speed?
        brakeAcc = true;
    end;
    local accelerationPedal;
    local brakePedal;
    if math.abs(acceleration) < 0.001 then
        accelerationPedal = 0;
        brakePedal = 1;
    else
        if not brakeAcc then
            accelerationPedal = acceleration;
            brakePedal = 0;
        else
            accelerationPedal = 0;
            brakePedal = math.abs(acceleration);
        end;
    end;

    local numTouching = 0;
    local numNotTouching = 0;
    local numHandbrake = 0;

    local axleSpeedSum = 0;
    self.lastWheelRpm = 0;
    for i=1, self.numWheels do
        local hasGroundContact = WheelsUtil.wheelHasGroundContact(self.wheels[i]);

        if self.wheels[i].driveMode >= requiredDriveMode then
            if doHandbrake and self.wheels[i].hasHandbrake then
                numHandbrake = numHandbrake +1;
            else
                if hasGroundContact then
                    numTouching = numTouching+1;
                else
                    numNotTouching = numNotTouching+1;
                end;
            end;
        end;
    end;

    local motorTorque = 0;
    if numTouching > 0 and math.abs(accelerationPedal) > 0.01 then
        local axisTorque = WheelsUtil.computeAxisTorque(self, accelerationPedal);
        --numTouching*torque + numNotTouching*0.25*torque = axisTorque
        --torque * (numTouching+numNotTouching*0.25) = axisTorque
        --torque = axisTorque / (numTouching+numNotTouching*0.25)
        if axisTorque ~= 0 then
            motorTorque = axisTorque / (numTouching+numNotTouching*0.7);
        else
            brakePedal = 0.5;
        end;
    else
        local rpm = WheelsUtil.computeRpmFromWheels(self);
        self.motor:computeMotorRpm(rpm, accelerationPedal);
    end;

    if self.attachedTrailer ~= nil then
        if (brakePedal > 0 and self.lastSpeed > 0.0002) or doHandbrake then
            self.attachedTrailer:onBrake();
        else
            self.attachedTrailer:onReleaseBrake();
        end;
    end;

    for i=1, self.numWheels do
        WheelsUtil.updateWheel(self, self.wheels[i], doHandbrake, motorTorque, brakePedal, requiredDriveMode, dt)
    end;

end;

function WheelsUtil.wheelHasGroundContact(wheel)

    local x,y,z = getWheelShapeContactPoint(wheel.node, wheel.wheelShape)
    wheel.hasGroundContact = x~=nil;
    return wheel.hasGroundContact;
end;

function WheelsUtil.computeAxisTorque(self, accelerationPedal)

    local rpm = WheelsUtil.computeRpmFromWheels(self);
    self.motor:computeMotorRpm(rpm, accelerationPedal);

    local torque = accelerationPedal * self.motor:getTorque();
    return torque * self.motor:getGearRatio(accelerationPedal) * self.motor.differentialRatio * self.motor.transmissionEfficiency;
end;

function WheelsUtil.computeRpmFromWheels(self)
    local wheelRpm = 0;
    local numWheels = 0;
    for i=1, self.numWheels do
        local axleSpeed = getWheelShapeAxleSpeed(self.wheels[i].node, self.wheels[i].wheelShape)*3.14159/180; -- rad/sec

        self.wheels[i].axleSpeed = axleSpeed;

        if self.wheels[i].hasGroundContact then
            wheelRpm = wheelRpm + axleSpeed/(math.pi*2) * 60;
            numWheels = numWheels+1;
        end;
    end;

    if wheelRpm > 0.01 then
        self.movingDirection = 1;
    elseif wheelRpm < -0.01 then
        self.movingDirection = -1;
    else
        self.movingDirection = 0;
    end;
    if numWheels > 0 then
        return math.abs(wheelRpm)/numWheels;
    end
    return 0;
end;

function WheelsUtil.updateWheel(self, wheel, handbrake, motorTorque, brakePedal, requiredDriveMode, dt)

    local brakeForce = brakePedal*self.motor.brakeForce;
    if handbrake and wheel.hasHandbrake then
        brakeForce = self.motor.brakeForce*10;
    end;

    local actMotorTorque = 0;
    if wheel.driveMode >= requiredDriveMode then
        actMotorTorque = motorTorque;
    end;

    if not wheel.hasGroundContact then
        actMotorTorque = actMotorTorque*0.7;
    end;

    local steeringAngle = 0;
    if wheel.rotSpeed ~= 0 then
        steeringAngle = self.rotatedTime * wheel.rotSpeed;
        if steeringAngle > wheel.rotMax then
            steeringAngle = wheel.rotMax;
        elseif steeringAngle < wheel.rotMin then
            steeringAngle = wheel.rotMin;
        end;
    end;

    setWheelShapeProps(wheel.node, wheel.wheelShape, actMotorTorque, brakeForce, steeringAngle);

    local x,y,z = getRotation(wheel.repr);
    local xDrive,yDrive,zDrive;
    if wheel.repr == wheel.driveNode then
        xDrive,yDrive,zDrive = x,y,z;
    else
        xDrive,yDrive,zDrive = getRotation(wheel.driveNode);
    end;
    xDrive = xDrive+wheel.axleSpeed*dt/1000.0;

    local newX, newY, newZ = getWheelShapePosition(wheel.node, wheel.wheelShape);
    setTranslation(wheel.repr, newX, newY, newZ);

    if wheel.repr == wheel.driveNode then
        setRotation(wheel.repr, xDrive, steeringAngle, z);
    else
        setRotation(wheel.repr, x, steeringAngle, z);
        setRotation(wheel.driveNode, xDrive, yDrive, zDrive);
    end;

end;