## Mirai risk prediction

### Setup

#### Dockerized

We have chosen to use the Docker implementation of Mirai, for purposes of reproducibility.

##### Deployment

An explanation on how to deploy the Mirai Docker container can be found in the mirai/docker/ directory.

OncoServe 0.5.0 was used in this study.

##### Execution

Enter the docker container:
```docker run -it --shm-size=8g -v /local/data/directory:/data:z -v /local/output/directory:/output:z learn2cure/oncoserve_mirai:0.5.0 /bin/zsh```

###### Pre-processing

####### DICOM to PNG conversion

Following the Mirai Github repository:
```cd /root/OncoData
python scripts/dicom_to_png/dicom_to_png.py --dcmtk --dicom_dir /data/input_dir --png_dir /data/output_dir```

In this work:
1. xxxx / xxxx were converted using the original DCMTK version (3.6.1).
2. xxxx / xxxx were converted using the latest DCMTK version (3.6.9).
3. 12 / xxxx were corrupted and unrecoverable.


####### Data manifest creation

Execute `1_mirai_manifest_creation.R`

This will produce a manifest file suitable for input into Mirai.

###### Risk prediction

< to complete ... >

```cd /root/OncoNet
python scripts/main.py  --model_name mirai_full --img_encoder_snapshot snapshots/mgh_mammo_MIRAI_Base_May20_2019.p --transformer_snapshot snapshots/mgh_mammo_cancer_MIRAI_Transformer_Jan13_2020.p --callibrator_snapshot snapshots/callibrators/MIRAI_FULL_PRED_RF.callibrator.p --batch_size 1 --dataset csv_mammo_risk_all_full_future --img_mean 7047.99 --img_size 1664 2048 --img_std 12005.5 --metadata_path /data/mirai_manifest.csv --test --prediction_save_path /output/risk_scores/mirai_scores.csv```

#### Non-dockerized

@TODO: Section not completed.

```conda create -n \"mammo_risk_prediction\" python=3.6```

Install dependencies (for pre-processing):
```python -m pip install p_tqdm pydicom scipy pandas xlrd dicom h5py imageio```

Mirai codebase (from docker container) uses DCMTK 3.6.1~20150924-5 for conversion of DICOMs->PNGs
This version can be obtained here: https://dicom.offis.de/download/dcmtk/dcmtk361/ and needs to be compiled.
