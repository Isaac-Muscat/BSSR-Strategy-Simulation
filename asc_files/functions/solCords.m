function [sCords,b] = solCords(iCords,j,ascRouteFull)

% Loop over route csv to extract 1KM ditant locations

for i = j:18084
    
    dist = getDist(ascRouteFull(j,1),ascRouteFull(j,2),ascRouteFull(i+1,1),ascRouteFull(i+1,2));
    
    if dist >= 1        
       
        sCords = [iCords;ascRouteFull(i+1,:)];
        b = i + 1;

        break
        
    end
    
end

end



