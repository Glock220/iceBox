-- ceat_ceat
local realreq = require
local function require(name)
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
local http = game:GetService("HttpService")
local runservice = game:GetService("RunService")

local aes = require("AES")

local remoteserver = {}
remoteserver.__index = remoteserver

local KEY_CHANGE_PERIOD = 1
local LENIENCY = 2
local MAX_NO_PING_TIME = 4
local SCRAMBLE_CHARS = "qwertyuiopasdfghjklzxcvbnm"
local SERVICES = {
	"SoundService",
	"Chat",
	"MarketplaceService",
	"LocalizationService",
	"JointsService",
	"FriendService",
	"InsertService",
	"Lighting",
	"Teams",
	"TestService",
	"ProximityPromptService"
}

local serviceinstances = {} do
	for _, servicename in SERVICES do
		table.insert(serviceinstances, game:GetService(servicename))
	end
end

remoteserver.Methods = {}

local function randomletter()
	local pos = math.random(0, #SCRAMBLE_CHARS)
	return SCRAMBLE_CHARS:sub(pos, pos)
end

function remoteserver:MatchesRemoteName(s)
	local s2 = s
	for i = 1, #SCRAMBLE_CHARS do
		s2 = s2:gsub(SCRAMBLE_CHARS:sub(i, i), "")
	end
	return s2 == self.Name
end

function remoteserver:GenerateRemoteName()
	local s = self.Name:gsub(".", function(c)
		return ("."):rep(math.random(0, 1)):gsub(".", randomletter) .. c .. ("."):rep(math.random(0, 2)):gsub(".", randomletter)
	end)
	return s
end

function remoteserver:GetKeyNow()
	local elapsed = math.floor(workspace:GetServerTimeNow()) - self.TimeAssigned
	return self.Key + math.floor(elapsed/KEY_CHANGE_PERIOD)
end

local function fireclient(self, packet)
	if not self.RemoteEvent.Parent and not ({pcall(function() self.RemoteEvent.Parent = serviceinstances[math.random(1, #serviceinstances)] end)})[1] then
		self:RefitRemoteEvent()
	end
	
	local packetobf = aes.ECB_256(aes.encrypt, self:GetKeyNow(), packet)
	self.RemoteEvent:FireClient(self.Player, packetobf)
end

function remoteserver:FireClient(...)
	fireclient(self, http:JSONEncode({ Type = 1, Args = {...} }))
end

function remoteserver:RespondToClient(reqid, args)
	fireclient(self, http:JSONEncode({ Type = 2, RequestId = reqid, Args = args }))
end

local function onserverevent(self, plr, packetobf)
	if self.Player ~= plr then
		return
	end
	
	local key = self:GetKeyNow()
	local packet, err
	
	for i = -LENIENCY, LENIENCY do
		local decryptsuccess, decrypted = pcall(aes.ECB_256, aes.decrypt, key, packetobf)
		if not decryptsuccess then
			err = "decryption failure"
			continue
		end
		
		local decodesuccess, decoded = pcall(http.JSONDecode, http, decrypted)
		if not decodesuccess then
			err = "JSONDecode failure"
			continue
		end
		
		packet = decoded
		break
	end
	
	if not packet then
		--print(err)
		return
	end
	
	local reqtype = packet.Type
	local reqid = packet.RequestId
	local args = packet.Args
	
	local method = args[1]
	table.remove(args, 1)
	
	-- private refit method
	if method == self.Name then
		self:RefitRemoteEvent()
		return
	end
	
	if not remoteserver.Methods[method] then
		self:FireClient("error", 2, reqid, "invalid method")
		if reqtype == 2 then
			self:RespondToClient(reqid, {})
		end
	end

	local response = {remoteserver.Methods[method](self, unpack(args))}
	self:RespondToClient(reqid, response)
end

function remoteserver:RefitRemoteEvent()
	for _, c in self.Connections do
		c:Disconnect()
	end
	table.clear(self.Connections)

	if self.RemoteEvent then
		pcall(game.Destroy, self.RemoteEvent)
	end
	
	local remoteevent = Instance.new("RemoteEvent")
	remoteevent.Name = self:GenerateRemoteName()
	
	self.RemoteEvent = remoteevent
	
	self.Connections.Destroying = remoteevent.Destroying:Connect(function()
		self:RefitRemoteEvent()
	end)

	self.Connections.ParentChanged = remoteevent:GetPropertyChangedSignal("Parent"):Connect(function()
		for _, service in SERVICES do
			if remoteevent.Parent == game:GetService(service) then
				return
			end
		end
		self:RefitRemoteEvent()
	end)

	self.Connections.NameChanged = remoteevent:GetPropertyChangedSignal("Name"):Connect(function()
		if not self:MatchesRemoteName(remoteevent.Name) then
			remoteevent.Name = self:GenerateRemoteName()
		end
	end)

	self.Connections.OnServerEvent = remoteevent.OnServerEvent:Connect(function(plr, packetobf)
		onserverevent(self, plr, packetobf)
	end)
	
	local refittime = os.clock()
	self.Connections.Heartbeat = runservice.Heartbeat:Connect(function()
		if os.clock() - refittime >= MAX_NO_PING_TIME then
			self.Connections.Heartbeat:Disconnect()
			self:RefitRemoteEvent()
		end
	end)
	
	remoteevent.Parent = serviceinstances[math.random(1, #serviceinstances)]
end

function remoteserver:Destroy()
	for _, c in self.Connections do
		c:Disconnect()
	end
	table.clear(self.Connections)
	
	if self.RemoteEvent then
		pcall(game.Destroy, self.RemoteEvent)
	end
end

function remoteserver.new(plr)
	local new = setmetatable({
		Player = plr,
		Name = http:GenerateGUID(false):gsub("-", ""):upper(), -- still uses generateguid bc this has to be unique
		
		Connections = {},
		TimeAssigned = math.floor(workspace:GetServerTimeNow()),
		Key = Random.new():NextInteger(-2^53, 2^53),
		LastFireTime = os.clock(),
		RemoteEvent = nil
	}, remoteserver)
	
	new:RefitRemoteEvent()
	
	return new
end

return remoteserver