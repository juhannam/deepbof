function y = stft(x, N, win, hop, sr, pre_zeropadding)
% y = stft(x, N, win, hop, sr)
%   Short-time Fourier transform
%   x: input vector (1-D)
%   N: FFT size (default: 256)
%   win: window size (when it is a scholar value) or window function (when
%   it is given as a vector) (default: FFT size and Hann window)
%   hop: hop size (default: half window size)
%   sr: sampling rate (default: 8000Hz)
%   pre_zeropadding: size of zeros attached to the beginning of x
%
% Juhan Nam
% Feb-01-2013: initial version

if nargin < 2
    N = 256;
end
if nargin < 3
    win = N;
end
if nargin < 4
    if length(win) > 1
        hop = floor(length(win)/2);
    else
        hop = floor(win/2);        
    end
end
if nargin < 5
    sr = 8000; 
end
if nargin < 6
    pre_zeropadding = 0; 
end

% make x a column
x = x(:);

if length(win) == 1
    w = hann(win,'periodic');
else
    w = win;
end
w = w(:);

if length(w) > N
    N = length(w);
end

% if necessary, do pre-zeropadding for time alignment
if pre_zeropadding > 0
    x = [zeros(pre_zeropadding,1); x];
end

% fit x to FFT size
l = length(x);
if l >= N
    l2 = ceil((l-N)/hop)*hop + N;
else
    l2 = N;
end
x = [x; zeros(l2-l,1)];
M = (l2-N)/hop+1;

% fft loop
y = zeros(N/2+1, M);
for k=1:M
    temp = fft(w.*x((k-1)*hop+[1:length(w)]),N);
    y(:,k) = temp(1:N/2+1);
end

if nargout == 0
    t = [0:M-1]*hop/sr;
    f = [0:N/2]/N*sr;
    imagesc(t,f,20*log10(abs(y)));
    axis xy;
    xlabel('time [sec]');
    ylabel('freq. [Hz]');
end


