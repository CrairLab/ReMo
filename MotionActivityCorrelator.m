function MotionActivityCorrelator(txtpath, downFactor)

    if nargin <2 
        downFactor = 2;
    end

    % Read in paths/ directories from summary_dirs.txt
    DirList = readtext(txtpath);
    DirList = DirList(~cellfun('isempty', DirList));
    nDir = length(DirList);

    % Go over each folder to do the analysis
    for i = 1:nDir
        cur_folder = DirList{i};
        % Do preprocessing
        MotionActivityPreProcessing(cur_folder, downFactor)
        CorrelateMotionAndActivity(cur_folder, downFactor)    
    end

end

