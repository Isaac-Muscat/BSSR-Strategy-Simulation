function [vOpt] = getOpt(vMap)
%% Docstring 

% This function takes in a time, position, solcast irradiation matrix, and
% an initial battery charge, and return an optimal speed and route plan.

%% Define function inputs and outputs 

% T      :  starting time [datenum]
% P      :  starting position [csv]
% sCast  :  solcast irradiation matrix [csv] 
% inChar :  initial battery charge [kWh]
% vOpt   :  optimal speed for given input conditions [kPh]
%vPlan   :  optimal route plan for produced optimal speed [csv]

%% Define imported files and generated arrays 

% vR     :  chosen constant speed range [kPh]
% B      :  base route coordinates without the loops [csv]
% L1     :  loop 1 coordinates [csv]
% L2     :  loop 2 coordinates [csv]
% L3     :  loop 3 coordinates [csv]
% LN     :  number of times each loop is to be done if possible [csv]

%% Code 

vOpt = {};

for i = 1:6

    for j = 1:27 

        N = size(vMap{i,1}{1,2},1);

        dist = vMap{i,j}{1,2}(N,5); 
        tim = vMap{i,j}{1,2}(N,4); 
        charge = vMap{i,j}{1,2}(N,12);

        if min(vMap{i,j}{1,2}(:,12)) < 0

            vOpt{i,j} = {};

        else

            vOpt{i,j} = {vMap{i,j},[dist,tim,charge]};

        end


    end



end

end