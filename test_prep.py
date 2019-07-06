#! /usr/bin/env python

import os.path
import random

all_info = []
transcript = {}
# URI path to test audios
path = '/project/vais-02/Work/minhnq/kaggle/commands/test/audio'

all_info = []
count = 0
# r=root, d=directories, f = files
for r, d, f in os.walk(path):
    for file in f:
        if '.wav' in file:
            count+=1
            file_name = file.split(".")[0]
            spk_id = file_name.split("_")[1]
            all_info.append([spk_id,spk_id + "_" + file_name,os.path.join(r, file)])


if not os.path.exists(os.path.dirname('data/eval_command/wav.scp')):
    os.makedirs(os.path.dirname('data/eval_command/wav.scp'))

def wavscp(file_infos):
    results = []
    for info in file_infos:
        results.append("{} {}".format(info[1], info[2]))
    return '\n'.join(sorted(results))

with open("data/eval_command/wav.scp","wt") as f:
    f.writelines(wavscp(all_info))


if not os.path.exists(os.path.dirname('data/eval_command/utt2spk')):
    os.makedirs(os.path.dirname('data/eval_command/utt2spk'))

def utt2spk(file_infos):
    results = []
    for info in file_infos:
        speaker = info[0]
        utt_id = info[1]
        results.append("{} {}".format(utt_id, speaker))
    return '\n'.join(sorted(results))

with open("data/eval_command/utt2spk","wt") as f:
    f.writelines(utt2spk(all_info))
