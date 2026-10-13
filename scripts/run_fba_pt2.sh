#!/bin/bash
set -e

BASE_DIR="/home/cookies/Downloads/260731_proj-mirocals"
DERIV_DIR="${BASE_DIR}/derivatives"
TEMPLATE_DIR="${DERIV_DIR}/template"

#Defining the output directories file paths
TEMPLATE_FOD="${TEMPLATE_DIR}/wmfod_template.mif"
TEMPLATE_MASK="${TEMPLATE_DIR}/template_mask.mif"
TEMPLATE_FIXEL_DIR="${TEMPLATE_DIR}/fixels"
STATS_DIR="${DERIV_DIR}/stats"
FIXEL_IN_TEMPLATE="${STATS_DIR}/template_fixels"

#Statistical design & contrast files
DESIGN_MATRIX="${STATS_DIR}/design_matrix.txt"
CONTRAST_MATRIX="${STATS_DIR}/contrast_matrix.txt"

echo "Segmenting the population template FOD into template fixels"

#delete the old template fixels folder automatically if it exists
rm -rf "${TEMPLATE_FIXEL_DIR}"

#Creating template fixel directory and segment template FOD

mkdir -p "${TEMPLATE_FIXEL_DIR}"

#Segment template FOD into template fixels 
fod2fixel "${TEMPLATE_FOD}" "${TEMPLATE_FIXEL_DIR}" \
    -mask "${TEMPLATE_MASK}" \
    -fmls_peak_value 0.06

#Final Part: FIxel Processing and extracting metrics

echo "Processing subject fixels, reorientation, and metric calculations..."

#Preparing the stats directory and copy template fixel directory
mkdir -p "${STATS_DIR}"
cp -r "${TEMPLATE_FIXEL_DIR}" "${FIXEL_IN_TEMPLATE}"

mkdir -p "${FIXEL_IN_TEMPLATE}/fd"
mkdir -p "${FIXEL_IN_TEMPLATE}/fc"
mkdir -p "${FIXEL_IN_TEMPLATE}/log_fc"
mkdir -p "${FIXEL_IN_TEMPLATE}/fdc"


for SUB_DIR in ${BASE_DIR}/rawdata/sub-*; do
  if [ -d "${SUB_DIR}" ]; then
    for SES_DIR in "${SUB_DIR}"/ses-*; do
      if [ -d "${SES_DIR}" ]; then
            
	SUB=$(basename "${SUB_DIR}")
        SES=$(basename "${SES_DIR}")
	
	INPUT_DIR="${DERIV_DIR}/input/${SUB}/${SES}"
	
	if [ -d "${INPUT_DIR}" ]; then
	echo "processing fixel metrics for: ${SUB} | ${SES}"
	
	 SUBJECT_FOD="${INPUT_DIR}/${SUB}_${SES}_fod_wm_norm.mif" 
         SUBJECT_WARP="${INPUT_DIR}/${SUB}_${SES}_subject2template_warp.mif" 
         SUBJECT_FIXEL_DIR="${INPUT_DIR}/fixels"
         SUBJECT_FOD_REORIENTED="${INPUT_DIR}/${SUB}_${SES}_fod_wm_norm_reoriented.mif"
         SUBJECT_FOD_NOT_REORIENTED="${INPUT_DIR}/${SUB}_${SES}_fod_wm_norm_not_reoriented.mif"
         
         
         OUT_FD="${FIXEL_IN_TEMPLATE}/fd/${SUB}_${SES}.mif" 
         OUT_FC="${FIXEL_IN_TEMPLATE}/fc/${SUB}_${SES}.mif" 
         OUT_LOG_FC="${FIXEL_IN_TEMPLATE}/log_fc/${SUB}_${SES}.mif" 
         OUT_FDC="${FIXEL_IN_TEMPLATE}/fdc/${SUB}_${SES}.mif"
         
rm -rf "${SUBJECT_FIXEL_DIR}"
mkdir -p "${SUBJECT_FIXEL_DIR}"
mrtransform "${SUBJECT_FOD}" \
	-warp "${SUBJECT_WARP}" \
	-reorient_fod no \
	"${SUBJECT_FOD_NOT_REORIENTED}" \
	-force
  					
fod2fixel "${SUBJECT_FOD_NOT_REORIENTED}" "${SUBJECT_FIXEL_DIR}" \
-mask "${TEMPLATE_MASK}" \
-fmls_peak_value 0.06 \
-force

fixelreorient "${SUBJECT_FIXEL_DIR}" \
		"${SUBJECT_WARP}" \
		"${SUBJECT_FIXEL_DIR}" \
		-force
		
 #Assign subject FD to template fixels
 fixelcorrespondence "${SUBJECT_FIXEL_DIR}" "${FIXEL_IN_TEMPLATE}" \
 "${FIXEL_IN_TEMPLATE}/fd" "${SUB}_${SES}.mif" \
 -force

#Extracting FC:

          warp2metric "${SUBJECT_WARP}" -fc "${FIXEL_IN_TEMPLATE}" "${OUT_FC}" \
          -force
            
#Calculate log(FC) for linear statistical modeling 

          mrcalc "${OUT_FC}" -log "${OUT_LOG_FC}" \
          -force

#Calculate FDC (FD * FC) 

	  mrcalc "${OUT_FD}" "${OUT_FC}" -mult "${OUT_FDC}" \
	  -force

          echo "Completed metrics for: ${SUB} | ${SES}" 

        fi 

      fi 

    done 

  fi 

done 


#Generating whole brain tractogram:
echo "generating whole brain tractogram"
tckgen -angle 22.5 -maxlen 250 -minlen 10 -power 1.0 \
"${TEMPLATE_FOD}" \
-seed_image "${TEMPLATE_MASK}" \
-mask "${TEMPLATE_MASK}" \
-select 1000000 \
-cutoff 0.06 \
"${STATS_DIR}/tracks_1_million.tck" \
-force

#Reduce bias in tractogram densities:
echo "filtering tractogram with SIFT..."
tcksift "${STATS_DIR}/tracks_1_million.tck" "${TEMPLATE_FOD}" "${STATS_DIR}/tracks_500_thousand_sift.tck" -term_number 500000 \
-force

echo "generating fixel-fixel connectivity matrix..."
fixelconnectivity "${FIXEL_IN_TEMPLATE}" "${STATS_DIR}/tracks_500_thousand_sift.tck" \
"${STATS_DIR}/matrix/" \
-force

echo "smoothing the fixel metrics..."
fixelfilter "${FIXEL_IN_TEMPLATE}/fd" smooth \
"${FIXEL_IN_TEMPLATE}/fd_smooth" -matrix "${STATS_DIR}/matrix/" \
-force

fixelfilter "${FIXEL_IN_TEMPLATE}/log_fc" smooth \
"${FIXEL_IN_TEMPLATE}/log_fc_smooth" \
-matrix "${STATS_DIR}/matrix/" \
-force

fixelfilter "${FIXEL_IN_TEMPLATE}/fdc" smooth \
"${FIXEL_IN_TEMPLATE}/fdc_smooth" -matrix "${STATS_DIR}/matrix/" \
-force

echo "pipeline completed through fixelfilter. ready to generate the statistical matrices"

#Statistical Analysis (fixelcfestats)
#echo "running statistical testing..."
#echo "----------------------------------------------------------------------------------------------------------------------------------------"

#if [[-f"${DESIGN_MATRIX}" && -f"${CONTRAST_MATRIX}" ]]; then
	
	#echo "running CFE stats for FD..."
	#fixelcfestats "${FIXEL_IN_TEMPLATE}/fd_smooth"\
			#"${DESIGN_MATRIX}"\
			#"${CONTRAST_MATRIX}"\
			#"${STATS_DIR}/matrix/"\
			#"${STATS_DIR}/stats_fd"
	
	
	#echo "running CFE stats for log_FC..."
	#fixelcfestats "${FIXEL_IN_TEMPLATE}/log_fc_smooth"\
			#"${DESIGN_MATRIX}"\
			#"${CONTRAST_MATRIX}"\
			#"${STATS_DIR}/matrix/"\
			#"${STATS_DIR}/stats_log_fc"
	
	#echo "running CFE stats for FDC..."
	#fixelcfestats "${FIXEL_IN_TEMPLATE}/fdc_smooth"\
			#"${DESIGN_MATRIX}"\
			#"${CONTRAST_MATRIX}"\
			#"${STATS_DIR}/matrix/"\
			#"${STATS_DIR}/stats_fdc"
			
#else 
	#echo "WARNING: ${DESIGN_MATriX} or ${CONTRAST_MATRIX} not found in ${STATS_DIR}"
	#echo "pipeline paused before dixelecfestats. Please create design_matrix.txt and contrast_matrix.txt, then rerun statistical testing"
			

   



