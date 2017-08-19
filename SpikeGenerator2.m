function [S_out] = SpikeGenerator2(cfg_in,tc_in,pos_in)
%% SpikeGenerator Spike train generator
%   [S_out] = SpikeGenerator returns a spiketrain created using input tuning curves and position. 
% 
%   INPUTS:
%       cfg_in: config field
%        tc_in: input tuning curve struct (output from MakeTC)
%       pos_in: input tsd struct containing position data
%            
%   OUTPUTS:
%       S_out = output ts struct
%
%   CONFIG OPTIONS: 
%       cfg.avgSpikes = []; If non-empty, force mean number of spikes per pass of place field 
%       cfg.nTrials = 1; Number of trials to run poisson spike generation
%       cfg.fieldMethod = 'template'; Choose which set of cells to use. Alt: 'field',
%       'all'
%       cfg.convertFile = 1; If false, output is in a non-ts format.
%
%
% youkitan - 2016-09-06 initial ver

%% Parse cfg parameters and error check inputs
cfg_def.avgSpikes = [];
cfg_def.fr_multiplier = 1;
cfg_def.nTrials = 1;
cfg_def.fieldMethod = 'template';
cfg_def.convertFile = 1; 
cfg_def.verbose = 0;

cfg = ProcessConfig(cfg_def,cfg_in);
mfun = mfilename;

if ~CheckTSD(pos_in)
    error('~~~~~~~~~~ Input position is not a correctly formed tsd ~~~~~~~~~~')
elseif ~isstruct(tc_in)
    error('~~~~~~~~~~ Input tuning curve is not a struct ~~~~~~~~~~')
elseif ~isfield(tc_in,'tc')
    error('~~~~~~~~~~ Input tuning curve has no tc field! ~~~~~~~~~~')
end

%% Initial setup
nPosDims = size(pos_in.data,1);

% create internal variables
if pos_in.tvec(1) ~= 1
    tveci = pos_in.tvec - min(pos_in.tvec);
else
    tveci = pos_in.tvec;
end
pveci = pos_in.data;

%% Process data

switch nPosDims
    case 1
        % choose which cells to use
        switch cfg.fieldMethod
            case 'template'
                field_order = tc_in.template_idx;
             
            case 'field'
                field_order = tc_in.field_template_idx;
                
            case 'all'
                field_order = 1:size(tc_in.tc,1);
        end
        
        % initialize output data
        data_out.spiketimes = {};
        data_out.field_order = field_order;
        
        % non repeating variables
        [vals,idx,j] = unique(pveci);
        
        zero_rate_cells = [];
        
        tc_in.tc = tc_in.tc';
        
        % iterate process for each cell
        for iC = 1:length(field_order)
 
            % convert firing rate from a function of position to a function of time (for given run) 
            curr_tc = tc_in.tc(field_order(iC),:);
            pos_rate = curr_tc(pveci);
%             time_rate = @(t) interp1(vals,pos_rate(idx),interp1(pos_in.tvec,pveci,t));

            time_rate = @(t) cfg.fr_multiplier.*(interp1(vals,pos_rate(idx),interp1(tveci,pveci,t))) ... %main interpolation
                .* (abs(tveci(nearest_idx3(t,tveci,-1)) - tveci(nearest_idx3(t,tveci,1))) < .5)' ... %conditional for breaks in time  (less than .5 second of break)
                + 0; %sets rate to zero for large breaks in time (expects continuous time)
            % input into time_rate must be Nx1 array!


            % calculate normalizing constant to get normalized spike counts
            if ~isempty(cfg.avgSpikes)
                rateAUC = trapz(tveci,time_rate(tveci')); %find integral of rate
                
                if rateAUC < 0.01;
                    %                     disp(['rate is (basically) zero for cell ' num2str(iC)]); %sanity check
                    zero_rate_cells = horzcat(zero_rate_cells,iC);
                    A = 1;
                else
                    A = cfg.fr_multiplier*(cfg.avgSpikes/rateAUC); %normalizing factor
                end
                
                % new rate function with normalizing constant
                time_rate = @(t) A*cfg.fr_multiplier.*(interp1(vals,pos_rate(idx),interp1(tveci,pveci,t))) ... %main interpolation
                    .* (abs(tveci(nearest_idx3(t,tveci,-1)) - tveci(nearest_idx3(t,tveci,1))) < .5)' ... %conditional for breaks in time  (less than .5 second of break)
                    + 0; %sets rate to zero for large breaks in time (expects continuous time)
                % input into time_rate must be Nx1 array!
                
                if A > 10000
                    disp(sprintf('seems to be a problem still?',iC))
                    A = 1;
                end
                
            else
                A = cfg.fr_multiplier*1;
            end
 
            
            max_rate = A*cfg.fr_multiplier*max(curr_tc);
            total_time = tveci(end)-tveci(1);
            spikes = genInhomogeneousPoisson([],max_rate,total_time,time_rate);
            data_out.spiketimes{iC} = spikes{:};
            
        end
        
        if any(zero_rate_cells) && cfg.verbose
            disp([num2str(length(zero_rate_cells)) ' cells have zero firing rate!'])
            spf = sprintf('%d ',zero_rate_cells);
            disp(['cells: ' spf])
        end
        
    case 2
        error('spiking in 2 dimensions not yet implemented!')
        
end

%% sanity check
if isempty(vertcat(data_out.spiketimes{:}))
    disp('no spikes!!!')
end

%% Format for output

if cfg.convertFile
    S_out = ts;
    for iCell = 1:length(data_out.field_order)
        for iT = 1:cfg.nTrials
            S_out.t{iT,iCell} = data_out.spiketimes{iT,iCell}(:); %can be multiple trials
            S_out.label{iCell} = data_out.field_order(iCell);
        end
    end
    S_out.cfg.history.mfun = cat(1,S_out.cfg.history.mfun,mfun);
    S_out.cfg.history.cfg = cat(1,S_out.cfg.history.cfg,{cfg});
else
    S_out = data_out;
end


end