 function [sucL,vPath]  = getPath(V,B,L1,L2,L3,L1N,L2N,L3N,T,P)

% Docstring

% This function takes in a selected speed, base route, loops ,number of
% times each loop will be done (if possible), starting time, starting
% position, and returns a single array containing the path of the car in
% space and time along the route for the selectesd speed.

% Define function inputs and outputs

% V      :  chosen constant speed for the race [kPh]
% B      :  base route coordinates without the loops [csv]
% L1     :  loop 1 coordinates [csv]
% L2     :  loop 2 coordinates [csv]
% L3     :  loop 3 coordinates [csv]
% L1N    :  number of times loop 1 is to be done if possible [int]
% L2N    :  number of times loop 2 is to be done if possible [int]
% L3N    :  number of times loop 3 is to be done if possible [int]
% T      :  starting time [datenum]
% P      :  starting position [indx]
% vPath  :  path car will take for chosen inputs [csv]
% sucL   :  number of times each loop was completed successfuly [mat] 

% Code

% Define checkpoint indices

% checkInd = [2610,5745,8099];

checkInd = [2610,5745];

% Define stage stop indices

% stopInd = [3907,12954,16207];

stopInd = [16207]; % Second last index in the sheet

% Define loop indices

loopInd = [3907,8099,12954];

% Define critical times for checkpoints, stage stops, and base legs

% Stage 1

S1O = datenum('3-Aug-2021 09:00:00'); % Stage 1 open time
S1C = datenum('3-Aug-2021 18:00:00'); % Stage 1 close time (index 3907)

CP1O = datenum('3-Aug-2021 12:00:00'); % Check point 1 open time (index 2610)
CP1R = datenum('3-Aug-2021 14:00:00'); % Check point 1 drive resume time
CP1C = datenum('3-Aug-2021 14:45:00'); % Check point 1 close time

L1C  = datenum('3-Aug-2021 18:00:00'); % Loop 1 close time

% Stage 2

S2O = datenum('4-Aug-2021 09:00:00'); % Stage 2 open time
S2C = datenum('6-Aug-2021 18:00:00'); % Stage 2 close time (index 12954)

CP2O = datenum('4-Aug-2021 11:45:00'); % Check point 2 open time (index 5745)
CP2R = datenum('4-Aug-2021 15:45:00'); % Check point 2 drive resume time
CP2C = datenum('4-Aug-2021 16:30:00'); % Check point 2 close time

CP3O = datenum('4-Aug-2021 16:45:00'); % Check point 3 open time (index 8099)
CP3R = datenum('5-Aug-2021 15:30:00'); % Check point 3 drive resume time
CP3C = datenum('5-Aug-2021 16:35:00'); % Check point 3 close time

L2C  = datenum('5-Aug-2021 15:15:00'); % Loop 2 close time
L3C  = datenum('6-Aug-2021 19:00:00'); % Loop 3 close time

% Stage 3

S3O = datenum('7-Aug-2021 10:00:00'); % Stage 3 open time
S3C = datenum('7-Aug-2021 16:00:00'); % Stage 3 close time (index 16207)

% Loop over base route

% Define base leg for loop variables

N = size(B,1);               % Size of base route csv
tT(1) = T;                   % Temporary time variable
c = 1;                       % Temporary row counter for vPath
vPath(1,[1:3]) = B(P,:);     % vPath array initiation
vPath(1,4) = tT(1);          % vPath array initiation

% Define loops for loop variables

lOpen = [S1O,CP3O,S2O];      % Open times for each loop location
lClose = [S1C,CP3C,S2C];     % Close times for each checkpoint with loops location
llClose = [L1C,L2C,L3C];     % Close time for each loop 
lNum = [L1N,L2N,L3N];        % Number of times each of the loops is to be done
lSheet = {L1,L2,L3};         % Route sheets for each of the loops
lResume = [S2O,CP3R,S3O];    % Driving resumption time for each loop location
lStop = [S1C,S2C,S2C];       % Time at which car must stop where its at because of stage finish
sucL = [0,0,0];

% Define checkpoints variables

cOpen = [CP1O,CP2O];      % Open times for each checkpoint location
cResume = [CP1R,CP2R];    % Driving resumption time for each checkpoint location
cClose = [CP1C,CP2C];     % Close times for each checkpoint location

% Define stage stop variables

sOpen = [S3O];      % Open times for each stage stop location
sClose = [S3C];     % Close times for each stage stop location

for i = P:N-1
    
    % Check if car is along a stage before its opening time
    
    if nnz(i >= 1 & i < 3907)
        
        if tT(c) < S1O
            
            % Update counter
            
            c = c + 1;
            
            % Wait until stage open time
            
            tT(c) = S1O;
            
            % Update vPath array
            
            vPath(c,[1:3]) = B(i,:);
            vPath(c,4) = tT(c);
            
        end
        
    elseif nnz(i > 3907 & i < 12954)
        
        if tT(c) < S2O
            
            % Update counter
            
            c = c + 1;
            
            % Wait until stage open time
            
            tT(c) =  S2O;
            
            % Update vPath array
            
            vPath(c,[1:3]) = B(i,:);
            vPath(c,4) = tT(c);
            
        end
        
    elseif nnz(i > 12954 & i <= 16207)
        
        if tT(c) < S3O
            
            % Update counter
            
            c = c + 1;
            
            % Wait until stage open time
            
            tT(c) =  S3O;
            
            % Update vPath array
            
            vPath(c,[1:3]) = B(i,:);
            vPath(c,4) = tT(c);
            
        end
        
    end
    
    dVec = datevec(tT(c)); % Define datevec for current time
    
    if ismember(i,loopInd)   % Check if car is at a checkpoint or stage finish with a loop
        
        % Check which loop location the car is at
        
        lLoc = find(loopInd==i);
        
        % Check if arrived within checkpoint or stage stop open and close times
        
        if nnz(tT(c) >= lOpen(lLoc) & tT(c) < lClose(lLoc))
            
            % Update counter
            
            c = c + 1;
            
            % Wait 45 minutes at stage stop or checkpoint
            
            tT(c) =  tT(c-1) + datenum(minutes(45));
            
            % Update vPath array
            
            vPath(c,[1:3]) = B(i,:);
            vPath(c,4) = tT(c);
            
            % Define temporary loop path array
            
            lPath  = [];
            
            if lNum(lLoc) > 0  % Only do loop if number of times specified is > 0
                
                % Define counter of number of times loop is successfully completed
                
                sucL(lLoc) = 0;
                
                % Check if car is within loop 1 close time
                
                if tT(c) < llClose(lLoc)
                    
                    % Loop over loop 1 csv L1N times and update vPath
                    
                    for ln = 1:lNum(lLoc)
                        
                        % Define temporary loop row counter
                        
                        tc = 0;
                        
                        % Define temporary loop time variable
                        
                        lT(1) = tT(c);
                        
                        for l = 1:size(lSheet{lLoc},1)-1
                            
                            % Update temporary loop row counter
                            
                            tc = tc + 1;
                            
                            % Update loop path array
                            
                            lPath(tc,[1:3]) = lSheet{lLoc}(l,:);
                            lPath(tc,4) = lT(tc);
                            
                            % Find distance to next location in km
                            
                            nDist = getDist(lSheet{lLoc}(l,1),lSheet{lLoc}(l,2),lSheet{lLoc}(l+1,1),lSheet{lLoc}(l+1,2));
                            
                            % Find arrival time at next location
                            
                            lT(tc+1) = lT(tc) + datenum(hours(nDist/V));
                            
                            if l == size(lSheet{lLoc},1)-1 % Check if you are at last index
                                
                                % Update temporary loop row counter
                                
                                tc = tc + 1;
                                
                                % Update loop path array
                                
                                lPath(tc,[1:3]) = lSheet{lLoc}(l+1,:);
                                lPath(tc,4) = lT(tc);
                                
                            end
                            
                        end
                        
                        if lT(tc) < llClose(lLoc)
                            
                            % Update number of times the loop has been successfuly done
                            
                            sucL(lLoc) = sucL(lLoc) + 1;
                            
                            % Append new lPath into vPath
                            
                            vPath = [vPath;lPath];
                            
                            % Update global row counter and time
                            
                            c = c + size(lPath,1);
                            
                            % Add 15 mintes to end of vPath if loop is successfuly done
                            
                            addHold = vPath(end,:);
                            
                            addHold(1,4) = addHold(1,4) + datenum(minutes(15));
                            
                            vPath = [vPath;addHold];
                            
                            c = c + 1;
                            
                            tT(c) = addHold(1,4);
                            
                        else % Stop doing loops if you are out of time
                            
                            break
                            
                        end
                        
                    end
                    
                end
                
            end
            
            dVec = datevec(tT(c)); % Define datevec for current time
            
            if tT(c) < lResume(lLoc)  % Stay overnight at stage stops or until drive resume time for checkpoints and charge
                
                % Update row counter
                
                c = c + 1;

                % Update tT(c)

                tT(c) = lResume(lLoc);
                
                % Update vPath with charge duartion
                
                vPath(c,[1:3]) = B(i,:);
                
                vPath(c,4) = tT(c); % Charge up to nearest drive resumption time
                
                % Update row counter again
                
                c = c + 1;
                
                % Find distance to next location
                
                nDist = getDist(B(i,1),B(i,2),B(i+1,1),B(i+1,2));

                % Update tT(c)

                tT(c) = tT(c-1)+datenum(hours(nDist/V));
                
                % Update vPath array
                
                vPath(c,[1:3]) = B(i+1,:);                              % Store Lat, Long, and Alt
                vPath(c,4) = tT(c);           % Store Time
                
                
            elseif dVec(4) >= 18 % Check if it is past 6 PM
                
                % Adjust time and date to tomorrow                
                
                tommNumVec = tT(c) + datenum(days(1));
                tommNumVec = datevec(tommNumVec);
                tommNumVec(4) = 9; % 9 AM start time
                tommNumVec = datenum(tommNumVec);
                
                % Update row counter
                
                c = c + 1;

                % Update tT(c)

                tT(c) = datenum(tommNumVec);
                
                % Update vPath array
                
                vPath(c,[1:3]) = B(i,:);
                vPath(c,4) = tT(c);
                
                % Update row counter again
                
                c = c + 1;
                
                % Find distance to next location
                
                nDist = getDist(B(i,1),B(i,2),B(i+1,1),B(i+1,2));

                % Update tT(c)

                tT(c) = tT(c-1)+datenum(hours(nDist/V));
                
                % Update vPath array
                
                vPath(c,[1:3]) = B(i+1,:);                              % Store Lat, Long, and Alt
                vPath(c,4) = tT(c);           % Store Time
                
            else % Move on along the race
                
                % Update row counter again
                
                c = c + 1;
                
                % Find distance to next location
                
                nDist = getDist(B(i,1),B(i,2),B(i+1,1),B(i+1,2));

                % Update tT(c)

                tT(c) = tT(c-1)+datenum(hours(nDist/V));
                
                % Update vPath array
                
                vPath(c,[1:3]) = B(i+1,:);                              % Store Lat, Long, and Alt
                vPath(c,4) = tT(c);           % Store Time
                
            end
            
        else % Car arrived at checkpoint or stage stop outside opening hours
            
            dVec = datevec(tT(c)); % Define datevec for current time
            
            if dVec(4) >= 18 % Check if it is past 6 PM
                
                % Adjust time and date to tomorrow
                
                tommNumVec = tT(c) + datenum(days(1));
                tommNumVec = datevec(tommNumVec);
                tommNumVec(4) = 9; % 9 AM start time
                tommNumVec = datenum(tommNumVec);
                
                % Update row counter
                
                c = c + 1;

                % Update tT(c)

                tT(c) = datenum(tommNumVec);
                
                % Update vPath array
                
                vPath(c,[1:3]) = B(i,:);
                vPath(c,4) = tT(c);
                
                % Update row counter again
                
                c = c + 1;
                
                % Find distance to next location
                
                nDist = getDist(B(i,1),B(i,2),B(i+1,1),B(i+1,2));

                % Update tT(c)

                tT(c) = tT(c-1)+datenum(hours(nDist/V));
                
                % Update vPath array
                
                vPath(c,[1:3]) = B(i+1,:);                              % Store Lat, Long, and Alt
                vPath(c,4) = tT(c);           % Store Time
                
            else
                
                % Update row counter
                
                c = c + 1;
                
                % Find distance to next location
                
                nDist = getDist(B(i,1),B(i,2),B(i+1,1),B(i+1,2));

                % Update tT(c)

                tT(c) = tT(c-1)+datenum(hours(nDist/V));
                
                % Update vPath array
                
                vPath(c,[1:3]) = B(i+1,:);                              % Store Lat, Long, and Alt
                vPath(c,4) = tT(c);       % Store Time
                
            end
            
        end
        
        
    elseif ismember(i,checkInd)  % Check if car is at a regular checkpoint
        
        % Check which checkpopint location the car is at
        
        cLoc = find(checkInd==i);
        
        dVec = datevec(tT(c)); % Define datevec for current time
        
        % Check if arrived within checkpoint open and close times
        
        if nnz(tT(c) >= cOpen(cLoc) & tT(c) < cClose(cLoc))
            
            % Update counter
            
            c = c + 1;
            
            % Wait 45 minutes at stage stop or checkpoint
            
            tT(c) =  tT(c-1) + datenum(minutes(45));
            
            % Update vPath array
            
            vPath(c,[1:3]) = B(i,:);
            vPath(c,4) = tT(c);
            
            dVec = datevec(tT(c)); % Define datevec for current time
            
            if tT(c) < cResume(cLoc)  % Stay until checkpoint drive resume time and charge
                
                % Update row counter
                
                c = c + 1;

                % Update tT(c)

                tT(c) = cResume(cLoc);
                
                % Update vPath with charge duartion
                
                vPath(c,[1:3]) = B(i,:);
                
                vPath(c,4) = tT(c); % Charge up to nearest drive resumption time
                
                % Update row counter again
                
                c = c + 1;
                
                % Find distance to next location
                
                nDist = getDist(B(i,1),B(i,2),B(i+1,1),B(i+1,2));

                % Update tT(c)

                tT(c) = tT(c-1)+datenum(hours(nDist/V));
                
                % Update vPath array
                
                vPath(c,[1:3]) = B(i+1,:);                              % Store Lat, Long, and Alt
                vPath(c,4) = tT(c);           % Store Time
                
                
            elseif dVec(4) >= 18 % Check if it is past 6 PM
                
                % Adjust time and date to tomorrow
                
                tommNumVec = tT(c) + datenum(days(1));
                tommNumVec = datevec(tommNumVec);
                tommNumVec(4) = 9; % 9 AM start time
                tommNumVec = datenum(tommNumVec);
                
                % Update row counter
                
                c = c + 1;

                % Update tT(c)

                tT(c) = datenum(tommNumVec);
                
                % Update vPath array
                
                vPath(c,[1:3]) = B(i,:);
                vPath(c,4) = tT(c);
                
                % Update row counter again
                
                c = c + 1;
                
                % Find distance to next location
                
                nDist = getDist(B(i,1),B(i,2),B(i+1,1),B(i+1,2));

                % Update tT(c)

                tT(c) = tT(c-1)+datenum(hours(nDist/V));
                
                % Update vPath array
                
                vPath(c,[1:3]) = B(i+1,:);                              % Store Lat, Long, and Alt
                vPath(c,4) = tT(c);           % Store Time
                
            else % Move on along the race
                
                % Update row counter again
                
                c = c + 1;
                
                % Find distance to next location
                
                nDist = getDist(B(i,1),B(i,2),B(i+1,1),B(i+1,2));

                % Update tT(c)

                tT(c) = tT(c-1)+datenum(hours(nDist/V));
                
                % Update vPath array
                
                vPath(c,[1:3]) = B(i+1,:);                              % Store Lat, Long, and Alt
                vPath(c,4) = tT(c);       % Store Time
                
            end
            
        elseif dVec(4) >= 18 % Check if it is past 6 PM
            
            % Adjust time and date to tomorrow
            
            tommNumVec = tT(c) + datenum(days(1));
            tommNumVec = datevec(tommNumVec);
            tommNumVec(4) = 9; % 9 AM start time
            tommNumVec = datenum(tommNumVec);
            
            % Update row counter
            
            c = c + 1;

            % Update tT(c)

            tT(c) = datenum(tommNumVec);
            
            % Update vPath array
            
            vPath(c,[1:3]) = B(i,:);
            vPath(c,4) = tT(c);
            
            % Update row counter again
            
            c = c + 1;
            
            % Find distance to next location
            
            nDist = getDist(B(i,1),B(i,2),B(i+1,1),B(i+1,2));

            % Update tT(c)

            tT(c) = tT(c-1)+datenum(hours(nDist/V));
            
            % Update vPath array
            
            vPath(c,[1:3]) = B(i+1,:);                              % Store Lat, Long, and Alt
            vPath(c,4) = tT(c);           % Store Time
            
        else % Move on along the route
            
            % Update row counter
            
            c = c + 1;
            
            % Find distance to next location
            
            nDist = getDist(B(i,1),B(i,2),B(i+1,1),B(i+1,2));

            % Update tT(c)

            tT(c) = tT(c-1)+datenum(hours(nDist/V));
            
            % Update vPath array
            
            vPath(c,[1:3]) = B(i+1,:);                              % Store Lat, Long, and Alt
            vPath(c,4) = tT(c);           % Store Time
            
        end
        
    elseif ismember(i,stopInd)   % Check if car is at a regular stage finish
        
        % Check which stage finish location the car is at
        
        sLoc = find(stopInd==i);
        
        dVec = datevec(tT(c)); % Define datevec for current time
        
        % Check if arrived within stage open and close times
        
        if nnz(tT(c) >= sOpen(sLoc) & tT(c) < sClose(sLoc))
            
            % Update counter
            
            c = c + 1;
            
            % Wait 45 minutes at stage stop or checkpoint
            
            tT(c) =  tT(c-1) + datenum(minutes(45));
            
            % Update vPath array
            
            vPath(c,[1:3]) = B(i,:);
            vPath(c,4) = tT(c);
            
            dVec = datevec(tT(c)); % Define datevec for current time
            
            if dVec(4) >= 18 % Check if it is past 6 PM
                
                % Adjust time and date to tomorrow
                
                tommNumVec = tT(c) + datenum(days(1));
                tommNumVec = datevec(tommNumVec);
                tommNumVec(4) = 9; % 9 AM start time
                tommNumVec = datenum(tommNumVec);
                
                % Update row counter
                
                c = c + 1;

                % Update tT(c)

                tT(c) = datenum(tommNumVec);
                
                % Update vPath array
                
                vPath(c,[1:3]) = B(i,:);
                vPath(c,4) = tT(c);
                
                % Update row counter again
                
                c = c + 1;
                
                % Find distance to next location
                
                nDist = getDist(B(i,1),B(i,2),B(i+1,1),B(i+1,2));

                % Update tT(c)

                tT(c) = tT(c-1)+datenum(hours(nDist/V));
                
                % Update vPath array
                
                vPath(c,[1:3]) = B(i+1,:);                          % Store Lat, Long, and Alt
                vPath(c,4) = tT(c);                                 % Store Time
                
            else % Move on along the race
                
                % Update row counter again
                
                c = c + 1;
                
                % Find distance to next location
                
                nDist = getDist(B(i,1),B(i,2),B(i+1,1),B(i+1,2));

                % Update tT(c)

                tT(c) = tT(c-1)+datenum(hours(nDist/V));
                
                % Update vPath array
                
                vPath(c,[1:3]) = B(i+1,:);                              % Store Lat, Long, and Alt
                vPath(c,4) = tT(c);                                     % Store Time
                
            end
            
            
        elseif dVec(4) >= 18 % Check if it is past 6 PM
            
            % Adjust time and date to tomorrow
            
            tommNumVec = tT(c) + datenum(days(1));
            tommNumVec = datevec(tommNumVec);
            tommNumVec(4) = 9; % 9 AM start time
            tommNumVec = datenum(tommNumVec);
            
            % Update row counter
            
            c = c + 1;

            % Update tT(c)

            tT(c) = datenum(tommNumVec);
            
            % Update vPath array
            
            vPath(c,[1:3]) = B(i,:);
            vPath(c,4) = tT(c);
            
            % Update row counter again
            
            c = c + 1;
            
            % Find distance to next location
            
            nDist = getDist(B(i,1),B(i,2),B(i+1,1),B(i+1,2));

            % Update tT(c)

            tT(c) = tT(c-1)+datenum(hours(nDist/V));            
            
            % Update vPath array
            
            vPath(c,[1:3]) = B(i+1,:);                              % Store Lat, Long, and Alt
            vPath(c,4) = tT(c);           % Store Time
            
        else % Move on along the route
            
            % Update row counter
            
            c = c + 1;

            % Find distance to next location
            
            nDist = getDist(B(i,1),B(i,2),B(i+1,1),B(i+1,2));

            % Update tT(c)

            tT(c) = tT(c-1)+datenum(hours(nDist/V));
            
            % Update vPath array
            
            vPath(c,[1:3]) = B(i+1,:);                              % Store Lat, Long, and Alt
            vPath(c,4) = tT(c);                                     % Store Time
            
        end
        
        
    else  % Car is driving along a base leg
        
        if dVec(4) >= 18
            
            % Adjust time and date to tomorrow
            
            tommNumVec = tT(c) + datenum(days(1));
            tommNumVec = datevec(tommNumVec);
            tommNumVec(4) = 9; % 9 AM start time
            tommNumVec = datenum(tommNumVec);
            
            % Update row counter
            
            c = c + 1;

            % Update tT(c)

            tT(c) = datenum(tommNumVec);
            
            % Update vPath array
            
            vPath(c,[1:3]) = B(i,:);
            vPath(c,4) = tT(c);
            
            % Update row counter again
            
            c = c + 1;
            
            % Find distance to next location
            
            nDist = getDist(B(i,1),B(i,2),B(i+1,1),B(i+1,2));

            % Update tT(c)

            tT(c) = tT(c-1)+datenum(hours(nDist/V));
            
            % Update vPath array
            
            vPath(c,[1:3]) = B(i+1,:);                              % Store Lat, Long, and Alt
            vPath(c,4) = tT(c);                                     % Store Time
            
        else
            
            % Update row counter
            
            c = c + 1;
            
            % Find distance to next location
            
            nDist = getDist(B(i,1),B(i,2),B(i+1,1),B(i+1,2));

            % Update tT(c)

            tT(c) = tT(c-1)+datenum(hours(nDist/V));
            
            % Update vPath array
            
            vPath(c,[1:3]) = B(i+1,:);                              % Store Lat, Long, and Alt
            vPath(c,4) = tT(c);                                     % Store Time
            
        end
        
    end
    
    
end


end