function save_song_level_features_tagatune(data_file, tag_file, scratch_folder, options)
%
% compute AROC and Mean Average-precision
%
% Input arguments:
% data_file:        list of training, validation and test data files 
% tag_file:         list of training, validation and test label files 
% scratch_path:     directory were the learned params are to be stored
% options:          Matlab structure that specifies the feature learning
%                   algorithm and parameters

% read file/label 
for i=1:3
    fid = fopen(data_file{i});
    C = textscan(fid,'%s');  
    file_names{i} = C{1};
    fclose(fid); 

    tag_label{i} = dlmread(tag_file{i}); 
end

% learn sparse features                                                                                        
[pca_params, rbm_params, rbmModel] = local_feature_learning(data_file{1}, scratch_folder, options);

% extract features
train_song_features = local_feature_encoding(data_file{1}, pca_params, rbm_params, rbmModel, options);
valid_song_features = local_feature_encoding(data_file{2}, pca_params, rbm_params, rbmModel, options);
test_song_features = local_feature_encoding(data_file{3}, pca_params, rbm_params, rbmModel, options);

% get labels 
train_label = tag_label{1}; 
valid_label = tag_label{2}; 
test_label = tag_label{3};   

for i=1:length(options.pooling.size)
    train_data = train_song_features{i};
    valid_data = valid_song_features{i};
    test_data = test_song_features{i};

    options2 = options;
    options2.pooling.size = options.pooling.size(i);

    [data_path pca_path feature_path pooling_path] = getParamsPath(options2);
    mkdir([scratch_folder filesep pooling_path]);
    save([scratch_folder filesep pooling_path filesep sprintf('song_level_features.mat')], ...
        'train_data', 'train_label', 'valid_data', 'valid_label','test_data', 'test_label');
end

