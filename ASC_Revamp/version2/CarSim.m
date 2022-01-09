classdef CarSim < handle
    properties(Constant)
        consts = simConstants;
        CAR_MASS_KG         = 300;
        AIR_DENSITY_KGM3    = 1.177;
        CDA_M3              = 0.12;
        ARRAY_AREA_M2       = 4.114;
        PASSIVE_ELEC_LOSS_W = 20;
        REGEN_EFF           = 0.60;
        ARRAY_EFF           = 0.24;
        MOTOR_EFF           = 0.97;
        BATTERY_EFF         = 0.98;
        ROLL_RES_SCALE      = 3.14e-5;
        ROLL_RES_INT        = 0.00252;
    end
    properties(Access = private)
        windSpeed_kmph  = 0;
        windDir_deg     = 0;
        carDir_deg      = 0;
    end
    properties
        speed_kmph;
        loopPlan;
        info;
        DNI;
        DHI;
        DNI_SCALING;
    end
    
    methods(Access = public)
        function this = CarSim(car_speed_kmh, loop_plan)
            % Constructs an instance of this class.
            this.speed_kmph = car_speed_kmh;
            this.loopPlan   = loop_plan;
            this.info = this.createTable();
            
            % Initial entry
            this.info.BatteryCharge_kwh(end, 1) = 5;
        end
        
        function wait(this, pos, dTime_h, time)
            
            % Car charging on stand (Perfect 90 deg array to sun)
            Az = 0;
            El = 90;
            
            % Calculate gains and losses
            losses_kwh = this.getLoss(dTime_h, 0, 0);
            gains_kwh  = this.getArrayGains(Az, El, dTime_h, time, pos);
            
            % Assume gains is higher than losses (Idling < Solar energy)
            fracToMotor        = losses_kwh / (this.MOTOR_EFF*(gains_kwh));
            energytoBatt       = gains_kwh * (1-fracToMotor);
            dBatteryCharge_kwh = (energytoBatt*this.BATTERY_EFF);
            
            % Update info
            t                       = this.info;
            prevCharge              = t.BatteryCharge_kwh(end, 1);
            prevDist                = t.Distance_km(end, 1);
            
            data.BatteryCharge_kwh = prevCharge + dBatteryCharge_kwh;
            data.Distance_km      = prevDist;
            data.DateTime         = time;
            data.Gains_kwh        = gains_kwh;
            data.Losses_kwh       = losses_kwh;
            data.Az               = Az;
            data.El               = El;
            data.Bearing          = 0;
            data.Lat              = pos(1);
            data.Lon              = pos(2);
            data.Alt              = pos(3);
            
            % Ensure battery charge integrity
            if data.BatteryCharge_kwh > 5
                data.BatteryCharge_kwh = 5;
            elseif data.BatteryCharge_kwh < 0
                success = 0;
                return;
            end
            success = 1;
            
            this.updateInfo(data);
            
        end
        
        function [success, dTime_h] = update(this, pos1, pos2, time)
            
            % Get orientation
            dDist_km        = getDist(pos1(1), pos1(2), pos2(1), pos2(2));
            dAlt_km         = pos2(1, 3) - pos1(1, 3);
            bearing_degrees = getBearing(pos1(1), pos1(2), pos2(1), pos2(2));
            [Az, El]        = this.getAzElFromBearing(bearing_degrees, pos1(1), pos1(2), pos1(3), time);
            
            % Calculate time change
            dTime_h = dDist_km / this.speed_kmph;

            % Calculate gains and losses and define temp battery charge change
            dBatteryCharge_kwh = 0;
            losses_kwh         = this.getLoss(dTime_h, dDist_km, dAlt_km);
            gains_kwh          = this.getArrayGains(Az, El, dTime_h, time, pos1);

             %Conditionals for battery charge
            if losses_kwh <= 0 
                %Add gained energy to gains_kwh
                gains_kwh = gains_kwh + this.MOTOR_EFF*(abs(losses_kwh));

                %Update battery charge 
                dBatteryCharge_kwh = dBatteryCharge_kwh + (gains_kwh*this.BATTERY_EFF);
            
            elseif losses_kwh > this.MOTOR_EFF*gains_kwh 
                %Define energy needed from battery in [kWh]
                energyNeeded = losses_kwh-(this.MOTOR_EFF*(gains_kwh));

                %Update battery charge
                dBatteryCharge_kwh = dBatteryCharge_kwh - (energyNeeded/this.BATTERY_EFF);

            elseif losses_kwh < this.MOTOR_EFF*gains_kwh
                %Define fraction of gains energy that goes to motor
                frac = losses_kwh/(this.MOTOR_EFF*(gains_kwh));

                %Define energy to go to battery
                energytoBatt = gains_kwh*(1-frac);

                %Update battery charge
                dBatteryCharge_kwh = dBatteryCharge_kwh + (energytoBatt*this.BATTERY_EFF);
            end
            
            % Update info
            t                       = this.info;
            prevCharge              = t.BatteryCharge_kwh(end, 1);
            prevDist                = t.Distance_km(end, 1);
            
            data.BatteryCharge_kwh = prevCharge + dBatteryCharge_kwh;
            data.Distance_km      = prevDist + dDist_km;
            data.DateTime         = time;
            data.Gains_kwh        = gains_kwh;
            data.Losses_kwh       = losses_kwh;
            data.Az               = Az;
            data.El               = El;
            data.Bearing          = bearing_degrees;
            data.Lat              = pos1(1);
            data.Lon              = pos1(2);
            data.Alt              = pos1(3);
            
            % Ensure battery charge integrity
            if data.BatteryCharge_kwh > 5
                data.BatteryCharge_kwh = 5;
            elseif data.BatteryCharge_kwh < 0
                success = 0;
                return;
            end
            success = 1;
            
            this.updateInfo(data);
        end
    end
    
    methods(Access = private)
        function addRowToTable(this)
            this.info = [this.info; this.createTable()];
        end
        
        function t = createTable(~)
            % Get table schema from constants
            variable_names_types = simConstants.variable_names_types;
            
            % Make table using fieldnames & value types from above
            t = table('Size',[1,size(variable_names_types,1)],... 
                'VariableNames', variable_names_types(:,1),...
                'VariableTypes', variable_names_types(:,2));
        end
        
        function updateInfo(this, data)
            tableToAppend = struct2table(data);
            this.info = [this.info; tableToAppend];
        end
        
        function gain = getArrayGains(this, Az, El, dTime_h, time, pos)
            delta_time_s = dTime_h * 3600;
            [dni, dhi]   = this.getIrradiance(time, pos);
            dni_scaling  = this.getDniScaling(Az, El);
            
            gain = dni_scaling * dni + dhi*this.ARRAY_AREA_M2*this.ARRAY_EFF;
            gain = gain * delta_time_s / (3.6e6); % J to kwh
        end
        
        function loss = getLoss(this, dTime_h, dDist_km, dAltitude_km)
            % Get the loss of the car at an instance.
            if dDist_km == 0
                speed_mps = 0;
            else
                speed_mps = this.getCarSpeedWithWind_kmph() / 3.6; % kmh to m/s
            end
            delta_time_s = dTime_h * 3600;

            aero_loss_kwh = 0.5*(this.AIR_DENSITY_KGM3)*(speed_mps^3)*(this.CDA_M3)*(delta_time_s)/(3.6e6); % J to kwh
            rolling_loss_kwh = ((this.ROLL_RES_INT + (this.ROLL_RES_SCALE)*(speed_mps*3.6))*(this.CAR_MASS_KG)*9.81*(dDist_km*1000))/(3.6e6);% J to kwh
            electrical_loss_kwh = this.PASSIVE_ELEC_LOSS_W*delta_time_s/(3.6e6);% J to kwh
            gravity_loss_kwh = (this.CAR_MASS_KG*9.81*dAltitude_km*1000)/(3.6e6);% J to kwh
            
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
        
        function [dni, dhi] = getIrradiance(this, time, pos)
            time_datenum = datenum(time);
            dni = this.DNI;
            locTime = [];
            for j = 3:size(dni,2)
                locTime(j-2) = abs(etime(datevec(time_datenum),datevec(dni(1,j))));
            end

            [minTime,col] = min(locTime);
            col = col + 2;
            
            locDist= [];
            for j = 2:size(dni,1)
                locDist(j-1) = getDist(pos(1),pos(2),dni(j,1),dni(j,2));
            end

            [minDist,row] = min(locDist);
            row = row + 1;
            
            dni = dni(row, col);
            dhi = this.DHI(row, col);
        end
        
        function dni_scaling = getDniScaling(this, Az, El)
            dni_scaling = this.DNI_SCALING(round(El+1),round(Az+1));
        end
        
        function effective_car_speed_kmh = getCarSpeedWithWind_kmph(this)
            % Computes the effective speed of the car
            % accounting for wind
            wind_velocity = [
                this.windSpeed_kmph*sind(this.windDir_deg), ...
                this.windSpeed_kmph*cosd(this.windDir_deg)
                ];
            car_velocity = [sind(this.carDir_deg), cosd(this.carDir_deg)];
            effective_wind_speed = dot(wind_velocity, car_velocity);

            effective_car_speed_kmh = this.speed_kmph - effective_wind_speed;
        end
    end
end

