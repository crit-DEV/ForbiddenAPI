--[[ Overview

Brief Overview of the queue system.


The queue system comes with automatic components for those that are lazy as well as advanced functions 
that allow you to siphon through values in a sequential order. A value of any type may be inserted.


TABLE OF CONTENTS

	1. Components
	2. Manual Queue Functionality
	3. Automatic Queue Functionality
]]--

--[[ Components

-----------------------------
1. Components
-----------------------------

	When you call API.New it returns a table with...
	
	
		{
		
		["head"]: a number representing the front of the queue - 1
		["tail"]: a number representing the end of the queue
		numbers: reserved for actual values in the queue
		
		}
	
	
	Optionally you can insert a table with settings
	
		
]]--

--[[ Manual Components
-----------------------------
2. MANUAL QUEUE FUNCTIONALITY
-----------------------------

	API.Length(queue) | Returns the length of the queue
	
	API.is_empty(queue) | Determines whether the queue is empty
	
	API.AddToBack(queue, value) | Adds a value to the back of the queue
	API.AddToFront(queue, value) | Adds a value to the front of the queue
	
	API.ReadBack(queue) | Reads the back of the queue
	API.ReadFront(queue) | Reads the front of the queue
	
	API.RemoveBack(queue) | Removes and returns the value taken from the back of the queue
	API.RemoveFront(queue) | Removes and returns the value taken from the front of the queue
	
	API.RotateTowardsBack(queue, places) Rotates the queue towards the back (places) number of places.
	
		ex.
		
		before,
					[1] = "hello1",
                    [2] = "hello2",
                    [3] = "hello3",
                    [4] = "hello4",
                    [5] = "hello5",
                    ["head"] = 0,
                    ["tail"] = 5
                    
        function: API.RotateTowardsBack(queue, 2)
        
        after:
        
        			[-1] = "hello4",
                    [0] = "hello5",
                    [1] = "hello1",
                    [2] = "hello2",
                    [3] = "hello3",
                    ["head"] = -2,
                    ["tail"] = 3

    API.RotateTowardsFront(queue, places) Rotates the queue towards the front (places) number of places.
     
    API.SendToBack(queue, value) Finds the value in the queue and sends it to the back. Returns true if found, false if not.
    API.BringToFront(queue, value) Finds the value in the queue and sends it to the front. Returns true if found, false if not.
     
    API.Remove(queue, value) Finds the value in the queue and removes it. Returns true if found, false if not.
   	 
    API.Contents(queue) Returns just the participants in the queue.
   	 
    API.SequentialRemovalFromFront(queue) Returns a function that everytime it is called removes and returns a value from the front.
   	 
    	ex. 
   	 		[1] = "hello1",
                    [2] = "hello2",
                    [3] = "hello3",
                    [4] = "hello4",
                    [5] = "hello5",
                    ["head"] = 0,
                    ["tail"] = 5
                    
       local iter = API.SequentialRemovalFromFront(queue)
        
       local value = iter()
        
       value = hello1
        
       queue = 	[2] = "hello2",
                    [3] = "hello3",
                    [4] = "hello4",
                    [5] = "hello5",
                    ["head"] = 0,
                    ["tail"] = 5
                    
    API.SequentialRemovalFromBack(queue) Returns a function that everytime it is called removes and returns a value from the back.
   	 
]]--

--[[ Automatic Components
--------------------------------
3. AUTOMATIC QUEUE FUNCTIONALITY
--------------------------------













]]--