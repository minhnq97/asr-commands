RAW_DICT_PATH=dict
OOV=
nj=16   #number of processes
stage=0
train=true
decode=true
. utils/parse_options.sh


if [ $stage -le 0 ]; then
  echo "==== Preparing data ===="
  utils/prepare_lang.sh --position-dependent-phones false data/local/dict "<SIL>" data/local/dict/tmp data/lang || exit 1
  echo "==== End of preparing data ===="

  # Language model
  echo "==== Preparing language model ===="
  arpa2fst --disambig-symbol=#0 --read-symbol-table=data/lang/words.txt data/local/tmp/lm.arpa data/lang/G.fst || exit 1
  echo "==== End of preparing language model ===="

  # Feature extraction
  echo "==== Extracting feature ===="
  for x in train_command test_command eval_command; do
   utils/fix_data_dir.sh data/$x
   steps/make_mfcc.sh --nj 16 data/$x exp/log/make_mfcc/$x
   steps/compute_cmvn_stats.sh data/$x exp/log/make_mfcc/$x
  done
  echo "==== End of extracting feature ===="
fi

if [ $stage -le 1 ]; then
  echo "==== Monophone training ===="
  steps/train_mono.sh --nj 16 --cmd "utils/run.pl" data/train_command data/lang exp/mono || exit 1
  #../../src/fstbin/fstcopy 'ark:gunzip -c exp/mono/fsts.1.gz|' ark,t:- | head -n 20

   # Decoding and testing
  echo "==== Decoding Monophone ===="
  utils/mkgraph.sh --mono data/lang exp/mono exp/mono/graph     # Fully connected FST network (HCLG in exp/mono/graph)
  steps/decode.sh --nj 100 --cmd "utils/run.pl" exp/mono/graph data/test_command exp/mono/decode_test_command

  for x in exp/*/decode*; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done
fi
if [ $stage -le 2 ]; then
  # tri1
  if $train; then
    steps/align_si.sh --boost-silence 1.25 --nj 10 --cmd "run.pl" \
      data/train_command data/lang exp/mono exp/mono0a_ali || exit 1;
    steps/train_deltas.sh --boost-silence 1.25 --cmd "run.pl" 2000 10000 \
      data/train_command data/lang exp/mono0a_ali exp/tri1 || exit 1;
  fi
  if $decode; then
    utils/mkgraph.sh data/lang \
      exp/tri1 exp/tri1/graph_nosp_tgpr || exit 1;
    for data in command; do
      nspk=$(wc -l <data/test_${data}/spk2utt)
      steps/decode.sh --nj $nspk --cmd "run.pl" exp/tri1/graph_nosp_tgpr \
        data/test_${data} exp/tri1/decode_test_${data} || exit 1;

    done
    ## the following command demonstrates how to get lattices that are
    ## "word-aligned" (arcs coincide with words, with boundaries in the right
    ## place).
    #sil_label=`grep '!SIL' data/lang_nosp_test_tgpr/words.txt | awk '{print $2}'`
    #steps/word_align_lattices.sh --cmd "$train_cmd" --silence-label $sil_label \
    #  data/lang_nosp_test_tgpr exp/tri1/decode_nosp_tgpr_dev93 \
    #  exp/tri1/decode_nosp_tgpr_dev93_aligned || exit 1;
  fi
fi

if [ $stage -le 3 ]; then
  # tri2b.  there is no special meaning in the "b"-- it's historical.
  if $train; then
    steps/align_si.sh --nj 10 --cmd "run.pl" \
      data/train_command data/lang exp/tri1 exp/tri1_ali || exit 1;

    steps/train_lda_mllt.sh --cmd "run.pl" \
      --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
      data/train_command data/lang exp/tri1_ali exp/tri2b || exit 1;
  fi

  if $decode; then
    utils/mkgraph.sh data/lang \
      exp/tri2b exp/tri2b/graph_nosp_tgpr || exit 1;
    nspk=$(wc -l <data/test_command/spk2utt)
    steps/decode.sh --nj $nspk --cmd "run.pl" exp/tri2b/graph_nosp_tgpr \
        data/test_command exp/tri2b/decode_test_command || exit 1;
    for x in exp/tri2b/decode*; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done
  fi
fi
if [ $stage -le 4 ]; then
  # From 2b system, train 3b which is LDA + MLLT + SAT.

  # Align tri2b system with all the si284 data.
  if $train; then
    steps/align_si.sh  --nj 10 --cmd "run.pl" \
      data/train_command data/lang exp/tri2b exp/tri2b_ali  || exit 1;

    steps/train_sat.sh --cmd "run.pl" 4200 40000 \
      data/train_command data/lang exp/tri2b_ali exp/tri3b || exit 1;
  fi

  if $decode; then
    utils/mkgraph.sh data/lang \
      exp/tri3b exp/tri3b/graph_nosp_tgpr || exit 1;

    # the larger dictionary ("big-dict"/bd) + locally produced LM.

    # At this point you could run the command below; this gets
    # results that demonstrate the basis-fMLLR adaptation (adaptation
    # on small amounts of adaptation data).
    # local/run_basis_fmllr.sh --lang-suffix "_nosp"

    nspk=$(wc -l <data/test_command/spk2utt)
    steps/decode_fmllr.sh --nj ${nspk} --cmd "run.pl" \
        exp/tri3b/graph_nosp_tgpr data/test_command \
        exp/tri3b/decode_nosp_tgpr_command || exit 1;
    for x in exp/tri3b/decode*; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done
   fi
fi

