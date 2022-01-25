classdef LoopPlanGenerator < handle
    % Defines an object for generating loop plans. Each loop plan has a
    % cruise speed and a vector containing the number of repeats for each
    % loop.
    
    properties(Access = private)
        SPEEDS_KMPH;
        MAX_REPEATS;
        NUM_LOOPS;
        PLANS;
    end
    
    methods(Access = public)
        function this = LoopPlanGenerator(speeds_kmph, num_loops, max_repeats)
            % INPUT: speed vector with, the number of loops of the race,
            % the maximum number of times to repeat a single loop.
            this.SPEEDS_KMPH = speeds_kmph;
            this.MAX_REPEATS = max_repeats;
            this.NUM_LOOPS   = num_loops;
            this.generatePlans();
        end
        
        function plans = getPlans(this)
           plans = this.PLANS; 
        end
        function speeds_kmph = getSpeeds(this)
           speeds_kmph = this.SPEEDS_KMPH; 
        end
    end
    
    methods(Access = private)
        function generatePlans(this)
            % Generates permutations of all possible cruise speeds and loop
            % repeats
            plans = zeros((this.MAX_REPEATS+1)^this.NUM_LOOPS, this.NUM_LOOPS);
            for i=0:((this.MAX_REPEATS+1)^this.NUM_LOOPS-1)
                plans(i+1, :) = this.getRow(i, (this.MAX_REPEATS+1), this.NUM_LOOPS);
            end
            this.PLANS = plans;
        end
        
        function vec_in_base = getRow(~, decimal_num, base, num_digits)
            % Helper function for generating permutations
            vec_in_base = zeros(1, num_digits);
            result = decimal_num;
            for i=1:num_digits
                vec_in_base(1, i) = mod(result, base);
                result=floor(result/base);
            end
        end
    end
end

