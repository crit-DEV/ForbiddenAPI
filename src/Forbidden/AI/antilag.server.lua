-- forces server to run the AI physics sim preventing rubberbanding when transferring from server->client rendering
task.wait(1)
local hrt = script.Parent:FindFirstChild("HumanoidRootPart")
local t = script.Parent:FindFirstChild("Torso")
if t ~= nil and hrt == nil then hrt = t end
if hrt ~= nil then hrt:SetNetworkOwner(nil) end
if hrt == nil then warn("Unable to use anti-lag script.") return end

script:Destroy()