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
    end
    
    methods(Access = public)
        function this = Route(baseRoute, checkpoints, loops, stages, carSimGen)
            this.BASE_ROUTE  = baseRoute;
            this.CHECKPOINTS = checkpoints;
            this.LOOPS       = loops;
            this.STAGES      = stages;
            this.CAR_SIM_GEN = carSimGen;
            
            Simulation = carSimGen.generateSims();
            Viable     = zeros(size(Simulation, 1), 1);
            Distance     = zeros(size(Simulation, 1), 1);
            this.sims  = table(Simulation, Viable, Distance);
        end
        
        function runSims(this)
            for i = 1:size(this.sims, 1)
                this.runSim(i);
            end
        end
    end
    
    methods(Access = private)
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
                    if time < this.CHECKPOINTS.CloseTimes(num_checkpoints)...
                    && time > this.CHECKPOINTS.OpenTimes(num_checkpoints)
                        dTime_h = 0.75; % Wait for 45 minutes
                        time = time + minutes(dTime_h);
                        sim.wait(pos2, dTime_h, time);
                    end

                % Reach Stage Stop
                elseif ismember(i, this.STAGES.Indices)
                    num_stages = num_stages + 1;
                    if time > this.STAGES.CloseTimes(num_stages)
                        return;
                    elseif num_stages < size(this.STAGES.OpenTimes, 1)
                        dTime_s = etime(datevec(this.STAGES.OpenTimes(num_stages + 1)), datevec(time));
                        dTime_h = dTime_s / 3.6e3;
                        time = time + minutes(dTime_h);
                        sim.wait(pos2, dTime_h, time);
                    end
                end

                % Reach Loop
                if ismember(i, this.LOOPS.Indices)
                    num_loops = num_loops + 1;
                    repeats = sim.loopPlan(num_loops);
                    if repeats == 0
                        continue;
                    end
                    
                    for j = 1:repeats
                        % Check if within loop times
                        if time <= this.LOOPS.CloseTimes
                            dTime_h = 0.25; % Wait for 15 minutes
                            time = time + minutes(dTime_h);
                            sim.wait(pos2, dTime_h, time);
                        else
                            return;
                        end

                        for k=2:this.LOOPS.Path{num_loops}
                            % Get positions
                            pos1 = this.BASE_ROUTE(k-1, :);
                            pos2 = this.BASE_ROUTE(k, :);

                            % Update the state of the car
                            [success, dTime_h] = sim.update(pos1, pos2, time);

                            % Exit if unsuccessful
                            if(success == 0)
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
                    end
                end
            end
            
            % The sim finished the race
            this.sims.Viable(simIndex) = 1;
            this.sims.Distance(simIndex) = sim.info.Distance_km(end);
        end
        
        function checkpoint(this, sim, num_checkpoints)
            
        end
        function loop(this, sim, num_loops)
            
        end
        function stageStop(this, sim, num_stages)
            
        end
        function night_stop(this, sim)
            
        end
    end
end

