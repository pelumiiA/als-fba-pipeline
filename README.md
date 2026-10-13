# als-fba-pipeline
A Fixel-Based Analysis (FBA) pipeline developed during my JRA for ALS diffusion MRI data

This repository contains the cross-sectional and longitudinal Fixel-Based Analysis (FBA) pipeline developed during my Junior Research Associate (JRA) project at the University of Sussex. The pipeline investigates white matter degeneration involved in Amyotrophic Lateral Sclerosis (ALS) and produces fibre-specific metrics (**FD, FDC and logFC**) which provide information about the underlying physiology behind the abnormalities. 

---

## Project Scope & Computational Limitations Notes
Because neuroimaging processing is highly resource-intensive, this pipeline was executed as a **proof of concept** with strategic adjustments made for local hardware limitations:
*   **Cohort Size**: A subset of **5 subjects** (comprising one ALS patient and controls) was processed locally from raw data through to metric estimation to validate the pipeline mechanics.
*   **Template & Group Stats**: To ensure scientific validity regardless of my machines limitations, the population-specific FOD template, structural connectivity matrices, and final statistical outputs were integrated from the broader dataset (provided by my supervisor).
*   **Statistical Permutations**: Testing was run with a reduced number of permutations ( `5` instead of the standard `5000`) to verify script execution without exhausting system memory. Final statistical inference (**fixelcfestats**) was run with the standard number of permutations.

---

## Environment & OS Virtualisation
To ensure reproducibility, this pipeline was built and executed in a virtual environment.
*   **Host OS Compatibility**: Windows / macOS / Linux
*   **Virtual Machine Manager**: Ubuntu running inside a Virtual Machine Manager (Oracle VirtualBox Manager )
*   **Guest Operating System**: Ubuntu Linux (OS version: Ubuntu 25.04 (Plucky Puffin) (64-bit))
*   **Hardware Allocation Note**: Ensure your virtual machine is allocated maximum available CPU cores and RAM (minimum 16GB recommended) to handle MRtrix3 commands.

---
## Software & Tool Dependencies

The pipeline relies on the following open-source neuroimaging software packages and environments:

* **[MRtrix3](https://www.mrtrix.org/)**: Core library for diffusion processing, response function estimation, FOD spherical deconvolution, and fixel-based statistics (`fixelcfestats`). (Installation guide: https://mrtrix.readthedocs.io/en/latest/installation/package_install.html)
* **[FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki)**: Used for motion and eddy current correction (`eddy`), brain extraction (`BET`), and spatial registration tools.
* **[ANTs (Advanced Normalisation Tools)](https://github.com/ANTsX/ANTs)**: For non-linear registration and bias field correction.

---

## Pipeline Workflow

### 1. Preprocessing (Cleaning the Data)
Before we can analyse brain scans, raw data needs to be cleaned up to fix scanning artefacts and distortion:
1. **Noise & Artefact Removal**: Removing random scanner noise (`dwidenoise`) and ripples or blurriness caused by signal interference (`mrdegibbs`).
2. **Head Movement & Distortion Correction**: Fixing stretches, warping, and bending caused by the scanner's magnetic fields and minor head twitching during the scan (`eddy` / `dwifslpreproc`).
3. **Brightness Equalisation**: Smoothing out uneven lighting or shadow gradients across the brain image so the entire scan has uniform brightness (`dwibiascorrect`).

### 2. Fibre Orientation & Template Building (Mapping Brain Pathways)
Next, we calculate how water molecules travel along nerve pathways to map out the brain's wiring:
1. **Tissue Response Calculation**: Figuring out the unique signal signature of white matter nerve fibres compared to other fluids in the brain (`dwi2response`).
2. **Direction Mapping**: Calculating the exact angles and directions that nerve fibres travel in every part of the brain (`dwi2fod`).
3. **Balancing the Scans**: Normalising the brightness across all different subject scans so they can be accurately compared (`mtnormalise`).
4. **Group Template Creation**: Combining all the individual brain maps together to create a single, shared standard reference map for the group.

### 3. Measuring the Pathways (Fixel Metrics)
Instead of looking at the whole brain at once, we break down white matter pathways into tiny individual bundles (fixels) to measure specific health indicators:
* **Fibre Density (FD)**: Counts how many individual nerve fibres are packed tightly together inside a specific pathway.
* **Fibre Cross-Section (FC / logFC)**: Measures whether a nerve bundle is physically shrinking (atrophy) or expanding compared to the standard template.
* **Fibre Density and Cross-Section (FDC)**: A combined overall score showing the total functional capacity of the nerve pathway.

### 4. Statistical Analysis & Finding Abnormalities
1. **Virtual Brain Wiring**: Reconstructing thousands of continuous nerve tracks across the whole template brain (`tckgen`) to see how regions connect.
2. **Filtering Extra Tracks**: Cleaning up accidental overlapping tracks to ensure the mathematical models match real biology (`tcksift2`).
3. **Spotting ALS Damage**: Running computer tests (`fixelcfestats`) to compare patients and controls, highlighting specific pathways that are significantly degraded.
4. **Isolating Affected Tracts**: Extracting and saving just the damaged pathways (`tckedit`) based on strict statistical thresholds to clearly visualise where the disease has taken a toll.

---

