local ChatCommand
local cPlayerTP
local cPlayerView
local cRejoin
local cServerHop
local cReloadVape
local cChangeTeam
local cWhitelist
local oldCameraSubject
local viewDeathConnection
local teamsService = game:GetService('Teams')

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
					loadstring(game:HttpGet('https://raw.githubusercontent.com/Night5449791/VapeV4ForRoblox/main/NewMainScript.lua', true))()
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
				end
			end))
		else
			restoreCamera()
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