Utils = {};

function Utils.indexToObject(rootNode, index)
    if index == nil then
        return nil;
    end;
    local retVal = rootNode;
    local curPos = 1;
    local iStart, iEnd = string.find(index, "|", curPos);
    while iStart ~= nil do
        retVal = getChildAt(retVal, tonumber(string.sub(index, curPos, iStart-1)));
        curPos = iEnd+1;
        iStart, iEnd = string.find(index, "|", curPos);
    end;
    retVal = getChildAt(retVal, tonumber(string.sub(index, curPos)));

    return retVal;
end;

function Utils.updateWheatArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value)
    local wheatId = g_currentMission.wheatId;
    return Utils.updateDensity(wheatId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0, value);
end;

function Utils.updateCuttedWheatArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local cuttedWheatId = getChild(g_currentMission.terrainRootNode, "cuttedWheat");
    local wheatId = getChild(g_currentMission.terrainRootNode, "wheat");

    local x, y, z = worldToLocal(cuttedWheatId, startWorldX, 0, startWorldZ);
    local xWidth, yWidth, zWidth = worldToLocal(cuttedWheatId, widthWorldX, 0, widthWorldZ);
    local xHeight, yHeight, zHeight = worldToLocal(cuttedWheatId, heightWorldX, 0, heightWorldZ);
    local widthDiffX = xWidth-x;
    local widthDiffZ = zWidth-z;
    local heightDiffX = xHeight-x;
    local heightDiffZ = zHeight-z;
    setDensityMaskedParallelogram(cuttedWheatId, x, z, widthDiffX, widthDiffZ, heightDiffX, heightDiffZ, 0, wheatId, 0, 1.0);
end;

function Utils.updateGrassAt(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value)
    local grassId = g_currentMission.grassId;
    return Utils.updateDensity(grassId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0, value);
end;

function Utils.updateCultivatorArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local detailId = g_currentMission.terrainDetailId;
    Utils.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    return Utils.updateDensity(detailId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, g_currentMission.cultivatorChannel, 1, g_currentMission.ploughChannel, 0, g_currentMission.sowingChannel, 0, g_currentMission.sprayChannel, 0);
end;

function Utils.updatePloughArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local detailId = g_currentMission.terrainDetailId;
    Utils.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    return Utils.updateDensity(detailId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, g_currentMission.ploughChannel, 1, g_currentMission.cultivatorChannel, 0, g_currentMission.sowingChannel, 0, g_currentMission.sprayChannel, 0);
end;

function Utils.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local wheatId = g_currentMission.wheatId;
    local cuttedWheatId = g_currentMission.cuttedWheatId;
    local grassId = g_currentMission.grassId;
    Utils.updateDensity(wheatId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, -1, 0);
    Utils.updateDensity(cuttedWheatId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0, 0);
    Utils.updateDensity(grassId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0, 0);
end;

function Utils.updateSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local cultivatorId = getChild(g_currentMission.terrainRootNode, "terrainDetail");

    local x, y, z = worldToLocal(cultivatorId, startWorldX, 0, startWorldZ);
    local xWidth, yWidth, zWidth = worldToLocal(cultivatorId, widthWorldX, 0, widthWorldZ);
    local xHeight, yHeight, zHeight = worldToLocal(cultivatorId, heightWorldX, 0, heightWorldZ);
    local widthDiffX = xWidth-x;
    local widthDiffZ = zWidth-z;
    local heightDiffX = xHeight-x;
    local heightDiffZ = zHeight-z;
    setDensityMaskedParallelogram(cultivatorId, x, z, widthDiffX, widthDiffZ, heightDiffX, heightDiffZ, 3, cultivatorId, 0, 1.0);
    setDensityMaskedParallelogram(cultivatorId, x, z, widthDiffX, widthDiffZ, heightDiffX, heightDiffZ, 3, cultivatorId, 1, 1.0);
    setDensityMaskedParallelogram(cultivatorId, x, z, widthDiffX, widthDiffZ, heightDiffX, heightDiffZ, 3, cultivatorId, 2, 1.0);
end;

function Utils.updateSowingArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local cultivatorId = g_currentMission.terrainDetailId;

    local x, y, z = worldToLocal(cultivatorId, startWorldX, 0, startWorldZ);
    local xWidth, yWidth, zWidth = worldToLocal(cultivatorId, widthWorldX, 0, widthWorldZ);
    local xHeight, yHeight, zHeight = worldToLocal(cultivatorId, heightWorldX, 0, heightWorldZ);
    local widthDiffX = xWidth-x;
    local widthDiffZ = zWidth-z;
    local heightDiffX = xHeight-x;
    local heightDiffZ = zHeight-z;

    local area1 = setDensityMaskedParallelogram(cultivatorId, x, z, widthDiffX, widthDiffZ, heightDiffX, heightDiffZ, g_currentMission.sowingChannel, cultivatorId, g_currentMission.cultivatorChannel, 1.0);
    local area2 = setDensityMaskedParallelogram(cultivatorId, x, z, widthDiffX, widthDiffZ, heightDiffX, heightDiffZ, g_currentMission.sowingChannel, cultivatorId, g_currentMission.ploughChannel, 1.0);

    setDensityParallelogram(cultivatorId, x, z, widthDiffX, widthDiffZ, heightDiffX, heightDiffZ, 0, 0.0);
    setDensityParallelogram(cultivatorId, x, z, widthDiffX, widthDiffZ, heightDiffX, heightDiffZ, 1, 0.0);

    local wheatId = g_currentMission.wheatId;
    xWidth, yWidth, zWidth = worldToLocal(wheatId, widthWorldX, 0, widthWorldZ);
    xHeight, yHeight, zHeight = worldToLocal(wheatId, heightWorldX, 0, heightWorldZ);
    widthDiffX = xWidth-x;
    widthDiffZ = zWidth-z;
    heightDiffX = xHeight-x;
    heightDiffZ = zHeight-z;
    setDensityMaskedParallelogram(wheatId, x, z, widthDiffX, widthDiffZ, heightDiffX, heightDiffZ, 0, cultivatorId, 2, 1.0);
    return area1+area2;
end;

function Utils.updateMeadowArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local meadowId = g_currentMission.meadowId;
    
    local cuttedMeadowId = g_currentMission.cuttedMeadowId;
    
    local x, y, z = worldToLocal(cuttedMeadowId, startWorldX, 0, startWorldZ);
    local xWidth, yWidth, zWidth = worldToLocal(cuttedMeadowId, widthWorldX, 0, widthWorldZ);
    local xHeight, yHeight, zHeight = worldToLocal(cuttedMeadowId, heightWorldX, 0, heightWorldZ);
    local widthDiffX = xWidth-x;
    local widthDiffZ = zWidth-z;
    local heightDiffX = xHeight-x;
    local heightDiffZ = zHeight-z;
    setDensityMaskedParallelogram(cuttedMeadowId, x, z, widthDiffX, widthDiffZ, heightDiffX, heightDiffZ, 0, meadowId, 1, 1.0);
    setDensityMaskedParallelogram(cuttedMeadowId, x, z, widthDiffX, widthDiffZ, heightDiffX, heightDiffZ, 0, meadowId, 2, 1.0);
    setDensityMaskedParallelogram(cuttedMeadowId, x, z, widthDiffX, widthDiffZ, heightDiffX, heightDiffZ, 0, meadowId, 3, 1.0);

    return Utils.updateDensity(meadowId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 1, 0, 2, 0, 3, 0);
end;

function Utils.updateCuttedMeadowArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local cuttedMeadowId = g_currentMission.cuttedMeadowId;
    return Utils.updateDensity(cuttedMeadowId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 1, 0);
end;

function Utils.updateDensity(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, channel, value, channel2, value2, channel3, value3, channel4, value4)
    local x, y, z = worldToLocal(id, startWorldX, 0, startWorldZ);
    local xWidth, yWidth, zWidth = worldToLocal(id, widthWorldX, 0, widthWorldZ);
    local xHeight, yHeight, zHeight = worldToLocal(id, heightWorldX, 0, heightWorldZ);
    local widthDiffX = xWidth-x;
    local widthDiffZ = zWidth-z;
    local heightDiffX = xHeight-x;
    local heightDiffZ = zHeight-z;
    local returnValues = {};
    if channel2 ~= nil and value2 ~= nil then
        returnValues[2] = setDensityParallelogram(id, x, z, widthDiffX, widthDiffZ, heightDiffX, heightDiffZ, channel2, value2);
        if channel3 ~= nil and value3 ~= nil then
            returnValues[3] = setDensityParallelogram(id, x, z, widthDiffX, widthDiffZ, heightDiffX, heightDiffZ, channel3, value3);
            if channel4 ~= nil and value4 ~= nil then
                returnValues[4] = setDensityParallelogram(id, x, z, widthDiffX, widthDiffZ, heightDiffX, heightDiffZ, channel4, value4);
            end;
        end;
    end;
    returnValues[1] = setDensityParallelogram(id, x, z, widthDiffX, widthDiffZ, heightDiffX, heightDiffZ, channel, value);
    --return setDensityParallelogram(id, x, z, widthDiffX, widthDiffZ, heightDiffX, heightDiffZ, channel, value);
    return unpack(returnValues);
end;

function Utils.getDensity(id, channel, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local x, y, z = worldToLocal(id, startWorldX, 0, startWorldZ);
    local xWidth, yWidth, zWidth = worldToLocal(id, widthWorldX, 0, widthWorldZ);
    local xHeight, yHeight, zHeight = worldToLocal(id, heightWorldX, 0, heightWorldZ);
    local widthDiffX = xWidth-x;
    local widthDiffZ = zWidth-z;
    local heightDiffX = xHeight-x;
    local heightDiffZ = zHeight-z;
    return getDensityParallelogram(id, x, z, widthDiffX, widthDiffZ, heightDiffX, heightDiffZ, channel);
end;

function Utils.vector2Length(x,y)
    return math.sqrt(x*x + y*y);
end;

function Utils.vector3Length(x,y,z)
    return math.sqrt(x*x + y*y + z*z);
end;

function Utils.degToRad(deg)
    if deg ~= nil then
        return math.rad(deg);
        --return deg*3.141592/180;
    else
        return 0;
    end;
end;

function Utils.getNoNil(value, setTo)
    if value == nil then
        return setTo;
    end;
    return value;
end;

function Utils.getVectorFromString(input)
    if input == nil then
        return nil;
    end;
    local strings = Utils.splitString(" ", input);
    local results = {};
    for i=1, table.getn(strings) do
        table.insert(results, tonumber(strings[i]));
    end;
    return unpack(results);
end;

function Utils.splitString(splitPattern, text)
    local results = {};
    local start = 1;
    local splitStart, splitEnd = string.find(text, splitPattern, start);
    while splitStart ~= nil do
        table.insert(results, string.sub(text, start, splitStart-1));
        start = splitEnd + 1;
        splitStart, splitEnd = string.find(text, splitPattern, start);
    end
    table.insert(results, string.sub(text, start));
    return results;
end;

function Utils.sign(x)
    if x > 0 then
        return 1;
    elseif x < 0 then
        return -1;
    end;
    return 0;
end;

function Utils.getMovedLimitedValues(currentValues, maxValues, minValues, numValues, speed, dt, inverted)
    local ret = {};
    for i=1, numValues do
        local limitF = math.min;
        local maxVal = maxValues[i];
        local minVal = minValues[i];
        if inverted then
            -- opposite direction, inverted max, min
            maxVal = minVal;
            minVal = maxValues[i];
        end;
        -- we are moving towards -inf, we need to check for the maximum
        if maxVal < minVal then
            limitF = math.max;
        end;
        ret[i] = limitF(currentValues[i] + (maxVal-minVal)/speed * dt, maxVal);
    end;
    return ret;
end;

function Utils.loadParticleSystem(xmlFile, particleSystems, baseString, linkNode, defaultEmittingState)

    local posStr = getXMLString(xmlFile, baseString .. "#position");
    local rotStr = getXMLString(xmlFile, baseString .. "#rotation");
    if posStr ~= nil and rotStr ~= nil then
        local posX, posY, posZ = Utils.getVectorFromString(posStr);
        local rotX, rotY, rotZ = Utils.getVectorFromString(rotStr);
        rotX = Utils.degToRad(rotX);
        rotY = Utils.degToRad(rotY);
        rotZ = Utils.degToRad(rotZ);
        local psFile = getXMLString(xmlFile, baseString .. "#file");
        local rootNode = loadI3DFile(psFile);
        link(linkNode, rootNode);
        setTranslation(rootNode, posX, posY, posZ);
        setRotation(rootNode, rotX, rotY, rotZ);
        for i=0, getNumOfChildren(rootNode)-1 do
            local child = getChildAt(rootNode, i);
            if getClassName(child) == "Shape" then
                local geometry = getGeometry(child);
                if geometry ~= 0 then
                    if getClassName(geometry) == "ParticleSystem" then
                        table.insert(particleSystems, geometry);
                        if defaultEmittingState ~= nil then
                            setEmittingState(geometry, defaultEmittingState);
                        end;
                    end;
                end;
            end;
        end;
    end;
end;

function Utils.setEmittingState(particleSystems, state)

    for i=1, table.getn(particleSystems) do
        setEmittingState(particleSystems[i], state);
    end;

end;

function Utils.getMSAAIndex(msaa)
    local currentMSAAIndex = 1;
    if msaa == 2 then currentMSAAIndex = 2; end;
    if msaa == 4 then currentMSAAIndex = 3; end;
    if msaa == 8 then currentMSAAIndex = 4; end;
    
    return currentMSAAIndex;
end;

function Utils.getAnsioIndex(ansio)
    local currentAnisoIndex = 1;
    if ansio == 2 then currentAnisoIndex = 2; end;
    if ansio == 4 then currentAnisoIndex = 3; end;
    if ansio == 8 then currentAnisoIndex = 4; end;
    
    return currentAnisoIndex;
end;

function Utils.getProfileClassIndex(profileClass)
    local currentProfileIndex = 1;
    if profileClass == "low" then currentProfileIndex = 2; end;
    if profileClass == "medium" then currentProfileIndex = 3; end;
    if profileClass == "high" then currentProfileIndex = 4; end;
    if profileClass == "very high" then currentProfileIndex = 5; end;
    return currentProfileIndex;
end;

function Utils.getTimeScaleIndex(timeScale)
    local timeScaleIndex = 1;
    if timeScale == 4 then timeScaleIndex = 2; end;
    if timeScale == 16 then timeScaleIndex = 3; end;
    if timeScale == 32 then timeScaleIndex = 4; end;
    if timeScale == 60 then timeScaleIndex = 5; end;
    return timeScaleIndex;
end;
