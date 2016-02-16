--------------------------------------------------------------------------------
--- Load modules
--------------------------------------------------------------------------------

require("torch")


--------------------------------------------------------------------------------
--- Implement pacman as a game
--------------------------------------------------------------------------------

local pacman = torch.class("pacman")

function pacman.initialState()          -- returns the initial state of the game
   return {maze = "+"}
end

function pacman.applyMove(state, action)      -- player performs action in state
   local rewoard = 0
   local next_state = {}
   return reward, next_state                    -- returns reward and next state
end

function pacman.getActions()                       -- returns the set of actions
   return {"north", "east", "south", "east"}
end

function pacman.isFinal(state)               -- checks if a given state is final
   return state.isFinal
end

function pacman.displayState(state)                    -- displays a given state
   print(state.maze)
end

function pacman.serializeState(state)                -- serializes a given state
   print("x")
end


return pacman




--[[
-- Pacman is in a maze. He must collect magic 'o's
-- maze is a 2D matrix with values:
-- P -> pacman
-- o -> delight
-- X -> bad bad monster, run away from him
-- * -> great asciinese wall
-- . -> empty cell, anything can go here

-- Pacman and the monsters take turns
-- After pacman and monsters made their move, treats are 'decayed'
-- i.e. after a predefined time, treats disappear and regenerate in new
-- positions


-- globals
maze =  {}
pac = {} -- current position of pacman
monsters = {} -- current positions of monsters, entries of type: {monster_index: {x,y}}
treats = {} -- current positions of treats and corresponding ttls: {{y,x} : ttl}
treat_ttl = 1 -- treats have a time after which they disappear
move_list = {"up", "down", "left", "right", "nop"} -- list of possible moves in maze
move_incs = {up={-1, 0}, down={1, 0}, left={0, -1}, right={0, 1}, nop={0, 0}} -- corresponding indexes

score = 0 -- +1 every time pacman gets a treat; -1 every time he dies
-- end global section

-- initialize maze
-- dim_x -> width of maze; single number
-- dim_y -> height of maze; single number
-- pac pos -> initial position of pacman; table with position {y, x}
-- monster_pos -> initial positions of monsters; table with positions {{y,x}}
-- treat_pos ->  initial positions of treats; table with positions {{y,x}}
function init_maze(dim_y, dim_x, pac_pos, monster_pos, treat_pos, wall_pos)
    --get rid of prev values
    maze =  {}
    pac = {}
    monsters = {}
    treats = {}

    -- initialize empty maze
    for i = 1,dim_y do
        maze[i] = {}
        for j = 1,dim_x do
            maze[i][j] = '.' -- initially empty
        end
    end

    --add the pacman
    local pac_y = pac_pos[1]
    local pac_x = pac_pos[2]
    maze[pac_y][pac_x] = 'P'
    pac = pac_pos

    --add the monsters
    for k,v in pairs(monster_pos) do
        maze[v[1] ][v[2] ] = 'X'
        monsters[#monsters + 1] = v
    end

    --add the treats
    for k,v in pairs(treat_pos) do
        maze[v[1] ][v[2] ] = 'o'
        treats[v] = treat_ttl
    end

    --add the walls
    for k,v in pairs(wall_pos) do
        maze[v[1] ][v[2] ] = '*'
    end

end

event_list = {"pac_moved", "pac_got_treat", "pac_got_eaten", "monsters_moved"} -- list of events, for reference

-- performs a move on pacman, assumes move is correct
-- returns an event corresponding the action that took place
function move_pac(pac_move)
    maze[pac[1] ][pac[2] ] = '.'
    local incs =  move_incs[pac_move]

    pac[1] = pac[1] + incs[1]
    pac[2] = pac[2] + incs[2]
    local ev = "pac_moved"
    if (maze[pac[1] ][pac[2] ] == 'o') then -- pacman got a treat
        ev = "pac_got_treat"
        treats[{pac}] = nil -- remove treat from dict
    elseif (maze[pac[1] ][pac[2] ] == 'X') then
        ev = "pac_got_eaten"
    end

    maze[pac[1] ][pac[2] ] = 'P' -- move the pacman

    return ev

end

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




-- generate a random move for pacman
function gen_rand_pac_move()
    local can_move = false
    for k,v in pairs(move_incs) do
        if (k ~= "nop") then
            if (is_valid_move(pac, k, false)) then
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
    while (not is_valid_move(pac, move_list[move_index], false)) do
        move_index = math.random(#move_list - 1)
        move_inc = move_incs[move_list[move_index] ]
    end

    return move_list[move_index]

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


-- run a turn for pacman
function pac_turn()
    local ev = move_pac(gen_rand_pac_move())
    print_maze()
    if (ev == "pac_got_treat") then
        score = score + 1
    elseif (ev == "pac_got_eaten") then
        score = score - 1
        re_init()
    end
    print(ev)
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
