--
-- MissionStats
-- stores all stats for a mission
--
-- @author  Stefan Geiger (mailto:sgeiger@giants.ch)
-- @date  06/03/08

MissionStats = {};

local MissionStats_mt = Class(MissionStats);

function MissionStats:new()

    local instance = {};
    setmetatable(instance, MissionStats_mt);

    instance.fuelUsageTotal = g_missionLoaderDesc.stats.fuelUsage;
    instance.fuelUsageSession = 0;
    instance.seedUsageTotal = g_missionLoaderDesc.stats.seedUsage;
    instance.seedUsageSession = 0;
    instance.traveledDistanceTotal = g_missionLoaderDesc.stats.traveledDistance;
    instance.traveledDistanceSession = 0;
    instance.hectaresSeededTotal = g_missionLoaderDesc.stats.hectaresSeeded;
    instance.hectaresSeededSession = 0;
    instance.seedingDurationTotal = g_missionLoaderDesc.stats.seedingDuration;
    instance.seedingDurationSession = 0;

    instance.hectaresThreshedTotal = g_missionLoaderDesc.stats.hectaresThreshed;
    instance.hectaresThreshedSession = 0;
    instance.threshingDurationTotal = g_missionLoaderDesc.stats.threshingDuration;
    instance.threshingDurationSession = 0;
    instance.farmSiloWheatAmount = g_missionLoaderDesc.stats.farmSiloWheatAmount;
    instance.storedWheatFarmSiloTotal = g_missionLoaderDesc.stats.storedWheatFarmSilo;
    instance.storedWheatFarmSiloSession = 0;
    instance.soldWheatPortSiloTotal = g_missionLoaderDesc.stats.soldWheatPortSilo;
    instance.soldWheatPortSiloSession = 0;
    instance.revenueTotal = g_missionLoaderDesc.stats.revenue;
    instance.revenueSession = 0;
    instance.expensesTotal = g_missionLoaderDesc.stats.expenses;
    instance.expensesSession = 0;

    instance.playTime = g_missionLoaderDesc.stats.playTime;
    instance.playTimeSession = 0;

    instance.money = g_missionLoaderDesc.stats.money;
    instance.saveDate = "--.--.--";


    instance.hudPDABasePosX = 0.012;
    instance.hudPDABasePosY = 0.2;
    instance.hudPDABaseWidth = 0.35;
    instance.hudPDABaseHeight = instance.hudPDABaseWidth*(850/586)*(1/0.75);
    instance.hudPDABaseOverlay = Overlay:new("hudPDABaseOverlay", "data/missions/hud_pda_base.png", instance.hudPDABasePosX, instance.hudPDABasePosY, instance.hudPDABaseWidth, instance.hudPDABaseHeight);

    instance.pdaX = instance.hudPDABasePosX+instance.hudPDABaseWidth*0.13;
    instance.pdaY = instance.hudPDABasePosY+instance.hudPDABaseHeight-instance.hudPDABaseHeight*0.155;
    instance.pdaWidth = instance.hudPDABaseWidth*(0.875-0.13);
    instance.pdaHeight = instance.hudPDABaseHeight*(0.8-0.155);
    instance.pdaLeftSpacing = instance.pdaWidth*0.025;
    instance.pdaTopSpacing = instance.pdaHeight*0.09;

    instance.pdaCol1 = instance.pdaX + instance.pdaLeftSpacing;
    instance.pdaCol2 = instance.pdaX + instance.pdaLeftSpacing + instance.pdaWidth*0.425;
    instance.pdaCol3 = instance.pdaX + instance.pdaLeftSpacing + instance.pdaWidth*0.65;
    instance.pdaHeadRow = instance.pdaY - instance.pdaTopSpacing;
    instance.pdaFontSize = instance.pdaHeight/24;

    instance.pdaRowSpacing = instance.pdaFontSize*1.15;

    instance.showPDA = false;

    return instance;
end;

function MissionStats:delete()
    self.hudPDABaseOverlay:delete();
end;

function MissionStats:mouseEvent(posX, posY, isDown, isUp, button)
end;

function MissionStats:keyEvent(unicode, sym, modifier, isDown)
end;

function MissionStats:update(dt)

    local dtMinutes = dt/(1000*60);
    self.playTime = self.playTime + dtMinutes;
    self.playTimeSession = self.playTimeSession + dtMinutes;

    if InputBinding.hasEvent(InputBinding.TOGGLE_PDA) then
        self.showPDA = not self.showPDA;
    end;

end;

function MissionStats:draw()

    if self.showPDA then
        self.hudPDABaseOverlay:render();

        --self.testOverlay:render();

        setTextBold(true);

        setTextColor(0,0,0,1);

        renderText(self.pdaCol2, self.pdaHeadRow, self.pdaFontSize*1.125, g_i18n:getText("Session"));
        renderText(self.pdaCol3, self.pdaHeadRow, self.pdaFontSize*1.125, g_i18n:getText("Total"));
        setTextBold(false);

        renderText(self.pdaCol1, self.pdaHeadRow-self.pdaRowSpacing*1, self.pdaFontSize, g_i18n:getText("Seed") .. " [ha]");
        renderText(self.pdaCol2, self.pdaHeadRow-self.pdaRowSpacing*1, self.pdaFontSize, string.format("%d", self.hectaresSeededSession));
        renderText(self.pdaCol3, self.pdaHeadRow-self.pdaRowSpacing*1, self.pdaFontSize, string.format("%d", self.hectaresSeededTotal));
        renderText(self.pdaCol1, self.pdaHeadRow-self.pdaRowSpacing*2, self.pdaFontSize, g_i18n:getText("Seed") .. " [ha/h]");

        local str1 = "0";
        if self.seedingDurationSession ~= 0 then
            str1 = string.format("%d", self.hectaresSeededSession/(self.seedingDurationSession/60));
        end;
        local str2 = "0";
        if self.seedingDurationTotal ~= 0 then
            str2 = string.format("%d", self.hectaresSeededTotal/(self.seedingDurationTotal/60));
        end;
        renderText(self.pdaCol2, self.pdaHeadRow-self.pdaRowSpacing*2, self.pdaFontSize, str1);
        renderText(self.pdaCol3, self.pdaHeadRow-self.pdaRowSpacing*2, self.pdaFontSize, str2);
        renderText(self.pdaCol1, self.pdaHeadRow-self.pdaRowSpacing*3, self.pdaFontSize, g_i18n:getText("Seeds") .. " [l]");
        renderText(self.pdaCol2, self.pdaHeadRow-self.pdaRowSpacing*3, self.pdaFontSize, string.format("%d", self.seedUsageSession));
        renderText(self.pdaCol3, self.pdaHeadRow-self.pdaRowSpacing*3, self.pdaFontSize, string.format("%d", self.seedUsageTotal));

        renderText(self.pdaCol1, self.pdaHeadRow-self.pdaRowSpacing*5, self.pdaFontSize, g_i18n:getText("Threshing") .. " [ha]");
        renderText(self.pdaCol2, self.pdaHeadRow-self.pdaRowSpacing*5, self.pdaFontSize, string.format("%d", self.hectaresThreshedSession));
        renderText(self.pdaCol3, self.pdaHeadRow-self.pdaRowSpacing*5, self.pdaFontSize, string.format("%d", self.hectaresThreshedTotal));
        renderText(self.pdaCol1, self.pdaHeadRow-self.pdaRowSpacing*6, self.pdaFontSize, g_i18n:getText("Threshing") .. " [ha/h]");

        local str3 = "0";
        if self.threshingDurationSession ~= 0 then
            str3 = string.format("%d", self.hectaresThreshedSession/(self.threshingDurationSession/60));
        end;
        local str4 = "0";
        if self.threshingDurationTotal ~= 0 then
            str4 = string.format("%d", self.hectaresThreshedTotal/(self.threshingDurationTotal/60));
        end;
        renderText(self.pdaCol2, self.pdaHeadRow-self.pdaRowSpacing*6, self.pdaFontSize, str3);
        renderText(self.pdaCol3, self.pdaHeadRow-self.pdaRowSpacing*6, self.pdaFontSize, str4);
        renderText(self.pdaCol1, self.pdaHeadRow-self.pdaRowSpacing*7, self.pdaFontSize, g_i18n:getText("Corn_storage") .. " [l]");
        --renderText(self.pdaCol2, self.pdaHeadRow-self.pdaRowSpacing*7, self.pdaFontSize, string.format("%d", self.storedWheatFarmSiloSession));
        renderText(self.pdaCol3, self.pdaHeadRow-self.pdaRowSpacing*7, self.pdaFontSize, string.format("%d", self.farmSiloWheatAmount)); --self.storedWheatFarmSiloTotal));
        renderText(self.pdaCol1, self.pdaHeadRow-self.pdaRowSpacing*8, self.pdaFontSize, g_i18n:getText("Corn_sold") .. " [l]");
        renderText(self.pdaCol2, self.pdaHeadRow-self.pdaRowSpacing*8, self.pdaFontSize, string.format("%d", self.soldWheatPortSiloSession));
        renderText(self.pdaCol3, self.pdaHeadRow-self.pdaRowSpacing*8, self.pdaFontSize, string.format("%d", self.soldWheatPortSiloTotal));

        renderText(self.pdaCol1, self.pdaHeadRow-self.pdaRowSpacing*10, self.pdaFontSize, g_i18n:getText("Fuel") .. " [l]");
        renderText(self.pdaCol2, self.pdaHeadRow-self.pdaRowSpacing*10, self.pdaFontSize, string.format("%d", self.fuelUsageSession));
        renderText(self.pdaCol3, self.pdaHeadRow-self.pdaRowSpacing*10, self.pdaFontSize, string.format("%d", self.fuelUsageTotal));
        renderText(self.pdaCol1, self.pdaHeadRow-self.pdaRowSpacing*11, self.pdaFontSize, g_i18n:getText("Fuel") .." [l/km]");

        local str5 = "0";
        if self.traveledDistanceSession ~= 0 then
            str5 = string.format("%d", self.fuelUsageSession/self.traveledDistanceSession);
        end;
        local str6 = "0";
        if self.traveledDistanceTotal ~= 0 then
            str6 = string.format("%d", self.fuelUsageTotal/self.traveledDistanceTotal);
        end;
        renderText(self.pdaCol2, self.pdaHeadRow-self.pdaRowSpacing*11, self.pdaFontSize, str5);
        renderText(self.pdaCol3, self.pdaHeadRow-self.pdaRowSpacing*11, self.pdaFontSize, str6);
        renderText(self.pdaCol1, self.pdaHeadRow-self.pdaRowSpacing*12, self.pdaFontSize, g_i18n:getText("Distance") .. " [km]");
        renderText(self.pdaCol2, self.pdaHeadRow-self.pdaRowSpacing*12, self.pdaFontSize, string.format("%d", self.traveledDistanceSession));
        renderText(self.pdaCol3, self.pdaHeadRow-self.pdaRowSpacing*12, self.pdaFontSize, string.format("%d", self.traveledDistanceTotal));

        renderText(self.pdaCol1, self.pdaHeadRow-self.pdaRowSpacing*14, self.pdaFontSize, g_i18n:getText("Revenue") .. " [€]");
        renderText(self.pdaCol2, self.pdaHeadRow-self.pdaRowSpacing*14, self.pdaFontSize, string.format("%d", self.revenueSession));
        renderText(self.pdaCol3, self.pdaHeadRow-self.pdaRowSpacing*14, self.pdaFontSize, string.format("%d", self.revenueTotal));
        renderText(self.pdaCol1, self.pdaHeadRow-self.pdaRowSpacing*15, self.pdaFontSize, g_i18n:getText("Expenses") .. " [€]");
        renderText(self.pdaCol2, self.pdaHeadRow-self.pdaRowSpacing*15, self.pdaFontSize, string.format("%d", self.expensesSession));
        renderText(self.pdaCol3, self.pdaHeadRow-self.pdaRowSpacing*15, self.pdaFontSize, string.format("%d", self.expensesTotal));
        renderText(self.pdaCol1, self.pdaHeadRow-self.pdaRowSpacing*16, self.pdaFontSize, g_i18n:getText("Profit") .. " [€]");
        renderText(self.pdaCol2, self.pdaHeadRow-self.pdaRowSpacing*16, self.pdaFontSize, string.format("%d", self.revenueSession-self.expensesSession));
        renderText(self.pdaCol3, self.pdaHeadRow-self.pdaRowSpacing*16, self.pdaFontSize, string.format("%d", self.revenueTotal-self.expensesTotal));

        local playTimeHoursF = self.playTime/60+0.0001;
        local playTimeHours = math.floor(playTimeHoursF);
        local playTimeMinutes = math.floor((playTimeHoursF-playTimeHours)*60);

        local playTimeSessionHoursF = self.playTimeSession/60+0.0001;
        local playTimeSessionHours = math.floor(playTimeSessionHoursF);
        local playTimeSessionMinutes = math.floor((playTimeSessionHoursF-playTimeSessionHours)*60);
        renderText(self.pdaCol1, self.pdaHeadRow-self.pdaRowSpacing*18, self.pdaFontSize, g_i18n:getText("Duration"));
        renderText(self.pdaCol2, self.pdaHeadRow-self.pdaRowSpacing*18, self.pdaFontSize, string.format("%02d:%02d", playTimeSessionHours, playTimeSessionMinutes));
        renderText(self.pdaCol3, self.pdaHeadRow-self.pdaRowSpacing*18, self.pdaFontSize, string.format("%02d:%02d", playTimeHours, playTimeMinutes));

        setTextColor(1,1,1,1);

    end;

end;
