classdef RaceCarSim < handle
    % Represents the current state of the simulation
    % of the car which is associated with a specific loop plan
    
    properties
        % Declare constant values
        CAR_MASS_KG = 300;
        AIR_DENSITY_KGM3 = 1.177;
        CDA_M3 = 0.12;
        ARRAY_AREA_M2 = 4.114;
        PASSIVE_ELEC_LOSS_W = 20;
        REGEN_EFF = 0.60;
        ARRAY_EFF = 0.24;
        MOTOR_EFF = 0.97;
        BATTERY_EFF = 0.98;

        % Declare variable values
        carSpeed_kmh;
        windSpeed_kmh;
        windDirection_deg;
        carDirection_deg;
        loopPlan;
        batteryCharge_kwh = 5;
        distanceTravelled_km = 0;

        batteryCharge_vec = [0, 5]; % [Distance km, Charge kwh]
        simInfo_table; % TODO: replace ^

    end
    
    methods
        function this = RaceCarSim(car_speed_kmh, loop_plan)
            % Constructs an instance of this class.
            this.carSpeed_kmh = car_speed_kmh;
            this.loopPlan= loop_plan;
            
            % Make N by 2 matrix of fieldname + value type
            variable_names_types = [["BatteryCharge_kwh", "double"]; ...
                        ["Distance_km", "double"]; ...
                        ["DateTime", "datetime"]; ...
                        ["Gains_kwh", "double"]; ...
                        ["Losses_kwh", "double"]; ...
                        ["Az", "double"]; ...
                        ["El", "double"]; ...
                        ["Dhi", "double"]; ...
                        ["Dni", "double"]; ...
                        ["Bearing", "double"]; ...
                        ["Lat", "double"]; ...
                        ["Lon", "double"]; ...
                        ["Alt", "double"]];

            % Make table using fieldnames & value types from above
            this.simInfo_table = table('Size',[0,size(variable_names_types,1)],... 
                'VariableNames', variable_names_types(:,1),...
                'VariableTypes', variable_names_types(:,2));
        end
        
        function updateParamaters(this)
            % TODO add values to table
        end

        function updateDistance(this, delta_dist_km)
            this.distanceTravelled_km = this.distanceTravelled_km + delta_dist_km;
        end
        
        function updateCharge(this, delta_time_h, delta_dist_km, delta_alt_km, Az, El, DNI, DHI, LUT_TABLE, row, col)
            % Calculate gains and losses
            losses_kwh = this.getCarLoss(delta_time_h, delta_dist_km, delta_alt_km);
            gains_kwh  = this.getArrayGains(Az, El, DNI, DHI, LUT_TABLE, delta_time_h, row, col);

             %Conditionals for battery charge
            if losses_kwh <= 0 
                %Add gained energy to gains_kwh
                gains_kwh = gains_kwh + this.MOTOR_EFF*(abs(losses_kwh));

                %Update battery charge 
                this.batteryCharge_kwh = this.batteryCharge_kwh + (gains_kwh*this.BATTERY_EFF);
            
            elseif losses_kwh > this.MOTOR_EFF*gains_kwh 
                %Define energy needed from battery in [kWh]
                energyNeeded = losses_kwh-(this.MOTOR_EFF*(gains_kwh));

                %Update battery charge
                this.batteryCharge_kwh = this.batteryCharge_kwh - (energyNeeded/this.BATTERY_EFF);

            elseif losses_kwh < this.MOTOR_EFF*gains_kwh
                %Define fraction of gains energy that goes to motor
                frac = losses_kwh/(this.MOTOR_EFF*(gains_kwh));

                %Define energy to go to battery
                energytoBatt = gains_kwh*(1-frac);

                %Update battery charge
                this.batteryCharge_kwh = this.batteryCharge_kwh + (energytoBatt*this.BATTERY_EFF);
            end
  
            if this.batteryCharge_kwh > 5
                this.batteryCharge_kwh = 5;
            end

            this.batteryCharge_vec(end+1, :) = [this.distanceTravelled_km, this.batteryCharge_kwh];
            
            battery_kwh = this.batteryCharge_kwh;

        end

        function gain = getArrayGains(this, Az, El, DNI, DHI, LUT_TABLE, delta_time_h, row, col)
            delta_time_s = delta_time_h * 3600;
            gain = LUT_TABLE(round(El+1),round(Az+1)) * DNI(row,col) + DHI(row,col)*this.ARRAY_AREA_M2*this.ARRAY_EFF;
            gain = gain * delta_time_s / (3.6e6); % J to kwh
        end

        function [Az, El] = getAzElFromBearing(this, bearing, lat, lon, alt, time)
            % Time + 5 hours to convert to UTC
            [Az, El] = getAzEl(time + hours(5), lat, lon, alt);
            Az = Az + 180 - bearing;
            if Az < 0
                Az = 360 + Az;
            elseif Az > 360
                Az = Az - 360;
            end
        end

        function loss = getCarLoss(this, delta_time_h, delta_dist_km, delta_altitude_km)
            % Get the loss of the car at an instance.
            if delta_dist_km == 0
                speed_ms = 0;
            else
                speed_ms = this.getCarSpeedWithWind_kmh() / 3.6; % kmh to m/s
            end
            delta_time_s = delta_time_h * 3600;

            aero_loss_kwh = 0.5*(this.AIR_DENSITY_KGM3)*(speed_ms^3)*(this.CDA_M3)*(delta_time_s)/(3.6e6); % J to kwh
            rolling_loss_kwh = ((0.00252 + (3.14e-5)*(speed_ms*3.6))*(this.CAR_MASS_KG)*9.81*(delta_dist_km*1000))/(3.6e6);% J to kwh
            electrical_loss_kwh = this.PASSIVE_ELEC_LOSS_W*delta_time_s/(3.6e6);% J to kwh
            gravity_loss_kwh = (this.CAR_MASS_KG*9.81*delta_altitude_km*1000)/(3.6e6);% J to kwh
            
            general_loss_kwh = aero_loss_kwh + rolling_loss_kwh + electrical_loss_kwh;

            if gravity_loss_kwh >= 0 % Uphill 
                loss = general_loss_kwh + gravity_loss_kwh;

            elseif gravity_loss_kwh <= 0 % Downhill 
                if general_loss_kwh < this.REGEN_EFF*abs(gravity_loss_kwh) % Energy gain
                    loss = general_loss_kwh - this.REGEN_EFF*abs(gravity_loss_kwh);
   
                elseif (general_loss_kwh) > this.REGEN_EFF*abs(gravity_loss_kwh) % Energy loss
                    loss = general_loss_kwh - this.REGEN_EFF*abs(gravity_loss_kwh);
                end
            end
        end
        
        function effective_car_speed_kmh = getCarSpeedWithWind_kmh(this)
            % Computes the effective speed of the car
            % accounting for wind
            wind_velocity = [
                this.windSpeed_kmh*sind(this.windDirection_deg),
                this.windSpeed_kmh*cosd(this.windDirection_deg)
                ];
            car_velocity = [sind(this.carDirection_deg), cosd(this.carDirection_deg)];
            effective_wind_speed = dot(wind_velocity, car_velocity);

            effective_car_speed_kmh = this.carSpeed_kmh - effective_wind_speed;
        end
    end
end

