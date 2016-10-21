function y = get_fscore(precision, recall)

% f-score
y = 2*(precision.*recall)./(precision+recall);

