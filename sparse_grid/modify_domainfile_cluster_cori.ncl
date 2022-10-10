; NCL script
; modify_domainfile_cluster.ncl
; Keith Oleson, Dec 2020
; This script creates a 1.9x2.5 sparse grid domain file for use with CLM
; The sparse grid is defined by a file created by the Forrest Hoffman/Nate Collier cluster analysis for PPE

; Modified for use on cori by Jessica Needham Oct 2022

;**************************************

begin

 print ("=========================================")
 print ("Start Time: "+systemfunc("date") )
 print ("=========================================")

 maxcnt = 400
 
domain_filename_orig = "/global/homes/j/jneedham/sparse_grid/domain.lnd.fv1.9x2.5_gx1v7.181205.nc"

; This is for output_v4 version (final)
domain_filename_new  = "/global/homes/j/jneedham/sparse_grid/domain.lnd.fv1.9x2.5_gx1v6.090206.sparse"+maxcnt+".nc"

system("/bin/cp -f " + domain_filename_orig + " " + domain_filename_new)
system("chmod u+w " + domain_filename_new)

; Cluster analysis file (produced by Forrest Hoffman/Nate Collier for PPE)
; This is for output_v4 version (final)
cluster_filename = "/global/homes/j/jneedham/sparse_grid/clusters.clm51_PPEn02ctsm51d021_2deg_GSWP3V1_leafbiomassesai_PPE3_hist.annual.sd.400.nc"

; Open new domain file for write
 in1 = addfile(domain_filename_new,"w")
 mask_in = in1->mask
 frac_in = in1->frac
 nj = dimsizes(mask_in(:,0))
 ni = dimsizes(mask_in(0,:))
 xc_in = in1->xc
 yc_in = in1->yc

; Open cluster analysis file for read
 in2 = addfile(cluster_filename,"r")
 rcent_coords = in2->rcent_coords
 printVarSummary(rcent_coords)
 rcent_lon = rcent_coords(:,0)
 rcent_lat = rcent_coords(:,1)

 mask_out = mask_in
 mask_out = 0
 frac_out = frac_in
 frac_out = 0.d

 mask_out!0 = "nj"
 mask_out&nj = yc_in(:,0)
 mask_out!1 = "ni"
 mask_out&ni = xc_in(0,:)
 copy_VarCoords(mask_out,frac_out)
 copy_VarCoords(frac_out,frac_in)

 do c = 0,maxcnt-1
;   print(rcent_lon(c))
;   print(rcent_lat(c))
    mask_out({rcent_lat(c)},{rcent_lon(c)}) = 1
    frac_out({rcent_lat(c)},{rcent_lon(c)}) = frac_in({rcent_lat(c)},{rcent_lon(c)})
 end do

 in1->mask = mask_out
 in1->frac = frac_out

 print ("=========================================")
 print ("Finish Time: "+systemfunc("date") )
 print ("=========================================")

end
