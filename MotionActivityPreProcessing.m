function MotionActivityPreProcessing(cur_folder, downFactor)
%Do preprocessing on movies in current folder by combining them first and
%do other preprocessing steps

    if nargin < 2
        downFactor = 2;
    end

    cd(cur_folder);
    disp(['Working on ' cur_folder]);
    
    [~, ~, A4] = ReadAndGetAvg(downFactor, 1);
    
    % Photobleaching correction
    
    A5 = movieData.bleachCorrection(A4);
    
    clear A4

    % Gaussian smoothing
    A6 = movieData.GauSmoo(A5, 1); % Sigma = 1
    
    clear A5
    
    % dFoF
    A_dFoF = movieData.grossDFoverF(A6, 1, 10);
    
    clear A6
    
    savefn = ['Combined_downsampled_' num2str(downFactor) '_filtered'];
    
    save([savefn '.mat'], 'A_dFoF', '-v7.3');
    
    clearAllMemoizedCaches;
    
end