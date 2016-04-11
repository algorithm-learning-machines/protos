require 'torch'
require 'nn'
require 'rnn'

local data_loader = require("data_loader")
data_loader:__init(10, 20, 10)

local my_gru =  nn.LSTM(data_loader.v_size + data_loader.address_size,
                        data_loader.address_size)
local mse = nn.MSECriterion()
for i=1,1000 do
   local x, t = data_loader:getNext()
   local out = my_gru:forward(x)
   local err = mse:forward(out, t)
   local d_err = mse:backward(out, t)
   my_gru:backward(x, d_err)
   --print(err)
end
for i=1,100 do
    local x, t = data_loader:getNext(true)
   local out = my_gru:forward(x)
   local err = mse:forward(out, t)
   local d_err = mse:backward(out, t)
   print("OUT-------")
   print(out)
   print("TEST------")
   print(t)
   print("END-------")
   my_gru:backward(x, d_err)
end
--print(data_loader:getNext())
