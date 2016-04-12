require "torch"

local class = require("class")


-- static class
local ShiftGenerator = class("ShiftGenerator")

--------------------------------------------------------------------------------
-- returns an N * N shift matrix  
--------------------------------------------------------------------------------
function ShiftGenerator.getShiftMatrix(n, shift_index)
  --n = n + 1
  local m = torch.zeros(n, n)

  for i=1,n do -- one element every column
     m[(shift_index + i - 1)  % n + 1 ][i] = 1
  end
  return m

end


function ShiftGenerator.getNumMatrices(n)
   return n
end


return ShiftGenerator 
