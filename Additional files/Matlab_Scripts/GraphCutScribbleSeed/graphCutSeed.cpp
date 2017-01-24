//Copyright (c) 2014, Lena Gorelick
//All rights reserved.
//
//Redistribution and use in source and binary forms, with or without
//modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright
//      notice, this list of conditions and the following disclaimer in the
//      documentation and/or other materials provided with the distribution.
//    * Neither the name of the University of Western Ontarior nor the
//      names of its contributors may be used to endorse or promote products
//      derived from this software without specific prior written permission.
//
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
//DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//
//THIS SOFTWARE IMPLEMENTS THE OneCut ALGORITHM THAT USES SCRIBBLES AS HARD CONSTRAINTS.
//PLEASE USE THE FOLLOWING CITATION:
//
//@inproceedings{iccv2013onecut,
//	title	= {Grabcut in One Cut},
//	author	= {Tang, Meng and Gorelick, Lena and Veksler, Olga and Boykov, Yuri},
//	booktitle={International Conference on Computer Vision},
//	month	= {December},
//	year	= {2013}}
//
//THIS SOFTWARE USES maxflow/min-cut CODE THAT WAS IMPLEMENTED BY VLADIMIR KOLMOGOROV,
//THAT CAN BE DOWNLOADED FROM http://vision.csd.uwo.ca/code/.
//PLEASE USE THE FOLLOWING CITATION:
//
//@ARTICLE{Boykov01anexperimental,
//    author = {Yuri Boykov and Vladimir Kolmogorov},
//    title = {An Experimental Comparison of Min-Cut/Max-Flow Algorithms for Energy Minimization in Vision},
//    journal = {IEEE TRANSACTIONS ON PATTERN ANALYSIS AND MACHINE INTELLIGENCE},
//    year = {2001},
//    volume = {26},
//    pages = {359--374}}
//
//
//
//THIS SOFTWARE USES OpenCV 2.4.3 THAT CAN BE DOWNLOADED FROM http://opencv.org
//
//
//
//
//
//
//
//
//
//##################################################################
//
//  USAGE  INSTRUCTIONS
//
//	In the command line type:
//
//	OneCut <imageFileName> [<beta> <numBinsPerChannel>]
//
//	Default values: beta= 0.1, numBinsPerChannel=64
//
//	Example: OneCut frida_small.jpg 0.1 64
//	or       OneCut frida_small.jpg
//
//
//	Once the image is opened you can scribble with left and right
//	mouse buttons on the object and the background in the
//	"Scribble Image" window. Once the scribbles are given you can
//	segment the image.You can keep repeatedly adding scribbles and
//	segmenting until the result is satisfactory.
//
//	Use the following Short Keys:
//		'q' - quit
//		's' - segment
//		'r' - reset (removes all strokes and clears all results)
//		'+' - increase brush stroke radius
//		'-' - decrease brush stroke radius
//		'right mouse button drug' - draw blue scribble
//		'left mouse button drug' - draw red scribble
//
//
//##################################################################
// Code edited to fit into scallop project
// Author: Prasanna Kannappan
//##################################################################
//
//  NEW USAGE  INSTRUCTIONS
//
//	In the command line type:
//
//	OneCut <imageFileName> <beta> <numBinsPerChannel> <foreground mask> <background mask>
//
//	Default values: beta= 0.1, numBinsPerChannel=64
//
//	Example: OneCut frida_small.jpg 0.1 64
//	or       OneCut frida_small.jpg

#include <iostream> // for standard I/O
#include <string>   // for strings
#include <iomanip>  // for controlling float print precision
#include <sstream>  // string to number conversion

#include <opencv2/imgproc/imgproc.hpp>  // Gaussian Blur
#include <opencv2/core/core.hpp>        // Basic OpenCV structures (cv::Mat, Scalar)
#include <opencv2/highgui/highgui.hpp>  // OpenCV window I/O

#include "graph.h"
#include "graphCutSeed.h"

using namespace std;
using namespace cv;

// images
Mat inputImg, binPerPixelImg, segMask, showEdgesImg;

// user clicked mouse buttons flags
int numUsedBins = 0;
float varianceSquared = 0;
int scribbleRadius = 10;


// default arguments
//float bha_slope = 0.1f;
//int numBinsPerChannel = 64;


const float INT32_CONST = 1000;
const float HARD_CONSTRAINT_CONST = 1000;


#define NEIGHBORHOOD_8_TYPE 1;
#define NEIGHBORHOOD_25_TYPE 2;

const int NEIGHBORHOOD = NEIGHBORHOOD_8_TYPE;


typedef Graph<int,int,int> GraphType;
GraphType *myGraph;


//***********************************
// M a i n

int OnceCutSeedsMaskInput(Mat & inputImg,
		bool *fgMask, bool *bgMask, bool *sgMask, int numRows, int numCols,
		double bha_slope_double = 0.1, int numBinsPerChannel = 64)
{
	bool **foregroundMask, **backgroundMask, **segmentMask;
	float bha_slope = (float) bha_slope_double;
	foregroundMask = (bool**) calloc(numRows, sizeof(bool*));
	backgroundMask = (bool**) calloc(numRows, sizeof(bool*));
	segmentMask = (bool**) calloc(numRows, sizeof(bool*));
	for (int rowI = 0; rowI < numRows; rowI++ )		{
		foregroundMask[rowI] = (bool*) calloc(numCols, sizeof(bool));
		backgroundMask[rowI] = (bool*) calloc(numCols, sizeof(bool));
		segmentMask[rowI] = (bool*) calloc(numCols, sizeof(bool));
	}
	convertOneD2TwoDMat(fgMask, foregroundMask, numRows, numCols);
	convertOneD2TwoDMat(bgMask, backgroundMask, numRows, numCols);
	convertOneD2TwoDMat(sgMask, segmentMask, numRows, numCols);

	//cout << "Image Filename : "<< imgFileName << endl;
	//cout << "Using " << numBinsPerChannel <<  " bins per channel " << endl;
	//cout << "Using beta  = " << bha_slope << endl;

	if (init(inputImg, foregroundMask, backgroundMask, bha_slope, numBinsPerChannel)==-1)
	{
		cout <<  "Could not initialize" << endl ;
		return -1;
	}


	//cout << "maxflow..." << endl;
	//int flow = myGraph -> maxflow();
	myGraph -> maxflow();
	//cout << "done maxflow..." << endl;

	// this is where we store the results
	segMask = Scalar(0);

	// copy the segmentation results on to the result images
	for (int i = 0; i<inputImg.rows * inputImg.cols; i++)
	{
		// if it is foreground - color blue
		if (myGraph->what_segment((GraphType::node_id)i ) == GraphType::SOURCE)
		{
			segMask.at<uchar>(i/inputImg.cols, i%inputImg.cols) = 255;
			segmentMask[int(i/inputImg.cols)][i%inputImg.cols] = true;
		}
		// if it is background - color red
		else
		{
			segMask.at<uchar>(i/inputImg.cols, i%inputImg.cols) = 0;
            segmentMask[int(i/inputImg.cols)][i%inputImg.cols] = false;
		}
	}


	convertTwoD2OneDMat(segmentMask, sgMask, numRows, numCols);

	destroyAll();

	for (int rowI = 0; rowI < numRows; rowI++ )		{
		free(foregroundMask[rowI]);
		free(backgroundMask[rowI]);
		free(segmentMask[rowI]);
	}
	free(foregroundMask);
	free(backgroundMask);
	free(segmentMask);

	return 0;
}

// clear everything before closing
void destroyAll()
{
	//  destroy all windows
    // 	destroyWindow("Input Image");
    // 	destroyWindow("Scribble Image");
    // 	destroyWindow("Bin Per Pixel");
    // 	destroyWindow("Edges");
    // 	destroyWindow("bg mask");
    // 	destroyWindow("fg mask");
    // 	destroyWindow("Segmentation Mask");
    // 	destroyWindow("Segmentation Image");

	// clear all data
	//inputImg.release();
	showEdgesImg.release();
	binPerPixelImg.release();
	segMask.release();

	delete myGraph;


}

// init all images/vars
int init(Mat & inputImg, bool **foregroundMask, bool **backgroundMask,
		float bha_slope, int numBinsPerChannel)
{
	// Read the file
    //inputImg = imread(imgFileName, CV_LOAD_IMAGE_COLOR);

	// Check for invalid input
    if(!inputImg.data )
    {
        cout <<  "Image is corrupt" <<endl ;
        return -1;
    }

	// this is the mask to keep the user scribbles
	segMask.create(2,inputImg.size,CV_8UC1);
	segMask = Scalar(0);
	showEdgesImg.create(2, inputImg.size, CV_32FC1);
	showEdgesImg = Scalar(0);
	binPerPixelImg.create(2, inputImg.size,CV_32F);


	// get bin index for each image pixel, store it in binPerPixelImg
	getBinPerPixel(binPerPixelImg, inputImg, numBinsPerChannel, numUsedBins);

	// compute the variance of image edges between neighbors
	getEdgeVariance(inputImg, showEdgesImg, varianceSquared);



	myGraph = new GraphType(inputImg.rows * inputImg.cols + numUsedBins,
		 12 * inputImg.rows * inputImg.cols);
	GraphType::node_id currNodeId = myGraph -> add_node((int)inputImg.cols * inputImg.rows + numUsedBins);


	for(int i=0; i<inputImg.rows; i++)
	{
		for(int j=0; j<inputImg.cols; j++)
		{
			// this is the node id for the current pixel
			GraphType::node_id currNodeId = i * inputImg.cols + j;

			// add hard constraints based on scribbles
			if (foregroundMask[i][j] == true)	{
				myGraph->add_tweights(currNodeId,(int)ceil(INT32_CONST * HARD_CONSTRAINT_CONST + 0.5),0);
			}
			else if (backgroundMask[i][j] == true)		{
				myGraph->add_tweights(currNodeId,0,(int)ceil(INT32_CONST * HARD_CONSTRAINT_CONST + 0.5));
			}

			// You can now access the pixel value with cv::Vec3b
			float b = (float)inputImg.at<Vec3b>(i,j)[0];
			float g = (float)inputImg.at<Vec3b>(i,j)[1];
			float r = (float)inputImg.at<Vec3b>(i,j)[2];

			// go over the neighbors
			for (int si = -NEIGHBORHOOD; si <= NEIGHBORHOOD && si + i < inputImg.rows && si + i >= 0 ; si++)
			{
				for (int sj = 0; sj <= NEIGHBORHOOD && sj + j < inputImg.cols; sj++)
				{
					if ((si == 0 && sj == 0) ||
						(si == 1 && sj == 0) ||
						(si == NEIGHBORHOOD && sj == 0))
						continue;

					// this is the node id for the neighbor
					GraphType::node_id nNodeId = (i+si) * inputImg.cols + (j + sj);

					float nb = (float)inputImg.at<Vec3b>(i+si,j+sj)[0];
					float ng = (float)inputImg.at<Vec3b>(i+si,j+sj)[1];
					float nr = (float)inputImg.at<Vec3b>(i+si,j+sj)[2];

					//   ||I_p - I_q||^2  /   2 * sigma^2
					float currEdgeStrength = exp(-((b-nb)*(b-nb) + (g-ng)*(g-ng) + (r-nr)*(r-nr))/(2*varianceSquared));
					float currDist = sqrt((float)si*(float)si + (float)sj*(float)sj);

					// this is the edge between the current two pixels (i,j) and (i+si, j+sj)
					currEdgeStrength = ((float)0.95 * currEdgeStrength + (float)0.05) /currDist;
					myGraph -> add_edge(currNodeId, nNodeId,   (int) ceil(INT32_CONST*currEdgeStrength + 0.5), (int)ceil(INT32_CONST*currEdgeStrength + 0.5));

				}
			}
			// add the edge to the auxiliary node
			int currBin =  (int)binPerPixelImg.at<float>(i,j);

			myGraph -> add_edge(currNodeId, (GraphType::node_id)(currBin + inputImg.rows * inputImg.cols),
							(int) ceil(INT32_CONST*bha_slope+ 0.5), (int)ceil(INT32_CONST*bha_slope + 0.5));
		}

	}

	return 0;
}

// get bin index for each image pixel, store it in binPerPixelImg
void getBinPerPixel(Mat & binPerPixelImg, Mat & inputImg, int numBinsPerChannel, int & numUsedBins)
{
	// this vector is used to through away bins that were not used
	vector<int> occupiedBinNewIdx((int)pow((double)numBinsPerChannel,(double)3),-1);


	// go over the image
	int newBinIdx = 0;
	for(int i=0; i<inputImg.rows; i++)
		for(int j=0; j<inputImg.cols; j++)
		{
			// You can now access the pixel value with cv::Vec3b
			float b = (float)inputImg.at<Vec3b>(i,j)[0];
			float g = (float)inputImg.at<Vec3b>(i,j)[1];
			float r = (float)inputImg.at<Vec3b>(i,j)[2];

			// this is the bin assuming all bins are present
			int bin = (int)(floor(b/256.0 *(float)numBinsPerChannel) + (float)numBinsPerChannel * floor(g/256.0*(float)numBinsPerChannel)
				+ (float)numBinsPerChannel * (float)numBinsPerChannel * floor(r/256.0*(float)numBinsPerChannel));


			// if we haven't seen this bin yet
			if (occupiedBinNewIdx[bin]==-1)
			{
				// mark it seen and assign it a new index
				occupiedBinNewIdx[bin] = newBinIdx;
				newBinIdx ++;
			}
			// if we saw this bin already, it has the new index
			binPerPixelImg.at<float>(i,j) = (float)occupiedBinNewIdx[bin];

        //cout << bin << endl;
		}

		double maxBin;
		minMaxLoc(binPerPixelImg,NULL,&maxBin);
		numUsedBins = (int) maxBin + 1;
		//imshow("Bin Per Pixel", binPerPixelImg/maxBin);

		occupiedBinNewIdx.clear();
		cout << "Num occupied bins:" << numUsedBins<< endl;

}

// compute the variance of image edges between neighbors
void getEdgeVariance(Mat & inputImg, Mat & showEdgesImg, float & varianceSquared)
{


	varianceSquared = 0;
	int counter = 0;
	for(int i=0; i<inputImg.rows; i++)
	{
		for(int j=0; j<inputImg.cols; j++)
		{

			// You can now access the pixel value with cv::Vec3b
			float b = (float)inputImg.at<Vec3b>(i,j)[0];
			float g = (float)inputImg.at<Vec3b>(i,j)[1];
			float r = (float)inputImg.at<Vec3b>(i,j)[2];
			for (int si = -NEIGHBORHOOD; si <= NEIGHBORHOOD && si + i < inputImg.rows && si + i >= 0 ; si++)
			{
				for (int sj = 0; sj <= NEIGHBORHOOD && sj + j < inputImg.cols ; sj++)

				{
					if ((si == 0 && sj == 0) ||
						(si == 1 && sj == 0) ||
						(si == NEIGHBORHOOD && sj == 0))
						continue;

					float nb = (float)inputImg.at<Vec3b>(i+si,j+sj)[0];
					float ng = (float)inputImg.at<Vec3b>(i+si,j+sj)[1];
					float nr = (float)inputImg.at<Vec3b>(i+si,j+sj)[2];

					varianceSquared+= (b-nb)*(b-nb) + (g-ng)*(g-ng) + (r-nr)*(r-nr);
					counter ++;

				}

			}
		}
	}
	varianceSquared/=counter;

	// just for visualization
	for(int i=0; i<inputImg.rows; i++)
	{
		for(int j=0; j<inputImg.cols; j++)
		{


			float edgeStrength = 0;
			// You can now access the pixel value with cv::Vec3b
			float b = (float)inputImg.at<Vec3b>(i,j)[0];
			float g = (float)inputImg.at<Vec3b>(i,j)[1];
			float r = (float)inputImg.at<Vec3b>(i,j)[2];
			for (int si = -NEIGHBORHOOD; si <= NEIGHBORHOOD && si + i < inputImg.rows && si + i >= 0; si++)
			{
				for (int sj = 0; sj <= NEIGHBORHOOD && sj + j < inputImg.cols   ; sj++)
				{
					if ((si == 0 && sj == 0) ||
						(si == 1 && sj == 0) ||
						(si == NEIGHBORHOOD && sj == 0))
						continue;

					float nb = (float)inputImg.at<Vec3b>(i+si,j+sj)[0];
					float ng = (float)inputImg.at<Vec3b>(i+si,j+sj)[1];
					float nr = (float)inputImg.at<Vec3b>(i+si,j+sj)[2];

					//   ||I_p - I_q||^2  /   2 * sigma^2
					float currEdgeStrength = exp(-((b-nb)*(b-nb) + (g-ng)*(g-ng) + (r-nr)*(r-nr))/(2*varianceSquared));
					float currDist = sqrt((float)si*(float)si + (float)sj * (float)sj);


					// this is the edge between the current two pixels (i,j) and (i+si, j+sj)
					edgeStrength = edgeStrength + ((float)0.95 * currEdgeStrength + (float)0.05) /currDist;

				}
			}
			// this is the avg edge strength for pixel (i,j) with its neighbors
			showEdgesImg.at<float>(i,j) = edgeStrength;

		}
	}

	double maxEdge;
	Point maxPoint;
	minMaxLoc(showEdgesImg,NULL,&maxEdge, NULL, &maxPoint);
	//cout << showEdgesImg.at<float>(maxPoint) << endl;
	//imshow("Edges", showEdgesImg/maxEdge);

}

/*
*******************************
Mat myMat(size(3, 3), CV_32FC2);

myMat.ptr<float>(y)[2*x]; // first channel
myMat.ptr<float>(y)[2*x+1]; // second channel
*/
