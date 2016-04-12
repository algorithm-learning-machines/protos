require 'torch'
require 'nn'
require 'rnn'
require 'optim'

local data_loader = require("data_loader")
data_loader:__init(10, 20, 0)

local model = nn.Sequential();
model:add(nn.LSTM(data_loader.v_size + data_loader.address_size,
data_loader.v_size + data_loader.address_size, 10))
 
local criterion = nn.MSECriterion()

params, grad_params = model:getParameters()
params:zero()
config = {}
dataset = {}
function dataset:size() return 1000 end
for i=1, dataset:size() do
   local x, t = data_loader:getNext()
   dataset[i] = {x, t}
end


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


print("...training")
eval_eps = 100
for i=1,100 do
   local x, t = data_loader:getNext(true)
   local out = model:forward(x)
   local err = criterion:forward(out, x)
   --print(t
   --print(out)
   --print("------")
   print("OUT")
   print(out)
   print("T")
   print(t)
   print("END")
   _, ix_out = out:max(1)
   _, ix_t = t:max(1)
   if ix_out[1] ~= ix_t[1] then
       eval_eps = eval_eps - 1
   end
end
print(eval_eps)
--print(data_loader:getNext())
