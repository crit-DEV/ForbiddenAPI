local API = {}

local int_Forbidden = script.Parent

API.basic = require(script.stdfunctions) -- gets Standard functions (exists like this so .Math can require the stdfunctions module without recursion)
API.math = require(int_Forbidden.Math) -- Math Library

return API