function [GFLC,Time] = MyCumSum(GFLC,Time)

aux=table(GFLC,Time);
aux=sortrows(aux,'Time');

GFLC=cumsum(aux.GFLC);

end

