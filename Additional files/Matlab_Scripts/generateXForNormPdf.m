function xVect = generateXForNormPdf(mu, sigma, xlimits, varargin)
%GENERATEXFORNORMPDF is used to generate the x vector or the set of sample
%points where normpdf will calculate the normal distribution values. This
%performs variable sampling of points taking into account the
%charateristics of the given gaussian(mu, sigma). It can take two optional
%parameters.
%
%Syntax
%
%xVect = generateXForNormPdf(mu, sigma, xlimits);
%xVect = generateXForNormPdf(mu, sigma, xlimits, 'samplePoints', samplePointsVal);
%xVect = generateXForNormPdf(mu, sigma, xlimits, 'samplePoints', samplePointsVal, 'tailPoints', tailPointsVal);
%
%Arguments
%
%mu = gaussian mean
%sigma = gaussian standard deviation
%xlimits = [xmin xmax] to generate x values
%
% OPTIONAL ARGUMENTS
%
%samplePoints = 100 (default)
%Sample points number is the number of points that are sampled within the 
%region mu+3sigma to mu-3sigma.
%
%tailPoints = 10 (default)
%Tail points number is the number of points that are sampled within the 
%region mu+3sigma to xmax and xmin to mu-3sigma. Infact the total tail
%points will be 2 times the given value.

%% Initialization
inputP = inputParser;
defaultSamplePoints = 100;
defaultTailPoints = 10;
xmin = xlimits(1);
xmax = xlimits(2);

addOptional(inputP, 'samplePoints', defaultSamplePoints);
addOptional(inputP, 'tailPoints', defaultTailPoints);
parse(inputP, varargin{:});

samplePoints = inputP.Results.samplePoints;
tailPoints = inputP.Results.tailPoints;

%% Generating 1 sigma points
numSigma1Pts = floor(0.66*samplePoints);
sigma1Pts = linspace(mu-sigma, mu+sigma, numSigma1Pts);

%% Generating 2 sigma points
numSigma2LeftPts = floor(0.14*samplePoints);
sigma2LeftPts = linspace(mu-2*sigma, mu-sigma, numSigma2LeftPts+1);
sigma2LeftPts = sigma2LeftPts(1:end-1);

numSigma2RightPts = floor(0.28*samplePoints)-numSigma2LeftPts;
sigma2RightPts = linspace(mu+sigma, mu+2*sigma, numSigma2RightPts+1);
sigma2RightPts = sigma2RightPts(2:end);

%% Generating 3 sigma points
numSigma3LeftPts = floor((samplePoints-numSigma1Pts...
                    -numSigma2LeftPts-numSigma2RightPts)/2);
sigma3LeftPts = linspace(mu-3*sigma, mu-2*sigma, numSigma3LeftPts+1);
sigma3LeftPts = sigma3LeftPts(1:end-1);

numSigma3RightPts = samplePoints-numSigma1Pts-numSigma2LeftPts...
                        -numSigma2RightPts-numSigma3LeftPts;
sigma3RightPts = linspace(mu+2*sigma, mu+3*sigma, numSigma3RightPts+1);
sigma3RightPts = sigma3RightPts(2:end);

%% Generating tail points
leftTailPts = linspace(xmin,mu-3*sigma, tailPoints+1);
leftTailPts = leftTailPts(1:end-1);

rightTailPts = linspace(mu+3*sigma, xmax, tailPoints+1);
rightTailPts = rightTailPts(2:end);

%% Output X vector
xVect = [leftTailPts sigma3LeftPts sigma2LeftPts...
            sigma1Pts...
            sigma2RightPts sigma3RightPts rightTailPts];













