function [A4B, A4U] = separateBlueUV(A4, blueInitial, matchflag)
    
    if nargin < 3
        matchflag = 0;
    end

    % Extract blue and uv frames respectively
    sz = size(A4);
    blueFrames = blueInitial : 2: sz(3);
    uvFrames = setdiff(1:sz(3), blueFrames);

    A4B = A4(:,:,blueFrames);
    A4U = A4(:,:,uvFrames);
    
    
    
    % match number of frames in A and B
    if matchflag
        if size(A4B, 3) >= size(A4U, 3)
            A4B = A4B(:, :, 1:size(A4U, 3));
            blueFrames = blueFrames(1:legnth(uvFrames));
        else
            try
                A4U = A4U(:, :, 2:size(A4B, 3)+1);
                uvFrames = uvFrames(2:length(blueFrames)+1);
            catch
                A4U = A4U(:, :, 1:size(A4B, 3));
                uvFrames = uvFrames(1:length(blueFrames));
            end
        end        
    end
    
    save('Blue_UV_indices.mat','blueFrames', 'uvFrames')
        
end