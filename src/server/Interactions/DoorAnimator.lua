local DoorAnimator = {}

function DoorAnimator.OpenDoor(context, panel, modeloPuerta)
    if not modeloPuerta then return false end

    local attributeNames = context.AttributeNames
    local tweenService = context.TweenService
    local doorConstants = context.GameConstants.Door

    local bisagra = modeloPuerta:FindFirstChild("Bisagra")
    if not bisagra then return false end

    if not modeloPuerta:GetAttribute(attributeNames.CFrameOriginal) then
        modeloPuerta:SetAttribute(attributeNames.CFrameOriginal, bisagra.CFrame)
    end

    local cframeBase = modeloPuerta:GetAttribute(attributeNames.CFrameOriginal)
    local estaAbierta = modeloPuerta:GetAttribute(attributeNames.EstaAbierta) or false
    if estaAbierta then
        return true
    end

    local infoAnimacion = TweenInfo.new(
        doorConstants.TweenDuration,
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut
    )

    local objetivoCFrame = cframeBase * CFrame.Angles(0, math.rad(doorConstants.RotationDegrees), 0)
    local animacion = tweenService:Create(bisagra, infoAnimacion, {CFrame = objetivoCFrame})

    local sonidoRechinido = panel:FindFirstChild("SonidoRechinido")
    if sonidoRechinido then sonidoRechinido:Play() end

    animacion:Play()
    animacion.Completed:Wait()
    modeloPuerta:SetAttribute(attributeNames.EstaAbierta, true)
    return true
end

function DoorAnimator.CloseDoor(context, panel, modeloPuerta)
    if not modeloPuerta then return false end

    local attributeNames = context.AttributeNames
    local tweenService = context.TweenService
    local doorConstants = context.GameConstants.Door

    local bisagra = modeloPuerta:FindFirstChild("Bisagra")
    if not bisagra then return false end

    if not modeloPuerta:GetAttribute(attributeNames.CFrameOriginal) then
        modeloPuerta:SetAttribute(attributeNames.CFrameOriginal, bisagra.CFrame)
    end

    local cframeBase = modeloPuerta:GetAttribute(attributeNames.CFrameOriginal)

    local infoAnimacion = TweenInfo.new(
        doorConstants.TweenDuration,
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut
    )

    local animacion = tweenService:Create(bisagra, infoAnimacion, {CFrame = cframeBase})
    local sonidoRechinido = panel:FindFirstChild("SonidoRechinido")
    if sonidoRechinido then sonidoRechinido:Play() end

    animacion:Play()
    animacion.Completed:Wait()
    modeloPuerta:SetAttribute(attributeNames.EstaAbierta, false)
    return true
end

return DoorAnimator
