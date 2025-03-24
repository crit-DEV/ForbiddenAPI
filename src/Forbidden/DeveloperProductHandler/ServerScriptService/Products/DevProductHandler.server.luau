-- [Services] --
local mps = game:GetService("MarketplaceService")

-- [References] --
local productsFolder = script.Parent
local prodBase = require(productsFolder:WaitForChild("ProductBase"))

-- [Products]
local impl = productsFolder:WaitForChild("impl")
local products = {}

-- [Type Def] -- 
type receiptInfo = {
	PurchaseId: number,
	PlayerId: number,
	ProductId: number,
	PlaceIdWherePurchased: number,
	CurrencySpent: number,
	CurrencyType: Enum.CurrencyType
}

for i, v: ModuleScript in pairs(impl:GetChildren()) do
	local req_v : prodBase = require(v)
	table.insert(products, req_v)
end

local function handlePurchase(info: receiptInfo)
	
	if info == nil then return end
	
	-- Determine product purchased.
	local ReceivedProductID = info.ProductId
	
	for i, v: prodBase in pairs(products) do
		
		if ReceivedProductID == v.GetProductId() then
			print("[DevProductHandler] Triggering product: " .. v.GetProductName() .. "!")
			spawn(function() v.Trigger(info) end) -- async.
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		
	end
end

mps.ProcessReceipt = handlePurchase