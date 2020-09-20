-- Main lua file

-- @author  Stefan Geiger (mailto:sgeiger@giants.ch)
-- @date  24/11/06

function explode(div, str)
    local pos,arr = 0,{};
    for st,sp in function() return string.find(str,div,pos,true) end do -- for each divider found
        table.insert(arr,string.sub(str,pos,st-1)); -- attach chars left of current divider
        pos = sp + 1; -- jump past current divider
    end
    table.insert(arr,string.sub(str,pos)); -- attach chars right of last divider
    return arr;
end;

-- Engine scripts
source("shared/scripts/common/class.lua");

-- Custom scripts
source("data/scripts/I18N.lua");
source("data/scripts/gui/base_gui.lua");
source("data/scripts/MissionStats.lua");
source("data/scripts/BaseMission.lua");
source("data/scripts/RaceMission.lua");
source("data/scripts/StationFillMission.lua");
source("data/scripts/FieldMission.lua");
source("data/scripts/gui/LoadingScreen.lua");
source("data/scripts/gui/MissionMenu.lua");
source("data/scripts/gui/QuickPlayMenu.lua");
source("data/scripts/gui/MedalsDisplay.lua");
source("data/scripts/gui/InGameMenu.lua");
source("data/scripts/gui/menu.lua");
source("data/scripts/gui/DemoEndScreen.lua");

source("data/scripts/environment/environment.lua");
source("data/scripts/player.lua");
source("data/scripts/utils.lua");
source("data/scripts/vehicles/WheelsUtil.lua");
source("data/scripts/vehicles/VehicleMotor.lua");
source("data/scripts/animation.lua");
source("data/scripts/objects/windmill.lua");
source("data/scripts/objects/ship.lua");
source("data/scripts/objects/Nightlight.lua");
source("data/scripts/vehicles/cutter.lua");
source("data/scripts/vehicles/vehiclePlacementCallback.lua");
source("data/scripts/vehicles/vehicleCamera.lua");
source("data/scripts/events.lua");

source("data/scripts/triggers/SiloTrigger.lua");
source("data/scripts/triggers/tipTrigger.lua");
source("data/scripts/triggers/GasStationTrigger.lua");
source("data/scripts/triggers/BarrierTrigger.lua");
source("data/scripts/sounds/randomSound.lua");

gameMenuSystem = {};

g_languageSuffix = "_de";
g_languageShort = "de";
g_isDemo = false;

g_vehicleTypes = {};

g_settingsJoystickEnabled = false;
g_settingsJoystickEnabledMenu = false;

g_settingsHelpText = true;
g_settingsHelpTextMenu = true;
g_settingsTimeScale = 16;
g_settingsTimeScaleMenu = 16;

g_settingsMSAA = 0;
g_settingsAnsio = 0;
g_settingsDisplayResolution = 0;
g_settingsDisplayProfile = 0;

g_savegameRevision = 5;
g_finishedMissions = {};
g_finishedMissionsRecord = {};

g_missionLoaderDesc = {};

g_menuMusic = nil;

g_fuelPricePerLiter = 0.7;
g_seedUsagePerQm = 0.007;
g_seedPricePerLiter = 0.5;
g_wheatPricePerLiter = 0.4;
g_grassPricePerLiter = 0.3;

g_inputButtonEvent = {false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false};
g_inputButtonLast = {false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false};

InputBinding = {};
_=[[InputBinding.ENTER = 1;
InputBinding["ENTER"] = 1;
InputBinding.CAMERA_SWITCH = 2;
InputBinding.TOGGLE_LIGHTS = 3;
InputBinding.LOWER_IMPLEMENT = 4;
InputBinding.ATTACH = 5;
InputBinding.IMPLEMENT_EXTRA = 6;
InputBinding.ACTIVATE_THRESHING = 7;
--InputBinding.OPEN_PIPE = 8;
InputBinding.EMPTY_GRAIN = 8;
InputBinding.SWITCH_IMPLEMENT = 9;
InputBinding.REFUEL = 10;
InputBinding.SPEED_LEVEL1 = 11;
InputBinding.SPEED_LEVEL2 = 12;
InputBinding.SPEED_LEVEL3 = 13;
InputBinding.TOGGLE_PDA = 14;

InputBinding.NUM_BUTTONS = 14;]]

InputBinding.buttons = {};
_=[[InputBinding.buttons[InputBinding.ENTER] = Input.BUTTON_6;
InputBinding.buttons[InputBinding.CAMERA_SWITCH] = Input.BUTTON_5;
InputBinding.buttons[InputBinding.TOGGLE_LIGHTS] = Input.BUTTON_7;
InputBinding.buttons[InputBinding.LOWER_IMPLEMENT] = Input.BUTTON_1;
InputBinding.buttons[InputBinding.ATTACH] = Input.BUTTON_2;
InputBinding.buttons[InputBinding.IMPLEMENT_EXTRA] = Input.BUTTON_3;
InputBinding.buttons[InputBinding.ACTIVATE_THRESHING] = Input.BUTTON_4;
--InputBinding.buttons[InputBinding.OPEN_PIPE] = Input.BUTTON_9;
InputBinding.buttons[InputBinding.EMPTY_GRAIN] = Input.BUTTON_3;
InputBinding.buttons[InputBinding.SWITCH_IMPLEMENT] = Input.BUTTON_4;
InputBinding.buttons[InputBinding.REFUEL] = Input.BUTTON_9;
InputBinding.buttons[InputBinding.SPEED_LEVEL1] = Input.BUTTON_10;
InputBinding.buttons[InputBinding.SPEED_LEVEL2] = Input.BUTTON_11;
InputBinding.buttons[InputBinding.SPEED_LEVEL3] = Input.BUTTON_12;
InputBinding.buttons[InputBinding.TOGGLE_PDA] = Input.BUTTON_13;]]

InputBinding.buttonKeys = {};
_=[[InputBinding.buttonKeys[InputBinding.ENTER] = Input.KEY_e;
InputBinding.buttonKeys[InputBinding.CAMERA_SWITCH] = Input.KEY_c;
InputBinding.buttonKeys[InputBinding.TOGGLE_LIGHTS] = Input.KEY_f;
InputBinding.buttonKeys[InputBinding.LOWER_IMPLEMENT] = Input.KEY_v;
InputBinding.buttonKeys[InputBinding.ATTACH] = Input.KEY_q;
InputBinding.buttonKeys[InputBinding.IMPLEMENT_EXTRA] = Input.KEY_b;
InputBinding.buttonKeys[InputBinding.ACTIVATE_THRESHING] = Input.KEY_g;
--InputBinding.buttonKeys[InputBinding.OPEN_PIPE] = Input.KEY_r;
InputBinding.buttonKeys[InputBinding.EMPTY_GRAIN] = Input.KEY_b;
InputBinding.buttonKeys[InputBinding.SWITCH_IMPLEMENT] = Input.KEY_g;
InputBinding.buttonKeys[InputBinding.REFUEL] = Input.KEY_t;
InputBinding.buttonKeys[InputBinding.SPEED_LEVEL1] = Input.KEY_1;
InputBinding.buttonKeys[InputBinding.SPEED_LEVEL2] = Input.KEY_2;
InputBinding.buttonKeys[InputBinding.SPEED_LEVEL3] = Input.KEY_3;
InputBinding.buttonKeys[InputBinding.TOGGLE_PDA] = Input.KEY_i;]]

_=[[InputBinding.buttonDescriptions = {};
InputBinding.buttonDescriptions[InputBinding.ENTER] = "Ein-/aussteigen";
InputBinding.buttonDescriptions[InputBinding.CAMERA_SWITCH] = "Kamera wechseln";
InputBinding.buttonDescriptions[InputBinding.TOGGLE_LIGHTS] = "Licht an-/ausschalten";
InputBinding.buttonDescriptions[InputBinding.LOWER_IMPLEMENT] = "Gerät hochheben/herunterlassen";
InputBinding.buttonDescriptions[InputBinding.ATTACH] = "Gerät anhängen";
InputBinding.buttonDescriptions[InputBinding.IMPLEMENT_EXTRA] = "Gerät Extra-Funktion";
InputBinding.buttonDescriptions[InputBinding.ACTIVATE_THRESHING] = "Drescher aktivieren";
--InputBinding.buttonDescriptions[InputBinding.OPEN_PIPE] = "Ausflussrohr öffnen";
InputBinding.buttonDescriptions[InputBinding.EMPTY_GRAIN] = "Korntank entleeren";
InputBinding.buttonDescriptions[InputBinding.SWITCH_IMPLEMENT] = "Gerät Auswahl ändern";
InputBinding.buttonDescriptions[InputBinding.REFUEL] = "Tanken";
InputBinding.buttonDescriptions[InputBinding.SPEED_LEVEL1] = "Geschwindigkeitsstufe 1";
InputBinding.buttonDescriptions[InputBinding.SPEED_LEVEL2] = "Geschwindigkeitsstufe 2";
InputBinding.buttonDescriptions[InputBinding.SPEED_LEVEL3] = "Geschwindigkeitsstufe 3";
InputBinding.buttonDescriptions[InputBinding.TOGGLE_PDA] = "PDA ein-/ausschalten";]]

function InputBinding.getButton(button)
    return InputBinding.buttons[button];
end;

function InputBinding.getButtonKey(button)
    return InputBinding.buttonKeys[button];
end;

function InputBinding.hasEvent(button)
    return g_inputButtonEvent[InputBinding.buttons[button]+1];
end;

_=[[function InputBinding.getButtonDescription(button)
    return InputBinding.buttonDescriptions[button];
end;]]

function InputBinding.getButtonKeyName(button)
    return string.upper(string.char(InputBinding.getButtonKey(button)));
end;

function InputBinding.getButtonName(button)
    return string.format("%d", InputBinding.getButton(button)+1);
end;

function init()

    loadInputBinding();

    local xmlFile = loadXMLFile("LanguageFile", "data/language.xml");
    g_languageShort = Utils.getNoNil(getXMLString(xmlFile, "language#short"), "de");
    g_languageSuffix = Utils.getNoNil(getXMLString(xmlFile, "language#suffix"), "_de");
    delete(xmlFile);

    g_settingsJoystickEnabled = getJoystickEnabled();
    g_settingsJoystickEnabledMenu = g_settingsJoystickEnabled;

    g_i18n = I18N:new();

    -- Copy savegames xml file to user profile app directory
    local savegamePathTemplate = getAppBasePath() .. "data/savegamesTemplate.xml";
    g_savegamePath = getUserProfileAppPath() .. "savegames.xml";
    copyFile(savegamePathTemplate, g_savegamePath, false);

    g_savegameXML = loadXMLFile("savegameXML", g_savegamePath);

    -- Overwrite old savegame xml if version doesn't match
    local revision = getXMLInt(g_savegameXML, "savegames#revision");
    if revision == nil or revision ~= g_savegameRevision then
        copyFile(savegamePathTemplate, g_savegamePath, true);
        delete(g_savegameXML);
        g_savegameXML = loadXMLFile("savegameXML", g_savegamePath);
    end;

    -- Load savegame
    g_settingsHelpText = getXMLBool(g_savegameXML, "savegames.settings.autohelp");
    g_settingsHelpTextMenu = g_settingsHelpText;

    g_settingsTimeScale = getXMLFloat(g_savegameXML, "savegames.settings#timescale");
    --print("timeScale ", g_settingsTimeScale);

    if g_settingsTimeScale == nil or g_settingsTimeScale == 0 then
        g_settingsTimeScale = 16;
    end;
    g_settingsTimeScaleMenu = g_settingsTimeScale;


    --local loadDir = getUserProfileAppPath() .. "savegame0_0";
    --setTerrainLoadDirectory(loadDir);

    -- initialize lua random generator
    math.randomseed(os.time());
    math.random(); math.random(); math.random();

    loadVehicleTypes();

    for i=1, InputBinding.NUM_BUTTONS do
        setKeyboardButtonMapping(InputBinding.getButton(i), InputBinding.getButtonKey(i));
    end;

    simulatePhysics(false);

    gameMenuSystem = GameMenuSystem:new();
    gameMenuSystem:init();
    setShowMouseCursor(true);

    g_defaultCamera = getCamera();

    g_menuMusic = createSample("menuMusic");
    loadSample(g_menuMusic, "data/menu/menu.wav", false);
    playSample(g_menuMusic, 0, 1, 0);

    return true;

end;

-- Global mouse input callback function
function mouseEvent(posX, posY, isDown, isUp, button)

    Input.updateMouseButtonState(button, isDown)

    -- send event to gui
    --gui_mouseEvent(posX, posY, isDown, isUp, button);
    gameMenuSystem:mouseEvent(posX, posY, isDown, isUp, button);

    if g_currentMission ~= nil and not gameMenuSystem:isMenuActive() then
        g_currentMission:mouseEvent(posX, posY, isDown, isUp, button);
    end

end;

-- Global key input callback function
function keyEvent(unicode, sym, modifier, isDown)
    Input.updateKeyState(sym, isDown);

    gameMenuSystem:keyEvent(unicode, sym, modifier, isDown);

    if g_currentMission ~= nil and not gameMenuSystem:isMenuActive() then
        g_currentMission:keyEvent(unicode, sym, modifier, isDown);
    end;

    --if sym == Input.KEY_p and isDown then
    --    local dir = getUserProfileAppPath() .. "savegame0_2";
    --    createFolder(dir);
    --    local filename = getDensityMapFileName(g_currentMission.wheatId);
    --    saveDensityMapToFile(g_currentMission.wheatId, dir .."/"..filename);
    --end;
end;

-- GC fly through
--flyTime = 0;

-- Global update callback function
function update(dt)

    for i=1, 16 do
        local isDown = getInputButton(i-1) > 0;
        g_inputButtonEvent[i] = isDown and not g_inputButtonLast[i];
        g_inputButtonLast[i] = isDown;
    end;

    -- update gui
    gameMenuSystem:update(dt);

    if g_currentMission ~= nil and not gameMenuSystem:isMenuActive() then
        g_currentMission:update(dt);
    end;

end;

-- Global draw callback function
function draw()

    -- render gui
    gameMenuSystem:render();

    if g_currentMission ~= nil then

        --renderText(0.01, 0.98, 0.02, string.format("Speed: %f", Player.speed));

        _=[[if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle.grainTankFillLevel ~= nil then
            if g_currentMission.controlledVehicle.grainTankCrowded then
                setTextColor(1.0, 0.0, 0.0, 1.0);
                renderText(0.01, 0.96, 0.02, "Warning: Grain tank crowded");
            else
                setTextColor(1.0, 1.0, 1.0, 1.0);
            end;
            --renderText(0.01, 0.98, 0.02, string.format("%f", --g_currentMission.controlledVehicle.grainTankFillLevel));

            setTextColor(1.0, 1.0, 1.0, 1.0);
            if g_currentMission.controlledVehicle.noTrailerWarning then
                renderText(0.01, 0.94, 0.02, "Warning: Draining of tank was aborted! There is no trailer to fill.");
            end;
        end;]]

        --renderText(0.01, 0.98, 0.02, string.format("%f %f %f %f", dayPart, sunsetPart, nightPart, sunrisePart));
        --renderText(0.01, 0.96, 0.02, string.format("%f", vel));

        g_currentMission:draw();
    end;
    
    --if g_currentMission == nil then
    --    renderText(0.75, 0.01, 0.04, "Internal use only");
    --end;

    --local used = collectgarbage("count");
    --renderText(0.1, 0.1, 0.02,  string.format("used memory %dkb", used));
end;

function loadVehicleTypes()
    local types = {"steerables", "trailers", "implements", "cutters"}
    local xmlFile = loadXMLFile("VehicleTypes", "data/vehicleTypes.xml");
    for t=1, table.getn(types) do
        local i=0;
        while true do
            local baseName = string.format("vehiclesTypes."..types[t]..".type(%d)", i);
            local typeName = getXMLString(xmlFile, baseName.. "#name");
            if typeName == nil then
                break;
            end;
            if g_vehicleTypes[typeName] ~= nil then
                print("Error vehicleTypes.xml: multiple specifications of type '"..typeName .."'");
            else
                local typeEntry = {};
                typeEntry.name = typeName;

                typeEntry.intern = types[t];

                local className = getXMLString(xmlFile, baseName.. "#className");
                if className == nil then
                    print("Error vehicleTypes.xml: no className specified for '".. typeName .."'");
                else
                    typeEntry.className = className;
                    local filename = getXMLString(xmlFile, baseName.. "#filename");
                    if filename == nil then
                        print("Error vehicleTypes.xml: no filename specified for '".. typeName .."'");
                    else
                        typeEntry.filename = filename;

                        source(filename);
                        g_vehicleTypes[typeName] = typeEntry;
                    end;
                end;
            end;
            i = i+1;
        end;
    end;
    delete(xmlFile);
end;

function loadInputBinding()
    local xmlFile = loadXMLFile("VehicleTypes", "data/inputBinding.xml");
    local i=0;
    while true do
        local baseName = string.format("inputBinding.input(%d)", i);
        local inputName = getXMLString(xmlFile, baseName.. "#name");
        if inputName == nil then
            break;
        end;
        local inputKey = getXMLString(xmlFile, baseName.. "#key");
        local inputButton = getXMLString(xmlFile, baseName.. "#button");
        if inputKey == nil or inputButton == nil then
            print("Error: no button or key specified for input event '" .. inputName .. "'");
            break;
        end;
        if Input[inputButton] == nil then
            print("Error: invalid button '" .. inputButton .. "'  for input event '" .. inputName .. "'");
            break;
        end;
        if Input[inputKey] == nil then
            print("Error: invalid key '" .. inputKey .. "'  for input event '" .. inputName .. "'");
            break;
        end;
        InputBinding[inputName] = i+1;
        InputBinding.buttons[InputBinding[inputName]] = Input[inputButton];
        InputBinding.buttonKeys[InputBinding[inputName]] = Input[inputKey];
        i = i+1;
    end;
    InputBinding.NUM_BUTTONS = i;
    delete(xmlFile);
end;
