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
   local sh = nn.Identity()()
   local x = nn.Identity()()
   local x_sh = nn.JoinTable(1)({sh, x})

   -----------------------------------------------------------------------------
   -- Internal shift matrix
   -----------------------------------------------------------------------------
   local learner2D = 
      nn.Sigmoid()(nn.Linear(2 * (vecSize + vecSize), vecSize * vecSize)( 
      nn.Sigmoid()(nn.Linear(vecSize + vecSize, 2 * (vecSize + vecSize))(x_sh)
      )))

   -----------------------------------------------------------------------------
   -- Shifted Tensor
   -----------------------------------------------------------------------------
   local fin = nn.SoftMax()(nn.Sigmoid()(nn.MM()({nn.Reshape(1, vecSize)(x),
      nn.Reshape(vecSize, vecSize)(learner2D)})))
   local res_fin = nn.Squeeze()(fin)

   return nn.gModule({sh, x}, {res_fin})

end

return ShiftGenerator 
