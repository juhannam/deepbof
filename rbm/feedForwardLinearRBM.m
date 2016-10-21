function hidden = feedForwardLinearRBM (data, params, rbmModel)
  
hidden = params.scl * (bsxfun(@plus, rbmModel.vishid*data, rbmModel.hidbiases));
hidden = 1 ./ (1 + exp(-hidden));


