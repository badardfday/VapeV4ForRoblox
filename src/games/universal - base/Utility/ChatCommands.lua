local ChatCommand
local cPlayerTP
local cPlayerView
local cRejoin
local cServerHop
local cReloadVape
local cChangeTeam
local cWhitelist
local cPosTP
local cTPMethod
local cTPSpeed
local cTPWait
local oldCameraSubject
local viewDeathConnection
local teamsService = game:GetService('Teams')
local runService = cloneref and cloneref(game:GetService('RunService')) or game:GetService('RunService')
local noclipConnection
local activeRoot
local tpInProgress = false

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

local motorMove = motorMove or function(target, cf)
	local part = Instance.new('Part')
	part.Anchored = true
	part.Parent = workspace
	local motor = Instance.new('Motor6D')
	motor.Part0 = target
	motor.Part1 = part
	motor.C1 = cf
	motor.Parent = part
	task.delay(0, part.Destroy, part)
end

local function cleanupTP()
	if noclipConnection then
		noclipConnection:Disconnect()
		noclipConnection = nil
	end
	if activeRoot and activeRoot.Parent then
		activeRoot.AssemblyLinearVelocity = Vector3.zero
		activeRoot.AssemblyAngularVelocity = Vector3.zero
	end
	activeRoot = nil
	tpInProgress = false
end

local function lerpStepTo(root, humanoid, destinationPos, speed)
	local reached = false
	local connection
	connection = runService.PreSimulation:Connect(function(dt)
		if not (humanoid and humanoid.Health > 0 and root and root.Parent and tpInProgress) then
			if connection then connection:Disconnect() end
			return
		end

		local currentPos = root.Position
		local diff = destinationPos - currentPos
		local dist = diff.Magnitude

		if dist <= 3 then
			root.CFrame = CFrame.lookAlong(destinationPos, root.CFrame.LookVector)
			root.AssemblyLinearVelocity = Vector3.zero
			reached = true
			if connection then connection:Disconnect() end
			return
		end

		local step = math.min(dist, speed * dt)
		root.CFrame = root.CFrame + (diff.Unit * step)
		root.AssemblyLinearVelocity = Vector3.zero
	end)

	while not reached and tpInProgress do
		if not (humanoid and humanoid.Health > 0 and root and root.Parent) then
			if connection then connection:Disconnect() end
			return false
		end
		task.wait()
	end
	if connection then connection:Disconnect() end
	return reached
end

local function velocityStepTo(root, humanoid, destinationPos, speed)
	local reached = false
	local connection
	connection = runService.PreSimulation:Connect(function()
		if not (humanoid and humanoid.Health > 0 and root and root.Parent and tpInProgress) then
			if connection then connection:Disconnect() end
			return
		end

		local currentPos = root.Position
		local diff = destinationPos - currentPos
		local dist = diff.Magnitude

		if dist <= 6 then
			root.CFrame = CFrame.lookAlong(destinationPos, root.CFrame.LookVector)
			root.AssemblyLinearVelocity = Vector3.zero
			reached = true
			if connection then connection:Disconnect() end
			return
		end

		root.AssemblyLinearVelocity = diff.Unit * speed
	end)

	while not reached and tpInProgress do
		if not (humanoid and humanoid.Health > 0 and root and root.Parent) then
			if connection then connection:Disconnect() end
			return false
		end
		task.wait()
	end
	if connection then connection:Disconnect() end
	return reached
end

local function teleportToAndBack(targetPos, methodOverride)
	if tpInProgress then
		notif('PosTP', 'Teleport already in progress! Say .canceltp to cancel.', 3, 'warning')
		return
	end

	local character = lplr.Character
	local root = entitylib.character and entitylib.character.RootPart or (character and (character:FindFirstChild('HumanoidRootPart') or character:FindFirstChild('Torso')))
	local humanoid = entitylib.character and entitylib.character.Humanoid or (character and character:FindFirstChildOfClass('Humanoid'))

	if not (character and root and humanoid and humanoid.Health > 0) then
		notif('PosTP', 'Character not available or dead.', 3, 'warning')
		return
	end

	local method = methodOverride or (cTPMethod and cTPMethod.Value or 'Lerp')
	local speed = cTPSpeed and cTPSpeed.Value or 300
	local waitTime = cTPWait and cTPWait.Value or 0.5

	tpInProgress = true
	activeRoot = root

	task.spawn(function()
		local originalCFrame = root.CFrame
		local targetCFrame = CFrame.new(targetPos) * originalCFrame.Rotation

		noclipConnection = runService.Stepped:Connect(function()
			if character and character.Parent then
				for _, part in character:GetChildren() do
					if part:IsA('BasePart') then
						part.CanCollide = false
					end
				end
			end
		end)

		notif('PosTP', string.format('[%s] Moving to (%.0f, %.0f, %.0f)...', method, targetPos.X, targetPos.Y, targetPos.Z), 3)

		local success = false
		if method == 'CFrame' then
			root.CFrame = targetCFrame
			root.AssemblyLinearVelocity = Vector3.zero
			success = true
		elseif method == 'Motor' then
			motorMove(root, targetCFrame)
			root.AssemblyLinearVelocity = Vector3.zero
			success = true
		elseif method == 'Velocity' then
			success = velocityStepTo(root, humanoid, targetPos, speed)
		else
			success = lerpStepTo(root, humanoid, targetPos, speed)
		end

		if not success or not tpInProgress or not (humanoid and humanoid.Health > 0 and root.Parent) then
			cleanupTP()
			return
		end

		root.CFrame = targetCFrame
		root.AssemblyLinearVelocity = Vector3.zero

		if waitTime > 0 then
			task.wait(waitTime)
		end

		if not tpInProgress or not (humanoid and humanoid.Health > 0 and root.Parent) then
			cleanupTP()
			return
		end

		notif('PosTP', string.format('[%s] Returning to start position...', method), 3)

		if method == 'CFrame' then
			root.CFrame = originalCFrame
			root.AssemblyLinearVelocity = Vector3.zero
		elseif method == 'Motor' then
			motorMove(root, originalCFrame)
			root.AssemblyLinearVelocity = Vector3.zero
		elseif method == 'Velocity' then
			velocityStepTo(root, humanoid, originalCFrame.Position, speed)
		else
			lerpStepTo(root, humanoid, originalCFrame.Position, speed)
		end

		if tpInProgress and root and root.Parent then
			root.CFrame = originalCFrame
		end

		cleanupTP()
		notif('PosTP', 'Returned successfully!', 3)
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
				elseif loweredMessage == '.canceltp' or loweredMessage == '.stoptp' or loweredMessage == '.canceltween' or loweredMessage == '.stoptween' or loweredMessage == '.cancel' then
					if tpInProgress then
						cleanupTP()
						notif('PosTP', 'Teleport cancelled.', 3)
					else
						notif('PosTP', 'No teleport in progress.', 3, 'warning')
					end
				elseif (loweredMessage == '.pos' or loweredMessage == '.tp2' or loweredMessage == '.tppos' or loweredMessage == '.goto' or loweredMessage == '.tween' or loweredMessage == '.tweenpos' or (loweredCommand and (loweredCommand == 'pos' or loweredCommand == 'tp2' or loweredCommand == 'tppos' or loweredCommand == 'goto' or loweredCommand == 'tween' or loweredCommand == 'tweenpos'))) and (not cPosTP or cPosTP.Enabled) then
					local targetPos = Vector3.new(817, 90, 2228)
					local methodOverride = nil
					if prefix then
						local loweredPrefix = prefix:lower()
						if loweredPrefix:find('cframe') then
							methodOverride = 'CFrame'
						elseif loweredPrefix:find('motor') then
							methodOverride = 'Motor'
						elseif loweredPrefix:find('velo') then
							methodOverride = 'Velocity'
						elseif loweredPrefix:find('lerp') or loweredPrefix:find('step') then
							methodOverride = 'Lerp'
						end

						local x, y, z = prefix:match('([%-%d%.]+)[%s,]+([%-%d%.]+)[%s,]+([%-%d%.]+)')
						if x and y and z and tonumber(x) and tonumber(y) and tonumber(z) then
							targetPos = Vector3.new(tonumber(x), tonumber(y), tonumber(z))
						end
					end
					teleportToAndBack(targetPos, methodOverride)
				elseif loweredCommand and (loweredCommand == 'addskid' or loweredCommand == 'skid') then
					if vape.AddSkid then
						local name, reason = prefix:match('^(%S+)%s*(.*)$')
						vape.AddSkid(name or prefix, reason ~= '' and reason or nil)
					else
						local skidsFile = 'newvape/profiles/skids.json'
						local localSkids = {}
						if isfile and isfile(skidsFile) then
							pcall(function()
								localSkids = game:GetService('HttpService'):JSONDecode(readfile(skidsFile)) or {}
							end)
						end
						local name, reason = prefix:match('^(%S+)%s*(.*)$')
						name = name or prefix
						reason = reason ~= '' and reason or 'known exploiter'
						localSkids[name] = reason
						localSkids[name:lower()] = reason
						if writefile then
							pcall(function()
								writefile(skidsFile, game:GetService('HttpService'):JSONEncode(localSkids))
							end)
						end
						notif('SkidDetector', 'Added '..name..' to Skid list (saved locally).', 5)
					end
				elseif loweredCommand and (loweredCommand == 'remskid' or loweredCommand == 'delskid' or loweredCommand == 'unskid') then
					if vape.RemoveSkid then
						local name = prefix:match('^(%S+)')
						vape.RemoveSkid(name or prefix)
					else
						local skidsFile = 'newvape/profiles/skids.json'
						local localSkids = {}
						if isfile and isfile(skidsFile) then
							pcall(function()
								localSkids = game:GetService('HttpService'):JSONDecode(readfile(skidsFile)) or {}
							end)
						end
						local name = prefix:match('^(%S+)') or prefix
						localSkids[name] = nil
						localSkids[name:lower()] = nil
						if writefile then
							pcall(function()
								writefile(skidsFile, game:GetService('HttpService'):JSONEncode(localSkids))
							end)
						end
						notif('SkidDetector', 'Removed '..name..' from Skid list.', 5)
					end
				end
			end))
		else
			restoreCamera()
			cleanupTP()
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

cPosTP = ChatCommand:CreateToggle({
	Name = 'PosTP',
	Default = true
})

cTPMethod = ChatCommand:CreateDropdown({
	Name = 'TP Method',
	List = {'Lerp', 'CFrame', 'Motor', 'Velocity'}
})

cTPSpeed = ChatCommand:CreateSlider({
	Name = 'TP Speed',
	Min = 50,
	Max = 1000,
	Default = 300,
	Suffix = function(val)
		return val..' studs/s'
	end
})

cTPWait = ChatCommand:CreateSlider({
	Name = 'Return Delay',
	Min = 0,
	Max = 5,
	Decimal = 10,
	Default = 0.5,
	Suffix = function(val)
		return val == 1 and 'second' or 'seconds'
	end
})