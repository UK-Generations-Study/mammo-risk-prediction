## Mirai risk prediction

### Setup

#### Dockerized

We have chosen to use the Docker implementation of Mirai, for purposes of reproducibility.

##### Deployment

An explanation on how to deploy the Mirai Docker container can be found in the mirai/docker/ directory.

OncoServe 0.5.0 was used in this study.

##### Execution

Enter the docker container:
```docker run -it -v /local/data/directory:/data:z learn2cure/oncoserve_mirai:0.5.0 /bin/zsh```

###### Pre-processing

####### DICOM to PNG conversion

Following the Mirai Github repository:
```cd /root/OncoData
python scripts/dicom_to_png/dicom_to_png.py --dcmtk --dicom_dir /data/input_dir --png_dir /data/output_dir```

####### Data manifest creation

< to complete ... >

###### Risk prediction

< to complete ... >

```cd /root/OncoNet
python scripts/main.py  --model_name mirai_full --img_encoder_snapshot snapshots/mgh_mammo_MIRAI_Base_May20_2019.p --num_gpus 1 --cuda --transformer_snapshot snapshots/mgh_mammo_cancer_MIRAI_Transformer_Jan13_2020.p --callibrator_snapshot snapshots/callibrators/MIRAI_FULL_PRED_RF.callibrator.p --batch_size 1 --dataset csv_mammo_risk_all_full_future --img_mean 7047.99 --img_size 1664 2048 --img_std 12005.5 --metadata_path demo/sample_metadata.csv --test --prediction_save_path demo/validation_output.csv```

#### Non-dockerized

@TODO: Section not completed.

```conda create -n \"mammo_risk_prediction\" python=3.6```

Install dependencies (for pre-processing):
```python -m pip install p_tqdm pydicom scipy pandas xlrd dicom h5py imageio```

Mirai codebase (from docker container) uses DCMTK 3.6.1~20150924-5 for conversion of DICOMs->PNGs
This version can be obtained here: https://dicom.offis.de/download/dcmtk/dcmtk361/ and needs to be compiled.
