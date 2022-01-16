% Import utilities functions
addpath('../Utilities/');

% Clear the console.
clc;

% Clear the workspace
clear;

% Turn off annoying warnings
% warning('off','all')

% Load all csvs in memory
ROUTE_CSV = readmatrix("../csvs/baseRoute.csv");
LOOP_ONE_CSV = readmatrix("../csvs/loopOne.csv");
LOOP_TWO_CSV = readmatrix("../csvs/loopTwo.csv");
LOOP_THREE_CSV = readmatrix("../csvs/loopThree.csv");
DNI_SCALING_CSV = readmatrix("../csvs/ascLUT.csv");
DNI_CSV = readmatrix("../csvs/dni.csv");
DHI_CSV = readmatrix("../csvs/dhi.csv");

% Define critcal indices forcheckpoints, stage stops, and base legs

% Define checkpoint indices
CHECKPOINT_INDICES = [2610,5745,8099];

% Define stage stop indices
STAGE_STOP_INDICES = [3907,12954,16207];

% Define loop indices
LOOP_INDICES = [3907,8099,12954];

% Stage 1
S1O = datetime('3-Aug-2021 09:00:00'); % Stage 1 open time
S1C = datetime('3-Aug-2021 18:00:00'); % Stage 1 close time (index 3907)

CP1O = datetime('3-Aug-2021 12:00:00'); % Check point 1 open time (index 2610)
CP1R = datetime('3-Aug-2021 14:00:00'); % Check point 1 drive resume time
CP1C = datetime('3-Aug-2021 14:45:00'); % Check point 1 close time

L1C  = datetime('3-Aug-2021 18:00:00'); % Loop 1 close time

% Stage 2
S2O = datetime('4-Aug-2021 09:00:00'); % Stage 2 open time
S2C = datetime('6-Aug-2021 18:00:00'); % Stage 2 close time (index 12954)

CP2O = datetime('4-Aug-2021 11:45:00'); % Check point 2 open time (index 5745)
CP2R = datetime('4-Aug-2021 15:45:00'); % Check point 2 drive resume time
CP2C = datetime('4-Aug-2021 16:30:00'); % Check point 2 close time

CP3O = datetime('4-Aug-2021 16:45:00'); % Check point 3 open time (index 8099)
CP3R = datetime('5-Aug-2021 15:30:00'); % Check point 3 drive resume time
CP3C = datetime('5-Aug-2021 16:35:00'); % Check point 3 close time

L2C  = datetime('5-Aug-2021 15:15:00'); % Loop 2 close time
L3C  = datetime('6-Aug-2021 19:00:00'); % Loop 3 close time

% Stage 3
S3O = datetime('7-Aug-2021 10:00:00'); % Stage 3 open time
S3C = datetime('7-Aug-2021 16:00:00'); % Stage 3 close time (index 16207)

% Table for Checkpoints
OpenTimes   = [CP1O;CP2O;CP3O];
CloseTimes  = [CP1C;CP2C;CP3C];
ResumeTimes = [CP1R;CP2R;CP3R];
Indices     = CHECKPOINT_INDICES';
Checkpoints = table(OpenTimes, CloseTimes, Indices);

% Table for Loops
CloseTimes  = [L1C;L2C;L3C];
Indices     = LOOP_INDICES';
Path = {LOOP_ONE_CSV; LOOP_TWO_CSV; LOOP_THREE_CSV};
Loops = table(CloseTimes, Indices, Path);

% Table for Stages
OpenTimes = [S1O;S2O;S3O];
CloseTimes = [S1C;S2C;S3C];
Indices     = STAGE_STOP_INDICES';
Stages = table(OpenTimes, CloseTimes, Indices);

% Create a loop plan generator
loopPlanGen = LoopPlanGenerator(60:60, 3, 1);

% Create a simulation generator
carSimGen = CarSimGenerator(DNI_SCALING_CSV, DNI_CSV, DHI_CSV, loopPlanGen);

% Create route
route = Route(ROUTE_CSV, Checkpoints, Loops, Stages, carSimGen);

% TODO Calculate stage/loop distances
% TODO Discard untimely plans
route.cullLateSims();

% Search through plans and run sim on each one
% route.runSims();

% Tabulate the results of sims in csvs

% Find optimal sim

% Plot battery charge over distance

disp("Finished")
