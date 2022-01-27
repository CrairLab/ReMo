function [avg_wf, wh_filt] = CorrelateMotionAndActivity(cur_folder, downFactor, param)
% Go to s folder and use cmos moives to get activity traces, and use
% infrared cam movies to get motion energy.
    if nargin < 2
        downFactor = 2;
        param.blueInitial = 0;
    elseif nargin < 3
        param.blueInitial = 0;
    end

    try
        
        cd(cur_folder);
        smooth_filter = 300; % Smooth over 300 frames
        disp(['Working on ' cur_folder]);
        
        if ~exist('summary_traces.mat', 'file')
            
            %Get averaged fluorescent traces
            [avg_wf, motion_detected, ~] = ReadAndGetAvg(downFactor, 0 , param);
            
            %Get motion energy
            wh_filt = ComputeMotionEnergy(downFactor, param);
            
            %Generate plots
            if size(avg_wf, 2) == 2
                renewPlots(avg_wf(:, 1), wh_filt(:, 1), smooth_filter, 'Blue');
                renewPlots(avg_wf(:, 2), wh_filt(:, 2), smooth_filter, 'UV');
            end
            
        else
            disp('Loading existing summary traces and renew plots...')
            load('summary_traces.mat')
            renewPlots(avg_wf, wh_filt, smooth_filter); %Replot
        end
        
    catch
        warning('Errors detected, skip this folder!')
    end
end





