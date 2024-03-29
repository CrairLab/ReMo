function renewPlots(avg_wf, wh_filt, smooth_filter, colorflag)
%Generate plots based on given traces
      
    if nargin < 3
        smooth_filter = 30;
        colorflag = 'Blue';
    elseif nargin < 4
        colorflag = 'Blue';
    end
    
    if exist('parameters.mat', 'file')
        load('parameters.mat')
        scale_factor = param.fr/20;
        hat = 3000 * scale_factor;
        param.scale_factor = scale_factor;
        param.hat = hat;
        save('parameters.mat', 'param')
    else
        scale_factor = 1;
        hat = 3000 * scale_factor;
    end
    
    %test
    if nargin < 1
        colorflag = 'Blue_UVregressed';
        load([colorflag '_summary_traces.mat'])
        smooth_filter = 50;
        %scale_factor = 1;
        smooth_filter = smooth_filter * scale_factor;
        %foldername = [colorflag '_' num2str(smooth_filter) '_' num2str(hat*scale_factor)];
        %mkdir(foldername)
        %cd(fullfile(pwd,foldername))
    end

    
    % Hyperparameters
    cc_width = 1000;
    %hat = 10000;
    %scale_factor = 0.5;
    %smooth_filter = smooth_filter * scale_factor; 

    % Correct photobleaching
    if strcmp(colorflag,  'Blue_UVregressed')
        f_detrend = doTopHat(avg_wf, hat);
        %f_detrend = avg_wf;
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
        f_detrend = doTopHat(f_debleached, hat);
        %f_detrend = f_debleached;

        % Get dff
        dff = f_detrend./ meanF ;
    end
    
    % Skip initial frames (light response etc)
    SkipInitialFrames = 3000 * scale_factor;
    disp(['Skip the first ' num2str(SkipInitialFrames) ' frames']);
    dff = dff(SkipInitialFrames: end);
    wh_filt_ = wh_filt(SkipInitialFrames: end);
    
    % F smoothing
    dff_smoothed = smooth(dff, smooth_filter);

    % Get zscored df/f
    %zdff = (f_detrend - meanF)/sqrt(sum((f_detrend - meanF).^2)/length(f_detrend));
    zdff = zscore(dff);

    % zdff Detrend
    %zdff_detrend = detrend(zdff, 2);
    zdff_detrend = zdff;

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
    
    prefix = [colorflag '_' num2str(smooth_filter) '_' num2str(hat)];

    h1 = figure;
    plot(wh_filt_z); hold on; plot(zdff_detrend);
    legend('zscored motion energy', 'zscored dF/F'); xlabel('Frames')
    title('Motion vs dF/F'); xlim([1, length(avg_wf)]);
    cur_ax = gca; cur_xt = cur_ax.XTick; cur_xt_ = cur_xt + SkipInitialFrames; cur_ax.XTickLabel = num2cell(cur_xt_');
    saveas(h1, [prefix '_motion_energy_vs_dff.png'])
    saveas(h1, [prefix '_motion_energy_vs_dff.fig'])

    h2 = figure;
    plot(wh_filt_smoothed); hold on; plot(zdff_detrend_smoothed);
    legend('abs zscored motion energy', 'zscored dF/F'); xlabel('Frames')
    title(['Motion vs dF/F (Smoothed = ' num2str(smooth_filter) ')']); 
    xlim([1, length(avg_wf)]); cur_ax = gca; cur_ax.XTickLabel = num2cell(cur_xt_');
    saveas(h2, [prefix '_motion_energy_abs_vs_dff_smoothed.png'])
    saveas(h2, [prefix '_motion_energy_abs_vs_dff_smoothed.fig'])


    h3 = figure; plot(dff); 
    legend('dF/F'); xlabel('Frames')
    title('dF/F (detrended)'); xlim([1, length(avg_wf)]);
    cur_ax = gca; cur_ax.XTickLabel = num2cell(cur_xt_');
    saveas(h3, [prefix '_detrendeddFF.png'])
    saveas(h3, [prefix '_detrendeddFF.fig'])

    h4 = figure; plot(dff_smoothed);
    legend('dF/F (smoothed)'); xlabel('Frames')
    title('dF/F (detrended & smoothed)'); xlim([1, length(avg_wf)]);
    cur_ax = gca; cur_ax.XTickLabel = num2cell(cur_xt_');
    saveas(h4, [prefix '_detrendeddFF_smoothed.png'])
    saveas(h4, [prefix '_detrendeddFF_smoothed.fig'])

    h5 = figure; %Cross correlations
    if length(zdff_detrend_smoothed) >= length(wh_filt_smoothed)
        zdff_detrend_smoothed_ = zdff_detrend_smoothed(1:length(wh_filt_smoothed));
        wh_filt_smoothed_ = wh_filt_smoothed;
    else
        wh_filt_smoothed_ = wh_filt_smoothed(1:length(zdff_detrend_smoothed));
        zdff_detrend_smoothed_ = zdff_detrend_smoothed;
    end
    [c,lags] = xcorr(zdff_detrend_smoothed_, wh_filt_smoothed_, cc_width * scale_factor,'normalized');
    stem(lags,c); hold on
    % Permutated cross correlations
    
    [c_p, c_2p5, c_97p5, lags_p] = xcorr_circularPerm(zdff_detrend_smoothed_, wh_filt_smoothed_...
        , cc_width * scale_factor);
    stem(lags_p,c_p); plot(lags_p, c_2p5); plot(lags_p, c_97p5);    
    legend('Original', 'Permutated (mean)', 'Permutated 2.5% ', 'Permutated 97.5%')
    title(['Cross-correlation btw zscored dFF and zscored motion energy ('...
        num2str(smooth_filter), ')']);
    saveas(h5, [prefix '_xcorr_zscored_smoothed.png'])
    saveas(h5, [prefix '_xcorr_zscored_smoothed.fig'])
    
    save([colorflag '_summary_traces.mat'], 'avg_wf', 'zdff', 'wh_filt',...
        'wh_filt_thresh', 'zdff_detrend', 'zdff_detrend_smoothed', ...
        'wh_filt_z', 'wh_filt_smoothed', 'f_detrend', ...
        'dff', 'dff_smoothed', 'SkipInitialFrames', 'smooth_filter', 'c', 'lags'...
        ,'c_p', 'c_2p5', 'c_97p5', 'lags_p')
    
end


function f_detrend = doTopHat(f_input, hat)

    se = strel('line', hat, 0);    
    ff = flipud(f_input(1:hat)')';
    f_tophat = [-ff + 2 * f_input(1); f_input];
    f_detrend = imtophat(f_tophat', se);
    f_detrend = f_detrend(hat+1:end);
    f_detrend = f_detrend';

end


function [c, c_2p5, c_97p5, lags] = xcorr_circularPerm(x, y, maxlag)
% Compute mean cross correlations based on random circular shifts
n = 500; % Number of random trails
c_total = zeros(2*maxlag+1, n);
for i = 1:n
    shift = randi(length(y));
    y_ = circshift(y, shift);
    [c, lags] = xcorr(x, y_, maxlag, 'normalized');
    c_total(:, i) = c;
end

c_2p5 = prctile(c_total, 2.5, 2);
c_97p5 = prctile(c_total, 97.5, 2);
c = nanmean(c_total, 2);

end
