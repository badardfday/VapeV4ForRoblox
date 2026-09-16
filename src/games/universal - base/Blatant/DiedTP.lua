local DiedTP
local SpawnDelay
local deathCFrame
local lastValidCFrame
local isDead = false

local function hookHumanoid(character)
	if not character then return end
	local hum = character:WaitForChild('Humanoid', 5)
	if hum then
		DiedTP:Clean(hum.Died:Connect(function()
			if not isDead and lastValidCFrame then
				deathCFrame = lastValidCFrame
				isDead = true
			end
		end))
		DiedTP:Clean(hum.HealthChanged:Connect(function(health)
			if health <= 0 and not isDead and lastValidCFrame then
				deathCFrame = lastValidCFrame
				isDead = true
			end
		end))
	end
end

DiedTP = vape.Categories.Blatant:CreateModule({
	Name = 'DiedTP',
	Function = function(callback)
		if not callback then
			deathCFrame = nil
			lastValidCFrame = nil
			isDead = false
			return
		end

		isDead = false
		hookHumanoid(lplr.Character)

		DiedTP:Clean(runService.PreSimulation:Connect(function()
			if isDead then return end

			local char = lplr.Character
			local root = entitylib.character and entitylib.character.RootPart or (char and (char:FindFirstChild('HumanoidRootPart') or char:FindFirstChild('Torso')))
			local hum = entitylib.character and entitylib.character.Humanoid or (char and char:FindFirstChildOfClass('Humanoid'))

			if char and root and hum and hum.Health > 0 and root:IsDescendantOf(workspace) then
				local voidThreshold = (workspace.FallenPartsDestroyHeight or -500) + 25
				if root.Position.Y > voidThreshold then
					lastValidCFrame = root.CFrame
				end
			end
		end))

		DiedTP:Clean(lplr.CharacterAdded:Connect(function(character)
			hookHumanoid(character)

			local returnCFrame = deathCFrame or lastValidCFrame
			if not returnCFrame then return end

			task.spawn(function()
				local start = os.clock()
				while not character:IsDescendantOf(workspace) and (os.clock() - start) < 5 do
					task.wait()
				end

				if not character:IsDescendantOf(workspace) then return end

				local root = character:WaitForChild('HumanoidRootPart', 5)
				local hum = character:WaitForChild('Humanoid', 5)
				if not (root and hum) then return end

				local delayTime = SpawnDelay and SpawnDelay.Value or 0.15
				if delayTime > 0 then
					task.wait(delayTime)
				end

				if not (DiedTP.Enabled and character.Parent and root.Parent and hum.Health > 0) then
					return
				end

				for i = 1, 8 do
					if not (DiedTP.Enabled and character.Parent and root.Parent and hum.Health > 0) then
						break
					end
					root.CFrame = returnCFrame
					root.AssemblyLinearVelocity = Vector3.zero
					root.AssemblyAngularVelocity = Vector3.zero
					runService.PreSimulation:Wait()
				end

				character:PivotTo(returnCFrame)
				isDead = false
				deathCFrame = nil

				notif('DiedTP', 'Teleported to death location.', 3)
			end)
		end))
	end,
	Tooltip = 'Teleports you back to your last position after respawning.'
})

SpawnDelay = DiedTP:CreateSlider({
	Name = 'Delay',
	Min = 0.05,
	Max = 1,
	Decimal = 100,
	Default = 0.15,
	Suffix = function(val)
		return val == 1 and 'second' or 'seconds'
	end,
	Tooltip = 'Delay after respawning before teleporting back.'
})