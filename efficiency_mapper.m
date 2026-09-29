clear; clc;
mapfile = "FMOTB_edata.mat";
%change map file and other files via file name
inputdata  = "endurancedata2.csv";
outputdata = "testing_data_efficiency.csv";
startingrow = 19;
timecolumn = 1;
rpmcolumn = 3;
torquecolumn = 2;

%%
d = load(mapfile, "rpm_data", "torque_data", "efficiency_data");
F = scatteredInterpolant(d.rpm_data(:), d.torque_data(:), d.efficiency_data(:), "linear", "none");
data = readmatrix(inputdata);
data = data(startingrow:end, :);
time   = data(:, timecolumn);
rpm    = data(:, rpmcolumn);
torque = data(:, torquecolumn);
torque = torque ./ 4;
%remove torque = torque ./ 4  if not using motor data from single
%hub motor
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
