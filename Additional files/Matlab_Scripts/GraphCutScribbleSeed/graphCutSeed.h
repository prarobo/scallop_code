/*
 * graphCutSeed.h
 *
 *  Created on: Apr 3, 2014
 *      Author: prasanna
 */

#ifndef GRAPHCUTSEED_H_
#define GRAPHCUTSEED_H_

#include <opencv2/imgproc/imgproc.hpp>  // Gaussian Blur
#include <opencv2/core/core.hpp>        // Basic OpenCV structures (cv::Mat, Scalar)
#include <opencv2/highgui/highgui.hpp>  // OpenCV window I/O

using namespace cv;

//************************************
// F u n c t i o n     d e c l a r a t i o n s

// Graphcut function
int OnceCutSeedsMaskInput(Mat &, bool*, bool*, bool*, int, int, double, int);

// init all images/vars
int  init(Mat &, bool**, bool**, float, int);

// clear everything before closing
void destroyAll();

// set bin index for each image pixel, store it in binPerPixelImg
void getBinPerPixel(Mat & , Mat & , int, int & );

// compute the variance of image edges between neighbors
void getEdgeVariance(Mat & , Mat & , float & );

//Converts from 1D to 2D array
template <typename T> void convertOneD2TwoDMat(T* inMat, T** outMat, int numRows, int numCols)  {
    for(int colI = 0; colI < numCols; colI++)    {
        for(int rowI = 0; rowI < numRows; rowI++)    {
           outMat[rowI][colI]=inMat[colI*numRows+rowI];
       }
   }
}

//Converts from 2D to 1D array
template <typename T> void convertTwoD2OneDMat(T** inMat, T* outMat, int numRows, int numCols)  {
    for(int colI = 0; colI < numCols; colI++)    {
        for(int rowI = 0; rowI < numRows; rowI++)    {
           outMat[colI*numRows+rowI] = inMat[rowI][colI];
       }
   }
}

#endif /* GRAPHCUTSEED_H_ */
