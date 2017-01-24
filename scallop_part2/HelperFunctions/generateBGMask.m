function bgMask = generateBGMask( cropWindowWidth, cropWindowHeight, bgRadiusPercent, fgMask )
%GENERATEBGMASK Function to generate Background Mask

minDim = min(cropWindowWidth, cropWindowHeight);
bgRadius = round(minDim*bgRadiusPercent);

bgMask1 = getCircMask(1, 1, bgRadius, cropWindowWidth, cropWindowHeight);
bgMask2 = getCircMask(cropWindowWidth, 1, bgRadius, cropWindowWidth, cropWindowHeight);
bgMask3 = getCircMask(1, cropWindowHeight, bgRadius, cropWindowWidth, cropWindowHeight);
bgMask4 = getCircMask(cropWindowWidth, cropWindowHeight, bgRadius, cropWindowWidth, cropWindowHeight);

bgMask = (bgMask1 | bgMask2 | bgMask3 | bgMask4) & ~fgMask;
