#! /usr/bin/env python

import os.path
import random

all_info = []
transcript = {}
# URI path for training audios
path = '/project/vais-02/Work/minhnq/kaggle/commands/train/audio'

all_info = []
count = 0
# r=root, d=directories, f = files
for r, d, f in os.walk(path):
    for file in f:
        if '.wav' in file:
            count+=1
            trans = r.split("/")[-1]
            file_id = file.split(".")[0] + "_" + trans
            spk_id = file_id.split("_")[0]
            transcript[file_id] = trans
            all_info.append([spk_id,file_id,os.path.join(r, file)])

print(count)
counter = int(len(all_info) * 0.1)
random.shuffle(all_info)
all_train_info = all_info[counter:]
all_test_info = all_info[:counter]

if not os.path.exists(os.path.dirname('data/train_command/text')):
    os.makedirs(os.path.dirname('data/train_command/text'))
if not os.path.exists(os.path.dirname('data/test_command/text')):
    os.makedirs(os.path.dirname('data/test_command/text'))

def text(file_infos):
    results = []
    # folder_path = os.path.abspath("recordings")
    for info in file_infos:
        utt_id = info[1]
        trans = transcript[utt_id]
        results.append("{} {}".format(utt_id, trans))
    return '\n'.join(sorted(results))

with open("data/train_command/text","wt") as f:
    f.writelines(text(all_train_info))
with open("data/test_command/text","wt") as f:
    f.writelines(text(all_test_info))

if not os.path.exists(os.path.dirname('data/train_command/wav.scp')):
    os.makedirs(os.path.dirname('data/train_command/wav.scp'))
if not os.path.exists(os.path.dirname('data/test_command/wav.scp')):
    os.makedirs(os.path.dirname('data/test_command/wav.scp'))

def wavscp(file_infos):
    results = []
    for info in file_infos:
        results.append("{} {}".format(info[1], info[2]))
    return '\n'.join(sorted(results))

with open("data/train_command/wav.scp","wt") as f:
    f.writelines(wavscp(all_train_info))
with open("data/test_command/wav.scp","wt") as f:
    f.writelines(wavscp(all_test_info))


if not os.path.exists(os.path.dirname('data/train_command/utt2spk')):
    os.makedirs(os.path.dirname('data/train_command/utt2spk'))
if not os.path.exists(os.path.dirname('data/test_command/utt2spk')):
    os.makedirs(os.path.dirname('data/test_command/utt2spk'))

def utt2spk(file_infos):
    results = []
    for info in file_infos:
        speaker = info[0]
        utt_id = info[1]
        results.append("{} {}".format(utt_id, speaker))
    return '\n'.join(sorted(results))

with open("data/train_command/utt2spk","wt") as f:
    f.writelines(utt2spk(all_train_info))
with open("data/test_command/utt2spk","wt") as f:
    f.writelines(utt2spk(all_test_info))
