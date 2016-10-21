function [mean_aroc, mean_ap, aroc, ap] = eval_retrieval(test_estimate, test_truth)
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


available_index = find((sum(test_truth,1)>0));

aroc = zeros(size(test_estimate,2),1);
ap = zeros(size(test_estimate,2),1);

for j = available_index  % each word
    [temp ranking] = sort(test_estimate(:, j),'descend');
    
    recall = zeros(size(test_estimate,1),1);
    precision = zeros(size(test_estimate,1),1);
    false_positive_rate = zeros(size(test_estimate,1),1);

    for k=1:size(test_estimate,1)
        TP = sum(test_truth(ranking(1:k), j));
        recall(k) = TP/sum(test_truth(:,j));
        precision(k) = TP/k;
        false_positive_rate(k) = (k-TP)/(size(test_estimate,1)-sum(test_truth(:,j)));
    end
    
    % find levels where retrieved one is correctly identied 
    corr_index = find(diff([0; recall]) > 0);

    ap(j) = mean(precision(corr_index));
       
    % compute area under ROC
    for i=1:size(test_estimate,1)-1
        width = false_positive_rate(i+1)-false_positive_rate(i);
        aroc(j) = aroc(j) + width*(recall(i+1)+recall(i))/2;
    end
end

aroc = aroc(available_index);
ap = ap(available_index);

mean_aroc = mean(aroc);
mean_ap = mean(ap);
