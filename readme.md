## Radiosonde

### Description

Global radiosonde stations have provided a very unique and imporatant datasets for atmopshere research. According to the Integrated Gloabal Radiosonde Archive ([IGRA](https://www.ncdc.noaa.gov/data-access/weather-balloon/integrated-global-radiosonde-archive)), more than 2,700 ground-base radiosonde stations had or have been functioning all around the wrold, which cover all the big cities and interested geolocations. These accurate in-situ data can be applied to calculate the atmospheric molecule optical properties [ref 1](#References), like backscatter and extinction coefficient. These parameters are of high importance for lidar calibration, quality control and lidar retrieving algorithms. Therefore, how to get these dataset is an essential part of lidar data processing.

- global distribution of radiosonde stations
<br>
<img src="https://www.ncdc.noaa.gov/sites/default/files/styles/full_page_width/public/igra_stationmap.jpg?itok=j0biEjcy" alt="global radiosonde stations" width="600" height="400">


During the past 4 years, I used different computer language for lidar data processing and I have developed different query functions to get radiosonde data, including python, matlab and IDL. I hope this repository can be useful and energy-saving for those who is currently working on lidar data processing.

### Methodology

All the scripts are based on parsing of the html from [Wyoming Radiosond Browse Webpage](http://weather.uwyo.edu/upperair/sounding.html). The description of the returned parameters can be found [here](http://weather.uwyo.edu/upperair/columns.html).

Basically, we will construct the query url to the server and parsing the results from the retrurned html text. This is very straightforward. What we should pay attention to, is the type of the sonding. Sometimes, results of old sonding or wind sonding will be returned. So a warning module should be added. But for the IDL and python scripts, which have a history of years, I will don't have the passion yet to improve it. But for the matlab verision, I have add this processing module and also some minor data quality control. You can easily convert it to python or IDL version as you like.

Regarding to the {sitenum} of different stations, you can find it in [radiosonde-station-list.txt](radiosonde-station-list.txt).

Enjoy it!!!

### Acknowledgement

Special thanks to [Heese Birgit](https://www.tropos.de/institut/ueber-uns/mitarbeitende/birgit-heese/) for the matlab script.

### References

1. Bucholtz, A. (1995). "Rayleigh-scattering calculations for the terrestrial atmosphere." Applied optics 34(15): 2765-2773.


