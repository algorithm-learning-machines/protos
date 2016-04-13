require "torch"
require "nn"

local ShiftLearn = require("ShiftLearn")
local data_creator = require("ShiftDataset")
local data_loader = data_creator()

local model = ShiftLearn.create(3)

local sh = torch.zeros(3)
sh[1] = 1
local x = torch.zeros(3)
x[1] = 1

local criterion = nn.MSECriterion()

params, grad_params = model:getParameters()
params:zero()
config = {}

--------------------------------------------------------------------------------
-- Dataset definition
--------------------------------------------------------------------------------
dataset = {}
function dataset:size() return 1000 end
for i=1, dataset:size() do
   local x, t = data_loader:getNext()
   dataset[i] = {x, t}
end

--------------------------------------------------------------------------------
-- Train procedure
--------------------------------------------------------------------------------
function train()
    for t=1,dataset:size() do
        local feval = function(x)
            if x ~= params then
                params:copy(x)
            end

            grad_params:zero()
            local input = dataset[t][1]
            local target = dataset[t][2]

            local output = model:forward(input)
            local err = criterion:forward(output, target)

            local dfdo = criterion:backward(output, target)

            model:backward(input, dfdo)
            grad_params:div(input:size(1))

            return err, grad_params
        end

        optim.adam(feval, params, config)
        print("finished adam "..t)
    end
end

for j = 1,10 do
    train()
end


print(model:forward({sh, x}))







