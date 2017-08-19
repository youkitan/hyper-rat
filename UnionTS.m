function ts_out = UnionTS(cfg_in,ts1,ts2)
% function ts_out = UnionTS(cfg,ts1,ts2)
%
% union of ts objects
%
% output is resorted based on start times (ascending)
%
% MvdM 2014-08-28 initial version

cfg_def = [];
cfg = ProcessConfig(cfg_def,cfg_in);

mfun = mfilename;

%% Sanity checks
if isempty(ts1) % function should work for empty arguments
    ts1 = ts();
end

if isempty(ts2)
    ts2 = ts([],[]);
end

if ~CheckTS(ts1) | ~CheckTS(ts2)
   error('Malformed TS.'); 
end

if length(ts1.t) ~= length(ts2.t)
    error('different sized ts inputs!')
end

if horzcat(ts1.label{:}) ~= horzcat(ts2.label{:})
    error('there are different cells?')
end

%% do the things

% preallocate
ts_out = ts();
ts_out.t = cell(size(ts1.t));
ts_out.label = ts1.label;

% iterate and merge
for iC = 1:length(ts1.t)
    curr_t = vertcat(ts1.t{iC},ts2.t{iC});
    curr_t = sort(curr_t);
    ts_out.t{iC} = curr_t;
end

% housekeeping
ts_out.cfg = ts1.cfg;
ts_out.cfg.history.mfun = cat(1,ts_out.cfg.history.mfun,mfun);
ts_out.cfg.history.cfg = cat(1,ts_out.cfg.history.cfg,{cfg});