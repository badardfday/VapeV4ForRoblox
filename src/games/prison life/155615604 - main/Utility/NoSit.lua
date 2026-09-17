local NoSit
local humanoid

local function EntityAdded(entity)
	humanoid = entity.Humanoid
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	humanoid.Sit = false
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

	NoSit:Clean(humanoid.StateChanged:Connect(function(_, state)
		if state == Enum.HumanoidStateType.Seated then
		humanoid.Sit = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end))
end

NoSit = vape.Categories.Utility:CreateModule({
	Name = 'NoSit',
	Function = function(callback)
		if callback then
			NoSit:Clean(entitylib.Events.LocalAdded:Connect(EntityAdded))
			if entitylib.isAlive then
				EntityAdded(entitylib.character)
		end
		    elseif humanoid then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
		end
	end,
	Tooltip = 'Prevents your character from sitting.'
})