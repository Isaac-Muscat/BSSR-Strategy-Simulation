classdef CarSimGenerator
    
    properties(Access = private)
        DNI;
        DHI;
        DNI_SCALING;
        
        LOOP_PLAN_GEN;
    end
    
    methods(Access = public)
        function this = CarSimGenerator(DNI_SCALING_CSV, DNI_CSV, DHI_CSV, loopPlanGen)
            this.DNI = DNI_CSV;
            this.DHI = DHI_CSV;
            this.DNI_SCALING = DNI_SCALING_CSV;
            this.LOOP_PLAN_GEN = loopPlanGen;
            
            c = CarSim.consts;
            c.DNI_SCALING = DNI_SCALING_CSV;
            c.DNI = DNI_CSV;
            c.DHI = DHI_CSV;
        end
        
        function sims = generateSims(this)
            sims = [CarSim(0, [1, 1, 1])];
            sims(end, :) = [];
            speeds = this.LOOP_PLAN_GEN.getSpeeds();
            plans = this.LOOP_PLAN_GEN.getPlans();
            for i = 1:size(speeds, 2)
                for j = 1:size(plans, 1)
                    sim = CarSim(speeds(i), plans(j, :));
                    sim.DNI_SCALING = this.DNI_SCALING;
                    sim.DNI = this.DNI;
                    sim.DHI = this.DHI;
                    sims(end+1, 1) = sim;
                end
            end
        end
    end
end

