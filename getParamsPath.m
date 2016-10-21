function [data_path pca_path feature_path pooling_path base_path deep_path] = getParamsPath(options)
%
% generate path names to store parameters
%
% Input arguments:
% options:          Matlab structure that specifies the feature learning
%                   algorithm and parameters

% filename
if strcmp(options.preproc.tfr.tf_data,'spectrogram')
    path0 = sprintf('spec');
elseif strcmp(options.preproc.tfr.tf_data,'mel_spectrogram')
    path0 = sprintf('mel_spec_%d', options.preproc.tfr.mel_spec.bands);
elseif strcmp(options.preproc.tfr.tf_data, 'constant_q2')
    path0 = sprintf('constq');
elseif strcmp(options.preproc.tfr.tf_data,'mfcc')
    path0 = sprintf('mfcc');
elseif strcmp(options.preproc.tfr.tf_data,'chroma-FB')
    path0 = sprintf('chroma-FB');
end

if options.preproc.tf_agc.on
    path0 = [path0 '_agc'];
end

if options.preproc.norm.mean_subtraction.on
    path0 = [path0 '_ms'];
end

if options.preproc.comp.amp_compress.log_c.on
    path0 = [path0 sprintf('_log_%d', options.preproc.comp.amp_compress.log_c.gain)];
end

path0 = [path0 sprintf('_sz_%d',options.preproc.patch.size) filesep];
data_path = path0;

path0 = [path0 options.fl.sampling.type sprintf('_seg_%d_', options.fl.sampling.segment_frames)];
path0 = [path0 sprintf('num_%dk', ceil(options.fl.sampling.num_samples/1000)) filesep];

if options.preproc.pca.on
    path0 = [path0 sprintf('pca_%.2f_%.3f', options.preproc.pca.retained, options.preproc.pca.eps) filesep];
    pca_path = path0;
else
    pca_path = path0;
end

feature_path = [path0 sprintf('rbm_dic_%d_%.3f_%.4f_%.1f',options.fl.rbm.hidden_layer, options.fl.rbm.sparsity, options.fl.rbm.weight_cost, options.fl.rbm.scale) filesep];
pooling_path = [feature_path sprintf('pooling_%d', options.pooling.size) filesep];

if options.deep_networks.input_normalization
    base_path = [pooling_path 'norm' filesep];
else
    base_path = pooling_path;
end

if options.deep_networks.pre_training

    if options.preproc.trim.on
        base_path = [base_path 'trim' filesep];
    end

    if options.deep_networks.num_hidden_layers >= 1
        deep_path{1} = [base_path sprintf('L1_%d_hid_%d_wc_%.4f_init_%.4f', ...
            options.deep_networks.rbm_params{1}.binarybinary, ...
            options.deep_networks.rbm_params{1}.hidden_layer, options.deep_networks.rbm_params{1}.weight_cost, ...
            options.deep_networks.rbm_params{1}.initMult)];
    end

    if options.deep_networks.num_hidden_layers >= 2
        deep_path{2} = [deep_path{1} filesep sprintf('L2_hid_%d_wc_%.4f_init_%.4f', ...
            options.deep_networks.rbm_params{2}.hidden_layer, options.deep_networks.rbm_params{2}.weight_cost, ...
            options.deep_networks.rbm_params{2}.initMult)];
    end

    if options.deep_networks.num_hidden_layers >= 3
        deep_path{3} = [deep_path{2} filesep sprintf('L3_hid_%d_wc_%.4f_init_%.4f', ...
            options.deep_networks.rbm_params{3}.hidden_layer, options.deep_networks.rbm_params{3}.weight_cost, ...
            options.deep_networks.rbm_params{3}.initMult)];
    end

else
    if options.deep_networks.num_hidden_layers >= 1
        deep_path{1} = [base_path sprintf('L1_hid_%d', options.deep_networks.rbm_params{1}.hidden_layer)];
    end

    if options.deep_networks.num_hidden_layers >= 2
        deep_path{2} = [deep_path{1} filesep sprintf('L2_hid_%d', options.deep_networks.rbm_params{2}.hidden_layer)];
    end

    if options.deep_networks.num_hidden_layers >= 3
        deep_path{3} = [deep_path{2} filesep sprintf('L3_hid_%d', options.deep_networks.rbm_params{3}.hidden_layer)];
    end
end
    






