# Mirs Analysis

## Intro comments
- The initial version of the code is stored in *initial_script.R* file.
- A more systematical and autonomous version of the code is organized in files *script_mirs.R*, *qc.R*, *diff_analysis.R* and *fa.R*.
- The main script is *script_mirs.R*. Hence, this is the one to be executed. The rest of the scripts are being called gradually inside the main script.

## Scripts:
- *script_mirs.R*: main script
- *qc.R*: quality control
- *diff_analysis.R*: differential analysis
- *fa.R*: functional analysis

## Execution:
- **Packages**: Make sure that every package loaded in **lines 20-31** inside the *script_mirs.R* is installed. The package **saveImageHigh** is basically **nikopech**'s tool, so you need to install it from [here](https://github.com/nikopech/saveImageHigh).
- **Input**: The input parameters are specified inside the **input.yml** file. No need to specify parameters inside the main script.
- **Execution**: Just run *script_mirs.R*.
- **Output**: Inside the *'output/'* directory:
  1. Directories *'plate1/'*, *'plate2/'*  and *'plate3/'* contain the outputs from quality control analysis.
  2. Directory *'Differential Analysis/'* contains the output from differential analysis.
  3. Directory *'Functional Analysis/'* contains the output from functional analysis.
  4. Tables normalized_data, data.all, multimir_results.validated@summary$target_symbol **or** multimir_results.predicted@summary$target_symbol (depends on the input), KEGG_enrich.f and GO_enrich.f are stored inside the *'Tables/'* directory as .csv files.
  5. *report.txt'*: Contains information concerning the analysis (e.g. samples that were droped out due to high NA's percentage, errors in specific plots, etc) and execution time measurements.
