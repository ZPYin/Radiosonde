% test matlab script for downlaoding radiosonde data
%
% Aurhors: Zhenping Yin
% Email: zp.yin@whu.edu.cn
% Date: 2027-07-20

clc;

workPath = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(workPath, 'matlab'));

%% Parameter Definition
stationID = 57494;
mDate = datenum(2026, 7, 12, 12, 0, 0);

%% Data Download
fprintf('Test matlab script for downloading radiosonde data\n');
fprintf('Downloading radiosonde data for station %d on %s...\n', stationID, datestr(mDate, 'yyyy-mm-dd HH:MM:SS'));

[pres, alt, temp, relh, wvmr, wins, wind, dwpt, attri] = read_websonde(mDate, stationID);

if isempty(pres)
    fprintf('No radiosonde data available for station %d on %s.\n', stationID, datestr(mDate, 'yyyy-mm-dd HH:MM:SS'));
else
    fprintf('Successfully downloaded radiosonde data for station %d on %s.\n', stationID, datestr(mDate, 'yyyy-mm-dd HH:MM:SS'));
    fprintf('Number of data points: %d\n', length(pres));
    fprintf('URL: %s\n', attri.URL);

    for iH = 1:length(pres)
        fprintf('Data point %d: Pressure = %.2f hPa, Altitude = %.2f m, Temperature = %.2f °„C, Relative Humidity = %.2f %%\n', ...
            iH, pres(iH), alt(iH), temp(iH), relh(iH));
    end

end