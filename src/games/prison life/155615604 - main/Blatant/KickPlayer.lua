local KickPlayer
local Movement
local didClick = {}
local tempList = setmetatable({}, {
	__mode = 'k'
})

local GuardTarget
local InmateTarget
local CriminalTarget
local NeutralTarget

local activeTarget = nil
local watcherConns = {}

local function playerNames(teamName)
	local names = {'None'}
	for _, player in playersService:GetPlayers() do
		if player ~= lplr and player.Team and player.Team.Name == teamName then
			table.insert(names, player.DisplayName .. ' - ' .. player.Name)
		end
	end
	return names
end

local function getTargetPlayer(value)
	local username = value:match(' %- (.+)$')
	return username and playersService:FindFirstChild(username)
end

local function selectedTarget()
	for _, value in {GuardTarget.Value, InmateTarget.Value, CriminalTarget.Value} do
		local player = getTargetPlayer(value)
		if player then return player end
	end
end

local function refreshTargets()
	GuardTarget:Change(playerNames('Guards'))
	InmateTarget:Change(playerNames('Inmates'))
	CriminalTarget:Change(playerNames('Criminals'))
    NeutralTarget:Change(playerNames('Neutral'))
end

local function findEntity(player)
	if not entitylib.isAlive then return end
	for _, entity in entitylib.List do
		if entity.Player == player then
			return entity
		end
	end
end

local function isValidTarget(entity)
	if not entity then return false end
	if not entity.Humanoid or entity.Humanoid.Health <= 0 then return false end
	if entity.Humanoid.Sit and entity.Humanoid.SeatPart and entity.Humanoid.SeatPart.Anchored then return false end
	if not select(2, whitelist:get(entity.Player)) then return false end
	if entity.Player.Team == teams.Neutral then return false end
	if (os.clock() - entity.SpawnTime) <= 5 then return false end
	return true
end

local function getTarget(seat)
	local targetPlayer = selectedTarget()
	if not targetPlayer then return end

	local cached = tempList[seat]
	if cached and cached.Player == targetPlayer and isValidTarget(cached) then
		return cached
	end

	local entity = findEntity(targetPlayer)
	if not isValidTarget(entity) then return end

	tempList[seat] = entity
	notif('KickPlayer', 'Attempted fling: '..entity.Player.Name, 5)
	return entity
end

local function flingSeat(seat, target)
	seat.AssemblyLinearVelocity = Vector3.new(10000, 10000, 0)
	seat.CFrame = CFrame.new(target.RootPart.Position) * CFrame.new(-2, -2, -12)
	sethiddenproperty(seat, 'PhysicsRepRootPart', target.RootPart)

	local wheels = seat.Parent.Parent:FindFirstChild('Wheels')
	if wheels then
		wheels:Destroy()
	end
end

local function clearWatchers()
	for _, conn in watcherConns do
		conn:Disconnect()
	end
	table.clear(watcherConns)
	activeTarget = nil
end

local function watchTarget(plr)
	clearWatchers()
	if not plr then return end

	activeTarget = plr

	table.insert(watcherConns, playersService.PlayerRemoving:Connect(function(removed)
		if removed == plr and KickPlayer and KickPlayer.Enabled then
			notif('KickPlayer', plr.Name..' has been kicked / left. Disabling.', 5)
			task.defer(function()
				if KickPlayer.Enabled then
					KickPlayer:Toggle()
				end
			end)
		end
	end))
end

KickPlayer = vape.Categories.Blatant:CreateModule({
	Name = 'KickPlayer',
	Function = function(callback)
		if callback then
			if vape.Modules.AntiFling and not vape.Modules.AntiFling.Enabled then
				vape.Modules.AntiFling:Toggle()
			end

			watchTarget(selectedTarget())

			KickPlayer:Clean(runService.Heartbeat:Connect(function()
				if entitylib.isAlive then
					local sel = selectedTarget()
					if sel and sel ~= activeTarget then
						watchTarget(sel)
					end

					local root = entitylib.character.RootPart
					if Movement.Enabled and ((root.Position - Vector3.new(633, 98, 2489)).Magnitude < 40 or (os.clock() - entitylib.character.SpawnTime) < 0.4) then
						root.CFrame = CFrame.new(Vector3.new(612 + math.sin(os.clock() * 1.3) * 12, 90, 2494))
						root.AssemblyLinearVelocity = Vector3.zero
					end

					for _, button in workspace.Prison_ITEMS.buttons:GetChildren() do
						if button.Name == 'Car Spawner' and (button['Car Spawner'].Position - root.Position).Magnitude < 15 and (didClick[button] or 0) < os.clock() then
							didClick[button] = os.clock() + 0.2
							task.spawn(function()
								replicatedStorage.Remotes.InteractWithItem:InvokeServer(button['Car Spawner'])
							end)
						end
					end

					if selectedTarget() then
						for _, seat in workspace.CarContainer:QueryDescendants('VehicleSeat') do
							if isnetworkowner(seat) then
								local target = getTarget(seat)
								if target then
									flingSeat(seat, target)
								end
							end
						end
					end
				end
			end))
		else
			clearWatchers()
		end
	end,
	Tooltip = 'Kicks player specifically. Auto-disables once the target is kicked.'
})

Movement = KickPlayer:CreateToggle({
	Name = 'Movement',
	Default = true
})

GuardTarget = KickPlayer:CreateDropdown({
	Name = 'Guard',
	List = playerNames('Guards')
})
InmateTarget = KickPlayer:CreateDropdown({
	Name = 'Inmates',
	List = playerNames('Inmates')
})
NeutralTarget = KickPlayer:CreateDropdown({
	Name = 'Neutral',
	List = playerNames('Neutral')
})
CriminalTarget = KickPlayer:CreateDropdown({
	Name = 'Criminals',
	List = playerNames('Criminals')
})

refreshTargets()

playersService.PlayerAdded:Connect(function(player)
	player:GetPropertyChangedSignal('Team'):Connect(refreshTargets)
	refreshTargets()
end)
playersService.PlayerRemoving:Connect(refreshTargets)
for _, player in playersService:GetPlayers() do
	if player ~= lplr then
		player:GetPropertyChangedSignal('Team'):Connect(refreshTargets)
	end
end