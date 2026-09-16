local SkidDetector
local Users
local httpService = cloneref and cloneref(game:GetService('HttpService')) or game:GetService('HttpService')

local skidsFile = 'newvape/profiles/skids.json'
local localSkids = {}

local function loadLocalSkids()
	if isfile and isfile(skidsFile) then
		local suc, res = pcall(function()
			return httpService:JSONDecode(readfile(skidsFile))
		end)
		if suc and type(res) == 'table' then
			localSkids = res
		end
	end
end

local function saveLocalSkids()
	if writefile then
		pcall(function()
			if isfolder and not isfolder('newvape/profiles') then
				if makefolder then makefolder('newvape/profiles') end
			end
			writefile(skidsFile, httpService:JSONEncode(localSkids))
		end)
	end
end

loadLocalSkids()

local cUsernames = {
		['WyRaff'] = 'speedhack,teleporting',
		['PraiseDracc'] = 'known exploiter',
		['jerry_plsnoban7'] = 'known exploiter (kerax)',
		['jerry_plsnoban6'] = 'known exploiter (kerax)',
		['jerry_plsnoban5'] = 'known exploiter (kerax)',
		['rudeeis_ab'] = 'phase/noclip ahhh hack', -- saint member, dont they even use the same thing
		['JOJI12416'] = 'known exploiter (kerax owner)', -- kerax if u wonder
		['DawnPulseVoid'] = 'known exploiter',
		['BestCode_BaconThx']= 'known exploiter (kerax)',   -- join .gg/prisonlife if u got flagged by this dude, we wanna laugh at u
		['RazhulanDeveloper'] = 'known exploiter (kerax)', -- join .gg/prisonlife if u got flagged by this dude, we wanna laugh at u
		['SaintSkirr'] = 'known exploiter (vape)', -- not a big deal, why kerax just why
		['centipedeinmyheads'] = 'known exploiter (kerax)', -- NOT another saint member lol, kerax user
		['FishHunterGDA'] = 'exploiter (kerax)',
		['egegwtwytw'] = 'exploiter (kerax)',
		['roskskjs'] = 'exploiter (kerax)',
		['LaylaPowerGalaxy'] = 'exploiter (kerax)',
		['Def12ne5'] = 'exploiter (kerax)',
		['antikick37'] = 'blatant cheating',
		['Eaglertestsubject1'] = 'kerax admin user',
		-- skids list
		["veggeta38372737"] = "kerax user, abuser", -- most kerax users are skids abusing so, yeah
		['jbskjbg'] = 'invalid state Platform Stand exp',
		['1267_isevil'] = 'failed fling attempt',
		['1987_isevil'] = 'failed fling attempt',
		['HeyiamTheCooolest'] = 'skid exploiter',
		['Chill_baconr00'] = 'highjump', --  using vape v4 from Night5449791 and cant beat me XD
		['gcfhjfjf4'] = 'highjump, aimbot',
		['dannielll51'] = 'headsit exploit', -- inspired, vape antiheadsit soon.
		['Bonjour394'] = 'skid exploiter', -- hes js a jerk
		['princeofegypt'] = 'gets kicked for fling attempt', -- imagine gets kicked for script that kicks
		['bilinmez4095'] = 'invalid state Platform Stand',
		['djdjdd54321'] = 'phase/noclip into walls',
		['cnmjm222'] = 'invisible',
		['oyeuser67'] = 'speedhack',
		['BetterCallMe788'] = 'fling',
		['Avacad0731'] = 'phase/noclip',
		['C0nquerons'] = 'Platform Stand exploit',
		['goobyzoobytv'] = 'phase/noclip',
		['Joni_8824'] = 'phase/noclip',
		['jaycomputing'] = 'skid using selenium larps and got kicked',
		['tooodarl9'] = 'skid exploiter',
		['Henr45555455'] = 'invalid state Platform Stand',
		['Marssimo_14'] = 'invalid state Platform Stand',
		['boy_cantot2'] = 'invalid state Platform Stand',
		['killerdoy372bro'] = 'invalid animation',
		['trervoTDJ'] = 'aimbotting',
		['Pedro9Henrique2000'] = 'phase/noclip',
		["faizan1111789"] = "speed",
		['juanpro231ew'] = "invalid state Swimming",
		["voidwalker5346"] = "invalid animation (car kick)",
		["mchser3"] = "invalid state Swimming",
		["ang5454"] = "highjump",
		['rackasauras'] = 'speed',
		["dobys149"] = "phase/noclip",
		["SyntaxK3v"] = "speed",
		["Thacosmick_2"] = "invalid state Swimming",
		["Unicornpoop1239508"] = "speed",
		["kind_jack001"] = "invalid animation (invis)",
		["lilyazz0000"] = "invalid state PlatformStanding (fly)",
		["nobby_rules2"] = "speed",
		["duimaxxing"] = "phase/noclip",
		['sauodwuansd212'] = 'fling/kickall'
	}

local function findPlr(prefix)
	if not prefix or prefix == '' then return nil end
	local lowered = prefix:lower()
	for _, p in playersService:GetPlayers() do
		if p.Name:lower() == lowered or p.DisplayName:lower() == lowered then
			return p
		end
	end
	for _, p in playersService:GetPlayers() do
		if p.Name:lower():sub(1, #lowered) == lowered or p.DisplayName:lower():sub(1, #lowered) == lowered then
			return p
		end
	end
	return nil
end

local function flagPlayer(plr, reason)
	if not plr then return end
	reason = reason or 'known exploiter'
	notif('SkidDetector', 'Skid Detected ('..reason..'): '..plr.Name..' ('..plr.DisplayName..')', 15, 'alert')
	if whitelist and whitelist.customtags then
		whitelist.customtags[plr.Name] = {{text = 'Exploiter', color = Color3.new(1, 0, 0)}}
	end
	if tempTargets then
		tempTargets[plr.Name] = true
	end
	if entitylib and entitylib.getEntity then
		local entity = entitylib.getEntity(plr)
		if entity then
			entity.Target = true
			if entitylib.Events and entitylib.Events.EntityUpdated then
				entitylib.Events.EntityUpdated:Fire(entity)
			end
		end
	end
end

local function playerAdded(plr)
	local reason = cUsernames[plr.Name]
	if not reason and localSkids then
		reason = localSkids[plr.Name] or localSkids[plr.Name:lower()] or localSkids[plr.DisplayName:lower()] or localSkids[tostring(plr.UserId)]
	end
	if not reason and Users then
		for _, item in Users.ListEnabled do
			if item:lower() == plr.Name:lower() or item:lower() == plr.DisplayName:lower() or item == tostring(plr.UserId) then
				reason = 'known exploiter'
				break
			end
		end
	end

	if reason then
		flagPlayer(plr, reason)
	end
end

local function addSkid(targetStr, reason)
	targetStr = targetStr and targetStr:match('^%s*(.-)%s*$')
	if not targetStr or targetStr == '' then
		notif('SkidDetector', 'Please specify a username or displayname.', 5, 'warning')
		return
	end

	local foundPlr = findPlr(targetStr)
	local username = foundPlr and foundPlr.Name or targetStr
	local displayName = foundPlr and foundPlr.DisplayName or targetStr
	local userId = foundPlr and tostring(foundPlr.UserId) or nil
	reason = reason and reason ~= '' and reason or 'known exploiter'

	localSkids[username] = reason
	localSkids[username:lower()] = reason
	if displayName and displayName ~= username then
		localSkids[displayName:lower()] = reason
	end
	if userId then
		localSkids[userId] = reason
	end
	saveLocalSkids()

	if Users and not table.find(Users.List, username) then
		Users:ChangeValue(username)
	end

	if foundPlr then
		flagPlayer(foundPlr, reason)
		notif('SkidDetector', 'Added and flagged '..username..' as a cheater!', 5)
	else
		notif('SkidDetector', 'Saved '..username..' locally as a cheater.', 5)
	end
end

local function removeSkid(targetStr)
	targetStr = targetStr and targetStr:match('^%s*(.-)%s*$')
	if not targetStr or targetStr == '' then
		notif('SkidDetector', 'Please specify a username or displayname.', 5, 'warning')
		return
	end

	local foundPlr = findPlr(targetStr)
	local username = foundPlr and foundPlr.Name or targetStr
	local displayName = foundPlr and foundPlr.DisplayName or nil
	local userId = foundPlr and tostring(foundPlr.UserId) or nil

	localSkids[username] = nil
	localSkids[username:lower()] = nil
	if displayName then
		localSkids[displayName:lower()] = nil
	end
	if userId then
		localSkids[userId] = nil
	end
	saveLocalSkids()

	if Users and table.find(Users.List, username) then
		Users:ChangeValue(username)
	end

	if foundPlr then
		if whitelist and whitelist.customtags then
			whitelist.customtags[foundPlr.Name] = nil
		end
		if tempTargets then
			tempTargets[foundPlr.Name] = nil
		end
	end

	notif('SkidDetector', 'Removed '..username..' from skid list.', 5)
end

vape.AddSkid = addSkid
vape.RemoveSkid = removeSkid

local function handleChat(message)
	if message:sub(1, 1) ~= '.' then return end
	local command, arg = message:match('^%.(%S+)%s*(.-)$')
	if not command then return end
	local loweredCommand = command:lower()

	if loweredCommand == 'addskid' or loweredCommand == 'skid' then
		local name, reason = arg:match('^(%S+)%s*(.*)$')
		if name and name ~= '' then
			addSkid(name, reason ~= '' and reason or nil)
		else
			notif('SkidDetector', 'Usage: .addskid <username or displayname> [reason]', 5, 'warning')
		end
	elseif loweredCommand == 'remskid' or loweredCommand == 'delskid' or loweredCommand == 'unskid' then
		local name = arg:match('^(%S+)')
		if name and name ~= '' then
			removeSkid(name)
		else
			notif('SkidDetector', 'Usage: .remskid <username or displayname>', 5, 'warning')
		end
	end
end

SkidDetector = vape.Categories.Utility:CreateModule({
	Name = 'SkidDetector',
	Function = function(callback)
		if callback then
			SkidDetector:Clean(playersService.PlayerAdded:Connect(playerAdded))
			SkidDetector:Clean(lplr.Chatted:Connect(handleChat))
			for _, v in playersService:GetPlayers() do
				task.spawn(playerAdded, v)
			end
		end
	end,
	Tooltip = 'Detects people with history of cheating',
})

Users = SkidDetector:CreateTextList({
	Name = 'Custom Skids',
	Placeholder = 'Username / UserId',
	Function = function(list)
		for _, v in list do
			if not localSkids[v] then
				localSkids[v] = 'manual entry'
			end
		end
		saveLocalSkids()
	end
})