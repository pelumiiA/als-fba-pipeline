#!/bin/bash 

set -e 

 

STATS_DIR="/home/cookies/Downloads/260731_proj-mirocals/derivatives/stats" 

 

# Header 

echo "metric,hypothesis,contrast,label,mean_pct_effect,mean_std_effect,mean_std_lower,mean_std_upper,n_sig_fixels" 

 

extract_one () { 

  METRIC=$1 

  HYP=$2 

  DESIGN=$3 

  TNUM=$4 

  LABEL=$5 

 

  DIR="${STATS_DIR}/${METRIC}/${HYP}/${DESIGN}" 

  FWE_FILE="${DIR}/fwe_1mpvalue_t${TNUM}.mif" 

  PCT_FILE="${DIR}/pct_t${TNUM}.mif" 

  STD_FILE="${DIR}/std_effect_t${TNUM}.mif" 

  STD_LOWER_FILE="${DIR}/std_effect_lower_t${TNUM}.mif" 

  STD_UPPER_FILE="${DIR}/std_effect_upper_t${TNUM}.mif" 

 

  if [ ! -f "${FWE_FILE}" ]; then 

    echo "WARNING: ${FWE_FILE} not found, skipping" >&2 

    return 

  fi 

 

  TMP_MASK=$(mktemp --suffix=.mif) 

  mrthreshold "${FWE_FILE}" -abs 0.95 "${TMP_MASK}" -force 

 

  NSIG=$(mrstats "${TMP_MASK}" -mask "${TMP_MASK}" -output count) 

 

  PCT_MEAN="NA" 

  if [ -f "${PCT_FILE}" ]; then 

    VAL=$(mrstats "${PCT_FILE}" -mask "${TMP_MASK}" -output mean) 

    [ -n "${VAL}" ] && [ "${VAL}" != "NA" ] && PCT_MEAN=$(awk -v v="${VAL}" 'BEGIN {print -v}') 

  fi 

 

  STD_MEAN="NA" 

  if [ -f "${STD_FILE}" ]; then 

    VAL=$(mrstats "${STD_FILE}" -mask "${TMP_MASK}" -output mean) 

    [ -n "${VAL}" ] && [ "${VAL}" != "NA" ] && STD_MEAN=$(awk -v v="${VAL}" 'BEGIN {print -v}') 

  fi 

 

  RAW_LOWER="NA" 

  if [ -f "${STD_LOWER_FILE}" ]; then 

    VAL=$(mrstats "${STD_LOWER_FILE}" -mask "${TMP_MASK}" -output mean) 

    [ -n "${VAL}" ] && [ "${VAL}" != "NA" ] && RAW_LOWER=$(awk -v v="${VAL}" 'BEGIN {print -v}') 

  fi 

 

  RAW_UPPER="NA" 

  if [ -f "${STD_UPPER_FILE}" ]; then 

    VAL=$(mrstats "${STD_UPPER_FILE}" -mask "${TMP_MASK}" -output mean) 

    [ -n "${VAL}" ] && [ "${VAL}" != "NA" ] && RAW_UPPER=$(awk -v v="${VAL}" 'BEGIN {print -v}') 

  fi 

 

  rm -f "${TMP_MASK}" 

 

  # Swapping lower and upper bounds because negating flips their order (e.g. -0.2 becomes smaller than -0.8) 

  STD_LOWER="${RAW_UPPER}" 

  STD_UPPER="${RAW_LOWER}" 

 

  echo "${METRIC},${HYP},t${TNUM},\"${LABEL}\",${PCT_MEAN},${STD_MEAN},${STD_LOWER},${STD_UPPER},${NSIG}" 

} 

 

for METRIC in fd fdc logfc; do 

  extract_one "${METRIC}" "h1" "ptcvctr" 3 "ALS baseline vs Control" 

  extract_one "${METRIC}" "h1" "ptcvctr" 4 "ALS follow-up vs Control" 

  extract_one "${METRIC}" "h2" "ptcvptc" 2 "ALS follow-up vs ALS baseline" 

done 
