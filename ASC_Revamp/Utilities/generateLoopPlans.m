
function loop_plans = generateLoopPlans(speeds_kmh, max_repeats_per_loop)
    plans = zeros(max_repeats_per_loop^3, 3);
    loop_plans = ones(size(speeds_kmh, 1)*max_repeats_per_loop^3,1);
    for i=1:3
        plans(i) = [1 1 1];
    end
    
    for speed=speeds_kmh
        
        loop_plans(1) = LoopPlan(speeds(1), [1, 1, 1]);
    end
    
end