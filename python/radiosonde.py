import requests
import h5py
import datetime as dt
from bs4 import BeautifulSoup
import numpy as np


URL = {
    'TEMP': 'http://weather.uwyo.edu/cgi-bin/sounding?region=naconf&' +
            'TYPE=TEXT%3ALIST&YEAR={0}&MONTH={1}&FROM={2}&TO={2}&STNM={3:d}',
    'BUFR': 'http://weather.uwyo.edu/cgi-bin/bufrraob.py?src=bufr&' +
            'datetime={0}%20{1}&id={2:d}&type=TEXT:LIST'}


def GetRSData(year, month, day, hour, *,
              dFormat='TEMP', siteNum=57494, file=None):
    '''
    retrieve the radiosonde data from Wyoming website.

    Parameters
    ----------
    year: int
        4 digit year. e.g., 2014
    month: int
        2 digit month. e.g., 12
    day: int
        2 digit day. e.g., 12
    hour: int
        2 digit hour (UTC). e.g., 00
    Keywords
    --------
    dFormat: string
        data format, only 'temp' (default) and 'bufr' are available.
    siteNum: int
        five-digit WMO identification number (see ./doc/radiosonde-station-list.txt).
        e.g., 57494 (for Wuhan)
    file: string
        If it is set, the data will be saved in the file.
    Returns
    -------
        compound numpy array with fields of ('PRES', 'HGHT', 'TEMP', 'DWPT',
        'RELH', 'MIXR', 'DRCT', 'SKNT', 'THTA', 'THTE', 'THTV')
        - PRES: atmospheric pressure. [hPa]
        - HGHT: geopotential height. [meter]
        - TEMP: temperature. [celsius]
        - DWPT: dewpoint temperature. [celsius]
        - RELH: relative humidity. [%]
        - MIXR: mixing ratio. [gram/kilogram]
        - DRCT: wind direction. [degrees true]
        - SKNT: wind speed. [knot]
        - THTA: potential temperature. [kelvin]
        - THTE: equivalent potential temperature. [kelvin]
        - THTV: virtual potential temperature. [kelvin]
    Examples
    --------
    data = GetRSData(2014, 5, 8, 0, siteNum='57494', file='temp.h5')
    History
    -------
    2017-08-01: First Edition by Zhenping Yin <zp.yin@whu.edu.cn>.
    2020-04-05: Support BUFR data format.
    '''

    t = dt.datetime(year, month, day, hour, 0, 0)

    if dFormat.lower() == 'temp':
        # use http://weather.uwyo.edu/upperair/sounding.html
        reqURL = URL['TEMP'].format(
            t.strftime('%Y'), t.strftime('%m'), t.strftime('%d%H'), siteNum
        )
    elif dFormat.lower() == 'bufr':
        reqURL = URL['BUFR'].format(
            t.strftime('%Y-%m-%d'), t.strftime('%H:%M:%S'), siteNum
        )
    else:
        raise ValueError('Unknown input of dFormat')

    # parse the data
    try:
        html = requests.get(reqURL).text
        soup = BeautifulSoup(html, 'lxml')
    except Exception as e:
        print(reqURL)
        raise e('Error in loading the html!')

    try:
        dataStr = soup.pre.string.split('\n')
        dataStr = dataStr[5:-1]

        dataType = np.dtype([
            ('PRES', np.float), ('HGHT', np.float), ('TEMP', np.float),
            ('DWPT', np.float), ('RELH', np.float), ('MIXR', np.float),
            ('DRCT', np.float), ('SKNT', np.float), ('THTA', np.float),
            ('THTE', np.float), ('THTV', np.float)])
        data = np.empty(len(dataStr), dtype=dataType)

        for index in range(len(dataStr)):
            data[index]['PRES'] = None if dataStr[index][0:7] == '       ' \
                else float(dataStr[index][0:7])
            data[index]['HGHT'] = None if dataStr[index][7:14] == '       ' \
                else float(dataStr[index][7:14])
            data[index]['TEMP'] = None if dataStr[index][14:21] == '       ' \
                else float(dataStr[index][14:21])
            data[index]['DWPT'] = None if dataStr[index][21:28] == '       ' \
                else float(dataStr[index][21:28])
            data[index]['RELH'] = None if dataStr[index][28:35] == '       ' \
                else float(dataStr[index][28:35])
            data[index]['MIXR'] = None if dataStr[index][35:42] == '       ' \
                else float(dataStr[index][35:42])
            data[index]['DRCT'] = None if dataStr[index][42:49] == '       ' \
                else float(dataStr[index][42:49])
            if dFormat.lower() == 'temp':
                data[index]['SKNT'] = None \
                    if dataStr[index][49:56] == '       ' \
                    else float(dataStr[index][49:56])
            elif dFormat.lower() == 'bufr':
                data[index]['SKNT'] = None \
                    if dataStr[index][49:56] == '       ' \
                    else float(dataStr[index][49:56]) * 1.944
            data[index]['THTA'] = None if dataStr[index][56:63] == '       ' \
                else float(dataStr[index][56:63])
            data[index]['THTE'] = None if dataStr[index][63:70] == '       ' \
                else float(dataStr[index][63:70])
            data[index]['THTV'] = None if dataStr[index][70:77] == '       ' \
                else float(dataStr[index][70:77])
    except Exception as e:
        raise e("Error in parsing the data from http://weather.uwyo.edu")

    # save and return the data
    if file:
        fid = h5py.File(file, 'w')
        dataSet = fid.create_dataset(
            'RadioSonde', (len(dataStr), ), dtype=dataType)
        dataSet[:] = data
        dataSet.attrs['Name'] = '{} {} {} {} {} {} {} {} {} {} {}'.format(
            'PRES', 'HGHT', 'TEMP', 'DWPT', 'RELH',
            'MIXR', 'DRCT', 'SKNT', 'THTA', 'THTE', 'THTV')
        dataSet.attrs['Unit'] = '{} {} {} {} {} {} {} {} {} {} {}'.format(
            'hPa', 'm', 'C', 'C', '%', 'g/kg', 'deg', 'knot', 'K', 'K', 'K')

    return data


def main():
    data = GetRSData(
        2021, 9, 21, 12, dFormat='BUFR',
        siteNum=54511, file='temp.h5')


if __name__ == '__main__':
    main()
