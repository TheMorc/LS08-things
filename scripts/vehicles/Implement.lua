--
-- Implement
-- Base class for all implements
--
-- @author  Stefan Geiger (mailto:sgeiger@giants.ch)
-- @date  04/02/08

Implement = {};

function Implement:new(configFile, positionX, offsetY, positionZ, rotationY, customMt)

    if Implement_mt == nil then
        Implement_mt = Class(Implement);
    end;

    local instance = {};
    if customMt ~= nil then
        setmetatable(instance, customMt);
    else
        setmetatable(instance, Implement_mt);
    end;

    instance.configFileName = configFile;

    local xmlFile = loadXMLFile("TempConfig", configFile);

    local rootNode = loadI3DFile(getXMLString(xmlFile, "vehicle.filename"));
    instance.rootNode = getChildAt(rootNode, 0);
    link(getRootNode(), instance.rootNode);
    delete(rootNode);

    local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, positionX, 300, positionZ);

    setTranslation(instance.rootNode, positionX, terrainHeight+offsetY, positionZ);
    rotate(instance.rootNode, 0, rotationY, 0);

    instance.name = Utils.getNoNil(getXMLString(xmlFile, "vehicle.name."..g_languageShort), "Gerät");

    local numCuttingAreas = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.cuttingAreas#count"), 0);
    instance.cuttingAreas = {}
    for i=1, numCuttingAreas do
        instance.cuttingAreas[i] = {};
        local areanamei = string.format("vehicle.cuttingAreas.cuttingArea" .. "%d", i);
        --local x,y,z = getTranslation(Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, areanamei .. "#startIndex")));
        --local widthX, widthY, widthZ = getTranslation(Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, areanamei .. "#widthIndex")));
        --local heightX, heightY, heightZ = getTranslation(Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, areanamei .. "#heightIndex")));
        _=[[instance.cuttingAreas[i].startX = x;
        instance.cuttingAreas[i].startZ = z;
        instance.cuttingAreas[i].width = widthX-x;
        instance.cuttingAreas[i].height = heightZ-z;]]
        instance.cuttingAreas[i].start = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, areanamei .. "#startIndex"));
        instance.cuttingAreas[i].width = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, areanamei .. "#widthIndex"));
        instance.cuttingAreas[i].height = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, areanamei .. "#heightIndex"));
    end;

    instance.attacherJoint = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, "vehicle.attacherJoint#index"));
    instance.fixedAttachRotation = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.attacherJoint#fixedRotation"), false);
    instance.topReferenceNode = Utils.indexToObject(instance.rootNode, getXMLString(xmlFile, "vehicle.topReferenceNode#index"));

    local centerOfMassX = getXMLFloat(xmlFile, "vehicle.centerOfMass#x");
    local centerOfMassY = getXMLFloat(xmlFile, "vehicle.centerOfMass#y");
    local centerOfMassZ = getXMLFloat(xmlFile, "vehicle.centerOfMass#z");
    if centerOfMassX ~= nil and centerOfMassY ~= nil and centerOfMassZ ~= nil then
        setCenterOfMass(instance.rootNode, centerOfMassX, centerOfMassY, centerOfMassZ);
    end;

    delete(xmlFile);

    instance.isAttached = false;
    instance.isSelected = false;
    instance.firstTimeRun = false;
    instance.needActivation = false;
    instance.needLowering = true;

    return instance;
end;

function Implement:delete()
    delete(self.rootNode);
end;

function Implement:setWorldPosition(x,y,z, xRot,yRot,zRot)
    setTranslation(self.rootNode, x,y,z);
    setRotation(self.rootNode, xRot,yRot,zRot);
end;

function Implement:mouseEvent(posX, posY, isDown, isUp, button)
end;

function Implement:keyEvent(unicode, sym, modifier, isDown)
end;

function Implement:update(dt)

    self.firstTimeRun = true;
end;

function Implement:draw()
end;

function Implement:onAttach(attacherVehicle)
    self.isAttached = true;
    self.attacherVehicle = attacherVehicle;
end;

function Implement:onDetach()
    self.isAttached = false;
end;

function Implement:onSelect()
    self.isSelected = true;
end;

function Implement:onDeselect()
    self.isSelected = false;
end;
