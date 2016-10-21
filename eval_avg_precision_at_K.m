function [prec, maxprec] = eval_avg_precision_at_K(test_estimate, test_truth, K)
%
% compute AROC and Mean Average-precision
%
% Input arguments:
%   test_estimate:   (NxM) matrix (N = number of songs and M = number of
%                    tags) where test_estimate(i,j) is the probability of
%                    song i being labeled with tag j
%   test_truth:      (NxM) binary matrix (N = number of songs and M = 
%                    number of tags) where test_truth(i,j) == 1 if song i
%                    in the ground truth data was labeled with tag j and 0
%                    if not
%   K:               the number of songs to retriev

prec = 0;
maxprec = 0;

W = size(test_truth,2);

for w = 1:W
    [temp ranking] = sort(-test_estimate(:, w));
    prec = prec + sum(test_truth(ranking(1:K), w))/K;
    maxprec = maxprec + min(K, sum(test_truth(:, w)))/K;
end

prec = prec / W;
maxprec = maxprec / W;