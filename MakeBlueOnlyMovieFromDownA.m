function MakeBlueOnlyMovieFromDownA(downA)

    blueInitial = 2;
    matchflag = 1;

    if nargin < 1
        fn = dir('*downsampled.mat');
        load(fn.name)
    end

    [A4B, ~] = separateBlueUV(downA, blueInitial, matchflag);

    % Photobleaching correction
    A5 = movieData.bleachCorrection(A4B);
    hat = 3000;
    %A5 = movieData.TopHatFiltering(A4, hat); 

    clear A4B

    % Gaussian smoothing
    A6 = movieData.GauSmoo(A5, 1); % Sigma = 1
    %A6 = A5;

    clear A5

    % dFoF
    A_dFoF = movieData.grossDFoverF(A6, 1, 50);
    A_dFoF = single(A_dFoF);

    clear A6

    save('Blue_dFF_only.mat', 'A_dFoF', '-v7.3'); clear A_dFoF

end