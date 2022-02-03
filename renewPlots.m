function renewPlots(avg_wf, wh_filt, smooth_filter, colorflag)
%Generate plots based on given traces
    
    scale_factor = smooth_filter / 30;
    SkipInitialFrames = 3000 * scale_factor;
    disp(['Skip the first ' num2str(SkipInitialFrames) ' frames']);
    
    if nargin < 3
        smooth_filter = 30;
        colorflag = 'Blue';
    elseif nargin < 4
        colorflag = 'Blue';
    end

    % Correct photobleaching
    if strcmp(colorflag,  'Blue_UVregressed')
        f_detrend = doTopHat(avg_wf, 600 * scale_factor);
        dff = f_detrend;
    else
        x = 1:length(avg_wf); x = x';
        f = fit(x,avg_wf,'exp1');
        trend = f.a.*exp(f.b.*x);
        mean_baseline = nanmean(trend);
        f_debleached = avg_wf - trend + mean_baseline;

        % Get mean intensity
        meanF = mean(f_debleached);

        % F Detrend       
        %f_detrend = detrend(f_debleached, 2);

        % Detrend by tophat filtering
        f_detrend = doTopHat(f_debleached, 600 * scale_factor);

        % Get dff
        dff = f_detrend./ meanF ;
    end
    
    % Skip initial frames (light response etc)
    dff = dff(SkipInitialFrames: end);
    wh_filt_ = wh_filt(SkipInitialFrames: end);
    
    % F smoothing
    dff_smoothed = smooth(dff, smooth_filter);

    % Get zscored df/f
    %zdff = (f_detrend - meanF)/sqrt(sum((f_detrend - meanF).^2)/length(f_detrend));
    zdff = zscore(dff);

    % zdff Detrend
    zdff_detrend = detrend(zdff, 2);

    % zdff Smoothing 
    zdff_detrend_smoothed = smooth(zdff_detrend, smooth_filter);

    %fr = 100; % set this to the frame rate of the face movie.
    %windowSize = round(2*fr);
    %b = (1/windowSize)*ones(1,windowSize);
    %a = 1;
    %zdff_detrend_filt = filter(b,a,zdff_detrend);

    % Zscore and smooth motion energy
    wh_filt_z = zscore(wh_filt_);
    wh_filt_thresh = wh_filt_ > 0.005;
    wh_filt_smoothed = smooth(abs(wh_filt_z), smooth_filter);

    h1 = figure;
    plot(wh_filt_z); hold on; plot(zdff_detrend);
    legend('zscored motion energy', 'zscored dF/F'); xlabel('Frames')
    title('Motion vs dF/F'); xlim([1, length(avg_wf)]);
    cur_ax = gca; cur_xt = cur_ax.XTick; cur_xt_ = cur_xt + SkipInitialFrames; cur_ax.XTickLabel = num2cell(cur_xt_');
    saveas(h1, [colorflag '_motion_energy_vs_dff.png'])

    h2 = figure;
    plot(wh_filt_smoothed); hold on; plot(zdff_detrend_smoothed);
    legend('abs zscored motion energy', 'zscored dF/F'); xlabel('Frames')
    title(['Motion vs dF/F (Smoothed = ' num2str(smooth_filter) ')']); 
    xlim([1, length(avg_wf)]); cur_ax = gca; cur_ax.XTickLabel = num2cell(cur_xt_');
    saveas(h2, [colorflag '_motion_energy_abs_vs_dff_smoothed.png'])

    h3 = figure; plot(dff); 
    legend('dF/F'); xlabel('Frames')
    title('dF/F (detrended)'); xlim([1, length(avg_wf)]);
    cur_ax = gca; cur_ax.XTickLabel = num2cell(cur_xt_');
    saveas(h3, [colorflag '_detrendeddFF.png'])

    h4 = figure; plot(dff_smoothed);
    legend('dF/F (smoothed)'); xlabel('Frames')
    title('dF/F (detrended & smoothed)'); xlim([1, length(avg_wf)]);
    cur_ax = gca; cur_ax.XTickLabel = num2cell(cur_xt_');
    saveas(h4, [colorflag '_detrendeddFF_smoothed.png'])

    h5 = figure; 
    if length(zdff_detrend_smoothed) >= length(wh_filt_smoothed)
        zdff_detrend_smoothed_ = zdff_detrend_smoothed(1:length(wh_filt_smoothed));
        wh_filt_smoothed_ = wh_filt_smoothed;
    else
        wh_filt_smoothed_ = wh_filt_smoothed(1:length(zdff_detrend_smoothed));
        zdff_detrend_smoothed_ = zdff_detrend_smoothed;
    end
    [c,lags] = xcorr(zdff_detrend_smoothed_, wh_filt_smoothed_, 600 * scale_factor,'normalized');
    stem(lags,c)
    title('Cross-correlation btw zscored dFF and zscored motion energy')
    saveas(h5, [colorflag '_xcorr_zscored_smoothed.png'])
    
    save([colorflag '_summary_traces.mat'], 'avg_wf', 'zdff', 'wh_filt',...
        'wh_filt_thresh', 'zdff_detrend', 'zdff_detrend_smoothed', ...
        'wh_filt_z', 'wh_filt_smoothed', 'f_detrend', ...
        'dff', 'dff_smoothed', 'SkipInitialFrames', 'smooth_filter')
    
end


function f_detrend = doTopHat(f_input, hat)

    se = strel('line', hat, 0);    
    ff = flipud(f_input(1:hat)')';
    f_tophat = [-ff + 2 * f_input(1); f_input];
    f_detrend = imtophat(f_tophat', se);
    f_detrend = f_detrend(hat+1:end);
    f_detrend = f_detrend';

end
