local AntiHit
local Intensity
local oldCF
local oldRoot
local oldFallenHeight

AntiHit = vape.Categories.Blatant:CreateModule({
    Name = 'AntiHit',
    Function = function(callback)
        if callback then
            oldFallenHeight = workspace.FallenPartsDestroyHeight
            workspace.FallenPartsDestroyHeight = -math.huge

            AntiHit:Clean(runService.PostSimulation:Connect(function()
                if entitylib.isAlive then
                    local root = entitylib.character.RootPart
                    oldRoot = root
                    oldCF = root.CFrame
                    local radius = math.random() * Intensity.Value
                    local angle = math.random() * math.pi * 2
                    local offset = Vector3.new(math.cos(angle) * radius, (math.random() - 0.5) * radius, math.sin(angle) * radius)
                    root.CFrame += offset

                    if root.Position.Y > 179.99 then
                        root.CFrame = root.CFrame - Vector3.new(0, root.Position.Y - 179.99, 0)
                    end
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
    Tooltip = 'Offsets your position without locking movement'
})
Intensity = AntiHit:CreateSlider({
    Name = 'Intensity',
    Min = 1,
    Max = 20,
    Default = 8
})