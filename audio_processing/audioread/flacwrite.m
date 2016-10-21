function flacwrite(D,SR,NBITS,FILE,OPTIONS)
% FLACWRITE   Write FLAC file by use of external binary
%   FLACWRITE(Y,FS,NBITS,FILE) writes waveform data Y to mp4-encoded
%     file FILE at sampling rate FS using bitdepth NBITS.  
%     The syntax exactly mirrors WAVWRITE.  NBITS must be 16.
%   FLACWRITE(Y,FS,FILE) assumes NBITS is 16
%   FLACWRITE(Y,FILE) further assumes FS = 8000.
%
%   FLACWRITE(..., OPTIONS) specifies additional compression control 
%     options as a string passed directly to the flac encoder
%     program; default is '--quiet -h' for high-quality model.
%
%   Example: 
%   To convert a wav file to flac (assuming the sample rate is 
%   supported):
%     [Y,FS] = wavread('piano.wav');
%     flacwrite(Y,FS,'piano.flac');
%
%   Note: The actual flac encoding is done by an external binary, 
%     f;ac, which is available for multiple platforms.  See
%     http://flac.sourceforge.net/
%
%   Note: FLACWRITE will use the mex file popenw, if available, to
%     open a pipe to the encoder.  Otherwise, it will have to
%     write a large temporary file, then execute flac on that file.
%     popenw is available at: 
%       http://labrosa.ee.columbia.edu/matlab/popenrw.html
%     This is a nice way to save large audio files as the
%     incremental output of your code, but you'll have to adapt the
%     central loop of this function (rather than using it directly).
%
%    See also  FLACREAD2, WAVWRITE, POPENW


% $Header: /Users/dpwe/matlab/columbiafns/RCS/mp3write.m,v 1.2 2007/07/26 15:09:16 dpwe Exp $

% find our baseline directory
[path] = fileparts(which('flacwrite'));

% %%%%% Directory for temporary file (if needed)
% % Try to read from environment, or use /tmp if it exists, or use CWD
tmpdir = getenv('TMPDIR');
if isempty(tmpdir) || exist(tmpdir,'file')==0
  tmpdir = '/tmp';
end
if exist(tmpdir,'file')==0
  tmpdir = '';
end
% ensure it exists
%if length(tmpdir) > 0 && exist(tmpdir,'file')==0
%  mkdir(tmpdir);
%end

%%%%%% Command to delete temporary file (if needed)
rmcmd = 'rm';

%%%%%% Location of the binary - attempt to choose automatically
%%%%%% (or edit to be hard-coded for your installation)
ext = lower(computer);
if ispc
  ext = 'exe';
  rmcmd = 'del';
end
%flac = fullfile(path,['flac.',ext]);
[r,flac] = system('which flac');
if r ~= 0; error(flac); end
% strip trailing returns
flac = flac(1:end-1);

%%%% Process input arguments
% Do we have NBITS?
mynargin = nargin;
if ischar(NBITS)
  % NBITS is a string i.e. it's actually the filename
  if mynargin > 3
    OPTIONS = FILE;
  end
  FILE = NBITS;
  NBITS = 16;
  % it's as if NBITS had been specified...
  mynargin = mynargin + 1;
end

if mynargin < 5
  OPTIONS = '';
end

[nr, nc] = size(D);
if nc < nr
  D = D';
  [nr, nc] = size(D);
end
% Now rows are channels, cols are time frames (so interleaving is right)

%%%%% add extension if none (like wavread)
[path,file,ext] = fileparts(FILE);
if isempty(ext)
  FILE = [FILE, '.flac'];
end

nchan = nr;
nfrm = nc;

flacopts = [' ', OPTIONS, ...
            ' --channels=',num2str(nchan), ...
            ' --endian=little --sign=signed --bps=',num2str(NBITS), ...
            ' --sample-rate=',num2str(SR), ...
            ' --force-raw-format -'];

%if exist('popenw') == 3
if length(which('popenw')) > 0

  % We have the writable stream process extensions
  cmd = ['"',flac,'"', flacopts, ' -f -o "',FILE,'"'];

  p = popenw(cmd);
  if p < 0
    error(['Error running popen(',cmd,')']);
  end

  % We feed the audio to the encoder in blocks of <blksize> frames.
  % By adapting this loop, you can create your own code to 
  % write a single, large, flac file one part at a time.
  
  blksiz = 10000;

  nrem = nfrm;
  base = 0;

  while nrem > 0
    thistime = min(nrem, blksiz);
    done = popenw(p,32767*D(:,base+(1:thistime)),'int16le');
    nrem = nrem - thistime;
    base = base + thistime;
    %disp(['done=',num2str(done)]);
  end

  % Close pipe
  popenw(p,[]);

else 
  disp('Warning: popenw not available, writing temporary file');
  
  tmpfile = fullfile(tmpdir,['tmp',num2str(round(1000*rand(1))),'.wav']);

  wavwrite(D',SR,tmpfile);
  
  cmd = ['"',flac,'" ', OPTIONS, ' "',tmpfile, '" -f -o "', FILE, '"'];

  mysystem(cmd);

  % Delete tmp file
  mysystem([rmcmd, ' "', tmpfile,'"']);

end 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function w = mysystem(cmd)
% Run system command; report error; strip all but last line
[s,w] = system(cmd);
if s ~= 0 
  error(['unable to execute ',cmd,' (',w,')']);
end
% Keep just final line
w = w((1+max([0,findstr(w,10)])):end);
% Debug
%disp([cmd,' -> ','*',w,'*']);
