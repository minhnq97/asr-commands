# asr-commands
Scripts run on Kaldi toolkit on Kaggle's Tensorflow Speech Recognition Challenge. The URL to the challenge is [here](https://www.kaggle.com/c/tensorflow-speech-recognition-challenge/).  

To run the script, you have to copy this folder to $kaldi_path/egs/  
Check the symbolic links of utils, steps, conf, local folders if it does work.  
The kernel describe this repository is on [kaggle](https://www.kaggle.com/minhnq/tutorial-how-to-train-asr-on-kaldi-lb-75?scriptVersionId=16804869).

#### Step 1:
Create training and validation data:  
> python data_prep.py  

#### Step 2:
Create evaluation data:  
> python eval_prep.py  

#### Step 3:  
Training data (running from stage 0):  
> . ./path.sh  
./run.sh --stage 0
