classdef CarSimGenerator
    % Defines an object that generates "CarSim.m" objects with a dedicated
    % loop plan from "LoopPlanGenerator.m"
    
    properties(Access = private)
        DNI;
        DHI;
        DNI_SCALING;
        
        LOOP_PLAN_GEN;
    end
    properties(Access = public)
        DNI_ROW_LOOKUP; % Rows = (Distance from start, index in DNI table)
    end
    
    methods(Access = public)
        function this = CarSimGenerator(DNI_SCALING_CSV, DNI_CSV, DHI_CSV, loopPlanGen)
            % INPUTS: normal irradiance scaling factor csv, Normal and
            % diffuse irradiance csvs, and a loopPlanGenerator object for
            % creating loop plans to be inserted into each unique
            % simulation
            this.DNI = DNI_CSV;
            this.DHI = DHI_CSV;
            this.DNI_SCALING = DNI_SCALING_CSV;
            this.LOOP_PLAN_GEN = loopPlanGen;
            
            % Creates a matrix for fast indexing into the DNI and DHI csvs
            this.DNI_ROW_LOOKUP = [];
            start = this.DNI(2, 1:2);
            for i=2:size(this.DNI, 2)
                pos = this.DNI(i, 1:2);
                distance = getDist(start(1), start(2), pos(1), pos(2));
                this.DNI_ROW_LOOKUP(end+1, :) = [distance, i];
            end
            this.DNI_ROW_LOOKUP = sortrows(this.DNI_ROW_LOOKUP);
            
            c = CarSim.consts;
            c.DNI_SCALING = DNI_SCALING_CSV;
            c.DNI = DNI_CSV;
            c.DHI = DHI_CSV;
        end
        
        function sims = generateSims(this)
            % OUTPUT: vector of sims
            % Generates simulation objects with all possible plans.
            sims = [CarSim(0, [])];
            sims(end, :) = [];
            speeds = this.LOOP_PLAN_GEN.getSpeeds();
            plans = this.LOOP_PLAN_GEN.getPlans();
            for i = 1:size(speeds, 2)
                for j = 1:size(plans, 1)
                    sim = CarSim(speeds(i), plans(j, :));
                    sim.DNI_SCALING = this.DNI_SCALING;
                    sim.DNI = this.DNI;
                    sim.DHI = this.DHI;
                    sim.DNI_ROW_LOOKUP = this.DNI_ROW_LOOKUP;
                    sims(end+1, 1) = sim;
                end
            end
        end
    end
end

