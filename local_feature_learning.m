function [pca_params, rbm_params, rbmModel] = local_feature_learning(file_list, scratch_path, options)
%
% conduct local audio feauture leanring in an unsupervided manner, using 
% PCA whitening and sparse RBM
%
% Input arguments:
% file_list:        cell that includes the list of filenames
% scratch_path:     directory were the learned params are to be stored
% options:          Matlab structure that specifies the feature learning
%                   algorithm and parameters

[data_path pca_path feature_path pooling_path] = getParamsPath(options);

% PCA whitening
pca_file = [scratch_path filesep pca_path filesep 'pca_params.mat'];
if exist(pca_file, 'file')
    load(pca_file)
else
    % get samples
    fprintf(1,'calculating PCA...');
    pca_time = tic;

    rand('seed',1); 
    sampled_data = get_samples(file_list, options);
   
    % PCA whitening
    pca_params.M = mean(sampled_data,2);
    sampled_data2 = bsxfun(@minus, sampled_data, pca_params.M);
    pca_params.retained = options.preproc.pca.retained;
    pca_params.eps = options.preproc.pca.eps;
    
    [pca_params.V, pca_params.Vi, pca_params.E, pca_params.D] = pca_whiten( ...
        sampled_data2(:, randperm(size(sampled_data2, 2))), ...
        size(sampled_data2, 1),  ...
        pca_params.retained,  ...
        pca_params.eps);
    pca_params.dim = size(pca_params.D,1);
    
    sampled_data2 = bsxfun(@minus, sampled_data, pca_params.M);
    sampled_data_norm = pca_params.V*sampled_data2;
    time_elapsed = toc(pca_time);
    fprintf(1,'done\n');
    fprintf(1, 'PCA took %.1f seconds\n', time_elapsed);
    
    mkdir([scratch_path filesep pca_path]);
    save(pca_file, 'pca_params');
end

fl_file = [scratch_path filesep feature_path 'rbm_params.mat'];

if exist(fl_file, 'file')
    load(fl_file)
else
    mkdir([scratch_path filesep feature_path]); 

    randn('seed',1); rand('seed',1);

    % PCA whitening
    if ~exist('sampled_data_norm', 'var')     
        sampled_data = get_samples(file_list, options);
        sampled_data2 = bsxfun(@minus, sampled_data, pca_params.M);
        sampled_data_norm = pca_params.V*sampled_data2;
    end

    % run sparse RBM
    fprintf(1,'training RBM...');
    rbm_time = tic;
    log_file = [scratch_path filesep feature_path 'log.txt'];

    rbm_params = init_rbm(size(pca_params.V,1), options.fl.rbm);
    warning off;
    randn('seed',1); rand('seed',1);
    rbm = train_rbm(sampled_data_norm, rbm_params, log_file);      
    warning on;

    time_elapsed = toc(rbm_time);
    fprintf(1,'done\n');
    fprintf(1, 'RBM training took %.1f seconds\n', time_elapsed);

    rbmModel.vishid = rbm.weight;
    rbmModel.hidbiases = rbm.hbias;
    rbmModel.visbiases = rbm.vbias;
    save(fl_file, 'rbm_params','rbmModel');
end
