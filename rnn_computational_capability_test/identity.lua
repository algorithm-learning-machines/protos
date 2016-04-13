-- simple identity test
-- see if network is capable of producing identity function
require "torch"
require "nn"
require "rnn"
require "optim"
require "pl.tablex"

local criterion = nn.MSECriterion()
--------------------------------------------------------------------------------
-- Models
--------------------------------------------------------------------------------
local lstm = nn.LSTM(1,1,1)
local gru = nn.GRU(1,1,1)

local ffn = nn.Sequential()
ffn:add(nn.Linear(1,1))
--------------------------------------------------------------------------------

cmd = torch.CmdLine() 
cmd:option('-model_no', '1', 'which model to try')
cmd:option('-evalSize', '20', 'size of eval set')
cmd:option('-trainSize', '100', 'size of train set')


local opt = cmd:parse(arg)
local trainSize = tostring(opt.trainSize)
local evalSize = tostring(opt.evalSize) 
local num = tonumber(opt.model_no)

model = lstm
if num == 2 then
   model = gru 
elseif num == 3 then
   model = ffn 
end

params, grad_params = model:getParameters()
params:zero()


local dataset = {}
for i=1,trainSize do
   x = math.random() 
   while tablex.find(dataset, x) do
      x = math.random() 
   end
   dataset[#dataset + 1] = {torch.Tensor{x},torch.Tensor{x}} 
end
local evalset = {}
for i=1,evalSize do
   x = math.random() 
   while tablex.find(evalset, x) or
      tablex.find(dataset,x) do
      x = math.random() 
   end
   evalset[#evalset + 1] = {torch.Tensor{x},torch.Tensor{x}}
end

function dataset:size() return trainSize end

function train()
    for t=1,dataset:size() do
        local feval = function(x)
            if x ~= params then
                params:copy(x)
            end

            grad_params:zero()
            local input = dataset[t][1]
            --print(input)
            local target = dataset[t][2]
            local output = model:forward(input)
            local err = criterion:forward(output, target)
            local dfdo = criterion:backward(output, target)

            model:backward(input, dfdo)

            return err, grad_params
        end

        optim.adam(feval, params, config)
        --print("finished adam "..t)
    end
end
function train_ffn()
   return train(ffn, ffn_params, ffn_grad_params)
end


function train_lstm()
   return train(lstm, lstm_params, lstm_grad_params)
end


for j = 1,1 do
    train()
end

--------------------------------------------------------------------------------
-- Eval Model
--------------------------------------------------------------------------------
function evalset:size() return evalSize end

local totalErr = 0.0
for j=1,evalset:size() do
   local instance = evalset[j]
   local output = model:forward(instance[1])
   local err = criterion:forward(output, instance[2])
   totalErr = totalErr + err
end
totalErr = totalErr / evalset:size()
print(totalErr)


