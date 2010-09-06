local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF Experience was unable to locate oUF install')

local hunterPlayer = select(2, UnitClass('player')) == 'HUNTER'

local function GetXP(unit)
	if(unit == 'pet') then
		return GetPetExperience()
	else
		return UnitXP(unit), UnitXPMax(unit)
	end
end

local function Update(self, event, owner)
	if(event == 'UNIT_PET' and owner ~= 'player') then return end

	local experience = self.Experience
	-- Conditional hiding
	if(self.unit == 'player') then
		if(UnitLevel('player') == MAX_PLAYER_LEVEL) then
			return experience:Hide()
		end
	elseif(self.unit == 'pet') then
		local _, hunterPet = HasPetUI()
		if(not self.disallowVehicleSwap and UnitHasVehicleUI('player')) then
			return experience:Hide()
		elseif(not hunterPet or (UnitLevel('pet') == UnitLevel('player'))) then
			return experience:Hide()
		end
	else
		return experience:Hide()
	end

	local unit = self.unit
	local min, max = GetXP(unit)
	experience:SetMinMaxValues(0, max)
	experience:SetValue(min)
	experience:Show()

	if(experience.Text) then
		experience.Text:SetFormattedText('%d / %d', min, max)
	end

	if(experience.Rested) then
		local rested = GetXPExhaustion()
		if(unit == 'player' and rested and rested > 0) then
			experience.Rested:SetMinMaxValues(0, max)
			experience.Rested:SetValue(math.min(min + rested, max))
			experience.rested = rested
		else
			experience.Rested:SetMinMaxValues(0, 1)
			experience.Rested:SetValue(0)
			experience.rested = nil
		end
	end

	if(experience.PostUpdate) then
		return experience:PostUpdate(unit, min, max)
	end
end

local function Enable(self, unit)
	local experience = self.Experience
	if(experience) then
		local Update = experience.Update or Update

		self:RegisterEvent('PLAYER_XP_UPDATE', Update)
		self:RegisterEvent('PLAYER_LEVEL_UP', Update)
		self:RegisterEvent('UNIT_PET', Update)

		if(experience.Rested) then
			self:RegisterEvent('UPDATE_EXHAUSTION', Update)
			experience.Rested:SetFrameLevel(1)
		end

		if(hunterPlayer) then
			self:RegisterEvent('UNIT_PET_EXPERIENCE', Update)
		end

		if(not experience:GetStatusBarTexture()) then
			experience:SetStatusBarTexture([=[Interface\TargetingFrame\UI-StatusBar]=])
		end

		return true
	end
end

local function Disable(self)
	local experience = self.Experience
	if(experience) then
		local Update = experience.Update or Update

		self:UnregisterEvent('PLAYER_XP_UPDATE', Update)
		self:UnregisterEvent('PLAYER_LEVEL_UP', Update)
		self:UnregisterEvent('UNIT_PET', Update)

		if(experience.Rested) then
			self:UnregisterEvent('UPDATE_EXHAUSTION', Update)
		end

		if(hunterPlayer) then
			self:UnregisterEvent('UNIT_PET_EXPERIENCE', Update)
		end
	end
end

oUF:AddElement('Experience', Update, Enable, Disable)
