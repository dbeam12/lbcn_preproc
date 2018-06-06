function EpochDataAll(sbj_name, project_name, bn, dirs,elecs,locktype,bef_time,aft_time,datatype,thr_raw,thr_diff,blc)

%% INPUTS:
%   sbj_name: subject name
%   project_name: name of task
%   block_names: blocks to be analyed (cell of strings)
%   dirs: directories pointing to files of interest (generated by InitializeDirs)
%   elecs: can select subset of electrodes to epoch (default: all)
%   locktype: 'stim' or 'resp' (which events to timelock to)
%   bef_time: time (in s) before event to start each epoch of data
%   aft_time: time (in s) after event to end each epoch of data
%   datatype: 'CAR', 'HFB', or 'Spect' (which type of data to load and epoch)
%   thr_raw: threshold for raw data (z-score threshold relative to all data points) to exclude timepoints
%   thr_diff: threshold for changes in signal (diff bw two consecutive points; also z-score)
%   blc: baseline correction
%       .run: true or false (whether to run baseline correction)
%       .locktype: 'stim' or 'resp' (which event to use to choose baseline window)
%       .win: 2-element vector specifiying window relative to lock event to use for baseline, in sec (e.g. [-0.2 0])

% set default paramters (if inputs are missing or empty)

if nargin < 12 || isempty(blc)
    blc.run = true;
    blc.locktype = 'stim';
    blc.win = [-0.2 0];
end
if nargin < 11 || isempty(thr_diff)
    thr_diff = 8;
end
if nargin < 10 || isempty(thr_raw)
    thr_raw = 8;
end
if nargin < 9 || isempty(datatype)
    datatype = 'CAR';
end
if nargin < 8 || isempty(aft_time)
    aft_time = 3;
end
if nargin < 7 || isempty(bef_time)
    bef_time = -0.5;
end
if nargin < 6 || isempty(locktype)
    locktype = 'stim';
end

% Check if baseline window is within desired epoched window
% Otherwise, will need to epoch baseline separately and add as separate
% input to baseline correction function
if blc.run && ~(strcmp(locktype,blc.locktype) && blc.win(1)>=bef_time && blc.win(2) <= aft_time)
    sep_bl = true;
else
    sep_bl = false;
end

%% loop through electrodes

% Load globalVar
fn = sprintf('%s/originalData/%s/global_%s_%s_%s.mat',dirs.data_root,sbj_name,project_name,sbj_name,bn);
load(fn,'globalVar');

dir_in = [dirs.data_root,'/',datatype,'Data/',sbj_name,'/',bn];
dir_out = [dirs.data_root,'/',datatype,'Data/',sbj_name,'/',bn, '/EpochData'];

if nargin < 5 || isempty(elecs)
    elecs = setdiff(1:globalVar.nchan,globalVar.refChan);
end

% load trialinfo
load([dirs.result_root,'/',project_name,'/',sbj_name,'/',bn,'/trialinfo_',bn,'.mat'])
% Select only trials that are not rest
trialinfo = trialinfo(~strcmp(trialinfo.condNames, 'rest'),:);


if strcmp(locktype,'stim')
    lockevent = trialinfo.allonsets(:,1);
elseif strcmp(locktype,'resp')
    lockevent = trialinfo.RT_lock;
else
    lockevent = [];
end

if sep_bl
    if strcmp(blc.locktype,'stim')
        bl_lockevent = trialinfo.allonsets(:,1);
    elseif strcmp(bl.locktype,'resp')
        bl_lockevent = trialinfo.RT_lock;
    else
        bl_lockevent = [];
    end
end

%% Get HFO bad trials:
pTS = globalVar.pathological_event_bipolar_montage;
[bad_epochs_HFO, bad_indices_HFO] = exclude_trial(pTS.ts,pTS.channel, lockevent, globalVar.channame, bef_time, aft_time, globalVar.iEEG_rate);
% Put the indices to the final sampling rate
bad_indices_HFO = cellfun(@(x) round(x./(globalVar.iEEG_rate/globalVar.fs_comp)), bad_indices_HFO, 'UniformOutput',false);

for ei = 1:length(elecs)
    el = elecs(ei);
    
    % epoch data
    load(sprintf('%s/%siEEG%s_%.2d.mat',dir_in,datatype,bn,el));
    
    if strcmp(datatype,'CAR')
        data.wave = wave;
        data.fsample = globalVar.iEEG_rate;
        data.label = globalVar.channames{el};
    end
    
    if sep_bl
        bl_data = EpochData(data,bl_lockevent,blc.win(1),blc.win(2));
    end
    ep_data = EpochData(data,lockevent,bef_time,aft_time);
    
    data.wave = ep_data.wave;
    data.time = ep_data.time;
    clear ep_data
    data.trialinfo = trialinfo;
    
    %% Epoch rejection
    if strcmp(datatype,'Spec')
        %if spectral data, average across frequency dimension before
        %epoch rejection
        [badtrials, badinds] = epoch_reject_raw(squeeze(nanmean(abs(data.wave),1)),thr_raw,thr_diff);
    else % CAR or HFB (i.e. 1 frequency)
        [badtrials, badinds] = epoch_reject_raw(data.wave,thr_raw,thr_diff);
    end
    
    %% Method 2, SU's
    badtrials_SU = LBCN_filt_bad_trial(data.wave',data.fsample*5);
   
    
    %% Update trailinfo and globalVar with bad trials and bad indices
    data.trialinfo.badtrials_raw = badtrials;
    badtrial_HFO = zeros(size(data.trialinfo,1),1,1);
    badtrial_HFO(bad_epochs_HFO{el}) = 1;
    data.trialinfo.badtrials_HFO = logical(badtrial_HFO);
    data.trialinfo.badtrials_SU = badtrials_SU'; % based on spikes in the raw signal
    data.trialinfo.badtrials = data.trialinfo.badtrials_HFO | data.trialinfo.badtrials_raw | data.trialinfo.badtrials_SU;
    
    data.trialinfo.badinds_raw = badinds.raw'; % based on the raw signal
    data.trialinfo.badinds_diff = badinds.diff'; % based on spikes in the raw signal
    data.trialinfo.badinds_HFO = bad_indices_HFO(:,el); % based on spikes in the raw signal
    
    for ui = 1:length(data.trialinfo.badinds_raw)
        badinds_all = union_several(data.trialinfo.badinds_raw{ui,:}, data.trialinfo.badinds_diff{ui,:},data.trialinfo.badinds_HFO{ui,:});
        data.trialinfo.badinds{ui} = badinds_all(:)';
    end
    
    globalVar.bad_epochs(el).badtrials_raw = data.trialinfo.badtrials_raw;
    globalVar.bad_epochs(el).badtrials_HFO = data.trialinfo.badtrials_HFO;
    globalVar.bad_epochs(el).badtrials = data.trialinfo.badtrials;
    
    globalVar.bad_epochs(el).badinds_raw = data.trialinfo.badinds_raw;
    globalVar.bad_epochs(el).badinds_diff = data.trialinfo.badinds_diff;
    globalVar.bad_epochs(el).badinds_HFO = data.trialinfo.badinds_HFO;
    globalVar.bad_epochs(el).badinds = data.trialinfo.badinds;
    
    
    %% Run baseline correction (either calculate from data if locktype = stim or uses these values when locktype = 'resp')
    if blc.run
        if sep_bl
            data_blc = BaselineCorrect(data,bl_data);
        else
            data_blc = BaselineCorrect(data,blc.win);
        end
        data.wave = data_blc.wave;
    end
    
    %% Update data structure
    data.label = globalVar.channame{el};
    if strcmp(datatype,'CAR')
        data.fsample = globalVar.iEEG_rate;
    else
        data.fsample = globalVar.fs_comp;
    end
    
    % Naming specs based on the epoching parameters
    if blc.run == true
        bl_tag = 'bl_corr_';
    else
        bl_tag = [];
    end
    fn_out = sprintf('%s/%siEEG_%slock_%s%s_%.2d.mat',dir_out,datatype,locktype,bl_tag,bn,el);
    
    save(fn_out,'data')
    disp(['Data epoching: Block ', bn, ' ' bl_tag,' Elec ',num2str(el)])
end

%% save updated globalVar (with bad epochs)
fn = [dirs.data_root,'/OriginalData/',sbj_name,'/global_',project_name,'_',sbj_name,'_',bn,'.mat'];
save(fn,'globalVar')
end


