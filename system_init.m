% Initialization function
function [t,sample_time,k,Text,Text_ini,Tin_sp,rad_90,step,Qdot_dem, Design,T_primary] = system_init(model)
% returns a structure containing initial values, system parameters and
% state space matrices

% Structure of variables for simulink
s = struct;
% Model Name
M_name = model;

% time step use for simulation
step = get_param(M_name,'FixedStep');
if isnan(step)
    error('You must select a Fixed step solver !')
elseif strcmp(step,'auto')
    step = '1';
else
    step = str2double(get_param(M_name,'FixedStep'));
end
StartTime = str2double(get_param(M_name,'StartTime'));
StopTime = prod(str2double(strsplit(get_param(M_name,'StopTime'),'*')));
t = [StartTime:step:StopTime]';

%time = str2double(strsplit(get_param('NatersV4','StopTime'),'*'));
time = str2double(strsplit(get_param(M_name,'StopTime'),'*'));
s.time = time;
if time(1) == 24 % hours
    sample_time = 3600;
elseif time(1) == 4 % 1/4 hours
    sample_time = 900;
elseif time(1) == 12 % 5 minutes
    sample_time = 300;
elseif time(1) == 60 % 1 minutes
    sample_time = 60;
elseif time(1) == 3600 % secondes
    sample_time = 1;
else
    error('The time sampling should be minutes, hours or day');
end

%% Building
[Ab_c, Bb_c, Qdot_dem, Design] = get_state_input_mat_building(sample_time);

% Continuous building model
step=1/sample_time;
Ab_c = Ab_c.*step;
Bb_c = Bb_c.*step;
sysb_c = ss(Ab_c, Bb_c, eye(size(Ab_c,1)), zeros(size(Ab_c,1), size(Bb_c,2)));
% impulsetest = impulse(sysb_c);
% 
% figure(1)
% impulse(sysb_c);
% [y, T] = impulse(sysb_c);
% 
% tau1 = T(find(y(:,1,2)<=0.3678*y(1,1,2),1))/3600
% tau2 = T(find(y(find(y(:,2,1)>=max(y(:,2,1))):end,2,1)<=0.3678*max(y(:,2,1)),1))/3600
% tau3 = T(find(y(:,3,1)<=0.3678*y(1,3,1),1))/3600

% Discrete building model
sysb_d = c2d(sysb_c, 1);
[Ab_d, Bb_d] = ssdata(sysb_d);

%% Heat pump model
[ K ] = get_param_hp(Qdot_dem);
k = K;
% Tprimary_in = repmat(linspace(-5,15,100),4,1); %[10 * ones(1,60),10 * ones(1,60)] ;
% Tsecondary_out = [35 * ones(1,100); 45* ones(1,100); 55* ones(1,100);65* ones(1,100)];%linspace(35,35,100);
% Tprimary_in = repmat([2 10 15],4,1); %[10 * ones(1,60),10 * ones(1,60)] ;
% p = size(Tprimary_in,2);
% Tsecondary_out = [35 * ones(1,p); 45*ones(1,p); 55*ones(1,p); 60*ones(1,p)];%linspace(35,35,100);
% 
% heating_power = [K(1,1) * Tprimary_in(1:2,1:p) + K(1,2) * Tsecondary_out(1:2,1:p) + K(1,3); K(2,1) * Tprimary_in(3:4,1:p) + K(2,2) * Tsecondary_out(3:4,1:p) + K(2,3)];
% electric_power = [K(1,4) * Tprimary_in(1:2,1:p) + K(1,5) * Tsecondary_out(1:2,1:p) + K(1,6); K(2,4) * Tprimary_in(3:4,1:p) + K(2,5) * Tsecondary_out(3:4,1:p) + K(2,6)]; 
% source_power = [-K(1,7) * Tprimary_in(1:2,1:p) - K(1,8) * Tsecondary_out(1:2,1:p) - K(1,9); -K(2,7) * Tprimary_in(3:4,1:p) - K(2,8) * Tsecondary_out(3:4,1:p) - K(2,9)];
% % AA=heating_power+source_power-electric_power;
% % plot(AA)
% figure(1)
% plot(Tprimary_in(1,:), heating_power(1,:)/1000,'r',Tprimary_in(1,:), heating_power(2,:)/1000,'b',Tprimary_in(1,:), heating_power(3,:)/1000,'g',Tprimary_in(1,:), heating_power(4,:)/1000,'k');
% hold on 
% plot(Tprimary_in(1,:), -source_power(1,:)/1000,'*-r',Tprimary_in(1,:), -source_power(2,:)/1000,'*-b',Tprimary_in(1,:), -source_power(3,:)/1000,'*-g',Tprimary_in(1,:), -source_power(4,:)/1000,'*-k');
% hold on 
% plot(Tprimary_in(1,:), electric_power(1,:)/1000,'--r',Tprimary_in(1,:), electric_power(2,:)/1000,'--b',Tprimary_in(1,:), electric_power(3,:)/1000,'--g',Tprimary_in(1,:), electric_power(4,:)/1000,'--k');
% legend('Qhot [35�C]','Qhot [45�C]','Qhot [55�C]','Qhot [60�C]','Qcold [35�C]','Qcold [45�C]','Qcold [55�C]','Qcold [60�C]','E_el [35�C]','E_el [45�C]','E_el [55�C]','E_el [60�C]','Location','EastOutside');
% xlabel('Source temperature (Primary loop) [�C]');
% xlim([2 15])
% ylabel('Power [kW]');
% COP = heating_power./electric_power; 
% COP2 = 0.49*(273.15+Tsecondary_out)./ (Tsecondary_out-Tprimary_in);
% figure(2)
% %plot(Tsecondary_out, COP,'-b', Tsecondary_out, COP2, 'r');
% plot(Tprimary_in', COP','-b', Tprimary_in', COP2', 'r');

%% Other paramters and variables
% external temperature
%Sion data
Text_data = load('Sion_Temperatures_January_May_m'); % minute data
if sample_time ~= 1;
    Text_data = Text_data(StartTime:(sample_time/60):length(Text_data));
else
    Text_data = Text_data(StartTime:1:length(Text_data));
    Text_data = kron(Text_data,ones(60,1));
end
Text = struct('time', t, 'signals', struct('values',Text_data(1:length(t))));
Text_ini = Text.signals.values(1);
%clear Text_data

% room setpoint temperature 
Tin_sp_day = [18*ones(7,1);20*ones(16,1);18*ones(2,1)];
Tin_sp_vec = repmat(Tin_sp_day,ceil(length(t)/length(Tin_sp_day)),1);
Tin_sp = struct('time', t, 'signals', struct('values',Tin_sp_vec(1:length(t))));

% variable room temperature
Tin_sp = Tin_sp.signals.values(1);

% solar radiation
rad_90_data = load('Sion_Meteonorm_Radiation_SOUTH_90_January_May_m');
if sample_time ~= 1;
    rad_90_data = rad_90_data(1:sample_time/60:length(rad_90_data));
else
    rad_90_data = rad_90_data(1:sample_time:length(rad_90_data));
    rad_90_data = kron(rad_90_data,ones(60,1));
end
rad_90 = struct('time', t, 'signals', struct('values', rad_90_data(1:length(t))));
%clear rad_90_data

% initial conditions
HP_status = 0;
L_ini = (Design(2)-Text_ini)/(Design(2)-Design(1));

T_primary=10;







end