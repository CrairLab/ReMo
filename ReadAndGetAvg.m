function [avg_wf, motion_detected, downA] = ReadAndGetAvg(downFactor, loadmovie)
% Read movies and generate averaged fluorescent traces

    if nargin < 1
        downFactor = 2;
        loadmovie = 0;
    elseif nargin < 2
        loadmovie = 0;
    end
    
    % Search tif files
    movieList = dir('*.tif');
    motion_detected = [];
    downA = [];
    avg_wf = [];
    roi = ROI;
    nmovies = length(movieList);
    savefn = [movieList(1).name(1:end-4) '_' num2str(nmovies) 'combined_' ...
    num2str(downFactor) '_avgtrace.mat'];
    savefn2 = [movieList(1).name(1:end-4) '_' num2str(nmovies) 'combined_' ...
    num2str(downFactor) '_downsampled.mat'];

    if exist(savefn, 'file')
        load(savefn);
        disp('Loading the existing averaged trace');
        if loadmovie
            load(savefn2);
            disp('Loading the existing downsampled movie')
        end            
    else

        for i = 1:nmovies
            tic;
            disp(['Reading movie #' num2str(i)]);
            
            % Read movies, rigid-registration, and apply rois
            [A3, output_all] = ReadRegisterRoi(movieList(i).name, roi, downFactor);
            motion_detected = [motion_detected; output_all];
            
            % Concatenate downsampled movies
            downA = cat(3, downA, A3);

            clear A3;
            clearAllMemoizedCaches;
            toc;
        end

        downA = single(downA);
        % Get averaged traces
        avg_wf = nanmean(nanmean(downA,1),2);
        avg_wf = avg_wf(:);

        save(savefn, 'avg_wf', 'motion_detected');
        save(savefn2, 'downA', '-v7.3');
    end

end
