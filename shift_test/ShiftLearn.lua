require "torch"
require "nn"
require "nngraph"

local class = require("class")


-- static class
local ShiftGenerator = class("ShiftLearn")

function ShiftGenerator.create(vecSize)
   -----------------------------------------------------------------------------
   -- Input def
   -----------------------------------------------------------------------------
   print(vecSize)
   local sh = nn.Identity()()
   local x = nn.Identity()()

   local learner2D = nn.Linear(vecSize + vecSize, vecSize * vecSize)({sh, x})
   local fin = nn.MM()({nn.Reshape(1, vecSize)(x), learner2D})
   return nn.gModule({sh, x}, {fin})

end

return ShiftGenerator 
