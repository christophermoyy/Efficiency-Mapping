clear; clc;

mapfile = "FMOTB_edata.mat";
%change map file and other files via file name
inputdata  = "testing_data.csv";
outputdata = "testing_data_efficiency.csv";

startingrow = 18;
timecolumn = 1;
rpmcolumn = 2;
torquecolumn = 3;

%%
d = load(mapFile, "rpm_data", "torque_data", "efficiency_data");
F = scatteredInterpolant(d.rpm_data(:), d.torque_data(:), d.efficiency_data(:), "linear", "none");

opts = detectImportOptions(inputdata, "NumHeaderLines", 17);
T = readtable(inputdata, opts);

time = T{:, timecolumn};
rpm = T{:, rpmcolumn};
torque = T{:, torquecolumn};

fprintf("%d data rows starting after row %d.\n", height(T), startingrow);

%%
efficiency = F(rpm, torque);
outT = table(time, rpm, torque, efficiency);
outofrange = isnan(efficiency);
nOut = sum(outofrange);

if nOut > 0
    warning('%d of %d rows were out of map.', nOut, height(outT));
    disp("Rows omitted:");
    disp(outT(outofrange, {"time", "rpm", "torque"}));
end

%%
writetable(outT, outputdata);
%save table elsewhere, gets overridden by next run