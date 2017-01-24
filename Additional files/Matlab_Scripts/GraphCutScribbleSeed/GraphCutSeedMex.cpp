/*********************************************************************
 * Demo.cpp
 *
 * This file shows the basics of setting up a mex file to work with
 * Matlab.  This example shows how to use 2D matricies.  This may
 * 
 * Keep in mind:
 * <> Use 0-based indexing as always in C or C++
 * <> Indexing is column-based as in Matlab (not row-based as in C)
 * <> Use linear indexing.  [x*dimy+y] instead of [x][y]
 *
 * For more information, see my site: www.shawnlankton.com
 * by: Shawn Lankton
 *
 ********************************************************************/
#include <opencv2/core/core.hpp> 
#include <opencv2/highgui/highgui.hpp> 
#include <matrix.h>
#include <mex.h>   
#include "opencv_matlab.hpp"
# include "graphCutSeed.h"

/* Definitions to keep compatibility with earlier versions of ML */
#ifndef MWSIZE_MAX
typedef int mwSize;
typedef int mwIndex;
typedef int mwSignedIndex;

#if (defined(_LP64) || defined(_WIN64)) && !defined(MX_COMPAT_32)
/* Currently 2^48 based on hardware limitations */
# define MWSIZE_MAX    281474976710655UL
# define MWINDEX_MAX   281474976710655UL
# define MWSINDEX_MAX  281474976710655L
# define MWSINDEX_MIN -281474976710655L
#else
# define MWSIZE_MAX    2147483647UL
# define MWINDEX_MAX   2147483647UL
# define MWSINDEX_MAX  2147483647L
# define MWSINDEX_MIN -2147483647L
#endif
#define MWSIZE_MIN    0UL
#define MWINDEX_MIN   0UL
#endif

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

//declare variables
    mxArray *mImage, *mForegroundMask, *mBackgroundMask, *mSegmentMask, *mGrapcutResult;
    const mwSize *dims;
    cv::Mat image;
    bool *foregroundMask, *backgroundMask, *segmentMask;
    double *graphcutResult;
    int numRows, numCols, numDims;
    bool **foregroundMask2D, **backgroundMask2D, **segmentMask2D;
    int numBinsPerChannel = 64, numChannels;
    double bha_slope = 0.1;

//associate inputs
    mImage = mxDuplicateArray(prhs[0]);
    mForegroundMask = mxDuplicateArray(prhs[1]);
    mBackgroundMask = mxDuplicateArray(prhs[2]);

//figure out dimensions
    dims = mxGetDimensions(mImage);
    numDims = mxGetNumberOfDimensions(mImage);
    numRows = (int)dims[0]; 
    numCols = (int)dims[1];
    numChannels = (numDims == 3 ? dims[2] : 1);
    
    //mexPrintf("Number of channels = %d", numChannels);
    
//Associate outputs
   mSegmentMask = plhs[0] = mxCreateLogicalMatrix(numRows,numCols);
   mGrapcutResult = plhs[1] = mxCreateDoubleMatrix(1,1,mxREAL);

// Allocate, copy, and convert the input image
    // @note: input is double
    image = cv::Mat::zeros(cv::Size(numCols, numRows), CV_64FC(numChannels));
    om::copyMatrixToOpencv(mxGetPr(mImage), image);
    image.convertTo(image, CV_8U, 255);

//Attaching Matlab to C++ variables
    //imageName = mxArrayToString(mImageName);
    foregroundMask = mxGetLogicals(mForegroundMask);
    backgroundMask = mxGetLogicals(mBackgroundMask);
    segmentMask = mxGetLogicals(mSegmentMask);
    graphcutResult = mxGetPr(mGrapcutResult);
    
    //plhs[2] = mImage;
    plhs[2] = mxCreateNumericArray(numDims, dims, mxUINT8_CLASS, mxREAL);
    plhs[3] = mForegroundMask;
    plhs[4] = mBackgroundMask;
    
    om::copyMatrixToMatlab<unsigned char>(image, (unsigned char*)mxGetPr(plhs[2]));
    
//Graphcut
	OnceCutSeedsMaskInput(image, foregroundMask, backgroundMask, segmentMask, numRows, numCols, bha_slope, numBinsPerChannel);
    
    //cv::imwrite("frida_redone.jpg", image);
    
    return;
}
