local API = {}

local dir = script.Parent

API.basic = require(script.stdfunctions) -- gets Standard functions (exists like this so .Math can require the stdfunctions module without recursion)
API.math = require(dir.Math) -- Math Library

return API