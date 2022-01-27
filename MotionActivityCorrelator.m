function MotionActivityCorrelator(txtpath, downFactor, param)

    if nargin < 2 
        downFactor = 2;
        param.blueInitial = 0;
    elseif nargin < 3
        param.blueInitial = 0;
    end

    % Read in paths/ directories from summary_dirs.txt
    DirList = readtext(txtpath);
    DirList = DirList(~cellfun('isempty', DirList));
    nDir = length(DirList);

    % Go over each folder to do the analysis
    for i = 1:nDir
        cur_folder = DirList{i};
        % Do preprocessing
        A_dFoF = MotionActivityPreProcessing(cur_folder, downFactor, param);
        
        % Seed-based correlation
        disp('Doing seed-based correlation analysis...')
        movieData.SeedBasedCorr_GPU(A_dFoF, downFactor, 1000);
        
        % Correlate motion and activity for each channel
        [~, wh_filt] = CorrelateMotionAndActivity(cur_folder, downFactor, param);
        
        % Correlate motion and activity if uv-regression is available 
        if param.blueInitial
            avg_wf = nanmean(nanmean(A_dFoF, 1),2);
            avg_wf = avg_wf(:);
            renewPlots(avg_wf, wh_filt(:,1), 300, 'Blue_UVregressed')
        end
    end

end

