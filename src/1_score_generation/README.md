## Mirai risk prediction

### Setup

#### Dockerized

We have chosen to use the Docker implementation of Mirai, for purposes of reproducibility.

##### Deploy Docker container from Mirai Docker image

An explanation on how to initialize the Mirai Docker image can be found in the mirai/docker/ directory.

##### Execution

###### Pre-processing

< to complete ... >

###### Risk prediction

< to complete ... >


#### Non-dockerized

@TODO: Section not completed.

```conda create -n \"mammo_risk_prediction\" python=3.6```

Install dependencies (for pre-processing):
```python -m pip install p_tqdm pydicom scipy pandas xlrd dicom h5py imageio```

Mirai codebase (from docker container) uses DCMTK 3.6.1~20150924-5 for conversion of DICOMs->PNGs
This version can be obtained here: https://dicom.offis.de/download/dcmtk/dcmtk361/
