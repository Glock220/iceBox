wait(); script.Parent = nil
local clientScripts = {}
local scriptEnvs = {}
local script = script

local players = game:GetService("Players")
local context = game:GetService("ScriptContext")
local replicated = game:GetService("ReplicatedStorage")
local teleport = game:GetService('TeleportService')
local http = game:GetService("HttpService")
local player = players.LocalPlayer
local Library = script.Library
local RbxGui = require(Library:WaitForChild("RbxGui"))
local RbxStamper = require(Library:WaitForChild("RbxStamper"))
local RbxUtility = require(Library:WaitForChild("RbxUtility"))

local mainEnv = getfenv(0)
local mainEnvFunc = setfenv(1, mainEnv);
mainEnv.script = nil

local coroutine = {wrap = coroutine.wrap, create = coroutine.create, resume = coroutine.resume};
local string = {gsub = string.gsub, sub = string.sub, lower = string.lower, gmatch = string.gmatch, match = string.match, format = string.format, find = string.find};
local table = {insert = table.insert, remove = table.remove, sort = table.sort, concat = table.concat};
local os = os;
local next = next;
local tonumber = tonumber;
local getfenv = getfenv;
local getmetatable = getmetatable;
local unpack = unpack;
local setmetatable = setmetatable;
local ypcall = ypcall;
local xpcall = xpcall;
local pairs = pairs;
local rawget = rawget;
local newproxy = newproxy;
local shared = shared;
local collectgarbage = collectgarbage;
local rawset = rawset;
local ipairs = ipairs;
local type = type;
local tostring = tostring;
local gcinfo = gcinfo;
local rawequal = rawequal;
local select = select;
local print = print;
local pcall = pcall;
local assert = assert;
local loadstring = loadstring;
local setfenv = setfenv;
local error = error;
local _G = _G;

-------------------------------------------------------------

local function sendData(plyr, data, sync)
	local player2 = player
	if player2 and player2:IsA("Player") then
		local type, text = unpack(data)
		if type == "Print" then
			print(text)
		elseif type == "Warn" then
			warn(text)
		elseif type == "Error" then
			error(text, 0)
		elseif type == "Run" then
			game:GetService("TestService"):Message(text)
		end
	end
end

local newProxyEnv;
local proxies = setmetatable({}, {__mode="v"});

local customLibrary = {
	print = function(...)
		local owner = scriptEnvs[getfenv(0)]
		local args = {...}
		for i = 1, select("#", ...) do
			args[i] = tostring(args[i])
		end
		sendData(owner.Name, {"Print", table.concat(args, "\t")}, true)
	end, 
	warn = function(text)
		local owner = scriptEnvs[getfenv(0)]
		sendData(owner.Name, {"Warn", tostring(text)}, true)
	end,
	getfenv = function(arg)
		local typ = type(arg);
		local env;
		if (typ == "number" and arg >= 0) then
			local lvl = (arg == 0 and 0 or arg+1);
			env = getfenv(lvl);
		elseif (typ == "nil") then
			env = getfenv(2);
		elseif (typ == "function") then
			env = getfenv(arg);
		else
			getfenv(arg);
		end
		if (env == mainEnv) then
			return getfenv(0);
		else
			return env;
		end
	end,
	setfenv = function(arg, tbl)
		local typ = type(arg);
		local func;
		if (typ == "number" and arg >= 0) then
			local lvl = (arg == 0 and 0 or arg+1);
			func = setfenv(lvl, tbl);
		elseif (typ == "function") then
			func = setfenv(arg, tbl);
		else
			setfenv(arg, tbl);
		end
		if (func == mainEnvFunc) then
			setfenv(mainEnvFunc, mainEnv);
			error("Error occured setfenv");
		else
			return func;
		end
	end,
	LoadLibrary = function(library)
		assert(library and type(library) == "string", "Bad argument")
		local LoadLibrary = function(Lib)
			Lib = string.lower(Lib)
			if Lib=="rbxgui" then
				return RbxGui
			elseif Lib=="rbxstamper" then
				return RbxStamper
			elseif Lib=="rbxutility" then
				return RbxUtility
			end
		end
		if LoadLibrary(library) then
			local Library = LoadLibrary(library)
			local userdata = newproxy(true)
			local meta = getmetatable(userdata)
			meta.__index = function(self, index)
				return Library[index]
			end
			meta.__tostring = function(self)
				return library
			end
			meta.__metatable = "The metatable is locked"
			return userdata
		else
			error("Invalid library name")
		end
	end,
	_G = _G,
	shared = shared
}

function newProxyEnv(script, owner)	
	local env = setmetatable({script = script; owner = owner}, {
		__index = function(self, index)
			if (not scriptEnvs[getfenv(0)]) then error("Script ended"); end
			rawset(mainEnv, index, nil);
			local lib = (customLibrary[index] or mainEnv[index]);
			if (proxies[lib]) then 
				return proxies[lib]; 
			end
			if (lib and type(lib) == "function" and index ~= "setfenv" and index ~= "getfenv" and index ~= "error") then
				local func = function(...)
					if scriptEnvs[mainEnv.getfenv(0)] then
						local result = {pcall(lib, ...)}
						if (result[1]) then
							return unpack(result, 2)
						else
							error(result[2]:gsub("^.+:%d+:", ""):gsub("lib", index, 1), 2)
						end
						return lib(...)
					else
						error("Script ended", 0)
					end
				end
				proxies[lib] = func;
				return func;
			else
				return lib or rawget(_G, index);
			end
		end,
		__metatable = getmetatable(mainEnv)
	})
	return env
end

-------------------------------------------------------------


local userdata = newproxy(true)
local meta = getmetatable(userdata)
meta.__metatable = "The metatable is locked"

meta.__call = function(self, script)
	if not clientScripts[script] then
		local owner, name = player, script:GetFullName()
		local env = newProxyEnv(script, owner)
		setfenv(0, env)
		setfenv(2, env)
		scriptEnvs[env] = owner
		clientScripts[script] = {owner, name, env = env}
		sendData(owner.Name, {"Run", "Running ("..name..")"}, true)
	end 
end

return userdata
