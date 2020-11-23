function valid_date, yyyymmdd
;+
; :NAME:
;     valid_date
;
; :PURPOSE:
;     The VALID_DATE fucntion check if given date in (YYYYMMDD format) 
;     is a valid calendar date and returns 1 if true, 0 otherwise.            
;
; :SYNTAX:
;     Result = valid_date( YYYYMMDD )     
;
;  :PARAMS:
;    yyyymmdd (IN:String) YearMonthDay in YYYYMMDD format.
;
;
; :REQUIRES:
;
;
; :EXAMPLES:
;    IDL> print, valid_date(20090631)
;         0
;    IDL> print, valid_date(20091255)
;         0
;    IDL> print, valid_date([20080229])
;         1
;    IDL> print, valid_date([20090229])
;         0
;    IDL> print,valid_date(['20080229','20120229'])
;         1   1    
;    IDL> print,valid_date([20080229,20100229,20111232])
;         1   0   0 
;
; :CATEGORIES:
;
; :
; - - - - - - - - - - - - - - - - - - - - - - - - - -
; :COPYRIGHT: (c) Crown Copyright Met Office
; :HISTORY:
;  15-Mar-2010 15:47:16 Created. Yaswant Pradhan.
;  03-May-2011 Vectorisation. YP. 
;-

  syntax  = 'Result = valid_date( YyyyMmDd )'
  if N_PARAMS() lt 1 then message, syntax
  
  date  = STRTRIM(yyyymmdd, 2)
  ;if strlen(date) lt 8 then message,' Date should be in YYYYMMDD form' 
  if (PRODUCT( STRLEN(date) eq 8) eq 0) then $
  message,' Date must be in YYYYMMDD form'
    
  iy  = FIX( STRMID(date,0,4) )
  im  = FIX( STRMID(date,4,2) )
  id  = FIX( STRMID(date,6,2) )
  
  jd  = JULDAY(im, id, iy)  
  CALDAT, jd, m,d,y
    
  return,(id eq d AND im eq m AND iy eq y)
  
end

;+
; :Author:
;  yinzp
;
; :Description:
;   Retrieve the radiosonde data from the site: 
;   http://weather.uwyo.edu/upperair/sounding.html.
;
; :Params:
;    year: [String] yyyy eg, '2014'
;    date: [String] mmdd eg, '0120'
;    hour: [String] hh   eg, '00'. 
;          Note: it is the UTC time. (GMT:00)
;    siteN: [String] sssss eg, '57494'
;
; :Keywords:
;    FILENAME: the filename for the HDF file.
;    BUFR: If this keyword is set, BUFR format data will be downloaded.
;    PRES: If this keyword is set, the pressure will be returned. Unit: hPa
;    HGHT: If this keyword is set, the height will be returned. Unit: m
;    TEMP: If this keyword is set, the temperature will be returned. Unit: C
;    DWPT: If this keyword is set, the dew point will be returned. Unit: C
;    RELH: If this keyword is set, the relative humity will be returned. Unit: %
;    MIXR: If this keyword is set, the mixing ratio will be returned. Unit: g/kg
;    DRCT: If this keyword is set, the wind direction will be returned. Unit: degree
;    SKNT: If this keyword is set, the wind speed will be returned. Unit: knot
;    THTA: If this keyword is set, the Potential temperature will be returned. Unit: K
;    THTE: If this keyword is set, the Equivalent Potential Temperature 
;          will be returned. Unit: K
;    THTV: If this keyword is set, the Virtual Potential Temperature 
;          will be returned. Unit: K
;
; :Examples:
;    res = getrsdata('2017', '0120', '12', '57494', 
;                    PRES = pres, hght = hght, relh = relh, temp = temp, 
;                    filename = 'C:\Users\yinzp\Desktop\temp.h5')
; :History:
;  2017-3-6
;-
;
;
;
FUNCTION GetRSData, year, date, hour, siteN, $
                    FILENAME = filename, $
                    BUFR = bufr, $
                    PRES = pres, $
                    HGHT = hght, $
                    TEMP = temp, $
                    DWPT = dwpt, $
                    RELH = relh, $
                    MIXR = mixr, $
                    DRCT = drct, $
                    SKNT = sknt, $
                    THTA = thta, $
                    THTE = thte, $
                    THTV = thtv
;--------------------------------------------------------------------------------------;
;                                Input Check
;--------------------------------------------------------------------------------------;
    syntax = 'res = GetRSData(year, date, siteN)'
    IF N_Params() LT 3L THEN $
        Message, 'Error in "GetRSData": ' + syntax
    
    IF ~ISA(year, 'String') THEN $
        Message, 'Error in "GetRSData": ' + $
                 Scope_Varname(year, LEVEL=1) + ' is not a string!'
    IF ~Valid_Date(year+date) THEN $
        Message, 'Error in "GetRSData": ' + $
                 Scope_Varname(date, LEVEL=1) + ' is not a valid date!'
    IF ~ISA(hour, 'String') THEN $ 
        Message, 'Error in "GetRSData": ' + $
                 Scope_Varname(hour, LEVEL=1) + ' is not a a string!'
    IF ~(LONG(hour) LE 24 OR LONG(hour) GE 0) THEN $
        Message, 'Error in "GetRSData": ' + $
                 Scope_Varname(hour, LEVEL=1) + ' is not a valid hour!'        
    ; valid the site Number    
    IF ~ISA(siteN, 'String') THEN $ 
        Message, 'Error in "GetRSData": ' + $
                 Scope_Varname(siteN, LEVEL=1) + ' is not a a string!'            
;--------------------------------------------------------------------------------------;

;--------------------------------------------------------------------------------------;
;                               Parameters Initialize
;--------------------------------------------------------------------------------------;
IF KEYWORD_SET(BUFR) THEN BEGIN
    baseURL = 'http://weather.uwyo.edu/cgi-bin/bufrraob.py?src=bufr&'
    URL = StrJoin([baseURL, $
                   'datetime='+STRJOIN([year,StrMid(date, 0, 2),StrMid(date, 2, 2)], '-'), $
                   '%20'+hour, $
                   ':00:00&id='+siteN, $
                   '&type=TEXT:LIST'], '')    
    wind_speed_factor=1.0D/0.5144444
ENDIF ELSE BEGIN
    baseURL = 'http://weather.uwyo.edu/cgi-bin/sounding?region=naconf&TYPE=TEXT%3ALIST&'
    URL = StrJoin([baseURL, $
                   'YEAR='+year, $
                   'MONTH='+StrMid(date, 0, 2), $
                   'FROM='+StrMid(date, 2, 2)+hour, $
                   'TO='+StrMid(date, 2, 2)+hour, $
                   'STNM='+siteN], '&')
    wind_speed_factor=1.0D 
END
;--------------------------------------------------------------------------------------;

    oURL = Obj_New('IDLnetURL')
    content = oURL->Get(/STRING_ARRAY, URL=URL)
    Obj_Destroy, oURL
    
    lineStart = (Where(Stregex(content, '<PRE>') NE -1))[0] + 1L
    lineEnd = (Where(Stregex(content, '</PRE>') NE -1))[0] - 1L
    
    RSData = content[lineStart+4L:lineEnd]   ; the radiosonde data retrieved from the 
                                             ; HTML text
    
    nRS = N_Elements(RSData)   
    pres = Fltarr(nRS)   ; Pressure. Unit: hPa
    hght = Fltarr(nRS)   ; Height. Unit: m
    temp = Fltarr(nRS)   ; Temperature. Unit: C
    dwpt = Fltarr(nRS)   ; Dew point. Unit: C
    relh = Fltarr(nRS)   ; Relative humity. Unit: %
    mixr = Fltarr(nRS)   ; Mixing Ratio. Unit: g/kg
    drct = Fltarr(nRS)   ; Wind Direction. Unit: degree
    sknt = Fltarr(nRS)   ; Wind speed. Unit: knot
    thta = Fltarr(nRS)   ; Potential temperature. Unit: K
    thte = Fltarr(nRS)   ; Equivalent Potential Temperature. Unit: K
    thtv = Fltarr(nRS)   ; Virtual Potential Temperature. Unit: K
    FOR iRS = 0L, nRS-1L DO BEGIN
        pres[iRS] = StrMid(RSData[iRS], 0, 7) EQ '       '? $
                    !VALUES.F_NAN : Float(StrMid(RSData[iRS], 0, 7))
        hght[iRS] = StrMid(RSData[iRS], 7, 7) EQ '       '? $
                    !VALUES.F_NAN : Float(StrMid(RSData[iRS], 7, 7))
        temp[iRS] = StrMid(RSData[iRS], 14, 7) EQ '       '? $
                    !VALUES.F_NAN : Float(StrMid(RSData[iRS], 14, 7))
        dwpt[iRS] = StrMid(RSData[iRS], 21, 7) EQ '       '? $
                    !VALUES.F_NAN : Float(StrMid(RSData[iRS], 21, 7))
        relh[iRS] = StrMid(RSData[iRS], 28, 7) EQ '       '? $
                    !VALUES.F_NAN : Float(StrMid(RSData[iRS], 28, 7))
        mixr[iRS] = StrMid(RSData[iRS], 35, 7) EQ '       '? $
                    !VALUES.F_NAN : Float(StrMid(RSData[iRS], 35, 7))
        drct[iRS] = StrMid(RSData[iRS], 42, 7) EQ '       '? $
                    !VALUES.F_NAN : Float(StrMid(RSData[iRS], 42, 7))
        sknt[iRS] = StrMid(RSData[iRS], 49, 7) EQ '       '? $
                    !VALUES.F_NAN : Float(StrMid(RSData[iRS], 49, 7))
        thta[iRS] = StrMid(RSData[iRS], 56, 7) EQ '       '? $
                    !VALUES.F_NAN : Float(StrMid(RSData[iRS], 56, 7))
        thte[iRS] = StrMid(RSData[iRS], 63, 7) EQ '       '? $
                    !VALUES.F_NAN : Float(StrMid(RSData[iRS], 63, 7))
        thtv[iRS] = StrMid(RSData[iRS], 70, 7) EQ '       '? $
                    !VALUES.F_NAN : Float(StrMid(RSData[iRS], 70, 7))
    ENDFOR
    
    ; unit of wind speed is unified to knot
    idx_sknt=where(finite(sknt),/null)
    sknt[idx_sknt]=sknt[idx_sknt]*wind_speed_factor
    
    ; save to .h5 file
    IF Keyword_Set(filename) THEN BEGIN
        File_MKDIR, File_Dirname(filename)
        Attibute = { Name:STRING('PRES', 'HGHT', 'TEMP', 'DWPT', 'RELH', $
                         'MIXR', 'DRCT', 'SKNT', 'THTA', 'THTE', $
                         'THTV', $
                         FORMAT='(A4, TR2, A4, TR2, A4, TR2,'+ $
                                ' A4, TR2, A4, TR2, A4, TR2,'+ $
                                ' A4, TR2, A4, TR2, A4, TR2,'+ $
                                ' A4, TR2, A4)'), $
        Unit:STRING('hPa', 'm', 'C', 'C', '%', $
                    'g/kg', 'deg', 'knot', 'K', 'K', $
                    'K', $
                    FORMAT='(A4, TR2, A4, TR2, A4, TR2,'+ $
                           ' A4, TR2, A4, TR2, A4, TR2,'+ $
                           ' A4, TR2, A4, TR2, A4, TR2,'+ $
                           ' A4, TR2, A4)') }
                             
        WriteH5, Transpose([[pres], [hght], [temp], [dwpt], [relh], $
                            [mixr], [drct], [sknt], [thta], [thte], [thtv]]), $
                 filename, $
                 VARNAME = 'RadioSonde', $
                 /OVERWRITE, ATTRIBUTES = Attibute
    ENDIF
    
    Return, 1L
END
