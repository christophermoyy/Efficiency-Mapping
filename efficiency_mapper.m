clear; clc;
mapfile = "FMOTB_edata.mat";
%change map file and other files via file name
AWDmotormap = true;
%set false for single hub maps
inputdata  = "endurancedata1.csv";
%change inputdata file name per csv file name
outputdata = "testing_data_efficiency.csv";
startingrow = 18;
timecolumn = 1;
rpmcolumn = 2;
torquecolumn = 3;

%%
d = load(mapfile, "rpm_data", "torque_data", "efficiency_data");
F = scatteredInterpolant(d.rpm_data(:), d.torque_data(:), d.efficiency_data(:), "linear", "none");
data = readmatrix(inputdata);
data = data(startingrow:end, :);
time   = data(:, timecolumn);
rpm    = data(:, rpmcolumn);
torque = data(:, torquecolumn);
if AWDmotormap
    torque = torque ./ 4;
%assuming torque is spread across 4 motors for AWD
power = rpm .* torque;
fprintf("%d data rows starting after row %d.\n", size(data,1), startingrow);

%%
efficiency = F(rpm, torque);
mthermalp = power .* (1 - (efficiency ./ 100));
outT = table(time, rpm, torque, power, efficiency, mthermalp);
outofrange = isnan(efficiency);
nOut = sum(outofrange);
if nOut > 0
    warning("%d of %d rows were out of map.", nOut, height(outT));
end
figure;
plot(time, mthermalp);
xlabel("Time");
ylabel("Motor Thermal Power");
title("Motor Thermal Power vs Time");
grid on;

%%
thermavg = mean(mthermalp, "omitnan");
thermrms = rms(mthermalp, "omitnan");
fprintf("\nMotor thermal power AVG: %.3f\n", thermavg);
fprintf("\nMotor thermal power RMS: %.3f\n", thermrms);

%%
writetable(outT, outputdata);
%save table elsewhere, gets overridden by next run
