-- @skull, 6/13/25, ty for code!
-- skull, whole module

local KeyAssignments = {}

KeyAssignments.Keys = {

    Hide = {Enum.UserInputType.MouseButton1, Enum.KeyCode.E, Enum.KeyCode.ButtonA},
    -- you could also put other key assignments here !

}

-- Assignment -> Key in table (i.e. Hide == "Hide")
-- input -> the actual input object
-- See ClientHideHandler for usage example.
KeyAssignments.CheckInputs = function(input: InputObject, assignment: string): boolean
    for _, key in KeyAssignments.Keys[assignment] do
        if input.KeyCode == key or input.UserInputType == key then
            return true
        end
    end
    return false
end

return KeyAssignments