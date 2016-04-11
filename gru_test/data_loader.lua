require("torch")

local class = require("class")

local DataLoader = class("DataLoader")

function DataLoader:__init(train_limit, test_limit, v_size, codes)
   self.train_limit = train_limit or 20
   self.test_limit = test_limit or 50
   self.v_size = v_size or 10
   self.address_size = self.test_limit
   self.codes = {-1, 1}
end

function DataLoader:getNext(isForTest)
   local n
   if isForTest then
      n = torch.random(self.test_limit - 1)
   else
      n = torch.random(self.train_limit - 1)
   end

   local x = torch.rand(self.v_size + self.address_size)
   x[{{self.v_size + 1, self.v_size + self.address_size}}]:fill(self.codes[1])
   x[self.v_size + n] = self.codes[2]

   local t = torch.Tensor(self.address_size)
   t:fill(self.codes[1])
   t[n + 1] = self.codes[2]

   return x, t
end

return DataLoader
