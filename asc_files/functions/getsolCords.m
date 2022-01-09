o = 1; 
p = 1;

sCords{1} = [];

while o < 18084
    
    [tsCords,b] = solCords(sCords{o},p,ascRouteFull);
    sCords{o+1} = tsCords;
    o = o + 1;
    p = b;
    
end
    
    