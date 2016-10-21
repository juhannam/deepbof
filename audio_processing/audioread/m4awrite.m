function m4awrite(D,SR,NBITS,FILE,OPTIONS)
% M4AWRITE   Write M4A file by use of external binary
%   M4AWRITE(Y,FS,NBITS,FILE) writes waveform data Y to mp4-encoded
%     file FILE at sampling rate FS using bitdepth NBITS.  
%     The syntax exactly mirrors WAVWRITE.  NBITS must be 16.
%   M4AWRITE(Y,FS,FILE) assumes NBITS is 16
%   M4AWRITE(Y,FILE) further assumes FS = 8000.
%
%   M4AWRITE(..., OPTIONS) specifies additional compression control 
%     options as a string passed directly to the faac encoder
%     program; default is '--quiet -h' for high-quality model.
%
%   Example: 
%   To convert a wav file to m4a (assuming the sample rate is 
%   supported):
%     [Y,FS] = wavread('piano.wav');
%     m4awrite(Y,FS,'piano.m4a');
%
%   Note: The actual m4a encoding is done by an external binary, 
%     faac, which is available for multiple platforms.  See
%     http://www.audiocoding.com/faac.html
%
%   Note: M4AWRITE will use the mex file popenw, if available, to
%     open a pipe to the encoder.  Otherwise, it will have to
%     write a large temporary file, then execute faac on that file.
%     popenw is available at: 
%       http://labrosa.ee.columbia.edu/matlab/popenrw.html
%     This is a nice way to save large audio files as the
%     incremental output of your code, but you'll have to adapt the
%     central loop of this function (rather than using it directly).
%
%   See also: m4aread, wavwrite, popenw.

% 2011-03-15 Original version adapted from mp3write.m
%
% $Header: /Users/dpwe/matlab/columbiafns/RCS/m4awrite.m,v 1.2 2007/07/26 15:09:16 dpwe Exp $

% find our baseline directory
[path] = fileparts(which('m4awrite'));

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
%faac = fullfile(path,['faac.',ext]);
%faac = 'faac';
[r,faac] = system('which faac');
if r ~= 0; error(faac); end
% strip trailing returns
faac = faac(1:end-1);

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
  OPTIONS = ' ';
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
  FILE = [FILE, '.m4a'];
end

nchan = nr;
nfrm = nc;

faacopts = [' ', OPTIONS, ...
            ' -R ', num2str(SR), ...
            ' -P ', ...
            ' -B ', num2str(NBITS), ...
            ' -C ', num2str(nchan), ...
            ' '];

%if exist('popenw') == 3
if length(which('popenw')) > 0

  % We have the writable stream process extensions
  cmd = ['"',faac,'"', faacopts, ' -o "',FILE,'" - '];

  p = popenw(cmd);
  if p < 0
    error(['Error running popen(',cmd,')']);
  end

  % We feed the audio to the encoder in blocks of <blksize> frames.
  % By adapting this loop, you can create your own code to 
  % write a single, large, M4A file one part at a time.
  
  blksiz = 10000;

  nrem = nfrm;
  base = 0;

  while nrem > 0
    thistime = min(nrem, blksiz);
    done = popenw(p,32767*D(:,base+(1:thistime)),'int16be');
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
  
  cmd = ['"',faac,'"', OPTIONS, '"',tmpfile, '" "', FILE, '"'];

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
