local MarketplaceService = game:GetService("MarketplaceService")
local local_player = game:GetService("Players").LocalPlayer

-- [SETTINGS] --
local ProductID = 1906320455
local button = script.Parent

button.Activated:Connect(function()
	MarketplaceService:PromptProductPurchase(local_player, ProductID)
end)