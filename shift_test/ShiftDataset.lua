--------------------------------------------------------------------------------
-- Dataset for address shifting
-- address to shift and shift_index are one of k
-- target -> shifted_address
--------------------------------------------------------------------------------

require "torch"
require "bit"
require "pl.tablex"
require "pl.seq"
List = require "pl.List"

local class = require("class")

local DataLoaderBits = class("DataLoaderBits")

function DataLoaderBits:__init(bits)
   self.bits = bits or 200
end

--------------------------------------------------------------------------------
-- Return Set
--------------------------------------------------------------------------------
function DataLoaderBits:getSet(exclusionList, exampleNum)
   local ix, dep

   exclusionList = exclusionList or List{}
   currentList = List{}
   trainList = List{}
   targetList = List{}

   for i in seq.range(1,exampleNum) do
      local inEx = true
      while inEx == true do
         inEx = false
         ix = torch.random(self.bits)
         dep = torch.random(self.bits)
         if exclusionList:contains(List{ix,dep}) or
            currentList:contains(List{ix,dep}) then
            inEx = true
         end
      end
      currentList:put(List{ix, dep})

      local d_vec = torch.zeros(self.bits)
      d_vec[dep] = 1
      local x = torch.zeros(self.bits)
      x[ix] = 1
      local t = torch.zeros(self.bits)
      ix_shift = (ix + dep - 1) % self.bits + 1 -- one based modulo 
      t[ix_shift] = 1

      trainList:put(List{x, d_vec})
      targetList:put(t)
   end

 

   return seq.copy2(seq.zip(trainList,targetList)), currentList 

end


return DataLoaderBits
