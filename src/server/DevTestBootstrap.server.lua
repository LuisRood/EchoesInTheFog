local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not RunService:IsStudio() then
    return
end

local SharedModules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModuleScripts")
local PromptActionTypes = require(SharedModules:WaitForChild("PromptActionTypes"))
local AttributeNames = require(SharedModules:WaitForChild("AttributeNames"))

local ROOT_FOLDER_NAME = "DevTest"

local function createPickupTest(rootFolder)
    local pickupPart = Instance.new("Part")
    pickupPart.Name = "Pickup_Key_Storage"
    pickupPart.Size = Vector3.new(2, 1, 2)
    pickupPart.Anchored = true
    pickupPart.Color = Color3.fromRGB(255, 223, 102)
    pickupPart.Position = Vector3.new(0, 4, 12)
    pickupPart.Parent = rootFolder

    pickupPart:SetAttribute(AttributeNames.NombreItem, "LlaveAlmacen")
    pickupPart:SetAttribute(AttributeNames.DescripcionItem, "Llave temporal de pruebas para desbloquear puertas.")

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = PromptActionTypes.RecogerObjeto
    prompt.ActionText = "Recoger"
    prompt.ObjectText = "LlaveAlmacen"
    prompt.RequiresLineOfSight = false
    prompt.MaxActivationDistance = 10
    prompt.HoldDuration = 0.2
    prompt.Parent = pickupPart
end

local function createNpcReviveTest(rootFolder)
    local model = Instance.new("Model")
    model.Name = "CompaneroNPC_Test"
    model.Parent = rootFolder

    model:SetAttribute(AttributeNames.Estado, "Abatido")

    local rootPart = Instance.new("Part")
    rootPart.Name = "HumanoidRootPart"
    rootPart.Size = Vector3.new(2, 2, 1)
    rootPart.Anchored = true
    rootPart.Color = Color3.fromRGB(170, 80, 80)
    rootPart.Position = Vector3.new(6, 4, 12)
    rootPart.Parent = model

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = PromptActionTypes.Revivir
    prompt.ActionText = "Levantar"
    prompt.ObjectText = "Companero NPC"
    prompt.RequiresLineOfSight = false
    prompt.MaxActivationDistance = 10
    prompt.HoldDuration = 0.5
    prompt.Parent = rootPart
end

local function bootstrapDevTests()
    local existing = workspace:FindFirstChild(ROOT_FOLDER_NAME)
    if existing then
        existing:Destroy()
    end

    local rootFolder = Instance.new("Folder")
    rootFolder.Name = ROOT_FOLDER_NAME
    rootFolder.Parent = workspace

    createPickupTest(rootFolder)
    createNpcReviveTest(rootFolder)

    print("[DEV-TEST] Escena temporal creada en Workspace/" .. ROOT_FOLDER_NAME)
    print("[DEV-TEST] 1) Prueba RecogerObjeto con 'LlaveAlmacen'.")
    print("[DEV-TEST] 2) Prueba Revivir sobre 'CompaneroNPC_Test'.")
    print("[DEV-TEST] Nota: Revivir jugador real requiere 2 jugadores en Local Server.")
end

bootstrapDevTests()
