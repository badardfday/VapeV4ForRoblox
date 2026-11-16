local GunModifier
local Selected
local ApplySelected
local ApplyAll
local ResetSelected
local MaxDamage
local MinDamage
local AmmoCount
local HeadshotMultiplier
local ReloadSpeed
local firerate
local spread
local crouchSpread
local Recoil
local Penetration
local Range
local ShellsPerShot
local Weight
local Suppression
local teamkill
local PresetInstaKill
local PresetLaser
local PresetStock

local gunSettingsFolder = replicatedStorage:FindFirstChild('TREKModules')
	and replicatedStorage.TREKModules:FindFirstChild('GunSettings')

if not gunSettingsFolder then
	notif('GunModifier', 'TREKModules.GunSettings not found', 6, 'warning')
	return
end

local gunCache = {}
local gunNames = {}
local selectedGun = nil
local selectedName = ''
local currentValues = {
	MaxDamage = 100,
	MinDamage = 100,
	AmmoCount = 0,
	HeadshotMultiplier = 0,
	ReloadSpeed = 0,
	firerate = 0,
	spread = 0,
	crouchSpread = 0,
	Recoil = 0,
	Penetration = 0,
	Range = 0,
	ShellsPerShot = 0,
	teamkill = true,
	Weight = 0,
	Suppression = 0
}

local function refreshGunList()
	table.clear(gunNames)
	table.clear(gunCache)
	for _, mod in ipairs(gunSettingsFolder:GetChildren()) do
		if mod:IsA('ModuleScript') then
			local ok, settings = pcall(require, mod)
			if ok and type(settings) == 'table' then
				gunCache[mod] = settings
				table.insert(gunNames, mod.Name)
			end
		end
	end
	table.sort(gunNames)
end

local function applyToGun(mod, values)
	local settings = gunCache[mod]
	if not settings then return false end
	for key, val in pairs(values) do
		settings[key] = val
	end
	return true
end

local function applyAll(values)
	local count = 0
	for mod in pairs(gunCache) do
		if applyToGun(mod, values) then
			count += 1
		end
	end
	return count
end

local function collectValues()
	return {
		MaxDamage = MaxDamage.Value,
		MinDamage = MinDamage.Value,
		AmmoCount = AmmoCount.Value,
		HeadshotMultiplier = HeadshotMultiplier.Value,
		ReloadSpeed = ReloadSpeed.Value,
		firerate = firerate.Value,
		spread = spread.Value,
		crouchSpread = crouchSpread.Value,
		Recoil = Recoil.Value,
		Penetration = Penetration.Value,
		Range = Range.Value,
		ShellsPerShot = ShellsPerShot.Value,
		Weight = Weight.Value,
		Suppression = Suppression.Value,
		teamkill = teamkill.Enabled
	}
end

local function pushUIFromGun(mod)
	local settings = gunCache[mod]
	if not settings then return end
	MaxDamage:SetValue(settings.MaxDamage or 100)
	MinDamage:SetValue(settings.MinDamage or 100)
	AmmoCount:SetValue(settings.AmmoCount or 0)
	HeadshotMultiplier:SetValue(settings.HeadshotMultiplier or 0)
	ReloadSpeed:SetValue(settings.ReloadSpeed or 0)
	firerate:SetValue(settings.firerate or 0)
	spread:SetValue(settings.spread or 0)
	crouchSpread:SetValue(settings.crouchSpread or 0)
	Recoil:SetValue(settings.Recoil or 0)
	Penetration:SetValue(settings.Penetration or 0)
	Range:SetValue(settings.Range or 0)
	ShellsPerShot:SetValue(settings.ShellsPerShot or 0)
	Weight:SetValue(settings.Weight or 0)
	Suppression:SetValue(settings.Suppression or 0)
	teamkill:SetValue(settings.teamkill and true or false)
end

local function loadPreset(values)
	MaxDamage:SetValue(values.MaxDamage)
	MinDamage:SetValue(values.MinDamage)
	AmmoCount:SetValue(values.AmmoCount)
	HeadshotMultiplier:SetValue(values.HeadshotMultiplier)
	ReloadSpeed:SetValue(values.ReloadSpeed)
	firerate:SetValue(values.firerate)
	spread:SetValue(values.spread)
	crouchSpread:SetValue(values.crouchSpread)
	Recoil:SetValue(values.Recoil)
	Penetration:SetValue(values.Penetration)
	Range:SetValue(values.Range)
	ShellsPerShot:SetValue(values.ShellsPerShot)
	Weight:SetValue(values.Weight)
	Suppression:SetValue(values.Suppression)
	teamkill:SetValue(values.teamkill)
end

refreshGunList()

GunModifier = vape.Categories.Utility:CreateModule({
	Name = 'GunModifier',
	Function = function(callback)
		if callback then
			refreshGunList()
			if #gunNames > 0 and not selectedGun then
				selectedName = gunNames[1]
				for mod in pairs(gunCache) do
					if mod.Name == selectedName then
						selectedGun = mod
						break
					end
				end
				if Selected then
					Selected:SetValue(selectedName)
				end
				if selectedGun then
					pushUIFromGun(selectedGun)
				end
			end
			notif('GunModifier', 'Loaded '..#gunNames..' gun modules', 4)
		end
	end,
	Tooltip = 'Live editor for TREKModules.GunSettings — change values and apply'
})

Selected = GunModifier:CreateDropdown({
	Name = 'Gun',
	List = gunNames,
	Function = function(name)
		selectedName = name
		selectedGun = nil
		for mod in pairs(gunCache) do
			if mod.Name == name then
				selectedGun = mod
				break
			end
		end
		if selectedGun then
			pushUIFromGun(selectedGun)
		end
	end
})

MaxDamage = GunModifier:CreateSlider({
	Name = 'MaxDamage',
	Min = 0,
	Max = 500,
	Default = 100
})
MinDamage = GunModifier:CreateSlider({
	Name = 'MinDamage',
	Min = 0,
	Max = 500,
	Default = 100
})
AmmoCount = GunModifier:CreateSlider({
	Name = 'AmmoCount',
	Min = 0,
	Max = 999,
	Default = 0
})
HeadshotMultiplier = GunModifier:CreateSlider({
	Name = 'HeadshotMultiplier',
	Min = 0,
	Max = 10,
	Default = 0,
	Decimal = 10
})
ReloadSpeed = GunModifier:CreateSlider({
	Name = 'ReloadSpeed',
	Min = 0,
	Max = 10,
	Default = 0,
	Decimal = 10
})
firerate = GunModifier:CreateSlider({
	Name = 'firerate',
	Min = 0,
	Max = 30,
	Default = 0,
	Decimal = 10
})
spread = GunModifier:CreateSlider({
	Name = 'spread',
	Min = 0,
	Max = 50,
	Default = 0,
	Decimal = 10
})
crouchSpread = GunModifier:CreateSlider({
	Name = 'crouchSpread',
	Min = 0,
	Max = 50,
	Default = 0,
	Decimal = 10
})
Recoil = GunModifier:CreateSlider({
	Name = 'Recoil',
	Min = 0,
	Max = 50,
	Default = 0,
	Decimal = 10
})
Penetration = GunModifier:CreateSlider({
	Name = 'Penetration',
	Min = 0,
	Max = 20,
	Default = 0
})
Range = GunModifier:CreateSlider({
	Name = 'Range',
	Min = 0,
	Max = 5000,
	Default = 0
})
ShellsPerShot = GunModifier:CreateSlider({
	Name = 'ShellsPerShot',
	Min = 0,
	Max = 20,
	Default = 0
})
Weight = GunModifier:CreateSlider({
	Name = 'Weight',
	Min = -50,
	Max = 50,
	Default = 0,
	Decimal = 10
})
Suppression = GunModifier:CreateSlider({
	Name = 'Suppression',
	Min = 0,
	Max = 100,
	Default = 0
})
teamkill = GunModifier:CreateToggle({
	Name = 'teamkill',
	Default = true
})

ApplySelected = GunModifier:CreateToggle({
	Name = 'Apply Selected',
	Function = function(callback)
		if callback and selectedGun then
			if applyToGun(selectedGun, collectValues()) then
				notif('GunModifier', 'Applied to '..selectedName, 3)
			else
				notif('GunModifier', 'Failed to apply to '..selectedName, 4, 'warning')
			end
			ApplySelected:Toggle()
		end
	end,
	Tooltip = 'Write current UI values into the selected gun module'
})

ApplyAll = GunModifier:CreateToggle({
	Name = 'Apply All Guns',
	Function = function(callback)
		if callback then
			local count = applyAll(collectValues())
			notif('GunModifier', 'Applied to '..count..' guns', 4)
			ApplyAll:Toggle()
		end
	end,
	Tooltip = 'Write current UI values into every gun module'
})

ResetSelected = GunModifier:CreateToggle({
	Name = 'Reset Selected UI',
	Function = function(callback)
		if callback and selectedGun then
			pushUIFromGun(selectedGun)
			notif('GunModifier', 'UI reset to current module values', 3)
			ResetSelected:Toggle()
		end
	end
})

PresetInstaKill = GunModifier:CreateToggle({
	Name = 'Preset: InstaKill',
	Function = function(callback)
		if callback then
			loadPreset({
				MaxDamage = 999, MinDamage = 999, HeadshotMultiplier = 1,
				firerate = 0, ReloadSpeed = 0, AmmoCount = 999,
				spread = 0, crouchSpread = 0, Recoil = 0,
				Range = 5000, Penetration = 10, ShellsPerShot = 1,
				teamkill = true, Weight = 0, Suppression = 0
			})
			notif('GunModifier', 'Loaded preset InstaKill', 3)
			task.defer(function()
				if PresetInstaKill.Enabled then PresetInstaKill:Toggle() end
			end)
		end
	end
})

PresetLaser = GunModifier:CreateToggle({
	Name = 'Preset: Laser',
	Function = function(callback)
		if callback then
			loadPreset({
				MaxDamage = 50, MinDamage = 50, HeadshotMultiplier = 2,
				firerate = 0.05, ReloadSpeed = 0.1, AmmoCount = 200,
				spread = 0, crouchSpread = 0, Recoil = 0,
				Range = 3000, Penetration = 5, ShellsPerShot = 1,
				teamkill = true, Weight = 0, Suppression = 0
			})
			notif('GunModifier', 'Loaded preset Laser', 3)
			task.defer(function()
				if PresetLaser.Enabled then PresetLaser:Toggle() end
			end)
		end
	end
})

PresetStock = GunModifier:CreateToggle({
	Name = 'Preset: Stock-ish',
	Function = function(callback)
		if callback then
			loadPreset({
				MaxDamage = 30, MinDamage = 20, HeadshotMultiplier = 1.5,
				firerate = 0.15, ReloadSpeed = 2, AmmoCount = 30,
				spread = 2, crouchSpread = 1, Recoil = 3,
				Range = 800, Penetration = 1, ShellsPerShot = 1,
				teamkill = false, Weight = 5, Suppression = 10
			})
			notif('GunModifier', 'Loaded preset Stock-ish', 3)
			task.defer(function()
				if PresetStock.Enabled then PresetStock:Toggle() end
			end)
		end
	end
})