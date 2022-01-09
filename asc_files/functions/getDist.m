function [dist] = getDist(lat1,lon1,lat2,lon2) 

% Docstring 

% This function takes in a pair of starting lat and long and a pair of
% ending lat and long and returns the distance between them 

% Code 

R = 6371e3;                  % Radius of Earth in metres
phi_1 = lat1 * pi/180;       % φ, λ in radians
phi_2 = lat2 * pi/180;
delPhi = (lat2-lat1) * pi/180;
delLambda = (lon2-lon1) * pi/180;

a =  ( sin(delPhi/2) * sin(delPhi/2) ) + ( cos(phi_1) * cos(phi_2) * sin(delLambda/2) * sin(delLambda/2) );
c = 2 * atan2(sqrt(a), sqrt(1-a));
 
dist = (R * c)/1000;    % Distance in km

end