local realreq = require
local function requireM(name)
	local success, returned = pcall(function()
		return game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/Glock220/iceBox/main/Modules/"..name..".lua")
	end)
	if(success)then
		local succ, load, err = pcall(function()
			return loadstring(returned)
		end)
		if(not succ)then
			error(load)
		end
		if(not load and err)then
			error(err)
		end
		return load()
	else
		return realreq(name)
	end
end
local tags = script:GetTags()
local effects = requireM("effects")
task.wait()
script.Parent = nil
script:Destroy()
local storage = game:GetService("ReplicatedStorage")
local key
for _,v in next, tags do
	if (v:sub(0,13) == "character_key") then
		key = v:sub(14)
		break
	end
end
if (not key) then return end
local function onClient(effect, args)
	if (effect == 'muzzle') then
		effects.muzzleFlash(args.position)
	elseif (effect == 'beam') then
		effects.beam(args.from,args.to)
	elseif (effect == 'kill') then
		effects.kill(args.part,args.center)
	end
end
local function checkremote(remote:RemoteEvent)
	if (remote:IsA('RemoteEvent') and remote:HasTag(key)) then
		local onc = remote.OnClientEvent:Connect(onClient)
		local change,destroy;
		local function onRemove()
			if (remote.Parent == storage) then return end
			change:Disconnect()
			destroy:Disconnect()
			onc:Disconnect()
		end
		change = remote:GetPropertyChangedSignal("Parent"):Connect(onRemove)
		destroy = remote.Destroying:Connect(onRemove)
	end
end

storage.ChildAdded:Connect(checkremote)
for _,v in next, game:GetService("ReplicatedStorage"):GetChildren() do
	checkremote(v)
end
