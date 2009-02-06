--[[

	Elements handled:
	 .Experience [statusbar]
	 .Experience.Text [fontstring] (optional)

	Shared:
	 - MouseOver [boolean]
	 - Tooltip [boolean]

	Functions that can be overridden from within a layout:
	 - :PostUpdate(event, unit, bar, min, max)
	 - :OverrideText(min, max)

--]]

local localized, class = UnitClass('player')

local function Tooltip(self, unit, min, max)
	GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT', 5, -5)
	GameTooltip:AddLine(string.format('XP: %d/%d (%.1f%%)', min, max, min/max*100))

	if(unit == 'pet') then
		GameTooltip:AddLine(string.format('%d needed (%.1f%% - %.1f bars)', max-min, (max-min)/max*100, 6*(max-min)/max))
	else
		GameTooltip:AddLine(string.format('%d needed (%.1f%% - %.1f bars)', max-min, (max-min)/max*100, 20*(max-min)/max))
	end

	if(unit == 'player' and GetXPExhaustion()) then
		GameTooltip:AddLine(string.format('|cff0090ffRested: +%d (%.1f%%)', GetXPExhaustion(), GetXPExhaustion()/max*100))
	end

	GameTooltip:Show()
end

local function GetXP(unit)
	if(unit == 'pet') then
		return GetPetExperience()
	else
		return UnitXP(unit), UnitXPMax(unit)
	end
end

local function Update(self, event, unit)
	local bar = self.Experience

	if(self.unit == 'player' and (UnitLevel(self.unit) ~= MAX_PLAYER_LEVEL) or (self.unit == 'pet' and class == 'HUNTER') and (UnitLevel(self.unit) < UnitLevel('player'))) then
		local min, max = GetXP(self.unit)

		bar:SetMinMaxValues(0, max)
		bar:SetValue(min)
		bar:Show()

		if(bar.Text) then
			if(bar.OverrideText) then
				bar:OverrideText(min, max)
			else
				bar.Text:SetFormattedText('%d / %d', min, max)
			end
		end

		if(bar.Tooltip and bar.MouseOver) then
			bar:SetScript('OnEnter', function() bar:SetAlpha(1); Tooltip(bar, self.unit, min, max) end)
		elseif(bar.Tooltip and not bar.MouseOver) then
			bar:SetScript('OnEnter', function() Tooltip(bar, self.unit, min, max) end)
		end

		if(bar.PostUpdate) then bar.PostUpdate(self, event, unit, bar, min, max) end
	else
		bar:Hide()
	end
end

local function Enable(self, unit)
	local experience = self.Experience
	if(experience and (unit == 'pet' or unit == 'player')) then
		self:RegisterEvent('PLAYER_XP_UPDATE', Update)
		self:RegisterEvent('UNIT_PET', Update)

		if(class == 'HUNTER') then
			self:RegisterEvent('UNIT_PET_EXPERIENCE', Update)
		end

		if(experience.MouseOver or experience.Tooltip) then
			experience:EnableMouse()
		end

		if(not experience:GetStatusBarTexture()) then
			experience:SetStatusBarTexture([=[Interface\TargetingFrame\UI-StatusBar]=])
		end

		if(experience.Tooltip and experience.MouseOver) then
			experience:SetAlpha(0)
			experience:SetScript('OnLeave', function(self) self:SetAlpha(0); GameTooltip:Hide() end)
		elseif(experience.MouseOver and not experience.Tooltip) then
			experience:SetAlpha(0)
			experience:SetScript('OnEnter', function(self) self:SetAlpha(1) end)
			experience:SetScript('OnLeave', function(self) self:SetAlpha(0) end)
		elseif(experience.Tooltip and not experience.MouseOver) then
			experience:SetScript('OnLeave', function() GameTooltip:Hide() end)
		end

		return true
	end
end

local function Disable(self)
	if(self.Experience) then
		self:UnregisterEvent('PLAYER_XP_UPDATE', Update)
		self:UnregisterEvent('UNIT_PET', Update)

		if(class == 'HUNTER') then
			self:UnregisterEvent('UNIT_PET_EXPERIENCE', Update)
		end 
	end
end

oUF:AddElement('Experience', Update, Enable, Disable)