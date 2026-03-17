local UserInputService = game:GetService("UserInputService")

local InputController = {}

local moveInput = 0
local strafeInput = 0
local isHoldingShift = false

function InputController:Init(onFlashlightToggle, onMouseMove)
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end

        if input.KeyCode == Enum.KeyCode.W then
            moveInput = 1
        elseif input.KeyCode == Enum.KeyCode.S then
            moveInput = -1
        elseif input.KeyCode == Enum.KeyCode.A then
            strafeInput = -1
        elseif input.KeyCode == Enum.KeyCode.D then
            strafeInput = 1
        elseif input.KeyCode == Enum.KeyCode.LeftShift then
            isHoldingShift = true
        elseif input.KeyCode == Enum.KeyCode.F and onFlashlightToggle then
            onFlashlightToggle()
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S then
            moveInput = 0
        elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D then
            strafeInput = 0
        elseif input.KeyCode == Enum.KeyCode.LeftShift then
            isHoldingShift = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and onMouseMove then
            onMouseMove(input.Delta.X, input.Delta.Y)
        end
    end)
end

function InputController:GetState()
    return moveInput, strafeInput, isHoldingShift
end

return InputController
