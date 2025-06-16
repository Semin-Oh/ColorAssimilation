function [outRGB, illumEstPyr] = colorAssimilationCC(inRGB, opts)
%COLORASSIMILATIONCC  Implementation of the multiresolution color
%constancy / color–assimilation model proposed by Ulucan et al. (ACCV 2024).
%
%   outRGB = COLORASSIMILATIONCC(inRGB) processes the input sRGB image
%   INRGB according to the algorithm described in "A computational model for
%   color assimilation illusions and color constancy" (Ulucan, Ulucan & Ebner,
%   2024) and returns the corrected / perceived image OUTRGB (sRGB, uint8).
%
%   [outRGB, illumEstPyr] = COLORASSIMILATIONCC(...) also returns a cell
%   array containing the estimated (spatially‑varying) illuminant at every
%   scale of the Gaussian pyramid.
%
%   ... = COLORASSIMILATIONCC(..., OPTS) allows the following optional
%   parameters to be adjusted (pass as a struct):
%       OPTS.gammaIllum  – {double, 0.2}   scaling for σ in local SAC filter
%       OPTS.singleIllum – {logical,false} pick γ automatically for single
%                                            (≈ 0.95) or mixed (≈ 0.095)
%       OPTS.clip3pc     – {logical,true}  discard 3 % brightest & darkest
%       OPTS.histEq      – {logical,true}  perform L* histogram equalisation
%       OPTS.guidedR     – {double,4}      radius used by imguidedfilter
%       OPTS.guidedEps   – {double,1e-3}   ε  "     "       "
%
%   EXAMPLE
%       I  = imread('illusion.png');
%       O  = colorAssimilationCC(I);
%       figure,  imshowpair(I,O,'montage');
%
%   NOTE  This code is a faithful—but concise—Matlab re‑implementation of
%   the paper.  It is fully self‑contained and requires only the Image
%   Processing Toolbox (for rgb2lab/lab2rgb & imguidedfilter).
%
%   Markus (2025‑06‑16)    MIT License

% -----------------------------------------------------------------------
% 1. housekeeping & options ------------------------------------------------
if nargin < 2, opts = struct; end
opts = setDefaults(opts);

% ensure double in [0,1]
if ~isa(inRGB,'double'), inRGB = im2double(inRGB); end
[h,w,~] = size(inRGB);

% -----------------------------------------------------------------------
% 2. linearise (inverse sRGB gamma) ---------------------------------------
linRGB = sRGB2linear(inRGB);

% optionally drop 3 % darkest/brightest pixels (noise & clipping)
if opts.clip3pc
    pLow  = prctile(linRGB(:),   3);
    pHigh = prctile(linRGB(:), 97);
    linRGB = min(max(linRGB, pLow), pHigh);
end

% -----------------------------------------------------------------------
% 3. obtain perceptual lightness layer (Eq. & histEq) ---------------------
meanChan = squeeze(mean(mean(linRGB,1),2));
scale    = mean(meanChan) ./ meanChan;      % Gray‑world gains
linScaled = bsxfun(@times, linRGB, reshape(scale,1,1,3));

labScaled = rgb2lab(linScaled);             % convert using D65 white
Lstar     = labScaled(:,:,1);
if opts.histEq
    LstarEq = histeq(Lstar/100)*100;        % bring back to [0,100]
else
    LstarEq = Lstar;
end

% -----------------------------------------------------------------------
% 4. build pyramids --------------------------------------------------------
M = floor(log2(min(h,w))) - 2;              % number of levels as paper
imgPyr   = cell(1,M);
ellumPyr = cell(1,M);

curr = linRGB;
for m = 1:M
    imgPyr{m} = curr;

    % --- local space‑average colour (LSAC) --------------------------------
    [hm,wm,~] = size(curr);
    if opts.singleIllum
        gamma = 0.95;                       % favour large neighbourhood
    else
        gamma = opts.gammaIllum;            % default 0.2 ≈ mixed illum.
    end
    sigma = gamma * (max(hm,wm)/2);

    illum = zeros(size(curr));
    for c = 1:3
        % illum(:,:,c) = imgaussfilt(curr(:,:,c), sigma, 'FilterSize', ceil(6*sigma));
        fsz = ceil(6*sigma);
        if mod(fsz,2) == 0, fsz = fsz + 1; end  % make it odd
        illum(:,:,c) = imgaussfilt(curr(:,:,c), sigma, 'FilterSize', fsz);

        % guided filter to align with edges (depth‑proxy)
        illum(:,:,c) = imguidedfilter(illum(:,:,c), curr(:,:,c), ...
            'NeighborhoodSize', 2*opts.guidedR+1, ...
            'DegreeOfSmoothing', opts.guidedEps);
    end
    ellumPyr{m} = illum;

    % downsample (next level)
    if m < M, curr = imresize(curr,0.5,'bilinear'); end
end

% -----------------------------------------------------------------------
% 5. multiresolution colour constancy -------------------------------------
% Build Laplacian pyramid of the image
LapPyr = cell(1,M);
for t = 1:M-1
    LapPyr{t} = imgPyr{t} - imresize(imgPyr{t+1}, size(imgPyr{t}(:,:,1)), 'bilinear');
end
LapPyr{M} = imgPyr{M};                      % coarsest level (residual)

% Divide Laplacian coeffs by Gaussian illuminant estimates
adjLap = cell(1,M);
for t = 1:M
    adjLap{t} = LapPyr{t} ./ max(ellumPyr{t}, 1e-6);  % avoid division by 0
end

% Pyramid collapse (Eq. 12–13)
recon = adjLap{M};
for t = M-1:-1:1
    recon = imresize(recon, size(adjLap{t}(:,:,1)), 'bilinear') + adjLap{t};
end

reflectance = recon;                        % o(x,y) in paper

% -----------------------------------------------------------------------
% 6. merge with perceptual lightness & return -----------------------------
labRef   = rgb2lab(min(max(reflectance,0),1));
labRef(:,:,1) = LstarEq;                    % substitute lightness layer
outRGB   = lab2rgb(labRef, 'OutputType','uint8');

if nargout > 1
    illumEstPyr = ellumPyr;                 % for inspection/debug
end
end

%=========================================================================%
%                              HELPERS                                    %
%=========================================================================%
function opts = setDefaults(opts)
d.gammaIllum  = 0.2;     % γ for mixed‑illum scenes
d.singleIllum = false;   % true: γ = 0.95 (assume one illuminant)
d.clip3pc     = true;
d.histEq      = true;
d.guidedR     = 4;       % guided‑filter radius
d.guidedEps   = 1e-3;    % degree of smoothing
opts = setstructfields(d, opts);
end

function lin = sRGB2linear(srgb)
thr = 0.04045;
lin = zeros(size(srgb));
mask = srgb <= thr;
lin(mask) = srgb(mask)/12.92;
lin(~mask) = ((srgb(~mask)+0.055)/1.055).^2.4;
end

function S = setstructfields(Sdef,Susr)
f = fieldnames(Susr);
for k = 1:numel(f)
    Sdef.(f{k}) = Susr.(f{k});
end
S = Sdef;
end
