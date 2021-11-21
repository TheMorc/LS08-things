--LS2008MP Settings

--Server IP
MPip = "176.101.178.133"

--Server port
MPport = 2008

--Player Name
MPplayerName = "Player"

--Random numbers on end of your name
MPplayerNameRndNums = false

--Max player limit
MPplayerLimit = 10

--Render text on top
MPrenderDebugText = false

--Use the new LS2008 logo
MPuseNewLogo = true

--Chat key binding (either ASCII key numbers or look in InputBindings.xml or /shared/scripts/foundation/input.lua)
MPchatKey = Input.KEY_t

--Main menu buttons
MPclientButtonPath = "data/menu/MP_client.png"
MPserverButtonPath = "data/menu/MP_server.png"
MPmainMenuButtonsText = false

--if you want to use generic buttons in the main menu instead of the stock game themed buttons, remove those two "--" comment symbols in front of lines below
--and also you can comment the three lines above if you want, it's not necessary
--MPclientButtonPath = "data/missions/hud_env_base.png"
--MPserverButtonPath = "data/missions/hud_env_base.png"
--MPmainMenuButtonsText = true

--LS2008MP translatable strings
MPmenuPlayerText = "Player name"
MPmenuIPText = "  IP address"
MPmenuPortText = "Port number"
MPmenuWaitText = "Wait.."
MPmenuLimitText = " Player limit"
MPsyncingDataText = "Syncing game data with %s\n          Please wait..."
MPmenuClientButton = "Join"
MPmenuServerButton = "Host"
MPplayerListSitting1 = "%s sitting" --used for vehicles that for some reason lack the <name> xml element
MPplayerListSitting2 = "%s sitting in %s"