function wh_filt = ComputeMotionEnergy(downFactor, param)
% Compute motion energy based on infrared cam

    if nargin < 1
        downFactor = 4;
        param.blueInitial = 0;
        param.efr = 10;
    else
        param.blueInitial = 0;
        param.efr = 10;
    end
    
    % Search for infrared cam recordings
    listing = dir('*.avi');
    moviename = listing.name(1:end-4);
    searchfile = [moviename,'_wh_mot_en.mat'];
    
    if exist(searchfile, 'file')
        load(searchfile);
        disp('Loading existing motion energy data...')
    else
        reader = VideoReader(fullfile(listing.folder,listing.name));
        nframes = reader.NumFrames;
        downHeight = ceil(reader.Height / downFactor);
        downWidth =  ceil(reader.Width / downFactor);
        movA = zeros(downHeight, downWidth, nframes, 'uint8');
        disp('Reading the infra-red cam movie...')

        parfor i = 1:nframes

            if(rem(i,1000) == 0) 
                fprintf('%d out of %d frames processed\n',i,nframes)
            end
            % Do downsampling to save memory
            curFrame = rgb2gray(read(reader, i));
            downFrame = imresize(curFrame, 1/downFactor, 'bilinear');
            movA(:,:,i) = downFrame;
        end
        
        if param.blueInitial
            %Separate Blue UV and do motion energy analysis
            [movA_B, movA_U] = separateBlueUV(movA, param.blueInitial, 1);
            clear movA
            [mot_frame_B, wh_mot_B, wh_total_B] = getMotionEnergy(movA_B);
            clear movA_B
            [mot_frame_U, wh_mot_U, wh_total_U] = getMotionEnergy(movA_U);
            clear movA_U
            wh_filt_B = compute_wh_filt(wh_mot_B, wh_total_B, param.efr);
            wh_filt_U = compute_wh_filt(wh_mot_U, wh_total_U, param.efr);
            wh_filt = [wh_filt_B wh_filt_U];
            wh_mot = [wh_mot_B wh_mot_U];
            wh_total = [wh_total_B wh_total_U];
            mot_frame = [mot_frame_B mot_frame_U];
        else
            % Comput motion energy
            [mot_frame, wh_mot, wh_total] = getMotionEnergy(movA);
            
            wh_filt = compute_wh_filt(wh_mot, wh_total);

            % Plot motion energy
            %plotMotionEnergy(wh_filt, moviename)
        end

        save(searchfile,'wh_mot','wh_total','wh_filt','mot_frame');
    end


        
end


function [mot_frame, wh_mot, wh_total] = getMotionEnergy(mov_input)
% Compute motion energy given input frames
    mov_input = int8(mov_input);
    mot_frames = mov_input(:,:,2:end) - mov_input(:,:,1:end-1);
    mot_frame = mov_input(:,:,end) - mov_input(:,:,1);

    wh_mot = sum(sum(mot_frames,1),2);
    wh_mot = wh_mot(:);
    wh_mot = [wh_mot(1); wh_mot];

    wh_total = sum(sum(mov_input(:,:,2:end),1),2);
    wh_total = wh_total(:);
    wh_total = [sum(sum(mov_input(:,:,1),1),2); wh_total];
end


function wh_filt = compute_wh_filt(wh_mot, wh_total, fr)
    
    if nargin < 3
        fr = 10;
    end

        %fr = 10; % set this to the frame rate of the face movie.

        % Normalization
        wh = wh_mot./wh_total;
        windowSize = round(2*fr);
        b = (1/windowSize)*ones(1,windowSize);
        a = 1;

        % FIR filtering
        wh_filt = filter(b,a,wh);

end

function plotMotionEnergy(wh_filt, moviename)
% Normalize, filter, and threshold whisker motion data
% to get a binary whisking vs non-whisking period.


    h1 = figure('visible', 'off'); plot(wh_filt);
    saveas(h1, [moviename, '_wh_filt.png'])

    wh_filt_thresh = wh_filt>0.005;

    h2 = figure('visible', 'off');
    plot(wh_filt_thresh); ylim([0 2])
    saveas(h2, [moviename, '_wh_filt_thresh.png'])

end