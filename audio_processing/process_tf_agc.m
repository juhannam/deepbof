function [y, fbg] = process_tf_agc(x, options)
%
% x: spectrogram
%
% sligh modified version of Dan Ellis' tf_agc.m : http://labrosa.ee.columbia.edu/matlab/tf_agc/

ftsr = options.fs/options.hop;
nbands = max(10,20/options.tf_agc.f_scale); % 10 bands, or more for very fine f_scale
mwidth = options.tf_agc.f_scale*nbands/10; % will be 2.0 for small f_scale
f2a = fft2melmx(options.window_size, options.fs, nbands, mwidth);
f2a = f2a(:,1:(options.window_size/2+1));

audgram = f2a * x;

if options.tf_agc.env_type == 1
    % noncausal, time-symmetric smoothing
    % Smooth in time with tapered window of duration ~ t_scale
    tsd = round(options.tf_agc.t_scale*ftsr)/2;
    htlen = 6*tsd; % Go out to 6 sigma
    twin = exp(-0.5*((([-htlen:htlen])/tsd).^2))';
    
    % reflect ends to get smooth stuff
    AD = audgram;
    fbg = filter(twin,1,...
        [AD(:,htlen:-1:1),...
        AD,...
        AD(:,end:-1:(end-htlen+1)),...
        zeros(size(AD,1),htlen)]',...
        [],1)';
    % strip "warm up" points
    fbg = fbg(:,length(twin)+[1:size(xf,2)]);
    
else
    
    % traditional attack/decay smoothing
    fbg = zeros(size(audgram,1),size(audgram,2));
    state = zeros(size(audgram,1),1);
    alpha = exp(-(1/ftsr)/options.tf_agc.t_scale);
    for j = 1:size(audgram,2)
        state = max([alpha*state,audgram(:,j)],[],2);
        fbg(:,j) = state;
    end
end

% map back to FFT grid, flatten bark loop gain
sf2a = sum(f2a);
E = diag(1./(sf2a+(sf2a==0))) * f2a' * fbg;

% Remove any zeros in E (shouldn't be any, but who knows?)
E(E(:)<=0) = min(E(E(:)>0));

y = x./(E + options.tf_agc.eps);
