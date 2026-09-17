local AntiHit
local Intensity
local oldCF
local oldVelocity
local oldRoot
local oldFallenHeight
local renderStepKey = 'AntiHit_' .. tostring(math.random(100000, 999999))

AntiHit = vape.Categories.Blatant:CreateModule({
    Name = 'AntiHit',
    Function = function(callback)
        if callback then
            oldCF = nil
            oldVelocity = nil
            oldFallenHeight = workspace.FallenPartsDestroyHeight
            workspace.FallenPartsDestroyHeight = -math.huge

            runService:BindToRenderStep(renderStepKey, Enum.RenderPriority.Camera.Value - 1, function()
                if entitylib.isAlive then
                    local root = entitylib.character.RootPart
                    if root ~= oldRoot then
                        oldCF = nil
                        oldVelocity = nil
                        oldRoot = root
                    end
                end
                if entitylib.isAlive and oldCF and entitylib.character.RootPart == oldRoot then
                    local root = entitylib.character.RootPart
                    root.CFrame = oldCF
                    if oldVelocity then
                        root.AssemblyLinearVelocity = oldVelocity
                    end
                end
            end)

            AntiHit:Clean(function()
                runService:UnbindFromRenderStep(renderStepKey)
            end)

            AntiHit:Clean(runService.PostSimulation:Connect(function()
                if entitylib.isAlive then
                    local root = entitylib.character.RootPart
                    oldRoot = root
                    oldCF = root.CFrame
                    oldVelocity = root.AssemblyLinearVelocity
                    local jitter = (math.random() - 0.5) * 2 * Intensity.Value
                    root.CFrame += Vector3.new(0, jitter, 0)

                    if root.Position.Y > 179.99 then
                        root.CFrame = root.CFrame - Vector3.new(0, root.Position.Y - 179.99, 0)
                        if root.AssemblyLinearVelocity.Y > 0 then
                            root.AssemblyLinearVelocity *= Vector3.new(1, 0, 1)
                        end
                    end
                end
            end))
        else
            if entitylib.isAlive and oldCF and entitylib.character.RootPart == oldRoot then
                local root = entitylib.character.RootPart
                root.CFrame = oldCF
                if oldVelocity then
                    root.AssemblyLinearVelocity = oldVelocity
                end
            end
            oldCF = nil
            oldVelocity = nil
            oldRoot = nil

            if oldFallenHeight then
                workspace.FallenPartsDestroyHeight = oldFallenHeight
                oldFallenHeight = nil
            end
        end
    end,
    Tooltip = 'Jitters your vertical position to make you harder to hit'
})
Intensity = AntiHit:CreateSlider({
    Name = 'Intensity',
    Min = 1,
    Max = 20,
    Default = 8
})