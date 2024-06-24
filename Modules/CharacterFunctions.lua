local module = {}
local oldbilbord = nil
local talking = false
local playingSong = false
local currentSong = false
local randomSong = nil
local timePosition = 0
local oldSong = "142376088"
local songs = {
	{SongId = "142376088"},
	{SongId = "1844487326"},
	{SongId = "9048375035"},
	{SongId = "1842652230"},
	{SongId = "1836137438"},
	{SongId = "1837015572"},
	{SongId = "1837015572"},
	{SongId = "9038255279"},
	{SongId = "1842959945"},
	{SongId = "9042479935"},
	{SongId = "9042370540"},
	{SongId = "9043731019"},
	{SongId = "9043730968"},
	{SongId = "9043730981"}
}

function module:Raycast(POSITION, DIRECTION, IGNOREDECENDANTS)
	return workspace:FindPartOnRayWithIgnoreList(Ray.new(POSITION, DIRECTION), IGNOREDECENDANTS)
end
function module:RemoveOBJ(Obj,Time)
	task.spawn(function()
		if Time >= 0 then
			task.wait(Time)
		end
		pcall(function()
			Obj:Destroy()
		end)
	end)
end
function module:PlaySound(SOUNDID,PART,REMOVETIME,VOL,PITCH,POS)
	local SOUND = Instance.new("Sound",PART)
	local deletion
	SOUND.SoundId = SOUNDID
	SOUND.Volume = VOL
	SOUND.PlaybackSpeed = PITCH
	if not POS then
		SOUND.TimePosition = 0
	else 	
		SOUND.TimePosition = POS
	end
	SOUND:Play()
	task.wait(0.01)
	deletion = SOUND.Ended:Connect(function()
		SOUND:Destroy()
		deletion:Disconnect()
	end)
	return SOUND
end
function module:FindPartByTag(char,tagName,isCustomCharacter)
	local part, partName = nil, nil 
	if isCustomCharacter then 
		for _, limb in pairs(char:GetChildren()) do
			if limb:IsA("BasePart") then 
				for _, tag in pairs(limb:GetTags()) do
					if tag == tagName then
						part = limb
						partName = tagName
						break 
					end
				end
				if part then break end 
			end
		end
	else
		for _, limb in pairs(char) do
			if limb.VarValue ~= false then
				for _, tag in pairs(limb.VarValue:GetTags()) do
					if tag == tagName then
						part = limb.VarValue
						partName = tagName
						break 
					end
				end
				if part then break end
			end
		end
	end
	return part, partName
end
function module:FindPart(char,Name)
	local part = false
	for i,limb in char do
		if typeof(limb.VarValue) ~= "boolean" then
			if limb.LimbName == Name then
				part = limb.VarValue
			end	
		end	
	end
	return part
end
function module:GetLimbsInTable(char)
	local t = {}
	for _, limb in char do
		if typeof(limb.VarValue) ~= "boolean" then
			table.insert(t,limb.VarValue)
		end
	end
	return t 
end
function module.limbConfg(owner,char,limb,Name,mouse)
	if Name == "Head" then
		local event = Instance.new("RemoteEvent",mouse.Remotes)
		event.Name = "Cam"
		delay(0.15,function()
			event:Destroy()
		end)
		task.wait(0.05)
		event:FireClient(owner,owner.Name,limb)
	end
	if Name == "BoomBox" then
		if playingSong then
			module:EnableMusic(char,false)
		end
	end
end
function module.method(f,num,speed,multi)
	local t = 0
	local a 
	a = game:GetService("RunService").Heartbeat:Connect(function()
		t = t + (speed * multi or .01)
		f()	
		if t >= num then
			task.wait()
			a:Disconnect()
		end

	end)
end
function module:EnableMusic(char,songIndex,turnOff)
	if turnOff then
		playingSong = false
		if currentSong and currentSong ~= "gone" then
			currentSong:Destroy()
			wait(0.1)
			currentSong = "gone"
		end
		return
	end
	if not turnOff then
		playingSong = true
		timePosition = 0
		randomSong = songs[songIndex]
		coroutine.wrap(function()
			while true do
				task.wait()
				if not module:FindPartByTag(char,"Head",false) then 
					if currentSong and currentSong ~= "gone" then
						currentSong:Destroy()
						wait(0.1)
						currentSong = "gone"
					end
					break end
				if not playingSong then
					if currentSong and currentSong ~= "gone" then
						currentSong:Destroy()
						wait(0.1)
						currentSong = "gone"
					end
					break 
				end
				if not currentSong or currentSong.Parent == nil then
				else
					timePosition = currentSong.TimePosition
				end
				if not currentSong or currentSong.Parent == nil then
					local head,name = module:FindPartByTag(char,"Head",false)
					currentSong = module:PlaySound("rbxassetid://"..randomSong.SongId,head,1,1,1,timePosition)
					wait()
					currentSong.Looped = true
				end
			end
		end)()
	end
end
function module:Talk(char,Text)
	task.spawn(function()
		if oldbilbord then
			oldbilbord:Destroy()
		end
		local gone = false
		local bilbordGUI = Instance.new("BillboardGui",workspace.Terrain)
		bilbordGUI.Size = UDim2.new(20,0,1,0)
		bilbordGUI.AlwaysOnTop = false
		bilbordGUI.MaxDistance = 100
		bilbordGUI.Brightness = 100
		bilbordGUI.StudsOffset = Vector3.new(0,2.5,0)
		local textLabel = Instance.new("TextLabel",bilbordGUI)
		textLabel.MaxVisibleGraphemes = 0
		wait()
		textLabel.Text = Text
		textLabel.BackgroundTransparency = 1
		textLabel.TextStrokeTransparency = 0
		textLabel.TextColor3 = Color3.fromRGB(197, 197, 197)
		textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		textLabel.TextScaled = true
		textLabel.Font = Enum.Font.Code
		textLabel.Interactable = false
		textLabel.Size = UDim2.new(1,0,1,0)
		oldbilbord = bilbordGUI
		spawn(function()
			while true do
				task.wait()
				if gone or not bilbordGUI  then break end
				bilbordGUI.Adornee = module:FindPartByTag(char,"Head",false)
			end
		end)
		talking = true
		for i=1,string.len(Text) do
			task.wait(0.05)
			if string.sub(Text,i,i) == "." or string.sub(Text,i,i) == "?" or string.sub(Text,i,i) == "," then
				wait(0.6)
			end
			if string.sub(Text,i,i) == " " then
				task.wait(0.05)
			end
			textLabel.MaxVisibleGraphemes += 1
			module:PlaySound("rbxassetid://7772738671",module:FindPartByTag(char,"Head",false),5,1,Random.new():NextNumber(0.7,1.2),0)
		end
		talking = false
		wait(3)
		game:GetService("TweenService"):Create(textLabel,TweenInfo.new(1,Enum.EasingStyle.Exponential),{TextTransparency = 1,TextStrokeTransparency = 1}):Play()
		wait(1)
		bilbordGUI:Destroy()
		gone = true
	end)
end
return module
