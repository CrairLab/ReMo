function MotionActivityCorrelator(txtpath, downFactor, param)

    if nargin < 2 
        downFactor = 2;
        param.blueInitial = 0;
        param.fr = 10;  
    elseif nargin < 3
        param.blueInitial = 0;
        param.fr = 10;  
    end
    
    if param.blueInitial
        disp('Dual wavelengths analysis...')
        param.efr = param.fr / 2; % Effective frame rate is half of the acquisition rate 
    else
        param.efr = param.fr;
    end
        
    % Read in paths/ directories from summary_dirs.txt
    DirList = readtext(txtpath);
    DirList = DirList(~cellfun('isempty', DirList));
    nDir = length(DirList);

    % Go over each folder to do the analysis
    for i = 1:nDir
        cur_folder = DirList{i};
        
        disp(['Effective frame rate = ' num2str(param.efr)])

        % Do preprocessing
        A_dFoF = MotionActivityPreProcessing(cur_folder, downFactor, param);
        
        % Seed-based correlation
        %disp('Doing seed-based correlation analysis...')
        %movieData.SeedBasedCorr_GPU(A_dFoF, downFactor, 1000);
        
        % Correlate motion and activity for each channel
        [~, wh_filt] = CorrelateMotionAndActivity(cur_folder, downFactor, param);
        
        % Correlate motion and activity if uv-regression is available 
        if param.blueInitial
            avg_wf = nanmean(nanmean(A_dFoF, 1),2);
            avg_wf = avg_wf(:);
            smooth_filter = 30 * param.efr / 10;
            renewPlots(avg_wf, wh_filt(:,1), smooth_filter, 'Blue_UVregressed')
        end
        
        clear A_dFoF
        clearAllMemoizedCaches;
    end

end

