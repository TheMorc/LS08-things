--[[ Windmill class
    each windmill must fulfill the following scenegraph structure and naming convention
    |-windmillname
    |--|-top
       |---rotor
    The local coordinate system must be paced so that we can turn the top around its y-axis and the rotor around its z-axis
    
    wka1 = Windmill:create(wkaId);
    wka1.update(dt);
--]]

Windmill = {}

local Windmill_mt = Class(Windmill);

function Windmill:onCreate(id)
    table.insert(g_currentMission.windmills, Windmill:new(id));
    --print("created windmill, id: ", id);
end;

function Windmill:new(name)
    local instance = {};
    setmetatable(instance, Windmill_mt);

    local soundId = createAudioSource("windmillSample", "data/maps/sounds/windmill.wav", 100, 30, 0.5, 0);
    link(name, soundId);
    
    local topId = getChildAt(name, 0);
    instance.rotorId = getChildAt(topId, 0);

    -- set random rotor rotation, to avoid equivalent rotations
    local rot = math.random(0, 360)
    rotate(instance.rotorId, 0, 0, Utils.degToRad(rot));

    return instance;
end;

function Windmill:update(dt)
    -- get wind speed and direction
	--function Mission.getWindSpeed()
    -- return Mission.windspeed;
    --end
	local rotorRot = -0.002*dt;
	rotate(self.rotorId, 0, 0, rotorRot);
	
end;
