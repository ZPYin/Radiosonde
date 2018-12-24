import os
import requests
from bs4 import BeautifulSoup
import numpy as np

def GetRSData(year, month, day, hour, URL='http://weather.uwyo.edu/cgi-bin/sounding', siteNum=57494, file=None):
    '''
    Description:
    Params:
        year: It's string type and stands for the year.
        month: It's string type and stands for the month.
        day: It's string type and stands for the day.
        hour: It's string type and stands for the hour.
    Keywords:
        URL: It's the Internet link for crawling the data
        siteNum: It's string type and stands for the number of the obervation site.
        file: If it is set, the data will be saved in the file.
    Return:
        a compound numpy array with fields 'PRES', 'HGHT', 'TEMP', 'DWPT', 'RELH', 'MIXR', 'DRCT', 'SKNT', 'THTA', 'THTE', 'THTV'.
    Usage:
        data = GetRSData('2014', '05', '08', '00', siteNum='57494', file='/Users/yinzhenping/Desktop/temp.h5')
    History:
        2017-08-01. First Edition by ZP.Yin
    '''

    # Input checking
    try:
        import time 

        temp = time.strptime(year+month+day, '%Y%m%d')
    except Exception as e:
        print('Not a valid date!')
        raise e

    reqURL = "{0}?region=naconf&TYPE=TEXT%3ALIST&YEAR={1}&MONTH={2}&FROM={3}&TO={3}&STNM={4}".format(URL, year, month, day+hour, siteNum)

    # return the html text
    try:
        html = requests.get(reqURL).text
    except Exception as e:
        raise e

    # parse the data
    try:
        soup = BeautifulSoup(html, 'lxml')
    except Exception as e:
        print('Error in parse the html!')
        raise e

    try:
        dataStr = soup.pre.string.split('\n')
        dataStr = dataStr[5:-1]

        dataType = np.dtype([('PRES', np.float), ('HGHT', np.float), ('TEMP', np.float), ('DWPT', np.float), ('RELH', np.float), ('MIXR', np.float), ('DRCT', np.float), ('SKNT', np.float), ('THTA', np.float), ('THTE', np.float), ('THTV', np.float)])
        data = np.empty(len(dataStr), dtype = dataType)

        for index in range(len(dataStr)):
            data[index]['PRES'] = None if dataStr[index][0:7] == '       ' else float(dataStr[index][0:7])
            data[index]['HGHT'] = None if dataStr[index][7:14] == '       ' else float(dataStr[index][7:14])
            data[index]['TEMP'] = None if dataStr[index][14:21] == '       ' else float(dataStr[index][14:21])
            data[index]['DWPT'] = None if dataStr[index][21:28] == '       ' else float(dataStr[index][21:28])
            data[index]['RELH'] = None if dataStr[index][28:35] == '       ' else float(dataStr[index][28:35])
            data[index]['MIXR'] = None if dataStr[index][35:42] == '       ' else float(dataStr[index][35:42])
            data[index]['DRCT'] = None if dataStr[index][42:49] == '       ' else float(dataStr[index][42:49])
            data[index]['SKNT'] = None if dataStr[index][49:56] == '       ' else float(dataStr[index][49:56])
            data[index]['THTA'] = None if dataStr[index][56:63] == '       ' else float(dataStr[index][56:63])
            data[index]['THTE'] = None if dataStr[index][63:70] == '       ' else float(dataStr[index][63:70])
            data[index]['THTV'] = None if dataStr[index][70:77] == '       ' else float(dataStr[index][70:77])
    except:
        raise Exception("Error in parsing the data from http://weather.uwyo.edu")

    # save and return the data
    if file:
        import h5py

        fid = h5py.File(file, 'w')
        dataSet = fid.create_dataset('RadioSonde', (len(dataStr), ), dtype=dataType)
        dataSet[:] = data
        dataSet.attrs['Name'] = '{0}  {1}  {2}  {3}  {4}  {5}  {6}  {7}  {8}  {9}  {10}'.format('PRES', 'HGHT', 'TEMP', 'DWPT', 'RELH', 'MIXR', 'DRCT', 'SKNT', 'THTA', 'THTE', 'THTV')
        dataSet.attrs['Unit'] = '{0}  {1}  {2}  {3}  {4}  {5}  {6}  {7}  {8}  {9}  {10}'.format('hPa', 'm', 'C', 'C', '%', 'g/kg', 'deg', 'knot', 'K', 'K', 'K')

    return data

def main():
    print('------------------------------------------------------------------')
    print("Test on GetRSData: data = GetRSData('2014', '05', '08', '00', siteNum='57494')")
    data = GetRSData('2014', '05', '08', '00', siteNum='57494', file='/Users/yinzhenping/Desktop/temp.h5')
    print(data)

if __name__ == '__main__':
    main()