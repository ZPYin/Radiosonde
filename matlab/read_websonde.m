function [alt, temp, pres, rh, globalAttri] = read_websonde(measTime, tRange, sitenum, dFormat)
%READ_WEBSONDE search the closest radionsde based on the Wyoming sounding portal and retrieve the data from HTML.
%   Example:
%       [alt, temp, pres, rh, globalAttri] = read_websonde(measTime, tRange, sitenum, dFormat)
%   Inputs:
%       measTime: float
%           lidar measurement time (UTC). [datenum]
%           00:00 or 12:00 in the given date is suggested.
%       tRange: 2-element array
%           search range for the online radiosonde.
%       sitenum: integer
%           site number, which can be found in doc/radiosonde-station-list.txt.
%           You can update the list with using download_radiosonde_list.m
%       dFormat: char
%           data format ('TEMP' or 'BUFR'). Default: 'TEMP'
%           TEMP (traditional ascii format): http://weather.uwyo.edu/upperair/sounding.html
%           BUFR (binary universal format): http://weather.uwyo.edu/upperair/bufrraob.shtml
%   Outputs:
%       alt: array
%           altitute for each range bin. [m]
%       temp: array
%           temperature for each range bin. If no valid data, NaN will be filled. [C]
%       pres: array
%           pressure for each range bin. If no valid data, NaN will be filled. [hPa]
%       rh: array
%           relative humidity for each range bin. If no valid data, NaN will be filled. [%]
%       globalAttri: struct
%           URL: URL which can be used to retrieve the current returned values.
%           datetime: measurement time for current used sonde. [datenum]
%           sitenum: site number for current used sonde.
%   History:
%       2018-12-22. First Edition by Zhenping
%       2020-04-05. Support BUFR data format.
%   Contact:
%       zhenping@tropos.de

if ~ exist('dFormat', 'var')
    dFormat = 'TEMP';
end

alt = [];
temp = [];
pres = [];
rh = [];

[thisYear, thisMonth, day1] = datevec(tRange(1)); 
[~, ~, day2] = datevec(tRange(2)); 

if strcmpi(dFormat, 'temp')
    URL = sprintf('http://weather.uwyo.edu/cgi-bin/sounding?region=europe&TYPE=TEXT%%3ALIST&YEAR=%04d&MONTH=%02d&FROM=%02d00&TO=%02d00&STNM=%5d', thisYear, thisMonth, day1, day2, sitenum);
elseif strcmpi(dFormat, 'bufr')
    URL = sprintf('http://weather.uwyo.edu/cgi-bin/bufrraob.py?src=bufr&datetime=%s%%20%s&id=%5d&type=TEXT:LIST', datestr(measTime, 'yyyy-mm-dd'), datestr(measTime, 'HH:MM:SS'), sitenum);
else
    warning('Unknown dFormat: %s', dFormat);
    return;
end

[pressure, altitude, temperature, relh, mTime] = parse_sounding(URL, dFormat);

if isempty(mTime)
    warning('No radiosonde data was found.\n%s\n', URL);
    return;
end

[datetime, iSonde] = min(abs(measTime - mTime));
globalAttri.URL = URL;
globalAttri.datetime = datetime;
globalAttri.sitenum = sitenum;

alt = altitude{iSonde};
temp = temperature{iSonde};
rh = relh{iSonde};
pres = pressure{iSonde};

end