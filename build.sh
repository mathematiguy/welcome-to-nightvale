#! /bin/bash

set -ex

make train

(cd nightvale/corpus && zip -r /output/corpus.zip *)
(cd models/cecil_speaks zip -r /output/model.zip *)
