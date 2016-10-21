function song_features = local_feature_encoding(file_list,  pca_params, rbm_params, rbmModel, options)
%
% extract local audio features given learned parameters and summarize them into song-level features
%
% Input arguments:
% file_list:        cell that includes the list of filenames
% scratch_path:     directory were the learned params are to be stored
% pca_params:       PCA whitening matrix
% rbm_params:       RBM weight and bias
% options:          Matlab structure that specifies the feature learning
%                   algorithm and parameters

fid = fopen(file_list);

C = textscan(fid,'%s');
file_names = C{1};
fclose(fid);

num_files = length(file_names);
song_features = cell(length(options.pooling.size),1);

count = 0;

num_frames = zeros(1,num_files);

fprintf(1,'local feature encoding  0 / %d ', num_files);
for i=1:num_files
    if ~rem(i,100)
       fprintf(repmat('\b',1,length(num2str(i-1)) + 3 + length(num2str(num_files)) ));
       fprintf(1,'%d / %d', i, num_files);
    end

    temp = load(file_names{i});
    
    num_frames(i) = size(temp.data,2);

    if options.preproc.trim.on
        start_index = floor(options.preproc.trim.start*options.preproc.tfr.fs/options.preproc.tfr.hop)+1;
        start_index = max(start_index,1);        

        end_index = floor((options.preproc.trim.start + options.preproc.trim.length)*options.preproc.tfr.fs/options.preproc.tfr.hop)+1;
        end_index = min(end_index, size(temp.data,2));

        temp.data = temp.data(:,start_index:end_index);
        temp.nf = temp.nf(:,start_index:end_index);
    end

    spec_data = double(temp.data);

    % amplitude compression
    if options.preproc.comp.amp_compress.log_c.on
        spec_data = log10(1+options.preproc.comp.amp_compress.log_c.gain*spec_data);
    end

    % chunk
    if options.preproc.patch.size > 1
        spec_data = convertToChunk(spec_data, options.preproc.patch.size, 1);
    end
    
    % PCA whitening
    if options.preproc.pca.on
        spec_data = bsxfun(@minus, spec_data, pca_params.M);
        spec_data = pca_params.V*spec_data;
    elseif options.preproc.norm.standardization.on
        spec_data = bsxfun(@rdivide,bsxfun(@minus, spec_data, standard_params.M), standard_params.std);
    end
    
    % encoding    
    L1_features = feedForwardLinearRBM(spec_data, rbm_params, rbmModel);

    % pooling
    for j=1:length(options.pooling.size)    
    	pooling_size = options.pooling.size(j);

        if isempty(song_features{j})
            song_features{j} = zeros(size(L1_features,1), length(file_list));
        end		     

        if (pooling_size > 1)
            num_pooled = ceil(size(L1_features,2)/pooling_size);
            L1_features_pooled = zeros(size(L1_features,1),num_pooled);
            index = 1;
            for p=1:num_pooled
                L1_features_pooled(:,p) = max(L1_features(:,[index:min(index+pooling_size-1, size(L1_features,2))]),[],2);
                index = index + pooling_size;
            end
            song_features{j}(:,i) = mean(L1_features_pooled, 2);
        else
            song_features{j}(:,i) = mean(L1_features, 2);
        end
    end
end
fprintf(1, '\n');