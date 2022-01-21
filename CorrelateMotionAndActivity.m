function CorrelateMotionAndActivity(cur_folder, downFactor)
% Go to s folder and use cmos moives to get activity traces, and use
% infrared cam movies to get motion energy.
    if nargin < 1
        downFactor = 2;
    end

    try
        
        cd(cur_folder);
        smooth_filter = 300; % Smooth over 300 frames
        disp(['Working on ' cur_folder]);
        
        if ~exist('summary_traces.mat', 'file')
            
            %Get averaged fluorescent traces
            [avg_wf, motion_detected, ~] = ReadAndGetAvg(downFactor);
            
            %Get motion energy
            wh_filt = ComputeMotionEnergy(downFactor);
            
            %Generate plots
            renewPlots(avg_wf, wh_filt, smooth_filter);
            
        else
            disp('Loading existing summary traces and renew plots...')
            load('summary_traces.mat')
            renewPlots(avg_wf, wh_filt, smooth_filter); %Replot
        end
        
    catch
        warning('Errors detected, skip this folder!')
    end
end


function renewPlots(avg_wf, wh_filt, smooth_filter)
%Generate plots based on given traces 

            % Correct photobleaching
            x = 1:length(avg_wf); x = x';
            f = fit(x,avg_wf,'exp1');
            trend = f.a.*exp(f.b.*x);
            trend = trend./min(trend);
            f_debleached = avg_wf./trend;
            
            % Get mean intensity
            meanF = mean(f_debleached);

            % F Detrend       
            f_detrend = detrend(f_debleached, 2);
            
            % Get dff
            dff = f_detrend./ meanF ;

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
            wh_filt_z = zscore(wh_filt);
            wh_filt_thresh = wh_filt>0.005;
            wh_filt_smoothed = smooth(abs(wh_filt_z), smooth_filter);

            h1 = figure;
            plot(wh_filt_z); hold on; plot(zdff_detrend);
            legend('zscored motion energy', 'zscored dF/F'); xlabel('Frames')
            title('Motion vs dF/F'); xlim([1, length(avg_wf)]);
            saveas(h1, 'motion_energy_vs_dff.png')

            h2 = figure;
            plot(wh_filt_smoothed); hold on; plot(zdff_detrend_smoothed);
            legend('abs zscored motion energy', 'zscored dF/F'); xlabel('Frames')
            title(['Motion vs dF/F (Smoothed = ' num2str(smooth_filter) ')']); 
            xlim([1, length(avg_wf)]);
            saveas(h2, 'motion_energy_abs_vs_dff_smoothed.png')

            h3 = figure; plot(dff); 
            legend('dF/F'); xlabel('Frames')
            title('dF/F (detrended)'); xlim([1, length(avg_wf)]);
            saveas(h3, 'detrendeddFF.png')

            h4 = figure; plot(dff_smoothed); 
            legend('dF/F (smoothed)'); xlabel('Frames')
            title('dF/F (detrended & smoothed)'); xlim([1, length(avg_wf)]);
            saveas(h4, 'detrendeddFF_smoothed.png')

            save('summary_traces.mat', 'avg_wf', 'zdff', 'wh_filt',...
                'wh_filt_thresh', 'zdff_detrend', 'zdff_detrend_smoothed', ...
                'wh_filt_z', 'wh_filt_smoothed', 'f_detrend', ...
                'dff', 'dff_smoothed')
end


