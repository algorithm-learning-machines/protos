require "torch"
require "optim"
require "nn"
require "pl.seq"

local ShiftLearn = require("ShiftLearn")
local data_creator = require("ShiftDataset")
local data_loader = data_creator(100)

local model = ShiftLearn.create(100)


local criterion = nn.MSECriterion()

params, grad_params = model:getParameters()
params:zero()
config = {}

--------------------------------------------------------------------------------
-- Dataset definition
--------------------------------------------------------------------------------
dataset, exclusionList = data_loader:getSet(nil, 50) 
evalset = data_loader:getSet(exclusionList, 20)
function dataset:size() return 50 end
function evalset:size() return 20 end
--print(dataset[1][1])
model:training()
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
            print("train "..err)
            return err, grad_params
        end

        optim.adam(feval, params, config)
        print("finished adam "..t)
    end
end

for j=1,5 do
    train()
end

--------------------------------------------------------------------------------
-- Eval procedure
--------------------------------------------------------------------------------
local good = evalset:size()

for i in seq.range(1, evalset:size()) do
   local out = model:forward(evalset[i][1])
   local err = criterion:forward(out, evalset[i][2])
   local val,ix_o = out:max(2)
   local _, ix_t = evalset[i][2]:max(1)
   if ix_o[1] ~= ix_t[1] then
      good = good - 1
   end
   print("eval "..err)
end
--------------------------------------------------------------------------------
-- number of correct evaluations
--------------------------------------------------------------------------------
print(good)









