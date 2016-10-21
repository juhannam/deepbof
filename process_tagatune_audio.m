% 
% preprocessing mp3 files into mel-frequency spectrogram
%

addpath(genpath('./audio_processing'));
data_path = '/media/data/shared/datasets/Magnatagatune/tagatune_lists/';
save_path ='/media/data/shared/datasets/Magnatagatune/mel_spec/';

mkdir(save_path);

options.window_size = 1024;
options.hop = 512;
options.fs = 22050;
options.window_type = 'hann';
options.file_format = 'mp3';
options.mel_spec_bands = 128;

% agc paramters
options.tf_agc_on = 1;
options.tf_agc.t_scale = 0.5;
options.tf_agc.f_scale = 2;
options.tf_agc.eps = 0.01;
options.tf_agc.env_type = 2; % 1 = 'symmetric', 2 = 'att_dec',

options.tf_data = 'mel_spectrogram'; %'mel_spectrogram', 'mel_spectrogram','spectrogram'

% novelty function
options.novelty.tf_data = 'mel_spectrogram';
options.novelty.bands = 40;
options.novelty.log_c = 100;

% all labeled files (train, validation, test)
fid = fopen([data_path 'tagatune_supervised.txt']);
C = textscan(fid,'%s');
fclose(fid);
file_list = C{1};

num_songs = length(file_list);

if strcmp(options.tf_data, 'mel_spectrogram')
    f2a2 = fft2melmx(options.window_size, options.fs, options.mel_spec_bands);
    f2a2 = f2a2(:,1:(options.window_size/2+1));
end

if strcmp(options.novelty.tf_data, 'mel_spectrogram')
    f2a2_novelty = fft2melmx(options.window_size, options.fs, options.novelty.bands);
    f2a2_novelty = f2a2_novelty(:,1:(options.window_size/2+1));
end

xf = [];
warning off;
for i=1:num_songs
    prev_xf = xf;
    xf = getSpecgram(file_list{i}, options);

     % automatic gain control
    if sum(sum(xf))
        if options.tf_agc_on
            xf = process_tf_agc(xf, options);
        end
    else
        xf = prev_xf;
        disp(['no content in the file :' num2str(i) ' - ' file_list{i} ]);
    end
    
    % mel spectrogram
    if strcmp(options.tf_data, 'mel_spectrogram')
        data = f2a2 * xf;
    elseif strcmp(options.tf_data, 'mfcc')
        data = mfcc_spec(xf, options.fs);
    end
   
    % novelty function
    mel_spec = log10(1+options.novelty.log_c*f2a2_novelty * xf);
    rect_data = max(diff(mel_spec,1,2),0);
    nf = [0 mean(rect_data,1)];

    % file name
    start_index = strfind(file_list{i},'mp3')+19;
    end_index = length(file_list{i})-3;
    
    save_folder = [save_path file_list{i}(start_index:start_index+1)];
    if ~exist(save_folder,'dir')
        mkdir(save_folder);
    end
    
    % to reduce data size 
    data = single(data);
    nf = single(nf);
    filename = file_list{i};

    save([save_folder filesep file_list{i}(start_index:end_index) 'mat'], 'data', 'nf', 'filename');
    
    if rem(i,100) == 0
        fprintf('%3d.',i);
    end
end
warning on;
