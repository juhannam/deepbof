function [precision, recall] = eval_annotation(test_estimate, test_truth, emp_prob_label, num_top_tags, diverse_factor)
%
% compute precision, recall and f-score
%
% Input arguments:
%   test_estimate:   (NxM) matrix (N = number of songs and M = number of
%                    tags) where test_estimate(i,j) is the probability of
%                    song i being labeled with tag j
%   test_truth:      (NxM) binary matrix (N = number of songs and M = 
%                    number of tags) where test_truth(i,j) == 1 if song i
%                    in the ground truth data was labeled with tag j and 0
%                    if not
%   emp_prob_label:  empirical probability of a label
%   num_top_tags:    number of tags that will be annotated
%   diverse_factor:  factor to compensate the "skewness problem" (see the CBA
%                    paper)


estimate = bsxfun(@minus, test_estimate, mean(test_estimate,1)*diverse_factor);

decision = zeros(size(estimate));
for j = 1:size(test_estimate,1)
    [temp ranking] = sort(estimate(j, :),'descend');
    decision(j,ranking(1:num_top_tags)) = 1;
end

correct_decision = decision.*test_truth;

% precision
annotated_tag_index = find((sum(decision,1)>0) & (sum(test_truth,1)>0));
non_annotated_tag_index = find((sum(decision,1)==0) & (sum(test_truth,1)>0));
word_precison = zeros(1,size(test_truth,2));
word_precison(non_annotated_tag_index) = emp_prob_label(non_annotated_tag_index);
word_precison(annotated_tag_index) = sum(correct_decision(:,annotated_tag_index),1)./sum(decision(:,annotated_tag_index),1);

unavailable_index = find((sum(test_truth,1)==0));
precision = word_precison;
precision(unavailable_index) = NaN;

% recall
recall = sum(correct_decision,1)./sum(test_truth,1);
recall(unavailable_index) = NaN;



