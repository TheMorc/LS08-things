
-- Main Menu

function OnMainMenuQuickPlay()

    gameMenuSystem:quickPlayMode();

end;

function OnMainMenuMission()

    gameMenuSystem:missionMode();

end;

function OnMainMenuSettings()

	gameMenuSystem:settingsMode();

end;

function OnMainMenuCredits()
	gameMenuSystem:creditsMode();
end;

function OnMainMenuQuit()

    if g_isDemo then
        gameMenuSystem:demoEndMode();
    else 
        requestExit();
    end;
    
end;

-- Loading Screen
function OnLoadingScreen(scriptFilename, scriptClass, missionId, bronzeTime, silverTime, goldTime)

    --print("OnLoadingScreen", bronzeTime, " ", silverTime, " ", goldTime);

    source(scriptFilename);

    local callString = "g_currentMission = " .. scriptClass .. ":new();";
    loadstring(callString)();

    g_currentMission:setMissionInfo(missionId, bronzeTime, silverTime, goldTime);

    g_currentMission:load();

    --gameMenuSystem:playMode();
    --setShowMouseCursor(false);

end;

function OnLoadingScreenFinish()
    gameMenuSystem.currentMenu:delete();
    gameMenuSystem:playMode();
    setShowMouseCursor(false);
    --g_currentMission.isRunning = true;
end;

function OnInGameMenuRestart()
    g_currentMission:delete();
    gameMenuSystem:loadingScreenMode()
end;

function OnInGameMenuSave()
    --gameMenuSystem.quickPlayMenu:saveSelectedGame();
    gameMenuSystem.inGameMenu.doSaveGame = true;
end;

-- Setings Menu

function OnSettingsMenuBack()

	gameMenuSystem:mainMenuMode();

end;

function OnSettingsMenuSave()
    
    setJoystickEnabled(g_settingsJoystickEnabledMenu);
    setScreenMode(g_settingsDisplayResolution);
    setMSAA(g_settingsMSAA);
    setFilterAnisotropy(g_settingsAnsio);
    setGPUPerformanceClass(g_settingsDisplayProfile);
	setXMLBool(g_savegameXML, "savegames.settings.autohelp", g_settingsHelpTextMenu);
	
	setXMLFloat(g_savegameXML, "savegames.settings#timescale", g_settingsTimeScaleMenu);
	
	saveXMLFile(g_savegameXML);
    
    --save
    restartApplication();
end;

function OnSettingsMenuDisplayResolution(state)
    local numR = getNumOfScreenModes();
    g_settingsDisplayResolution = numR-state;
    --print("state ", state, " numR ", numR, " g_settingsDisplayResolution ", g_settingsDisplayResolution);
end;

function OnSettingsMenuMSAA(state)
    g_settingsMSAA = 0;
    if state == 2 then g_settingsMSAA = 2; end;
    if state == 3 then g_settingsMSAA = 4; end;
    if state == 4 then g_settingsMSAA = 8; end;
end;

function OnSettingsMenuAniso(state)
    g_settingsAnsio = 0;
    if state == 2 then g_settingsAnsio = 2; end;
    if state == 3 then g_settingsAnsio = 4; end;
    if state == 4 then g_settingsAnsio = 8; end;
end;

function OnSettingsMenuGPUProfile(state)
    g_settingsDisplayProfile = "auto";
    if state == 2 then g_settingsDisplayProfile = "low"; end;
    if state == 3 then g_settingsDisplayProfile = "medium"; end;
    if state == 4 then g_settingsDisplayProfile = "high"; end;
    if state == 5 then g_settingsDisplayProfile = "very high"; end;
end;

function OnSettingsMenuTimeScale(state)
    g_settingsTimeScaleMenu = 1;
    if state == 2 then g_settingsTimeScaleMenu = 4; end;
    if state == 3 then g_settingsTimeScaleMenu = 16; end;
    if state == 4 then g_settingsTimeScaleMenu = 32; end;
    if state == 5 then g_settingsTimeScaleMenu = 60; end;
end;

function OnSettingsMenuHelpRadio(state)
    g_settingsHelpTextMenu = state;
end;

function OnSettingsMenuJoystickEnabled(state)
    g_settingsJoystickEnabledMenu = state;
end;

-- Credits Menu

function OnCreditsMenuBack()
	gameMenuSystem:mainMenuMode();
end;

-- Activate Ingame Menu
function OnInGameMenu()
    gameMenuSystem:inGameMenuMode();
    setShowMouseCursor(true);
end;

-- Ingame Menu
function OnInGameMenuPlay()

    gameMenuSystem:playMode();
    setShowMouseCursor(false);

end;

function OnInGameMenuSettings()

end;

function OnInGameMenuMenu()

    local isFreePlayMission = g_currentMission.isFreePlayMission;

    g_currentMission:delete();

    if isFreePlayMission then
        gameMenuSystem:mainMenuMode();
    else
        gameMenuSystem:missionMode();
    end;
    setShowMouseCursor(true);

    playSample(g_menuMusic, 0, 1, 0);

end;

-- Mission Menu
function OnMissionMenuScrollUp()
    gameMenuSystem.missionMenu:setSelectedIndex(gameMenuSystem.missionMenu.selectedIndex-1);
end;

function OnMissionMenuScrollDown()
    gameMenuSystem.missionMenu:setSelectedIndex(gameMenuSystem.missionMenu.selectedIndex+1);
end;

function OnMissionMenuBack()
	gameMenuSystem:mainMenuMode();
end;

function OnMissionMenuPlay()
	gameMenuSystem.missionMenu:startSelectedMission();
end;

-- Quick Play Menu

function OnQuickPlayMenuBack()
	gameMenuSystem:mainMenuMode();
end;

function OnQuickPlayMenuPlay()
	gameMenuSystem.quickPlayMenu:startSelectedGame();
end;

function OnQuickPlayMenuDelete()
	gameMenuSystem.quickPlayMenu:deleteSelectedGame();
end;

function OnQuickPlayMenuResetVehicles()
    gameMenuSystem.quickPlayMenu:resetVehiclesOfSelectedGame();
end;

function OnQuickPlayMenuScrollUp()
    gameMenuSystem.quickPlayMenu:setSelectedIndex(gameMenuSystem.quickPlayMenu.selectedIndex-1);
end;

function OnQuickPlayMenuScrollDown()
    gameMenuSystem.quickPlayMenu:setSelectedIndex(gameMenuSystem.quickPlayMenu.selectedIndex+1);
end;