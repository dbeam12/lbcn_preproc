function ROLparams = genROLParams()

% ROLparams.method = 'slopes';  % 'slopes' (Amy/Brett/Mo) or 'thresh'
ROLparams.smooth = false;   % true or false- whether to smooth signal before estimating ROL
ROLparams.smwin = 0.01;     % width of gaussian smoothing window (in s), if used
ROLparams.thr = 1;          % threshold used for determining rough onset (around which more accurate onset is estimated)- z-score relative to baseline
ROLparams.thrwin = 0.05;    % width of sliding window (s) used to determine where signal (avg. within window) crosses above thre
ROLparams.mindur = 0.05;    % signal must exceed threshold for at least this duration (s)
ROLparams.winlen = 0.05;    % length (s) of smaller windows where linear fit of data is computed
ROLparams.overlap = 0.04;   % length (s) of window overlap
ROLparams.pre_event = -0.1;
ROLparams.dur = 1;
% ROLparams.trialavgtype = 'bs'; % 'bs' for bootstrap, or 'st' for single trials
ROLparams.bs_frac = 0.5;    % fraction of trials to be included in each bootstrap rep
ROLparams.bs_reps = 100;    % number of bootstrap reps
ROLparams.blc = true;       % whether to load baseline corrected data
ROLparams.bl = [-0.2 0];    % baseline period used for baseline correction
ROLparams.freq_range = [70 180]; % if loading spectral data, avg across this freq. range to generate single timecourse
ROLparams.power = true;     % compute ROL on power (true) or amplitude (false)
ROLparams.slopewin = [-0.2 0.1];  % window around threshold crossing where more exact onset will be detected
ROLparams.minrol = 0;       % start looking for rol at this time point (s)
    