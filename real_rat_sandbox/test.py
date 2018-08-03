# -*- coding: utf-8 -*-
"""
=============================
Saving an animation
=============================

To save an animation, simply add the `save_path` kwarg and specify the path
where you want to save the movie, including the extension.  NOTE: this
depends on having ffmpeg installed on your computer.
"""

# Code source: Andrew Heusser
# License: MIT

import hypertools as hyp
import pandas as pd
import scipy as sc

# load data
runL1=pd.read_csv('runL1.csv')
runL2=pd.read_csv('runL2.csv')
posL1 = pd.read_csv('posL1.csv',header=None)
loc = posL1.values.tolist()

# look at single trial plots
hyp.plot(runL1,save_path='singletrial.png')
# hyp.plot(runL1,group=loc,save_path='singletrial_by_location.png')

# compare across trials for same type
run_compare_trial = [runL1,runL2]
hyp.plot(run_compare_trial,save_path='twotrials.png')

# compare across type
runR1 = pd.read_csv('runR1.csv')
run_compare_type = [runL1,runR1]
hyp.plot(run_compare_type,save_path='left_vs_right.png')

# compare run vs replay
replayL1 = pd.read_csv('replayL1.csv')
run_vs_rest = [runL1,replayL1]
hyp.plot(run_vs_rest,save_path='run_vs_rest.png')
