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

## 💻 Environment & OS Virtualization
To ensure reproducibility, this pipeline was built and executed in a virtualised environment.
*   **Host OS Compatibility**: Windows / macOS / Linux
*   **Virtual Machine Manager**: Ubuntu running inside a Virtual Machine Manager (Oracle VirtualBox Manager )
*   **Guest Operating System**: Ubuntu Linux (OS version: Ubuntu 25.04 (Plucky Puffin) (64-bit))
*   **Hardware Allocation Note**: Ensure your virtual machine is allocated maximum available CPU cores and RAM (minimum 16GB recommended) to handle MRtrix3 commands.

---


