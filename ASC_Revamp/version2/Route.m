classdef Route < handle
    properties(Access = private)
        CHECKPOINTS;
        LOOPS;
        STAGES;
        BASE_ROUTE;
        
        CAR_SIM_GEN;
    end
    
    properties(Access = public)
        sims;
        
        STOP_INDEXES;
        STOP_DISTANCES;
        LOOP_DISTANCES;
    end
    
    methods(Access = public)
        function this = Route(baseRoute, checkpoints, loops, stages, carSimGen)
            this.BASE_ROUTE  = baseRoute;
            this.CHECKPOINTS = checkpoints;
            this.LOOPS       = loops;
            this.STAGES      = stages;
            this.CAR_SIM_GEN = carSimGen;
            
            Simulation = carSimGen.generateSims();
            Viable     = strings(size(Simulation, 1), 1);
            Distance   = zeros(size(Simulation, 1), 1);
            this.sims  = table(Simulation, Viable, Distance);
        end
        
        function runSims(this)
            for i = 1:height(this.sims)
                this.runSim(i);
            end
        end
        
        function cullLateSims(this)
            this.calculateDistances();
            late_sims = [];

            for i = 1:height(this.sims)
                if this.isSimTimely(i) == 0
                    late_sims(end + 1) = i;
                end
            end
            this.sims(late_sims, :) = [];
            
        end
    end
    
    methods(Access = public)
        function calculateDistances(this)
            this.STOP_INDEXES = sort([this.STAGES.Indices; this.CHECKPOINTS.Indices]);
            this.STOP_DISTANCES = [];
            this.LOOP_DISTANCES = [];
            current_distance = 0;
            
            for i=2:size(this.BASE_ROUTE, 1)
                pos1 = this.BASE_ROUTE(i-1, :);
                pos2 = this.BASE_ROUTE(i, :);
                current_distance = current_distance + getDist(pos1(1), pos1(2), pos2(1), pos2(2));
                
                if ismember(i, this.STOP_INDEXES)
                    this.STOP_DISTANCES(end+1) = current_distance;
                    current_distance = 0;
                end
            end
            for loop_index = 1:height(this.LOOPS)
                current_loop = this.LOOPS.Path{loop_index};
                this.LOOP_DISTANCES(loop_index) = 0;
                for i = 2:size(current_loop, 1)
                    distance = getDist( ...
                        current_loop(i-1, 1), current_loop(i-1, 2), ...
                        current_loop(i, 1), current_loop(i, 2));
                    this.LOOP_DISTANCES(loop_index) = this.LOOP_DISTANCES(loop_index) + distance;
                end
            end
        end
        
        function success = isSimTimely(this, simIndex)
            sim             = this.sims.Simulation(simIndex);
            speed           = sim.getSpeed();
            loop_plan       = sim.getLoopPlan();
            time            = this.STAGES.OpenTimes(1);
            num_loops       = 0;
            num_checkpoints = 0;
            num_stages      = 0;
            
            % Move through base route
            for i=1:size(this.STOP_INDEXES, 1)
                route_index = this.STOP_INDEXES(i);
                dDist_km = this.STOP_DISTANCES(i);
                time = time + hours(dDist_km / speed);

                % Night stop
                if hour(time) >= 18
                    dTime_h = 15;
                    time = time + hours(dTime_h);
                end
                
                % Reach Checkpoint
                if ismember(route_index, this.CHECKPOINTS.Indices)
                    num_checkpoints = num_checkpoints + 1;
                    if time > this.CHECKPOINTS.CloseTimes(num_checkpoints)
                        success = 0;
                        return;
                    elseif time > this.CHECKPOINTS.OpenTimes(num_checkpoints)
                        dTime_h = 0.75; % Wait for 45 minutes
                        time = time + hours(dTime_h);
                    end
                end
                
                % Reach Loop
                if ismember(route_index, this.LOOPS.Indices)
                    num_loops = num_loops + 1;
                    repeats = loop_plan(num_loops);
                    
                    if repeats > 0
                        for j = 1:repeats
                            % Wait for 15 minutes and complete loop <repeats> times
                            dDist_km = (0.25 + this.LOOP_DISTANCES(num_loops)) * repeats;
                            time = time + hours(dDist_km / speed);
                            
                            % Night stop
                            if hour(time) >= 18
                                dTime_h = 15;
                                time = time + hours(dTime_h);
                            end
                            
                            % Check if within loop times
                            if time > this.LOOPS.CloseTimes
                                success = 0;
                                return;
                            end
                        end
                    end
                end

                % Reach Stage Stop
                if ismember(route_index, this.STAGES.Indices)
                    num_stages = num_stages + 1;
                    if time > this.STAGES.CloseTimes(num_stages)
                        success = 0;
                        return;
                    elseif num_stages < height(this.STAGES)
                        dTime_s = etime(datevec(this.STAGES.OpenTimes(num_stages + 1)), datevec(time));
                        dTime_h = dTime_s / 3.6e3;
                        time = time + hours(dTime_h);
                    end
                end
            end
            
            success = 1;
        end
        
        function runSim(this, simIndex)
            sim             = this.sims.Simulation(simIndex);
            time            = this.STAGES.OpenTimes(1);
            num_loops       = 0;
            num_checkpoints = 0;
            num_stages      = 0;
            
            % Move through base route
            for i=2:size(this.BASE_ROUTE, 1)
                % Get positions
                pos1 = this.BASE_ROUTE(i-1, :);
                pos2 = this.BASE_ROUTE(i, :);
                
                % Update the state of the car
                [success, dTime_h] = sim.update(pos1, pos2, time);
                
                % Exit if unsuccessful
                if(success == 0)
                    this.sims.Viable(simIndex) = "Insufficient energy";
                    return;
                end
                
                % Increment time
                time = time + hours(dTime_h);

                % Night stop
                if hour(time) >= 18
                    dTime_h = 15;
                    time = time + hours(dTime_h);
                    sim.wait(pos2, dTime_h, time);
                end

                % Reach Checkpoint
                if ismember(i, this.CHECKPOINTS.Indices)
                    num_checkpoints = num_checkpoints + 1;
                    if time > this.CHECKPOINTS.CloseTimes(num_checkpoints)
                        this.sims.Viable(simIndex) = "Missed checkpoint";
                        return;
                    elseif time > this.CHECKPOINTS.OpenTimes(num_checkpoints)
                        dTime_h = 0.75; % Wait for 45 minutes
                        time = time + hours(dTime_h);
                        sim.wait(pos2, dTime_h, time);
                    end
                end
                
                % Reach Loop
                if ismember(i, this.LOOPS.Indices)
                    num_loops = num_loops + 1;
                    repeats = sim.loopPlan(num_loops);
                    
                    if repeats > 0
                        for j = 1:repeats
                            % Check if within loop times
                            if time > this.LOOPS.CloseTimes
                                this.sims.Viable(simIndex) = "Missed loop";
                                return;
                            end
                            
                            loop_path = this.LOOPS.Path{num_loops};
                            for k=2:size(loop_path, 1)
                                % Get positions
                                pos1 = loop_path(k-1, :);
                                pos2 = loop_path(k, :);

                                % Update the state of the car
                                [success, dTime_h] = sim.update(pos1, pos2, time);

                                % Exit if unsuccessful
                                if(success == 0)
                                    this.sims.Viable(simIndex) = "Insufficient energy";
                                    return;
                                end

                                % Increment time
                                time = time + hours(dTime_h);

                                % Night stop
                                if hour(time) >= 18
                                    dTime_h = 15;
                                    time = time + hours(dTime_h);
                                    sim.wait(pos2, dTime_h, time);
                                end
                            end
                            
                            dTime_h = 0.25; % Wait for 15 minutes
                            time = time + hours(dTime_h);
                            sim.wait(pos2, dTime_h, time);
                        end
                    end
                end

                % Reach Stage Stop
                if ismember(i, this.STAGES.Indices)
                    num_stages = num_stages + 1;
                    if time > this.STAGES.CloseTimes(num_stages)
                        this.sims.Viable(simIndex) = "Missed stage";
                        return;
                    elseif num_stages < height(this.STAGES)
                        dTime_s = etime(datevec(this.STAGES.OpenTimes(num_stages + 1)), datevec(time));
                        dTime_h = dTime_s / 3.6e3;
                        time = time + hours(dTime_h);
                        sim.wait(pos2, dTime_h, time);
                    end
                end
            end
            
            % The sim finished the race
            this.sims.Viable(simIndex) = "Viable";
            this.sims.Distance(simIndex) = sim.info.Distance_km(end);
        end
    end
end

