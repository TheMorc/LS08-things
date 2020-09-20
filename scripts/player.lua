Player = {}
Player.walkingSpeed = 0.005;
Player.gravity = -0.980665;

Player.mouseXLast = nil; -- = 0.5;
Player.mouseYLast = nil; -- = 0.5;
Player.rotX = 0;
Player.rotY = 0;

Player.height = 1.8;

Player.lastCamera = "";
Player.camera = 0;

Player.time = 0;

Player.walkStepSolidGround = {};
Player.numWalkStepSolidGround = 0;
Player.currentWalkStep = 0;
Player.walkStepSolidGroundDuration = {};
Player.walkStepSolidGroundTimestamp = 0;
Player.lastXPos = 0;
Player.lastZPos = 0;
Player.lastYPos = 0;
Player.walkStepDistance = 0;
Player.lightNode = 0;

function Player.create(posX, yOffset, posZ, rotX, rotY)
    Player.playerName = loadI3DFile("data/templates/player.i3d");
    link(getRootNode(), Player.playerName);
    if posX ~= nil and yOffset ~= nil and posZ ~= nil then
        Player.moveTo(posX, yOffset, posZ);
    else
        setTranslation(Player.playerName, 270, 118, 46);
    end;

    Player.camera = getChild(getChildAt(Player.playerName, 0), "playerCamera");
    if Player.camera == 0 then
        print("Error: invalid player camera");
    end;
    
    if getNumOfChildren(Player.camera) > 0 then
        Player.lightNode = getChildAt(Player.camera, 0);
        setVisibility(Player.lightNode, false);
    end;

    Player.camX, Player.camY, Player.camZ = getTranslation(Player.camera);

    if rotX ~= nil and rotY ~= nil then
        Player.rotX = rotX;
        Player.rotY = rotY;
    else
        Player.rotX = 0;
        Player.rotY = 0;
    end;

    Player.swimPos = 0;

    Player.walkStepSolidGround[0] = createSample("walkStepSolidGround01");
    loadSample(Player.walkStepSolidGround[0], "data/maps/sounds/walkStepSolidGround01.wav", false);    
    Player.walkStepSolidGroundDuration[0] = getSampleDuration(Player.walkStepSolidGround[0]);
    Player.walkStepSolidGround[1] = createSample("walkStepSolidGround02");
    loadSample(Player.walkStepSolidGround[1], "data/maps/sounds/walkStepSolidGround02.wav", false);    
    Player.walkStepSolidGroundDuration[1] = getSampleDuration(Player.walkStepSolidGround[1]);
    Player.walkStepSolidGround[2] = createSample("walkStepSolidGround03");
    loadSample(Player.walkStepSolidGround[2], "data/maps/sounds/walkStepSolidGround03.wav", false);    
    Player.walkStepSolidGroundDuration[2] = getSampleDuration(Player.walkStepSolidGround[2]);
    Player.walkStepSolidGround[3] = createSample("walkStepSolidGround04");
    loadSample(Player.walkStepSolidGround[3], "data/maps/sounds/walkStepSolidGround04.wav", false);    
    Player.walkStepSolidGroundDuration[3] = getSampleDuration(Player.walkStepSolidGround[3]);
    Player.numWalkStepSolidGround = 4;

    Player.oceanWavesSample = createSample("oceanWaves");
    loadSample(Player.oceanWavesSample, "data/maps/sounds/oceanWaves.wav", false); 
    Player.oceanWavesSamplePlaying = false;

    local cctCollisionMask = 2097151; -- 111111111111111111111
    Player.controllerIndex = createCCT(Player.playerName, 0.3, Player.height-2*0.3, 0.6, 45.0, 0.1, 0, 80.0);
    Player.onEnter();
   
end;

function Player.destroy()
    --unlink(Player.playerName);
    removeCCT(Player.controllerIndex);
    delete(Player.playerName);
    Player.playerName = "";
    
    delete(Player.walkStepSolidGround[0]);
    delete(Player.walkStepSolidGround[1]);
    delete(Player.walkStepSolidGround[2]);
    delete(Player.walkStepSolidGround[3]);
    delete(Player.oceanWavesSample);
    
    Player.mouseXLast = nil;
    Player.mouseYLast = nil;
    Player.lightNode  = 0;
    
end;

function Player.mouseEvent(posX, posY, isDown, isUp, button)

    if Player.mouseXLast~=nil and Player.mouseYLast ~= nil then
        Player.rotX = Player.rotX - (Player.mouseYLast-posY);
        Player.rotY = Player.rotY - (posX-Player.mouseXLast);
    
        Player.mouseXLast = posX;
        Player.mouseYLast = posY;
    end;
end;

function Player.update(dt)

    Player.time = Player.time+dt;


    local rotSpeed = 0.001*dt;
    Player.rotX = Player.rotX - rotSpeed*getInputAxis(Input.AXIS_W);
    Player.rotY = Player.rotY - rotSpeed*getInputAxis(Input.AXIS_Z);

    local movementX = 0.0;
    local movementY = Player.gravity*0.25*dt;
    local movementZ = 0.0;
    
    local inputX = getInputAxis(Input.AXIS_X);
    local inputY = getInputAxis(Input.AXIS_Y);
    local len = Utils.vector2Length(inputX, inputY);

    if len > 1 then
        inputX = inputX/len;
        inputY = inputY/len;
    end;
    
    local dz = inputY * Player.walkingSpeed * dt;
    local dx = inputX * Player.walkingSpeed * dt;
    
    movementX = math.sin(Player.rotY)*dz + math.cos(-Player.rotY)*dx;
    movementZ = math.cos(-Player.rotY)*dz - math.sin(Player.rotY)*dx;

    local xt, yt, zt = getTranslation(Player.playerName);
    
    local swimYoffset = 0;

    local waterY = 82.3;
    local deltaWater = yt-waterY;

    local wavesMax = 2;
    local wavesMin = -4;
    if deltaWater < wavesMax then
        
        if not Player.oceanWavesSamplePlaying then
            playSample(Player.oceanWavesSample, 0, 0, 0);
            Player.oceanWavesSamplePlaying = true;
        end;
        

        local height = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, Player.lastXPos, 0, Player.lastZPos)-waterY;
        local volume = 0.5;
        if deltaWater > 0 then
            volume = (wavesMax-deltaWater)/wavesMax*0.5;
        else
            if height < wavesMin then
                volume = 0;
            else
                volume = (wavesMin-height)/wavesMin;
            end;
        end;        
        
        --print(deltaWater, " ", volume, " ", height);
        
        setSampleVolume(Player.oceanWavesSample, volume);
        --print("on");
        
    else
        stopSample(Player.oceanWavesSample);
        Player.oceanWavesSamplePlaying = false;
        --print("off");
    end;


    if deltaWater < 0 then
        movementY = 0;
        Player.swimPos = Player.swimPos + Utils.vector2Length(dx, dz);
        swimYoffset = math.sin(Player.swimPos)*0.3;

        if deltaWater < -0.5 then
            movementY = -Player.gravity*0.001*dt*(-deltaWater);
        end;
    end;
    local dist = 0.5;
    if deltaWater < dist and deltaWater >= 0 then
        swimYoffset = swimYoffset*((dist-deltaWater)/dist);
    end;

    setTranslation(Player.camera, Player.camX, Player.camY+swimYoffset, Player.camZ);

    -- collision group is 0x    0xFFFFFFFD, all but group 1
    -- collision group is combination of nonpushable and trigger_player = 1048607


    moveCCT(Player.controllerIndex, movementX, movementY, movementZ, 1048607, 0.4);

    Player.rotX = math.min(1.2, math.max(-1.5, Player.rotX));
    setRotation(Player.camera, Player.rotX, Player.rotY, 0.0);

    wrapMousePosition(0.5, 0.5);
    Player.mouseXLast = 0.5;
    Player.mouseYLast = 0.5;

    -- Walk step sound
    Player.walkStepDistance = Player.walkStepDistance + Utils.vector2Length(Player.lastXPos-xt, Player.lastZPos-zt);
    local walkStepVolume = 0.35;
    if deltaWater >= 0 and Player.walkStepDistance > 1.3 and Player.walkStepSolidGroundTimestamp < Player.time then

        local pitch = math.random(0.8, 1.1);
        local volume = math.random(0.75, 1);
        local delay = math.random(0, 30);
        setSamplePitch(Player.walkStepSolidGround[Player.currentWalkStep], pitch);        
        playSample(Player.walkStepSolidGround[Player.currentWalkStep], 1, volume*walkStepVolume, delay);
        Player.walkStepDistance = 0;
        Player.walkStepSolidGroundTimestamp = Player.time+Player.walkStepSolidGroundDuration[Player.currentWalkStep]*pitch+delay;
        
        local last = Player.currentWalkStep;
        while last == Player.currentWalkStep do
            Player.currentWalkStep = math.floor(math.random(0, Player.numWalkStepSolidGround-1.00001));
        end;
        
    end;
    
    if Player.lightNode ~= 0 and InputBinding.hasEvent(InputBinding.TOGGLE_LIGHTS) then
        setVisibility(Player.lightNode, not getVisibility(Player.lightNode));
    end;

    Player.lastXPos = xt;
    Player.lastZPos = zt;
end;

function Player.moveTo(x, yOffset, z)
    --removeCCT(Player.controllerIndex);
    --cx, cy, cz = getWorldTranslation(Player.playerName);
    --moveCCT(Player.controllerIndex, x-cx, y-cy, z-cz, 4294967293, 0.4);
    local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 300, z);
    local y = terrainHeight+yOffset+Player.height;
    setTranslation(Player.playerName, x, y, z);
    --Player.controllerIndex = createCCT(Player.playerName, 0.3, 1.8, 0.6, 45.0, 0.01, 0);
    
    Player.lastXPos = x;
    Player.lastYPos = y;
    Player.lastYPos = z;
    
end;

function Player.moveToAbsolute(x, y, z)
    setTranslation(Player.playerName, x, y+Player.height, z);

    Player.lastXPos = x;
    Player.lastYPos = y+Player.height;
    Player.lastZPos = z;
end;


function Player.draw()

end;

function Player.onEnter()
    setCamera(Player.camera);
end;

function Player.onLeave()

    if Player.lightNode ~= 0 then
        setVisibility(Player.lightNode, false);
    end;

end;