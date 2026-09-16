local DiedTP
local lastCFrame

DiedTP = vape.Categories.Blatant:CreateModule({
	Name = 'DiedTP',
	Function = function(callback)
		if not callback then
			lastCFrame = nil
			return
		end

		DiedTP:Clean(runService.PreSimulation:Connect(function()
			if entitylib.isAlive then
				lastCFrame = entitylib.character.RootPart.CFrame
			end
		end))

		DiedTP:Clean(lplr.CharacterAdded:Connect(function(character)
			local returnCFrame = lastCFrame
			local root = character:WaitForChild('HumanoidRootPart', 5)
			if root and returnCFrame then
				if DiedTP.Enabled and character.Parent then
					character:PivotTo(returnCFrame)
				end
			end
		end))
	end,
	Tooltip = 'Teleports you back to your last position after respawning.'
})