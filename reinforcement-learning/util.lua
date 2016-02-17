--------------------------------------------------------------------------------
--- Various functions
--------------------------------------------------------------------------------

local util = {}

--------------------------------------------------------------------------------
--- deepcopy from:  http://lua-users.org/wiki/CopyTable
--------------------------------------------------------------------------------

function util.deepcopy(orig)
   local orig_type = type(orig)
   local copy
   if orig_type == 'table' then
      copy = {}
      for orig_key, orig_value in next, orig, nil do
         copy[util.deepcopy(orig_key)] = util.deepcopy(orig_value)
      end
      setmetatable(copy, util.deepcopy(getmetatable(orig)))
   else -- number, string, boolean, etc
      copy = orig
   end
   return copy
end


--------------------------------------------------------------------------------
--- getch_unix from:
---  http://lua.2524044.n2.nabble.com/Check-for-a-keypress-td7654769.html
--------------------------------------------------------------------------------

function util.getch_unix()
   os.execute("stty cbreak </dev/tty >/dev/tty 2>&1")
   local key = io.read(1)
   os.execute("stty -cbreak </dev/tty >/dev/tty 2>&1");
   return(key)
end

return util
