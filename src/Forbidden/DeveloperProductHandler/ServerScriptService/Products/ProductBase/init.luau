local ProductBase = {}

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

ProductBase.Trigger = function(receipt: receiptInfo)
	return Enum.ProductPurchaseDecision.NotProcessedYet -- does not do anything.
end

ProductBase.GetProductId = function()
	return config.ProductId
end

ProductBase.GetProductName = function()
	return script.Name
end


return ProductBase