--------------------------------------------------------------------------------
--- Import needed modules
--------------------------------------------------------------------------------

require("torch")
require("nn")

--------------------------------------------------------------------------------
--- Do gradient check for a given model, criterion and a given test case
--------------------------------------------------------------------------------

function gradientCheck(model, criterion, inputs, outputs, epsilon)
   local W, dJdW = model:getParameters()              -- parametes and gradients
   local n = W:size(1)                               -- the number of parameters

   --- 1. Compute gradient (backpropagation)
   dJdW:zero()                                                -- erase gradients
   criterion:forward(model:forward(inputs), outputs)                  -- forward
   model:backward(inputs, criterion:backward(model.output, outputs))  --backward

   local origGradient = dJdW:clone()                       -- save the gradients
   local origW = W:clone()                                -- save the parameters

   --- 2. Compute gradient (using definition)
   local defGradient = torch.Tensor(n)                    -- definition gradient
   defGradient:zero()                                            -- make it zero

   for i=1,n do                                         -- for the ith parameter
      W:copy(origW)               -- take the original values for the parameters
      W[i] = W[i] + epsilon                       -- slightly modify the ith one
      local j1 = criterion:forward(model:forward(inputs), outputs)     -- loss 1

      W[i] = W[i] - 2 * epsilon        -- slightly modify in the other direction
      local j2 = criterion:forward(model:forward(inputs), outputs)     -- loss 2

      defGradient[i] = (j1 - j2) / (2 * epsilon)               -- compute dJdW_i
   end

   local distance = torch.norm(defGradient - origGradient)
   if distance < 1e-10 then
      print("Ok!")
   else
      print("Not Ok!")
   end
   print("Distance: " .. distance)

   --print(torch.cat(compGradient, origGradient, 2))
end


local inputSize = 25
local outputSize = 30

local model = nn.Sequential()
model:add(nn.Reshape(inputSize))
model:add(nn.Linear(inputSize, outputSize))

local criterion = nn.MSECriterion()

local testInputs = torch.rand(inputSize)
testInputs:mul(0.001)

local testOutputs = torch.zeros(outputSize)
testOutputs[1] = 1

local epsilon = 1e-4

gradientCheck(model, criterion, testInputs, testOutputs, epsilon)
