local Road = {}

function Road.create(scene)
	local road = Instance.new("Part")
	road.Name = "Road"
	road.Anchored = true
	road.CanCollide = true
	road.Size = Vector3.new(120, 1, 30)
	road.Position = Vector3.new(0, 0, 0)
	road.Material = Enum.Material.Asphalt
	road.Color = Color3.fromRGB(60, 60, 60)
	road.Parent = scene
end

return Road
