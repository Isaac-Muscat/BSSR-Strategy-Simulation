classdef simConstants < handle
    properties(Constant)
        variable_names_types = [["BatteryCharge_kwh", "double"]; ...
                        ["Distance_km", "double"]; ...
                        ["DateTime", "datetime"]; ...
                        ["Gains_kwh", "double"]; ...
                        ["Losses_kwh", "double"]; ...
                        ["Az", "double"]; ...
                        ["El", "double"]; ...
                        ["Bearing", "double"]; ...
                        ["Lat", "double"]; ...
                        ["Lon", "double"]; ...
                        ["Alt", "double"]];
    end
    
    properties
        DNI;
        DHI;
        DNI_SCALING;
    end
end