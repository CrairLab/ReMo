function wh_filt = ComputeMotionEnergy(downFactor)
% Compute motion energy based on infrared cam

    if nargin < 1
        downFactor = 4;
    end
    
    % Search for infrared cam recordings
    listing = dir('*.avi');
    moviename = listing.name(1:end-4);
    searchfile = [moviename,'_wh_mot_en.mat'];
    
    if exist(searchfile, 'file')
        load(searchfile);
        disp('Loading existing motion energy data...')
    else
        
        reader = VideoReader([listing.folder,'\',listing.name]);
        nframes = reader.NumberofFrames;
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
        
        % Comput motion energy
        movA = single(movA);
        mot_frames = movA(:,:,2:end) - movA(:,:,1:end-1);
        mot_frame = movA(:,:,end) - movA(:,:,1);
  
        wh_mot = sum(sum(mot_frames,1),2);
        wh_mot = wh_mot(:);
        wh_mot = [wh_mot(1); wh_mot];

        wh_total = sum(sum(movA(:,:,2:end),1),2);
        wh_total = wh_total(:);
        wh_total = [sum(sum(movA(:,:,1),1),2); wh_total];

        save(searchfile,'wh_mot','wh_total','mot_frame');
    end



        %% Normalize, filter, and threshold whisker motion data
        % to get a binary whisking vs non-whisking period.

        fr = 10; % set this to the frame rate of the face movie.
        
        % Normalization
        wh = wh_mot./wh_total;
        windowSize = round(2*fr);
        b = (1/windowSize)*ones(1,windowSize);
        a = 1;
        
        % FIR filtering
        wh_filt = filter(b,a,wh);

        h1 = figure('visible', 'off'); plot(wh_filt);
        saveas(h1, [moviename, '_wh_filt.png'])

        wh_filt_thresh = wh_filt>0.005;

        h2 = figure('visible', 'off');
        plot(wh_filt_thresh); ylim([0 2])
        saveas(h2, [moviename, '_wh_filt_thresh.png'])
        
end
