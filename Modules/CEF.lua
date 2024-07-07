local Services = setmetatable({}, {
	__index = function(self, t:string)
		return game:GetService(t)
	end,
})
local Effects = {}
local F = {}
function F.Set(Table)
	Effects = Table
end
function LerpNumber(a, b, t)
	return a + (b - a) * t
end
Services.RunService.RenderStepped:Connect(function()
	for i, self in pairs(Effects) do
		if self.Lifetime then
			if self.TimePosition then
				self.TimePosition = self.TimePosition + 1
			else
				self.TimePosition = 0
			end
		else
			self.Lifetime = 500
			self.TimePosition = 0
		end
		local Part = self.Part
		if not Part then
			warn("'Part' was not set in EffectInstance!")
			table.remove(Effects, i)
			self = nil
			return
		end
		if self.TimePosition >= self.Lifetime then
			pcall(function()
				Part:Destroy()
			end)
			table.remove(Effects, i)
			self = nil
			return
		end
		if self.Transparency then
			Part.Transparency = LerpNumber(Part.Transparency, self.Transparency, self.TimePosition/self.Lifetime)
		end
		if self.Color3 then
			Part.Color = Part.Color:Lerp(self.Color3, self.TimePosition/self.Lifetime)
		end
		if self.Size then
			Part.Size = Part.Size:Lerp(self.Size, self.TimePosition/self.Lifetime)
		end
		if self.Offset then
			Part.CFrame = Part.CFrame * self.Offset:Lerp(CFrame.new(), self.TimePosition/self.Lifetime)
		end
		if self.EndCFrame then
			Part.CFrame = Part.CFrame:Lerp(self.EndCFrame, self.TimePosition/self.Lifetime)
		end
	end
end)

return F
