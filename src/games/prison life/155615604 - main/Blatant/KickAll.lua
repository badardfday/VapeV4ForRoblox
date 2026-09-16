local KickAll
local Movement
local didClick = {}
local lastFling = {}
local tempList = setmetatable({}, {
	__mode = 'k'
})

local FLING_VELOCITY = 100000   -- way above what phys/anti-cheat tolerates
local FLING_ANGULAR  = 5000     -- spin the seat so target gets rotated into the ground
local REAPPLY_TICKS  = 3        -- how many frames to re-hit each seat

local function getTarget(seat)
	if tempList[seat] and tempList[seat].Health > 0 and not tempList[seat].Humanoid.Sit then
		return tempList[seat]
	end

	if entitylib.isAlive then
		local cloned = table.clone(entitylib.List)
		table.sort(cloned, function(a, b)
			return (lastFling[a.Player.Name] or 0) < (lastFling[b.Player.Name] or 0)
		end)

		for _, entity in cloned do
			if not select(2, whitelist:get(entity.Player)) then continue end
			if entity.Player.Team == teams.Neutral then continue end
			if not (entity.Humanoid.Sit and entity.Humanoid.SeatPart.Anchored) and entity.Humanoid.Health > 0 and (os.clock() - entity.SpawnTime) > 5 then
				lastFling[entity.Player.Name] = os.clock()
				tempList[seat] = entity
				table.clear(cloned)
				notif('KickAll', 'Attempted fling: '..entity.Player.Name, 5)
				return entity
			end
		end

		table.clear(cloned)
	end
end

local function hardFling(seat, target)
	local randX = math.random(-1, 1)
	local randZ = math.random(-1, 1)
	local vel = Vector3.new(
		FLING_VELOCITY * (randX == 0 and 1 or randX),
		FLING_VELOCITY,
		FLING_VELOCITY * (randZ == 0 and 1 or randZ)
	)
	local ang = Vector3.new(
		FLING_ANGULAR * (math.random() > 0.5 and 1 or -1),
		FLING_ANGULAR,
		FLING_ANGULAR * (math.random() > 0.5 and 1 or -1)
	)

	seat.CFrame = CFrame.new(target.RootPart.Position) * CFrame.Angles(
		math.random() * math.pi * 2,
		math.random() * math.pi * 2,
		math.random() * math.pi * 2
	)
	sethiddenproperty(seat, 'PhysicsRepRootPart', target.RootPart)

	seat.AssemblyLinearVelocity  = vel
	seat.AssemblyAngularVelocity = ang

	task.spawn(function()
		for _ = 1, REAPPLY_TICKS do
			if not seat or not seat.Parent then break end
			seat.AssemblyLinearVelocity  = vel
			seat.AssemblyAngularVelocity = ang
			runService.Heartbeat:Wait()
		end
	end)

	local wheels = seat.Parent and seat.Parent.Parent and seat.Parent.Parent:FindFirstChild('Wheels')
	if wheels then
		wheels:Destroy()
	end
end

KickAll = vape.Categories.Blatant:CreateModule({
	Name = 'KickAll',
	Function = function(callback)
		if callback then
			if vape.Modules.AntiFling and not vape.Modules.AntiFling.Enabled then
				vape.Modules.AntiFling:Toggle()
			end

			KickAll:Clean(runService.Heartbeat:Connect(function()
				if entitylib.isAlive then
					local root = entitylib.character.RootPart
					if Movement and Movement.Enabled and ((root.Position - Vector3.new(633, 98, 2489)).Magnitude < 40 or (os.clock() - entitylib.character.SpawnTime) < 0.4) then
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

					for _, seat in workspace.CarContainer:QueryDescendants('VehicleSeat') do
						if isnetworkowner(seat) then
							local target = getTarget(seat)
							if target then
								hardFling(seat, target)
							end
						end
					end
				end
			end))
		end
	end,
	Tooltip = 'aesthetical, just remove collisions on vehicles please, this is the worst.'
})

Movement = KickAll:CreateToggle({
	Name = 'Movement',
	Default = true
})