
GameMenuSystem = {};

local GameMenuSystem_mt = Class(GameMenuSystem);

function GameMenuSystem:new()
    return setmetatable({}, GameMenuSystem_mt);
end;

function GameMenuSystem:init()
    -- load overlays
    local bgOverlay = Overlay:new("background01", "data/menu/background01".. g_languageSuffix .. ".png", 0.0, 0.0, 1.0, 1.0);
    local logoOverlay = Overlay:new("main_logo", "data/menu/main_logo".. g_languageSuffix .. ".png", 0.1, 0.575, 0.8, 0.4);

    -- Main
    local main_menu_posX = 0.05;
    local main_menu_posY = 0.5;
    local main_menu_sizeX = 0.15;
    local main_menu_spaceY = 0.07;
    local main_menu_sizeY = 0.06;
    self.mainMenu = OverlayMenu:new();
    self.mainMenu:addItem(bgOverlay);
    self.mainMenu:addItem(logoOverlay);
    self.mainMenu:addItem(OverlayButton:new(Overlay:new("main_quickplay_button", "data/menu/main_quickplay_button".. g_languageSuffix .. ".png", main_menu_posX, main_menu_posY-main_menu_spaceY*0, main_menu_sizeX, main_menu_sizeY), OnMainMenuQuickPlay));
    self.mainMenu:addItem(OverlayButton:new(Overlay:new("main_mission_button", "data/menu/main_mission_button".. g_languageSuffix .. ".png", main_menu_posX, main_menu_posY-main_menu_spaceY*1, main_menu_sizeX, main_menu_sizeY), OnMainMenuMission));
    self.mainMenu:addItem(OverlayButton:new(Overlay:new("main_settings_button", "data/menu/main_settings_button".. g_languageSuffix .. ".png", main_menu_posX, main_menu_posY-main_menu_spaceY*2, main_menu_sizeX, main_menu_sizeY), OnMainMenuSettings));
    self.mainMenu:addItem(OverlayButton:new(Overlay:new("main_credits_button", "data/menu/main_credits_button".. g_languageSuffix .. ".png", main_menu_posX, main_menu_posY-main_menu_spaceY*3, main_menu_sizeX, main_menu_sizeY), OnMainMenuCredits));
    self.mainMenu:addItem(OverlayButton:new(Overlay:new("main_quit_button", "data/menu/main_quit_button".. g_languageSuffix .. ".png", main_menu_posX, main_menu_posY-main_menu_spaceY*4, main_menu_sizeX, main_menu_sizeY), OnMainMenuQuit));

    -- Mission
    self.missionMenu = MissionMenu:new(bgOverlay);

    -- Quick Play
    self.quickPlayMenu = QuickPlayMenu:new(bgOverlay);

	-- Settings
    local settings_menu_posX = 0.05;
    local settings_menu_posY = 0.5;
    local settings_menu_sizeX = 0.15;
    local settings_menu_spaceY = 0.07;
    local settings_menu_sizeY = 0.06;
    self.settingsMenu = OverlayMenu:new();
    self.settingsMenu:addItem(bgOverlay);
    self.settingsMenu:addItem(logoOverlay);
    self.settingsMenu:addItem(OverlayButton:new(Overlay:new("settings_save_button", "data/menu/save_button".. g_languageSuffix .. ".png", settings_menu_posX, settings_menu_posY-settings_menu_spaceY*0, settings_menu_sizeX, settings_menu_sizeY), OnSettingsMenuSave));
    self.settingsMenu:addItem(OverlayButton:new(Overlay:new("settings_back_button", "data/menu/back_button".. g_languageSuffix .. ".png", settings_menu_posX, settings_menu_posY-settings_menu_spaceY*1, settings_menu_sizeX, settings_menu_sizeY), OnSettingsMenuBack));

	local settings_posX = 0.25;
    local settings_posY = 0.5;
    local settings_spaceY = 0.07;
    local settings_small_button_size = 0.06;
    local settings_text_label_sizeX = 0.48;
    local settings_text_label_sizeY = 0.06;

    local settings_sizeX = 0.7;
    local settings_menu_border = 0.01;
    local settings_sizeY = settings_spaceY*7+settings_menu_border*2;


    local settings_textX = settings_posX+0.375+0.05;
    local settings_offsetY = -0.01;

    self.settingsMenu:addItem(Overlay:new("settings_background", "data/menu/settings_background.png", settings_posX, settings_posY-settings_sizeY+settings_spaceY-0.01, settings_sizeX, settings_sizeY+0.01));

    self.settingsMenu:addItem(Overlay:new("settings_resolution", "data/menu/settings_resolution".. g_languageSuffix .. ".png", settings_posX+settings_menu_border, settings_posY-settings_spaceY*0-settings_menu_border, settings_text_label_sizeX*0.75, settings_text_label_sizeY));

    local resTable = {};
    local numR = getNumOfScreenModes();
    for i=0, numR-1 do
        local x, y = getScreenModeInfo(numR-i-1);

        aspect = x/y;

        if aspect == 1.25 then
            aspectStr = "(5:4)";
        else
            if aspect > 1.3 and aspect < 1.4 then
                aspectStr = "(4:3)";
            else
                if aspect > 1.7 and aspect < 1.8 then
                    aspectStr = "(16:9)";
                else
                    aspectStr = string.format("(%1.1f:1)", aspect);
                end;
            end;
        end;
        table.insert(resTable, string.format("%dx%d %s", x, y, aspectStr));
    end;

    g_settingsDisplayResolution = getScreenMode();

    local down = OverlayButton:new(Overlay:new("settings_resolution_down", "data/menu/small_button_left.png", settings_posX+0.375, settings_posY-settings_spaceY*0-settings_menu_border, settings_small_button_size*0.75, settings_small_button_size), OnSettingsMenuResolutionDown);
    local up = OverlayButton:new(Overlay:new("settings_resolution_up", "data/menu/small_button_right.png", settings_posX+0.63, settings_posY-settings_spaceY*0-settings_menu_border, settings_small_button_size*0.75, settings_small_button_size), OnSettingsMenuResolutionUp);
    self.settingsMenu.resTextOp = OverlayMultiTextOption:new(resTable, down, up, settings_textX+0.025-0.02, settings_posY-settings_spaceY*0-settings_menu_border-settings_offsetY, 0.033, numR-g_settingsDisplayResolution, OnSettingsMenuDisplayResolution);
    self.settingsMenu:addItem(self.settingsMenu.resTextOp);

    -- msaa
    self.settingsMenu:addItem(Overlay:new("settings_msaa", "data/menu/settings_msaa".. g_languageSuffix .. ".png", settings_posX+settings_menu_border, settings_posY-settings_spaceY*1-settings_menu_border, settings_text_label_sizeX*0.75, settings_text_label_sizeY));

    local msaaTable = {};
    table.insert(msaaTable, "Off");
    table.insert(msaaTable, "2");
    table.insert(msaaTable, "4");
    table.insert(msaaTable, "8");
    g_settingsMSAA = getMSAA();
    local down = OverlayButton:new(Overlay:new("settings_resolution_down", "data/menu/small_button_left.png", settings_posX+0.375, settings_posY-settings_spaceY*1-settings_menu_border, settings_small_button_size*0.75, settings_small_button_size), OnSettingsMenuResolutionDown);
    local up = OverlayButton:new(Overlay:new("settings_resolution_up", "data/menu/small_button_right.png", settings_posX+0.63, settings_posY-settings_spaceY*1-settings_menu_border, settings_small_button_size*0.75, settings_small_button_size), OnSettingsMenuResolutionUp);
    self.settingsMenu.msaaTextOp = OverlayMultiTextOption:new(msaaTable, down, up, settings_textX+0.025-0.02, settings_posY-settings_spaceY*1-settings_menu_border-settings_offsetY, 0.035, Utils.getMSAAIndex(g_settingsMSAA), OnSettingsMenuMSAA);
    self.settingsMenu:addItem(self.settingsMenu.msaaTextOp);


    -- Aniso
    self.settingsMenu:addItem(Overlay:new("settings_aniso_de", "data/menu/settings_aniso".. g_languageSuffix .. ".png", settings_posX+settings_menu_border, settings_posY-settings_spaceY*2-settings_menu_border, settings_text_label_sizeX*0.75, settings_text_label_sizeY));
    local anisoTable = {};
    table.insert(anisoTable, "Off");
    table.insert(anisoTable, "2");
    table.insert(anisoTable, "4");
    table.insert(anisoTable, "8");
    g_settingsAnsio = getFilterAnisotropy();
    local down = OverlayButton:new(Overlay:new("settings_resolution_down", "data/menu/small_button_left.png", settings_posX+0.375, settings_posY-settings_spaceY*2-settings_menu_border, settings_small_button_size*0.75, settings_small_button_size), OnSettingsMenuResolutionDown);
    local up = OverlayButton:new(Overlay:new("settings_resolution_up", "data/menu/small_button_right.png", settings_posX+0.63, settings_posY-settings_spaceY*2-settings_menu_border, settings_small_button_size*0.75, settings_small_button_size), OnSettingsMenuResolutionUp);
    self.settingsMenu.ansioTextOp = OverlayMultiTextOption:new(anisoTable, down, up, settings_textX+0.025-0.02, settings_posY-settings_spaceY*2-settings_menu_border-settings_offsetY, 0.035, Utils.getAnsioIndex(g_settingsAnsio), OnSettingsMenuAniso);
    self.settingsMenu:addItem(self.settingsMenu.ansioTextOp);

    -- Joystick
    self.settingsMenu:addItem(Overlay:new("settings_joystick_enabled", "data/menu/settings_joystick_enabled".. g_languageSuffix .. ".png", settings_posX+settings_menu_border, settings_posY-settings_spaceY*3-settings_menu_border, settings_text_label_sizeX*0.75, settings_text_label_sizeY));
	local radioOffLabel = Overlay:new("settings_radio1", "data/menu/radio_button_off.png", settings_posX+0.375, settings_posY-settings_spaceY*3-settings_menu_border, settings_small_button_size*0.75, settings_small_button_size);
	local radioOnLabel = Overlay:new("settings_radio2", "data/menu/radio_button_on.png", settings_posX+0.375, settings_posY-settings_spaceY*3-settings_menu_border, settings_small_button_size*0.75, settings_small_button_size);
	self.settingsMenu.joystickRadio = OverlayCheckbox:new(radioOnLabel, radioOffLabel, g_settingsJoystickEnabled, OnSettingsMenuJoystickEnabled);
	self.settingsMenu:addItem(self.settingsMenu.joystickRadio);


    -- Profile
    self.settingsMenu:addItem(Overlay:new("settings_profile", "data/menu/settings_profile".. g_languageSuffix .. ".png", settings_posX+settings_menu_border, settings_posY-settings_spaceY*4-settings_menu_border, settings_text_label_sizeX*0.75, settings_text_label_sizeY));
    local profileTable = {};
    table.insert(profileTable, string.format("Auto (%s)", getAutoGPUPerformanceClass()));
    table.insert(profileTable, "Low");
    table.insert(profileTable, "Medium");
    table.insert(profileTable, "High");
    table.insert(profileTable, "Very High");
    g_settingsDisplayProfile = getGPUPerformanceClass();
    local down = OverlayButton:new(Overlay:new("settings_resolution_down", "data/menu/small_button_left.png", settings_posX+0.375, settings_posY-settings_spaceY*4-settings_menu_border, settings_small_button_size*0.75, settings_small_button_size), OnSettingsMenuResolutionDown);
    local up = OverlayButton:new(Overlay:new("settings_resolution_up", "data/menu/small_button_right.png", settings_posX+0.63, settings_posY-settings_spaceY*4-settings_menu_border, settings_small_button_size*0.75, settings_small_button_size), OnSettingsMenuResolutionUp);
    self.settingsMenu.profileTextOp = OverlayMultiTextOption:new(profileTable, down, up, settings_textX+0.025-0.02, settings_posY-settings_spaceY*4-settings_menu_border-settings_offsetY, 0.035, Utils.getProfileClassIndex(g_settingsDisplayProfile), OnSettingsMenuGPUProfile);
    self.settingsMenu:addItem(self.settingsMenu.profileTextOp);

    -- TimeScale
    self.settingsMenu:addItem(Overlay:new("settings_time_scale", "data/menu/settings_time_scale".. g_languageSuffix .. ".png", settings_posX+settings_menu_border, settings_posY-settings_spaceY*5-settings_menu_border, settings_text_label_sizeX*0.75, settings_text_label_sizeY));
    local timeScaleTable = {};
    table.insert(timeScaleTable, "Real-Time");
    table.insert(timeScaleTable, "4x");
    table.insert(timeScaleTable, "16x");
    table.insert(timeScaleTable, "32x");
    table.insert(timeScaleTable, "60x");

    local down = OverlayButton:new(Overlay:new("settings_resolution_down", "data/menu/small_button_left.png", settings_posX+0.375, settings_posY-settings_spaceY*5-settings_menu_border, settings_small_button_size*0.75, settings_small_button_size), OnSettingsMenuResolutionDown);
    local up = OverlayButton:new(Overlay:new("settings_resolution_up", "data/menu/small_button_right.png", settings_posX+0.63, settings_posY-settings_spaceY*5-settings_menu_border, settings_small_button_size*0.75, settings_small_button_size), OnSettingsMenuResolutionUp);
    self.settingsMenu.timeScaleTextOp = OverlayMultiTextOption:new(timeScaleTable, down, up, settings_textX+0.025-0.02, settings_posY-settings_spaceY*5-settings_menu_border-settings_offsetY, 0.035, Utils.getTimeScaleIndex(g_settingsTimeScale), OnSettingsMenuTimeScale);
    self.settingsMenu:addItem(self.settingsMenu.timeScaleTextOp);


    self.settingsMenu:addItem(Overlay:new("settings_help", "data/menu/settings_help".. g_languageSuffix .. ".png", settings_posX+settings_menu_border, settings_posY-settings_spaceY*6-settings_menu_border, settings_text_label_sizeX*0.75, settings_text_label_sizeY));
	local radioOffLabel = Overlay:new("settings_radio1", "data/menu/radio_button_off.png", settings_posX+0.375, settings_posY-settings_spaceY*6-settings_menu_border, settings_small_button_size*0.75, settings_small_button_size);
	local radioOnLabel = Overlay:new("settings_radio2", "data/menu/radio_button_on.png", settings_posX+0.375, settings_posY-settings_spaceY*6-settings_menu_border, settings_small_button_size*0.75, settings_small_button_size);
	self.settingsMenu.helpRadio = OverlayCheckbox:new(radioOnLabel, radioOffLabel, g_settingsHelpText, OnSettingsMenuHelpRadio);
	self.settingsMenu:addItem(self.settingsMenu.helpRadio);

	-- Credits
    local credits_menu_posX = 0.8;
    local credits_menu_posY = 0.05;
    local credits_menu_sizeX = 0.15;
    local credits_menu_sizeY = 0.06;
    self.creditsMenu = OverlayMenu:new();
    self.creditsMenu:addItem(bgOverlay);
    self.creditsMenu:addItem(Overlay:new("credits", "data/menu/credits.png", 0.05, 0.06, 0.9, 0.9));
    self.creditsMenu:addItem(OverlayButton:new(Overlay:new("credits_back_button", "data/menu/back_button".. g_languageSuffix .. ".png", credits_menu_posX, credits_menu_posY, credits_menu_sizeX, credits_menu_sizeY), OnCreditsMenuBack));

    -- Demo
    if g_isDemo then
        self.demoEndMenu = DemoEndScreen:new();
        self.demoEndMenu:addItem(Overlay:new("demoEndScreenOverlay", "data/menu/demo_end_screen".. g_languageSuffix .. ".png", 0.0, 0.0, 1.0, 1.0));
    end;
    
    -- In Game
    self.inGameMenu = InGameMenu:new();

    self.medalsDisplay = MedalsDisplay:new();

    self.currentMenu = self.mainMenu;
end;

function GameMenuSystem:loadingScreenMode()

    stopSample(g_menuMusic);

    self.loadScreen = LoadingScreen:new(OnLoadingScreen);
    self.loadScreen:setScriptInfo(g_missionLoaderDesc.scriptFilename, g_missionLoaderDesc.scriptClass);
    self.loadScreen:setMissionInfo(g_missionLoaderDesc.id, g_missionLoaderDesc.bronze, g_missionLoaderDesc.silver, g_missionLoaderDesc.gold);
    self.loadScreen:addItem(g_missionLoaderDesc.backgroundOverlay);
    self.loadScreen:addItem(g_missionLoaderDesc.overlayBriefing);
    --self.loadScreen:addItem(g_missionLoaderDesc.overlayBriefingMedals);

    self.inGameMenu:setExtraOverlays(g_missionLoaderDesc.overlayBriefing);
    --self.inGameMenu.missionId=g_missionLoaderDesc.id;
    self.inGameMenu:setMissionId(g_missionLoaderDesc.id);

    self.currentMenu = self.loadScreen;
end;

function GameMenuSystem:quickPlayMode()
    self.quickPlayMenu:reset();
    self.currentMenu = self.quickPlayMenu;
end;

function GameMenuSystem:missionMode()
    self.missionMenu:reset();
    self.currentMenu = self.missionMenu;
end;

function GameMenuSystem:playMode()
    g_currentMission.isRunning = true;
    self.currentMenu = nil;
end;

function GameMenuSystem:settingsMode()
    self.settingsMenu.resTextOp.state = getNumOfScreenModes()-getScreenMode();
    self.settingsMenu.msaaTextOp.state = Utils.getMSAAIndex(getMSAA());
    self.settingsMenu.ansioTextOp.state = Utils.getAnsioIndex(getFilterAnisotropy());
    self.settingsMenu.profileTextOp.state = Utils.getProfileClassIndex(getGPUPerformanceClass());

    self.settingsMenu.joystickRadio:setState(g_settingsJoystickEnabled);

    self.settingsMenu.timeScaleTextOp.state = Utils.getTimeScaleIndex(g_settingsTimeScale);
    self.settingsMenu.helpRadio:setState(g_settingsHelpText);

    self.settingsMenu:reset();
    self.currentMenu = self.settingsMenu;
end;

function GameMenuSystem:creditsMode()
    self.creditsMenu:reset();
    self.currentMenu = self.creditsMenu;
end;

function GameMenuSystem:inGameMenuMode()
    self.inGameMenu:reset();
    g_currentMission.isRunning = false;
    self.currentMenu = self.inGameMenu;
end;

function GameMenuSystem:mainMenuMode()
    self.mainMenu:reset();
    self.currentMenu = self.mainMenu;
end;

function GameMenuSystem:demoEndMode()
    --self.demoEndMenu:reset();
    self.currentMenu = self.demoEndMenu;
end;

function GameMenuSystem:isMenuActive()
    return (self.currentMenu ~= nil);
end;

function GameMenuSystem:mouseEvent(posX, posY, isDown, isUp, button)
    if self.currentMenu ~= nil then
        self.currentMenu:mouseEvent(posX, posY, isDown, isUp, button);
    end;
end;

function GameMenuSystem:keyEvent(unicode, sym, modifier, isDown)
    if self.currentMenu ~= nil then
        if isDown and sym == Input.KEY_esc and self.currentMenu == self.inGameMenu then
            OnInGameMenuPlay();
        else
            self.currentMenu:keyEvent(unicode, sym, modifier, isDown);
        end;
    else
        if isDown and sym == Input.KEY_esc then
            OnInGameMenu();
        end;
    end;
end;

g_hudOverlay = nil;
g_hudOverlay1 = nil;
g_hudOverlay2 = nil;
g_hudOverlay3 = nil;

function GameMenuSystem:update(dt)
    if self.currentMenu ~= nil then
        self.currentMenu:update(dt);
    end;

    _=[[if g_hudOverlay == nil then
        local hudBasePoxX = 0.8325;
        local hudBasePoxY = 1-0.094;
        local hudBaseWidth = 0.16;
        local hudBaseHeight = 0.099-0.018;

        local hudBaseWeatherPoxX = hudBasePoxX+0.925-0.8325;
        local hudBaseWeatherPoxY = hudBasePoxY+0.004;
        local hudBaseWeatherWidth = 0.977-0.922;
        local hudBaseWeatherHeight = 0.095-0.023;

        g_hudOverlay = Overlay:new("hud_env_base", "data/missions/hud_env_base.png", hudBasePoxX, hudBasePoxY, hudBaseWidth, hudBaseHeight);
        g_hudOverlay1 = Overlay:new("hud_sun", "data/missions/hud_sun.png", hudBaseWeatherPoxX, hudBaseWeatherPoxY, hudBaseWeatherWidth, hudBaseWeatherHeight);
    end;]]

end;



function GameMenuSystem:render()

    if self.currentMenu ~= nil then
        self.currentMenu:render();
    end;

    _=[[local hudBasePoxX = 0.8325;
    local hudBasePoxY = 1-0.094;
    local hudBaseWidth = 0.16;
    local hudBaseHeight = 0.099-0.018;

    g_hudOverlay:render();
    g_hudOverlay1:render();

    setTextBold(true);
    --setTextColor(1.0, 0.0, 1.0, 1.0);
    renderText(hudBasePoxX+0.007, hudBasePoxY+0.02, 0.04, "09:86");

    --renderText(hudBasePoxX+0.058, hudBasePoxY+0.09, 0.06, "km/h");
    --renderText(hudBasePoxX+0.04, hudBasePoxY+0.06, 0.03, "7634");
    --renderText(hudBasePoxX+0.04, hudBasePoxY+0.02, 0.03, string.format("%d liter", 261));
    ]]

end;
