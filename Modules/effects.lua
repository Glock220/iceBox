local ts = game:GetService("TweenService")
return {
	muzzleFlash = function(Position:CFrame)
		local particles = {
			shockwave = function()
				local p = Instance.new("Part")
				local t = ts:Create(p,TweenInfo.new(.2,Enum.EasingStyle.Circular),{
					Size = Vector3.one*2.6,
					Transparency = 1,
				})
				p.Shape = Enum.PartType.Ball
				p.CanTouch = false
				p.CanCollide = false
				p.CanQuery = false
				p.Anchored = true
				p.Transparency = .4
				p.Size = Vector3.zero
				p.Color = Color3.new(0,1,0)
				p.Material = Enum.Material.Neon
				p.CFrame = Position
				p.Parent = workspace
				t:Play()
				t.Completed:Once(function()
					t:Destroy()
					p:Destroy()
				end)
			end,
			blast = function()
				local p = Instance.new("Part")
				local m = Instance.new("SpecialMesh",p)
				local a = CFrame.Angles(math.rad(math.random(-180,180)),math.rad(math.random(-180,180)),math.rad(math.random(-180,180)))
				local t = ts:Create(p,TweenInfo.new(.3,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out),{
					Size = Vector3.new(.2,.2,1.7),
					CFrame = Position * CFrame.Angles(math.rad(math.random(-180,180)),math.rad(math.random(-180,180)),math.rad(math.random(-180,180))),
					Transparency = .9,
				})
				m.MeshType = Enum.MeshType.Sphere
				p.CanCollide = false
				p.CanQuery = false
				p.CanTouch = false
				p.Anchored = true
				p.Material = Enum.Material.Neon
				p.Transparency = .3
				p.Size = Vector3.new(.2,.2,.2)
				p.Color = Color3.new(0,1,0)
				p.CFrame = Position * a
				p.Parent = workspace
				t:Play()
				t.Completed:Once(function()
					t:Destroy()
					local t = ts:Create(p,TweenInfo.new(.3,Enum.EasingStyle.Cubic),{
						Size = Vector3.one*.2,
						Transparency = 1,
					})
					t:Play()
					t.Completed:Once(function()
						t:Destroy()
						p:Destroy()
					end)
				end)
			end,
			spreadParticle = function()
				local spreadAngle = 1
				local p = Instance.new("Part")
				local m = Instance.new("SpecialMesh",p)
				local len = math.random(30,50)/10
				local face = ((Position.LookVector*len)+ ((Position-Position.Position) *  CFrame.new(math.random(-spreadAngle,spreadAngle),math.random(-spreadAngle,spreadAngle),0)).Position)
				local look = CFrame.lookAt(Position.Position,Position.Position+face)
				local angle = (look-look.Position)
				angle = Vector3.new(angle:ToEulerAnglesXYZ())
				angle = CFrame.Angles(angle.X,0,angle.Z)
				local t = ts:Create(p,TweenInfo.new(.5,Enum.EasingStyle.Exponential),{
					CFrame = CFrame.new(Position.Position + face) * (look-look.Position),
					Transparency = 1
				})
				m.MeshType = Enum.MeshType.Sphere
				p.CanTouch = false
				p.CanCollide = false
				p.CanQuery = false
				p.Anchored = true
				p.Material = Enum.Material.Neon
				p.Color = Color3.new(0,1,0)
				p.Size = Vector3.new(.2,.2,1.6)
				p.CFrame = look
				p.Transparency = .3
				p.Parent = workspace
				t:Play()
				t.Completed:Once(function()
					p:Destroy()
					t:Destroy()
				end)
			end,
		}
		particles.shockwave()
		for i = 0, math.random(4,5) do
			particles.blast()
		end
		for i = 0, math.random(5,7) do
			particles.spreadParticle()
		end
	end,
	
	beam = function(from:CFrame, to:CFrame)
		local distance = (from.Position-to.Position).Magnitude > 1000 and 1000 or (from.Position-to.Position).Magnitude
		local look = CFrame.lookAt(from.Position,to.Position)
		local blast = Instance.new("Part")
		blast.Color = Color3.new(0,1,0)
		blast.Material = Enum.Material.Neon
		blast.Anchored = true
		blast.CanCollide = false
		blast.CanQuery = false
		blast.CanTouch = false
		blast.Transparency = .6
		local beam = blast:Clone()
		local mesh = Instance.new("SpecialMesh",beam)
		mesh.MeshType = Enum.MeshType.Sphere
		blast.Shape = Enum.PartType.Ball
		blast.Size = Vector3.one * 6
		blast.CFrame = to
		local innerBlast = blast:Clone()
		innerBlast.Size = blast.Size * .9
		innerBlast.Color = Color3.new(1,1,1)
		innerBlast.Transparency = .4
		beam.Size = Vector3.new(.6,.6,distance)
		beam.CFrame = look * CFrame.new(0,0,-distance/2)
		local innerBeam = beam:Clone()
		innerBeam.Size = beam.Size * .9
		innerBeam.Color = Color3.new(1,1,1)
		innerBeam.Transparency = .4
		beam.Parent = workspace
		innerBeam.Parent = workspace
		blast.Parent = workspace
		innerBlast.Parent = workspace
		local t1 = ts:Create(beam,TweenInfo.new(.8),{Transparency = 1, Size = Vector3.new(.2,.2,beam.Size.Z)})
		local t2 = ts:Create(innerBeam,TweenInfo.new(.8),{Transparency = 1, Size = Vector3.new(.1,.1,innerBeam.Size.Z)})
		local t3 = ts:Create(blast,TweenInfo.new(.8),{Transparency = 1, Size = Vector3.one * 8})
		local t4 = ts:Create(innerBlast,TweenInfo.new(.8),{Transparency = 1, Size = (Vector3.one * 8) *.9 })
		t1:Play()
		t2:Play()
		t3:Play()
		t4:Play()
		t1.Completed:Once(function()
			t1:Destroy()
			beam:Destroy()
		end)
		t2.Completed:Once(function()
			t2:Destroy()
			innerBeam:Destroy()
		end)
		t3.Completed:Once(function()
			t3:Destroy()
			blast:Destroy()
		end)
		t4.Completed:Once(function()
			t4:Destroy()
			innerBlast:Destroy()
		end)
	end,
	
	kill = function(partInfo:{},center:Vector3)
		local part = Instance.new("Part")
		for p,v in next, partInfo do
			part[p] = v
		end
		part.Color = Color3.new(0,1,0)
		part.Material = Enum.Material.Neon
		part.Transparency = .6
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		local inner = part:Clone()
		inner.Size = part.Size * .9
		inner.Color = Color3.new(1,1,1)
		inner.Transparency = .4
		
		part.Parent = workspace
		inner.Parent = workspace
		local setCenter = CFrame.new(center) * CFrame.Angles(math.rad(math.random(-180,180)),math.rad(math.random(-180,180)),math.rad(math.random(-180,180)))
		local t1 = ts:Create(part,TweenInfo.new(1.7,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out),{Transparency = 1, CFrame = setCenter, Size = part.Size * .12})
		local t2 = ts:Create(inner,TweenInfo.new(1.7,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out),{Transparency = 1, CFrame = setCenter, Size = inner.Size * .12})
		t1:Play()
		t2:Play()
		t1.Completed:Once(function()
			t1:Destroy()
			part:Destroy()
		end)
		t2.Completed:Once(function()
			t2:Destroy()
			inner:Destroy()
		end)
	end,
	
}
