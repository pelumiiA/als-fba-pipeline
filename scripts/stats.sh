#!/bin/bash

BASE_DIR="/home/cookies/Downloads/260731_proj-mirocals"
DERIV_DIR="${BASE_DIR}/derivatives"
TEMPLATE_DIR="${DERIV_DIR}/template"

TRACKS="${DERIV_DIR}/tracks"
META="${DERIV_DIR}/meta"
PARAMS="${DERIV_DIR}/params"
STATS="${DERIV_DIR}/stats"


#for param in fd fdc log_fc; do

	#echo "smoothing the fixel metrics..."
	#fixelfilter "${PARAMS}/${param}/" smooth \
	#"${PARAMS}/${param}_smooth" -matrix "${TEMPLATE_DIR}/matrix/" \
	#-force
#done



#echo "pipeline completed through fixelfilter. ready to generate the statistical matrices"


mkdir -p "${STATS}" 
[[ -f "${META}/design_h1.txt" && -f "${META}/contrast_h1.txt" ]] || continue

for param in fd fdc log_fc; do	
	echo "running CFE stats for ${param}..."
	fixelcfestats "${PARAMS}/${param}_smooth"\
			"${META}/files_h1.txt"\
			"${META}/design_h1.txt"\
			"${META}/contrast_h1.txt"\
			"${TEMPLATE_DIR}/matrix/" \
			"${STATS}/${param}" \
			-nshuffles 5
done
