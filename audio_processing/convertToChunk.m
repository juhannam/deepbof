function y = convertToChunk(x, chunkSize, chunkHop)

% take multiple frames and vectorize it 

chunkNum = floor((size(x,2)-chunkSize)/chunkHop);

y = zeros(chunkSize*size(x,1), chunkNum);

for i=1:chunkNum
    temp = x(:, [1+(i-1)*chunkHop:chunkSize+(i-1)*chunkHop]);
    y(:,i) = temp(:); 
end