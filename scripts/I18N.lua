I18N = {};

local I18N_mt = Class(I18N);

function I18N:new()

    local instance = {};
    setmetatable(instance, I18N_mt);
    instance:load();

    return instance;

end;

function I18N:load()

    self.texts = {};
    local xmlFile = loadXMLFile("TempConfig", "data/i18n"..g_languageSuffix..".xml");

    local textI = 0;
    while true do
        local key = string.format("i18n.texts.text(%d)", textI);
        local name = getXMLString(xmlFile, key.."#name");
        local text = getXMLString(xmlFile, key.."#text");
        if name == nil or text == nil then
            break;
        end;
        if self.texts[name] ~= nil then
            print("Warning: duplicate text in i18n"..g_languageSuffix..".xml. Ignoring previous defintion.");
        end;
        self.texts[name] = text;
        textI = textI+1;
    end;

    delete(xmlFile);

end;

function I18N:getText(name)

    local ret = self.texts[name];
    if ret == nil then
        ret = "Missing "..name.." in i18n"..g_languageSuffix..".xml";
    end;
    return ret;

end;
