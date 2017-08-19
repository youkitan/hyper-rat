%% simple gaussian

function [sg] = simple_gaussian(amplitude,x,mean,width)
    sg = amplitude*exp(((-(x-mean).^2))./(2*width.^2));
end
