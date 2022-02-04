function MotionActivityCorrelator(txtpath, downFactor, param)

    if nargin < 2 
        downFactor = 2;
        param.blueInitial = 0;
        param.fr = 10;
        param.smoothbase = 10;
    elseif nargin < 3
        param.blueInitial = 0;
        param.fr = 10;
        param.smoothbase = 10;
    end
    
    if param.blueInitial
        disp('Dual wavelengths analysis...')
        param.efr = param.fr / 2; % Effective frame rate is half of the acquisition rate 
        colortag = 'Blue_UVregressed';
    else
        param.efr = param.fr;
        colortag = 'Blue';
    end
    
    fn = [colortag '_summary_traces.mat'];
    smooth_filter = param.smoothbase * param.efr / 10;
        
    % Read in paths/ directories from summary_dirs.txt
    DirList = readtext(txtpath);
    DirList = DirList(~cellfun('isempty', DirList));
    nDir = length(DirList);

    % Go over each folder to do the analysis
    for i = 1:nDir
        cur_folder = DirList{i};
        
        disp(['Effective frame rate = ' num2str(param.efr)])
        disp(['Working on ' cur_folder]);
        summaryfile_path = fullfile(cur_folder, fn);
        
        if ~exist(summaryfile_path, 'file')

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
                avg_wf = avg_wf(:); cd(cur_folder)
                renewPlots(avg_wf, wh_filt(:,1), smooth_filter, 'Blue_UVregressed')
            end
            
        else
            disp('Loading existing summary traces and renew plots...')
            
            % Renew the primary channel (Blue_UVregressed or Blue)
            fn = [colortag '_summary_traces.mat'];
            summaryfile_path = fullfile(cur_folder, fn);
            load(summaryfile_path)
            smooth_filter = param.smoothbase * param.efr / 10; cd(cur_folder)
            renewPlots(avg_wf, wh_filt, smooth_filter, colortag); %Replot
            
            if param.blueInitial
                % Renew individual channels: Blue
                colortag = 'Blue';
                fn = [colortag '_summary_traces.mat'];
                summaryfile_path = fullfile(cur_folder, fn);
                load(summaryfile_path)
                smooth_filter = param.smoothbase * param.efr / 10; cd(cur_folder)
                renewPlots(avg_wf, wh_filt, smooth_filter, colortag); %Replot
                
                % Renew individual channels: UV
                colortag = 'UV';
                fn = [colortag '_summary_traces.mat'];
                summaryfile_path = fullfile(cur_folder, fn);
                load(summaryfile_path)
                smooth_filter = param.smoothbase * param.efr / 10; cd(cur_folder)
                renewPlots(avg_wf, wh_filt, smooth_filter, colortag); %Replot
            end               
        end
        
        clear A_dFoF
        clearAllMemoizedCaches;
    end

end

