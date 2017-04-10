local KoreanChamps = {"Ahri", "Brand", "Blitzcrank", "Darius", "Diana", "KogMaw"}
if not table.contains(KoreanChamps, myHero.charName)  then print("" ..myHero.charName.. " Is Not (Yet) Supported") return end

local KoreanMechanics = MenuElement({type = MENU, id = "KoreanMechanics", name = "Korean Mechanics Reborn | " ..myHero.charName, leftIcon = "http://4.1m.yt/d5VbDBm.png"})
KoreanMechanics:MenuElement({type = MENU, id = "Combo", name = "Korean Combo Settings"})
KoreanMechanics:MenuElement({type = MENU, id = "Harass", name = "Korean Harass Settings"})
KoreanMechanics:MenuElement({type = MENU, id = "Clear", name = "Clear Settings"})
KoreanMechanics:MenuElement({type = MENU, id = "Draw", name = "Drawing Settings"})
KoreanMechanics:MenuElement({type = MENU, id = "AS", name = "CastDelay Settings"})

local function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end

function KoreanTarget(range)
	if _G.GOS then
		return GOS:GetTarget(range)
	elseif _G.SDK and _G.SDK.Orbwalker then
		return _G.SDK.TargetSelector:GetTarget(range)
	end
end

local _AllyHeroes
local function GetAllyHeroes()
	if _AllyHeroes then return _AllyHeroes end
	_AllyHeroes = {}
	for i = 1, Game.HeroCount() do
		local unit = Game.Hero(i)
		if unit.isAlly then
			table.insert(_AllyHeroes, unit)
		end
	end
	return _AllyHeroes
end

local _EnemyHeroes
local function GetEnemyHeroes()
	if _EnemyHeroes then return _EnemyHeroes end
	_EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local unit = Game.Hero(i)
		if unit.isEnemy then
			table.insert(_EnemyHeroes, unit)
		end
	end
	return _EnemyHeroes
end

local function GetPercentHP(unit)
	if type(unit) ~= "userdata" then error("{GetPercentHP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	return 100*unit.health/unit.maxHealth
end

local function GetPercentMP(unit)
	if type(unit) ~= "userdata" then error("{GetPercentMP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	return 100*unit.mana/unit.maxMana
end

local function GetBuffData(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return buff
		end
	end
	return {type = 0, name = "", startTime = 0, expireTime = 0, duration = 0, stacks = 0, count = 0}--
end

local function GetBuffs(unit)
	local t = {}
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.count > 0 then
			table.insert(t, buff)
		end
	end
	return t
end

local sqrt = math.sqrt 
local function GetDistance(p1,p2)
	return sqrt((p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y) + (p2.z - p1.z)*(p2.z - p1.z))
end

local function GetDistance2D(p1,p2)
	return sqrt((p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y))
end

local function GetMode()
	if _G.EOWLoaded then
		return EOW:Mode()
	elseif _G.GOS then
		return GOS.GetMode()
	elseif _G.SDK and _G.SDK.Orbwalker then
		if _G.SDK.Orbwalker and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
			return "Combo"
		elseif _G.SDK.Orbwalker and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
			return "Harass"
		elseif _G.SDK.Orbwalker and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] or _G.SDK.Orbwalker and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
			return "LaneClear"
		elseif _G.SDK.Orbwalker and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
			return "LastHit"
		end
	end
end

local function HasBuff(unit, buffname)
	if type(unit) ~= "userdata" then error("{HasBuff}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	if type(buffname) ~= "string" then error("{HasBuff}: bad argument #2 (string expected, got "..type(buffname)..")") end
	for i, buff in pairs(GetBuffs(unit)) do
		if buff.name == buffname then 
			return true
		end
	end
	return false
end

local function IsImmobileTarget(unit)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.name == "recall") and buff.count > 0 then
			return true
		end
	end
	return false	
end

local ItemHotKey = {
    [ITEM_1] = HK_ITEM_1,
    [ITEM_2] = HK_ITEM_2,
    [ITEM_3] = HK_ITEM_3,
    [ITEM_4] = HK_ITEM_4,
    [ITEM_5] = HK_ITEM_5,
    [ITEM_6] = HK_ITEM_6,
}

local function GetItemSlot(unit, id)
  for i = ITEM_1, ITEM_7 do
    if unit:GetItemData(i).itemID == id then
      return i
    end
  end
  return 0 
end

local function IsImmune(unit)
	if type(unit) ~= "userdata" then error("{IsImmune}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	for i, buff in pairs(GetBuffs(unit)) do
		if (buff.name == "KindredRNoDeathBuff" or buff.name == "UndyingRage") and GetPercentHP(unit) <= 10 then
			return true
		end
		if buff.name == "VladimirSanguinePool" or buff.name == "JudicatorIntervention" then 
			return true
		end
	end
	return false
end

function IsValidTarget(unit, range, onScreen)
    local range = range or 20000
    
    return unit and unit.distance <= range and not unit.dead and unit.valid and unit.visible and unit.isTargetable and not (onScreen and not unit.pos2D.onScreen)
end

local _OnVision = {}
function OnVision(unit)
	if _OnVision[unit.networkID] == nil then _OnVision[unit.networkID] = {state = unit.visible , tick = GetTickCount(), pos = unit.pos} end
	if _OnVision[unit.networkID].state == true and not unit.visible then _OnVision[unit.networkID].state = false _OnVision[unit.networkID].tick = GetTickCount() end
	if _OnVision[unit.networkID].state == false and unit.visible then _OnVision[unit.networkID].state = true _OnVision[unit.networkID].tick = GetTickCount() end
	return _OnVision[unit.networkID]
end
Callback.Add("Tick", function() OnVisionF() end)
local visionTick = GetTickCount()
function OnVisionF()
	if GetTickCount() - visionTick > 100 then
		for i,v in pairs(GetEnemyHeroes()) do
			OnVision(v)
		end
	end
end

local _OnWaypoint = {}
function OnWaypoint(unit)
	if _OnWaypoint[unit.networkID] == nil then _OnWaypoint[unit.networkID] = {pos = unit.posTo , speed = unit.ms, time = Game.Timer()} end
	if _OnWaypoint[unit.networkID].pos ~= unit.posTo then 
		-- print("OnWayPoint:"..unit.charName.." | "..math.floor(Game.Timer()))
		_OnWaypoint[unit.networkID] = {startPos = unit.pos, pos = unit.posTo , speed = unit.ms, time = Game.Timer()}
			DelayAction(function()
				local time = (Game.Timer() - _OnWaypoint[unit.networkID].time)
				local speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
				if speed > 1250 and time > 0 and unit.posTo == _OnWaypoint[unit.networkID].pos and GetDistance(unit.pos,_OnWaypoint[unit.networkID].pos) > 200 then
					_OnWaypoint[unit.networkID].speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
					-- print("OnDash: "..unit.charName)
				end
			end,0.05)
	end
	return _OnWaypoint[unit.networkID]
end

local function GetPred(unit,speed,delay)
	local speed = speed or math.huge
	local delay = delay or 0.25
	local unitSpeed = unit.ms
	if OnWaypoint(unit).speed > unitSpeed then unitSpeed = OnWaypoint(unit).speed end
	if OnVision(unit).state == false then
		local unitPos = unit.pos + Vector(unit.pos,unit.posTo):Normalized() * ((GetTickCount() - OnVision(unit).tick)/1000 * unitSpeed)
		local predPos = unitPos + Vector(unit.pos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(myHero.pos,unitPos)/speed)))
		if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
		return predPos
	else
		if unitSpeed > unit.ms then
			local predPos = unit.pos + Vector(OnWaypoint(unit).startPos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(myHero.pos,unit.pos)/speed)))
			if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
			return predPos
		elseif IsImmobileTarget(unit) then
			return unit.pos
		else
			return unit:GetPrediction(speed,delay)
		end
	end
end

local function GetEnemyMinions(range)
    EnemyMinions = {}
    for i = 1, Game.MinionCount() do
        local Minion = Game.Minion(i)
        if Minion.isEnemy and IsValidTarget(Minion, range, false, myHero) and not Minion.dead then
            table.insert(EnemyMinions, Minion)
        end
    end
    return EnemyMinions
end

local function MinionsAround(pos, range, team)
	local Count = 0
	for i = 1, Game.MinionCount() do
		local m = Game.Minion(i)
		if m and m.team == team and not m.dead and GetDistance(pos, m.pos) <= range then
			Count = Count + 1
		end
	end
	return Count
end

local _EnemyHeroes
local function GetEnemyHeroes()
    if _EnemyHeroes then return _EnemyHeroes end
    _EnemyHeroes = {}
    for i = 1, Game.HeroCount() do
        local unit = Game.Hero(i)
        if unit.isEnemy then
            _EnemyHeroes[#_EnemyHeroes + 1] = unit
        end
    end
    return _EnemyHeroes
end

 function GetEnemiesInRange(range, unit)
    local unit = unit or myHero
    local Enemies = GetEnemyHeroes()
    local inRange = {}

    for i = 1, #Enemies do
        local Enemy = Enemies[i]

        if Enemy.distance <= range then
            inRange[#inRange + 1] = Enemy
        end
    end

    return inRange
end

local function GetRlvl()
local lvl = myHero:GetSpellData(_R).level
	if lvl >= 1 then
		return (lvl + 1)
elseif lvl == nil then return 1
	end
end

require "Collision"
require "DamageLib"

_G.Spells = { 
        ["Ahri"] = {
            ["targetvalue"] = 1000,
            ["AhriOrbofDeception"] = {delay = 0.25, range = 875, speed = 1700, width = 100, skillshot = true, collision = false},
            ["AhriFoxFire"] = {delay = 0.25, range = 700, speed = math.huge, skillshot = false, collision = false},
            ["AhriSeduce"] = {delay = 0.25, range = 950, speed = 1600, width = 65, skillshot = true, collision = true},
            ["AhriTumble"] = {delay = 0, range = 600, skillshot = false, collision = false}},

        ["Darius"] = {
            ["targetvalue"] = 1000,
            ["DariusCleave"] = {delay = 0.75, range = 425, speed = 2200, width = 450, skillshot = false, collision = false},
            ["DariusNoxianTacticsONH"] = {delay = 0.25, range = 350, speed = math.huge, skillshot = false, collision = false},
            ["DariusAxeGrabCone"] = {range = 535, delay = 0.32, speed = 1500, width = 125, skillshot = true, collision = false}, 
            ["DariusExecute"] = {delay = 0.85, range = 460, speed = 3200, skillshot = false, collision = false}},

        ["Diana"] = {
            ["targetvalue"] = 1000,    
            ["DianaArc"] = {delay = 0.25, range = 875, speed = 1500, width = 130, skillshot = true, collision = false},
            ["DianaOrbs"] = {delay = 0.25, range = 250, speed = math.huge, skillshot = false, collision = false},
            ["DianaVortex"] = {delay = 0.25, range = 250, speed = math.huge, skillshot = false, collision = false},
            ["DianaTeleport"] = {delay = 0, range = 825, skillshot = false, collision = false}},

        ["KogMaw"] = {
            ["targetvalue"] = 2000,        
            ["KogMawQ"] = {delay = 0.25, range = 1175, speed = 1600, width = 80, skillshot = true, collision = true},
            ["KogMawBioArcaneBarrage"] = {delay = 0.25, range = 700, skillshot = false, collision = false},
            ["KogMawVoidOoze"] = {delay = 0.25, range = 1200, speed = 1000, width = 120, skillshot = true, collision = false},
            ["KogMawLivingArtillery"] = {delay = 1, range = 2000, speed = math.huge, skillshot = true, collision = false}},

        ["Blitzcrank"] = {
            ["targetvalue"] = 1000,
            ["RocketGrab"] = {delay = 0.25, range = 925, speed = 1800, width = 100, skillshot = true, collision = true},
            ["Overdrive"] = {delay = 0.25, range = math.huge, skillshot = false, collision = false},
            ["PowerFist"] = {delay = 0.25, range = 300, speed = math.huge, skillshot = false, collision = false},
            ["StaticField"] = {delay = 0.25, range = 600, speed = math.huge, skillshot = false, collision = false}},

        ["Brand"] = {
            ["targetvalue"] = 1100,
            ["BrandQ"] = {delay = 0.25, range = 1050, speed = 1400, width = 75, skillshot = true, collision = true},
            ["BrandW"] = {delay = 0.625, range = 900, speed = math.huge, width = 187, skillshot = true, collision = false},
            ["BrandE"] = {delay = 0.25, range = 625, speed = math.huge, skillshot = false, collision = false},
            ["BrandR"] = {delay = 0.25, range = 750, speed = math.huge, skillshot = false, collision = false}}

}
--KoreanCast
function KoreanCanCast(spell)
local target = KoreanTarget(Spells[myHero.charName]["targetvalue"])
local spellname = Spells[myHero.charName][tostring(myHero:GetSpellData(spell).name)]
    if target == nil then return end
    local Range = spellname.range * 0.95 or math.huge
    if spellname.skillshot == true and spellname.collision == true then 
        if IsValidTarget(target, Range , true) then 
            if not spellname.spellColl:__GetCollision(myHero, target, 5) then
                return true
            end
        end
    end
    if spellname.collision == false then
        return IsValidTarget(target, Range, true) 
    end
end 

function KoreanPred(target, spell)
local spellname = Spells[myHero.charName][tostring(myHero:GetSpellData(spell).name)]
local pos = GetPred(target, spellname.speed, spellname.delay + Game.Latency()/1000)
    if pos and GetDistance(pos,myHero.pos) < spellname.range then 
      return pos
    end
end     

local function BlockMovement()
	if _G.GOS then 
		GOS.BlockMovement = true
	elseif _G.SDK and _G.SDK.Orbwalker then
		_G.SDK.Orbwalker:SetMovement(false)
	elseif _G.EOWLoaded then
		EOW:MovementsEnabled(false)
	end
end 

 local function UnblockMovement()
	if _G.GOS then
		GOS.BlockMovement = false 
	elseif _G.SDK and _G.SDK.Orbwalker then
		_G.SDK.Orbwalker:SetMovement(true)
	elseif _G.EOWLoaded then
		EOW:MovementsEnabled(true)
	end
 end

local isKCasting = 0
function KoreanCast(spell, pos, delay)
    if pos == nil or isKCasting == 1 then return end
    isKCasting = 1
    local cursorReset = mousePos:ToScreen()
    if isKCasting == 1 then 
    	if Game.Latency() > 0 then
   			DelayAction(function()
   			    Control.SetCursorPos(pos)
   			    BlockMovement()
   			    Control.KeyDown(spell) 
   			    end,0.01) 
   			DelayAction(function() 
   			  Control.KeyUp(spell)
   			 UnblockMovement() 
   			 Control.SetCursorPos(cursorReset.x, cursorReset.y)
   			  DelayAction(function()
   			  	isKCasting = 0
   			  	end, 0.001)
   			end, (delay + Game.Latency()) / 1000)
   		end
   		if isKCasting == 1 then
   			Control.SetCursorPos(cursorReset.x, cursorReset.y)
   		end
   	end	
end

local function KoreanCast2(spell, pos, delay)
    local Cursor = Game.mousePos()
    if pos == nil then return end
        Control.SetCursorPos(pos)
        DelayAction(function() Control.KeyDown(spell) end,0.01) 
        DelayAction(function() Control.KeyUp(spell) end, (delay + Game.Latency()) / 1000) -- ˇ ˆ
end 

class "Ahri"

function Ahri:__init()
    print("Korean Mechanics Reborn | Ahri Loaded succesfully")
    self:Menu()
    Callback.Add("Draw", function() self:Draw() end)
    Callback.Add("Tick", function() self:Tick() end)
    local _AhriE = Spells["Ahri"]["AhriSeduce"]
	_AhriE.spellColl = Collision:SetSpell(_AhriE.range, _AhriE.speed, _AhriE.delay, _AhriE.width, true)
end

function Ahri:Menu()
    KoreanMechanics.Combo:MenuElement({id = "Q", name = "Use Q", value = true})
    KoreanMechanics.Combo:MenuElement({id = "W", name = "Use W", value = true})
    KoreanMechanics.Combo:MenuElement({id = "E", name = "Use E", value = true})
    KoreanMechanics.Combo:MenuElement({type = MENU, id = "RS", name = "R Settings"})
    KoreanMechanics.Combo.RS:MenuElement({id = "R", name = "Use R [?]", value = true, tooltip = "Uses Smart-R to mouse"})
    KoreanMechanics.Combo.RS:MenuElement({id = "RD", name = "Max R engage distance", value = 600, min = 300, max = 1300, step = 100})
  	KoreanMechanics.Combo.RS:MenuElement({id = "RHP", name = "Uses R when target HP%", value = 50, min = 0, max = 100, step = 1})  
	KoreanMechanics.Combo:MenuElement({type = MENU, id = "IS", name = "Ignite Settings"})
	KoreanMechanics.Combo.IS:MenuElement({id = "I", name = "Use Ignite", value = true})		
	KoreanMechanics.Combo.IS:MenuElement({id = "IMode", name = "Ignite Mode", drop = {"Killable", "Custom"}})
	KoreanMechanics.Combo.IS:MenuElement({id = "IHP", name = "[Custom] Uses Ignite when target HP%", value = 50, min = 0, max = 100, step = 1})
    KoreanMechanics.Combo:MenuElement({type = MENU, id = "MM", name = "Mana Manager"}) 
    KoreanMechanics.Combo.MM:MenuElement({id = "QMana", name = "Min Mana to Q in Combo(%)", value = 10, min = 0, max = 100, step = 1})
    KoreanMechanics.Combo.MM:MenuElement({id = "WMana", name = "Min Mana to W in Combo(%)", value = 10, min = 0, max = 100, step = 1})
    KoreanMechanics.Combo.MM:MenuElement({id = "EMana", name = "Min Mana to E in Combo(%)", value = 10, min = 0, max = 100, step = 1})
    KoreanMechanics.Combo.MM:MenuElement({id = "RMana", name = "Min Mana to R in Combo(%)", value = 10, min = 0, max = 100, step = 1})

    KoreanMechanics.Harass:MenuElement({id = "Q", name = "Use Q", value = true})
    KoreanMechanics.Harass:MenuElement({id = "W", name = "Use W", value = true})
    KoreanMechanics.Harass:MenuElement({id = "E", name = "Use E", value = true})
    KoreanMechanics.Harass:MenuElement({type = MENU, id = "MM", name = "Mana Manager"})
    KoreanMechanics.Harass.MM:MenuElement({id = "QMana", name = "Min Mana to Q in Harass(%)", value = 40, min = 0, max = 100, step = 1})
    KoreanMechanics.Harass.MM:MenuElement({id = "WMana", name = "Min Mana to W in Harass(%)", value = 40, min = 0, max = 100, step = 1})
    KoreanMechanics.Harass.MM:MenuElement({id = "EMana", name = "Min Mana to E in Harass(%)", value = 40, min = 0, max = 100, step = 1})  

    KoreanMechanics.Clear:MenuElement({id = "Q", name = "Use Q", value = true})
    KoreanMechanics.Clear:MenuElement({id = "QC", name = "Min amount of minions to Q", value = 3, min = 1, max = 7, step = 1})
    KoreanMechanics.Clear:MenuElement({id = "Mana", name = "Min Mana to Clear (%)", value = 40, min = 0, max = 100, step = 1})  

    KoreanMechanics.Draw:MenuElement({id = "Enabled", name = "Enable all Drawings", value = true})
    KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
    KoreanMechanics.Draw:MenuElement({id = "TD", name = "Draw Current Target", type = MENU})
    KoreanMechanics.Draw.TD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.TD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.TD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 

    KoreanMechanics.AS:MenuElement({id = "QAS", name = "Q Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})
    KoreanMechanics.AS:MenuElement({id = "WAS", name = "W Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})
    KoreanMechanics.AS:MenuElement({id = "EAS", name = "E Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})
    KoreanMechanics.AS:MenuElement({id = "RAS", name = "R Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})
end

function Ahri:Tick()
    if myHero.dead then return end
    target = KoreanTarget(1500)
    if GetMode() == "Combo" then
        self:Combo(target)
    elseif target and GetMode() == "Harass" then
        self:Harass(target)
    elseif GOS.GetMode() == "Clear" or GetMode() == "LaneClear" then
		self:Clear()
	end
end

function Ahri:Combo()
    if target == nil then return end	
    if KoreanMechanics.Combo.RS.R:Value() and Ready(_R) and target.distance < KoreanMechanics.Combo.RS.RD:Value() and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.RMana:Value() / 100) then
        if target.valid and not target.dead and target.health/target.maxHealth <= KoreanMechanics.Combo.RS.RHP:Value()/100 then
            KoreanCast(HK_R, Game.mousePos(), KoreanMechanics.AS.RAS:Value())
        end
    end
    if KoreanMechanics.Combo.E:Value() and Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.EMana:Value() / 100) then
        if KoreanCanCast(_E) then 
            KoreanCast(HK_E, KoreanPred(target, _E), KoreanMechanics.AS.EAS:Value())
        end
        if KoreanMechanics.Combo.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.QMana:Value() / 100) then
            if KoreanCanCast(_Q) then
                KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
            end
        end
        if KoreanMechanics.Combo.W:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.WMana:Value() / 100) then
            if KoreanCanCast(_W) then
                KoreanCast(HK_W, Game.mousePos(), KoreanMechanics.AS.WAS:Value())
            end
        end
    end
    if KoreanMechanics.Combo.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.QMana:Value() / 100) then
        if KoreanCanCast(_Q) then
            KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
        end
        if KoreanMechanics.Combo.W:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.WMana:Value() / 100) then
            if KoreanCanCast(_W) then
               KoreanCast(HK_W, Game.mousePos(), KoreanMechanics.AS.WAS:Value())
            end
        end
    end
    if KoreanMechanics.Combo.W:Value() and Ready(_W) then
        if KoreanCanCast(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.WMana:Value() / 100) then
            KoreanCast(HK_W, Game.mousePos(), KoreanMechanics.AS.WAS:Value())
        end
    end
   	if KoreanMechanics.Combo.IS.I:Value() then 
   		if KoreanMechanics.Combo.IS.IMode:Value() == 2 and myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) then
       		if IsValidTarget(target, 600, true, myHero) and target.health/target.maxHealth <= KoreanMechanics.Combo.IS.IHP:Value()/100 then
            	Control.CastSpell(HK_SUMMONER_1, target)
       		end
		elseif  KoreanMechanics.Combo.IS.IMode:Value() == 2 and myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) then
        	if IsValidTarget(target, 600, true, myHero) and target.health/target.maxHealth <= KoreanMechanics.Combo.IS.IHP:Value()/100 then
           		 Control.CastSpell(HK_SUMMONER_2, target)
       		end
		elseif  KoreanMechanics.Combo.IS.IMode:Value() == 1 and myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) and not Ready(_Q) and not Ready(_R) then
       	 	if IsValidTarget(target, 600, true, myHero) and 50+20*myHero.levelData.lvl > target.health*1.1 then
           		Control.CastSpell(HK_SUMMONER_1, target)
       	 	end
		elseif KoreanMechanics.Combo.IS.IMode:Value() == 1  and myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) and not Ready(_Q) and not Ready(_R) then
       		 if IsValidTarget(target, 600, true, myHero) and 50+20*myHero.levelData.lvl > target.health*1.1 then
           		Control.CastSpell(HK_SUMMONER_2, target)
        	end
    	end 
    end
end

function Ahri:Harass()
    if target == nil then return end	
local HarassQ = KoreanMechanics.Harass.Q:Value()
local HarassW = KoreanMechanics.Harass.W:Value() 
local HarassE = KoreanMechanics.Harass.E:Value()
local HarassQMana = KoreanMechanics.Harass.MM.QMana:Value()
local HarassWMana = KoreanMechanics.Harass.MM.WMana:Value()
local HarassEMana = KoreanMechanics.Harass.MM.EMana:Value()
	if KoreanMechanics.Harass.E:Value() and Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.EMana:Value() / 100) then
		if KoreanCanCast(_E) then
			KoreanCast(HK_E, KoreanPred(target, _E), KoreanMechanics.AS.EAS:Value())
		end
		if KoreanMechanics.Harass.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.QMana:Value() / 100) then
			if KoreanCanCast(_Q) then
				KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
			end
		end
		if KoreanMechanics.Harass.W:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.WMana:Value() / 100) then
			if KoreanCanCast(_W) then
				KoreanCast(HK_W, Game.mousePos(), KoreanMechanics.AS.WAS:Value())
			end
		end
	end
	if KoreanMechanics.Harass.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.QMana:Value() / 100) then
		if KoreanCanCast(_Q) then
			KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
		end
		if KoreanMechanics.Harass.W:Value()  and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.WMana:Value() / 100) then
			if KoreanCanCast(_W) then
				KoreanCast(HK_W, Game.mousePos(), KoreanMechanics.AS.WAS:Value())
			end
		end
	end
	if KoreanMechanics.Harass.W:Value()  and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.WMana:Value() / 100) then
		if KoreanCanCast(_W) then
			KoreanCast(HK_W, Game.mousePos(), KoreanMechanics.AS.WAS:Value())
		end
	end
end

function Ahri:Clear()
local ClearQ = KoreanMechanics.Clear.Q:Value()
local ClearMana = KoreanMechanics.Clear.Mana:Value()
local GetEnemyMinions = GetEnemyMinions()
local Minions = nil	
	if ClearQ and Ready(_Q) and (myHero.mana/myHero.maxMana >= ClearMana / 100) then
		for i = 1, #GetEnemyMinions do
		local Minions = GetEnemyMinions[i]
		local Count = MinionsAround(Minions.pos, Spells["Ahri"]["AhriOrbofDeception"].range , Minions.team)
			if Count >= KoreanMechanics.Clear.QC:Value() and Minions.distance <= Spells["Ahri"]["AhriOrbofDeception"].range then
			local Rpos = Minions:GetPrediction(Spells["Ahri"]["AhriOrbofDeception"].speed, Spells["Ahri"]["AhriOrbofDeception"].delay)
				KoreanCast(HK_Q, Rpos, KoreanMechanics.AS.QAS:Value())
			end
		end
	end
end

function Ahri:Draw()
    if not myHero.dead then
    	if KoreanMechanics.Draw.Enabled:Value() then
	        if KoreanMechanics.Draw.QD.Enabled:Value() then
	            Draw.Circle(myHero.pos, Spells["Ahri"]["AhriOrbofDeception"].range, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	        end
	        if KoreanMechanics.Draw.WD.Enabled:Value() then
	            Draw.Circle(myHero.pos, Spells["Ahri"]["AhriFoxFire"].range, KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	        end
	        if KoreanMechanics.Draw.ED.Enabled:Value() then
	            Draw.Circle(myHero.pos, Spells["Ahri"]["AhriSeduce"].range, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	        end
	        if KoreanMechanics.Draw.RD.Enabled:Value() then
	            Draw.Circle(myHero.pos, KoreanMechanics.Combo.RS.RD:Value(), KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
	        end 
	        local target = KoreanTarget()
	        if target == nil then return end
	            if target then
	            Draw.Circle(target.pos, 100, KoreanMechanics.Draw.TD.Width:Value(), KoreanMechanics.Draw.TD.Color:Value())
	        end 
	    end
    end
end

class "KogMaw"

function KogMaw:__init()
	print("Korean Mechanics Reborn | Kog'Maw Loaded succesfully")
	self:Menu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	local _KogMawQ = Spells["KogMaw"]["KogMawQ"]
	_KogMawQ.spellColl = Collision:SetSpell(_KogMawQ.range, _KogMawQ.speed, _KogMawQ.delay, _KogMawQ.width, true)	
end

function KogMaw:Menu()
	KoreanMechanics.Combo:MenuElement({id = "Q", name = "Use Q", value = true})
	KoreanMechanics.Combo:MenuElement({id = "W", name = "Use W", value = true})
	KoreanMechanics.Combo:MenuElement({id = "WR", name = "Max range to cast W (default = 750)", value = 750, min = 300, max = 1500, step = 50})
	KoreanMechanics.Combo:MenuElement({id = "E", name = "Use E", value = true})
	KoreanMechanics.Combo:MenuElement({type = MENU, id = "RS", name = "R Settings"})
	KoreanMechanics.Combo.RS:MenuElement({id = "R", name = "Use R", value = true})
	KoreanMechanics.Combo.RS:MenuElement({id = "RHP", name = "Max Enemy HP to R in Combo(%)", value = 40, min = 0, max = 100, step = 1})
	KoreanMechanics.Combo.RS:MenuElement({id = "RR", name = "Min Range to R in Combo", value = 710, min = 0, max = 1200, step = 10})
	KoreanMechanics.Combo.RS:MenuElement({id = "RST", name = "Max R Stacks", value = 3, min = 0, max = 10, step = 1})
	KoreanMechanics.Combo:MenuElement({id = "Mode", name = "Combo Mode", drop = {"AP Combo", "AD Combo"}})
	KoreanMechanics.Combo:MenuElement({type = MENU, id = "IT", name = "Items" })
	KoreanMechanics.Combo.IT:MenuElement({id = "YG", name = "Use Youmuu's Ghostblade", value = true})
	KoreanMechanics.Combo.IT:MenuElement({id = "YGR", name = "Use Youmuu's Ghostblade when target distance", value = 1500, min = 0, max = 2500, step = 100})
	KoreanMechanics.Combo.IT:MenuElement({id = "BC", name = "Use Bilgewater Cutlass", value = true})
	KoreanMechanics.Combo.IT:MenuElement({id = "BCHP", name = "Max Enemy HP to BC in Combo(%)", value = 60, min = 0, max = 100, step = 1})
	KoreanMechanics.Combo.IT:MenuElement({id = "BOTRK", name = "Use Blade Of the Ruined King", value = true})
	KoreanMechanics.Combo.IT:MenuElement({id = "BOTRKHP", name = "Max Enemy HP to BOTRK in Combo(%)", value = 60, min = 0, max = 100, step = 1})
	KoreanMechanics.Combo:MenuElement({type = MENU, id = "MM", name = "Mana Manager"})
	KoreanMechanics.Combo.MM:MenuElement({id = "QMana", name = "Min Mana to Q in Combo(%)", value = 10, min = 0, max = 100, step = 1})
	KoreanMechanics.Combo.MM:MenuElement({id = "WMana", name = "Min Mana to W in Combo(%)", value = 10, min = 0, max = 100, step = 1})
	KoreanMechanics.Combo.MM:MenuElement({id = "EMana", name = "Min Mana to E in Combo(%)", value = 10, min = 0, max = 100, step = 1})
	KoreanMechanics.Combo.MM:MenuElement({id = "RMana", name = "Min Mana to R in Combo(%)", value = 10, min = 0, max = 100, step = 1})

	KoreanMechanics.Harass:MenuElement({id = "Q", name = "Use Q", value = true})
	KoreanMechanics.Harass:MenuElement({id = "W", name = "Use W", value = true})
	KoreanMechanics.Harass:MenuElement({id = "E", name = "Use E", value = true})
	KoreanMechanics.Harass:MenuElement({type = MENU, id = "MM", name = "Mana Manager"})
	KoreanMechanics.Harass.MM:MenuElement({id = "QMana", name = "Min Mana to Q in Harass(%)", value = 40, min = 0, max = 100, step = 1})
	KoreanMechanics.Harass.MM:MenuElement({id = "WMana", name = "Min Mana to W in Harass(%)", value = 40, min = 0, max = 100, step = 1})
	KoreanMechanics.Harass.MM:MenuElement({id = "EMana", name = "Min Mana to E in Harass(%)", value = 40, min = 0, max = 100, step = 1})

	KoreanMechanics.Clear:MenuElement({id = "W", name = "Use W", value = true})
	KoreanMechanics.Clear:MenuElement({id = "WC", name = "Min amount of minions to W", value = 3, min = 1, max = 7, step = 1})
	KoreanMechanics.Clear:MenuElement({id = "R", name = "Use R [beta]", value = false})
	KoreanMechanics.Clear:MenuElement({id = "RC", name = "Min amount of minions to R", value = 3, min = 1, max = 7, step = 1})
	KoreanMechanics.Clear:MenuElement({type = MENU, id = "MM", name = "Mana Manager"})
	KoreanMechanics.Clear.MM:MenuElement({id = "WMana", name = "Min Mana to W in Clear(%)", value = 40, min = 0, max = 100, step = 1})
	KoreanMechanics.Clear.MM:MenuElement({id = "RMana", name = "Min Mana to R in Clear(%)", value = 40, min = 0, max = 100, step = 1})

	KoreanMechanics.Draw:MenuElement({id = "Enabled", name = "Enable all Drawings", value = true})
	KoreanMechanics.Draw:MenuElement({id = "CM", name = "Draw ComboMode", value = true})
    KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
    KoreanMechanics.Draw:MenuElement({id = "TD", name = "Draw Current Target", type = MENU})
    KoreanMechanics.Draw.TD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.TD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.TD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 

    KoreanMechanics.AS:MenuElement({id = "QAS", name = "Q Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})
    KoreanMechanics.AS:MenuElement({id = "WAS", name = "W Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})
    KoreanMechanics.AS:MenuElement({id = "EAS", name = "E Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})
    KoreanMechanics.AS:MenuElement({id = "RAS", name = "R Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})
end

function KogMaw:Tick()
	if myHero.dead then return end
	target = KoreanTarget(2000)
    if GetMode() == "Combo" then
        self:Combo(target)
    elseif target and GetMode() == "Harass" then
        self:Harass(target)
    elseif GOS.GetMode() == "Clear" or GetMode() == "LaneClear" then
		self:Clear()
	end
end

function KogMaw:GetKogRange()
local level = GetRlvl()
	if level == nil then return 1
	end
local Range = (({0, 1200, 1500, 1800})[level])
	return Range 
end

 function KogMaw:KogMawRStacks() --Trus credit 
	for K, Buff in pairs(GetBuffs(myHero)) do
		if Buff.name:lower() == "kogmawlivingartillerycost" then
			return Buff.count
		end
	end
	return 0
end

function KogMaw:Combo()
    if target == nil then return end	
    if KoreanMechanics.Combo.RS.R:Value() and Ready(_R) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.RMana:Value() / 100) then
		if IsValidTarget(target, 1800, true, myHero) and (target.health/target.maxHealth) <= (KoreanMechanics.Combo.RS.RHP:Value()/100) and (KogMaw:KogMawRStacks() + 1) <= KoreanMechanics.Combo.RS.RST:Value() then
			if target.distance >= KoreanMechanics.Combo.RS.RR:Value() and target.distance < 1200 then
				local Rpos = GetPred(target, Spells["KogMaw"]["KogMawLivingArtillery"].speed, Spells["KogMaw"]["KogMawLivingArtillery"].delay + Game.Latency()/1000)	
				if Rpos then 		
					KoreanCast(HK_R, Rpos, KoreanMechanics.AS.RAS:Value())
				end
			end
		end
	end
	if KoreanMechanics.Combo.IT.YG:Value() and GetItemSlot(myHero, 3142) >= 1 then 
		if Ready(GetItemSlot(myHero, 3142)) and target.distance <= KoreanMechanics.Combo.IT.YGR:Value()  then 
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3142)], target)
		end 
	end
	if KoreanMechanics.Combo.IT.BC:Value() and GetItemSlot(myHero, 3144) >= 1 then 
		if target.valid and Ready(GetItemSlot(myHero, 3144)) and target.health/target.maxHealth <= KoreanMechanics.Combo.IT.BCHP:Value()/100 and target.distance < 550 then 
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3144)], target)
		end
	end
	if KoreanMechanics.Combo.IT.BOTRK:Value() and GetItemSlot(myHero, 3153) >= 1 then 
		if Ready(GetItemSlot(myHero, 3153)) and target.health/target.maxHealth <= KoreanMechanics.Combo.IT.BOTRKHP:Value()/100 and target.distance < 550 then 
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3153)], target)
		end
	end
	if KoreanMechanics.Combo.Mode:Value() == 1 then
		if KoreanMechanics.Combo.E:Value() and Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.EMana:Value() / 100) then
			if KoreanCanCast(_E) then
				KoreanCast(HK_E, KoreanPred(target, _E), KoreanMechanics.AS.EAS:Value())
			end
			if KoreanMechanics.Combo.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.QMana:Value() / 100) then
				if KoreanCanCast(_Q) then
					KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
				end
			end
			if KoreanMechanics.Combo.W:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.WMana:Value() / 100) then
				if target.distance <= KoreanMechanics.Combo.WR:Value() then
					KoreanCast(HK_W, Game.mousePos(), KoreanMechanics.AS.WAS:Value())
				end
			end
		end
		if KoreanMechanics.Combo.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.QMana:Value() / 100) then
			if KoreanCanCast(_Q) then
				KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
			end
			if KoreanMechanics.Combo.W:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.WMana:Value() / 100) then
				if target.distance <= KoreanMechanics.Combo.WR:Value() then
					KoreanCast(HK_W, Game.mousePos(), KoreanMechanics.AS.WAS:Value())
				end
			end
		end
		if KoreanMechanics.Combo.W:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.WMana:Value() / 100) then
			if target.distance <= KoreanMechanics.Combo.WR:Value() then
				KoreanCast(HK_W, Game.mousePos(), KoreanMechanics.AS.WAS:Value())
			end
		end
	end
	if KoreanMechanics.Combo.Mode:Value() == 2 then
		if KoreanMechanics.Combo.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.QMana:Value() / 100) then
			if KoreanCanCast(_Q) then
				KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
			end
			if KoreanMechanics.Combo.W:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.WMana:Value() / 100) then
				if target.distance <= KoreanMechanics.Combo.WR:Value() then
					KoreanCast(HK_W, Game.mousePos(), KoreanMechanics.AS.WAS:Value())
				end
			end
			if KoreanMechanics.Combo.E:Value() and Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.EMana:Value() / 100) then
				if KoreanCanCast(_E) then
					KoreanCast(HK_E, KoreanPred(target, _E), KoreanMechanics.AS.EAS:Value())
				end
			end
		end
		if KoreanMechanics.Combo.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.QMana:Value() / 100) then
			if KoreanCanCast(_Q) then
				KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
			end
			if KoreanMechanics.Combo.W:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.WMana:Value() / 100) then
				if target.distance <= KoreanMechanics.Combo.WR:Value() then
					KoreanCast(HK_W, Game.mousePos(), KoreanMechanics.AS.WAS:Value())
				end
			end
			if KoreanMechanics.Combo.E:Value() and Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.EMana:Value() / 100) then
				if KoreanCanCast(_E) then
					KoreanCast(HK_E, KoreanPred(target, _E), KoreanMechanics.AS.EAS:Value())
				end
			end
		end
		if KoreanMechanics.Combo.W:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.WMana:Value() / 100) then
			if target.distance <= KoreanMechanics.Combo.WR:Value() then
				KoreanCast(HK_W, Game.mousePos(), KoreanMechanics.AS.WAS:Value())
			end
			if KoreanMechanics.Combo.E:Value() and Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.EMana:Value() / 100) then
				if KoreanCanCast(_E) then
					KoreanCast(HK_E, KoreanPred(target, _E), KoreanMechanics.AS.EAS:Value())
				end
			end
		end
		if KoreanMechanics.Combo.E:Value() and Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.EMana:Value() / 100) then
			if KoreanCanCast(_E) then
				KoreanCast(HK_E, KoreanPred(target, _E), KoreanMechanics.AS.EAS:Value())
			end
		end
	end 
end

function KogMaw:Harass()
    if target == nil then return end	
	if KoreanMechanics.Harass.E:Value() and Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.EMana:Value() / 100) then
		if KoreanCanCast(_E) then
			KoreanCast(HK_E, KoreanPred(target, _E), KoreanMechanics.AS.EAS:Value())
		end
		if KoreanMechanics.Harass.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.QMana:Value() / 100) then
			if KoreanCanCast(_Q) then
				KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
			end
		end
		if KoreanMechanics.Harass.W:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.WMana:Value() / 100) then
			if target.distance <= KoreanMechanics.Combo.WR:Value() then
				KoreanCast(HK_W, Game.mousePos(), KoreanMechanics.AS.WAS:Value())
			end
		end
	end
	if KoreanMechanics.Harass.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.QMana:Value() / 100) then
		if KoreanCanCast(_Q) then
			KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
		end
		if KoreanMechanics.Harass.W:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.WMana:Value() / 100) then
			if target.distance <= KoreanMechanics.Combo.WR:Value() then
				KoreanCast(HK_W, Game.mousePos(), KoreanMechanics.AS.WAS:Value())
			end
		end
	end
	if KoreanMechanics.Harass.W:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.WMana:Value() / 100) then
		if target.distance <= KoreanMechanics.Combo.WR:Value() then
			KoreanCast(HK_W, Game.mousePos(), KoreanMechanics.AS.WAS:Value())
		end
	end
end

function KogMaw:Clear()
local ClearW = KoreanMechanics.Clear.W:Value()
local ClearWMana = KoreanMechanics.Clear.MM.WMana:Value()
local ClearR = KoreanMechanics.Clear.R:Value()
local ClearRMana = KoreanMechanics.Clear.MM.RMana:Value()
local GetEnemyMinions = GetEnemyMinions()
local Minions = nil	
	if ClearW and Ready(_W) and (myHero.mana/myHero.maxMana >= ClearWMana / 100) then 
		for i = 1, #GetEnemyMinions do
		local Minions = GetEnemyMinions[i]
		local Count = MinionsAround(Minions.pos, Spells["KogMaw"]["KogMawBioArcaneBarrage"].range , Minions.team)
			if Count >= KoreanMechanics.Clear.WC:Value() and Minions.distance <= KoreanMechanics.Combo.WR:Value() then
				KoreanCast(HK_W, Game.mousePos(), KoreanMechanics.AS.WAS:Value())
			end
		end
	end
	if ClearR and Ready(_R) and (myHero.mana/myHero.maxMana >= ClearRMana / 100) then
		for i = 1, #GetEnemyMinions do
		local Minions = GetEnemyMinions[i]
		local Count = MinionsAround(Minions.pos, KoreanMechanics.Combo.WR:Value() , Minions.team)
			if Count >= KoreanMechanics.Clear.RC:Value() and Minions.distance <= KogMaw:GetKogRange() and Minions.distance > Spells[myHero.charName][tostring(myHero:GetSpellData(_W).name)].range and (KogMaw:KogMawRStacks() + 1) <= KoreanMechanics.Combo.RS.RST:Value() then
			local Rpos = Minions:GetPrediction(Spells["KogMaw"]["KogMawLivingArtillery"].speed, Spells["KogMaw"]["KogMawLivingArtillery"].delay)
				KoreanCast(HK_R, Rpos, KoreanMechanics.AS.RAS:Value())
			end
		end
	end
end

function KogMaw:Draw()
    if not myHero.dead then
    	if KoreanMechanics.Draw.Enabled:Value() then
	        if KoreanMechanics.Draw.QD.Enabled:Value() then
	            Draw.Circle(myHero.pos, Spells[myHero.charName][tostring(myHero:GetSpellData(_Q).name)].range, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	        end
	        if KoreanMechanics.Draw.WD.Enabled:Value() then
	            Draw.Circle(myHero.pos, KoreanMechanics.Combo.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	        end
	        if KoreanMechanics.Draw.ED.Enabled:Value() then
	            Draw.Circle(myHero.pos, Spells[myHero.charName][tostring(myHero:GetSpellData(_E).name)].range, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	        end
	        if KoreanMechanics.Draw.RD.Enabled:Value() and KogMaw:GetKogRange() > 1 then
	            Draw.Circle(myHero.pos, KogMaw:GetKogRange() , KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
	        end
	       	if KoreanMechanics.Draw.CM:Value() then
	       		local textPos = myHero.pos:To2D()
				if KoreanMechanics.Combo.Mode:Value() == 1 then
					Draw.Text("AP Combo Active", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 
				elseif KoreanMechanics.Combo.Mode:Value() == 2 then
					Draw.Text("AD Combo Active", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 
				end
			end 
	    end
    end
end

class "Diana"

function Diana:__init()
	print("Korean Mechanics Reborn | Diana Loaded succesfully")
	self:Menu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function Diana:Menu()
	KoreanMechanics.Combo:MenuElement({id = "Q", name = "Use Q", value = true})
	KoreanMechanics.Combo:MenuElement({id = "W", name = "Use W", value = true})	
	KoreanMechanics.Combo:MenuElement({id = "E", name = "Use E", value = true})
	KoreanMechanics.Combo:MenuElement({type = MENU, id = "RS", name = "R Settings"})
	KoreanMechanics.Combo.RS:MenuElement({id = "R", name = "Use R", value = true})
	KoreanMechanics.Combo.RS:MenuElement({id = "RHP", name = "Use R when target HP%", value = 70, min = 0, max = 100, step = 1})
	KoreanMechanics.Combo:MenuElement({id = "Mode", name = "ComboMode [?]", drop = {"Normal", "Korean", "Misaya [Coming Soon]"}, tooltip = "Korean Combo Uses fast R"})
	KoreanMechanics.Combo:MenuElement({type = MENU, id = "IS", name = "Ignite Settings"})
	KoreanMechanics.Combo.IS:MenuElement({id = "I", name = "Use Ignite", value = true})		
	KoreanMechanics.Combo.IS:MenuElement({id = "IMode", name = "Ignite Mode", drop = {"Killable", "Custom"}})
	KoreanMechanics.Combo.IS:MenuElement({id = "IHP", name = "[Custom] Uses Ignite when target HP%", value = 50, min = 0, max = 100, step = 1})
    KoreanMechanics.Combo:MenuElement({type = MENU, id = "MM", name = "Mana Manager"}) 
    KoreanMechanics.Combo.MM:MenuElement({id = "QMana", name = "Min Mana to Q in Combo(%)", value = 10, min = 0, max = 100, step = 1})
    KoreanMechanics.Combo.MM:MenuElement({id = "WMana", name = "Min Mana to W in Combo(%)", value = 10, min = 0, max = 100, step = 1})
    KoreanMechanics.Combo.MM:MenuElement({id = "EMana", name = "Min Mana to E in Combo(%)", value = 10, min = 0, max = 100, step = 1})
    KoreanMechanics.Combo.MM:MenuElement({id = "RMana", name = "Min Mana to R in Combo(%)", value = 10, min = 0, max = 100, step = 1})

	KoreanMechanics.Harass:MenuElement({id = "Q", name = "Use Q", value = true})
	KoreanMechanics.Harass:MenuElement({id = "W", name = "Use W", value = true})
	KoreanMechanics.Harass:MenuElement({id = "E", name = "Use E", value = true})
    KoreanMechanics.Harass:MenuElement({type = MENU, id = "MM", name = "Mana Manager"})
    KoreanMechanics.Harass.MM:MenuElement({id = "QMana", name = "Min Mana to Q in Harass(%)", value = 40, min = 0, max = 100, step = 1})
    KoreanMechanics.Harass.MM:MenuElement({id = "WMana", name = "Min Mana to W in Harass(%)", value = 40, min = 0, max = 100, step = 1})
    KoreanMechanics.Harass.MM:MenuElement({id = "EMana", name = "Min Mana to E in Harass(%)", value = 40, min = 0, max = 100, step = 1})  

    KoreanMechanics.Clear:MenuElement({id = "Q", name = "Use Q", value = true})
    KoreanMechanics.Clear:MenuElement({id = "QC", name = "Min amount of minions to Q", value = 3, min = 1, max = 7, step = 1})
    KoreanMechanics.Clear:MenuElement({id = "W", name = "Use W", value = true})
    KoreanMechanics.Clear:MenuElement({id = "WC", name = "Min amount of minions to W", value = 3, min = 1, max = 7, step = 1})
	KoreanMechanics.Clear:MenuElement({type = MENU, id = "MM", name = "Mana Manager"})
	KoreanMechanics.Clear.MM:MenuElement({id = "QMana", name = "Min Mana to Q in Clear(%)", value = 40, min = 0, max = 100, step = 1})
	KoreanMechanics.Clear.MM:MenuElement({id = "WMana", name = "Min Mana to W in Clear(%)", value = 40, min = 0, max = 100, step = 1})

	KoreanMechanics.Draw:MenuElement({id = "Enabled", name = "Enable all Drawings", value = true})
	KoreanMechanics.Draw:MenuElement({id = "CM", name = "Draw ComboMode", value = true})
    KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W activate range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
    KoreanMechanics.Draw:MenuElement({id = "TD", name = "Draw Current Target", type = MENU})
    KoreanMechanics.Draw.TD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.TD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.TD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 

    KoreanMechanics.AS:MenuElement({id = "QAS", name = "Q Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})
    KoreanMechanics.AS:MenuElement({id = "WAS", name = "W Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})
    KoreanMechanics.AS:MenuElement({id = "EAS", name = "E Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})
    KoreanMechanics.AS:MenuElement({id = "RAS", name = "R Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})
end

function Diana:Tick()
	if myHero.dead then return end
    target = KoreanTarget(1000)
    if GetMode() == "Combo" then
        self:Combo(target)
    elseif target and GetMode() == "Harass" then
        self:Harass(target)
    elseif GOS.GetMode() == "Clear" or GetMode() == "LaneClear" then
		self:Clear()
	end
end

function Diana:HaveDianaBuff(unit)
    for i = 0, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff and buff.name == "dianamoonlight" and buff.count > 0 then
            return true
        end
    end
    return false
end

function Diana:Combo()
    if target == nil then return end	
    if KoreanMechanics.Combo.W:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.WMana:Value() / 100) then
    	if KoreanCanCast(_W) then
    		KoreanCast2(HK_W, Game.mousePos(), KoreanMechanics.AS.WAS:Value())
    	end
    	if KoreanMechanics.Combo.E:Value() and Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.EMana:Value() / 100) then
    		if KoreanCanCast(_E) then
    			KoreanCast2(HK_E, Game.mousePos(), KoreanMechanics.AS.EAS:Value())
    		end
    	end
    	if KoreanMechanics.Combo.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.QMana:Value() / 100) then 
    		if KoreanCanCast(_Q) then
    			KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
    		end
    	end
    end
    if KoreanMechanics.Combo.E:Value() and Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.EMana:Value() / 100) then
    	if KoreanCanCast(_E) then
    		KoreanCast2(HK_E, Game.mousePos(), KoreanMechanics.AS.EAS:Value())
    	end
    	if KoreanMechanics.Combo.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.QMana:Value() / 100) then 
    		if KoreanCanCast(_Q) then
    			KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
    		end
    	end
    end
    if KoreanMechanics.Combo.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.QMana:Value() / 100) then 
    	if KoreanCanCast(_Q) then
    		KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
    	end
    end
    if KoreanMechanics.Combo.RS.R:Value()  and Ready(_R) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.RMana:Value() / 100) then 
    	if (target.health/target.maxHealth) <= (KoreanMechanics.Combo.RS.RHP:Value()/100) and Diana:HaveDianaBuff(target) and KoreanCanCast(_R) then
    	local pos = target.pos
    		KoreanCast(HK_R, pos, KoreanMechanics.AS.RAS:Value())
    	end
    end
    if KoreanMechanics.Combo.Mode:Value() == 2 then
    	if KoreanMechanics.Combo.RS.R:Value()  and Ready(_R) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.RMana:Value() / 100) then 
    		if (target.health/target.maxHealth) <= (KoreanMechanics.Combo.RS.RHP:Value()/100) and Diana:HaveDianaBuff(target) and KoreanCanCast(_R) then
    		local pos = target.pos
    			KoreanCast2(HK_R, pos, KoreanMechanics.AS.RAS:Value())
    		end
   		end
   		if KoreanMechanics.Combo.RS.R:Value()  and Ready(_R) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.RMana:Value() / 100) then
   			if not Ready(_Q) and (target.health/target.maxHealth) <= (KoreanMechanics.Combo.RS.RHP:Value()/100) and KoreanCanCast(_R) then
   				local pos = target.pos
   				KoreanCast2(HK_R, pos, KoreanMechanics.AS.RAS:Value())
   			end
   		end
   	end
   	if KoreanMechanics.Combo.IS.I:Value() then 
   		if KoreanMechanics.Combo.IS.IMode:Value() == 2 and myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) then
       		if IsValidTarget(target, 600, true, myHero) and target.health/target.maxHealth <= KoreanMechanics.Combo.IS.IHP:Value()	/100 then
            	Control.CastSpell(HK_SUMMONER_1, target)
       		end
		elseif  KoreanMechanics.Combo.IS.IMode:Value() == 2 and myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) then
        	if IsValidTarget(target, 600, true, myHero) and target.health/target.maxHealth <= KoreanMechanics.Combo.IS.IHP:Value()	/100 then
           		 Control.CastSpell(HK_SUMMONER_2, target)
       		end
		elseif  KoreanMechanics.Combo.IS.IMode:Value() == 1 and myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) and not Ready(_Q) and not Ready(_R) then
       	 	if IsValidTarget(target, 600, true, myHero) and 50+20*myHero.levelData.lvl > target.health*1.1 then
           		Control.CastSpell(HK_SUMMONER_1, target)
       	 	end
		elseif KoreanMechanics.Combo.IS.IMode:Value() == 1  and myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) and not Ready(_Q) and not Ready(_R) then
       		 if IsValidTarget(target, 600, true, myHero) and 50+20*myHero.levelData.lvl > target.health*1.1 then
           		Control.CastSpell(HK_SUMMONER_2, target)
        	end
    	end 
    end
end

function Diana:Harass()
    if target == nil then return end	
	if KoreanMechanics.Harass.W:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.WMana:Value() / 100) then
		if KoreanCanCast(_W) then
			KoreanCast(HK_W, Game.mousePos(), KoreanMechanics.AS.WAS:Value())
		end
		if KoreanMechanics.Harass.E:Value() and Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.EMana:Value() / 100) then
			if KoreanCanCast(_E) then
				KoreanCast(HK_E, Game.mousePos(), KoreanMechanics.AS.EAS:Value())
			end
		end
		if KoreanMechanics.Harass.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.QMana:Value() / 100) then
			if KoreanCanCast(_Q) then
				KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
			end
		end
	end
	if KoreanMechanics.Harass.E:Value() and Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.EMana:Value() / 100) then
		if KoreanCanCast(_E) then
			KoreanCast(HK_E, Game.mousePos(), KoreanMechanics.AS.EAS:Value())
		end
		if KoreanMechanics.Harass.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.QMana:Value() / 100) then
			if KoreanCanCast(_Q) then
				KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
			end
		end
	end
	if KoreanMechanics.Harass.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.QMana:Value() / 100) then
		if KoreanCanCast(_Q) then
			KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
		end
	end
end	

function Diana:Clear()
local ClearQ = KoreanMechanics.Clear.Q:Value()
local ClearW = KoreanMechanics.Clear.W:Value()
local ClearQMana = KoreanMechanics.Clear.MM.QMana:Value()
local ClearWMana = KoreanMechanics.Clear.MM.WMana:Value()
local GetEnemyMinions = GetEnemyMinions()
local Minions = nil	
	if ClearQ and Ready(_Q) and (myHero.mana/myHero.maxMana >= ClearQMana / 100) then
		for i = 1, #GetEnemyMinions do
		local Minions = GetEnemyMinions[i]
		local Count = MinionsAround(Minions.pos, Spells["Diana"]["DianaArc"].range , Minions.team)
			if Count >= KoreanMechanics.Clear.QC:Value() and Minions.distance <= Spells["Diana"]["DianaArc"].range then
			local Rpos = Minions:GetPrediction(Spells["Diana"]["DianaArc"].speed, Spells[myHero.charName]["DianaArc"].delay)
				KoreanCast(HK_Q, Rpos, KoreanMechanics.AS.QAS:Value())
			end
		end
	end
	if ClearW and Ready(_W) and (myHero.mana/myHero.maxMana >= ClearWMana / 100) then 
		for i = 1, #GetEnemyMinions do
		local Minions = GetEnemyMinions[i]
		local Count = MinionsAround(Minions.pos, Spells["Diana"]["DianaOrbs"].range , Minions.team)
			if Count >= KoreanMechanics.Clear.WC:Value() and Minions.distance <= Spells["Diana"]["DianaOrbs"].range then
				KoreanCast(HK_W, Game.mousePos(), KoreanMechanics.AS.WAS:Value())
			end
		end
	end
end

function Diana:Draw()
    if not myHero.dead then
    	if KoreanMechanics.Draw.Enabled:Value() then
	        if KoreanMechanics.Draw.QD.Enabled:Value() then
	            Draw.Circle(myHero.pos, Spells["Diana"]["DianaArc"].range, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	        end
	        if KoreanMechanics.Draw.WD.Enabled:Value() then
	            Draw.Circle(myHero.pos, Spells["Diana"]["DianaOrbs"].range, KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	        end
	        if KoreanMechanics.Draw.ED.Enabled:Value() then
	            Draw.Circle(myHero.pos, Spells["Diana"]["DianaVortex"].range, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	        end
	        if KoreanMechanics.Draw.RD.Enabled:Value() then
	            Draw.Circle(myHero.pos, Spells["Diana"]["DianaTeleport"].range, KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
	        end
	       	if KoreanMechanics.Draw.CM:Value() then
	       		local textPos = myHero.pos:To2D()
				if KoreanMechanics.Combo.Mode:Value() == 1 then
					Draw.Text("Normal Combo Active", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 
				elseif KoreanMechanics.Combo.Mode:Value() == 2 then
					Draw.Text("Korean Combo Active", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 
				end
			end 
	    end
    end
end

class "Blitzcrank"

function Blitzcrank:__init()
	print("Korean Mechanics Reborn | Blitzcrank Loaded succesfully")
	self:Menu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	local _BlitzQ = Spells["Blitzcrank"]["RocketGrab"]
	_BlitzQ.spellColl = Collision:SetSpell(_BlitzQ.range, _BlitzQ.speed, _BlitzQ.delay, _BlitzQ.width, true)
end

function Blitzcrank:Menu()

	KoreanMechanics.Combo:MenuElement({type = MENU, id = "QS", name = "Q Grab Settings"})
	KoreanMechanics.Combo.QS:MenuElement({id = "Q", name = "Use Q", value = true})
	KoreanMechanics.Combo.QS:MenuElement({id = "QR", name = "Q range limiter", value = 900, min = 0, max = 925, step = 25})
	KoreanMechanics.Combo:MenuElement({id = "W", name = "Use W", value = true})
	KoreanMechanics.Combo:MenuElement({id = "WR", name = "W when target distance", value = 1500, min = 0, max = 2500, step = 100})
	KoreanMechanics.Combo:MenuElement({id = "E", name = "Use E", value = true})
	KoreanMechanics.Combo:MenuElement({id = "R", name = "Use R", value = true})
	KoreanMechanics.Combo:MenuElement({id = "RE", name = "Min Amount of Enemy's to R", value = 2, min = 1, max = 5, step = 1})
	KoreanMechanics.Combo:MenuElement({type = MENU, id = "MM", name = "Mana Manager"}) 
	KoreanMechanics.Combo.MM:MenuElement({id = "QMana", name = "Min Mana to Q in Combo(%)", value = 10, min = 0, max = 100, step = 1})
	KoreanMechanics.Combo.MM:MenuElement({id = "WMana", name = "Min Mana to W in Combo(%)", value = 10, min = 0, max = 100, step = 1})
	KoreanMechanics.Combo.MM:MenuElement({id = "EMana", name = "Min Mana to E in Combo(%)", value = 10, min = 0, max = 100, step = 1})
	KoreanMechanics.Combo.MM:MenuElement({id = "RMana", name = "Min Mana to R in Combo(%)", value = 10, min = 0, max = 100, step = 1})

	KoreanMechanics.Harass:MenuElement({id = "Q", name = "Use Q", value = true})
	KoreanMechanics.Harass:MenuElement({id = "WE", name = "Use W", value = true})
	KoreanMechanics.Harass:MenuElement({id = "WR", name = "W when target distance", value = 1500, min = 0, max = 2500, step = 100})
	KoreanMechanics.Harass:MenuElement({id = "E", name = "Use E", value = true})
    KoreanMechanics.Harass:MenuElement({type = MENU, id = "MM", name = "Mana Manager"})
    KoreanMechanics.Harass.MM:MenuElement({id = "QMana", name = "Min Mana to Q in Harass(%)", value = 40, min = 0, max = 100, step = 1})
    KoreanMechanics.Harass.MM:MenuElement({id = "WMana", name = "Min Mana to W in Harass(%)", value = 40, min = 0, max = 100, step = 1})
    KoreanMechanics.Harass.MM:MenuElement({id = "EMana", name = "Min Mana to E in Harass(%)", value = 40, min = 0, max = 100, step = 1}) 

	KoreanMechanics.Clear:MenuElement({id = "R", name = "Use R", value = true})
	KoreanMechanics.Clear:MenuElement({id = "RC", name = "Min Amount of Minion's to R", value = 3, min = 1, max = 7, step = 1})
	KoreanMechanics.Clear:MenuElement({id = "Mana", name = "Min. Mana to WaveClear (%)", value = 40, min = 0, max = 100, step = 1})

	KoreanMechanics.Draw:MenuElement({id = "Enabled", name = "Enable all Drawings", value = true})
    KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
    KoreanMechanics.Draw:MenuElement({id = "TD", name = "Draw Current Target", type = MENU})
    KoreanMechanics.Draw.TD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.TD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.TD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 

    KoreanMechanics.AS:MenuElement({id = "QAS", name = "Q Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})
    KoreanMechanics.AS:MenuElement({id = "WAS", name = "W Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})
    KoreanMechanics.AS:MenuElement({id = "EAS", name = "E Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})
    KoreanMechanics.AS:MenuElement({id = "RAS", name = "R Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})
end

function Blitzcrank:Tick()
	if myHero.dead then return end
    target = KoreanTarget(1000)
    if GetMode() == "Combo" then
        self:Combo(target)
    elseif GetMode() == "Harass" then
        self:Harass(target)
    elseif GOS.GetMode() == "Clear" or GetMode() == "LaneClear" then
		self:Clear()
	end
end

function Blitzcrank:Combo()
    if target == nil then return end	
	if KoreanMechanics.Combo.QS.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.QMana:Value() / 100) then
		if target.distance <= KoreanMechanics.Combo.QS.QR:Value() and KoreanCanCast(_Q) then
			KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
		end
	end
	if KoreanMechanics.Combo.W:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.WMana:Value() / 100) then 
		if target.distance <= KoreanMechanics.Combo.WR:Value() and KoreanCanCast(_W) then
			KoreanCast(HK_W, Game.mousePos(), KoreanMechanics.AS.WAS:Value())
		end
		if KoreanMechanics.Combo.E:Value() and Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.EMana:Value() / 100) then 
			if KoreanCanCast(_E) then
			local pos = target.pos
				KoreanCast(HK_E, pos, KoreanMechanics.AS.EAS:Value())
			end
		end
		if KoreanMechanics.Combo.R:Value() and Ready(_R) and not Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.RMana:Value() / 100) then
			if #GetEnemiesInRange(600) >= KoreanMechanics.Combo.RE:Value() and KoreanCanCast(_R) then
								if (target:GetCollision(Spells["Blitzcrank"]["RocketGrab"].width, Spells["Blitzcrank"]["RocketGrab"].speed, Spells["Blitzcrank"]["RocketGrab"].delay) == 1 or not Ready(_Q)) then
					KoreanCast(HK_R, Game.mousePos(), KoreanMechanics.AS.RAS:Value())
				end
			end
		end
	end
	if KoreanMechanics.Combo.E:Value() and Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.EMana:Value() / 100) then 
		if KoreanCanCast(_E) then
		local pos = target.pos
			KoreanCast(HK_E, pos, KoreanMechanics.AS.EAS:Value())
		end
		if KoreanMechanics.Combo.R:Value() and Ready(_R) and not Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.RMana:Value() / 100) then
			if #GetEnemiesInRange(600) >= KoreanMechanics.Combo.RE:Value() and KoreanCanCast(_R) then
				if (target:GetCollision(Spells["Blitzcrank"]["RocketGrab"].width, Spells["Blitzcrank"]["RocketGrab"].speed, Spells["Blitzcrank"]["RocketGrab"].delay) == 1 or not Ready(_Q)) then
					KoreanCast(HK_R, Game.mousePos(), KoreanMechanics.AS.RAS:Value())
				end
			end
		end
	end
	if KoreanMechanics.Combo.R:Value() and Ready(_R) and not Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.RMana:Value() / 100) then
		if #GetEnemiesInRange(600) >= KoreanMechanics.Combo.RE:Value() and KoreanCanCast(_R) then
			if (target:GetCollision(Spells["Blitzcrank"]["RocketGrab"].width, Spells["Blitzcrank"]["RocketGrab"].speed, Spells["Blitzcrank"]["RocketGrab"].delay) == 1 or not Ready(_Q)) then
				KoreanCast(HK_R, Game.mousePos(), KoreanMechanics.AS.RAS:Value())
			end
		end
	end
end

function Blitzcrank:Harass()
    if target == nil then return end	
    if KoreanMechanics.Harass.Q:Value()and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.QMana:Value() / 100) then 
    	if target.distance <= KoreanMechanics.Combo.QS.QR:Value() and KoreanCanCast(_Q) then
    		KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
		end
	end
	if KoreanMechanics.Harass.WE:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.WMana:Value() / 100) then 
		if target.distance <= KoreanMechanics.Harass.WR:Value() and KoreanCanCast(_W) then
			KoreanCast(HK_W, Game.mousePos(), KoreanMechanics.AS.WAS:Value())
		end
	end
	if KoreanMechanics.Harass.E:Value() and Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.EMana:Value() / 100) then
		if KoreanCanCast(_E) then
			local pos = target.pos
			KoreanCast(HK_E, pos, KoreanMechanics.AS.EAS:Value())
		end
	end
end

function Blitzcrank:Clear() --Kappa
local ClearR = KoreanMechanics.Clear.R:Value()
local ClearRC = KoreanMechanics.Clear.RC:Value()
local ClearMana = KoreanMechanics.Clear.Mana:Value()
local GetEnemyMinions = GetEnemyMinions()
local Minions = nil	
	if ClearR and Ready(_R) and (myHero.mana/myHero.maxMana >= ClearMana / 100) then
		for i = 1, #GetEnemyMinions do
		local Minions = GetEnemyMinions[i]
		local Count = MinionsAround(Minions.pos, 600 , Minions.team)
			if Count >= ClearRC and not Minions.dead and Minions.distance <= 550 then 
				KoreanCast(HK_R, Game.mousePos(), KoreanMechanics.AS.RAS:Value())
			end
		end
	end	
end

function Blitzcrank:Draw()
    if not myHero.dead then
    	if KoreanMechanics.Draw.Enabled:Value() then
	        if KoreanMechanics.Draw.QD.Enabled:Value() then
	            Draw.Circle(myHero.pos, KoreanMechanics.Combo.QS.QR:Value(), KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	        end
	        if KoreanMechanics.Draw.WD.Enabled:Value() then
	            Draw.Circle(myHero.pos, KoreanMechanics.Combo.WR:Value(), KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	        end
	        if KoreanMechanics.Draw.ED.Enabled:Value() then
	            Draw.Circle(myHero.pos, Spells["Blitzcrank"]["PowerFist"].range, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	        end
	        if KoreanMechanics.Draw.RD.Enabled:Value() then
	            Draw.Circle(myHero.pos, Spells["Blitzcrank"]["StaticField"].range, KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
	        end 
	    end
    end
end

class "Brand"

function Brand:__init()
	print("Korean Mechanics Reborn | Brand Loaded succesfully")
	self:Menu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	local _BrandQ = Spells["Brand"]["BrandQ"]
	_BrandQ.spellColl = Collision:SetSpell(_BrandQ.range, _BrandQ.speed, _BrandQ.delay, _BrandQ.width, true)
end

function Brand:Menu()
	KoreanMechanics.Combo:MenuElement({id = "Q", name = "Use Q", value = true})
	KoreanMechanics.Combo:MenuElement({id = "QM", name = "Q Ablaze only", value = true})
	KoreanMechanics.Combo:MenuElement({id = "W", name = "Use W", value = true})
	KoreanMechanics.Combo:MenuElement({id = "E", name = "Use E", value = true})
	KoreanMechanics.Combo:MenuElement({type = MENU, id = "RS",  name = "R Settings"})
	KoreanMechanics.Combo.RS:MenuElement({id = "R", name = "Use R", value = true})		
	KoreanMechanics.Combo.RS:MenuElement({id = "RMode", name = "R Mode", drop = {"Killable", "Custom"}})	
	KoreanMechanics.Combo.RS:MenuElement({id = "RC", name = "Min Amount of Enemy's to R", value = 2, min = 1, max = 5, step = 1})
	KoreanMechanics.Combo.RS:MenuElement({id = "RHP", name = "[Custom] Use R when target HP%", value = 50, min = 0, max = 100, step = 1})		
	KoreanMechanics.Combo:MenuElement({type = MENU, id = "IS", name = "Ignite Settings"})
	KoreanMechanics.Combo.IS:MenuElement({id = "I", name = "Use Ignite", value = true})				
	KoreanMechanics.Combo.IS:MenuElement({id = "IMode", name = "Ignite Mode", drop = {"Killable", "Custom"}})
	KoreanMechanics.Combo.IS:MenuElement({id = "IHP", name = "[Custom] Uses Ignite when target HP%", value = 50, min = 0, max = 100, step = 1})
	KoreanMechanics.Combo:MenuElement({type = MENU, id = "MM", name = "Mana Manager"}) 
	KoreanMechanics.Combo.MM:MenuElement({id = "QMana", name = "Min Mana to Q in Combo(%)", value = 10, min = 0, max = 100, step = 1})
	KoreanMechanics.Combo.MM:MenuElement({id = "WMana", name = "Min Mana to W in Combo(%)", value = 10, min = 0, max = 100, step = 1})
	KoreanMechanics.Combo.MM:MenuElement({id = "EMana", name = "Min Mana to E in Combo(%)", value = 10, min = 0, max = 100, step = 1})
	KoreanMechanics.Combo.MM:MenuElement({id = "RMana", name = "Min Mana to R in Combo(%)", value = 10, min = 0, max = 100, step = 1})

	KoreanMechanics.Harass:MenuElement({id = "Q", name = "Use Q", value = true})
	KoreanMechanics.Harass:MenuElement({id = "QM", name = "Q Ablaze only", value = true})	
	KoreanMechanics.Harass:MenuElement({id = "W", name = "Use W", value = true})
	KoreanMechanics.Harass:MenuElement({id = "E", name = "Use E", value = true})
	KoreanMechanics.Harass:MenuElement({type = MENU, id = "MM", name = "Mana Manager"})
	KoreanMechanics.Harass.MM:MenuElement({id = "QMana", name = "Min Mana to Q in Harass(%)", value = 40, min = 0, max = 100, step = 1})
	KoreanMechanics.Harass.MM:MenuElement({id = "WMana", name = "Min Mana to W in Harass(%)", value = 40, min = 0, max = 100, step = 1})
	KoreanMechanics.Harass.MM:MenuElement({id = "EMana", name = "Min Mana to E in Harass(%)", value = 40, min = 0, max = 100, step = 1})	

	KoreanMechanics.Clear:MenuElement({id = "W", name = "Use W", value = true})
	KoreanMechanics.Clear:MenuElement({id = "WC", name = "Min Amount of Minion's to W", value = 3, min = 1, max = 7, step = 1})
	KoreanMechanics.Clear:MenuElement({id = "E", name = "Use E", value = false})
	KoreanMechanics.Clear:MenuElement({id = "Mana", name = "Min. Mana to WaveClear (%)", value = 40, min = 0, max = 100, step = 1})    

	KoreanMechanics.Draw:MenuElement({id = "Enabled", name = "Enable all Drawings", value = true})
    KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
    KoreanMechanics.Draw:MenuElement({id = "TD", name = "Draw Current Target", type = MENU})
    KoreanMechanics.Draw.TD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.TD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.TD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 

    KoreanMechanics.AS:MenuElement({id = "QAS", name = "Q Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})
    KoreanMechanics.AS:MenuElement({id = "WAS", name = "W Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})
    KoreanMechanics.AS:MenuElement({id = "EAS", name = "E Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})
    KoreanMechanics.AS:MenuElement({id = "RAS", name = "R Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})
end

function Brand:Tick()
	if myHero.dead then return end
    target = KoreanTarget(1100)
    if GetMode() == "Combo" then
        self:Combo(target)
    elseif target and GetMode() == "Harass" then
        self:Harass(target)
    elseif GOS.GetMode() == "Clear" or GetMode() == "LaneClear" then
		self:Clear()
	end
end

function Brand:HaveBrandBuff(unit)
    for i = 0, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff and buff.name == "BrandAblaze" and buff.count > 0 and Game.Timer() <  buff.expireTime then
            return buff.count
        end
    end
    return false
end


function Brand:GetBrandRdmg()
    if target == nil then return end
local lvl = GetRlvl()
    if level == nil then return 1 
    end
local AP = myHero.ap
local Rdmg = CalcMagicalDamage(myHero.target, ((0.25 * AP) + (({0, 100, 200, 300})[level])))
    return Rdmg
end 

function Brand:Combo()
    if target == nil then return end	
    if KoreanMechanics.Combo.QM:Value() then
    	if KoreanMechanics.Combo.E:Value() and Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.EMana:Value() / 100) then
    		if KoreanCanCast(_E) then
    			local pos = target.pos
    			KoreanCast(HK_E, pos, KoreanMechanics.AS.EAS:Value())
    		end
    	end
    	if KoreanMechanics.Combo.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.QMana:Value() / 100) then
    		if KoreanCanCast(_Q) and Brand:HaveBrandBuff(target) then
    			KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
    		end
    	end
    	if KoreanMechanics.Combo.W:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.WMana:Value() / 100) then
    		if KoreanCanCast(_W) then 
    			KoreanCast(HK_W, KoreanPred(target, _W), KoreanMechanics.AS.WAS:Value())
    		end
    	end
    end
    if not KoreanMechanics.Combo.QM:Value() then
    	if KoreanMechanics.Combo.E:Value() and Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.EMana:Value() / 100) then
    		if KoreanCanCast(_E) then
    		local pos = target.pos
    			KoreanCast(HK_E, pos, KoreanMechanics.AS.EAS:Value())
    		end
    		if KoreanMechanics.Combo.Q:Value() and Ready(_Q) and not KoreanCanCast(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.QMana:Value() / 100) then
    			if KoreanCanCast(_Q) then
    				KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
    			end
    		end
    		if KoreanMechanics.Combo.W:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.WMana:Value() / 100) then
    			if KoreanCanCast(_W) then 
    				KoreanCast(HK_W, KoreanPred(target, _W), KoreanMechanics.AS.WAS:Value())
    			end
    		end
    	end
    	if KoreanMechanics.Combo.W:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.WMana:Value() / 100) then
    		if KoreanCanCast(_W) then 
    			KoreanCast(HK_W, KoreanPred(target, _W), KoreanMechanics.AS.WAS:Value())
    		end
    		if KoreanMechanics.Combo.Q:Value() and Ready(_Q) and not KoreanCanCast(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.QMana:Value() / 100) then
    			if KoreanCanCast(_Q) then
    				KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
    			end
    		end
    		if KoreanMechanics.Combo.E:Value() and Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.EMana:Value() / 100) then
    			if KoreanCanCast(_E) then
    			local pos = target.pos
    				KoreanCast(HK_E, pos, KoreanMechanics.AS.EAS:Value())
    			end
    		end
    	end
    	if KoreanMechanics.Combo.Q:Value() and Ready(_Q) and not KoreanCanCast(_E) and not KoreanCanCast(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.QMana:Value() / 100) then
    		if KoreanCanCast(_Q) then
    			KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
    		end
    	end
    end
    if KoreanMechanics.Combo.RS.RMode:Value() == 1 then
    	if KoreanMechanics.Combo.RS.R:Value() and Ready(_R) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.RMana:Value()	 / 100) and #GetEnemiesInRange(1000) >= KoreanMechanics.Combo.RS.RC:Value() then
    		if KoreanCanCast(_R) and Brand:GetBrandRdmg() * 1.1 >= target.health and Brand:HaveBrandBuff(target) then
    			local pos = target.pos
    			KoreanCast(HK_R, pos, KoreanMechanics.AS.RAS:Value())
    		end
    	end
    end
    if KoreanMechanics.Combo.RS.RMode:Value() == 2 then
    	if KoreanMechanics.Combo.RS.R:Value() and Ready(_R) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.RMana:Value()	 / 100) and #GetEnemiesInRange(1000) >= KoreanMechanics.Combo.RS.RC:Value() then
    		if KoreanCanCast(_R) and target.health/target.maxHealth <= KoreanMechanics.Combo.RS.RHP:Value()/100 and Brand:HaveBrandBuff(target) then
    			local pos = target.pos
    			KoreanCast(HK_R, pos, KoreanMechanics.AS.RAS:Value())
    		end
    	end
    end
    if KoreanMechanics.Combo.IS.I:Value() then 
		if KoreanMechanics.Combo.IS.IMode:Value() == 2 and myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) then
	 		if IsValidTarget(target, 600, true, myHero) and target.health/target.maxHealth <= KoreanMechanics.Combo.IS.IHP:Value()/100 then
	      		Control.CastSpell(HK_SUMMONER_1, target)
	 		end
 		elseif  KoreanMechanics.Combo.IS.IMode:Value() == 2 and myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) then
			if IsValidTarget(target, 600, true, myHero) and target.health/target.maxHealth <= KoreanMechanics.Combo.IS.IHP:Value()/100 then
	   			Control.CastSpell(HK_SUMMONER_2, target)
			end
 		elseif  KoreanMechanics.Combo.IS.IMode:Value() == 1 and myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) and not Ready(_Q) and not Ready(_R) then
		 	if IsValidTarget(target, 600, true, myHero) and 50+20*myHero.levelData.lvl > target.health*1.1 then
	   			Control.CastSpell(HK_SUMMONER_1, target)
		 	end
 		elseif KoreanMechanics.Combo.IS.IMode:Value() == 1  and myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) and not Ready(_Q) and not Ready(_R) then
			if IsValidTarget(target, 600, true, myHero) and 50+20*myHero.levelData.lvl > target.health*1.1 then
	   		Control.CastSpell(HK_SUMMONER_2, target)
			end
	  	end 
	end
end

function Brand:Harass()
    if target == nil then return end
	if KoreanMechanics.Harass.QM:Value() then
		if KoreanMechanics.Harass.E:Value() and Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.EMana:Value() / 100) then
			if KoreanCanCast(_E) then
				KoreanCast(HK_E, KoreanPred(target, _E), KoreanMechanics.AS.EAS:Value())
			end
		end
		if KoreanMechanics.Harass.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.QMana:Value() / 100) then
			if KoreanCanCast(_Q) and Brand:HaveBrandBuff(target) then
				KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
			end
		end
		if KoreanMechanics.Harass.W:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.WMana:Value() / 100) then
			if KoreanCanCast(_W) then
				KoreanCast(HK_W, KoreanPred(target, _W), KoreanMechanics.AS.WAS:Value())
			end
		end
	end
	if not KoreanMechanics.Harass.QM:Value() then
		if KoreanMechanics.Harass.E:Value() and Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.EMana:Value() / 100) then
			if KoreanCanCast(_E) then
				KoreanCast(HK_E, KoreanPred(target, _E), KoreanMechanics.AS.EAS:Value())
			end
		end
		if KoreanMechanics.Harass.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.QMana:Value() / 100) then
			if KoreanCanCast(_Q) and not KoreanCanCast(_E) then
				KoreanCast(HK_Q, KoreanPred(target, _Q), KoreanMechanics.AS.QAS:Value())
			end
		end
		if KoreanMechanics.Harass.W:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.WMana:Value() / 100) then
			if KoreanCanCast(_W) then
				KoreanCast(HK_W, KoreanPred(target, _W), KoreanMechanics.AS.WAS:Value())
			end
		end
	end
end 

function Brand:Clear()
local ClearW = KoreanMechanics.Clear.W:Value()
local ClearE = KoreanMechanics.Clear.E:Value()
local ClearMana = KoreanMechanics.Clear.Mana:Value()
local GetEnemyMinions = GetEnemyMinions()
local Minions = nil		
	if ClearW and Ready(_W) and (myHero.mana/myHero.maxMana >= ClearMana / 100) then
		for i = 1, #GetEnemyMinions do
		local Minions = GetEnemyMinions[i]
		local Count = MinionsAround(Minions.pos, Spells["Brand"]["BrandW"].range , Minions.team)
			if Count >= KoreanMechanics.Clear.WC:Value() and Minions.distance <= Spells["Brand"]["BrandW"].range then
			local Wpos = Minions:GetPrediction(Spells["Brand"]["BrandW"].speed, Spells["Brand"]["BrandW"].delay)
				KoreanCast(HK_W, Wpos, KoreanMechanics.AS.WAS:Value())
			end
		end
	end
	if ClearE and Ready(_E) and (myHero.mana/myHero.maxMana >= ClearMana / 100) then
		for i = 1, #GetEnemyMinions do
		local Minions = GetEnemyMinions[i]
			if Minions.distance <= Spells["Brand"]["BrandE"].range and Brand:HaveBrandBuff(Minions) then
			local pos = Minions.pos 
				KoreanCast(HK_E, pos, KoreanMechanics.AS.EAS:Value())
			end
		end
	end
end


function Brand:Draw()
    if not myHero.dead then
    	if KoreanMechanics.Draw.Enabled:Value() then
	        if KoreanMechanics.Draw.QD.Enabled:Value() then
	            Draw.Circle(myHero.pos, Spells["Brand"]["BrandQ"].range, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	        end
	        if KoreanMechanics.Draw.WD.Enabled:Value() then
	            Draw.Circle(myHero.pos, Spells["Brand"]["BrandW"].range, KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	        end
	        if KoreanMechanics.Draw.ED.Enabled:Value() then
	            Draw.Circle(myHero.pos, Spells["Brand"]["BrandE"].range, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	        end
	        if KoreanMechanics.Draw.RD.Enabled:Value()  then
	            Draw.Circle(myHero.pos, Spells["Brand"]["BrandR"].range, KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
	        end
	    end
    end
end

class "Darius"

function Darius:__init()
	print("Korean Mechanics Reborn | Brand Loaded succesfully")
	self:Menu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function Darius:Menu()
	KoreanMechanics.Combo:MenuElement({id = "Q", name = "Use Q", value = true})
	KoreanMechanics.Combo:MenuElement({id = "W", name = "Use W", value = true})
	KoreanMechanics.Combo:MenuElement({id = "E", name = "Use E", value = true})
	KoreanMechanics.Combo:MenuElement({id = "R", name = "Use R [?]", value = true, tooltip = "Uses smart-R when Killable"})
	KoreanMechanics.Combo:MenuElement({type = MENU, id = "IS", name = "Ignite Settings"})
	KoreanMechanics.Combo.IS:MenuElement({id = "I", name = "Use Ignite", value = true})				
	KoreanMechanics.Combo.IS:MenuElement({id = "IMode", name = "Ignite Mode", drop = {"Killable", "Custom"}})
	KoreanMechanics.Combo.IS:MenuElement({id = "IHP", name = "[Custom] Uses Ignite when target HP%", value = 50, min = 0, max = 100, step = 1})	
	KoreanMechanics.Combo:MenuElement({type = MENU, id = "IT", name = "Items"})
	KoreanMechanics.Combo.IT:MenuElement({id = "YG", name = "Use Youmuu's Ghostblade", value = true})
	KoreanMechanics.Combo.IT:MenuElement({id = "YGR", name = "Use Ghostblade when target distance", value = 1500, min = 0, max = 2500, step = 100})
	KoreanMechanics.Combo.IT:MenuElement({id = "T", name = "Use Tiamat", value = true})
	KoreanMechanics.Combo.IT:MenuElement({id = "TH", name = "Use Titanic Hydra", value = true})
	KoreanMechanics.Combo.IT:MenuElement({id = "RH", name = "Use Ravenous Hydra", value = true})
	KoreanMechanics.Combo:MenuElement({type = MENU, id = "MM", name = "Mana Manager"})
	KoreanMechanics.Combo.MM:MenuElement({id = "QMana", name = "Min Mana to Q in Combo(%)", value = 40, min = 0, max = 100, step = 1})
	KoreanMechanics.Combo.MM:MenuElement({id = "WMana", name = "Min Mana to W in Combo(%)", value = 40, min = 0, max = 100, step = 1})
	KoreanMechanics.Combo.MM:MenuElement({id = "EMana", name = "Min Mana to E in Combo(%)", value = 40, min = 0, max = 100, step = 1})
	KoreanMechanics.Combo.MM:MenuElement({id = "RMana", name = "Min Mana to R in Combo(%)", value = 40, min = 0, max = 100, step = 1})		

	KoreanMechanics.Harass:MenuElement({id = "Q", name = "Use Q", value = true})
	KoreanMechanics.Harass:MenuElement({id = "W", name = "Use W", value = true})
	KoreanMechanics.Harass:MenuElement({id = "E", name = "Use E", value = true})
	KoreanMechanics.Harass:MenuElement({type = MENU, id = "IT", name = "Items"})
	KoreanMechanics.Harass.IT:MenuElement({id = "T", name = "Use Tiamat", value = true})
	KoreanMechanics.Harass.IT:MenuElement({id = "TH", name = "Use Titanic Hydra", value = true})
	KoreanMechanics.Harass.IT:MenuElement({id = "RH", name = "Use Ravenous Hydra", value = true})
	KoreanMechanics.Harass:MenuElement({type = MENU, id = "MM", name = "Mana Manager"})
	KoreanMechanics.Harass.MM:MenuElement({id = "QMana", name = "Min Mana to Q in Harass(%)", value = 40, min = 0, max = 100, step = 1})
	KoreanMechanics.Harass.MM:MenuElement({id = "WMana", name = "Min Mana to W in Harass(%)", value = 40, min = 0, max = 100, step = 1})
	KoreanMechanics.Harass.MM:MenuElement({id = "EMana", name = "Min Mana to E in Harass(%)", value = 40, min = 0, max = 100, step = 1})

	KoreanMechanics.Clear:MenuElement({id = "Q", name = "Use Q", value = true})
	KoreanMechanics.Clear:MenuElement({id = "QC", name = "Min amount of minions to Q", value = 3, min = 1, max = 7, step = 1})
	KoreanMechanics.Clear:MenuElement({id = "Mana", name = "Min Mana to Clear (%)", value = 40, min = 0, max = 100, step = 1})

	KoreanMechanics.Draw:MenuElement({id = "Enabled", name = "Enable all Drawings", value = true})
    KoreanMechanics.Draw:MenuElement({id = "DMG", name = "Draw DMG Prediction", value = true})	
    KoreanMechanics.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    KoreanMechanics.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    KoreanMechanics.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "ED", name = "Draw E range", type = MENU})
    KoreanMechanics.Draw.ED:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.ED:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.ED:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    KoreanMechanics.Draw:MenuElement({id = "RD", name = "Draw R range", type = MENU})
    KoreanMechanics.Draw.RD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.RD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.RD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 
    KoreanMechanics.Draw:MenuElement({id = "TD", name = "Draw Current Target", type = MENU})
    KoreanMechanics.Draw.TD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    KoreanMechanics.Draw.TD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    KoreanMechanics.Draw.TD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)}) 

    KoreanMechanics.AS:MenuElement({id = "QAS", name = "Q Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})
    KoreanMechanics.AS:MenuElement({id = "WAS", name = "W Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})
    KoreanMechanics.AS:MenuElement({id = "EAS", name = "E Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})
    KoreanMechanics.AS:MenuElement({id = "RAS", name = "R Delay Value (default 50)", value = 50, min = 1, max = 1000, step = 10})	
end 

function Darius:Tick()
	if myHero.dead then return end
    target = KoreanTarget(800)
    if GetMode() == "Combo" then
        self:Combo(target)
    elseif target and GetMode() == "Harass" then
        self:Harass(target)
    elseif GOS.GetMode() == "Clear" or GetMode() == "LaneClear" then
		self:Clear()
	end
end

 function Darius:RStacks(unit)
    if not unit then print("nounit") return 0 end
    for i = 0, unit.buffCount do
        local buff = unit:GetBuff(i)
        local Counter = buff.count
        if buff.name == "DariusHemo" and  buff.count > 0 then
            return Counter
        end
    end
    return 0
end

function Darius:GetDariusRdmg()
    if target == nil then return end
local level = GetRlvl()
    if level == nil then return 1 
    end
local Stacks = (Darius:RStacks(target) + 1)
	if Stacks >= 4 then
	  AD = myHero.totalDamage
	else  AD = myHero.bonusDamage
	end
local basedmg = (({0, 100, 200, 300})[level] + (0.75 * AD))
local stacksdmg = (  (({0, 100, 200, 300})[level]) * ((({0, 0.2, 0.4, 0.6, 0.8, 1})[Stacks]) ) )
local Rdmg =  ((basedmg + stacksdmg) + (60 * (({0, 0.2, 0.4, 0.6, 0.8, 1})[Stacks]))) --CalcPhysicalDamage(myHero, target, ((basedmg + stacksdmg)))
    return Rdmg
end

function Darius:Combo()
    if target == nil then return end	
    if KoreanMechanics.Combo.R:Value() and Ready(_R) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.RMana:Value() / 100) then
    	if KoreanCanCast(_R) and target.health <= Darius:GetDariusRdmg() *0.9 and not  target.isImmortal then
    		local pos = target.pos
    		KoreanCast(HK_R, pos, KoreanMechanics.AS.RAS:Value())
    	end
    end
    if KoreanMechanics.Combo.IT.YG:Value() and GetItemSlot(myHero, 3142) >= 1 then 
		if Ready(GetItemSlot(myHero, 3142)) and target.distance <= KoreanMechanics.Combo.IT.YGR:Value()  then 
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3142)], target)
		end 
	end
	if KoreanMechanics.Combo.IT.T:Value() and GetItemSlot(myHero, 3077) >= 1 then 
		if Ready(GetItemSlot(myHero, 3077)) and target.distance <= 350 and target.health >= Darius:GetDariusRdmg() then 
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3077)], target)
		end 
	end
	if KoreanMechanics.Combo.IT.TH:Value() and GetItemSlot(myHero, 3748) >= 1 then 
		if Ready(GetItemSlot(myHero, 3748)) and target.distance <= 550 and target.health >= Darius:GetDariusRdmg() then 
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3748)], target)
		end 
	end
	if KoreanMechanics.Combo.IT.RH:Value() and GetItemSlot(myHero, 3074) >= 1 then 
		if Ready(GetItemSlot(myHero, 3074)) and target.distance <= 350 and target.health >= Darius:GetDariusRdmg() then 
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3074)], target)
		end 
	end
	if KoreanMechanics.Combo.E:Value() and Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.EMana:Value() / 100) then
		if KoreanCanCast(_E) then 
			KoreanCast(HK_E, KoreanPred(target, _E), KoreanMechanics.AS.EAS:Value())
		end
		if KoreanMechanics.Combo.W:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.WMana:Value() / 100) then
			if KoreanCanCast(_W) then
				local pos = target.pos
				KoreanCast(HK_W, pos, KoreanMechanics.AS.WAS:Value())
			end
		end
		if KoreanMechanics.Combo.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.QMana:Value() / 100) then
			if KoreanCanCast(_Q) and target.distance > 150 then 
				KoreanCast(HK_Q, Game.mousePos(), KoreanMechanics.AS.QAS:Value())
			end
		end
	end
	if KoreanMechanics.Combo.W:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.WMana:Value() / 100) then
		if KoreanCanCast(_W) then
			local pos = target.pos
			KoreanCast(HK_W, pos, KoreanMechanics.AS.WAS:Value())
		end
		if KoreanMechanics.Combo.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.QMana:Value() / 100) then
			if KoreanCanCast(_Q) and target.distance > 150 then 
				KoreanCast(HK_Q, Game.mousePos(), KoreanMechanics.AS.QAS:Value())
			end
		end
	end
	if KoreanMechanics.Combo.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Combo.MM.QMana:Value() / 100) then
		if KoreanCanCast(_Q) and target.distance > 150 then 
			KoreanCast(HK_Q, Game.mousePos(), KoreanMechanics.AS.QAS:Value())
		end
	end
   	if KoreanMechanics.Combo.IS.I:Value() then 
   		if KoreanMechanics.Combo.IS.IMode:Value() == 2 and myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) then
       		if IsValidTarget(target, 600, true, myHero) and target.health/target.maxHealth <= KoreanMechanics.Combo.IS.IHP:Value() /100 then
            	Control.CastSpell(HK_SUMMONER_1, target)
       		end
		elseif  KoreanMechanics.Combo.IS.IMode:Value() == 2 and myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) then
        	if IsValidTarget(target, 600, true, myHero) and target.health/target.maxHealth <= KoreanMechanics.Combo.IS.IHP:Value() /100 then
           		 Control.CastSpell(HK_SUMMONER_2, target)
       		end
		elseif  KoreanMechanics.Combo.IS.IMode:Value() == 1 and myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) and not Ready(_Q) and not Ready(_R) then
       	 	if IsValidTarget(target, 600, true, myHero) and 50+20*myHero.levelData.lvl > target.health*1.1 then
           		Control.CastSpell(HK_SUMMONER_1, target)
       	 	end
		elseif KoreanMechanics.Combo.IS.IMode:Value() == 1  and myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) and not Ready(_Q) and not Ready(_R) then
       		 if IsValidTarget(target, 600, true, myHero) and 50+20*myHero.levelData.lvl > target.health*1.1 then
           		Control.CastSpell(HK_SUMMONER_2, target)
        	end
    	end 
    end
end

function Darius:Harass()
    if target == nil then return end		
    if KoreanMechanics.Harass.E:Value() and Ready(_E) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.EMana:Value() / 100) then
    	if KoreanCanCast(_E) then
    		KoreanCast(HK_E, KoreanPred(target, _E), KoreanMechanics.AS.EAS:Value())
    	end
    end
    if KoreanMechanics.Harass.IT.T:Value() and GetItemSlot(myHero, 3077) >= 1 then 
		if Ready(GetItemSlot(myHero, 3077)) and target.distance <= 350  then 
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3077)], target)
		end 
	end
	if KoreanMechanics.Harass.IT.TH:Value() and GetItemSlot(myHero, 3748) >= 1 then 
		if Ready(GetItemSlot(myHero, 3748)) and target.distance <= 550  then 
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3748)], target)
		end 
	end
	if KoreanMechanics.Harass.IT.RH:Value() and GetItemSlot(myHero, 3074) >= 1 then 
		if Ready(GetItemSlot(myHero, 3074)) and target.distance <= 350  then 
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3074)], target)
		end 
	end
	if KoreanMechanics.Harass.W:Value() and Ready(_W) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.WMana:Value() / 100) then
		if KoreanCanCast(_W) then
			local pos = target.pos
			KoreanCast(HK_W, pos, KoreanMechanics.AS.WAS:Value())
		end
		if KoreanMechanics.Harass.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.QMana:Value() / 100) then
			if KoreanCanCast(_Q) then
				KoreanCast(HK_Q, Game.mousePos(), KoreanMechanics.AS.QAS:Value())
			end
		end
	end
	if KoreanMechanics.Harass.Q:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana >= KoreanMechanics.Harass.MM.QMana:Value() / 100) then
		if KoreanCanCast(_Q) then
			KoreanCast(HK_Q, Game.mousePos(), KoreanMechanics.AS.QAS:Value())
		end
	end
end 

function Darius:Clear()
local ClearQ = KoreanMechanics.Clear.Q:Value()
local ClearMana = KoreanMechanics.Clear.Mana:Value()
local GetEnemyMinions = GetEnemyMinions()
local Minions = nil	
	if ClearQ and Ready(_Q) and (myHero.mana/myHero.maxMana >= ClearMana / 100) then
		for i = 1, #GetEnemyMinions do
		local Minions = GetEnemyMinions[i]
		local Count = MinionsAround(Minions.pos, Spells["Darius"]["DariusCleave"].range , Minions.team)
			if Count >=	KoreanMechanics.Clear.QC:Value() and Minions.distance <= Spells["Darius"]["DariusCleave"].range then
				KoreanCast(HK_Q, Game.mousePos(), KoreanMechanics.AS.QAS:Value())
			end
		end
	end
end

function Darius:Draw()
    if not myHero.dead then
    	if KoreanMechanics.Draw.Enabled:Value() then
	        if KoreanMechanics.Draw.QD.Enabled:Value() then
	            Draw.Circle(myHero.pos, Spells["Darius"]["DariusCleave"].range, KoreanMechanics.Draw.QD.Width:Value(), KoreanMechanics.Draw.QD.Color:Value())
	        end
	        if KoreanMechanics.Draw.WD.Enabled:Value() then
	            Draw.Circle(myHero.pos, Spells["Darius"]["DariusNoxianTacticsONH"].range, KoreanMechanics.Draw.WD.Width:Value(), KoreanMechanics.Draw.WD.Color:Value())
	        end
	        if KoreanMechanics.Draw.ED.Enabled:Value() then
	            Draw.Circle(myHero.pos, Spells["Darius"]["DariusAxeGrabCone"].range, KoreanMechanics.Draw.ED.Width:Value(), KoreanMechanics.Draw.ED.Color:Value())
	        end
	        if KoreanMechanics.Draw.RD.Enabled:Value()  then
	            Draw.Circle(myHero.pos, Spells["Darius"]["DariusExecute"].range, KoreanMechanics.Draw.RD.Width:Value(), KoreanMechanics.Draw.RD.Color:Value())
	        end
	        local target = KoreanTarget()
	        if target == nil then return end
	       	if KoreanMechanics.Draw.DMG:Value() then
	        	if  Darius:GetDariusRdmg(target) ~= nil and Ready(_R) then 
	        		local textPos = myHero.pos:To2D()
					Draw.Text("R DMG " .. tostring(math.floor(Darius:GetDariusRdmg(target))), 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 0, 0)) 
				end
			end
	    end
    end
end	


if _G[myHero.charName]() then print("Welcome back " ..myHero.name.. ", Thank you for using Korean Mechanics Reborn ^^") end
