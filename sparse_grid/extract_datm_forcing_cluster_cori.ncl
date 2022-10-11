; NCL script
; extract_datm_forcing_cluster.ncl
; Keith Oleson, Dec 2020
; This script extracts GSWP3 forcing for a 1.9x2.5 sparse grid simulation
; The sparse grid is defined by a file created by the Forrest Hoffman/Nate Collier cluster analysis for the PPE.
; Here the forcing is condensed to a vector of 400 grid cells to increase computational efficiency. This approach will 
; not exactly reproduce the results of a sparse grid simulation forced by the global version of GSWP3 because in 
; that case the datm uses bilinear interpolation of the 0.5 degree forcing to derive the forcing for each 1.9x2.5 
; grid cell, whereas here we simply use the forcing from the nearest neighbor. However, comparison of the two approaches 
; yields generally reasonably small differences, in particular when compared to the uncertainty in representing a global 
; full grid simulation with 400 grid cells.


; Modified for use on cori by Jessica Needham Oct 2022
;**************************************

;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

 print ("=========================================")
 print ("Start Time: "+systemfunc("date") )
 print ("=========================================")

 maxcnt = 400

; This is for output_v4 version (final)
 currdate = "210222"

; Whether or not to create the atm domain file
; The forcing files are always created
 create_atm_domain_filename_new = False

; This is for output_v4 version (final)
 cluster_filename = "/global/homes/j/jneedham/sparse_grid/clusters.clm51_PPEn02ctsm51d021_2deg_GSWP3V1_leafbiomassesai_PPE3_hist.annual.sd.400.nc"
 
; The original GSWP3 domain file
 atm_domain_filename_orig = "/project/projectdirs/e3sm/inputdata/atm/datm7/atm_forcing.datm7.GSWP3.0.5d.v1.c170516/domain.lnd.360x720_gswp3.0v1.c170606.nc"

; The new GSWP3 domain file. Note: I labeled this "dense", not sparse because it is the forcing condensed to a vector
; of 400 grid cells, which in retrospect is a bit confusing.
; This is for output_v4 version (final)
 atm_domain_filename_new  = "/global/cscratch1/sd/jneedham/sparse_grid/domain.lnd.360x720_gswp3.0v1.c170606v4.dense"+maxcnt+".nc"

; Open original atm domain file for read
 in2 = addfile(atm_domain_filename_orig,"r")
 atm_xc_in = in2->xc
 atm_yc_in = in2->yc
 atm_xc_in!0 = "lat"
 atm_xc_in&lat = atm_yc_in(:,0)
 atm_xc_in!1 = "lon"
 atm_xc_in&lon = atm_xc_in(0,:)
 atm_yc_in!0 = "lat"
 atm_yc_in&lat = atm_yc_in(:,0)
 atm_yc_in!1 = "lon"
 atm_yc_in&lon = atm_xc_in(0,:)

 atm_area_in = in2->area
 atm_area_in!0 = "lat"
 atm_area_in&lat = atm_yc_in(:,0)
 atm_area_in!1 = "lon"
 atm_area_in&lon = atm_xc_in(0,:)

 atm_xv_in = in2->xv
 atm_xv_in!1 = "lat"
 atm_xv_in&lat = atm_yc_in(:,0)
 atm_xv_in!2 = "lon"
 atm_xv_in&lon = atm_xc_in(0,:)

 atm_yv_in = in2->yv
 atm_yv_in!1 = "lat"
 atm_yv_in&lat = atm_yc_in(:,0)
 atm_yv_in!2 = "lon"
 atm_yv_in&lon = atm_xc_in(0,:)

 atm_mask_in = in2->mask
 atm_mask_in!0 = "lat"
 atm_mask_in&lat = atm_yc_in(:,0)
 atm_mask_in!1 = "lon"
 atm_mask_in&lon = atm_xc_in(0,:)

; Prepare output arrays
 atm_xc_out   = new((/1,maxcnt/),double,"No_FillValue")
 copy_VarAtts(atm_xc_in,atm_xc_out)
 atm_yc_out   = new((/1,maxcnt/),double,"No_FillValue")
 copy_VarAtts(atm_yc_in,atm_yc_out)
 atm_area_out = new((/1,maxcnt/),double,"No_FillValue")
 copy_VarAtts(atm_area_in,atm_area_out)
 atm_xv_out   = new((/4,1,maxcnt/),double,"No_FillValue")
 copy_VarAtts(atm_xv_in,atm_xv_out)
 atm_yv_out   = new((/4,1,maxcnt/),double,"No_FillValue")
 copy_VarAtts(atm_yv_in,atm_yv_out)
 atm_mask_out = new((/1,maxcnt/),integer,"No_FillValue")
 copy_VarAtts(atm_mask_in,atm_mask_out)
 atm_xc_out!0 = "nj"
 atm_xc_out!1 = "ni"
 copy_VarCoords(atm_xc_out,atm_yc_out)
 copy_VarCoords(atm_xc_out,atm_area_out)
 atm_xv_out!0 = "nv"
 atm_xv_out!1 = "nj"
 atm_xv_out!2 = "ni"
 copy_VarCoords(atm_xv_out,atm_yv_out)
 copy_VarCoords(atm_xc_out,atm_mask_out)
 
; Open cluster analysis file for read
 in3 = addfile(cluster_filename,"r")
 rcent_coords = in3->rcent_coords
 printVarSummary(rcent_coords)
 rcent_lon = rcent_coords(:,0)
 rcent_lat = rcent_coords(:,1)

; Fill coordinate, mask, and area arrays
 do c = 0,maxcnt-1
;   print(rcent_lon(c))
;   print(rcent_lat(c))
    if (rcent_lon(c) .eq. 0.) then
      rcent_lon(c) = 0.25
    end if
    atm_mask_out(0,c) = 1
    atm_xc_out(0,c)   = (/atm_xc_in({rcent_lat(c)},{rcent_lon(c)})/)
    atm_yc_out(0,c)   = (/atm_yc_in({rcent_lat(c)},{rcent_lon(c)})/)
    atm_area_out(0,c) = (/atm_area_in({rcent_lat(c)},{rcent_lon(c)})/)
    atm_xv_out(:,0,c) = (/atm_xv_in(:,{rcent_lat(c)},{rcent_lon(c)})/)
    atm_yv_out(:,0,c) = (/atm_yv_in(:,{rcent_lat(c)},{rcent_lon(c)})/)
 end do

; Create the new domain file
 if (create_atm_domain_filename_new) then

 system("/bin/rm -f " + atm_domain_filename_new)

 setfileoption("nc","Format","LargeFile")

 cdf_file_out = addfile(atm_domain_filename_new,"c")

 setfileoption(cdf_file_out,"DefineMode",True)

 fAtt = True
 fAtt@username = "oleson"
 fAtt@case_title = "GSWP3 3-Hourly Atmospheric Forcing"
 fileattdef(cdf_file_out,fAtt)

 dimNames = (/"scalar","ni","nj","nv"/)
 dimSizes = (/1,maxcnt,1,4/)
 dimUnlim = (/False,False,False,False/)
 filedimdef(cdf_file_out,dimNames,dimSizes,dimUnlim)

 print(typeof(atm_xc_out))
 print(getvardims(atm_xc_out))
 filevardef(cdf_file_out,"xc",typeof(atm_xc_out),getvardims(atm_xc_out))
 filevardef(cdf_file_out,"yc",typeof(atm_yc_out),getvardims(atm_yc_out))
 filevardef(cdf_file_out,"xv",typeof(atm_xv_out),getvardims(atm_xv_out))
 filevardef(cdf_file_out,"yv",typeof(atm_yv_out),getvardims(atm_yv_out))
 filevardef(cdf_file_out,"mask",typeof(atm_mask_out),getvardims(atm_mask_out))
 filevardef(cdf_file_out,"area",typeof(atm_area_out),getvardims(atm_area_out))

 filevarattdef(cdf_file_out,"xc",atm_xc_out)
 filevarattdef(cdf_file_out,"yc",atm_yc_out)
 filevarattdef(cdf_file_out,"xv",atm_xv_out)
 filevarattdef(cdf_file_out,"yv",atm_yv_out)
 filevarattdef(cdf_file_out,"mask",atm_mask_out)
 filevarattdef(cdf_file_out,"area",atm_area_out)

 setfileoption(cdf_file_out,"DefineMode",False)

 cdf_file_out->xc = (/atm_xc_out/)
 cdf_file_out->yc = (/atm_yc_out/)
 cdf_file_out->xv = (/atm_xv_out/)
 cdf_file_out->yv = (/atm_yv_out/)
 cdf_file_out->mask = (/atm_mask_out/)
 cdf_file_out->area = (/atm_area_out/)

 end if

; Now extract datm data and write to new files

; This is the corrected (QBOT) GSWP3 input data
 src_dir = "/project/projectdirs/e3sm/inputdata/atm/datm7/atm_forcing.datm7.GSWP3.0.5d.v1.c170516/"
 var_dir = (/"Precip/","Solar/","TPHWL/"/)
 var_name = (/"Prec","Solr","TPQWL"/)
 file_name = "clmforc.GSWP3.c2011.0.5x0.5."
 
; Create the output directories
 src_dir_out = "/global/cscratch1/sd/jneedham/sparse_grid/atm_forcing.datm7.GSWP3.0.5d.v1.c"+currdate+"_"+maxcnt+"/"
 system("mkdir -p "+src_dir_out)
 system("mkdir -p "+src_dir_out+var_dir(0))
 system("mkdir -p "+src_dir_out+var_dir(1))
 system("mkdir -p "+src_dir_out+var_dir(2))

 years = flt2string(int2flt(ispan(1901,2014,1)))
 months = (/"01","02","03","04","05","06","07","08","09","10","11","12"/)

;printVarSummary(atm_xc_out)
;printVarSummary(atm_yc_out)
;print(dble2flt(atm_xc_out(0,:)))
;print(dble2flt(atm_yc_out(0,:)))

 do y = 0,dimsizes(years)-1
   print((/"Year: "+years(y)/))
   do m = 0,dimsizes(months)-1
     print((/"Month: "+months(m)/))
     in_prec = addfile(src_dir+var_dir(0)+file_name+var_name(0)+"."+years(y)+"-"+months(m)+".nc","r")
     in_solr = addfile(src_dir+var_dir(1)+file_name+var_name(1)+"."+years(y)+"-"+months(m)+".nc","r")
     in_tpqw = addfile(src_dir+var_dir(2)+file_name+var_name(2)+"."+years(y)+"-"+months(m)+".nc","r")
     time_prec = in_prec->time
     ntim_prec = dimsizes(time_prec)
     time_solr = in_solr->time
     ntim_solr = dimsizes(time_solr)
     time_tpqw = in_tpqw->time
     ntim_tpqw = dimsizes(time_tpqw)
     longxy    = in_prec->LONGXY
     latixy    = in_prec->LATIXY
     longxy!0  = "lat"
     longxy&lat = latixy(:,0)
     longxy!1  = "lon"
     longxy&lon = longxy(0,:)
;    printVarSummary(longxy)
     latixy!0  = "lat"
     latixy&lat = latixy(:,0)
     latixy!1  = "lon"
     latixy&lon = longxy(0,:)
;    printVarSummary(latixy)
     edgee     = in_prec->EDGEE
     edgew     = in_prec->EDGEW
     edges     = in_prec->EDGES
     edgen     = in_prec->EDGEN
     prec      = in_prec->PRECTmms
     prec!0    = "time"
     prec&time = time_prec
     prec!1    = "lat"
     prec&lat  = latixy(:,0)
     prec!2    = "lon"
     prec&lon  = longxy(0,:)
     solr      = in_solr->FSDS
     solr!0    = "time"
     solr&time = time_solr
     solr!1    = "lat"
     solr&lat  = latixy(:,0)
     solr!2    = "lon"
     solr&lon  = longxy(0,:)
     t         = in_tpqw->TBOT
     t!0    = "time"
     t&time = time_tpqw
     t!1    = "lat"
     t&lat  = latixy(:,0)
     t!2    = "lon"
     t&lon  = longxy(0,:)
     p         = in_tpqw->PSRF
     p!0    = "time"
     p&time = time_tpqw
     p!1    = "lat"
     p&lat  = latixy(:,0)
     p!2    = "lon"
     p&lon  = longxy(0,:)
     q         = in_tpqw->QBOT
     q!0    = "time"
     q&time = time_tpqw
     q!1    = "lat"
     q&lat  = latixy(:,0)
     q!2    = "lon"
     q&lon  = longxy(0,:)
     w         = in_tpqw->WIND
     w!0    = "time"
     w&time = time_tpqw
     w!1    = "lat"
     w&lat  = latixy(:,0)
     w!2    = "lon"
     w&lon  = longxy(0,:)
     f         = in_tpqw->FLDS
     f!0    = "time"
     f&time = time_tpqw
     f!1    = "lat"
     f&lat  = latixy(:,0)
     f!2    = "lon"
     f&lon  = longxy(0,:)

     longxy_out = new((/1,maxcnt/),float,"No_FillValue")
     latixy_out = new((/1,maxcnt/),float,"No_FillValue")
     prec_out = new((/ntim_prec,1,maxcnt/),float)
     solr_out = new((/ntim_solr,1,maxcnt/),float)
     t_out    = new((/ntim_tpqw,1,maxcnt/),float)
     p_out    = new((/ntim_tpqw,1,maxcnt/),float)
     q_out    = new((/ntim_tpqw,1,maxcnt/),float)
     w_out    = new((/ntim_tpqw,1,maxcnt/),float)
     f_out    = new((/ntim_tpqw,1,maxcnt/),float)
     ; NCL complains here about "warning:Dimension (0) has not been defined", harmless here.
     ; May have something to do with the dble2flt but that function is supposed to preserve metadata.
     do i = 0,maxcnt-1
       longxy_out(0,i) = longxy({dble2flt(atm_yc_out(0,i))},{dble2flt(atm_xc_out(0,i))})
       latixy_out(0,i) = latixy({dble2flt(atm_yc_out(0,i))},{dble2flt(atm_xc_out(0,i))})
       prec_out(:,0,i) = prec(:,{dble2flt(atm_yc_out(0,i))},{dble2flt(atm_xc_out(0,i))})
       solr_out(:,0,i) = solr(:,{dble2flt(atm_yc_out(0,i))},{dble2flt(atm_xc_out(0,i))})
       t_out(:,0,i)    = t(:,{dble2flt(atm_yc_out(0,i))},{dble2flt(atm_xc_out(0,i))})
       p_out(:,0,i)    = p(:,{dble2flt(atm_yc_out(0,i))},{dble2flt(atm_xc_out(0,i))})
       q_out(:,0,i)    = q(:,{dble2flt(atm_yc_out(0,i))},{dble2flt(atm_xc_out(0,i))})
       w_out(:,0,i)    = w(:,{dble2flt(atm_yc_out(0,i))},{dble2flt(atm_xc_out(0,i))})
       f_out(:,0,i)    = f(:,{dble2flt(atm_yc_out(0,i))},{dble2flt(atm_xc_out(0,i))})
     end do

     ; Write the precipitation file
     system("/bin/rm -f " + src_dir_out+var_dir(0)+file_name+var_name(0)+"."+years(y)+"-"+months(m)+".nc")
     setfileoption("nc","Format","LargeFile")
     cdf_file_out = addfile(src_dir_out+var_dir(0)+file_name+var_name(0)+"."+years(y)+"-"+months(m)+".nc","c")
     setfileoption(cdf_file_out,"DefineMode",True)

     fAtt = True
     fAtt@username = "oleson"
     fAtt@case_title = "GSWP3 3-Hourly Atmospheric Forcing: Precipitation."
     fileattdef(cdf_file_out,fAtt)

     dimNames = (/"scalar","lat","lon","time"/)
     dimSizes = (/1,1,maxcnt,ntim_prec/)
     dimUnlim = (/False,False,False,True/)
     filedimdef(cdf_file_out,dimNames,dimSizes,dimUnlim)

     filevardef(cdf_file_out,"time",typeof(time_prec),getvardims(time_prec))
     filevardef(cdf_file_out,"LONGXY",typeof(longxy),getvardims(longxy))
     filevardef(cdf_file_out,"LATIXY",typeof(latixy),getvardims(latixy))
     filevardef(cdf_file_out,"EDGEE",typeof(edgee),getvardims(edgee))
     filevardef(cdf_file_out,"EDGEW",typeof(edgew),getvardims(edgew))
     filevardef(cdf_file_out,"EDGES",typeof(edges),getvardims(edges))
     filevardef(cdf_file_out,"EDGEN",typeof(edgen),getvardims(edgen))
     filevardef(cdf_file_out,"PRECTmms",typeof(prec_out),getvardims(prec_out))

     filevarattdef(cdf_file_out,"time",time_prec)
     filevarattdef(cdf_file_out,"LONGXY",longxy)
     filevarattdef(cdf_file_out,"LATIXY",latixy)
     filevarattdef(cdf_file_out,"EDGEE",edgee)
     filevarattdef(cdf_file_out,"EDGEW",edgew)
     filevarattdef(cdf_file_out,"EDGES",edges)
     filevarattdef(cdf_file_out,"EDGEN",edgen)
     filevarattdef(cdf_file_out,"PRECTmms",prec_out)

     setfileoption(cdf_file_out,"DefineMode",False)

     cdf_file_out->time   = (/time_prec/)
     cdf_file_out->LONGXY = (/longxy_out/)
     cdf_file_out->LATIXY = (/latixy_out/)
     cdf_file_out->EDGEE  = (/edgee/)
     cdf_file_out->EDGEW  = (/edgew/)
     cdf_file_out->EDGES  = (/edges/)
     cdf_file_out->EDGEN  = (/edgen/)
     cdf_file_out->PRECTmms = (/prec_out/)

     ; Write the solar file
     system("/bin/rm -f " + src_dir_out+var_dir(1)+file_name+var_name(1)+"."+years(y)+"-"+months(m)+".nc")
     setfileoption("nc","Format","LargeFile")
     cdf_file_out = addfile(src_dir_out+var_dir(1)+file_name+var_name(1)+"."+years(y)+"-"+months(m)+".nc","c")
     setfileoption(cdf_file_out,"DefineMode",True)

     fAtt = True
     fAtt@username = "oleson"
     fAtt@case_title = "GSWP3 3-Hourly Atmospheric Forcing: Incoming Solar."
     fileattdef(cdf_file_out,fAtt)

     dimNames = (/"scalar","lat","lon","time"/)
     dimSizes = (/1,1,maxcnt,ntim_solr/)
     dimUnlim = (/False,False,False,True/)
     filedimdef(cdf_file_out,dimNames,dimSizes,dimUnlim)

     filevardef(cdf_file_out,"time",typeof(time_solr),getvardims(time_solr))
     filevardef(cdf_file_out,"LONGXY",typeof(longxy),getvardims(longxy))
     filevardef(cdf_file_out,"LATIXY",typeof(latixy),getvardims(latixy))
     filevardef(cdf_file_out,"EDGEE",typeof(edgee),getvardims(edgee))
     filevardef(cdf_file_out,"EDGEW",typeof(edgew),getvardims(edgew))
     filevardef(cdf_file_out,"EDGES",typeof(edges),getvardims(edges))
     filevardef(cdf_file_out,"EDGEN",typeof(edgen),getvardims(edgen))
     filevardef(cdf_file_out,"FSDS",typeof(solr_out),getvardims(solr_out))

     filevarattdef(cdf_file_out,"time",time_solr)
     filevarattdef(cdf_file_out,"LONGXY",longxy)
     filevarattdef(cdf_file_out,"LATIXY",latixy)
     filevarattdef(cdf_file_out,"EDGEE",edgee)
     filevarattdef(cdf_file_out,"EDGEW",edgew)
     filevarattdef(cdf_file_out,"EDGES",edges)
     filevarattdef(cdf_file_out,"EDGEN",edgen)
     filevarattdef(cdf_file_out,"FSDS",solr_out)

     setfileoption(cdf_file_out,"DefineMode",False)

     cdf_file_out->time   = (/time_solr/)
     cdf_file_out->LONGXY = (/longxy_out/)
     cdf_file_out->LATIXY = (/latixy_out/)
     cdf_file_out->EDGEE  = (/edgee/)
     cdf_file_out->EDGEW  = (/edgew/)
     cdf_file_out->EDGES  = (/edges/)
     cdf_file_out->EDGEN  = (/edgen/)
     cdf_file_out->FSDS   = (/solr_out/)

     ; Write the tpqw file
     system("/bin/rm -f " + src_dir_out+var_dir(2)+file_name+var_name(2)+"."+years(y)+"-"+months(m)+".nc")
     setfileoption("nc","Format","LargeFile")
     cdf_file_out = addfile(src_dir_out+var_dir(2)+file_name+var_name(2)+"."+years(y)+"-"+months(m)+".nc","c")
     setfileoption(cdf_file_out,"DefineMode",True)

     fAtt = True
     fAtt@username = "oleson"
     fAtt@case_title = "GSWP3 3-Hourly Atmospheric Forcing: Precipitation.  Missing values for Wind filled with 1948 Qian data interpolated by datm to GSWP3 grid."
     fileattdef(cdf_file_out,fAtt)

     dimNames = (/"scalar","lat","lon","time"/)
     dimSizes = (/1,1,maxcnt,ntim_tpqw/)
     dimUnlim = (/False,False,False,True/)
     filedimdef(cdf_file_out,dimNames,dimSizes,dimUnlim)

     filevardef(cdf_file_out,"time",typeof(time_tpqw),getvardims(time_tpqw))
     filevardef(cdf_file_out,"LONGXY",typeof(longxy),getvardims(longxy))
     filevardef(cdf_file_out,"LATIXY",typeof(latixy),getvardims(latixy))
     filevardef(cdf_file_out,"EDGEE",typeof(edgee),getvardims(edgee))
     filevardef(cdf_file_out,"EDGEW",typeof(edgew),getvardims(edgew))
     filevardef(cdf_file_out,"EDGES",typeof(edges),getvardims(edges))
     filevardef(cdf_file_out,"EDGEN",typeof(edgen),getvardims(edgen))
     filevardef(cdf_file_out,"PSRF",typeof(p_out),getvardims(p_out))
     filevardef(cdf_file_out,"TBOT",typeof(t_out),getvardims(t_out))
     filevardef(cdf_file_out,"WIND",typeof(w_out),getvardims(w_out))
     filevardef(cdf_file_out,"QBOT",typeof(q_out),getvardims(q_out))
     filevardef(cdf_file_out,"FLDS",typeof(f_out),getvardims(f_out))

     filevarattdef(cdf_file_out,"time",time_tpqw)
     filevarattdef(cdf_file_out,"LONGXY",longxy)
     filevarattdef(cdf_file_out,"LATIXY",latixy)
     filevarattdef(cdf_file_out,"EDGEE",edgee)
     filevarattdef(cdf_file_out,"EDGEW",edgew)
     filevarattdef(cdf_file_out,"EDGES",edges)
     filevarattdef(cdf_file_out,"EDGEN",edgen)
     filevarattdef(cdf_file_out,"PSRF",p_out)
     filevarattdef(cdf_file_out,"TBOT",t_out)
     filevarattdef(cdf_file_out,"WIND",w_out)
     filevarattdef(cdf_file_out,"QBOT",q_out)
     filevarattdef(cdf_file_out,"FLDS",f_out)

     setfileoption(cdf_file_out,"DefineMode",False)

     cdf_file_out->time   = (/time_tpqw/)
     cdf_file_out->LONGXY = (/longxy_out/)
     cdf_file_out->LATIXY = (/latixy_out/)
     cdf_file_out->EDGEE  = (/edgee/)
     cdf_file_out->EDGEW  = (/edgew/)
     cdf_file_out->EDGES  = (/edges/)
     cdf_file_out->EDGEN  = (/edgen/)
     cdf_file_out->PSRF   = (/p_out/)
     cdf_file_out->TBOT   = (/t_out/)
     cdf_file_out->WIND   = (/w_out/)
     cdf_file_out->QBOT   = (/q_out/)
     cdf_file_out->FLDS   = (/f_out/)

     delete(longxy)
     delete(latixy)
     delete(time_prec)
     delete(time_solr)
     delete(time_tpqw)
     delete(prec)
     delete(solr)
     delete(t)
     delete(p)
     delete(q)
     delete(w)
     delete(f)
     delete(prec_out)
     delete(solr_out)
     delete(t_out)
     delete(p_out)
     delete(q_out)
     delete(w_out)
     delete(f_out)
   end do
 end do

 print ("=========================================")
 print ("Finish Time: "+systemfunc("date") )
 print ("=========================================")

end
