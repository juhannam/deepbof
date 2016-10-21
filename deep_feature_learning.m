function deep_feature_learning(scratch_folder, options)
%
% conduct song-level pretraining 
%
% Input arguments:
% scratch_path:     directory were the learned params are to be stored
% options:          Matlab structure that specifies the feature learning
%                   algorithm and parameters

[data_path pca_path feature_path pooling_path base_path deep_path] = getParamsPath(options);


if options.preproc.trim.on
    disp(['loading... ' [scratch_folder filesep pooling_path filesep sprintf('song_level_features_trim.mat')]]);
    load([scratch_folder filesep pooling_path filesep sprintf('song_level_features_trim.mat')]);
else
    disp(['loading... ' [scratch_folder filesep pooling_path filesep sprintf('song_level_features.mat')]]);
    load([scratch_folder filesep pooling_path filesep sprintf('song_level_features.mat')]);
end

if exist('song_features', 'var')
    train_data = song_features;
    clear song_features;
end

%%%%%% stacked RBMs
rbm_params = cell(options.deep_networks.num_hidden_layers,1);
dbn_model = cell(options.deep_networks.num_hidden_layers,1);

if options.deep_networks.input_normalization
    max_value = max(train_data, [], 1);
    train_data2 = bsxfun(@rdivide, train_data, max_value);
else
    train_data2 = train_data;
end

for j=1:options.deep_networks.num_hidden_layers
    save_path = [scratch_folder filesep deep_path{j}];
    if ~exist(save_path, 'dir')
        mkdir(save_path);
    end
    log_file = [save_path filesep 'log.txt'];

    if options.deep_networks.rbm_params{j}.relu 
       rbm_exist = exist([save_path filesep 'rbm_relu_params.mat']);
    else
       rbm_exist = exist([save_path filesep 'rbm_params.mat']);
    end 

    if ~rbm_exist
        if j == 1
            rbm_params = init_rbm(size(train_data2,1), options.deep_networks.rbm_params{j});
        else
            rbm_params = init_rbm(options.deep_networks.rbm_params{j-1}.hidden_layer, options.deep_networks.rbm_params{j});
        end

        warning off;
        randn('seed',1); rand('seed',1);
            
        % train RBM
        rbm = train_rbm(train_data2, rbm_params, log_file);
        warning on;

        rbmModel.vishid = rbm.weight;
        rbmModel.hidbiases = rbm.hbias;
        rbmModel.visbiases = rbm.vbias;
        if options.deep_networks.rbm_params{j}.relu 
            save([save_path filesep 'rbm_relu_params.mat'], 'rbm_params', 'rbmModel');
        else
            save([save_path filesep 'rbm_params.mat'], 'rbm_params', 'rbmModel');
        end
    else
        if options.deep_networks.rbm_params{j}.relu 
            load([save_path filesep 'rbm_relu_params.mat'], 'rbm_params', 'rbmModel');
        else
            load([save_path filesep 'rbm_params.mat'], 'rbm_params', 'rbmModel');
        end
    end

    % go to upper layer
    if options.deep_networks.rbm_params{j}.relu 
        hidden = rbm_params.scl * (bsxfun(@plus, rbmModel.vishid*train_data2, rbmModel.hidbiases));
        train_data2 = max(hidden,0);
    else
        train_data2 = feedForwardLinearRBM(train_data2, rbm_params, rbmModel);
    end
end

