classdef LoopPlans
    % LoopPlans Represents a base object for the amount of repetitions for
    % each of the three loops with a constant speed.
    
    properties(Access=private)
        cruiseSpeeds_vec_kmh;
        repeatsPerLoop_vec;
    end
    
    methods
        function this = LoopPlans(speeds_vec_kmh, num_total_loops, max_repeats_per_loop)
            % LoopPlan Construct an instance of this class.
            % Inputs:
            %   speeds_vec_kmh  : all possible speeds

            i = 0;
            while i < (max_repeats_per_loop+1)^num_total_loops
                this.repeatsPerLoop_vec(end+1, :) = this.getRow(i, (max_repeats_per_loop+1), num_total_loops);
                i = i + 1;
            end

            this.cruiseSpeeds_vec_kmh = speeds_vec_kmh;
        end

        % Getters and Setters
        function result = getSpeeds(this)
            result = this.cruiseSpeeds_vec_kmh;
        end
        function result = getRepeatsPerLoop(this)
            result = this.repeatsPerLoop_vec;
        end
    end

    methods(Access=private)
        function vec_in_base = getRow(~, decimal_num, base, num_digits)
            % Convert decimal number to new base as a
            % vector. Generates each row of repeatsPerLoop_vec by changing
            % the base of the decimal number to a new base described by the
            % max_repeats_per_loop

            % Inputs
            % ~             : LoopPlans object
            % decimal_num   : current row of repeatsPerLoop_vec
            % base          : max_repeats_per_loop or base to transform to
            % num_digits    : Length of output or number of loops

            % Outputs
            % vec_in_base: the next row in repeatsPerLoop_vec describing
            % one possible plan for the number of times to go around each
            % loop in the race.

            vec_in_base = zeros(1, num_digits);
            result = decimal_num;
            for i=1:num_digits
                vec_in_base(1, i) = mod(result, base);
                result=floor(result/base);
            end
        end
    end
end