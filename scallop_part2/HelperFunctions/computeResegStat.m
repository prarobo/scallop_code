function [ statNumbers ] = computeResegStat( params, segmentCrescentMask, segmentCenterMask, fgMask, centerMask, ...
                                                                    bgMask, scallopCircleMask )
%COMPUTERESEGSTAT Computes statistics

scallopCircPix = sum(scallopCircleMask(:));

segmentCrescentInCircPix = sum(sum(segmentCrescentMask(scallopCircleMask)));
segmentCrescentOutCircPix = sum(sum(segmentCrescentMask(~scallopCircleMask))); 
fgCrescentInCircPix = sum(sum(fgMask(scallopCircleMask)));

segmentCenterInCircPix = sum(sum(segmentCenterMask(scallopCircleMask)));
segmentCenterOutCircPix = sum(sum(segmentCenterMask(~scallopCircleMask))); 
fgCenterInCircPix = sum(sum(centerMask(scallopCircleMask)));

statNumbers.segmentCrescentInCircPercent = segmentCrescentInCircPix/scallopCircPix;
statNumbers.segmentCrescentOutCircPercent = segmentCrescentOutCircPix/scallopCircPix;
statNumbers.fgCrescentInCircPercent = fgCrescentInCircPix/scallopCircPix;
statNumbers.segmentCrescentApprecPercent = segmentCrescentInCircPix/fgCrescentInCircPix;

statNumbers.segmentCenterInCircPercent = segmentCenterInCircPix/scallopCircPix;
statNumbers.segmentCenterOutCircPercent = segmentCenterOutCircPix/scallopCircPix;
statNumbers.fgCenterInCircPercent = fgCenterInCircPix/scallopCircPix;
statNumbers.segmentCenterApprecPercent = segmentCenterInCircPix/fgCenterInCircPix;