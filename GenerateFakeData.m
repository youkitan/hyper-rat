
mvdmlab_path = '/Users/youkitanaka/Documents/Github/vandermeerlab/code-matlab/shared'; 
addpath(genpath(mvdmlab_path))

addpath(genpath('/Users/youkitanaka/Desktop/MIND 2017/rat hyperalignment'))
%% Make functions
sg = @(amplitude,x,mean,width) amplitude*exp(((-(x-mean).^2))./(2*width.^2));

%% Load variables

% create "tracks"
track1 = 1:100;
track2 = 101:200;

% create "runs"
t = 10; %total experiment time
dt = 0.001; %timebins in s
tvec = 0:dt:t; % a vector of length(t/dt) containing the sampling points

tmp = 10*tvec;
a = 1;
b = 99;
result = a + b.*(tmp - min(tmp))./(max(tmp) - min(tmp));

pos1 = tsd();
pos1.data = round(result(1:end-1));
pos1.tvec = tvec(1:end-1);
% plot(pos1)

%% Set place cell parameters for variable 1 (e.g. left)
pf.amp = [16,22,13,13,20,20]; %maximum firing rate or amplitude
pf.sigma = [5,5,5,5,5,5]; %width of the gaussian
pf.ctr = [15,30,45,60,75,80]; % mean or center of place field

pf2.amp = [16,22,13,13,20,20]; %maximum firing rate or amplitude
pf2.sigma = [5,5,5,5,5,5]; %width of the gaussian
pf2.ctr = [75,30,80,15,45,60]; % mean or center of place field

nCells = length(pf.amp);
nTime = length(track1);
[tc1,tc2] = deal(zeros(nCells,nTime));

for iC = 1:nCells
    tc1(iC,:) = sg(pf.amp(iC),track1,pf.ctr(iC),pf.sigma(iC));
    tc2(iC,:) = sg(pf2.amp(iC),track1,pf2.ctr(iC),pf2.sigma(iC));
end

repeats = 10;

%% make Q for left
TC1 = tc();
TC1.tc = tc1;
tc_out = DetectPlaceCells1D([],TC1);

for i = 1:repeats
    S_curr = SpikeGenerator2([],tc_out,pos1);
    if i == 1
        S_out = S_curr;
    else
        S_curr.t = cellfun(@(x) x+10*(i-1),S_curr.t,'unif',0);
        S_out = UnionTS([],S_out,S_curr);
    end
end
cfg_Q.smooth = 'gauss';
cfg_Q.gausswin_sd = 0.5;
cfg_Q.tvec_edges = 0:dt:100;
Q_temp = MakeQfromS(cfg_Q,S_out);
Q1 = Q_temp.data;

%% make Q for right
TC2 = tc();
TC2.tc = tc2;
tc_out = DetectPlaceCells1D([],TC2);

for i = 1:repeats
    S_curr = SpikeGenerator2([],tc_out,pos1);
    if i == 1
        S_out = S_curr;
    else
        S_curr.t = cellfun(@(x) x+10*(i-1),S_curr.t,'unif',0);
        S_out = UnionTS([],S_out,S_curr);
    end
end

cfg_Q.smooth = 'gauss';
cfg_Q.gausswin_sd = 0.5;
cfg_Q.tvec_edges = 0:dt:100;

Q_temp = MakeQfromS(cfg_Q,S_out);
Q2 = Q_temp.data;