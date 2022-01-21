function [A3, output_all] = ReadRegisterRoi(filename, roi)

if nargain < 2
    roi.ROIData = [];
end

 % Read raw data
    A0 = movieData.inputMovie(filename);

    % Downsampling
    A1 = movieData.downSampleMovie(A0,downFactor,1);

    clear A0

    % Rigid registration
    [A2, output_all] = movieData.dftReg(A1);

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

    clear A2 output_all
            
end