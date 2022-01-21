function MotionActivityPreProcessing(cur_folder, downFactor)
%Do preprocessing on movies in current folder by combining them first and
%do other preprocessing steps

    if nargin < 2
        downFactor = 2;
    end

    cd(cur_folder);
    disp(['Working on ' cur_folder]);

    savefn = ['Combined_downsampled_' num2str(downFactor) '_filtered.mat'];
    
    if ~exist(savefn, 'file')
    
        [~, ~, A4] = ReadAndGetAvg(downFactor, 1);

        % Photobleaching correction

        A5 = movieData.bleachCorrection(A4);

        clear A4

        % Gaussian smoothing
        A6 = movieData.GauSmoo(A5, 1); % Sigma = 1

        clear A5

        % dFoF
        A_dFoF = movieData.grossDFoverF(A6, 1, 10);
        A_dFoF = single(A_dFoF);

        clear A6

        save(savefn, 'A_dFoF', '-v7.3');
    else
        load(savefn)
        disp('Loading existing A_dFoF (filtered matrix)...')
    end
    
    disp('Doing seed-based correlation analysis...')
    movieData.SeedBasedCorr_GPU(A_dFoF, downFactor, 1000);
    
    clearAllMemoizedCaches;
    
end