require("torch")

local class = require("class")

local DataLoader = class("DataLoader")

function DataLoader:__init(train_limit, test_limit, input_size)
   self.train_limit = train_limit or 20
   self.test_limit = test_limit or 50
   self.input_size = 10
   self.address_size = self.test_limit
end

function DataLoader:getNext(isForTest)
   local n
   if isForTest then
      n = torch.random(self.test_limit - 1)
   else
      n = torch.random(self.train_limit - 1)
   end

   local x = torch.rand(self.input_size + self.address_size)
   local t = torch.Tensor(self.address_size)
   t[{{1, self.input_size}}]:copy(x[{{1, self.input_size}}])
   x[{{self.input_size + 1, self.input_size + self.address_size}}]:fill(0)
   x[self.input_size + n] = 1
   t:fill(0)
   t[n + 1] = 1

   return x, t
end

return DataLoader
