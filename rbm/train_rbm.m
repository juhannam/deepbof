function rbm = train_rbm(data, params, logfile)
%
% RBM training code that supports binary-binary, Gaussian-binary, ReLU-ReLU and binary-ReLU units
%
% Origial code was written by Jiquan Ngiam and later heavily modified by Juhan Nam

applog(logfile, ':: Running RBM Training');
applog(logfile, ['-- Max Epoch ' num2str(params.maxEpoch)]);
applog(logfile, ['-- Target Activation ' num2str(params.binaryTargetAct)]);
applog(logfile, ['-- Weight Cost ' num2str(params.weightcost)]);
applog(logfile, ['-- Input Layer Size ' num2str(params.inputSize)]);
applog(logfile, ['-- Hidden Layer Size ' num2str(params.hiddenLayerSize)]);

tic;

% Minibatch
D = size(data, 1);
numBatch = floor(size(data, 2)/params.batchSize);
data = data(:, 1:(numBatch*params.batchSize));
data = reshape(data, D, params.batchSize, numBatch);

% initialize model parameters
randn('seed',1);
rbm.weight = params.initMult*randn(params.hiddenLayerSize, params.inputSize);
rbm.hbias = params.inithidbiases*ones(params.hiddenLayerSize, 1);
rbm.vbias = zeros(params.inputSize, 1);

% runtime parameters
averageActivations = zeros(params.hiddenLayerSize, 1);
momentum = params.initialmomentum;
epsilon = params.epsilon;

weight_inc  = zeros(params.hiddenLayerSize, params.inputSize);
hbias_inc = zeros(params.hiddenLayerSize,1);
vbias_inc = zeros(params.inputSize,1);

for epoch = 1:params.maxEpoch

    if epoch > params.epochfinalmomentum,
        momentum = params.finalmomentum;
    end

    errsum = 0;
    reconerr = 0;

    sparsityinc = 0;
    start = toc;

    for batch = 1:size(data,3)

        x = data(:, :, batch);
        N = size(data, 2);

        % positive phase
        pos_input = params.scl * bsxfun(@plus, rbm.weight*x,rbm.hbias);
        pos_sigmoid = sigmoid(pos_input);
        
        if params.relu
            pos_hidstates = max(pos_input + sqrt(pos_sigmoid) .* randn(size(pos_sigmoid)), 0);
            pos_input_re = max(pos_input,0); 
        else
            pos_hidstates = pos_sigmoid > rand(size(pos_sigmoid));
            pos_input_re = pos_sigmoid;
        end

        pos_prods = pos_input_re * x';
        pos_hidact = sum(pos_input_re, 2);
        pos_visact = sum(x, 2);
        
        
        % negative phase
        neg_data  = bsxfun(@plus, rbm.weight'*pos_hidstates, rbm.vbias);

        if params.binaryInput
            neg_data = sigmoid(neg_data);
        else
            if params.relu
                neg_data = max(neg_data,0);
            end
        end

        if params.relu
            neg_input_re= max(params.scl * bsxfun(@plus,rbm.weight*neg_data, rbm.hbias),0);
        else
            neg_input_re= sigmoid(params.scl * bsxfun(@plus,rbm.weight*neg_data, rbm.hbias));
        end

        neg_prods = neg_input_re * neg_data';
        neg_hidact = sum(neg_input_re, 2);
        neg_visact = sum(neg_data, 2);

        
        % eval reconstruction
        err = mean(sum( (x-neg_data).^2 ));
        recon = bsxfun(@plus, rbm.weight'*pos_input_re, rbm.vbias);
        rerr = mean(sum( (x-recon).^2 ));

        errsum = err + errsum;
        reconerr = rerr + reconerr;

        % update parameter
        averageActivations = (1 - params.activationAveragingConstant) * averageActivations + ...
                params.activationAveragingConstant * mean(pos_sigmoid, 2);
        sparsityinc = - (averageActivations - params.binaryTargetAct) * params.binaryLearningRateSparsity * epsilon;

        weight_inc = momentum*weight_inc + epsilon*((pos_prods-neg_prods)/N - params.weightcost*rbm.weight);
        vbias_inc = momentum*vbias_inc + (epsilon/N)*(pos_visact-neg_visact);
        hbias_inc = momentum*hbias_inc + sparsityinc + (epsilon/N)*(pos_hidact-neg_hidact);

        rbm.weight = rbm.weight + weight_inc;
        rbm.vbias = rbm.vbias + vbias_inc;
        rbm.hbias = rbm.hbias + hbias_inc;
    end

    timeTaken = toc - start;

    epsilon = max(params.minepsilon, epsilon * params.annealepsilon);

    % Log String
    logString = sprintf('-- Epoch %4i serror %f rerror %f meanact %f wnorm %f timeElapsed %f', epoch, errsum / size(data,3), ...
        reconerr / size(data,3), mean(averageActivations),...
        sum(sqrt(sum(rbm.weight.^2,2))), ...
        timeTaken);

    applog(logfile, logString);
end


function y = sigmoid(x)

y = 1./(1+exp(-x));
