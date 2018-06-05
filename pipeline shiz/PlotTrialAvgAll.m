function PlotTrialAvgAll(sbj_name,project_name,block_names,dirs,elecs,datatype,locktype,column,conds,col,noise_method,plot_params)


%% INPUTS
%       sbj_name: subject name
%       project_name: name of task
%       block_names: blocks to be analyed (cell of strings)
%       dirs: directories pointing to files of interest (generated by InitializeDirs)
%       elecs: can select subset of electrodes to epoch (default: all)
%       datatype: 'CAR','HFB',or 'Spec'
%       locktype: 'stim' or 'resp' (which event epoched data is locked to)
%       column: column of data.trialinfo by which to sort trials for plotting
%       conds:  cell containing specific conditions to plot within column (default: all of the conditions within column)
%       col:    colors to use for plotting each condition (otherwise will
%               generate randomly)
%       noise_method:   how to exclude data (default: 'trial'):
%                       'none':     no epoch rejection
%                       'trial':    exclude noisy trials (set to NaN)
%                       'timepts':  set noisy timepoints to NaN but don't exclude entire trials
%       plot_params:    .eb : plot errorbars ('ste','std',or 'none')
%                       .lw : line width of trial average
%                       .legend: 'true' or 'false'
%                       .label: 'name','number', or 'none'
%                       .sm: width of gaussian smoothing window (s)
%                       .textsize: text size of axis labels, etc
%                       .xlabel
%                       .ylabel
%                       .freq_range: frequency range to extract (only applies to spectral data)
%                       .bl_win: baseline correction window
%                       .xlim

load('cdcol.mat')

if nargin < 12 || isempty(plot_params)
    plot_params.eb = 'ste';
    plot_params.lw = 3;
    plot_params.legend = true;
    plot_params.label = 'name';
    plot_params.sm = 0.05;
    plot_params.textsize = 20;
    plot_params.xlabel = 'Time (s)';
    plot_params.ylabel = 'z-scored power';
    plot_params.freq_range = [70 180];
%     plot_params.xlim = [data.time(1), data.time(end)];
    plot_params.blc = true;
end

if nargin < 11 || isempty(noise_method)
    noise_method = 'trial';
end

if nargin < 10 || isempty(col)
    col = [cdcol.carmine;
        cdcol.ultramarine;
        cdcol.grassgreen;
        cdcol.lilac;
        cdcol.yellow;
        cdcol.turquoiseblue;
        cdcol.flamered;
        cdcol.periwinkleblue;
        cdcol.yellowgeen
        cdcol.purple];
end

if nargin < 5 || isempty(elecs)
    % load globalVar (just to get ref electrode, # electrodes)
    load([dirs.data_root,'/OriginalData/',sbj_name,'/global_',project_name,'_',sbj_name,'_',block_names{1},'.mat'])
    elecs = setdiff(1:globalVar.nchan,globalVar.refChan);
end


dir_out = [dirs.result_root,'/',project_name,'/',sbj_name,'/Figures/',datatype,'Data/',locktype,'lock'];
if ~exist(dir_out)
    mkdir(dir_out)
else
end

%% loop through electrodes and plot

for ei = 1:length(elecs)
    el = elecs(ei);
    data_all.wave = [];
    data_all.trialinfo = [];
%     column_data = cell(1,length(columns_to_keep));
    for bi = 1:length(block_names)
        bn = block_names{bi};
        dir_in = [dirs.data_root,'/',datatype,'Data/',sbj_name,'/',bn,'/EpochData/'];
        
        if plot_params.blc
            load(sprintf('%s/%siEEG_%slock_bl_corr_%s_%.2d.mat',dir_in,datatype,locktype,bn,el));
        else
            load(sprintf('%s/%siEEG_%slock_%s_%.2d.mat',dir_in,datatype,locktype,bn,el));
        end
        % Set xlim
        plot_params.xlim = [data.time(1), data.time(end)];

        
        % concatenante EEG data
        if strcmp(datatype,'Spec')
            data_all.wave = cat(2,data_all.wave,data.wave);
        else 
            data_all.wave = cat(1,data_all.wave,data.wave);
        end
        
        % concatenate trial info
        data_all.trialinfo = [data_all.trialinfo; data.trialinfo];

    end

    if nargin < 9 || isempty(conds)
        conds = unique(data.trialinfo.(column));
    end
    data_all.time = data.time;
    data_all.fsample = data.fsample;
    data_all.label = data.label;
    
    PlotTrialAvg(data_all,column,conds,col,plot_params)
    fn_out = sprintf('%s/%s_%s_%s_%s_%slock.png',dir_out,sbj_name,data.label,project_name,datatype,locktype);
    saveas(gcf,fn_out)
    close
end

