function CorrelationMapping(txtpath)

    DirList = readtext(txtpath);
    DirList = DirList(~cellfun('isempty', DirList));
    nDir = length(DirList);

        % Go over each folder to do the analysis
    for i = 1:nDir
        cur_folder = DirList{i};
        cd(cur_folder)
        
        disp(['Processing ' cur_folder])
        dFoF_fn = dir('*filtered.mat');
        dFoF_fn = dFoF_fn.name;
        load(dFoF_fn)
        sz = size(A_dFoF);
        
        mot_fn = dir('Blue_UVregressed_summary_traces.mat');
        mot_fn = mot_fn.name;
        load(mot_fn);
        
        % Do top hat filtering
        if SkipInitialFrames == 3000
            hat = 3000;
        else
            hat = 1500;
        end
        tic;
        A_dFoF = movieData.TopHatFiltering(A_dFoF, hat);
        toc;
        
        A_dFoF = reshape(A_dFoF, [sz(1)*sz(2), sz(3)]);

        wh_filt_B = wh_filt(:,1);
        wh_filt_B = zscore(wh_filt_B);
        wh_filt_B = smooth(abs(wh_filt_B), smooth_filter);


        if sz(3) >= length(wh_filt_B)
            A_dFoF = A_dFoF(:, 1:length(wh_filt_B));
        else
            wh_filt_B = wh_filt_B(1:sz(3));
        end

        max_lag = lags(find(c == max(c)));
        min_lag = lags(find(c == min(c)));

        %pixel_nanmean = nanmean(A_dFoF, 2);
        %ind_mid = round(sz(1)*sz(2)/2);

        plotCorrelationMaps(A_dFoF, sz, wh_filt_B, 0, smooth_filter, hat)
        plotCorrelationMaps(A_dFoF, sz, wh_filt_B, 50, smooth_filter, hat)
        plotCorrelationMaps(A_dFoF, sz, wh_filt_B, 100, smooth_filter, hat)
        plotCorrelationMaps(A_dFoF, sz, wh_filt_B, 200, smooth_filter, hat)
        plotCorrelationMaps(A_dFoF, sz, wh_filt_B, 300, smooth_filter, hat)
        plotCorrelationMaps(A_dFoF, sz, wh_filt_B, max_lag, smooth_filter, hat)
        plotCorrelationMaps(A_dFoF, sz, wh_filt_B, min_lag, smooth_filter, hat)

    end


end


function plotCorrelationMaps(A_dFoF, sz, wh_filt_B, lag, smooth_filter, hat)

mkdir('Correlation_outputs')

[wh_filt_B, A_dFoF] = movieData.timelagTruncate(wh_filt_B', A_dFoF, lag);
wh_filt_B = wh_filt_B';
[r, pvals] = corr(A_dFoF', wh_filt_B);

r = reshape(r, [sz(1) sz(2)]);
r_g = gaussSmooth(r, 2,'same');
%pvals = gaussSmooth(pvals, 1, 'same');

fn_base = ['correlations_' num2str(lag) '_' num2str(smooth_filter) '_' num2str(hat)];
fn_base = fullfile(pwd, 'Correlation_outputs', fn_base);

ind_maxcorr = find(r_g == max(r_g(:)));
ind_mincorr = find(r_g == min(r_g(:)));
trace_maxcorr = A_dFoF(ind_maxcorr, :);
trace_mincorr = A_dFoF(ind_mincorr, :);
trace_z_max = zscore(trace_maxcorr);
trace_smoothed_max = smooth(trace_z_max, smooth_filter);
%trace_smoothed_max = doTopHat(trace_smoothed_max, hat);
trace_z_min = zscore(trace_mincorr);
trace_smoothed_min = smooth(trace_z_min, smooth_filter);
%trace_smoothed_min = doTopHat(trace_smoothed_min, hat);

save([fn_base '_trace_maxcorr.mat'], 'ind_maxcorr', 'smooth_filter', 'hat',...
    'trace_maxcorr', 'trace_smoothed_max', 'trace_mincorr', 'trace_smoothed_min', 'wh_filt_B')

h0 = figure; fn0 = [fn_base '_trace_max_min_corr.png'];
plot(wh_filt_B); hold on; plot(trace_smoothed_max); %plot(trace_smoothed_min);
%title(['Traces of max/min-correlation vs Motion Energy (smooth = ' ...
    %num2str(smooth_filter) ')'])
legend('Motion energy', 'Trace of max corr', 'Trace of min corr')
exportgraphics(h0, [fn0(1:end-4) '.pdf'],'ContentType','vector')
saveas(h0, fn0); saveas(h0, [fn0(1:end-4) '.fig'])

r = reshape(r, [sz(1) sz(2)]);
pvals = reshape(pvals, [sz(1) sz(2)]);

r_g = reshape(r_g, [sz(1) sz(2)]);
save([fn_base '.mat'], 'lag', 'r', 'pvals', 'r_g');

h1 = figure; fn1 = [fn_base '_r.png'];
imagesc(r_g); colormap jet; axis image %colorbar; 

x1 = ceil(ind_maxcorr/sz(1));
y1 = ind_maxcorr - floor(ind_maxcorr/sz(1))*sz(1); 
x2 = ceil(ind_mincorr/sz(1));
y2 = ind_mincorr - floor(ind_mincorr/sz(1))*sz(1);
hold on
fill([x1-2,x1-2,x1+2,x1+2],[y1-2,y1+2,y1+2,y1-2], 'y')
%fill([x2-2,x2-2,x2+2,x2+2],[y2-2,y2+2,y2+2,y2-2], 'g')

%title(['Correlation Map, time lag = ' num2str(lag)], 'FontSize', 15)
caxis([-0.3, 0.3]);
exportgraphics(h1, [fn1(1:end-4) '.pdf'],'ContentType','vector')
saveas(h1, fn1); saveas(h1, [fn1(1:end-4) '.fig'])

h2 = figure; fn2 = [fn_base '_pvals.png'];
imagesc(pvals); colormap jet; axis image %colorbar; 
hold on
fill([x1-2,x1-2,x1+2,x1+2],[y1-2,y1+2,y1+2,y1-2], 'y')
fill([x2-2,x2-2,x2+2,x2+2],[y2-2,y2+2,y2+2,y2-2], 'g')
%title(['P values map, time lag = ' num2str(lag)], 'FontSize', 15)
caxis([0, 0.05]);
exportgraphics(h2, [fn1(1:end-4) '.pdf'],'ContentType','vector')
saveas(h2, fn2); saveas(h2, [fn2(1:end-4) '.fig'])


end
