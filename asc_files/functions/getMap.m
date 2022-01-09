function [vMap] = getMap(B,L1,L2,L3,T,P,inChar,luTable)
%% Docstring 

% This function takes in a speed range, base route, loops ,number of 
% times each loop will be done (if possible), starting time, starting 
% position, and returns a single array containing the path of the car in 
% space and time along the route for the selected speed and race plan. 

%% Define function inputs and outputs 

% V      :  chosen constant speed [kPh]
% B      :  base route coordinates without the loops [csv]
% L1     :  loop 1 coordinates [csv]
% L2     :  loop 2 coordinates [csv]
% L3     :  loop 3 coordinates [csv]
% LN     :  number of times each loop is to be done if possible [csv]
% T      :  starting time [datenum]
% P      :  starting position [csv]
% vMap   :  map of car paths for chosen inputs [csv] 

%% Code 

plans = {[0,0,0];[0,0,1];[0,0,2];[0,1,0];[0,1,1];[0,1,2];[0,2,0];[0,2,1];[0,2,2];[1,0,0];[1,0,1];[1,0,2];[1,1,0];[1,1,1];[1,1,2];[1,2,0];[1,2,1];[1,2,2];[2,0,0];[2,0,1];[2,0,2];[2,1,0];[2,1,1];[2,1,2];[2,2,0];[2,2,1];[2,2,2]};
speeds = {60;62;64;68;70;72};

for i = 1:27

    L1N = plans{i}(1);
    L2N = plans{i}(2);
    L3N = plans{i}(3);

    parfor j = 1:6 

        V = speeds{j};

        [sucL,vPath] = getPath(V,B,L1,L2,L3,L1N,L2N,L3N,T,P); 
        [vChar] = getCharge(V,vPath,inChar,luTable);
        vMap{j,i} = {sucL,vChar};

    end

end


end

