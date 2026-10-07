clear; clc;
inputdata = "UConnData1.tdms";
%change inputdata file name to fsae tdms file
groupname = "Data";
volt = "Voltage";
curr = "Current";

%%
tt = tdmsread(inputdata, ChannelGroupName=groupname, ChannelNames=[volt, curr]);
tt = tt{1};
if istimetable(tt)
    tt = timetable2table(tt);
end
voltage = tt.(volt);
current = tt.(curr);
timestep = 0.01;
time = (0:numel(voltage)-1)' * timestep;
voltage = voltage(:);
current = current(:);
power = abs(voltage .* current);

%%
mapfile = "EMRAX_edata.mat";
AWDmotormap = true;
%set false for single hub maps
perror = 0.005;

%%
if AWDmotormap
    pmotor = power ./ 4;
else
    pmotor = power;
end
%power per motor, assuming the load is shared by 4 motors
%%
d = load(mapfile, "rpm_data", "torque_data", "efficiency_data");
F = scatteredInterpolant(d.rpm_data(:), d.torque_data(:), d.efficiency_data(:), "linear", "none");
[Xr, Yt] = meshgrid(linspace(min(d.rpm_data(:)), max(d.rpm_data(:)), 1000), ...
                    linspace(min(d.torque_data(:)), max(d.torque_data(:)), 1000));
Zeff = F(Xr, Yt);
Pelec = (Xr .* 2*pi/60 .* Yt) ./ (Zeff ./ 100); 
%%
levels = round(pmotor, -1);
%round to nearest 10 W for repeated powers 
ulevels = unique(levels);
effcurves = cell(size(ulevels));
umedian = nan(size(ulevels));
for k = 1:numel(ulevels)
    P = ulevels(k);
    onCurve = abs(Pelec - P) <= perror * P;
    e = Zeff(onCurve);
    e = e(~isnan(e));
    effcurves{k} = e;
    umedian(k) = median(e);
end
alleff = vertcat(effcurves{:});
[~, idx] = ismember(levels, ulevels);
efficiency = umedian(idx);
mthermalp = pmotor .* (1 - (efficiency ./ 100));
outT = table(time, power, efficiency, mthermalp);
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
fprintf("\nFor FSAE data spanning %.3f seconds:\n", (numel(power)-1)/100);
fprintf("\nMotor thermal power AVG: %.3f\n", thermavg);
fprintf("\nMotor thermal power RMS: %.3f\n", thermrms);
