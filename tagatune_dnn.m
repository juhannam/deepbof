function tagatune_dnn(scratch_folder, options)
%
% conduct song-level supervised learning
%
% Input arguments:
% scratch_path:     directory were the learned params are to be stored
% options:          Matlab structure that specifies the feature learning
%                   algorithm and parameters

[~, ~, ~, pooling_path, ~, deep_path] = getParamsPath(options);

result_path = [deep_path{options.deep_networks.num_hidden_layers} filesep];

if options.deep_networks.pre_training
    result_file_name = [scratch_folder filesep result_path filesep sprintf('result_new_non_linear_%d_dropout_%d_adadelta_%d.mat',...
        options.deep_networks.non_linear_unit, options.deep_networks.dropout, options.deep_networks.adadelta)];
    
else
    result_file_name = [scratch_folder filesep result_path filesep sprintf('result_non_linear_%d_dropout_%d_adadelta_%d.mat',...
        options.deep_networks.non_linear_unit, options.deep_networks.dropout, options.deep_networks.adadelta)];
end

if options.evaluation.num_tags < 160
    result_file_name = [result_file_name(1:end-4) '_' num2str(options.evaluation.num_tags) '.mat'];
end

if exist(result_file_name, 'file')
    load(result_file_name);

    disp(['test precision mean: ' num2str(test_precision)]);
    disp(['test recall mean: ' num2str(test_recall)]);
    disp(['test f-score mean: ', num2str(test_f_score)]);

    disp(['test avg. precision: ' num2str(test_ap)]);
    disp(['test aroc-tag / aroc-clip: ' num2str(test_aroc) ' / ' num2str(test_aroc2)]);
    disp(['test p3 / p6 / p9 / p12 / p15: ' num2str(test_p3) ' / ' num2str(test_p6) ' / ' num2str(test_p9) ' / ' num2str(test_p12) ' / ' num2str(test_p15)]);
    fprintf(1, '=====================================================\n')

    return;
end



% load song-level features
load([scratch_folder filesep pooling_path filesep sprintf('song_level_features.mat')]);


% tag triming                                                                                                                   
if options.evaluation.num_tags < 174                                                                                               
    [sort_val, sort_index] = sort(sum(train_label,1),'descend');                                                                    
    available_index = sort(sort_index([1:options.evaluation.num_tags]),'ascend');                           
    train_label = train_label(:,available_index);
    valid_label = valid_label(:,available_index);
    test_label = test_label(:, available_index); 
end


% emperical tagging probabilities
emp_prob_label = sum(train_label,1)./(sum(sum(train_label,1))); 

% normalization
if options.deep_networks.input_normalization
    max_value = max(train_data, [], 1);
    train_data = bsxfun(@rdivide, train_data, max_value);
    max_value = max(valid_data, [], 1);
    valid_data = bsxfun(@rdivide, valid_data, max_value);
    max_value = max(test_data, [], 1);
    test_data = bsxfun(@rdivide, test_data, max_value);
end

% setup DNN
layers = [size(train_data,1)];
for i=1:options.deep_networks.num_hidden_layers
    layers = [layers, options.deep_networks.rbm_params{i}.hidden_layer ];
end
layers = [layers, options.evaluation.num_tags];
    
blayers = ones(1,options.deep_networks.num_hidden_layers+1);

M = default_mlp (layers);
M.output.binary = blayers(end);
M.hidden.use_tanh = options.deep_networks.non_linear_unit;

M.valid_min_epochs = 10;
M.dropout.use = options.deep_networks.dropout;

M.hook.per_epoch = {@save_intermediate, {'mlp_tagatune.mat'}};

M.learning.lrate = 1e-3;
M.learning.lrate0 = 5000;
M.learning.minibatch_sz = 128;

M.adadelta.use = options.deep_networks.adadelta;
M.adadelta.epsilon = 1e-8;
M.adadelta.momentum = 0.99;

M.noise.drop = 0;
M.noise.level = 0;

M.iteration.n_epochs = 100;


% load pre-trained network parameters 
if options.deep_networks.pre_training 
    for i=1:options.deep_networks.num_hidden_layers
        if options.deep_networks.non_linear_unit == 0
            load([scratch_folder filesep deep_path{i} filesep 'rbm_params.mat'], 'rbm_params', 'rbmModel');
        elseif options.deep_networks.non_linear_unit == 2
            load([scratch_folder filesep deep_path{i} filesep 'rbm_relu_params.mat'], 'rbm_params', 'rbmModel');
        end
        M.biases{i} = rbmModel.visbiases;
        M.W{i} = rbmModel.vishid';
    end
end
    
% training 
fprintf(1, 'Training MLP\n');
tic;
M = tagatune_mlp (M, train_data', train_label, valid_data', valid_label, 0.1, 0);
fprintf(1, 'Training is done after %f seconds\n', toc);


% test 
test_estimate = tagatune_mlp_classify (M, test_data', [], 1);


% evaluation-annotation
[test_word_precision, test_word_recall] = eval_annotation(test_estimate, test_label, emp_prob_label, options.evaluation.M, options.evaluation.diversity_factor);

tags_index = find(isnan(test_word_precision) == 0);
test_precision = mean(test_word_precision(tags_index));
test_recall = mean(test_word_recall(tags_index));
temp = get_fscore(test_word_precision(tags_index), test_word_recall(tags_index));
test_f_score = sum(temp(~isnan(temp)))/length(temp);

% evaluation-retrieval
[test_aroc test_ap] = eval_retrieval(test_estimate, test_label);
test_aroc2 = eval_retrieval(test_estimate', test_label');

test_p3 = eval_avg_precision_at_K(test_estimate', test_label', 3);
test_p6 = eval_avg_precision_at_K(test_estimate', test_label', 6);
test_p9 = eval_avg_precision_at_K(test_estimate', test_label', 9);
test_p12 = eval_avg_precision_at_K(test_estimate', test_label', 12);
test_p15 = eval_avg_precision_at_K(test_estimate', test_label', 15);


fprintf(1, '=====================================================\n');
fprintf(1, 'Test Results\n');
fprintf(1, '=====================================================\n');
disp(['test precision mean: ' num2str(test_precision)]);
disp(['test recall mean: ' num2str(test_recall)]);
disp(['test f-score mean: ', num2str(test_f_score)]);

disp(['test avg. precision: ' num2str(test_ap)]);
disp(['test aroc-tag / aroc-clip: ' num2str(test_aroc) ' / ' num2str(test_aroc2)]);
disp(['test p3 / p6 / p9 / p12 / p15: ' num2str(test_p3) ' / ' num2str(test_p6) ' / ' num2str(test_p9) ' / ' num2str(test_p12) ' / ' num2str(test_p15)]);

fprintf(1, '=====================================================\n')
fprintf(1, '=====================================================\n')


mkdir([scratch_folder filesep result_path]);
save(result_file_name, 'test_precision', 'test_recall', 'test_f_score', 'test_ap', 'test_aroc', 'test_aroc2', 'test_p3', 'test_p6', 'test_p9', 'test_p12', 'test_p15');  

