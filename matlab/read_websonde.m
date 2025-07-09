function [pres, alt, temp, relh, wvmr, wins, wind, dwpt, globalAttri] = read_websonde(measTime, sitenum)
% READ_WEBSONDE search the closest radionsde based on the Wyoming sounding portal and retrieve the data from HTML.
%
% INPUTS:
%    measTime: float
%        lidar measurement time (UTC). [datenum]
%        00:00 or 12:00 in the given date is suggested.
%    sitenum: integer
%        five-digit WMO identification number, which can be found in doc/radiosonde-station-list.txt.
%
% OUTPUTS:
%    pres: numeric
%        pressure [hPa]
%    alt: numeric
%        alt [m]
%    temp: numeric
%        air temperature [буC]
%    relh: numeric
%        relative humidity [%]
%    wvmr: numeric
%        water vapor mixing ratio [g/kg]
%    wins: numeric
%        wind speed [m/s]
%    wind: numeric
%        wind direction [бу]
%    dwpt: numeric
%        dew point temperature [буC]
%    globalAttri: struct
%        URL: URL which can be used to retrieve the current returned values.
%        datetime: measurement time for current used sonde. [datenum]
%        sitenum: site number for current used sonde.
%
% EXAMPLE:
%    [alt, temp] = read_websonde(datenum(2023, 12, 31, 12, 0, 0), 47169);
%
% HISTORY:
%    2018-12-22: First Edition by Zhenping
%    2020-04-05: Support BUFR data format.
%    2025-07-09: Support inquiry through new webpage (https://weather.uwyo.edu/upperair/sounding.shtml)
% .. Authors: - zp.yin@whu.edu.cn

URL = sprintf('http://weather.uwyo.edu/wsgi/sounding?datetime=%s%%20%s&id=%5d&src=UNKNOWN&type=TEXT:LIST', datestr(measTime, 'yyyy-mm-dd'), datestr(measTime, 'HH:MM:SS'), sitenum);

pres = cell(0);
alt = cell(0);
temp = cell(0);
relh = cell(0);
wvmr = cell(0);
wins = cell(0);
wind = cell(0);
dwpt = cell(0);
mTime = [];

[radiosonde, status] = urlread(URL, 'Timeout', 10);

if status == 0
    fprintf('Could not import radiosonde data from web.\n');
end

startStr = ['--------------------------------------------------------------'...
                                '---------------'];
startPos = strfind(radiosonde, startStr) + length(startStr) + 1;
endPos = strfind(radiosonde, '</PRE>');
obTimePos = strfind(radiosonde, 'Observations for');

if numel(startPos) == 0 || numel(endPos) == 0 || numel(obTimePos) == 0
    fprintf ('Problem with getting radiosonde from website:\n %s\n', URL);
    return;
end

for iSonde = 1:int32(numel(startPos) / 2)
    iStartPos = startPos(iSonde*2);
    iEndPos = endPos(iSonde) - 1;

    currentRadiosonde = radiosonde(iStartPos:iEndPos);

    % radiosonde should now be a string, where each line has 11 values and for
    % each value there should be 7 digits. each line then has 7*11 characters
    % plus the newline information contained in character 78 at the end of the line

    % check if number of entries in radiosonde is insufficient
    lines = floor(length(currentRadiosonde)/78);

    if lines < 10
        continue;
    end

    thisPres = NaN(lines,1);
    thisAlt = NaN(lines,1);
    thisTemp = NaN(lines,1);
    thisRelh = NaN(lines, 1);
    thisWvmr = NaN(lines, 1);
    thisWins = NaN(lines, 1);
    thisWind = NaN(lines, 1);
    thisDwpt = NaN(lines, 1);
    thisTime = datenum(radiosonde((obTimePos + 34):(obTimePos + 51)), 'HH UTC dd mmm yyyy');

    for k = 1:lines
        index = (k-1)*78 + 1;

        if numel(sscanf(currentRadiosonde(index:index+6), '%g')) == 0
            thisPres(k) = NaN;
        else
            thisPres(k) = sscanf(currentRadiosonde(index:index+6), '%g');
        end

        if numel(sscanf(currentRadiosonde(index+7:index+13), '%g')) == 0
            thisAlt(k) = NaN;
        else
            thisAlt(k) = sscanf(currentRadiosonde(index+7:index+13), '%g');
        end

        if numel(sscanf(currentRadiosonde(index+14:index+20), '%g')) == 0
            thisTemp(k) = NaN;
        else
            thisTemp(k) = sscanf(currentRadiosonde(index+14:index+20), '%g');
        end

        if numel(sscanf(currentRadiosonde(index+21:index+27), '%g')) == 0
            thisDwpt(k) = NaN;
        else
            thisDwpt(k) = sscanf(currentRadiosonde(index+21:index+27), '%g');
        end

        if numel(sscanf(currentRadiosonde(index+28:index+34), '%g')) == 0
            thisRelh(k) = NaN;
        else
            thisRelh(k) = sscanf(currentRadiosonde(index+28:index+34), '%g');
        end

        if numel(sscanf(currentRadiosonde(index+35:index+41), '%g')) == 0
            thisWvmr(k) = NaN;
        else
            thisWvmr(k) = sscanf(currentRadiosonde(index+35:index+41), '%g');
        end

        if numel(sscanf(currentRadiosonde(index+42:index+48), '%g')) == 0
            thisWind(k) = NaN;
        else
            thisWind(k) = sscanf(currentRadiosonde(index+42:index+48), '%g');
        end

        if numel(sscanf(currentRadiosonde(index+49:index+55), '%g')) == 0
            thisWins(k) = NaN;
        else
            thisWins(k) = sscanf(currentRadiosonde(index+49:index+55), '%g');
        end
    end

    temp = cat(2, temp, thisTemp);
    pres = cat(2, pres, thisPres);
    alt = cat(2, alt, thisAlt);
    relh = cat(2, relh, thisRelh);
    wvmr = cat(2, wvmr, thisWvmr);
    wins = cat(2, wins, thisWins);
    wind = cat(2, wind, thisWind);
    dwpt = cat(2, dwpt, thisDwpt);
    mTime = cat(1, mTime, thisTime);
end

globalAttri.URL = URL;
globalAttri.datetime = mTime;
globalAttri.sitenum = sitenum;

if isempty(mTime)
    warning('No radiosonde data was found.\n%s\n', URL);
    return;
end

end