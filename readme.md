## Radiosonde
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://GitHub.com/Naereen/StrapDown.js/graphs/commit-activity)

### Description

Global radiosonde stations have provided a very unique and important datasets for atmosphere research. According to the Integrated Global Radiosonde Archive ([IGRA][1]), more than 2,700 ground-base radiosonde stations had or have been functioning all around the world, which cover all the big cities and interested geolocations. These accurate in-situ data can be applied to calculate the atmospheric molecule optical properties [[1](#References)], like backscatter and extinction coefficient. These parameters are of high importance for lidar calibration, quality control and lidar retrieving algorithms. Therefore, how to get these dataset is an essential part of lidar data processing.

- global distribution of radiosonde stations
<br>
<img src="https://www.ncdc.noaa.gov/sites/default/files/styles/full_page_width/public/igra_stationmap.jpg?itok=j0biEjcy" alt="global radiosonde stations" width="600" height="400">


During the past 4 years, I made several query functions with different computer language to retrieve radiosonde data. I hope this repository can be useful and time-saving for those who is currently working on lidar data processing.

### Methodology

All the scripts are based on parsing of the html from Wyoming Radiosonde Browse Webpage ([old][2]|[new][3]). The description of the returned parameters can be found [here][4].

Basically, we will construct the query url to the server and parsing the results from the returned html text. This is very straightforward. What we should pay attention to, is the type of the sounding. Sometimes, results of old sounding or wind sounding will be returned. So a warning module should be added. But for the IDL and python scripts, which have a history of years, I don't have the passion yet to improve it. But for the matlab version, I have add this processing module and also some minor data quality control. You can easily convert it to python or IDL version as you like.

Regarding to the `sitenum` of different stations, you can find it in [radiosonde-station-list.txt](./doc/radiosonde-station-list.txt).

Enjoy it!!!

### Acknowledgement

Special thanks to [Heese Birgit][5] for the matlab script.

### References

1. Bucholtz, A. (1995). "Rayleigh-scattering calculations for the terrestrial atmosphere." Applied optics 34(15): 2765-2773.

[1]: https://www.ncdc.noaa.gov/data-access/weather-balloon/integrated-global-radiosonde-archive
[2]: http://weather.uwyo.edu/upperair/sounding.html
[3]: http://weather.uwyo.edu/upperair/bufrraob.shtml
[4]: http://weather.uwyo.edu/upperair/columns.html
[5]: https://www.tropos.de/institut/ueber-uns/mitarbeitende/birgit-heese/