local API = {}

local rs = game:GetService("ReplicatedStorage")
local forbidden = rs:WaitForChild("Forbidden")
local std = forbidden:WaitForChild("Multiplayer")

-- FOR AUTOMATED VERSION COMING SOON

--local this = script
--local signals = this:WaitForChild("signals")
--local RF_Join = signals:WaitForChild("join")
--local RF_Leave = signals:WaitForChild("leave")
--local BE_Matchmade = signals:WaitForChild("toServerMatchInfo")
--local RE_Matchmade = signals:WaitForChild("toClientMatchInfo")

API.Queues = {}

API.Length = function(self)
	return self.tail - self.head
end

API.is_empty = function(self)
	return API.Length(self) == 0
end

API.AddToBack = function(self, x) 
	assert(x ~= nil)
	self.tail = self.tail + 1
	self[self.tail] = x
end

API.AddToFront = function(self, x)
	assert(x ~= nil)
	self[self.head] = x
	self.head = self.head - 1
end

API.ReadBack = function(self)
	return self[self.tail]
end

API.ReadFront = function(self)
	return self[self.head+1]
end

API.RemoveBack = function(self)
	if API.is_empty(self) then return nil end
	local r = self[self.tail]
	self[self.tail] = nil
	self.tail = self.tail - 1
	return r
end

API.RemoveFront = function(self)
	if API.is_empty(self) then return nil end
	local r = self[self.head+1]
	self.head = self.head + 1
	local r = self[self.head]
	self[self.head] = nil
	return r
end

API.RotateTowardsBack = function(self, number_of_places)
	number_of_places = number_of_places or 1
	if API.is_empty(self) then return nil end
	for i=1,number_of_places do API.AddToFront(self, API.RemoveBack(self)) end
end

API.RotateTowardsFront = function(self, number_of_places)
	number_of_places = number_of_places or 1
	if API.is_empty(self) then return nil end
	for i=1,number_of_places do API.AddToBack(self, API.RemoveFront(self)) end
end

API.SendToBack = function(self, value)
	
	for i=self.head+1,self.tail do
		if self[i] == value then
			API.RotateTowardsBack(self, self.tail - i)
			return true
		end
	end
	return false
end

API.BringToFront = function(self, value)
	
	for i=self.tail,self.head+1,-1 do
		if self[i] == value then
			API.RotateTowardsFront(self, i-1)
			return true
		end
	end
	return false
end

local _remove_at_internal = function(self, idx)
	for i=idx, self.tail do self[i] = self[i+1] end
	self.tail = self.tail - 1
end

--[[
API.AlternateRemove = function(self, value) -- searches from different direction
	for i=self.tail,self.head+1,-1 do
		if self[i] == value then
			_remove_at_internal(self, i)
			return true
		end
	end
	return false
end
]]--
API.Remove = function(self, value)
	for i=self.head+1,self.tail do
		if self[i] == value then
			_remove_at_internal(self, i)
			return true
		end
	end
	return false
end

API.Contents = function(self)
	local r = {}
	for i=self.head+1,self.tail do
		r[i-self.head] = self[i]
	end
	return r
end

API.SequentialRemovalFromFront = function(self)
	local i = self.tail+1
	return function()
		if i > self.head+1 then
			i = i-1
			return self[i]
		end
	end
end

API.SequentialRemovalFromBack = function(self)
	local i = self.head
	return function()
		if i < self.tail then
			i = i+1
			return self[i]
		end
	end
end

function API.New(settings)
	
	local r = {head = 0, tail = 0}
	
	return r
end

return API

--[[
Copyright (C) 2013-2015 by Pierre Chapuis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
]]--

-- https://github.com/catwell/cw-lua/blob/master/deque/LICENSE.txt