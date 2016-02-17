--------------------------------------------------------------------------------
--- Load modules
--------------------------------------------------------------------------------

require("torch")
local util = require("util")

--------------------------------------------------------------------------------
--- Description

--- Pacman is in a maze. He must collect magic '$'s
--- Pacman and the monsters take turns.
--- After pacman and monsters made their move, treats are 'decayed'
--- i.e. after a predefined time, treats disappear and regenerate in new
--- empty positions.
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--- Implement pacman as a game
--------------------------------------------------------------------------------

--- Actions

local actionNames = {"north", "east", "south", "west", "noop"}
local getActionNames = function() return util.deepcopy(actionNames); end

local actionEffects = {          -- the effects of an action on pacman's postion
   north = { dy = -1, dx =  0},                                    -- move north
   east  = { dy =  0, dx =  1},                                     -- move east
   south = { dy =  1, dx =  0},                                    -- move south
   west  = { dy =  1, dx = -1},                                     -- move west
   noop  = { dy =  0, dx =  0}                                     -- do nothing
}

--- Cells

local EMPTY = "."                            -- empty cell, anything can go here
local WALL = "+"                                         -- great asciinese wall
local PACMAN = "P"                                                   -- our hero
local MONSTER = "M"                        -- bad bad monster, run away from him
local TREAT = "$"                                                     -- delight

--- Miscellaneous

local pacmanLives = 3                         -- how many live does the guy have
local treatLife = 7                     -- for how many rounds does a candy live

--------------------------------------------------------------------------------
--- The PacmanState class
--------------------------------------------------------------------------------

local PacmanState = {}
PacmanState.__index = PacmanState

function PacmanState:__getRandomEmptyCell()
   local row = torch.random(self.height)
   local col = torch.random(self.width)
   while self.maze[row][col] ~= EMPTY do
      row = torch.random(self.height)
      col = torch.random(self.width)
   end
   return row, col
end

function PacmanState.create(opt)        -- returns the initial state of the game
   -----------------------------------------------------------------------------
   --- Create "object"
   -----------------------------------------------------------------------------
   self = {}
   setmetatable(self, PacmanState)
   -----------------------------------------------------------------------------
   --- Configure fields
   -----------------------------------------------------------------------------
   if getmetatable(opt) == PacmanState then                 -- used when cloning

      --- 1. Copy maze
      self.height = opt.height
      self.width = opt.width
      self.maze = {}
      for row, originalCells in pairs(opt.maze) do
         local cells = {}
         for col, cell in pairs(originalCells) do cells[col] = cell end
         self.maze[row] = cells
      end

      --- 2. The walls are the same

      --- 3. The monsters
      self.monsters = util.deepcopy(opt.monsters)

      --- 4. The monsters
      self.pacman = util.deepcopy(opt.pacman)

      --- 5. The treats
      self.treats = util.deepcopy(opt.treats)

      --- 6. Miscellaneous
      self.score = opt.score
      self.lives = opt.lives
      self.lastAction = opt.lastAction
   else                                                     -- used with options

      --- 1. Create maze
      self.height = opt.height or 10
      self.width = opt.width or 10
      self.maze = {}
      for row = 1, self.height do
         local cells = {}
         for col = 1, self.width do cells[#cells+1] = EMPTY; end
         self.maze[#(self.maze)+1] = cells
      end

      --- 2. The walls
      if opt.walls then
         for coordsString in string.gmatch(opt.walls, "[%d]+,[%d]+") do
            local coords = coordsSring:split(",")
            local y = tonumber(coords[1])
            local x = tonumber(coords[2])
            self.maze[y][x] = WALL
         end
      else                                              -- put some random walls
         if self.width > 4 then
            local row = torch.random(self.height - 2) + 1
            local startCol = torch.random(self.width - 4) + 1
            local stopCol = torch.random(self.width - startCol - 2) + startCol
            for col = startCol, stopCol do self.maze[row][col] = WALL; end
         end -- if self.width > 4
         if self.height > 4 then
            local col = torch.random(self.width - 2) + 1
            local startRow = torch.random(self.height - 4) + 1
            local stopRow = torch.random(self.height - startRow - 2) + startRow
            for row = startRow, stopRow do self.maze[row][col] = WALL; end
         end -- if self.height > 4
      end

      --- 3. The monsters
      self.monsters = {}
      if opt.monsters then
         for coordsString in string.gmatch(opt.monsters, "[%d]+,[%d]+") do
            local coords = coordsSring:split(",")
            local row = tonumber(coords[1])
            local col = tonumber(coords[2])
            assert(self.maze[row][col] == "EMPTY", "cannot place monster there")
            self.maze[row][col] = MONSTER
            self.monsters[#(self.monsters)+1] = {y = row, x = col}
         end
      else                                           -- put some random monsters
         local monstersNo = opt.monstersNo or 4
         while monstersNo > 0 do
            local row, col = self:__getRandomEmptyCell()
            self.maze[row][col] = MONSTER
            self.monsters[#(self.monsters)+1] = {y = row, x = col}
            monstersNo = monstersNo - 1
         end -- while monstersNo > 0
      end

      --- 4. The Pacman
      if opt.pacman then
         local coords = opt.pacman:split(",")
         local row = tonumber(coords[1])
         local col = tonumber(coords[2])
         assert(self.maze[row][col] == "EMPTY", "cannot place pacman there")
         self.maze[row][col] = PACMAN
         self.pacman = {y = row, x = col}
      else                                  -- place the pacman in a random cell
         local row, col = self:__getRandomEmptyCell()
         self.maze[row][col] = PACMAN
         self.pacman = {y = row, x = col}
      end

      --- 5. The treats
      self.treats = {}
      if opt.treats then
         for coordsString in string.gmatch(opt.treats, "[%d]+,[%d]+") do
            local coords = coordsSring:split(",")
            local row = tonumber(coords[1])
            local col = tonumber(coords[2])
            -- treats spawn in empty cells
            assert(self.maze[row][col] == "EMPTY", "cannot place treat there")
            self.maze[row][col] = TREAT
            self.treats[#(self.treats)+1] = {y= row, x= col, life= treatLife}
         end
      else                                           -- put some random monsters
         local treatsNo = opt.treatsNo or 4
         while treatsNo > 0 do
            local row, col = self:__getRandomEmptyCell()
            self.maze[row][col] = TREAT
            self.treats[#(self.treats)+1] = {y= row, x= col, life= treatLife}
            treatsNo = treatsNo - 1
         end -- while monstersNo > 0
      end

      --- 6. Miscellaneous
      self.score = 0
      self.lives = pacmanLives
      self.lastAction = nil
   end

   return self
end

function PacmanState:__movePacman(action)
   self.lastAction = actionNames[action]
   self.maze[self.pacman.y][self.pacman.x] = EMPTY        -- erase previous cell
   local dCoords = actionEffects[actionNames[action]]
   local newY = dCoords.dy + self.pacman.y                 -- compute target row
   local newX = dCoords.dx + self.pacman.x                 -- compute target col

   if newY < 1 or newY > self.height or newX < 1 or newX > self.width then
      self.maze[self.pacman.y][self.pacman.x] = PACMAN           -- pacman stays
      return 0, "Pacman hit the wall!"
   elseif self.maze[newY][newX] == EMPTY then                     -- boring move
      self.pacman.y, self.pacman.x = newY, newX
      self.maze[self.pacman.y][self.pacman.x] = PACMAN
      return 0, "Pacman moved to new cell."
   elseif self.maze[newY][newX] == MONSTER then     -- pacman stepped on monster
      self.lives = self.lives - 1                                -- he dies once
      self.score = self.score - 10                            -- loses 10 points
      self.pacman.y, self.pacman.x = self:__getRandomEmptyCell()
      self.maze[self.pacman.y][self.pacman.x] = PACMAN               -- respawns
      return -10, "Pacman ran into monster!"
   elseif self.maze[newY][newX] == TREAT then            -- pacman grabbed treat
      self.score = self.score + 1
      self.pacman.y, self.pacman.x = self:__getRandomEmptyCell()
      self.maze[self.pacman.y][self.pacman.x] = PACMAN
      return 1, "Pacman grabbed a cookie!"
   end
end

function PacmanState:applyAction(action)      -- player performs action in state
   reward, message = self:__movePacman(action)
   -- self.t = self.t + 1
   return reward, message                                      -- returns reward
end

function PacmanState.getActions()          -- STATIC: returns the set of actions
   return getActionNames()
end

function PacmanState:isFinal()               -- checks if a given state is final
   return self.lives == 0
end

function PacmanState:__getScreen()

   screen = "=="                                                   -- top border
   for i = 1, self.width do screen = screen .. "==" end
   screen = screen .. "=\n"

   local fmt = "Score:%" .. (self.width * 2 + 3 - 6) .. "d\n"           -- score
   screen = screen .. string.format(fmt, self.score)

   fmt = "Lives:%" .. (self.width * 2 + 3 - 6) .. "d\n"            -- lives left
   screen = screen .. string.format(fmt, self.lives)

   fmt = "Last:%" .. (self.width * 2 + 3 - 5) .. "s\n"            -- last action
   screen = screen .. string.format(fmt, self.lastAction or "")

   screen = screen .. "+-"                                           -- top wall
   for i = 1, self.width do screen = screen .. "--" end
   screen = screen .. "+\n"

   for row = 1, self.height do                                       -- the rows
      screen = screen .. "| "
      local cells = self.maze[row]
      for col = 1, self.width do screen = screen .. cells[col] .. " "; end
      screen = screen .. "|\n"
   end

   screen = screen .. "+-"                                        -- bottom wall
   for i = 1, self.width do screen = screen .. "--" end
   screen = screen .. "+\n"

   screen = screen .. "=="                                      -- bottom border
   for i = 1, self.width do screen = screen .. "==" end
   screen = screen .. "=\n"

   return screen
end

function PacmanState:display()                         -- displays a given state
   io.write(self:__getScreen())
end

function PacmanState:serialize()                     -- serializes a given state
   local stateString = ""
   for row = 1, self.height do
      local cells = self.maze[row]
      for col = 1, self.width do stateString = stateString .. cells[col]; end
      stateString = stateString .. "|"
   end
   stateString = stateString .. self.score .. "|" .. self.lives
   return stateString
end

function PacmanState:clone()              -- creates a copy of the current state
   return PacmanState.create(self)
end

function PacmanState:reset()                     -- go back to the initial state
   -- TODO: not implemented
end

return PacmanState



--[[

event_list = {"pac_moved", "pac_got_treat", "pac_got_eaten", "monsters_moved"} -- list of events, for reference


-- moves monsters; assumes monster movement is correct
-- moves are given in format : {monster_index: _move_string_}
-- returns event
function move_monsters(monster_moves)
    local ev = "monsters_moved"
    for k,v in pairs(monster_moves) do
        local incs = move_incs[v]
        local old_y = monsters[k][1]
        local old_x = monsters[k][2]
        maze[old_y][old_x] = '.'

        monsters[k][1] =  old_y + incs[1]
        monsters[k][2] =  old_x + incs[2]

        local my = monsters[k][1]
        local mx = monsters[k][2]
        if (maze[my][mx] == 'P') then-- they killed Pacman!
            ev = "pac_got_eaten"
        end
        maze[my][mx] = 'X'
    end
    return ev
end

-- pretty prints the current maze
function print_maze()
    local maze_y = #maze
    local maze_x = #maze[1]
    for i=1,maze_x + 2 do
        io.write("* ")
    end
    io.write("\n")
    for i=1,maze_y do
        io.write("* ")
        io.flush()
        for j=1,maze_x do
            io.write(maze[i][j].." ")
        end
        io.write("*\n")
    end
    for i=1,maze_x + 2 do
        io.write("* ")
    end
    io.write("score: "..score.."\n")
end

-- checks if move is a valid
-- convention: monster cannot step on treat
-- we assume pacman may be stupid enough to step on monster
-- returns true if move valid, false otherwise
function is_valid_move(current_pos, move, is_monster)
    local move_inc = move_incs[move]
    local ny = current_pos[1] + move_inc[1]
    local nx = current_pos[2] + move_inc[2]

    local dim_y = #maze
    local dim_x = #maze[1]
    if (ny > dim_y or nx > dim_x or  ny < 1 or nx < 1) then
        return false
    end

    if (maze[ny][nx] == '*') then
        return false
    end

    if (is_monster and maze[ny][nx] == 'o') then
        return false
    end

    return true
end


-- generate a random move for monster with _monster_index_
function gen_rand_monster_move(monster_index)
    local m_pos = monsters[monster_index]
    local can_move = false
    for k,v in pairs(move_incs) do
        if (k ~= "nop") then
            if (is_valid_move(m_pos, k, true)) then
                can_move = true
                break
            end
        end
    end

    if (not can_move) then
        return "nop" -- no move is possible
    end

    local move_index = math.random(#move_list - 1) -- do not try nop 
    local move_inc = move_incs[move_list[move_index] ]
    while (not is_valid_move(m_pos, move_list[move_index], true)) do
        move_index = math.random(#move_list - 1)
        move_inc = move_incs[move_list[move_index] ]
    end

    return move_list[move_index]

end

-- generate moves for all monsters
function gen_all_monster_moves()
    local monster_moves = {}
    for k,v in pairs(monsters) do
        local m = gen_rand_monster_move(k)
        monster_moves[k] = m
    end
    return monster_moves
end


-- reinit maze to initial state
function re_init()
    local pac_pos = {3,4}
    local dim_x = 8
    local dim_y = 8
    local treat_pos = {{6,6}}
    local monster_pos = {{4,6}, {2,2}}
    local wall_pos = {{3,3}, {4,3}, {5,3}}
    init_maze(dim_y, dim_x, pac_pos, monster_pos, treat_pos, wall_pos)
end


-- run a turn for the monster
function monster_turn()
    local ev = move_monsters(gen_all_monster_moves())
    print_maze()
    if (ev == "pac_got_eaten") then
        score = score - 1
        re_init()
    end
    print(ev)
end

-- get all free cells in maze
function get_free_positions()
    local dim_y = #maze
    local dim_x = #maze[1]
    local free_cells = {}
    for i=1,dim_y do
        for j=1,dim_x do
            if (maze[i][j] == ".") then
                free_cells[#free_cells + 1] = {i,j}
            end
        end
    end
    return free_cells
end

-- reduce ttls for treats; those that disappear are respawned
function decay_treats()
    local num_treats = 0 -- treats that will be respawned
    for k,v in pairs(treats) do
        if (treats[k] <= 1) then
            maze[k[1] ][k[2] ] = '.'
            treats[k] = nil
            num_treats = num_treats + 1
        else
            treats[k] = treats[k] - 1
        end
    end

    local free_cells = get_free_positions()
    for i=1,num_treats do
        local ix = math.random(#free_cells)
        local pos = free_cells[ix]
        maze[pos[1] ][pos[2] ] = 'o'
        table.remove(free_cells, ix)

        treats[{pos[1],pos[2]}] = treat_ttl
    end
end


-- launch an iteration of the game
-- main function
function play()
    local pac_pos = {3,4}
    local dim_x = 8
    local dim_y = 8
    local treat_pos = {{6,6}}
    local monster_pos = {{4,6}, {2,2}}
    local wall_pos = {{3,3}, {4,3}, {5,3}}
    init_maze(dim_y, dim_x, pac_pos, monster_pos, treat_pos, wall_pos)
    print_maze()
    while(true) do
        io.write("----------------------\n")
        pac_turn()
        io.stdin:read'*l'

        monster_turn()
        io.stdin:read'*l'
        decay_treats()
    end
end
-- let the game begin
play()
--]]
