function [A3, output_all] = ReadRegisterRoi(filename, roi, downFactor, param)
% Read, register, apply roi, and downsample a movie

    if nargin < 2
        roi.ROIData = [];
        downFactor = 2;
        param.blueInitial = 2;
    elseif nargin < 3
        downFactor = 2;
        param.blueInitial = 2;
    end


    % Read raw data
    A0 = movieData.inputMovie(filename);

    % Downsampling
    A1 = movieData.downSampleMovie(A0,downFactor,1);

    clear A0

    % Rigid registration
    if param.blueInitial
        
        % Register each channel seperately
        [A1B, A1U] = separateBlueUV(A1, param.blueInitial);
        [A2B, output_all_B] = movieData.dftReg(A1B);
        [A2U, output_all_U] = movieData.dftReg(A1U);
        load('Blue_UV_indices.mat')
        
        % Reconstruct registered matrix in order 
        A2 = A1;
        A2(: ,:, blueFrames) = A2B;
        A2(:, :, uvFrames) = A2U;
        
        % Reconstruct motion output_all
        output_all = zeros(size(A2, 3), 4);
        output_all(blueFrames, :) = output_all_B;
        output_all(uvFrames, :) = output_all_U;
    else
        [A2, output_all] = movieData.dftReg(A1);
    end

    % Get indices or moving frames
    output_all = output_all(:,3) + output_all(:,4);
    output_all = output_all > 0;

    clear A1;

    % Apply rois
    if ~isempty(roi.ROIData)
        A3 = ROI.ApplyMask(A2, roi.ROIData, downFactor);
        A3 = movieData.focusOnroi(A3);
    else
        A3 = A2;
    end

    clear A2
            
end