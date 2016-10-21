function params = init_rbm(input_size, rbm)

% RBM parameters
params.hiddenLayerSize = rbm.hidden_layer;
params.inputSize = input_size;
params.binaryTargetAct = rbm.sparsity;
params.scl = rbm.scale;
params.weightcost = rbm.weight_cost;

if isfield(rbm, 'initMult')
    params.initMult = rbm.initMult;
else
    params.initMult = 0.01;
end

params.annealepsilon =  0.99;

if isfield(rbm, 'epsilon')
   params.epsilon = rbm.epsilon;
else
   params.epsilon = 0.007;
end

if isfield(rbm, 'minepsilon')
   params.minepsilon = rbm.minepsilon;
else
   params.minepsilon = 0.003;
end

if isfield(rbm, 'relu')
    params.relu  = rbm.relu;
else
    params.relu  = 0;    
end

if isfield(rbm, 'binaryInput')
    params.binaryInput  = rbm.binaryInput;
else
    params.binaryInput  = 0;    
end

params.maxEpoch  = rbm.maxEpoch;
params.epochfinalmomentum = params.maxEpoch/5;
params.activationAveragingConstant = 0.01;
params.batchSize = 100;
params.usemex = 0;
params.saveepoch = 1000;
params.binaryLearningRateSparsity = 3; 
params.inithidbiases = 0;
params.initialmomentum = 0.5;
params.finalmomentum = 0.9;
params.binaryMode = true;

if rbm.sparsity == 0
    params.binaryLearningRateSparsity = 0;
end

% ReLU RBM
if (params.relu == 1) & (params.binaryInput == 0)
    params.epsilon = 0.003;
    params.minepsilon = 0.001;
end


