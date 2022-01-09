classdef Route < handle
    % Defines the race and runs multiple simulations
    
    properties
        baseRoute;
        distsBetweenStops_km;
        stopsCheckpointsStages;

        loopRoutes_cell;
        loopCoordinates;
        loopCloseTimes;
        loopDists_km;

        stageFinishCoordinates;
        stageOpenTimes;
        stageCloseTimes;

        checkPointCoordinates;
        checkPointOpenTimes;
        checkPointDriveResumeTimes;
        checkPointCloseTimes;

        viableLoopSpeedCombos;
        loopPlan;

        LUT_TABLE;
        DHI;
        DNI;
    end
    
    methods
        function this = Route(DNI, DHI, LUT_TABLE)
            % Construct an instance of Route.m.
            
            this.viableLoopSpeedCombos = [];
            this.LUT_TABLE = LUT_TABLE;
            this.DHI = DHI;
            this.DNI = DNI;
        end

        function runSim(this, sim)
            % Execute a sim of an entire race and capture critical data.
            
            time = this.stageOpenTimes(1);
            loops_reached = 0;
            checkpoints_reached = 0;
            stages_reached = 0;

            % Move through base route
            for i=2:size(this.baseRoute, 1)
                if sim.batteryCharge_kwh <= 0
                    disp("This car ran out of charge in the base route.")
                    return;
                end

                % Get distance travelled
                pos1 = this.baseRoute(i-1, :);
                pos2 = this.baseRoute(i, :);
                delta_dist_km = getDist(pos1(1), pos1(2), pos2(1), pos2(2));

                % Get useful info
                delta_alt_km = pos2(1, 3) - pos1(1, 3);
                bearing_degrees = getBearing(pos1(1), pos1(2), pos2(1), pos2(2));
                [Az, El] = sim.getAzElFromBearing(bearing_degrees, pos1(1), pos1(2), pos1(3), time);

                % Update time
                delta_time_h = delta_dist_km/sim.carSpeed_kmh;
                time = time + hours(delta_time_h);

                % Update distance
                sim.updateDistance(delta_dist_km);
                
                % Update Charge
                [row, col] = this.getDniIndex(time, pos1);
                sim.updateCharge(delta_time_h, delta_dist_km, delta_alt_km, Az, El, this.DNI, this.DHI, this.LUT_TABLE, row, col);

                % Night stop
                if hour(time) >= 18
                    time = time + hours(15);
                    sim.updateCharge(15, 0, 0, Az, El, this.DNI, this.DHI, this.LUT_TABLE, row, col);
                    disp("Reached a night charge")
                end

                % Reach Checkpoint
                if ismember(i, this.checkPointCoordinates)
                    checkpoints_reached = checkpoints_reached + 1
                    if time < this.checkPointCloseTimes(checkpoints_reached) && time > this.checkPointOpenTimes(checkpoints_reached)
                        time = time + minutes(45);
                        sim.updateCharge(0.75, 0, 0, Az, El, this.DNI, this.DHI, this.LUT_TABLE, row, col);
                    end

                % Reach Stage End
                elseif ismember(i, this.stageFinishCoordinates)
                    stages_reached = stages_reached + 1
                    time = time + minutes(45);
                    sim.updateCharge(0.75, 0, 0, Az, El, this.DNI, this.DHI, this.LUT_TABLE, row, col);
                end

                % Reach Loop
                if ismember(i, this.loopCoordinates)
                    loops_reached = loops_reached + 1
                    time = time + minutes(15);
                    sim.updateCharge(0.25, 0, 0, Az, El, this.DNI, this.DHI, this.LUT_TABLE, row, col);

                    for i2=2:sim.loopPlan(loops_reached)
                        if sim.batteryCharge_kwh <= 0
                            disp("This car ran out of charge in a loop.")
                            return;
                        end
        
                        % Get distance travelled
                        pos1 = this.loopRoutes_cell{loops_reached}(i2-1, :);
                        pos2 = this.loopRoutes_cell{loops_reached}(i2, :);
                        delta_dist_km = getDist(pos1(1), pos1(2), pos2(1), pos2(2));
        
                        % Get useful info
                        delta_alt_km = pos2(1, 3) - pos1(1, 3);
                        bearing_degrees = getBearing(pos1(1), pos1(2), pos2(1), pos2(2));
                        [Az, El] = sim.getAzElFromBearing(bearing_degrees, pos1(1), pos1(2), pos1(3), time);
        
                        % Update time
                        delta_time_h = delta_dist_km/sim.carSpeed_kmh;
                        time = time + hours(delta_time_h);
        
                        % Update charge and distance
                        sim.updateDistance(delta_dist_km);
                        [row, col] = this.getDniIndex(time, pos1);
                        sim.updateCharge(delta_time_h, delta_dist_km, delta_alt_km, Az, El, this.DNI, this.DHI, this.LUT_TABLE, row, col);
                        
                        % Night stop
                        if hour(time) >= 18
                            time = time + hours(15);
                            sim.updateCharge(15, 0, 0, Az, El, this.DNI, this.DHI, this.LUT_TABLE, row, col);
                            disp("Reached a night charge")
                        end
                    end

                end
            end
        end
        
        function [row, col] = getDniIndex(this, time, pos)
            time_datenum = datenum(time);
            for j = 3:size(this.DNI,2)
                locTime(j-2) = abs(etime(datevec(time_datenum),datevec(this.DNI(1,j))));
            end

            [minTime,col] = min(locTime);
            col = col + 2;

            for j = 2:size(this.DNI,1)
                locDist(j-1) = getDist(pos(1),pos(2),this.DNI(j,1),this.DNI(j,2));
            end

            [minDist,row] = min(locDist);
            row = row + 1;
        end

        function [optimalRaceCarSim] = findOptimalPlan(this)
            for i=1:size(this.viableLoopSpeedCombos, 1)
                plan = this.viableLoopSpeedCombos(i, :);
                sim = RaceCarSim(plan(1, end), plan(1, 1:end-1));
                this.runSim(sim);
                if i==1
                    optimalRaceCarSim = sim;
                elseif sim.distanceTravelled_km > optimalRaceCarSim.distanceTravelled_km && sim.batteryCharge_kwh > 0
                    optimalRaceCarSim = sim;    
                end
            end
        end

        function calculateViablePlans(this)
            num_plans = size(this.loopPlan.getRepeatsPerLoop(), 1);
            for i=this.loopPlan.getSpeeds()
                this.viableLoopSpeedCombos = [
                    this.viableLoopSpeedCombos;
                    this.loopPlan.getRepeatsPerLoop(), i.*ones(num_plans, 1)
                    ];
            end

            for i=size(this.viableLoopSpeedCombos, 1):-1:1
                if this.isPlanValid(this.viableLoopSpeedCombos(i, :)) == false
                    this.viableLoopSpeedCombos(i, :)
                    this.viableLoopSpeedCombos(i, :) = [];
                end
            end
        end

        function bool = isPlanValid(this, plan)
            % Returns if a plan can be executed before stage close times

            % Declare keep track of time
            time = this.stageOpenTimes(1);
            num_loops_reached = 0;
            num_checkpoints_reached = 0;
            num_stages_finished = 0;

            for i=1:size(this.stopsCheckpointsStages, 2)
                dist = this.distsBetweenStops_km(i);
                delta_hours = dist/plan(end);
                time = time + hours(delta_hours);

                if hour(time) >= 18
                    time = time + hours(15);
                end

                route_index = this.stopsCheckpointsStages(i);
                if ismember(route_index, this.checkPointCoordinates)
                    num_checkpoints_reached = num_checkpoints_reached + 1;
                    if time < this.checkPointCloseTimes(num_checkpoints_reached) && time > this.checkPointOpenTimes(num_checkpoints_reached)
                        time = time + minutes(45);
                    end

                elseif ismember(route_index, this.stageFinishCoordinates)
                    num_stages_finished = num_stages_finished + 1;
                    if time <= this.stageCloseTimes(num_stages_finished)
                        time = time + minutes(45);
                    else
                        bool = false;
                        return
                    end
                end

                if ismember(route_index, this.loopCoordinates)
                    num_loops_reached = num_loops_reached + 1;
                    num_repeats = plan(num_loops_reached);
                    dist = num_repeats*this.loopDists_km(num_loops_reached);
                    delta_hours = dist/plan(end) + num_repeats*0.25;
                    time = time + hours(delta_hours);
                    if time > this.loopCloseTimes(num_loops_reached)
                        bool = false;
                        return
                    end
                end
            end
            bool = true;
        end
        
        function calculateDistances_km(this)
            %calculateDistances_km Summary of this method goes here
            %   Detailed explanation goes here

            this.distsBetweenStops_km = [];
            current_distance = 0;
            this.stopsCheckpointsStages = [this.stageFinishCoordinates, this.checkPointCoordinates];
            sort(this.stopsCheckpointsStages);

            for i=2:size(this.baseRoute, 1)
                pos1 = this.baseRoute(i-1, 1:2);
                pos2 = this.baseRoute(i, 1:2);
                current_distance = current_distance + getDist(pos1(1), pos1(2), pos2(1), pos2(2));
                
                if ismember(i, this.stopsCheckpointsStages)
                    this.distsBetweenStops_km(end+1) = current_distance;
                    current_distance = 0;
                end
            end
            

            this.loopDists_km = zeros(1, size(this.loopRoutes_cell, 2));
            for loop_num = 1:size(this.loopRoutes_cell, 2)
                current_loop = this.loopRoutes_cell{loop_num};
                for i=2:size(current_loop, 1)
                    distance = getDist( ...
                        current_loop(i-1, 1), current_loop(i-1, 2), ...
                        current_loop(i, 1), current_loop(i, 2));
                    this.loopDists_km(loop_num) = this.loopDists_km(loop_num) + distance;
                end
            end

        end
    end
end

