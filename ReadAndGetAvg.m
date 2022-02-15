function [avg_wf, motion_detected, downA] = ReadAndGetAvg(downFactor, loadmovie, param)
% Read movies and generate averaged fluorescent traces

    if nargin < 2
        loadmovie = 0;
        param.blueInitial = 0;
    elseif nargin < 3
        param.blueInitial = 0;
    end
    
    % Search tif files
    movieList = dir('*.tif');
    motion_detected = [];
    downA = [];
    avg_wf = [];
    avg_wf_B = []; %Blue
    avg_wf_U = []; %UV
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
            
            if i == 16
                warning('Stop Reading More Movies to Avoid Out-of-memory Errors')
                break;
            end
            
            % Read movies, rigid-registration, and apply rois
            [A3, output_all] = ReadRegisterRoi(movieList(i).name, roi, downFactor, param);
            motion_detected = [motion_detected; output_all];
                       
            % Concatenate downsampled movies
            downA = cat(3, downA, A3);
                        
            clear A3;
            clearAllMemoizedCaches;
            toc;
        end

        downA = single(downA);
        downA(downA == 0) = nan;
        % Get averaged traces
        
        if param.blueInitial
            [downA_B, downA_U] = separateBlueUV(downA, param.blueInitial, 1);
            % Mean blue trace
            avg_wf_B = nanmean(nanmean(downA_B,1),2);
            avg_wf_B = avg_wf_B(:);
            % Mean uv trace
            avg_wf_U = nanmean(nanmean(downA_U,1),2);
            avg_wf_U = avg_wf_U(:);
            
            % match number of frames in two channels
            if size(avg_wf_B, 1) >= size(avg_wf_U, 1)
                avg_wf_B = avg_wf_B(1:size(avg_wf_U, 1));
            else
                avg_wf_U = avg_wf_U(1:size(avg_wf_B, 1));
            end
            
            avg_wf = [avg_wf_B avg_wf_U];
           
            % Reconstruct downA
            load('Blue_UV_indices.mat')
            downA(: ,:, blueFrames) = downA_B;
            downA(:, :, uvFrames) = downA_U;
        else
            avg_wf = nanmean(nanmean(downA,1),2);
            avg_wf = avg_wf(:);
        end
                
        save(savefn, 'avg_wf', 'motion_detected');
        save(savefn2, 'downA', '-v7.3');
    end

end
