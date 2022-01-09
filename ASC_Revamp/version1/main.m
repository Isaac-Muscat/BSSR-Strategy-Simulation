
% 1. Generate possible plans
% 2. Find distances between checkpoints, stages, and loops
% 3. Find viable plans
% 4. Loop through viable plans
%   - Run Sim
%   - Determine Charge
% 5. Output plan and battery plot

% Import utilities functions
addpath('../Utilities/');

% Clear the console.
clc;

% Turn off annoying warnings
% warning('off','all')

% Load all csvs in memory
ROUTE_CSV = readmatrix("../csvs/baseRoute.csv");
LOOP_ONE_CSV = readmatrix("../csvs/loopOne.csv");
LOOP_TWO_CSV = readmatrix("../csvs/loopTwo.csv");
LOOP_THREE_CSV = readmatrix("../csvs/loopThree.csv");
NORAML_IRADIANCE_SCALING_CSV = readmatrix("../csvs/ascLUT.csv");
NORMAL_IRADIANCE_CSV = readmatrix("../csvs/dni.csv");
DIFFUSE_IRADIANCE_CSV = readmatrix("../csvs/dhi.csv");

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

% Instantiate route object
route = Route(NORMAL_IRADIANCE_CSV, DIFFUSE_IRADIANCE_CSV, NORAML_IRADIANCE_SCALING_CSV);

% Read CSVs associated with the car's path
route.baseRoute = ROUTE_CSV;
route.loopRoutes_cell = {LOOP_ONE_CSV, LOOP_TWO_CSV, LOOP_THREE_CSV};

route.loopCoordinates = LOOP_INDICES;
route.loopCloseTimes = [L1C, L2C, L3C];

route.stageFinishCoordinates = STAGE_STOP_INDICES;
route.stageOpenTimes = [S1O, S2O, S3O];
route.stageCloseTimes = [S1C, S2C, S3C];

route.checkPointCoordinates = CHECKPOINT_INDICES;
route.checkPointOpenTimes = [CP1O, CP2O, CP3O];
route.checkPointDriveResumeTimes = [CP1R, CP2R, CP3R];
route.checkPointCloseTimes = [CP1C, CP2C, CP3C];
disp("Loaded inputs.")

% Find and store distances for every path the car can take
route.calculateDistances_km();
disp("Calculated all distances cars can take.")

% Generate loop plans
route.loopPlan = LoopPlans([60], 3, 1);
disp("Generated loop plans.")

% Discard loop plans that take to long to finish
route.calculateViablePlans();
disp("Calculated viable plans.")

% Loop through every time-bound viable loop plan
% Step through the race using plan and RaceCarSim
% Use Race Car Sim as simulation
% Find when charge is < 0 and discard sim
% Calculate total distance each plan achieved
% Find max distance of all plans

% Returns race car simulation object with optimal parameters
% [optimalRaceCarSim] = route.findOptimalPlan();

% Testing the sim and route logic on one plan
plan = [1, 1, 1, 65];
optimalRaceCarSim = RaceCarSim(plan(1, end), plan(1, 1:end-1));
route.runSim(optimalRaceCarSim);

disp("Found optimal plan.")

% Plot battery charge, display speed
plot(optimalRaceCarSim.batteryCharge_vec(:, 1), optimalRaceCarSim.batteryCharge_vec(:, 2));
hold on;
title('Battery Energy over Distance Travelled');
xlabel('Distance (km)');
ylabel('Battery Energy (kWh)');
hold off;

disp("Finished!")
