function [ewSpeed] = getWind(windSpeed,windDir,carDir)

% This function takes in a wind speed, wind direction, and car direction
% and returns the effective wind speed in the direction the car is
% traveling in KPH

wVector = [windSpeed*sind(windDir),windSpeed*cosd(windDir)];
cVector = [sind(carDir),cosd(carDir)];

ewSpeed = dot(wVector,cVector);

end