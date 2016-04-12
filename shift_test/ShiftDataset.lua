require "torch"
require "bit"

local class = require("class")

local DataLoaderBits = class("DataLoaderBits")

function DataLoaderBits:__init(train_limit, test_limit, bits)
   self.train_limit = train_limit or 20
   self.test_limit = test_limit or 50
   self.bits = bits or 8
end


function DataLoaderBits:getNext(isForTest)
   local n, d
   if isForTest then
      n = torch.random(self.test_limit - 1)
   else
      n = torch.random(self.train_limit - 1)
   end
   local d_numeric = torch.random(1, self.bits)
   d_vec = torch.zeros(self.bits)
   d_vec[d_numeric] = 1

   local x = self.__numToBits(n, self.bits)
   local t = self.__numToBits(bit.lshift(n,shiftNum, n), self.bits)

   return {x, d_vec}, t

end


function DataLoaderBits:__numToBits(num, bits)
    local bitVec = Tensor(bits, 1):fill(0)
    local i_bit = 1
    while num ~= 0 do
        local b = bit.band(num, 1)
        bitVec[i_bit][1] = b
        num = bit.rshift(num, 1)
        i_bit = i_bit + 1
    end
    return bitVec
end


return DataLoaderBits
