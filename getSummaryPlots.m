function getSummaryPlots(txtpath)

    DirList = readtext(txtpath);
    DirList = DirList(~cellfun('isempty', DirList));
    nDir = length(DirList);

        % Go over each folder to do the analysis
    c_all = [];
    for i = 1:nDir
        cur_folder = DirList{i};
        cd(cur_folder)
        disp(cur_folder)
        searchname = 'Blue_UVregressed_summary_traces.mat';
        searchname = 'UV_summary_traces.mat';
        if exist(searchname, 'file')
            load(searchname)
            c_all = [c_all c];
        else
            fprintf('Did not detect the desired file.')
        end
    end
    
    figure; stem(lags,mean(c_all,2));