% 
% the main script that conducts unsupervised learning from local feature
% learning to song-level pretraining for DNN
%

data_path = '/media/data/shared/datasets/Magnatagatune/mel_spec_128_agc/';

data_file{1} = [data_path 'tagatune_train.txt'];
data_file{2} = [data_path 'tagatune_valid.txt'];
data_file{3} = [data_path 'tagatune_test.txt'];

tag_file{1} = [data_path 'tagatune_train_tag_binary.txt'];
tag_file{2} = [data_path 'tagatune_valid_tag_binary.txt'];
tag_file{3} = [data_path 'tagatune_test_tag_binary.txt'];

addpath(genpath([pwd filesep 'audio_processing']));
addpath(genpath([pwd filesep 'rbm']));

scratch_folder = './tagatune_scratch';
if ~exist(scratch_folder,'dir')
    mkdir(scratch_folder);
end

% run default options
default_options;

% choose options
options.preproc.patch.size = 8; 
options.fl.sampling.type = 'onset_sync_max';  % 'onset_sync_max', 'random'
options.preproc.trim.on = 0;

options.fl.rbm.hidden_layer = 1024;   
options.fl.rbm.sparsity = 0.02;
options.pooling.size = 43;

sparsity = 0.02; %[0.007 0.01 0.02 0.03];
pooling_size = 43; %[22 43 86 172 344];

%%%%% local feature learning 
fprintf(1,'Local feature learning...\n')
for i=1:length(sparsity)
    options.fl.rbm.sparsity = sparsity(i);
    [pca_params, rbm_params, rbmModel] = local_feature_learning(data_file{1}, scratch_folder, options);
end

%%%%% feature summaization
for ii=1:length(sparsity)    
    options.fl.rbm.sparsity = sparsity(ii);
    for i=1:length(pooling_size)
        options.pooling.size = pooling_size(i);
        [data_path pca_path feature_path pooling_path] = getParamsPath(options);
        if exist([scratch_folder filesep pooling_path filesep sprintf('song_level_features.mat')], 'file')
            load([scratch_folder filesep pooling_path filesep sprintf('song_level_features.mat')], 'train_data');
        else
            fprintf(1,'Pooling_size = %d \n', pooling_size(i));
            save_song_level_features_tagatune(data_file, tag_file, scratch_folder, options);
        end
    end
end


%%%%%% deep learning
fprintf(1,'Deep learning...\n');

options.deep_networks.num_hidden_layers = 3;
options.deep_networks.input_normalization = 0;
options.deep_networks.pre_training = 1;

options.deep_networks.rbm_params{1}.hidden_layer = 512;
options.deep_networks.rbm_params{1}.scale = 1;
options.deep_networks.rbm_params{1}.weight_cost = 0.01;
options.deep_networks.rbm_params{1}.maxEpoch = 200;
options.deep_networks.rbm_params{1}.initMult = 0.01;
options.deep_networks.rbm_params{1}.binaryInput = 1;  % binary input = 1, linaer input = 0;
options.deep_networks.rbm_params{1}.epsilon = 0.03;
options.deep_networks.rbm_params{1}.minepsilon = 0.01;
options.deep_networks.rbm_params{1}.relu = 1;
options.deep_networks.rbm_params{1}.sparsity = 0;

options.deep_networks.rbm_params{2} = options.deep_networks.rbm_params{1};
options.deep_networks.rbm_params{2}.binaryInput = 0;

options.deep_networks.rbm_params{3} = options.deep_networks.rbm_params{1};
options.deep_networks.rbm_params{3}.binaryInput = 0;

l1_weight_cost = 0.001; %[0.001 0.01 0.1];
l2_weight_cost = [0.001 0.01 0.1];
l3_weight_cost = [0.001 0.01 0.1];

for a=1:length(sparsity)
    options.fl.rbm.sparsity = sparsity(a);
    for b=1:length(pooling_size)
        options.pooling.size = pooling_size(b);
        for ii=1:length(l1_weight_cost)
            options.deep_networks.rbm_params{1}.weight_cost = l1_weight_cost(ii);
            for i=1:length(l2_weight_cost)
                options.deep_networks.rbm_params{2}.weight_cost = l2_weight_cost(i);
                for j=1:length(l3_weight_cost)
                    options.deep_networks.rbm_params{3}.weight_cost = l3_weight_cost(j);
                    fprintf(1,'L1_weight_cost = %.4f, L2_weight_cost = %.4f, L3_weight_cost = %.4f\n', l1_weight_cost(ii), l2_weight_cost(i), l3_weight_cost(j));
                    if (l1_weight_cost(ii) <= l2_weight_cost(i)) & (l2_weight_cost(i) <= l3_weight_cost(j))
                        deep_feature_learning(scratch_folder,  options);
                    end
                end
            end
        end
    end
end


