# als-fba-pipeline
A Fixel-Based Analysis (FBA) pipeline developed during my JRA for ALS diffusion MRI data

This repository contains the cross-sectional and longitudinal Fixel-Based Analysis (FBA) pipeline developed during my Junior Research Associate (JRA) project at the University of Sussex. The pipeline investigates white matter degeneration involved in Amyotrophic Lateral Sclerosis (ALS) and produces fibre-specific metrics (**FD, FDC and logFC**) which provide information about the underlying physiology behind the abnormalities. 

---

## Project Scope & Computational Limitations Notes
Because neuroimaging processing is highly resource-intensive, this pipeline was executed as a **proof of concept** with strategic adjustments made for local hardware limitations:
*   **Cohort Size**: A subset of **5 subjects** (comprising one ALS patient and controls) was processed locally from raw data through to metric estimation to validate the pipeline mechanics.
*   **Template & Group Stats**: To ensure scientific validity regardless of my machines limitations, the population-specific FOD template, structural connectivity matrices, and final statistical outputs were integrated from the broader dataset (provided by my supervisor).
*   **Statistical Permutations**: Local testing was run with a reduced number of permutations ( `5` instead of the standard `5000`) to verify script execution without exhausting system memory. Final statistical inference (**fixelcfestats**) was run with the standard number of permutations.

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
* **Python 3.x**: Scripting and automation.

---

## Pipeline Workflow

### 1. Preprocessing
1. **Denoising & Degibbs**: Removal of thermal noise (`dwidenoise`) and Gibbs ringing artifacts (`mrdegibbs`).
2. **Distortion & Motion Correction**: FSL `eddy` via MRtrix3 (`dwifslpreproc`) to correct for eddy current-induced distortions and subject movement.
3. **Bias Field Correction**: Bias field correction using ANTs (`dwibiascorrect`).

### 2. FOD Estimation & Registration
1. **Response Function Estimation**: Multi-shell multi-tissue (MSMT) response function generation (`dwi2response dhollander`).
2. **Constrained Spherical Deconvolution (CSD)**: FOD map computation (`dwi2fod msmt_csd`).
3. **Intensity Normalisation**: Multi-tissue FOD normalisation across subjects (`mtnormalise`).
4. **Population Template Generation**: Co-registration of subject FODs to build a representative study template.

### 3. Fixel Metric Estimation
FODs are segmented into discrete fixels to calculate specific microstructural and macrostructural properties:
* **Fibre Density (FD)**: Measures microscopic axon count within a fixel.
* **Fibre Cross-Section (FC / logFC)**: Measures macroscopic bundle morphometry (area expansion/contraction).
* **Fibre Density and Cross-Section (FDC)**: Combined metric quantifying total axonal capacity.

### 4. Statistical Analysis & Visualisation
1. **Whole-Brain Tractography**: Generated on the population FOD template (`tckgen`).
2. **SIFT2 Filtering**: Spherical-deconvolution Informed Filtering of Tractograms (`tcksift2`) to remove reconstruction bias.
3. **Statistical Inference**: Connectivity-based fixel enhancement (`fixelcfestats`) using non-parametric permutation testing to isolate significantly degraded pathways in ALS.
4. **Tract Thresholding & Isolation**: `tckedit` filtering using statistical threshold images (`-threshold_image` at FWE $p$-value $0.95$) to isolate affected tracts.

---

## 📂 Repository Layout

```text
.
├── scripts/
│   ├── 01_preprocessing.sh       # Denoising, unringing, and eddy correction
│   ├── 02_fod_estimation.sh      # Response functions & MSMT CSD
│   ├── 03_fixel_metrics.sh       # Segmentation, registration, FD/FC/FDC computation
│   └── 04_group_stats.sh         # Non-parametric permutation testing (fixelcfestats)
├── derivatives/
│   ├── template_wmfod.mif        # Population-wide FOD template
│   ├── tracks_for_analysis/      # Filtered statistical tracts (.tck)
│   └── stats_results/            # P-value maps and thresholded outputs
├── LICENSE
└── README.md

