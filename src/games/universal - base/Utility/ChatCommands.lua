local ChatCommand
local cPlayerTP
local cPlayerView
local cRejoin
local cServerHop
local cReloadVape
local cChangeTeam
local cWhitelist
local cTweenTP
local cTweenSpeed
local cTweenWait
local oldCameraSubject
local viewDeathConnection
local teamsService = game:GetService('Teams')
local tweenService = cloneref and cloneref(game:GetService('TweenService')) or game:GetService('TweenService')
local runService = cloneref and cloneref(game:GetService('RunService')) or game:GetService('RunService')
local activeTween
local noclipConnection
local originalAnchored
local activeRoot
local tweenInProgress = false

local function clearViewDeathConnection()
	if viewDeathConnection then
		viewDeathConnection:Disconnect()
		viewDeathConnection = nil
	end
end

local function restoreCamera()
	clearViewDeathConnection()
	local character = lplr.Character
	local cameraSubject = character and character:FindFirstChildOfClass('Humanoid')
		or (entitylib.character and entitylib.character.Humanoid)
	if cameraSubject then
		gameCamera.CameraSubject = cameraSubject
		gameCamera.CameraType = Enum.CameraType.Custom
	end
	oldCameraSubject = nil
end

local function findPlayer(prefix, includeDead)
	if not prefix or prefix == '' then
		return nil
	end

	local lowered = prefix:lower()
	for _, entity in entitylib.List do
		if entity and entity.Humanoid and (includeDead or entity.Humanoid.Health > 0) then
			local player = entity.Player or entity
			local displayName = player and player.DisplayName
			if displayName and displayName:lower():sub(1, #lowered) == lowered then
				return entity
			end
		end
	end

	return nil
end

local whitelistCommands = {
	 wl = true,
	 whitelist = true,
	 unwl = true,
	 unwhitelist = true
}

local function cleanupTween()
	if activeTween then
		pcall(function()
			activeTween:Cancel()
		end)
		activeTween = nil
	end
	if noclipConnection then
		noclipConnection:Disconnect()
		noclipConnection = nil
	end
	if activeRoot and activeRoot.Parent then
		if originalAnchored ~= nil then
			activeRoot.Anchored = originalAnchored
		end
		activeRoot.AssemblyLinearVelocity = Vector3.zero
		activeRoot.AssemblyAngularVelocity = Vector3.zero
	end
	originalAnchored = nil
	activeRoot = nil
	tweenInProgress = false
end

local function tweenToAndBack(targetPos)
	if tweenInProgress then
		notif('TweenTP', 'Tween already running! Say .canceltween to cancel.', 3, 'warning')
		return
	end

	local character = lplr.Character
	local root = entitylib.character and entitylib.character.RootPart or (character and (character:FindFirstChild('HumanoidRootPart') or character:FindFirstChild('Torso')))
	local humanoid = entitylib.character and entitylib.character.Humanoid or (character and character:FindFirstChildOfClass('Humanoid'))

	if not (character and root and humanoid and humanoid.Health > 0) then
		notif('TweenTP', 'Character not available or dead.', 3, 'warning')
		return
	end

	tweenInProgress = true
	activeRoot = root
	originalAnchored = root.Anchored

	task.spawn(function()
		local originalCFrame = root.CFrame
		local targetCFrame = CFrame.new(targetPos) * originalCFrame.Rotation

		local speed = cTweenSpeed and cTweenSpeed.Value or 200
		local waitTime = cTweenWait and cTweenWait.Value or 0.5

		noclipConnection = runService.Stepped:Connect(function()
			if character and character.Parent then
				for _, part in character:GetChildren() do
					if part:IsA('BasePart') then
						part.CanCollide = false
					end
				end
			end
		end)

		root.Anchored = true
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero

		local distTo = (root.Position - targetPos).Magnitude
		local durationTo = math.max(distTo / speed, 0.2)

		notif('TweenTP', string.format('Tweening to (%.0f, %.0f, %.0f)...', targetPos.X, targetPos.Y, targetPos.Z), math.max(durationTo, 2))

		local tweenInfoTo = TweenInfo.new(durationTo, Enum.EasingStyle.Linear)
		activeTween = tweenService:Create(root, tweenInfoTo, {CFrame = targetCFrame})
		activeTween:Play()

		local completed = false
		local conn = activeTween.Completed:Connect(function()
			completed = true
		end)

		while not completed and tweenInProgress do
			if not (humanoid and humanoid.Health > 0 and root.Parent) then
				if conn then conn:Disconnect() end
				cleanupTween()
				return
			end
			task.wait()
		end
		if conn then conn:Disconnect() end

		if not tweenInProgress then return end

		root.CFrame = targetCFrame
		root.AssemblyLinearVelocity = Vector3.zero

		if waitTime > 0 then
			task.wait(waitTime)
		end

		if not tweenInProgress or not (humanoid and humanoid.Health > 0 and root.Parent) then
			cleanupTween()
			return
		end

		local distBack = (root.Position - originalCFrame.Position).Magnitude
		local durationBack = math.max(distBack / speed, 0.2)

		notif('TweenTP', 'Returning to original position...', math.max(durationBack, 2))

		local tweenInfoBack = TweenInfo.new(durationBack, Enum.EasingStyle.Linear)
		activeTween = tweenService:Create(root, tweenInfoBack, {CFrame = originalCFrame})
		activeTween:Play()

		completed = false
		conn = activeTween.Completed:Connect(function()
			completed = true
		end)

		while not completed and tweenInProgress do
			if not (humanoid and humanoid.Health > 0 and root.Parent) then
				if conn then conn:Disconnect() end
				cleanupTween()
				return
			end
			task.wait()
		end
		if conn then conn:Disconnect() end

		if not tweenInProgress then return end

		root.CFrame = originalCFrame
		cleanupTween()
		notif('TweenTP', 'Returned successfully!', 3)
	end)
end

ChatCommand = vape.Categories.Utility:CreateModule({
	Name = 'ChatCommand',
	Function = function(callback)
		if callback then
			oldCameraSubject = gameCamera.CameraSubject
			ChatCommand:Clean(lplr.Chatted:Connect(function(message)
				if message:sub(1, 1) ~= '.' then
					return
				end

				local loweredMessage = message:lower()
				local command, prefix = message:match('^%.(%S+)%s+(.+)$')
				local loweredCommand = command and command:lower()
				local teamCommand = loweredMessage:match('^%.team%s+(%S+)$')
				if cChangeTeam.Enabled and teamCommand then
					local teamName = teamCommand == 'g' and 'Guards'
						or teamCommand == 'i' and 'Inmates'
						or teamCommand == 'guards' and 'Guards'
						or teamCommand == 'inmates' and 'Inmates'
					if teamName then
						local remotes = replicatedStorage:FindFirstChild('Remotes')
						local requestTeamChange = remotes and remotes:FindFirstChild('RequestTeamChange')
						local neutral = teamsService:FindFirstChild('Neutral')
						local targetTeam = teamsService:FindFirstChild(teamName)
						if requestTeamChange and neutral and targetTeam then
							if lplr.Team ~= neutral then
								requestTeamChange:InvokeServer(neutral, 1)
								task.wait(1)
							end
							requestTeamChange:InvokeServer(targetTeam, 1)
						end
					end
				elseif loweredMessage == '.reload' and cReloadVape.Enabled then
					delfile('newvape/main.lua')
					delfolder('newvape/libraries')
					delfolder('newvape/games')
					loadstring(game:HttpGet('https://raw.githubusercontent.com/badardfday/VapeV4ForRoblox/main/NewMainScript.lua', true))()
				elseif (loweredMessage == '.serverhop' or loweredMessage == '.hop') and cServerHop.Enabled then
					serverHop(nil, 'Descending')
				elseif (loweredMessage == '.rj' or loweredMessage == '.rejoin') and cRejoin.Enabled then
					if playersService.NumPlayers > 1 then
						teleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
					else
						teleportService:Teleport(game.PlaceId)
					end
				elseif loweredCommand and whitelistCommands[loweredCommand] and cWhitelist.Enabled then
					local isUnwhitelist = loweredCommand == 'unwl' or loweredCommand == 'unwhitelist'
					local target = findPlayer(prefix:match('^%s*(.-)%s*$'), true)
					local player = target and target.Player
					if not player and isUnwhitelist then
						player = playersService:FindFirstChild(prefix)
					end
					if not player then
						notif('Whitelist', 'No player found.', 5, 'warning')
						return
					end

					local friends = vape.Categories.Friends
					local isWhitelisted = table.find(friends.ListEnabled, player.Name) ~= nil
					if isUnwhitelist then
						if isWhitelisted then
							friends:ChangeValue(player.Name)
						end
						notif('Whitelist', player.DisplayName..' has been unwhitelisted.', 5)
						return
					end

					if not isWhitelisted then
						friends:ChangeValue(player.Name)
					end
					notif('Whitelist', player.DisplayName..' has been whitelisted.', 5)
				elseif loweredMessage == '.unview' then
					restoreCamera()
				elseif loweredCommand == 'tp' and cPlayerTP.Enabled then
					prefix = prefix:match('^%s*(.-)%s*$')
					local target = findPlayer(prefix)
					if not target or not target.RootPart then
						notif('ChatCommand', 'No living player found.', 5, 'warning')
						return
					end

					if entitylib.character and entitylib.character.RootPart then
						entitylib.character.RootPart.CFrame = target.RootPart.CFrame + Vector3.new(0, 2, 0)
					end
				elseif loweredCommand == 'view' and cPlayerView.Enabled and prefix then
					prefix = prefix:match('^%s*(.-)%s*$')
					local target = findPlayer(prefix)
					if not target then
						notif('ChatCommand', 'No living player found.', 5, 'warning')
						return
					end

					if target.Humanoid then
						clearViewDeathConnection()
						gameCamera.CameraSubject = target.Humanoid
						viewDeathConnection = target.Humanoid.Died:Connect(function()
							viewDeathConnection = nil
							local character = lplr.Character
							local localHumanoid = character and character:FindFirstChildOfClass('Humanoid')
								or (entitylib.character and entitylib.character.Humanoid)
							if localHumanoid then
								gameCamera.CameraSubject = localHumanoid
								gameCamera.CameraType = Enum.CameraType.Custom
							end
						end)
						vape:Clean(viewDeathConnection)
					end
				elseif loweredMessage == '.canceltween' or loweredMessage == '.stoptween' then
					if tweenInProgress then
						cleanupTween()
						notif('TweenTP', 'Tween cancelled.', 3)
					else
						notif('TweenTP', 'No tween in progress.', 3, 'warning')
					end
				elseif (loweredMessage == '.pos' or loweredMessage == '.tween' or loweredMessage == '.tweenpos' or loweredMessage == '.tppos' or loweredMessage == '.goto' or (loweredCommand and (loweredCommand == 'pos' or loweredCommand == 'tween' or loweredCommand == 'tweenpos' or loweredCommand == 'tppos' or loweredCommand == 'goto'))) and (not cTweenTP or cTweenTP.Enabled) then
					local targetPos = Vector3.new(817, 90, 2228)
					if prefix then
						local x, y, z = prefix:match('^([%-%d%.]+)[%s,]+([%-%d%.]+)[%s,]+([%-%d%.]+)')
						if x and y and z and tonumber(x) and tonumber(y) and tonumber(z) then
							targetPos = Vector3.new(tonumber(x), tonumber(y), tonumber(z))
						end
					end
					tweenToAndBack(targetPos)
				end
			end))
		else
			restoreCamera()
			cleanupTween()
		end
	end
})

cPlayerTP = ChatCommand:CreateToggle({
	Name = 'PlayerTP',
	Default = true,
})

cPlayerView = ChatCommand:CreateToggle({
	Name = 'PlayerView',
	Default = true,
	Function = function(callback)
		if callback then
			oldCameraSubject = gameCamera.CameraSubject
		else
			restoreCamera()
		end
	end
})

cRejoin = ChatCommand:CreateToggle({
	Name = 'Rejoin',
	Default = true
})

cServerHop = ChatCommand:CreateToggle({
	Name = 'ServerHop',
	Default = true
})

cReloadVape = ChatCommand:CreateToggle({
	Name = 'ReloadVape',
	Default = true
})

cChangeTeam = ChatCommand:CreateToggle({
	Name = 'ChangeTeam',
	Default = true
})

cWhitelist = ChatCommand:CreateToggle({
	Name = 'Whitelist',
	Default = true
})

cTweenTP = ChatCommand:CreateToggle({
	Name = 'TweenTP',
	Default = true
})

cTweenSpeed = ChatCommand:CreateSlider({
	Name = 'Tween Speed',
	Min = 50,
	Max = 500,
	Default = 200,
	Suffix = function(val)
		return val..' studs/s'
	end
})

cTweenWait = ChatCommand:CreateSlider({
	Name = 'Return Delay',
	Min = 0,
	Max = 5,
	Decimal = 10,
	Default = 0.5,
	Suffix = function(val)
		return val == 1 and 'second' or 'seconds'
	end
})