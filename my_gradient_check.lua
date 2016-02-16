--------------------------------------------------------------------------------
--- Import needed modules
--------------------------------------------------------------------------------

require("torch")
require("nn")

--------------------------------------------------------------------------------
--- Do gradient check for a given model, criterion and a given test case
--------------------------------------------------------------------------------

function gradientCheck(model, criterion, testInputs, testOutputs, epsilon)
   w, dldw = model:getParameters()

   n = w:size(1)

   --- 1. Compute gradient (backpropagation)
   dldw:zero()
   criterion:forward(model:forward(testInputs), testOutputs)
   model:backward(testInputs, criterion:backward(model.output, testOutputs))

   origGradient = dldw:clone()
   origW = w:clone()

   --- 2. Compute gradient (using definition)
   compGradient = torch.Tensor(n)
   compGradient:zero()

   for i=1,n do
      w:copy(origW)
      w[i] = w[i] + epsilon
      j1 = criterion:forward(model:forward(testInputs), testOutputs)

      w[i] = w[i] - 2 * epsilon
      j2 = criterion:forward(model:forward(testInputs), testOutputs)

      compGradient[i] = (j2 - j1) / (2 * epsilon)
   end
   print(torch.cat(compGradient, origGradient, 2))
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
