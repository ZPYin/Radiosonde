;+
; :NAME:
;     H5DTest
;
; :PURPOSE:
;     The H5DTest function checks if a DATASET exists in H5 files. 
;     H5D_TEST returns: 
;       1 (true), if the specified dataset exists 
;       0 (false), if the specified dataset exists
;       -1 if the specified File doesnot exist
;      
; :SYNTAX:
;     Result = H5DTest(Filename, Name)
;
; :PARAMS:
;    FileName (IN:string) Input hdf5 Filename
;    Name (IN:String) Input dataset name 
;         (full path of dataset e.g., 'Product/GM/CloudMask')
;
; :KEYWORDS:
;    GROUP: Test for existence of Group instead of Dataset 
; 
; :REQUIRES:
;     IDL7.0
;
; :EXAMPLES:     
;
; :CATEGORIES:
;     HDF5
; :
; - - - - - - - - - - - - - - - - - - - - - - - - - -
; :COPYRIGHT: (c) Crown Copyright Met Office
; :HISTORY:
;  18-Apr-2011 11:46:18 Created. Yaswant Pradhan.
;  2016-05-31  Edited by yinzp
;-



FUNCTION H5DTest, FileName, Name, GROUP=group
  
  IF ~FILE_TEST(FileName) THEN BEGIN
    PRINT,' Could not find file: '+FileName
    RETURN,-1
  ENDIF
  
  fId = H5F_OPEN(FileName)
    
  status=0b ; Initialise status  

  CATCH, err
  IF err NE 0 THEN BEGIN    
    CATCH, /CANCEL
    status = err NE 0              
    IF (status EQ 1) THEN GOTO, SKIP_H5D_OPEN       
  ENDIF
           
  dId = KEYWORD_SET(group) ? $
        H5G_OPEN( fId, Name ) : $
        H5D_OPEN( fId, Name )
  SKIP_H5D_OPEN:

  IF status EQ 0 THEN BEGIN
    IF KEYWORD_SET(group) THEN H5G_CLOSE,dId $
    ELSE H5D_CLOSE, dId
  ENDIF
  H5F_CLOSE,fId
  
  RETURN, ~status
  
END  