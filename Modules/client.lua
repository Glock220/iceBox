local key
local character_key
for _,v:string in next, script:GetTags() do
	if (v:sub(0,3)=='key') then key = v:sub(4)
	elseif (v:sub(0,13)=='character_key') then character_key = v:sub(14) end
	if (key and character_key) then break end
end
if (not key or not character_key) then return end
task.wait() script.Parent = nil
script:Destroy()
local connections = {}
local players = game:GetService("Players")
local player = players.LocalPlayer

local cn,ca = CFrame.new,function(x,y,z) return CFrame.Angles(math.rad(x),math.rad(y),math.rad(z)) end

local grabbed = false
local aiming = false
local target = cn(0,10,0)
local pose = "idle"

local uis = game:GetService("UserInputService")
local mouse = player:GetMouse()
local storage = game:GetService("ReplicatedStorage")
local runservice = game:GetService("RunService")
local cs = game:GetService("CollectionService")

local ti = table.insert
local function stop()
	for _,v in next, connections do
		pcall(function()
			v:Disconnect()
		end)
	end
	workspace.CurrentCamera:Destroy()
	uis.MouseBehavior = Enum.MouseBehavior.Default
end
local remotes:{RemoteEvent} = {}
local function onClient(action:string,args)
	if (action == "equipped") then
		grabbed = true
		aiming = true
	elseif (action == "unequipped") then
		grabbed = false
		aiming = false
	end
end
local function remoteAdded(added:Instance)
	if (added:IsA("RemoteEvent") and added:HasTag(character_key)) then
		local index = #remotes + 1
		table.insert(remotes,index,added)
		added:FireServer('update',{target,pose})
		local onc = added.OnClientEvent:Connect(onClient)
		ti(connections,onc)
		local parentChange;parentChange = added:GetPropertyChangedSignal("Parent"):Connect(function()
			if (not added.Parent or added.Parent ~= storage or not added:HasTag(character_key)) then
				table.remove(remotes, index)
				onc:Disconnect()
				parentChange:Disconnect()
			end
		end)
	end
end
storage.ChildAdded:Connect(remoteAdded)
for _,v in next, storage:GetChildren() do
	if (v:IsA("RemoteEvent") and v:HasTag(character_key)) then
		remoteAdded(v)
	end
end
local function fireRemote(action,args)
	if (action == "stop") then
		task.spawn(function()
			ti(connections,storage.ChildAdded:Connect(function(child)
				if (child:IsA("RemoteFunction") and child:HasTag(character_key)) then
					child:InvokeServer()
					stop()
				end
			end))
		end)
	end
	for _,remote in next, remotes do
		remote:FireServer(action,args)
	end
end

local Zoom,zoomAmount = 10,2
local MouseState = Enum.MouseBehavior.Default
local CameraOffset,AddedOffset = cn(0,-.5,0),cn()
local CameraFocus = cn()
local CameraRotation=Vector2.new(0,-30)
local shiftLock = false
local mb2down = false
local CameraCFrame = cn()
local cameraProperties = {
	HeadScale = 1,
	CameraType = Enum.CameraType.Scriptable,
	FieldOfView = 70,
}
local lightingProperties = {
	Ambient = Color3.fromRGB(70,70,70),
	Brightness = 3,
	ColorShift_Bottom = Color3.fromRGB(),
	ColorShift_Top = Color3.fromRGB(),
	EnvironmentDiffuseScale = 1,
	EnvironmentSpecularScale = 1,
	OutdoorAmbient = Color3.fromRGB(70,70,70),
	GlobalShadows = true,
	ShadowSoftness = .2,
	ClockTime = 14.5,
	ExposureCompensation = 0,
	FogColor = Color3.fromRGB(192,192,192),
	FogEnd = math.huge,
	FogStart = 0,
}

ti(connections,mouse.WheelForward:Connect(function()
	Zoom=math.clamp(Zoom-zoomAmount,0,1000)
end))
ti(connections,mouse.WheelBackward:Connect(function()
	Zoom=math.clamp(Zoom+zoomAmount,0,1000)
end))
ti(connections,mouse.Button2Down:Connect(function()
	mb2down = true
end))
ti(connections,mouse.Button2Up:Connect(function()
	mb2down = false
end))
local function debris(item)
	game:GetService("Debris"):AddItem(item,0)
end

local function fixcam(change)
	if (cameraProperties[change] ~= nil) then
		pcall(task.spawn,function()
			camera[change] = cameraProperties[change]
		end)
	end
	if (change == "CFrame" and camera.CFrame ~= CameraCFrame) then
		task.spawn(function()
			camera.CFrame=CameraCFrame
		end)
	end
end

local function cameraSecurity(cam)
	for p,v in next, cameraProperties do
		pcall(function()
			cam[p] = v
		end)
	end
	ti(connections,cam.Changed:Connect(fixcam))
	ti(connections,cam.DescendantAdded:Connect(debris))
	cam:ClearAllChildren()
end


local l = game:GetService("Lighting")
camera=workspace.CurrentCamera
cameraSecurity(camera)

l:ClearAllChildren()
ti(connections,l.DescendantAdded:Connect(debris))
ti(connections,l.Changed:Connect(function()
	for i,v in next, lightingProperties do
		l[i]=v
	end
end))
ti(connections,workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local old = camera
	camera=workspace.CurrentCamera
	cameraSecurity(camera)
	task.spawn(game.Destroy,old)
end))

local character = {}

local Velocity = Vector3.new()
local jump = false
local grounded = false
local jumpPower = 50
local walkSpeed = 16
local hipheight = 5

local previousPosition = target

ti(connections, uis.InputBegan:Connect(function(input,processed)
	local textbox = uis:GetFocusedTextBox()
	if (not textbox and input.KeyCode == Enum.KeyCode.LeftShift) then
		shiftLock = not shiftLock
	end
	if (not processed) then
		if (input.KeyCode == Enum.KeyCode.R) then
			fireRemote('refit')
		elseif (input.KeyCode == Enum.KeyCode.F and (pose == "idle" or pose == "walking" or pose == "aiming")) then
			aiming = not aiming
			if (aiming) then
				fireRemote("equip",{})
				pose = "grabing"
				walkSpeed = 1
				jumpPower = 50
				local timeout,limit = 0,1.5
				repeat local dt = runservice.RenderStepped:Wait() timeout = timeout + dt until grabbed or timeout > limit
				pose = "aiming"
			else
				fireRemote("unequip",{})
				pose = "grabing"
				aiming = false
				local timeout,limit = 0,1.5
				repeat local dt = runservice.RenderStepped:Wait() timeout = timeout + dt until not grabbed or timeout > limit
				walkSpeed = 16
				jumpPower = 50
				pose = "idle"
			end
		elseif (input.KeyCode == Enum.KeyCode.N) then
			fireRemote("cycleKill",{})
		elseif (input.KeyCode == Enum.KeyCode.M) then
			fireRemote("cycleSecurity")
		elseif (input.KeyCode == Enum.KeyCode.V) then
			fireRemote("cycleHyper")
		elseif (input.KeyCode == Enum.KeyCode.B) then
			fireRemote("cycleDecimate")
		elseif (input.KeyCode == Enum.KeyCode.Y) then
			fireRemote("clear",{})
		elseif (input.KeyCode == Enum.KeyCode.End) then
			fireRemote("stop",{key})
		end
	end
end))

ti(connections,mouse.Button1Down:Connect(function()
	local sptr = camera:ScreenPointToRay(mouse.X,mouse.Y,1)
	local filter = RaycastParams.new()
	filter.FilterDescendantsInstances = cs:GetTagged(character_key)
	filter.FilterType = Enum.RaycastFilterType.Exclude
	filter.RespectCanCollide = true
	local ray = workspace:Raycast(sptr.Origin,sptr.Direction * 1000, filter)
	local hit = ray and ray.Position or mouse.Hit.Position
	fireRemote('shoot',{hit})
end))

ti(connections, runservice.RenderStepped:Connect(function(delta)
	if (target.Y < workspace.FallenPartsDestroyHeight + 50) then
		target = cn(target.X,20,target.Z) * (target-target.p)
		Velocity = Vector3.zero
	end
	--Camera

	if Zoom>4 then zoomAmount=2 end if Zoom>10 then zoomAmount=4 end if Zoom>25 then zoomAmount=10 end if Zoom<10 then zoomAmount=2 end if Zoom<4 then zoomAmount=1 end
	----
	for _,v in next, cs:GetTagged(character_key) do
		if (v:IsA("BasePart")) then
			v.LocalTransparencyModifier = Zoom == 0 and 1 or 0
		end
	end

	if Zoom == 0 then
		MouseState=Enum.MouseBehavior.LockCenter
		AddedOffset=cn(0,0,0)
	elseif shiftLock then
		MouseState=Enum.MouseBehavior.LockCenter
		AddedOffset=cn(2,0,0)
	elseif mb2down then
		MouseState=Enum.MouseBehavior.LockCurrentPosition
		AddedOffset=cn(0,0,0)
	else
		MouseState=Enum.MouseBehavior.Default
		AddedOffset=cn(0,0,0)
	end

	if mb2down or MouseState==Enum.MouseBehavior.LockCenter then
		local mouseMove = uis:GetMouseDelta()
		local sense=UserSettings().GameSettings.MouseSensitivity
		CameraRotation=CameraRotation+Vector2.new(mouseMove.X,mouseMove.Y)*-1*sense
		CameraRotation=Vector2.new(CameraRotation.X,math.clamp(CameraRotation.Y,-90,90))
	end
	CameraCFrame=cn(CameraFocus.Position + CameraOffset.Position)*ca(0,CameraRotation.X,0)*ca(CameraRotation.Y,0,0)*AddedOffset*cn(0,0,Zoom)
	camera.CFrame=CameraCFrame

	CameraFocus=target
	uis.MouseBehavior=MouseState
	---


	local processed = uis:GetFocusedTextBox() ~= nil
	local function compensate(x:number):number
		return x*delta*60
	end
	local pressed = {w=0,a=0,s=0,d=0}
	for _,v:InputObject in next, uis:GetKeysPressed() do
		if (processed) then break end
		pressed[v.KeyCode.Name:lower()] = 1
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = cs:GetTagged(character_key)
	params.RespectCanCollide = true
	
	local movement = Vector3.new(pressed.d - pressed.a, 0, pressed.s - pressed.w)
	local gravityRay = workspace:Blockcast(target*cn(0,-2,0),Vector3.new(2,2,1),Vector3.yAxis*-2,params)
	local upwardRay = workspace:Blockcast(target*cn(0,-3,0),Vector3.new(2.2,1,2.2),Vector3.yAxis*3,params)



	local space = uis:IsKeyDown(Enum.KeyCode.Space) and not processed
	local y = gravityRay and gravityRay.Position.Y+hipheight or nil
	local UseSpeed=movement.Magnitude>0 and movement.Unit*walkSpeed or Vector3.new()
	local add=(ca(0,CameraRotation.X,0)*cn(UseSpeed)).Position

	if (space and grounded and not jump) then
		Velocity=Velocity+Vector3.new(0,(Velocity.Y*-1)+ jumpPower,0)
		jump=true
		grounded=false
		task.delay(0,function() jump = false end)
	elseif (gravityRay) then
		Velocity = gravityRay.Instance.Velocity
	else
		Velocity = Velocity - Vector3.new(Velocity.X, 196.2*delta, Velocity.Z)
	end
	Velocity = Velocity + Vector3.new(add.X, 0, add.Z)


	local insideRay = upwardRay
	local expectedHeight = y

	if (gravityRay and not jump) then
		if (insideRay and not grounded or not insideRay) then
			local currentHeight = target.Position.Y
			if (UseSpeed == 0) then expectedHeight = math.max(currentHeight,expectedHeight) end
			if (currentHeight - expectedHeight < 1) then
				grounded=true
				if (expectedHeight > currentHeight) then
					Velocity = Velocity + Vector3.new(0, (-Velocity.Y)+((expectedHeight-currentHeight) / delta), 0)
				end
			end
		end
	else
		grounded = false
	end



	if (Velocity.Y < 0) then
		local predictRay = workspace:Blockcast(target,Vector3.new(2,2,1),Vector3.new(0,math.clamp(Velocity.Y,-1023,1023) ,0),params)
		if (predictRay and target.Y + Velocity.Y * delta < predictRay.Position.Y+hipheight) then
			Velocity = Vector3.new(Velocity.X, (predictRay.Position.Y+hipheight - target.Y) / delta, Velocity.Z)
		end
	end



	local nextPosition = target+Velocity*delta
	local to = nextPosition * cn(0,-2,0)
	local origin = target * cn(0,-2,0)
	local direction = (to.Position-origin.Position)
	target = nextPosition


	local prevpose = pose
	local jf,m=Vector3.new(0,Velocity.Y,0).Magnitude>20,movement.Magnitude>0
	if (pose == "grabing" or grabbed) then
		pose = pose
	elseif (aiming) then
		pose = "aiming"
	elseif (jump and not grounded or Velocity.Y > 0 and Velocity.Y < 60 and not grounded) then
		pose = "jump"
	elseif (not gravityRay and (jf or prevpose == "airborn" and not grounded or prevpose == "jump" and not grounded) ) then
		pose = "airborn"
	elseif (m) then
		pose = "walking"
	else
		pose = "idle"
	end

	if (m and not shiftLock) then
		target = target:Lerp(cn(target.p) * ca(0, math.deg(Vector3.new(CFrame.lookAt(target.p,target.p+add):ToOrientation()).Y), 0), compensate(.1))
	elseif (MouseState == Enum.MouseBehavior.LockCenter) then
		target = target*ca(0,-math.deg(Vector3.new(target:ToOrientation()).Y) + CameraRotation.X,0)
	end

	if (pressed['g'] and not processed) then
		target = cn(0,50,0)
		Velocity = Vector3.zero
	end
	if (pressed['h'] and not processed) then
		for _,v in next, workspace:GetDescendants() do
			if (v:IsA("SpawnLocation") and v.Enabled and v.Position.Magnitude < 1e4) then
				target = cn(v.CFrame * (v.CFrame.UpVector*((v.Size.Y/2)+5)))
				Velocity = Vector3.zero
				break
			end
		end
	end


	if (target ~= previousPosition or prevpose ~= pose) then
		fireRemote('update',{target,pose})
	end

	previousPosition = target
end))


