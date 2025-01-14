local Players = game:GetService("Players")
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local teamColors = {Red = Color3.new(1, 0, 0), Blue = Color3.new(0, 0, 1)}

local espEnabled = true
local flyEnabled = false
local godModeEnabled = false
local speedControlEnabled = false
local aimbotEnabled = false
local playerSpeed = 50
local originalWalkSpeed = {}
local originalHealth = {}
local flyConnection = nil
local aimbotConnection = nil
local espInstances = {}

-- Função Utilitária para Verificar se a Parte Existe
local function getPart(character, partName)
    local part = character:FindFirstChild(partName)
    return part and part:IsA("BasePart") and part or nil
end

-- Função para Criar ESP
local function createESP(player)
    if espInstances[player] then return end  -- Evita duplicação de ESP

    local esp = Instance.new("Highlight")
    local teamColor = player.TeamColor == game:GetService("Teams").Home.TeamColor and teamColors.Blue or teamColors.Red
    esp.FillColor = teamColor
    esp.Adornee = getPart(player.Character, "HumanoidRootPart") or player.Character:WaitForChild("HumanoidRootPart")
    esp.Parent = player.Character
    espInstances[player] = esp
end

-- Função para Remover ESP
local function removeESP(player)
    if espInstances[player] then
        espInstances[player]:Destroy()
        espInstances[player] = nil
    end
end

-- Função para Toggle Fly
local function toggleFly(player)
    local character = player.Character
    if not character then return end

    local humanoidRootPart = getPart(character, "HumanoidRootPart")
    if not humanoidRootPart then return end

    flyEnabled = not flyEnabled
    local bodyVelocity = humanoidRootPart:FindFirstChildOfClass("BodyVelocity")
    if not bodyVelocity then
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)
        bodyVelocity.Parent = humanoidRootPart
    end

    -- Conectar evento de voo
    if flyEnabled then
        flyConnection = runService.RenderStepped:Connect(function()
            bodyVelocity.Velocity = Vector3.new(0, 50, 0)
        end)
    else
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    end
end

-- Função para God Mode
local function enableGodMode(player)
    local character = player.Character
    if character and character:FindFirstChild("Humanoid") then
        local humanoid = character.Humanoid
        godModeEnabled = not godModeEnabled

        if godModeEnabled then
            -- Armazenar valores originais antes de modificar
            originalHealth[player] = humanoid.Health
            humanoid.MaxHealth = math.huge
            humanoid.Health = humanoid.Health  -- Isso mantém a saúde intacta
        else
            if originalHealth[player] then
                humanoid.MaxHealth = 100
                humanoid.Health = originalHealth[player]
            end
        end
    end
end

-- Função para Controle de Velocidade
local function setPlayerSpeed(player, speed)
    local character = player.Character
    if character and character:FindFirstChild("Humanoid") then
        -- Armazenar o WalkSpeed original antes de alterar
        if not originalWalkSpeed[player] then
            originalWalkSpeed[player] = character.Humanoid.WalkSpeed
        end

        speedControlEnabled = not speedControlEnabled
        character.Humanoid.WalkSpeed = speedControlEnabled and speed or originalWalkSpeed[player]
    end
end

-- Função para Aimbot
local function aimbot(player)
    aimbotEnabled = not aimbotEnabled

    if aimbotEnabled then
        aimbotConnection = runService.RenderStepped:Connect(function()
            local target
            for _, v in pairs(Players:GetPlayers()) do
                if v ~= player and v.TeamColor ~= player.TeamColor and v.Character and v.Character:FindFirstChild("Head") then
                    target = v
                    break
                end
            end

            if target then
                local camera = workspace.CurrentCamera
                local targetPosition = target.Character.Head.Position
                local cameraPosition = camera.CFrame.Position
                local direction = (targetPosition - cameraPosition).unit
                camera.CFrame = CFrame.new(cameraPosition, cameraPosition + direction)
            end
        end)
    else
        if aimbotConnection then
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end
    end
end

-- Função para Criar GUI de Painel
local function createPanel(player)
    -- Criação da GUI básica para interagir com os recursos
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = player:WaitForChild("PlayerGui")  -- Garantir que PlayerGui existe
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 300)
    frame.Position = UDim2.new(0.5, -100, 0.5, -150)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.Parent = screenGui
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Text = "Painel Ativado!"
    textLabel.Parent = frame
end

-- Conectar Eventos de Jogador
Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(msg)
        local command, arg = msg:match("^(%S+)%s*(.-)$"):lower()
        if command == "fly" then
            toggleFly(player)
        elseif command == "god" then
            enableGodMode(player)
        elseif command == "speed" then
            setPlayerSpeed(player, tonumber(arg) or 50)
        elseif command == "aimbot" then
            aimbot(player)
        end
    end)

    player.CharacterAdded:Connect(function(character)
        if espEnabled then
            createESP(player)
        end
    end)

    player.CharacterRemoving:Connect(function()
        removeESP(player)
    end)

    -- Abrir o painel com a tecla Home
    uis.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Home then
            createPanel(player)
        end
    end)

    -- Garantir que ao sair do jogo, as conexões sejam desconectadas
    player.AncestryChanged:Connect(function(_, parent)
        if not parent then
            -- Limpar conexões quando o jogador for removido
            if flyConnection then
                flyConnection:Disconnect()
                flyConnection = nil
            end
            if aimbotConnection then
                aimbotConnection:Disconnect()
                aimbotConnection = nil
            end
        end
    end)
end)
