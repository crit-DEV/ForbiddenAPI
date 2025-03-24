-- [Services] --
local players = game:GetService("Players")

-- [Module Declaration]
local product = {}
local config = require(script:WaitForChild("Config"))

-- type defs.
type receiptInfo = {
	PurchaseId: number,
	PlayerId: number,
	ProductId: number,
	PlaceIdWherePurchased: number,
	CurrencySpent: number,
	CurrencyType: Enum.CurrencyType
}

product.GetProductId = function() return config.ProductId end
product.GetProductName = function() return script.Name end

product.Trigger = function(receipt : receiptInfo)
	
	local player = players:GetPlayerByUserId(receipt.PlayerId)
	print("Triggered by " .. player.Name)
	
end


return product

-- @rman501, @CritDEV on YT.