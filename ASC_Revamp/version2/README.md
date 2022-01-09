# American Solar Challenge (ASC) Strategy Simulation
This program runs simulations to determine the optimal loop plan that the solar car should take in order to maximize distance.

## Loop Plans
The simulation determines the optimal number of repeats for each loop and the optimal constant speed to accumlate the most distance throughout the entire race.

## Structure
An overview of the structure of the script.

### main.m
This is the entry point of the program which can be defined by the user.
### Route.m
This is the main container/object/interface in which the user interacts and manipulates.
### CarSim.m
This defines a single car simulation which is manipulated by the route object
### CarSimGenerator.m
This generates all the CarSim objects that are supplied to the route object to run.
### LoopPlanGenerator.m
This generates all the possible plans that are inputted into the CarSimGenerator object.