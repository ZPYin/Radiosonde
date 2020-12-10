;+
; :NAME:
;     WriteH5
;
; :PURPOSE:
;     The WriteH5 procedure writes or appends plain or structured dataset 
;     to an HDF5 file.
;
; :SYNTAX:
;     WriteH5, Data, Filename [,VARNAME=String] [,ATTRIBUTES=Structure] 
;               [,ATTRNAMES=Array] [,/APPEND |,/OVERWRITE] [,/FORCE]
;
; :PARAMS:
;    Data (IN:Array) Input data array to write or append to h5 file.
;    Filename (OUT:String) Output h5 filename.
;
;
; :KEYWORDS:
;    VARNAME    (IN:String) Variable name of the dataset. 
;    ATTRIBUTES (IN:Structure) Data Attributes to attach with the dataset.
;    ATTRNAMES  (IN:String|Array) Modified names of the Attributes given 
;               in Attributes. 
;    /APPEND    Add data to existing h5 File (Filename)
;    /OVERWRITE Write a fresh h5 file (if a Filename already exists).
;               Make sure you do not accidentally delete an important file.  
;    /FORCE     Filename can contain full directory. If a directory tree 
;               does not exists in path, this keyword will force creation
;               of the directory to h5 file first. 
;
; :REQUIRES:
;     IDL 7.0 and above 
;
; :EXAMPLES:     
;     To write a fltarr(20,20) in my/group/data tree and name it testdata
;     IDL> WriteH5, fltarr(20,20), 'test.h5', VARNAME='my/test/data/testdata'
;     
;     To add another array intarr(101) to the existing file's top level and 
;     name it topdata
;     IDL> WriteH5, intarr(101), 'test.h5', VARNAME='topdata', /APPEND
;     
;     To overwrite topdata to the same file but in a different group newgroup
;     IDL> WriteH5, intarr(101), 'test.h5', /over, VARNAME='newgroup/topdata'
;     
;     To add attibutes to the dataset
;     IDL> attri = {Length:'m. From 0~100'}   
;     IDL> WriteH5, FINDGEN(20,20,30,40), 'test.h5', $
;                   VARNAME='newgroup/downDada12', $
;                   /APPEND, AttrNames=ATTNAME, attributes = attri
;     
;
; :CATEGORIES:
;     File I/O
; :
; - - - - - - - - - - - - - - - - - - - - - - - - - -
; :COPYRIGHT: (c) Crown Copyright Met Office
; :HISTORY:
;  03-Feb-2011 16:18:48 Created. Yaswant Pradhan. v-0.1
;  07-Feb-2011 Added functionality to accept group names via 
;              VARNAME keyword (See example). YP.
;  07-Apr-2011 Major revision. v-1.0
;              Added data append functionality. YP.
;              Added data attribute keyword. YP.            
;  15-Apr-2011 Error handling for existing dataset in /Append mode. YP.
;  08-Jun-2011 Added expand_path to handle full path for Filename. YP.
;  2016-05-25  Edited by yinzp
;-



pro WriteH5, Data, Filename, $
             VARNAME=vname, $
             ATTRIBUTES=attributes, $
             ATTRNAMES=attrNames, $
             APPEND=append, $
             OVERWRITE=overwrite, $
             FORCE=force

    ON_ERROR, 2
       
    COMPILE_OPT idl2   ; strict arrsubs
    
    syntax = 'WriteH5, Data, Filename [,VARNAME=String] '+$
             '[,ATTRIBUTES=Structure] [,ATTRNAMES=Array] '+$
             '[,/APPEND |,/OVERWRITE] [,/FORCE]'

    ; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    ; Parse Arguments and Keywords
    ; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    IF N_PARAMS() LT 2 THEN BEGIN
      PRINT, 'Syntax: ' + syntax
      RETURN
    ENDIF  
      
    ; Check conflicting Keywords:
    app = KEYWORD_SET(append)
    ovr = KEYWORD_SET(overwrite)
    IF (app AND ovr) THEN BEGIN
      PRINT,'[WriteH5]: Conflicting keywords - /APPEND and /OVERWRITE.'
      RETURN
    ENDIF  

    ; Check if the file exists to handle Append and Overwrite keywords:
    FileName = EXPAND_PATH(FileName)
    IF (app AND ~FILE_TEST(Filename) ) THEN BEGIN    
      PRINT, '[WriteH5]: ' + Filename + $
            ' does not exist for append.'
      RETURN    
    ENDIF

    ; Check what to do if Filename already exists:    
    IF (FILE_TEST(Filename) AND (app+ovr EQ 0)) THEN BEGIN    
      PRINT,'[WriteH5]: '+ Filename + $
            ' exists. Use Keywords ' + $
            '[/OVERWRITE] to replace existing file] OR '+ $
            '[/APPEND] to add new data to existing file'
      RETURN    
    ENDIF

    ; Check if the file path is valid. Create if force keyword is provided:   
    IF ~FILE_TEST(FILE_DIRNAME(Filename), /DIR) THEN BEGIN
      IF KEYWORD_SET(force) THEN $
         FILE_MKDIR, FILE_DIRNAME(Filename) ELSE BEGIN $
         PRINT, '[WriteH5]: ' + FILE_DIRNAME(Filename) + ' does not exist. ' + $
                'Use Force keyword to create path.'
         RETURN      
      ENDELSE
    ENDIF 
    
    ; Parse Group/Dataset names:  
    vName = KEYWORD_SET(vname) ? vname : 'DATA'  ; Dataset full path
    grps  = STRSPLIT(vName, '/', /EXTRACT, COUNT=n_grps) ; Group Names
  
    ; Parent groupname:
    parentGrp = (n_grps GT 1) ? STRJOIN(grps[0:n_grps-2], '/') : grps
  
    ; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    ; Create or Append Group/Dataset to an existing File
    ; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    fId = app ? H5F_OPEN(Filename, /WRITE) : H5F_CREATE(Filename)  
    
    IF (fId LE 0 ) THEN BEGIN
      PRINT,'[WriteH5]:: Failed to '+(app ? 'Open' : 'Create')+ Filename
      RETURN
    ENDIF
  
    IF app THEN BEGIN    
      Err = {Msg:'', Stat:0}    
          
      IF H5DTest(Filename, vName) THEN BEGIN
        Err.Msg = ' A Dataset ['+vName+'] already exists in the File.'
        ++Err.Stat
      ENDIF
                     
      IF H5DTest(Filename,vName,/GROUP) THEN BEGIN
        Err.Msg = ' A Group ['+vName+'] already exists in the File.'
        ++Err.Stat      
      ENDIF
        
      IF H5DTest(Filename,parentGrp) THEN BEGIN
        Err.Msg = ' Can not create group ['+parentGrp+$
                  ']; a Dataset with same name already exists in the File.'
        ++Err.Stat
      ENDIF                            
      
      IF Err.Stat NE 0 THEN BEGIN
        PRINT, Err.Msg
        RETURN
      ENDIF                  
          
    ENDIF  
      
    ; 1.0. Create Groups if necessary
    ; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    FOR i=0,n_grps-2 DO BEGIN    
      gName = (i EQ 0) ? grps[i] : gName +'/'+ grps[i]
             
      CATCH, Error    
      IF Error NE 0 THEN BEGIN
        CATCH, /CANCEL
        gId = H5G_CREATE( fId, gName )      
      ENDIF
  
      gId = H5G_OPEN( fId, gName )
      IF (gId LE 0 ) THEN BEGIN
        PRINT,'[WriteH5]:: Failed to create group ' + gName
        RETURN
      ENDIF
  
      H5G_CLOSE, gId
      gId = -1        
    ENDFOR ;for i=0,n_grps-2
   
    ; 1.1. Check if name ends with a forward slash, 
    ;      in this case only groups are created
    ; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    IF (STRMID(vName, 0, 1, /REVERSE_OFFSET) eq "/" ) then begin
      gName = STRMID(vName, 0, STRLEN(vName)-1 )
      gId = H5G_CREATE( fId, gName )
  
      IF (gId LE 0 ) THEN BEGIN
        PRINT,"ERROR:: Failed to create group" + gName
        RETURN
      ENDIF
  
      H5G_CLOSE, gId
      gId = -1
    ENDIF
        
    ; 2.   Write/Append new Single data layer
    ; 2.0. Get data type and space again for the new dataset
    ; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    IF N_ELEMENTS(Data) GT 0 THEN BEGIN
      chunkDims = SIZE(Data,/DIMENSIONS)
      numDim    = SIZE(Data,/N_DIMENSIONS)
      
      IF (numDim GT 2) THEN chunkDims[0:numDim-3] = 1
      dType_id = H5T_IDL_CREATE(Data)
  
      IF SIZE(Data,/N_DIMENSIONS) EQ 0 THEN BEGIN
        sze = 1   
        dSpace_id = H5S_CREATE_SIMPLE(sze)
      ENDIF ELSE BEGIN    
        dSpace_id = H5S_CREATE_SIMPLE(SIZE(Data, /DIMENSIONS))
      ENDELSE
    
    ; 2.1. Create dataset in the output file
    ; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      dSet_id = H5D_CREATE( fId, vName, dType_id, dSpace_id, $
                            CHUNK_DIMENSIONS=chunk_dimensions, $
                            GZIP=9, /SHUFFLE )
       
    ; 2.2. Write data to dataset
    ; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      H5D_WRITE, dSet_id, Data
      H5S_CLOSE, dSpace_id
      H5T_CLOSE, dType_id
    ENDIF ELSE BEGIN
      dSet_id = H5G_OPEN(fId, vName) ; No data, just groups
    ENDELSE
           
    ; 3.   Write Attributes, if present 
    ; 3.0. if attributes are given, add them to the data.
    ; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    IF N_ELEMENTS(attributes) GT 0 THEN BEGIN
      names = N_ELEMENTS(AttrNames) EQ N_TAGS(attributes) ? $
              AttrNames : TAG_NAMES(attributes)
  
      FOR k=0,N_TAGS(attributes)-1 DO BEGIN
        CASE names[k] OF   ; STR UPPER CASE SOME ATTIBUTE NAMES
          '_fillvalue': name = '_FillValue'
          'missingvalue': name = 'MissingValue'
          'offset': name = 'Offset'
          'scalefactor': name = 'ScaleFactor'
          ELSE: name = names[k]
        ENDCASE
  
        dims = SIZE(attributes.(k), /DIMENSIONS)
        IF dims EQ 0 THEN dims = 1
        attr_dType_id   = H5T_IDL_CREATE(attributes.(k))
        attr_dSpace_id  = H5S_CREATE_SIMPLE(dims)
  
        attr_id = H5A_CREATE(dSet_id, name, attr_dType_id, attr_dSpace_id)
        IF attr_id LE 0 THEN BEGIN
          PRINT, "ERROR:: failed to create attribute"
          RETURN
        ENDIF
        
        H5A_WRITE, attr_id, attributes.(k)
        
        H5A_CLOSE, attr_id
        H5S_CLOSE, attr_dSpace_id
        H5T_CLOSE, attr_dType_id
      ENDFOR ;for k=0,N_TAGS(attributes)-1
    ENDIF
     
    ; 4. Close all open identifiers
    ; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    IF (N_ELEMENTS(Data) GT 0) $
    THEN H5D_CLOSE, dSet_id $
    ELSE H5G_CLOSE, dSet_id
      
    H5F_CLOSE, fId
  
END