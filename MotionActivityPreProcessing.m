function A_dFoF = MotionActivityPreProcessing(cur_folder, downFactor, param)
%Do preprocessing on movies in current folder by combining them first and
%do other preprocessing steps

    if nargin < 2
        downFactor = 2;
        param.blueInitial = 0;
        param.efr = 10;
    end

    cd(cur_folder);
    disp(['Working on ' cur_folder]);
    
    savefn = ['Combined_downsampled_' num2str(downFactor) '_' ...
        num2str(param.blueInitial) '_filtered.mat'];
    
    if ~exist(savefn, 'file')
        if param.blueInitial
            % Blue and UV 
            disp('Blue and UV dual wavelengths...')
            [A_dFoF, hat] = doubleWavelengthsPipe(downFactor, param);
        else
            % Only Blue
            disp('Blue chanel only..')
            [A_dFoF, hat] = singleWavelengthPipe(downFactor);
        end
        % Save A_dFoF
        save(savefn, 'A_dFoF', '-v7.3');
    else
        load(savefn)
        disp('Loading existing A_dFoF (filtered matrix)...')
    end
    save('parameters.mat', 'param')
    clearAllMemoizedCaches;
    
end


function [A_dFoF, hat] = singleWavelengthPipe(downFactor)

        [~, ~, A4] = ReadAndGetAvg(downFactor, 1);

        % Photobleaching correction
        A5 = movieData.bleachCorrection(A4);
        hat = 3000;
        %A5 = movieData.TopHatFiltering(A4, hat); 
        
        clear A4

        % Gaussian smoothing
        %A6 = movieData.GauSmoo(A5, 1); % Sigma = 1
        A6 = A5;

        clear A5

        % dFoF
        A_dFoF = movieData.grossDFoverF(A6, 1, 50);
        A_dFoF = single(A_dFoF);

        clear A6

end



function [A_dFoF, hat] = doubleWavelengthsPipe(downFactor, param)
% Part of the code adopted from https://codeocean.com/capsule/8947953/tree/v1
% Barson et al. Be aware of the assumption here: uv frames were triggered
% by presceding blue frames

        [~, ~, A4] = ReadAndGetAvg(downFactor, 1, param);
          
        [A4B, A4U] = separateBlueUV(A4, param.blueInitial, 1);
        sz = size(A4B);
        clear A4

        % Photobleaching correction
        A5B = movieData.bleachCorrection(A4B);
        scale_factor = param.fr/20; hat = 6000 * scale_factor;
        %A5B = movieData.TopHatFiltering(A4B, hat);
        A5U = movieData.bleachCorrection(A4U);
        %A5U = movieData.TopHatFiltering(A4U, hat);

        clear A4B A4U
        
        % Gaussian smoothing
        %A6B = movieData.GauSmoo(A5B, 1); % Sigma = 1
        %A6U = movieData.GauSmoo(A5U, 1);
        A6B = A5B; A6U = A5U;

        clear A5B A5U
        
        % Get the A_dFoF for just the blue channel
        A_dFoF = single(movieData.grossDFoverF(A6B, 1, 50));
        save('Blue_dFF_only.mat', 'A_dFoF', '-v7.3'); clear A_dFoF
        
        % Regressing out UV signals
        A6B_ = reshape(A6B, [sz(1)*sz(2), sz(3)]);
        A6U_ = reshape(A6U, [sz(1)*sz(2), sz(3)]);
        median_Bluebase = nanmedian(A6B_, 2);
        clear A6B A6U
        
        % Get regression coefficients
        mask_id = find(~isnan(median_Bluebase));
        
        g_pixel = zeros(length(mask_id), 1);
        for i = 1:length(mask_id)
            g_pixel(i) = regress(A6B_(mask_id(i), :)', A6U_(mask_id(i), :)');
        end
        
        A7 = A6B_;
        A7(mask_id, :) = A6B_(mask_id, :) - repmat(g_pixel, 1, sz(3)).*A6U_(mask_id, :);
        clear A6B_ A6U_

        % dFoF
        A_dFoF = A7./repmat(median_Bluebase, 1, sz(3));
        A_dFoF = single(A_dFoF);

        clear A7
        
        A_dFoF = reshape(A_dFoF, sz);
end