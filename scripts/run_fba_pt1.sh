#!/bin/bash

BASE_DIR="/home/cookies/Downloads/260731_proj-mirocals"
DERIV_DIR="${BASE_DIR}/derivatives"
RAW_DIR="${BASE_DIR}/rawdata"

if [ ! -d "${BASE_DIR}" ]; then
    echo "Error: Directory '$BASE_DIR' does not exist."
    exit 1
fi


#Part 1: Preprocessing & Individual Response Function Estimation

for SUB_DIR in ${BASE_DIR}/rawdata/sub-*; do
  if [ -d "${SUB_DIR}" ]; then
    for SES_DIR in "${SUB_DIR}"/ses-*; do
      if [ -d "${SES_DIR}" ]; then
				
				SUB=$(basename "${SUB_DIR}")
				SES=$(basename "${SES_DIR}")
				
				TARGET_DIR="${RAW_DIR}/${SUB}/${SES}/dwi"
				INPUT_DIR="${DERIV_DIR}/input/${SUB}/${SES}"
				
				echo $TARGET_DIR 
				if [ -d "$TARGET_DIR" ]; then
          echo "Processing Part 1: $(basename "${SUB}") | $(basename "${SES}")"
          
					mkdir -p "${INPUT_DIR}"

		#Definfing Outputs 
		  
		  NOISY="${INPUT_DIR}/${SUB}_${SES}_concat_raw.mif"
          DENOISED="${INPUT_DIR}/${SUB}_${SES}_denoised.mif"
          DERINGED="${INPUT_DIR}/${SUB}_${SES}_deringed.mif"
			PREPROC="${INPUT_DIR}/${SUB}_${SES}_preproc.mif"
          UNBIASED="${INPUT_DIR}/${SUB}_${SES}_unbiased.mif"

		  UPSAMPLED="${INPUT_DIR}/${SUB}_${SES}_multi_upsampled.mif"
          UPSAMPLED_MASK="${INPUT_DIR}/${SUB}_${SES}_multi_upsampled_mask.mif"
	        
          # Output Response Files               
	        RESPONSE_WM="${INPUT_DIR}/${SUB}_${SES}_response_wm.txt"
					RESPONSE_GM="${INPUT_DIR}/${SUB}_${SES}_response_gm.txt"
					RESPONSE_CSF="${INPUT_DIR}/${SUB}_${SES}_response_csf.txt"
					
          for BVAL in "b800" "b2400"; do
						
						mrconvert \
							-fslgrad "${TARGET_DIR}/${SUB}_${SES}_acq-${BVAL}_dwi.bvec" \
                			"${TARGET_DIR}/${SUB}_${SES}_acq-${BVAL}_dwi.bval" \
                			"${TARGET_DIR}/${SUB}_${SES}_acq-${BVAL}_dwi.nii.gz" \
               				"${INPUT_DIR}/${SUB}_${SES}_acq-${BVAL}_dwi.mif" 
			done

			#Concatenate shells before processing
            mrcat "${INPUT_DIR}/${SUB}_${SES}_acq-b800_dwi.mif" \
                  "${INPUT_DIR}/${SUB}_${SES}_acq-b2400_dwi.mif" \
                  "${NOISY}" 

						dwidenoise "${NOISY}" "${DENOISED}" 
						mrdegibbs "${DENOISED}" "$DERINGED" 
						dwifslpreproc "${DERINGED}" "${PREPROC}" -rpe_none -pe_dir j- -eddy_options " --slm=linear"
            			dwibiascorrect ants "${PREPROC}" "${UNBIASED}" 

						mrgrid "${UNBIASED}" regrid -vox 1.25 "${UPSAMPLED}" 
            			dwi2mask "${UPSAMPLED}" "${UPSAMPLED_MASK}" 

						#The tissue response functions
	        			dwi2response dhollander "${UPSAMPLED}" "$RESPONSE_WM" "$RESPONSE_GM" "$RESPONSE_CSF" \
              			-mask "${UPSAMPLED_MASK}"  	

						echo "Finished Part 1 for ${SUB} successfully!"
        			
        			
				fi
			fi
		done
	fi
done


# GROUP AVERAGE RESPONSE FUNCTIONS 

echo "Calculating group average response functions..."
#Defining the outputs
WM_AVG="${DERIV_DIR}/group_average_response_wm.txt"
GM_AVG="${DERIV_DIR}/group_average_response_gm.txt"
CSF_AVG="${DERIV_DIR}/group_average_response_csf.txt"

#Average white matter response across all subjects
responsemean "${DERIV_DIR}"/input/sub-*/ses-*/sub-*_response_wm.txt "$WM_AVG"

#Average grey matter response across all subjects
responsemean "${DERIV_DIR}"/input/sub-*/ses-*/sub-*_response_gm.txt "$GM_AVG" 

#Average CSF response across all subjects
responsemean "${DERIV_DIR}"/input/sub-*/ses-*/sub-*_response_csf.txt "$CSF_AVG" 


#Part 2: CSD and Normalising the Intensity

#I copied the steps to loop through each session and subject from part 1
for SUB_DIR in ${BASE_DIR}/rawdata/sub-*; do
  if [ -d "${SUB_DIR}" ]; then
    for SES_DIR in "${SUB_DIR}"/ses-*; do
      if [ -d "${SES_DIR}" ]; then
				
				#Extracting the subject & session IDs
				SUB=$(basename "${SUB_DIR}")
				SES=$(basename "${SES_DIR}")
				
				INPUT_DIR="${DERIV_DIR}/input/${SUB}/${SES}"
				
				if [ -d "${INPUT_DIR}" ]; then
					echo "Processing Part 2: ${SUB} | ${SES}"
					
				#Defining the output file paths for merged, upsampled, and masked images
					UPSAMPLED="${INPUT_DIR}/${SUB}_${SES}_multi_upsampled.mif"
					UPSAMPLED_MASK="${INPUT_DIR}/${SUB}_${SES}_multi_upsampled_mask.mif"

				#Defining the output file paths for the tissue FOD maps
					FOD_WM="${INPUT_DIR}/${SUB}_${SES}_fod_wm.mif"
					FOD_GM="${INPUT_DIR}/${SUB}_${SES}_gm.mif"
					FOD_CSF="${INPUT_DIR}/${SUB}_${SES}_csf.mif"

				#Defining the output file paths for the normalised maps
					OUT_WM_NORM="${INPUT_DIR}/${SUB}_${SES}_fod_wm_norm.mif"
    				OUT_GM_NORM="${INPUT_DIR}/${SUB}_${SES}_gm_norm.mif"
    				OUT_CSF_NORM="${INPUT_DIR}/${SUB}_${SES}_csf_norm.mif"
				

				#Running multi shell and multi tissue CSD to generate the tissue maps
					echo "Using group averages to run multishell tissue csd..."
					dwi2fod msmt_csd "${UPSAMPLED}" \
						"${WM_AVG}" "${FOD_WM}" \
						"${GM_AVG}" "${FOD_GM}" \
						"${CSF_AVG}" "${FOD_CSF}" \
						-mask "${UPSAMPLED_MASK}" 
						

				#multi-tissue intensity normalisation
					echo "Running Intensity Normalisation"
    				mtnormalise "${FOD_WM}" "${OUT_WM_NORM}" \
               	 		"${FOD_GM}" "${OUT_GM_NORM}" \
                		"${FOD_CSF}" "${OUT_CSF_NORM}" \
                		-mask "${UPSAMPLED_MASK}" 
                		
				fi
			fi
		done
	fi
done



#Part 3: Generating the Population Template
echo "Creating Population Template..."

#Defining the output directories file paths
TEMPLATE_DIR="${DERIV_DIR}/template"
FOD_INPUT_DIR="${TEMPLATE_DIR}/fod_input"
MASK_INPUT_DIR="${TEMPLATE_DIR}/mask_input"
TEMPLATE_FOD="${TEMPLATE_DIR}/wmfod_template.mif"

#Creating directories (following the MRtrix3 steps)
mkdir -p "${FOD_INPUT_DIR}"
mkdir -p "${MASK_INPUT_DIR}"

#Linking the individual normalised FODs and masks into single input folders
for SUB_DIR in ${BASE_DIR}/rawdata/sub-*; do
  if [ -d "${SUB_DIR}" ]; then
    for SES_DIR in "${SUB_DIR}"/ses-*; do
      if [ -d "${SES_DIR}" ]; then
        SUB=$(basename "${SUB_DIR}")
        SES=$(basename "${SES_DIR}")
        
        INPUT_DIR="${DERIV_DIR}/input/${SUB}/${SES}"
        
        #Linking normalised FOD and masks into the input folder
        if [ -f "${INPUT_DIR}/${SUB}_${SES}_fod_wm_norm.mif" ]; then
            ln -sr "${INPUT_DIR}/${SUB}_${SES}_fod_wm_norm.mif" "${FOD_INPUT_DIR}/${SUB}_${SES}.mif"
            ln -sr "${INPUT_DIR}/${SUB}_${SES}_multi_upsampled_mask.mif" "${MASK_INPUT_DIR}/${SUB}_${SES}.mif"
        fi
      fi
    done
  fi
done

#Template building
population_template "${FOD_INPUT_DIR}" \
    -mask_dir "${MASK_INPUT_DIR}" \
    "${TEMPLATE_FOD}" \
    -voxel_size 1.25 
   

echo "Population Template created successfully at: ${TEMPLATE_FOD}"


#Part 4: Subject Registration & Mask Warping (Combined Subject Loop)

echo "Registering subjects to template and warping brain masks..."

for SUB_DIR in ${BASE_DIR}/rawdata/sub-*; do
  if [ -d "${SUB_DIR}" ]; then
    for SES_DIR in "${SUB_DIR}"/ses-*; do
      if [ -d "${SES_DIR}" ]; then
        
			SUB=$(basename "${SUB_DIR}")
        	SES=$(basename "${SES_DIR}")
        
		#Defining the input directory path
			INPUT_DIR="${DERIV_DIR}/input/${SUB}/${SES}"
        
        if [ -d "${INPUT_DIR}" ]; then
          echo "Processing Registration & Mask Warp: ${SUB} | ${SES}"
          
		  #Defining the output warp file paths
          	SUBJECT_FOD="${INPUT_DIR}/${SUB}_${SES}_fod_wm_norm.mif"
          	SUBJECT_MASK="${INPUT_DIR}/${SUB}_${SES}_multi_upsampled_mask.mif"
          	SUBJECT_WARP="${INPUT_DIR}/${SUB}_${SES}_subject2template_warp.mif"
          	TEMPLATE_WARP="${INPUT_DIR}/${SUB}_${SES}_template2subject_warp.mif"

		#Defining the output warped mask path
          	WARPED_MASK="${INPUT_DIR}/${SUB}_${SES}_mask_in_template_space.mif"

          #Registering the subject FOD to the population template
          
				mrregister "${SUBJECT_FOD}" "${TEMPLATE_FOD}" \
			  		-mask1 "${SUBJECT_MASK}" \
  					-nl_warp "${SUBJECT_WARP}" "${TEMPLATE_WARP}" 
  					

				mrtransform "${SUBJECT_MASK}" \
  					-warp "${SUBJECT_WARP}" \
  					-interp nearest \
  					-datatype bit \
  					"${WARPED_MASK}" \
  					
        fi
      fi
    done
  fi
done



#Part 5: group template mask & template fixels 
echo "Building Population Template Mask..."

#Defining the output file paths and input directories
TEMPLATE_MASK="${TEMPLATE_DIR}/template_mask.mif"
WARPED_MASKS_INPUT="${TEMPLATE_DIR}/warped_masks"
TEMPLATE_FIXEL_DIR="${TEMPLATE_DIR}/fixels"

#Making a directory for the warped subject masks
mkdir -p "${WARPED_MASKS_INPUT}"

# Symlink all warped masks 
for SUB_DIR in ${BASE_DIR}/rawdata/sub-*; do
  if [ -d "${SUB_DIR}" ]; then
    for SES_DIR in "${SUB_DIR}"/ses-*; do
      if [ -d "${SES_DIR}" ]; then
        
			SUB=$(basename "${SUB_DIR}")
        	SES=$(basename "${SES_DIR}")

		#Defining the input warped mask path
        	INPUT_DIR="${DERIV_DIR}/input/${SUB}/${SES}"
        	WARPED_MASK="${INPUT_DIR}/${SUB}_${SES}_mask_in_template_space.mif"
        
		#Making the symlinks so group processing can happen 
        if [ -f "${WARPED_MASK}" ]; then
            ln -sr "$WARPED_MASK" "${WARPED_MASKS_INPUT}/${SUB}_${SES}.mif"
        fi
      fi
    done
  fi
done

#Generating population mask intersection across all subjects
mrmath "${WARPED_MASKS_INPUT}"/*.mif min "${TEMPLATE_MASK}" -datatype bit 

