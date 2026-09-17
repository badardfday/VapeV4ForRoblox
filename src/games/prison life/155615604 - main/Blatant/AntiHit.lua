local AntiHit
local Intensity
local oldCF
local oldRoot
local oldFallenHeight
local renderStepKey = 'AntiHit_' .. tostring(math.random(100000, 999999))

AntiHit = vape.Categories.Blatant:CreateModule({
    Name = 'AntiHit',
    Function = function(callback)
        if callback then
            oldCF = nil
            oldFallenHeight = workspace.FallenPartsDestroyHeight
            workspace.FallenPartsDestroyHeight = -math.huge

            runService:BindToRenderStep(renderStepKey, Enum.RenderPriority.Camera.Value - 1, function()
                if entitylib.isAlive then
                    local root = entitylib.character.RootPart
                    if root ~= oldRoot then
                        oldCF = nil
                        oldRoot = root
                    end
                end
                if entitylib.isAlive and oldCF and entitylib.character.RootPart == oldRoot then
                    local root = entitylib.character.RootPart
                    root.CFrame = oldCF
                end
            end)

            AntiHit:Clean(function()
                runService:UnbindFromRenderStep(renderStepKey)
            end)

            AntiHit:Clean(runService.PreSimulation:Connect(function()
                if entitylib.isAlive then
                    local root = entitylib.character.RootPart
                    oldRoot = root
                    oldCF = root.CFrame
                    local radius = math.random() * Intensity.Value
                    local angle = math.random() * math.pi * 2
                    local offset = Vector3.new(math.cos(angle) * radius, (math.random() - 0.5) * radius, math.sin(angle) * radius)
                    root.CFrame += offset

                    if root.Position.Y > 179.99 then
                        root.CFrame -= Vector3.new(0, root.Position.Y - 179.99, 0)
                    end
                end
            end))

            AntiHit:Clean(runService.PostSimulation:Connect(function()
                if entitylib.isAlive and oldCF and entitylib.character.RootPart == oldRoot then
                    entitylib.character.RootPart.CFrame = oldCF
                end
            end))
        else
            if entitylib.isAlive and oldCF and entitylib.character.RootPart == oldRoot then
                local root = entitylib.character.RootPart
                root.CFrame = oldCF
            end
            oldCF = nil
            oldRoot = nil

            if oldFallenHeight then
                workspace.FallenPartsDestroyHeight = oldFallenHeight
                oldFallenHeight = nil
            end
        end
    end,
    Tooltip = 'Offsets your position to make RootPart targeting less reliable'
})
Intensity = AntiHit:CreateSlider({
    Name = 'Intensity',
    Min = 1,
    Max = 20,
    Default = 8
})