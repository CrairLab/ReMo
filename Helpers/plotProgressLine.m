function plotProgressLine()

load('Blue_summary_traces.mat')

h1 = figure('visible', 'off');
max_frame = size(dff, 1); %max_frame = 100;
F(max_frame) = struct('cdata',[],'colormap',[]);


hold on
plot(wh_filt_smoothed); %hold on;
plot(zdff_detrend_smoothed); 
ax = gca; ax.XLim = [0, max_frame];
%legend('Motion energy (smoothed)', 'Retina activity (smoothed)')
hold off


tic;

for f = 1:max_frame


plot(wh_filt_smoothed); hold on;
plot(zdff_detrend_smoothed);
xline(f, 'LineWidth', 2); hold off;
F(f) = getframe(gcf);

if mod(f, 1000) == 0
    disp(num2str(f))
end

end

toc;

v = VideoWriter('Avg_trace_moving_bar.avi','Motion JPEG AVI');
v.FrameRate = 10;
open(v)
writeVideo(v, F);
close(v)
%F = getframe(gca);

