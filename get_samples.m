function sampled_data = get_samples(file_list, options)
%
% collect multiple frames of mel-freq. spectrogram for local feature learning 
% using either random or onset-based sampling 
%
% Input arguments:
% file_list:        cell that includes the list of filenames
% options:          Matlab structure that specifies the feature learning
%                   algorithm and parameters

fid = fopen(file_list);   
C = textscan(fid,'%s');
file_names = C{1};
fclose(fid);  

spec_data = cell(length(file_names),1);
nf_data = cell(length(file_names),1);

% load files
for i=1:length(file_names)
    temp = load(file_names{i});
    mel_spec = double(temp.data);

    % amplitude compression
    if options.preproc.comp.amp_compress.log_c.on
        mel_spec = log10(1+options.preproc.comp.amp_compress.log_c.gain*mel_spec);
    end

    spec_data{i} = mel_spec;
    nf_data{i} = double(temp.nf);
end

% count the total number of samples in the dataset
total_num_samples = 0;
for i=1:length(file_names)
    total_num_samples = total_num_samples + size(spec_data{i},2);
end

num_total_segments = total_num_samples/options.fl.sampling.segment_frames;
if num_total_segments < options.fl.sampling.num_samples
    repeat = options.fl.sampling.num_samples/num_total_segments;
else
    repeat = 1;
end

samples_data_cell = cell(length(file_names),1);

% sampling 
for i=1:length(file_names)
     % chunk- multiple frames 
     if options.preproc.patch.size > 1
        chunk_spec = convertToChunk(spec_data{i}, options.preproc.patch.size, 1);
     else
        chunk_spec = spec_data{i};
     end
 
     num_segs = floor(size(chunk_spec,2)/options.fl.sampling.segment_frames);
     seg_index = [0:num_segs-1];

     sample_index2 = [];
     for r = 1:repeat
         if strcmp(options.fl.sampling.type, 'random')
             sample_index = floor((seg_index + rand(1,length(seg_index))*0.999)*options.fl.sampling.segment_frames) + 1;
         elseif strcmp(options.fl.sampling.type, 'onset_sync_max')
             sample_index = seg_index*options.fl.sampling.segment_frames;
             for j=1:length(seg_index);
                 [max_valuee, max_index] =  max(nf_data{i}(sample_index(j) + [1:options.fl.sampling.segment_frames]));
                 nf_data{i}(sample_index(j) + max_index) = 0;  % for next repeat of max search
                 sample_index(j) = sample_index(j) + max_index;
             end
         end
         sample_index2 = [sample_index2  sample_index];
     end
     samples_data_cell{i} = chunk_spec(:, sample_index2); 
end

sampled_data = [samples_data_cell{:}];

% trim sampled data
num_samples = size(sampled_data,2);
if num_samples > options.fl.sampling.num_samples
    rand_index = randperm(num_samples);
    sampled_data = sampled_data(:,rand_index(1:options.fl.sampling.num_samples));
end



