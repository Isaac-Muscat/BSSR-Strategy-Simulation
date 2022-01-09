function [vChar,lossVec] = getCharge(V,vPath,inChar,luTable,windSpeed,windDir,carDir)
%% Docstring

% This function takes in a generated path csv and returns the same path
% csv with an added column expressing the battery's SoC for each row. The
% battery SoC for each row is computed in different ways depending on the
% condition of the car (driving, charging, parked).

%% Define function inputs and outputs

% vPath   :  path car will take from getPath.m [csv]
% V       :  speed of car [kph]
% inChar  :  initial battery charge [kWh]
% luTable :  look up table [csv]
% vChar   :  vPath with added battery charge, array power, distance from start, Az and El, and bearing columns [csv]

% Initiate arrays

dist = zeros(size(vPath,1),1);
times = zeros(size(vPath,1),1);
az = zeros(size(vPath,1),1);
el = zeros(size(vPath,1),1);
bear = zeros(size(vPath,1),1);
power = zeros(size(vPath,1),1);
charge = zeros(size(vPath,1),1);

% Define time limits for Solcast tables

tS = datenum('3-Aug-2021 00:00:00');
wS = datenum('4-Aug-2021 00:00:00');
thS = datenum('5-Aug-2021 00:00:00');
fS = datenum('6-Aug-2021 00:00:00');
sS = datenum('7-Aug-2021 00:00:00');

% Define checkers for whether Solcast table for a particular day has been read

tCheck = 0;
wCheck = 0;
thCheck = 0;
fCheck  = 0;
sCheck = 0;

% Initiate vChar with vPath rows

vChar = vPath;

% Loop over vPath and calculate all parameters then store them in vChar

for i = 1:size(vPath,1)
    
    % Check which Solcast table to use
    
    solT = vPath(i,4);
    
    if nnz(solT >= tS & solT < wS)
        
        if tCheck == 0
            
            DNI = readmatrix('D:\Work\BSSR\ascMock\fa\ascMock\solcast\tuesdni.csv');
            DHI = readmatrix('D:\Work\BSSR\ascMock\fa\ascMock\solcast\tuesdhi.csv');
            
            tCheck = tCheck + 1;
            
        end
        
    elseif nnz(solT >= wS & solT < thS)
        
        if wCheck == 0
            
            DNI = readmatrix('D:\Work\BSSR\ascMock\fa\ascMock\solcast\weddni.csv');
            DHI = readmatrix('D:\Work\BSSR\ascMock\fa\ascMock\solcast\weddhi.csv');
            
            wCheck = wCheck + 1;
            
        end
        
    elseif nnz(solT >= thS & solT < fS)
        
        if thCheck == 0
            
            DNI = readmatrix('D:\Work\BSSR\ascMock\fa\ascMock\solcast\thursdni.csv');
            DHI = readmatrix('D:\Work\BSSR\ascMock\fa\ascMock\solcast\thursdhi.csv');
            
            thCheck = thCheck + 1;
            
        end
        
    elseif nnz(solT >= fS & solT < sS)
        
        if fCheck == 0
            
            DNI = readmatrix('D:\Work\BSSR\ascMock\fa\ascMock\solcast\fridni.csv');
            DHI = readmatrix('D:\Work\BSSR\ascMock\fa\ascMock\solcast\fridhi.csv');
            
            fCheck = fCheck + 1;
            
        end
        
    elseif solT >= sS
        
        if sCheck == 0
            
            DNI = readmatrix('D:\Work\BSSR\ascMock\fa\ascMock\solcast\satdni.csv');
            DHI = readmatrix('D:\Work\BSSR\ascMock\fa\ascMock\solcast\satdhi.csv');
            
            sCheck = sCheck + 1;
            
        end
        
    end
    
    % Check which row of vPath you are at and compute accordingly
    
    if i == 1  % (special case)
        
        % Get distance
        
        dist(i) = 0;
        
        vChar(i,5) = dist(i);
        
        % Get time
        
        times(i) = vPath(i,4) + datenum(hours(5)); % Adjust time to UTC (CT + 05:00)
        
        % Get bearing
        
        bear(i) = getBear(vPath(i,1),vPath(i,2),vPath(i+1,1),vPath(i+1,2));
        
        vChar(i,6) = bear(i);
        
        % Get Az and El
        
        [az(i),el(i)] = getAzEl(times(i),vPath(i,1),vPath(i,2),vPath(i,3));
        
        vChar(i,7) = az(i);
        
        vChar(i,8) = el(i);
        
        az(i) = az(i) + (180-bear(i));
        
        if az(i) < 0
            
            az(i) = 360 + az(i);
            
        end
        
        if az(i) > 360
            
            az(i) = az(i) - 360;
            
        end
        
        % Get power
        
        times(i) = times(i) - datenum(hours(5));
        
        for j = 3:size(DNI,2)
            
            locTime(j-2) = abs(etime(datevec(times(i)),datevec(DNI(1,j))));
            
        end
        
        [minTime,col] = min(locTime);
        
        col = col + 2;
        
        for j = 2:size(DNI,1)
            
            locDist(j-1) = getDist(vPath(i,1),vPath(i,2),DNI(j,1),DNI(j,2));
            
        end
        
        [minDist,row] = min(locDist);
        
        row = row + 1;
        
        power(i) = luTable(round(el(i)+1),round(az(i)+1))*DNI(row,col) + DHI(row,col)*4.114; % array area is 4.8 m^2
        
        vChar(i,9) = DNI(row,col);
        
        vChar(i,10) = DHI(row,col);
        
        vChar(i,11) = power(i);
        
        % Get charge
        
        charge(i) = inChar; % Initial batt charge in kWh
        
        if charge(i) > 5 
                    
            charge(i) = 5;
                    
        end
        
        gains(i) = 0; 
        losses(i) = 0;

        lossVec(i,:) = [0,0,0,0];

        vChar(i,12) = charge(i);
        vChar(i,13) = gains(i);
        vChar(i,14) = losses(i);
        
        
    else if i == size(vPath,1)  % (special case)
            
            % Get distance
            
            dist(i) = dist(i-1) + getDist(vPath(i-1,1),vPath(i-1,2),vPath(i,1),vPath(i,2));
            
            vChar(i,5) = dist(i);
            
            % Get time
            
            times(i) = vPath(i,4) + datenum(hours(5)); % Adjust time to UTC (CT + 05:00)
            
            % Get bearing
            
            bear(i) = bear(i-1);
            
            vChar(i,6) = bear(i);
            
            % Get Az and El
            
            [az(i),el(i)] = getAzEl(times(i),vPath(i,1),vPath(i,2),vPath(i,3));
            
            vChar(i,7) = az(i);
            
            vChar(i,8) = el(i);
            
            az(i) = az(i) + (180-bear(i));
            
            if az(i) < 0
                
                az(i) = 360 + az(i);
                
            end
            
            if az(i) > 360
                
                az(i) = az(i) - 360;
                
            end
            
            % Get power
            
            times(i) = times(i) - datenum(hours(5));
            
            for j = 3:size(DNI,2)
                
                locTime(j-2) = abs(etime(datevec(times(i)),datevec(DNI(1,j))));
                
            end
            
            [minTime,col] = min(locTime);
            
            col = col + 2;
            
            for j = 2:size(DNI,1)
                
                locDist(j-1) = getDist(vPath(i,1),vPath(i,2),DNI(j,1),DNI(j,2));
                
            end
            
            [minDist,row] = min(locDist);
            
            row = row + 1;
            
            power(i) = luTable(round(el(i)+1),round(az(i)+1))*DNI(row,col) + DHI(row,col)*4.114*0.23; % array area is 4.8 m^2
            
            vChar(i,9) = DNI(row,col);
            
            vChar(i,10) = DHI(row,col);
            
            vChar(i,11) = power(i);
            
            % Get charge
            
            delT = etime(datevec(vPath(i,4)),datevec(vPath(i-1,4)));
            
            [losses(i),lossVec(i,:)] = getLoss(V,dist(i)-dist(i-1),vPath(i,3)-vPath(i-1,3),delT,60,windSpeed(i),windDir(i),carDir(i));
            
            gains(i) = (power(i-1)*delT)/3.6e6;

            %Conditionals for battery charge
            if losses(i) < 0 

                %Add gained energy to gains(i)
                gains(i) = gains(i) + 0.97*(abs(losses(i)));

                %Update battery charge 
                charge(i) = charge(i-1) + (gains(i)*0.98);

            elseif losses(i) > 0.97*gains(i) 
    
                %Define energy needed from battery in [kWh]
                energyNeeded = losses(i)-(0.97*(gains(i)));
    
                %Update battery charge
                charge(i) = charge(i-1) - (energyNeeded/0.98);
    
            elseif losses(i) == 0.97*gains(i)
    
                %Update battery charge
                charge(i) = charge(i-1);
    
            elseif losses(i) < 0.97*gains(i)
    
                %Define fraction of solarIn energy that goes to motor
                frac = losses(i)/(0.97*(gains(i)));
    
                %Define energy to go to battery
                energytoBatt = gains(i)*(1-frac);
    
                %Update battery charge
                charge(i) = charge(i-1) + (energytoBatt*0.98);
    
            end           
            
            if charge(i) > 5 
                    
                charge(i) = 5;
                    
            end
            
            vChar(i,12) = charge(i);
            vChar(i,13) = gains(i);
            vChar(i,14) = losses(i);
            
        else % Everywhere else
            
            delDist = getDist(vPath(i-1,1),vPath(i-1,2),vPath(i,1),vPath(i,2)); % Dist covered from previous step
            
            if delDist == 0 % Car is stationary and charging
                
                % Get distance
                
                dist(i) = dist(i-1) + getDist(vPath(i-1,1),vPath(i-1,2),vPath(i,1),vPath(i,2));
                
                vChar(i,5) = dist(i);
                
                % Get time
                
                times(i) = vPath(i,4) + datenum(hours(5)); % Adjust time to UTC (CT + 05:00)
                
                % Get bearing
                
                bear(i) = getBear(vPath(i,1),vPath(i,2),vPath(i+1,1),vPath(i+1,2));
                
                vChar(i,6) = bear(i);
                
                % Get Az and El
                
                [az(i),el(i)] = getAzEl(times(i),vPath(i,1),vPath(i,2),vPath(i,3));
                
                vChar(i,7) = az(i);
                
                vChar(i,8) = el(i);
                
                az(i) = az(i) + (180-bear(i));
                
                if az(i) < 0
                    
                    az(i) = 360 + az(i);
                    
                end
                
                if az(i) > 360
                    
                    az(i) = az(i) - 360;
                    
                end
                
                % Step in time in increments to compute total energy gained

                k = 1; % Counter for temptime abd tempenergy
                
                temptime(k) = times(i-1);
                
                times(i) = times(i) - datenum(hours(5));
                
                tempenergy(k) = 0;
                
                while temptime(k) < times(i)
                    
                    % Get Az and El
                    
                    [tempaz,tempel] = getAzEl((temptime(k)+datenum(hours(5))),vPath(i,1),vPath(i,2),vPath(i,3));
                    
                    % Correct el for charge stand angle
                    
                    if tempel < 15
                        
                        tempel = tempel + 75 + 1;
                        
                    else
                        
                        tempel = 91;
                        
                    end
                    
                    % Get power
                    
                    for j = 3:size(DNI,2)
                        
                        locTime(j-2) = abs(etime(datevec(temptime(k)),datevec(DNI(1,j))));
                        
                    end
                    
                    [minTime,col] = min(locTime);
                    
                    col = col + 2;
                    
                    for j = 2:size(DNI,1)
                        
                        locDist(j-1) = getDist(vPath(i,1),vPath(i,2),DNI(j,1),DNI(j,2));
                        
                    end
                    
                    [minDist,row] = min(locDist);
                    
                    row = row + 1;
                    
                    temppower = luTable(round(tempel),91)*DNI(row,col) + DHI(row,col)*4.114*0.23; % array area is 4.8 m^2
                    
                    tempenergy(k+1) = tempenergy(k) + ((temppower*60)/3.6e6);
                    
                    temptime(k+1) = temptime(k) + datenum(minutes(1));

                    k = k+1; % Update counter 
                    
                end
                
                % Get power
                
                for j = 3:size(DNI,2)
                    
                    locTime(j-2) = abs(etime(datevec(times(i)),datevec(DNI(1,j))));
                    
                end
                
                [minTime,col] = min(locTime);
                
                col = col + 2;
                
                for j = 2:size(DNI,1)
                    
                    locDist(j-1) = getDist(vPath(i,1),vPath(i,2),DNI(j,1),DNI(j,2));
                    
                end
                
                [minDist,row] = min(locDist);
                
                row = row + 1;
                
                power(i) = luTable(round(el(i)+1),round(az(i)+1))*DNI(row,col) + DHI(row,col)*4.114*0.23; % array area is 4.8 m^2
                
                vChar(i,9) = DNI(row,col);
                
                vChar(i,10) = DHI(row,col);
                
                vChar(i,11) = power(i);
                
                % Get charge
                
                delT = etime(datevec(vPath(i,4)),datevec(vPath(i-1,4)));
                
                losses(i) = (20*delT)/3.6e6; % Constant electrical loss

                lossVec(i,:) = [0,0,losses(i),0];
                
                gains(i) = tempenergy(k);

                %Conditionals for battery charge
                if losses(i) < 0 

                    %Add gained energy to gains(i)
                    gains(i) = gains(i) + 0.97*(abs(losses(i)));

                    %Update battery charge 
                    charge(i) = charge(i-1) + (gains(i)*0.98);

                elseif losses(i) > 0.97*gains(i) 
    
                    %Define energy needed from battery in [kWh]
                    energyNeeded = losses(i)-(0.97*(gains(i)));
    
                    %Update battery charge
                    charge(i) = charge(i-1) - (energyNeeded/0.98);
    
                elseif losses(i) == 0.97*gains(i)
    
                    %Update battery charge
                    charge(i) = charge(i-1);
    
                elseif losses(i) < 0.97*gains(i)
    
                    %Define fraction of solarIn energy that goes to motor
                    frac = losses(i)/(0.97*(gains(i)));
    
                    %Define energy to go to battery
                    energytoBatt = gains(i)*(1-frac);
    
                    %Update battery charge
                    charge(i) = charge(i-1) + (energytoBatt*0.98);
    
                end           
            
                if charge(i) > 5 
                    
                    charge(i) = 5;
                    
                end
                
                vChar(i,12) = charge(i);
                vChar(i,13) = gains(i);
                vChar(i,14) = losses(i);
                
            else % Car is moving
                
                % Get distance
                
                dist(i) = dist(i-1) + getDist(vPath(i-1,1),vPath(i-1,2),vPath(i,1),vPath(i,2));
                
                vChar(i,5) = dist(i);
                
                % Get time
                
                times(i) = vPath(i,4) + datenum(hours(5)); % Adjust time to UTC (CT + 05:00)
                
                % Get bearing
                
                bear(i) = getBear(vPath(i,1),vPath(i,2),vPath(i+1,1),vPath(i+1,2));
                
                vChar(i,6) = bear(i);
                
                % Get Az and El
                
                [az(i),el(i)] = getAzEl(times(i),vPath(i,1),vPath(i,2),vPath(i,3));
                
                vChar(i,7) = az(i);
                
                vChar(i,8) = el(i);
                
                az(i) = az(i) + (180-bear(i));
                
                if az(i) < 0
                    
                    az(i) = 360 + az(i);
                    
                end
                
                if az(i) > 360
                    
                    az(i) = az(i) - 360;
                    
                end
                
                % Get power
                
                times(i) = times(i) - datenum(hours(5));
                
                for j = 3:size(DNI,2)
                    
                    locTime(j-2) = abs(etime(datevec(times(i)),datevec(DNI(1,j))));
                    
                end
                
                [minTime,col] = min(locTime);
                
                col = col + 2;
                
                for j = 2:size(DNI,1)
                    
                    locDist(j-1) = getDist(vPath(i,1),vPath(i,2),DNI(j,1),DNI(j,2));
                    
                end
                
                [minDist,row] = min(locDist);
                
                row = row + 1;
                
                power(i) = luTable(round(el(i)+1),round(az(i)+1))*DNI(row,col) + DHI(row,col)*4.114*0.23; % array area is 4.8 m^2
                
                vChar(i,9) = DNI(row,col);
                
                vChar(i,10) = DHI(row,col);
                
                vChar(i,11) = power(i);
                
                % Get charge
                
                delT = etime(datevec(vPath(i,4)),datevec(vPath(i-1,4)));
                
                [losses(i),lossVec(i,:)] = getLoss(V,dist(i)-dist(i-1),vPath(i,3)-vPath(i-1,3),delT,60,windSpeed(i),windDir(i),carDir(i));
                
                gains(i) = (power(i-1)*delT)/3.6e6;
                
                %Conditionals for battery charge
                if losses(i) < 0 

                    %Add gained energy to gains(i)
                    gains(i) = gains(i) + 0.97*(abs(losses(i)));

                    %Update battery charge 
                    charge(i) = charge(i-1) + (gains(i)*0.98);
                
                elseif losses(i) > 0.97*gains(i) 
    
                    %Define energy needed from battery in [kWh]
                    energyNeeded = losses(i)-(0.97*(gains(i)));
    
                    %Update battery charge
                    charge(i) = charge(i-1) - (energyNeeded/0.98);
    
                elseif losses(i) == 0.97*gains(i)
    
                    %Update battery charge
                    charge(i) = charge(i-1);
    
                elseif losses(i) < 0.97*gains(i)
    
                    %Define fraction of gains energy that goes to motor
                    frac = losses(i)/(0.97*(gains(i)));
    
                    %Define energy to go to battery
                    energytoBatt = gains(i)*(1-frac);
    
                    %Update battery charge
                    charge(i) = charge(i-1) + (energytoBatt*0.98);
    
                end           
            
                if charge(i) > 5 
                    
                    charge(i) = 5;
                    
                end
                
                vChar(i,12) = charge(i);
                vChar(i,13) = gains(i);
                vChar(i,14) = losses(i);
                
            end
            
        end
        
        
        
    end
    
end
