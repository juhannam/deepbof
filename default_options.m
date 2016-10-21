
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRE_PROCESSING OPTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

options.dataset.name = 'tagatune';

options.preproc.tfr.tf_data = 'mel_spectrogram'; %'mel_spectrogram'; %'spectrogram'; %'standard_features';
options.preproc.tfr.window_size = 1024;
options.preproc.tfr.hop = 512;
options.preproc.tfr.fs = 22050;
options.preproc.tfr.window_type = 'hann';
options.preproc.tfr.file_format = 'mp3';

% pre-processing / automatic gain control (agc)
options.preproc.tf_agc.on = 1;
options.preproc.tf_agc.t_scale = 0.5;
options.preproc.tf_agc.f_scale = 2;
options.preproc.tf_agc.eps = 0.01;
options.preproc.tf_agc.env_type = 2; % 1 = 'symmetric', 2 = 'att_dec',

% pre-processing / time-frequency representation (tfr), only for MEL spectrogram
options.preproc.tfr.mel_spec.bands = 128;

% pre-processing / novelty function
options.preproc.novelty.tf_data = 'mel_spectrogram';
options.preproc.novelty.bands = 40;
options.preproc.novelty.log_c = 100;


% pre-processing / normalization
options.preproc.norm.mean_subtraction.on = 0;
options.preproc.norm.standardization.on = 0;
options.preproc.norm.norm_eps = 0.01;

options.preproc.comp.amp_compress.log_c.on = 1;
options.preproc.comp.amp_compress.log_c.gain = 10;

options.preproc.patch.size = 6;
options.preproc.patch.stride = 1;

options.preproc.pca.on = 1;
options.preproc.pca.dim = 64;
options.preproc.pca.eps = 0.01;
options.preproc.pca.retained = 0.9;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOCAL SPARSE FEATURE LEARNING OPTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% feature learning / algoritm selection
% CHOOSE ONLY ONE IF THESE:
options.fl.rbm.on = 1;

% feature learning / RBM
options.fl.rbm.init_params = 0;
options.fl.rbm.sparsity = 0.01;
options.fl.rbm.weight_cost = 0.001;
options.fl.rbm.scale = 1;
options.fl.rbm.hidden_layer = 1024;
options.fl.rbm.maxEpoch = 300;
options.fl.rbm.binarybinary = 0;

% sampling options
options.fl.sampling.type = 'onset_sync_max';  % 'random', 'onset_sync_max'
options.fl.sampling.segment_frames = 43; % about 1 sec
options.fl.sampling.num_samples = 200000;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FEATURE POOLING OPTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% pooling options
options.pooling.size = 43; %[22, 43, 86, 172 344];   % 5(115ms), 11(250ms), 22(500ms), 43(1s), 86(2s), 172(4s)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Deep Networks OPTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

options.deep_networks.num_hidden_layers = 3;
options.deep_networks.input_normalization = 1;
options.deep_networks.pre_training = 1;
options.deep_networks.fine_tuning = 1;

options.deep_networks.rbm_params{1}.hidden_layer = 512;
options.deep_networks.rbm_params{1}.scale = 1;
options.deep_networks.rbm_params{1}.weight_cost = 0.01;
options.deep_networks.rbm_params{1}.sparsity = 0;
options.deep_networks.rbm_params{1}.maxEpoch = 200;
options.deep_networks.rbm_params{1}.initMult = 0.01;
options.deep_networks.rbm_params{1}.binarybinary = 1; % binary input = 1, linaer input = 0;
options.deep_networks.rbm_params{1}.epsilon = 0.03;
options.deep_networks.rbm_params{1}.minepsilon = 0.01;

options.deep_networks.rbm_params{2} = options.deep_networks.rbm_params{1};
options.deep_networks.rbm_params{3} = options.deep_networks.rbm_params{1};


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% evaluation OPTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

options.evaluation.num_tags = 160 ;%78; % 174 %97
options.evaluation.num_cv_folds = 1;
options.evaluation.M = 10;
options.evaluation.diversity_factor = 1.25;

