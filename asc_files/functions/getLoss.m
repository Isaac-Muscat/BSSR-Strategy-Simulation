function [totalLoss, lossVec] = getLoss(speed,dist,deltaElv,deltaTime,regenEff,windSpeed,windDir,carDir)

% Modify speed to account for wind

ewSpeed = getWind(windSpeed,windDir,carDir);
speed = speed - ewSpeed;

%Convert speed to [m/s]

speed = speed*(1000/3600);

%Compute component losses in [kwH]

aeroLoss = (0.5)*(1.177)*((speed)^3)*(0.12)*deltaTime*(1/(3.6e6));
rollingLoss = ((0.00252 + (3.14e-5)*(speed*3600/1000))*(300)*9.81*(dist*1000))/3.6e6;
electricalLoss = 20*deltaTime*(1/(3.6e6));
elevLoss = (300*9.81*deltaElv*1000)*(1/(3.6e6));

%Sum up all losses in [kWh]

if elevLoss > 0 % Uphill 

    totalLoss = aeroLoss + rollingLoss + electricalLoss + elevLoss;

    elLoss = elevLoss;   % Elevation loss for loss vector 

elseif elevLoss < 0 % Downhill 

    if (aeroLoss+rollingLoss+electricalLoss) < (regenEff/100)*abs(elevLoss)

        totalLoss = -((regenEff/100)*abs(elevLoss) - (aeroLoss+rollingLoss+electricalLoss));

    elseif (aeroLoss+rollingLoss+electricalLoss) > (regenEff/100)*abs(elevLoss)

        totalLoss = (aeroLoss+rollingLoss+electricalLoss) - ((regenEff/100)*abs(elevLoss));

    else % Equal 

        totalLoss = 0;

    end

    elLoss = 0;

else % elevLoss = 0 Straight road

    totalLoss = aeroLoss + rollingLoss + electricalLoss;

    elLoss = 0;

end


lossVec = [aeroLoss,rollingLoss,electricalLoss,elLoss];

end