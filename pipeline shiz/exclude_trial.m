function [bad_epochs, bad_indices]=exclude_trial(pTS,pChan,onsetTS,chanNames, bef_time, aft_time, fsample)
%   Finds trials with pathological events. For each pathological event,
%   finds the [pTS - 100 ~ pTS + 100] samples, and detects whether
%   it overlaps with any [onsetTs - 300 ~ onsetTs + 800].
%   Output:    returns {channel index}(trial index)
%   pTS:       timestamps of pathological events.
%   pChan:     corresponding channels (in bipolar).
%   onsetTS:   timestamps of behavioral onset. Single vector.
%   chanNames: channel lables. Names and channel order should match
%   "pChan".
%   Written by Su Liu.
%   suliu@stanford.edu

chan=cell(length(pChan),2);
% for i = 1:length(pChan)
%     chan(i,:) = strsplit(pChan{i},'-');
% end
T = length(onsetTS);
onsetTS = round(onsetTS*fsample);
bef_time = round(bef_time*fsample);
aft_time = round(aft_time*fsample);
win_size = fsample/10;

for i = 1:length(pChan)
    try
        chan(i,:) = strsplit(pChan{i},'-');
    catch
        temp=strsplit(pChan{i},'-');
        if length(temp)==4
            chan(i,1)=strcat(temp(1),'-',temp(2));
            chan(i,2)=strcat(temp(3),'-',temp(4));
        else
            error('Channel name mismatch');
        end
    end
end

bad_epochs = cell(1,length(chanNames));
bad_indices = cell(T,length(chanNames));
for i = 1:length(chanNames)
    n = 1;
    ind = unique([find(strcmp(chan(:,1),chanNames(i)) == 1 );find(strcmp(chan(:,2),chanNames(i)) == 1 )]);
    target = pTS(ind);
    pind = [target-win_size target+win_size];
    pindc = [];
    if ~isempty(target)
        for l = 1:length(target)
            pindc = [pindc pind(l,1):pind(l,2)];
        end
    end
    for k = 1:T % Across trials 
        behInd = onsetTS(k) + (bef_time:aft_time);
        if sum(ismember(pindc,behInd)) ~= 0
            bad_epochs{i}(n) = k;
            n = n+1;
            bad_indices{k,i}=find(ismember(behInd,target));
        end        
    end
end

