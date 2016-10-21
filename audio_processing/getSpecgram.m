function [y, yp, xt2] = getSpecgram(file, options)


%read audio files
if strcmp(options.file_format,'aiff')
    [xt,fs] = aiffread(file);
elseif strcmp(options.file_format,'wav')
    [xt,fs] = wavread(file);
elseif strcmp(options.file_format,'au')
    [xt,fs] = auread(file);
elseif strcmp(options.file_format,'mp3')
    [xt,fs,nbits,opts] = mp3read(file);
end

% take only one channel
if size(xt,2) == 2
    xt = xt(:,1);
end

% trim
if isfield(options, 'file_start')
    xt = xt(1+options.file_start*fs:end);
end

% adjust length
if isfield(options, 'file_length')
    if length(xt) > options.file_length*fs
        xt = xt(1:options.file_length*fs);
    elseif length(xt) < options.file_length*fs
        xt = [xt; zeros(options.file_length*fs-length(xt),1)];
    end
end

% resample
if options.fs ~= fs
    xt = resample(xt, options.fs, fs);
end

% spectrogram
xt2 = [zeros(options.window_size/2,1); xt; zeros(options.window_size/2,1)];

win = feval(options.window_type, options.window_size);

xx = stft(xt2, options.window_size, win, options.hop);
y = abs(xx);
yp = angle(xx);
y = y + max(max(y))*0.0001;


