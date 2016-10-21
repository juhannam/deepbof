% 
% the main script that conducts supervised learning for auto-tagging 
%

% add dependencies to matlab's path
addpath(genpath([pwd filesep 'audio_processing']));
addpath(genpath([pwd filesep 'rbm']));
addpath('./deepmat');

data_path = '/media/data/shared/datasets/Magnatagatune/mel_spec_128_agc/';

scratch_folder = './tagatune_scratch';
if ~exist(scratch_folder,'dir')
    mkdir(scratch_folder);
end

% run default options
default_options;
rand('seed',1); randn('seed',1);

% choose options
options.preproc.patch.size = 8;
options.fl.sampling.type = 'onset_sync_max'; %'onset_sync_max' or 'random'
options.preproc.trim.on = 0;

options.fl.rbm.hidden_layer = 1024;
options.fl.rbm.sparsity = 0.02;  %[0.007 0.01 0.02;]
options.pooling.size = 43;%[22 43 86 172 344];

%sparsity = [0.005 0.007 0.01 0.02 0.03 0.05];
%pooling_size = [22 43 86 172 344 689 1378];%[22 43 86 172 344 689 1378];

sparsity = 0.02;%[0.01 0.02];%[0.007 0.01 0.02 0.03];%0.01;
pooling_size = 86;%[22 43 86];%[22 43 86 172 344];% 689 1378];

%%%%%% deep learning

options.deep_networks.num_hidden_layers = 3;
options.deep_networks.input_normalization = 0;
options.deep_networks.pre_training = 1;
options.deep_networks.fine_tuning = 1;

options.deep_networks.rbm_params{1}.hidden_layer = 512;
options.deep_networks.rbm_params{1}.scale = 1;
options.deep_networks.rbm_params{1}.weight_cost = 0.001;
options.deep_networks.rbm_params{1}.maxEpoch = 200;
options.deep_networks.rbm_params{1}.initMult = 0.01;
options.deep_networks.rbm_params{1}.binaryInput = 1;  % binary input = 1, linaer input = 0;
options.deep_networks.rbm_params{1}.epsilon = 0.03;
options.deep_networks.rbm_params{1}.minepsilon = 0.01;

options.deep_networks.rbm_params{2} = options.deep_networks.rbm_params{1};
options.deep_networks.rbm_params{3} = options.deep_networks.rbm_params{1};
options.deep_networks.rbm_params{2}.binaryInput = 0;
options.deep_networks.rbm_params{3}.binaryInput = 0;
 
options.deep_networks.non_linear_unit = 2;  % 0 = sigmoid, 1= tanh, 2 = rectlinear
options.deep_networks.dropout = 1;
options.deep_networks.adadelta = 1;


if ~options.deep_networks.pre_training
    for i=1:length(sparsity)
        options.fl.rbm.sparsity = sparsity(i);
        for j=1:length(pooling_size)
            options.pooling.size = pooling_size(j);
            tagatune_dnn(scratch_folder, options);
        end
    end
else
    l1_weight_cost = [0.001 0.01 0.1];
    l2_weight_cost = [0.001 0.01 0.1];
    l3_weight_cost = [0.001 0.01 0.1];
    for a=1:length(sparsity)
        options.fl.rbm.sparsity = sparsity(a);
        for b=1:length(pooling_size)
            options.pooling.size = pooling_size(b);
            if options.deep_networks.num_hidden_layers == 1
                for ii=1:length(l1_weight_cost)
                    options.deep_networks.rbm_params{1}.weight_cost = l1_weight_cost(ii);
                    fprintf(1, 'L1_weight_cost = %.4f\n', l1_weight_cost(ii));
                    tagatune_dnn(scratch_folder, options);
                end
            elseif options.deep_networks.num_hidden_layers == 2
%                l1_weight_cost = 0.001;%[0.01 0.001];
                for ii=1:length(l1_weight_cost)
                    options.deep_networks.rbm_params{1}.weight_cost = l1_weight_cost(ii);
                    for i=1:length(l2_weight_cost)
                        options.deep_networks.rbm_params{2}.weight_cost = l2_weight_cost(i);
                        fprintf(1,'L1_weight_cost = %.4f, L2_weight_cost = %.4f\n', l1_weight_cost(ii), l2_weight_cost(i));
%                        if (l1_weight_cost(ii) <= l2_weight_cost(i) )
                            tagatune_dnn(scratch_folder, options);
%                        end
                    end
                end
            elseif options.deep_networks.num_hidden_layers == 3
                l1_weight_cost = 0.001;%[0.01 0.001];
                for ii=1:length(l1_weight_cost)
                    options.deep_networks.rbm_params{1}.weight_cost = l1_weight_cost(ii);
                    for i=1:length(l2_weight_cost)
                        options.deep_networks.rbm_params{2}.weight_cost = l2_weight_cost(i);
                        for j=1:length(l3_weight_cost)
                            options.deep_networks.rbm_params{3}.weight_cost = l3_weight_cost(j);
                            fprintf(1,'L1_weight_cost = %.4f, L2_weight_cost = %.4f, L3_weight_cost = %.4f\n', l1_weight_cost(ii), l2_weight_cost(i), l3_weight_cost(j));
                            if (l1_weight_cost(ii) <= l2_weight_cost(i)  ) & (l2_weight_cost(i) <= l3_weight_cost(j))
                                tagatune_dnn(scratch_folder, options);
                            end
                        end
                    end
                end
            end
        end
    end
end
