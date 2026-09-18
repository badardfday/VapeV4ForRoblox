local KickPlayer
local Movement
local didClick = {}
local tempList = setmetatable({}, { __mode = 'k' })

local GuardTarget
local InmateTarget
local CriminalTarget
local NeutralTarget

local activeTarget = nil
local watcherConns = {}
local dir = 0

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
	for _, value in {GuardTarget.Value, InmateTarget.Value, CriminalTarget.Value, NeutralTarget.Value} do
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
	if entitylib.isAlive then
		for _, entity in entitylib.List do
			if entity.Player == player then
				return entity
			end
		end
	end
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass('Humanoid')
		local root = char:FindFirstChild('HumanoidRootPart')
		if hum and root then
			return {
				Player = player,
				Character = char,
				Humanoid = hum,
				RootPart = root,
				SpawnTime = 0,
			}
		end
	end
end

local function isValidTarget(entity)
	if not entity then return false end
	if not entity.Humanoid then return false end
	if entity.Humanoid.Sit and entity.Humanoid.SeatPart and entity.Humanoid.SeatPart.Anchored then return false end
	if not select(2, whitelist:get(entity.Player)) then return false end
	if entity.Player.Team == teams.Neutral then return false end
	if entity.Humanoid.Health > 0 and (os.clock() - entity.SpawnTime) <= 5 then return false end
	return true
end

local function getTarget(seat)
	local targetPlayer = selectedTarget()
	if not targetPlayer then return end

	local cached = tempList[seat]
	if cached and cached.Player == targetPlayer and isValidTarget(cached) and cached.RootPart then
		return cached
	end

	local entity = findEntity(targetPlayer)
	if not isValidTarget(entity) then return end

	tempList[seat] = entity
	notif('KickPlayer', 'Attempted fling: '..entity.Player.Name, 5)
	return entity
end

local function getFlingPart(entity)
	local root = entity.RootPart
	if not root then return end
	local isDead = entity.Humanoid and entity.Humanoid.Health <= 0
	if not isDead then return root end
	local char = root.Parent
	if not char then return root end
	return char:FindFirstChild('UpperTorso')
		or char:FindFirstChild('Torso')
		or char:FindFirstChild('Head')
		or root
end

local function stiffenVehicle(seat)
	local vehicle = seat.Parent and seat.Parent.Parent
	if not vehicle then return end

	for _, d in vehicle:GetDescendants() do
		if d:IsA('Motor6D') then
			pcall(function() d.MaxForce = math.huge end)
			pcall(function() d.MaxTorque = math.huge end)
		elseif d:IsA('HingeConstraint')
			or d:IsA('CylindricalConstraint')
			or d:IsA('BallSocketConstraint')
			or d:IsA('PrismaticConstraint')
			or d:IsA('AlignPosition')
			or d:IsA('AlignOrientation')
		then
			pcall(function() d.MaxForce = math.huge end)
			pcall(function() d.MaxTorque = math.huge end)
			pcall(function() d.MaxVelocity = math.huge end)
			pcall(function() d.Responsiveness = math.huge end)
		elseif d:IsA('Weld') or d:IsA('WeldConstraint') then
			pcall(function() d.Enabled = true end)
		end
	end
end

local function flingSeat(seat, target)
	local part = getFlingPart(target)
	if not part then return end

	local isDead = target.Humanoid and target.Humanoid.Health <= 0

	if isDead then
		stiffenVehicle(seat)
		seat.AssemblyLinearVelocity = Vector3.new(10000, 10000, 10000)
		seat.AssemblyAngularVelocity = Vector3.new(20000, 20000, 20000)
		seat.CFrame = CFrame.new(part.Position) * CFrame.new(-2, -2, -12)
	else
		seat.AssemblyLinearVelocity = Vector3.new(10000, 10000, 0)
		seat.CFrame = CFrame.new(part.Position) * CFrame.new(-2, -2, -12)
		sethiddenproperty(seat, 'PhysicsRepRootPart', part)

		local vehicle = seat.Parent and seat.Parent.Parent
		local wheels = vehicle and vehicle:FindFirstChild('Wheels')
		if wheels then
			wheels:Destroy()
		end
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

			KickPlayer:Clean(runService.Heartbeat:Connect(function(dt)
				if not entitylib.isAlive then return end

				local sel = selectedTarget()
				if not sel then
					clearWatchers()
					return
				end

				if sel and sel ~= activeTarget then
					watchTarget(sel)
				end

				local root = entitylib.character.RootPart
				local didMove

				for _, button in workspace.Prison_ITEMS.buttons:GetChildren() do
					if button.Name == 'Car Spawner' then
						local mag = (button['Car Spawner'].Position - root.Position).Magnitude
						if mag < 15 and (didClick[button] or 0) < os.clock() then
							didClick[button] = os.clock() + 0.2
							task.spawn(function()
								replicatedStorage.Remotes.InteractWithItem:InvokeServer(button['Car Spawner'])
							end)
						end

						if mag < 50 and button['Car Spawner'].BrickColor == BrickColor.new('Cyan') and not didMove then
							local diff = math.clamp((button['Car Spawner'].Position - root.Position).X, -1, 1)
							dir = math.clamp(dir + (diff * dt * 26), -12, 14)
							didMove = true
						end
					end
				end

				if not didMove then
					local diff = math.clamp(0 - dir, -1, 1)
					dir = math.clamp(dir + (diff * dt * 26), -12, 14)
				end

				if Movement.Enabled and ((root.Position - Vector3.new(633, 98, 2489)).Magnitude < 40 or (os.clock() - entitylib.character.SpawnTime) < 0.4) then
					root.CFrame = CFrame.new(Vector3.new(610 + dir, 90, 2494))
					root.AssemblyLinearVelocity = Vector3.zero
				end

				for _, seat in workspace.CarContainer:QueryDescendants('VehicleSeat') do
					local ok, ownsSeat = pcall(isnetworkowner, seat)
					if ok and ownsSeat then
						local target = getTarget(seat)
						if target then
							flingSeat(seat, target)
						end
					end
				end
			end))
		else
			clearWatchers()
			table.clear(tempList)
			dir = 0
		end
	end,
	Tooltip = 'Kicks player specifically. Auto-disables once the target is kicked.'
})

Movement = KickPlayer:CreateToggle({ Name = 'Movement', Default = true })
GuardTarget = KickPlayer:CreateDropdown({ Name = 'Guard', List = playerNames('Guards') })
InmateTarget = KickPlayer:CreateDropdown({ Name = 'Inmates', List = playerNames('Inmates') })
NeutralTarget = KickPlayer:CreateDropdown({ Name = 'Neutral', List = playerNames('Neutral') })
CriminalTarget = KickPlayer:CreateDropdown({ Name = 'Criminals', List = playerNames('Criminals') })

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