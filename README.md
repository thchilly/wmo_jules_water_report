# WMO JULES Water Report - Data Preprocessing

This repository contains the preprocessing scripts and (future) model outputs for the State of Global Water Resources report. It focuses on downloading and preparing ERA5 climate data to create JULES-ready meteorological forcing data. The workflow converts ERA5 data from hourly 0.25° to daily 0.5° ISIMIP-compliant data and adds necessary variables.

## Table of Contents
1. [Overview](#overview)
2. [Requirements](#requirements)
3. [Data Preprocessing Workflow](#data-preprocessing-workflow)
    1. [Download ERA5 Data](#1-download-era5-data)
    2. [Rename and Calculate Additional Variables](#2-rename-and-calculate-additional-variables)
    3. [Temporal Aggregation (Daily)](#3-temporal-aggregation-daily)
    4. [Spatial Aggregation (0.5°)](#4-spatial-aggregation-05°)
    5. [Calculate Temperature Range (tasrange)](#5-calculate-temperature-range-tasrange)
4. [ERA5 Dataset Information](#era5-dataset-information)
5. [Future Work](#future-work)
6. [Acknowledgements](#acknowledgements)
7. [License](#license)

## Overview
The scripts in this repository handle the full data processing pipeline for ERA5 data:
- Download ERA5 data using the CDS API.
- Rename and convert variables to the ISIMIP standard.
- Aggregate data to daily temporal resolution and 0.5° spatial resolution.
- Add the `tasrange` variable for JULES modeling.

## Requirements
- **Tools**: `cdo`, `nco`
    ```bash
    sudo apt install cdo nco
    ```
- **CDS API Key**: Needed for downloading ERA5 data via `getERA5.ipynb`. [CDS API Setup](https://cds.climate.copernicus.eu/api-how-to)

## Data Preprocessing Workflow

### 1. Download ERA5 Data
- **Script**: `getERA5.ipynb`
- **Description**: Download ERA5 variables (e.g., temperature, wind) for a specified period using the Climate Data Store (CDS) API.

### 2. Rename and Calculate Additional Variables
- **Script**: `renameERA5.sh`
  - Renames raw ERA5 variables to comply with ISIMIP standards.
- **Scripts**:
  - `calculateHussHurs.sh`: Calculates `huss` and `hurs` (specific and relative humidity).
  - `calculateSfcWind.sh`: Calculates `sfcwind` from `u` and `v` wind components.

### 3. Temporal Aggregation (Daily)
- **Scripts**:
  - `getDailyERA5.sh`: Aggregates a single ERA5 variable from hourly to daily resolution.
  - `getDailyERA5_allVars.sh`: Processes all variables (`tas`, `pr`, etc.) for a full year.

### 4. Spatial Aggregation (0.5°)
- **Scripts**:
  - `get0p5deg.sh`: Aggregates ERA5 data from 0.25° to 0.5° resolution.
  - `get0p5deg_allVars.sh`: Processes all variables for a year and resamples them to 0.5°.

### 5. Calculate Temperature Range (`tasrange`)
- **Script**: `processTasRange.sh`
- **Description**: Calculates the temperature range (`tasrange = tasmax - tasmin`) and updates metadata to meet JULES model requirements.

## ERA5 Dataset Information

The ERA5 dataset provides the most up-to-date meteorological data used for running the JULES model. These are sourced from the [Climate Data Store (CDS)](https://cds.climate.copernicus.eu) via the **CDS API**. 

### Meteorological Forcing Variables for JULES

The following key meteorological forcing variables are required for running the **JULES** land surface model:

- **tas**: Near-surface air temperature (2 meters above ground)
- **tasrange**: Range between daily maximum and minimum temperature
- **pr**: Total precipitation
- **ps**: Surface pressure
- **sfcWind**: Near-surface wind speed
- **huss**: Near-surface specific humidity
- **rsds**: Surface downwelling shortwave radiation
- **rlds**: Surface downwelling longwave radiation

### Calculated and Derived Variables:

- **tasrange**: The difference between daily maximum temperature (**tasmax**) and daily minimum temperature (**tasmin**).
- **huss** and **hurs**: Derived from near-surface dewpoint temperature (**dewptas**), surface pressure (**ps**), and near-surface air temperature (**tas**), following the **Buck (1981)** [[methodology](https://confluence.ecmwf.int/display/CKB/Near+surface+meteorological+variables+from+1979+to+2019+derived+from+bias-corrected+reanalysis+%28WFDE5%29%3A+Product+User+Guide#Nearsurfacemeteorologicalvariablesfrom1979to2019derivedfrombiascorrectedreanalysis(WFDE5):ProductUserGuide-references9)].
- **sfcWind**: Calculated from eastward (**uas**) and northward (**vas**) near-surface wind components:

\[
sfcWind = \sqrt{uas^2 + vas^2}
\]

### ERA5 Variables and Corresponding ISIMIP Naming Convention

| ERA5 Variable Name                              | ISIMIP Variable Name | Description                               |
|-------------------------------------------------|----------------------|-------------------------------------------|
| 2m_temperature                                  | **tas**               | Near-surface temperature (2m)             |
| maximum_2m_temperature_since_previous_post_processing | **tasmax**            | Maximum temperature for **tasrange**      |
| minimum_2m_temperature_since_previous_post_processing | **tasmin**            | Minimum temperature for **tasrange**      |
| 2m_dewpoint_temperature                         | **dewptas**           | Dewpoint temperature (for **hurs** and **huss**) |
| total_precipitation                             | **pr**                | Precipitation                             |
| surface_pressure                                | **ps**                | Surface pressure (used in **huss** and **hurs**) |
| surface_solar_radiation_downwards               | **rsds**              | Shortwave radiation                       |
| surface_thermal_radiation_downwards             | **rlds**              | Longwave radiation                        |
| 10m_u_component_of_wind                         | **uas**               | Wind u-component (for **sfcWind**)        |
| 10m_v_component_of_wind                         | **vas**               | Wind v-component (for **sfcWind**)        |


## Future Work
- Include JULES model output scripts.

## Acknowledgements
This work uses methods provided by **PIK** (Potsdam Institute for Climate Impact Research) for data remapping, ensuring consistency with existing ISIMIP datasets.

## License
This repository is licensed under the MIT License. See `LICENSE` for details.
