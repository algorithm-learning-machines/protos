# protos
prototypes and  experimental code

## Solving Pacman with various Reinforcement Learning algorithms

If you want to see the game play, run this:

    th main.lua -player random -episodes 4 -evalEvery 4 -evalEpisodes 0 -display -sleep 0.15

If you want to play the game:

    th main.lua -player human -justForFun -display -episodes 2

If you want to see Q-Learning evolving:

    th main.lua -height 4 -width 4 -monstersNo 1 -walls "2,2;2,3;3,2;3,3" -player Q -treatsNo 1 -episodes 100000
