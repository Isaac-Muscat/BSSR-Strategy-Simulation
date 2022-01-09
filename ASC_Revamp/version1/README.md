# American Solar Challenge (ASC) Simulation - August 2022
This folder contains the files for strategy simulations for the ASC.

## Last Edits
2021/Dec/17: Isaac Muscat

## Future Additions/Prospects
* Sort loop plans by distance travelled
* Use binary search to find the viable plan with the greatest distance travelled
* Store more useful info into each RaceCarSim object simInfo_table

## Bugs and TODO
* Stages, checkpoint, loops logic may be flawed
* Coefficient for rolling resistance is questionable --> From SCP (Page 26) and tests
* Crazy jumps at night charges
* Distance of stages and loops may be flawed
* Refactor some relationships between RaceCarSim.m and Route.m

## Conventions
Loop Plan or a Plan describes:
1. The number of loops in the race.
2. How many repeats per loop.
3. The cruise speed of the car.
Uses a naming convention following <variableName>_<unit/type> Examples:
* carSpeed_kmh: car speed in km/h
* ARRAY_EFF: array's percentage efficiency as a decimal

## General Format
The listed files constitute the structure of the simulation.
**They are classes to be instantiated as objects.**

### Route.m
* This is the entry point of interaction with the user.
* Contains the route information.
* Generates loop plans.
* Selects viable loop plans.
* handles the logic for the route.

### LoopPlans.m
* Specifies the amount of loops in the race, the number of repeats for each loop, and the various cruise speeds.
* Generates all possible loop plans for the race with speeds.

### RaceCarSim.m
* Contains all the logic for one simulation with an associated loop plan and speed.
* This includes array gains and losses with associated equations.
* This object is created by a Route.m object.