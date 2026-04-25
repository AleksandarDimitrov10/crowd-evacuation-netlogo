globals [
  initial-turtle-count
  exit-coordinates
  reached-exits
  last-positions
  current-exit-usage
  leader-exists
  all-turtles-stopped
  successful-exits
  death-count
  stuck-counter
]

turtles-own [
  speed
  energy
  last-direction
  is-leader
  is-dead
  last-position
  remembered-exit
]

to setup
  clear-all
  set-default-shape turtles "person"
  setup-background
  create-walls
  create-exits
  set leader-exists false
  if show-leader [ spawn-leader ]
  spawn-followers
  set reached-exits 0
  set last-positions []
  set current-exit-usage 0
  set successful-exits 0
  set death-count 0
  set initial-turtle-count count turtles
  reset-ticks
end

to setup-background
  ask patches [ set pcolor black ]
end

to create-walls
ask patches with [
  (pxcor = -15 or pxcor = 15) and abs(pycor) <= 15 or
  (pycor = -15 or pycor = 15) and abs(pxcor) <= 15
] [
  set pcolor red
]
ask patches with [pycor = 5 and pxcor > -12 and pxcor < 12] [ set pcolor white ]
ask patches with [pycor = -5 and pxcor > -12 and pxcor < 12] [ set pcolor white ]
ask patches with [pycor = 10 and pxcor > -10 and pxcor < 10] [ set pcolor white ]
ask patches with [pycor = -10 and pxcor > -10 and pxcor < 10] [ set pcolor white ]
ask patches with [pxcor = 5 and pycor > -13 and pycor < 13] [ set pcolor white ]
ask patches with [pxcor = -5 and pycor > -13 and pycor < 13] [ set pcolor white ]
ask patches with [pycor = 5 and pxcor >= -1 and pxcor <= 1] [ set pcolor black ]
ask patches with [pycor = -5 and pxcor >= -1 and pxcor <= 1] [ set pcolor black ]
ask patches with [pxcor = -5 and pycor >= -1 and pycor <= 1] [ set pcolor black ]
ask patches with [pxcor = 5 and pycor >= -1 and pycor <= 1] [ set pcolor black ]
ask patches with [pycor = 10 and pxcor >= -1 and pxcor <= 1] [ set pcolor black ]
ask patches with [pycor = -10 and pxcor >= -1 and pxcor <= 1] [ set pcolor black ]
end

to create-exits
 set exit-coordinates []
 repeat exit-count [
   let exit-location one-of (patches with [pcolor = red and (pxcor = -15 or pxcor = 15 or pycor = -15 or pycor = 15)])
   if exit-location != nobody [
     ask exit-location [ set pcolor green ]
     set exit-coordinates lput (list [pxcor] of exit-location [pycor] of exit-location) exit-coordinates
   ]
 ]
 set current-exit-usage 0
end

to spawn-leader
  ask turtles with [is-leader] [ die ]
  create-turtles 1 [
    set is-leader true
    set color yellow
    set size 1.5
    set speed random-float 0.5 + 0.9
    set energy random max-energy + 20
    set last-direction random 360
    set is-dead false
    set last-position []
    set remembered-exit nobody
    setxy random-xcor random-ycor
    while [not within-bounds?] [ setxy random-xcor random-ycor ]
  ]
  set leader-exists true
end

to spawn-followers
  create-turtles (agent-count - count turtles with [is-leader]) [
    set is-leader false
    let spawn-location nobody
    while [spawn-location = nobody] [
      let x random (31) - 15
      let y random (31) - 15
      let patch-location patch x y
      if [pcolor] of patch-location = black [
        set spawn-location patch-location
      ]
    ]
    setxy [pxcor] of spawn-location [pycor] of spawn-location
    set color blue
    set size 1.0
    set speed random-float 0.4 + 0.7
    set energy random max-energy + 10
    set last-direction random 360
    set is-dead false
    set last-position []
  ]
end

to go
  if show-leader [
    if not leader-exists [ spawn-leader ]
  ]

  if not show-leader [
    ask turtles with [is-leader] [ die ]
    set leader-exists false
  ]

  ask turtles [
    if energy > 0 [
      ifelse is-leader [
        ifelse leader-knows-exit [
          move-toward-exit
        ] [
          wander-and-search
        ]
      ] [
        follow-leader-or-move-to-exit
      ]
      move-slightly
      correct-outside-boundary
      set energy energy - 1
      detect-stuck
      detect-exit-line-of-sight
      if energy <= 0 [
        set color red
        set is-dead true
        set death-count death-count + 1
      ]
    ]
  ]
  set all-turtles-stopped all? turtles [is-dead or energy <= 0]
  if all-turtles-stopped [ stop ]
  update-plots
  tick
end

to follow-leader-or-move-to-exit
  let leader one-of turtles with [is-leader]
  if leader != nobody [
    let dist-to-leader distance leader
    ifelse dist-to-leader < 10 [
      face leader
      move-slightly
    ] [
      let nearest-exit find-nearest-exit
      if nearest-exit != nobody [
        face nearest-exit
        move-slightly
      ]
    ]
  ]
end

to wander-and-search
  let nearby-exit one-of patches in-radius 30 with [pcolor = green]
  let nearest-exit find-nearest-exit
  if nearest-exit != nobody and (remembered-exit = nobody or distance nearest-exit < distancexy item 0 remembered-exit item 1 remembered-exit) [
    set remembered-exit list [pxcor] of nearest-exit [pycor] of nearest-exit
  ]
  if remembered-exit != nobody and length remembered-exit = 2 [
    face patch item 0 remembered-exit item 1 remembered-exit
    move-toward-exit-fast
  ]
  rt random 10 - 5
  move-slightly
end

to correct-outside-boundary
  if pxcor < -15 [ set xcor -15 ]
  if pxcor > 15 [ set xcor 15 ]
  if pycor < -15 [ set ycor -15 ]
  if pycor > 15 [ set ycor 15 ]
end

to move-toward-exit
  let nearest-exit find-nearest-exit
  if nearest-exit != nobody [
    face nearest-exit
    fd speed * 1.5
    if distance nearest-exit < 15 [
      set energy energy - 0.2
    ]
  ]
end

to move-toward-exit-fast
  if remembered-exit != nobody [
    let exit-location patch item 0 remembered-exit item 1 remembered-exit
    face exit-location
    let dist-to-exit distance exit-location
    let dynamic-speed speed * (1.4 + (30 - dist-to-exit) / 20)  ; More acceleration toward the exit

    fd dynamic-speed
    set energy energy - 0.1
  ]
end

to detect-exit-line-of-sight
  let wall-neighbor one-of patches in-radius 1 with [pcolor = red]
  if wall-neighbor != nobody [
    let potential-exit one-of patches in-radius 5 with [pcolor = green]
    if potential-exit != nobody [
      face potential-exit
      fd speed * 1.2
    ]
  ]
end

to move-slightly
  let next-patch patch-ahead 1
  if ([pcolor] of next-patch = black or [pcolor] of next-patch = green) and within-bounds? [
    fd speed
    if ([pcolor] of patch-here = green) [
  if count turtles in-radius 1 with [pcolor = green and not is-dead] < exit-capacity [
    set reached-exits reached-exits + 1
    set current-exit-usage current-exit-usage + 1
    set successful-exits successful-exits + 1
    die
  ]
]
  ]
  avoid-walls
  correct-outside-boundary
end

to avoid-walls
  let attempts 0
  while [attempts < 10] [
    rt random-float 30 - 15
    let next-patch patch-ahead 1
    if ([pcolor] of next-patch = black or [pcolor] of next-patch = green) [
      fd speed * 0.9  ; More movement to help escape walls
      stop
    ]
    set attempts attempts + 1
  ]
  rt random 180
  bk speed * 0.5
end

to-report within-bounds?
  report pxcor >= -15 and pxcor <= 15 and pycor >= -15 and pycor <= 15
end

to detect-stuck
  if is-leader [
    let current-position (list xcor ycor)
    ifelse last-position = current-position [
      set stuck-counter stuck-counter + 1
      if stuck-counter > 5 [
        rt random 180
        set stuck-counter 0
      ]
    ] [
      set stuck-counter 0
    ]
    set last-position current-position
  ]
end

to-report find-nearest-exit
  if empty? exit-coordinates [ report nobody ]
  let nearest-exit nobody
  let min-distance max-pxcor * 2
  foreach exit-coordinates [
    exit ->
      let dist distancexy item 0 exit item 1 exit
      if dist < min-distance [
        set min-distance dist
        set nearest-exit patch item 0 exit item 1 exit
      ]
  ]
  report nearest-exit
end

to-report escape-percentage
  if initial-turtle-count = 0 [ report 0 ]
  report (successful-exits / initial-turtle-count) * 100
end

to-report death-percentage
  if initial-turtle-count = 0 [ report 0 ]
  report (death-count / initial-turtle-count) * 100
end
@#$#@#$#@
GRAPHICS-WINDOW
484
57
1011
585
-1
-1
15.73
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
125
12
188
45
NIL
Go\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
15
11
81
44
NIL
Setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
26
84
198
117
exit-count
exit-count
1
10
8.0
1
1
NIL
HORIZONTAL

SLIDER
26
132
198
165
agent-count
agent-count
0
100
52.0
1
1
NIL
HORIZONTAL

SLIDER
26
176
198
209
max-energy
max-energy
0
100
48.0
1
1
NIL
HORIZONTAL

SLIDER
25
224
197
257
exit-capacity
exit-capacity
0
10
6.0
1
1
NIL
HORIZONTAL

SWITCH
5
272
139
305
show-leader
show-leader
0
1
-1000

PLOT
11
323
362
618
Exits - Deaths
Ticks
Number of Exits/Deaths
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Exits" 1.0 0 -13840069 true "" "plot successful-exits"
"Died" 1.0 0 -2674135 true "" "plotxy ticks death-count"

MONITOR
370
351
455
396
People Exited
successful-exits
17
1
11

MONITOR
368
479
453
524
People Died
death-count
17
1
11

SWITCH
156
272
327
305
leader-knows-exit
leader-knows-exit
0
1
-1000

TEXTBOX
631
156
781
174
Inner-Walls\n
13
0.0
1

TEXTBOX
635
61
785
79
Outer-Walls
13
15.0
1

TEXTBOX
798
62
948
80
Exits
13
65.0
1

MONITOR
370
404
436
449
% Escaped
escape-percentage
17
1
11

MONITOR
369
532
429
577
% Death
death-percentage
17
1
11

@#$#@#$#@
## WHAT IS IT?

This model simulates an evacuation process in a building, where agents (representing people) attempt to escape through exits during an emergency. The goal of the model is to understand how different factors—such as the number of exits, the maximum energy available to agents, and the leadership roles—affect the overall evacuation success, which is measured by the percentage of agents who successfully escape. The model allows for experimentation with different scenarios to determine which parameters lead to the fastest or most efficient evacuations.

## HOW IT WORKS

In this model, agents move towards exits based on several factors:

1-) Escape Routes: Agents will attempt to find and move toward the nearest exit. The number of exits and their capacity influence how quickly agents can escape.

2-) Agent Energy: Each agent has a maximum energy value, representing their stamina or ability to move. Agents with higher energy can move faster and escape sooner.

3-) Leadership: Some agents are designated as leaders. Leaders may have specific advantages, such as knowing the exit locations and being able to guide other agents.

4-) Exit Capacity: Each exit has a limited capacity, meaning that if too many agents try to use the same exit, it could slow down the evacuation process.

5-) Escape Percentage: The primary output of the model is the escape percentage, which measures how many agents successfully reach an exit within the time limit.




The agents follow simple rules:

Movement: Agents move towards exits, considering their energy and the distance to the exit.

Escape: If an agent reaches an exit before the simulation ends, they are considered to have escaped.

Leadership Effect: Leaders can influence other agents’ choices, potentially improving the evacuation rate.

## HOW TO USE IT

Sliders:

Number of Exits: Adjust the number of exits available in the simulation. More exits generally lead to faster evacuation times.

Exit Capacity: Adjust the maximum number of agents that can exit through each door per time step.

Max Energy: Set the maximum energy for agents, which affects how quickly they can move towards exits.



Switches:

Show Leaders: Toggle this to indicate whether agents with leadership roles are present. Leaders can help influence others.

Show Exit Information: This option displays the current number of agents at each exit during the simulation.




Buttons:

Setup: Initializes the simulation, setting up agents, exits, and the environment.

Go: Starts the simulation, where agents move towards exits and the evacuation process occurs.



Plots:

Plot shows the ratio of escaped-agents and dead-agents
Monitors: 2 monitors showing the number or dead and alive agents. 2 other monitors showing the percentage of death/escaped.



## THINGS TO NOTICE

Evacuation Efficiency: Observe how the escape percentage changes as you vary the number of exits, exit capacity, or max energy.

Agent Behavior: Watch how agents with higher energy move more quickly and escape faster than those with lower energy.

Role of Leadership: Notice how the presence of leader agents can influence the evacuation rate and how quickly agents escape.

Exit Bottlenecks: Look for congestion at exits when there are too many agents trying to exit through a single door.

## THINGS TO TRY

Vary the number of exits: Try increasing or decreasing the number of exits to see how the escape percentage changes.

Adjust exit capacities: Experiment with different exit capacities to see how limiting the number of agents per exit affects the evacuation time.

Test different agent energy levels: Set different energy levels for agents and observe how this affects their ability to escape.

Toggle leader visibility: Try enabling and disabling leader agents and observe their impact on the overall evacuation.

Run scenarios: Try running several different scenarios (e.g., more exits vs. fewer exits) and compare the resulting evacuation times.

## EXTENDING THE MODEL

Add Obstacles: Introduce obstacles or blockages that could slow down agents or force them to take longer routes.

Simulate Panic: Implement a panic effect where agents become less efficient in their movement under stress, slowing down their progress.

Complex Exit Behavior: Allow agents to choose between multiple exits, based on factors like perceived congestion or proximity.

Advanced Leadership Roles: Introduce multiple types of leaders with different abilities to guide others, e.g., some leaders may influence larger groups, others might know the quickest routes.

Time Pressure: Add a time limit for evacuation, forcing agents to escape before the end of the simulation.


## CREDITS AND REFERENCES

Made by:

Soham Desriaux
Aleksandar Dimitrov

MAS Project 25/11/2024
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Evacuation - Scenario 1" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>escape-percentage</metric>
    <steppedValueSet variable="exit-count" first="1" step="1" last="3"/>
    <enumeratedValueSet variable="agent-count">
      <value value="75"/>
    </enumeratedValueSet>
    <steppedValueSet variable="max-energy" first="0" step="3" last="33"/>
    <steppedValueSet variable="exit-capacity" first="1" step="1" last="3"/>
    <enumeratedValueSet variable="show-leader">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="leader-knows-exit">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Evacuation- Scenario 2" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>escape-percentage</metric>
    <steppedValueSet variable="exit-count" first="4" step="1" last="6"/>
    <enumeratedValueSet variable="agent-count">
      <value value="75"/>
    </enumeratedValueSet>
    <steppedValueSet variable="max-energy" first="34" step="3" last="66"/>
    <steppedValueSet variable="exit-capacity" first="4" step="1" last="6"/>
    <enumeratedValueSet variable="show-leader">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="leader-knows-exit">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Evacuation - Scenario 3" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>escape-percentage</metric>
    <steppedValueSet variable="exit-count" first="7" step="1" last="10"/>
    <enumeratedValueSet variable="agent-count">
      <value value="75"/>
    </enumeratedValueSet>
    <steppedValueSet variable="max-energy" first="67" step="3" last="100"/>
    <steppedValueSet variable="exit-capacity" first="7" step="1" last="10"/>
    <enumeratedValueSet variable="show-leader">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="leader-knows-exit">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
