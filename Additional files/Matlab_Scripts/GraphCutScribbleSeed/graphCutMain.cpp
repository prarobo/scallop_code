/*
 * graphCutMain.cpp
 *
 *  Created on: Apr 3, 2014
 *      Author: prasanna
 */

#include <iostream>
#include "graphCutSeed.h"
using namespace std;
using namespace cv;

bool checkRect( int *rect, int rows, int cols)	{
	if( rect[0] >= 0 && rect[0] < cols &&
		rect[1] >= 0 && rect[1] < rows &&
		rect[0] + rect[2] < cols && rect[1] + rect[3] < rows )
		return true;
	else
		return false;
}

int main(int argc, char **argv)	{

	//intiialize inputs
	char *imgFileName = "frida_small.jpg";
	bool **backgroundMask, **foregroundMask, **segmentMask;
	float bha_slope = 0.1f;
	int numBinsPerChannel = 64;
	bool *backgroundMask1D, *foregroundMask1D, *segmentMask1D;

	int foregroundRect[4] = {181, 237, 108, 278};
	int backgroundRect[4] = {38, 69, 407, 49};

	Mat currImage, segImage;
	currImage = imread(imgFileName, CV_LOAD_IMAGE_COLOR);

	if(!currImage.data)	{
		cerr<<"Error reading image, quitting"<<endl;
		exit(1);
	}
	cout<<imgFileName<<"\tRows: "<<currImage.rows<< "\tCols: "<<currImage.cols<<endl;
	cout<<"foregroundRect : "<<foregroundRect[0]<<" "<<foregroundRect[1]<<" "<<foregroundRect[2]<<" "<<foregroundRect[3]<<endl;
	cout<<"backgroundRect : "<<backgroundRect[0]<<" "<<backgroundRect[1]<<" "<<backgroundRect[2]<<" "<<backgroundRect[3]<<endl;

	//Initializing image arrays
	backgroundMask = (bool**)calloc(currImage.rows, sizeof(bool*));
	foregroundMask = (bool**)calloc(currImage.rows, sizeof(bool*));
	segmentMask = (bool**)calloc(currImage.rows, sizeof(bool*));

	for (int rowI = 0; rowI < currImage.rows; rowI++)		{
		backgroundMask[rowI] = (bool*) calloc(currImage.cols, sizeof(bool));
		foregroundMask[rowI] = (bool*) calloc(currImage.cols, sizeof(bool));
		segmentMask[rowI] = (bool*) calloc(currImage.cols, sizeof(bool));
	}
	segImage.create(2,currImage.size,CV_8UC1);
	segImage = Scalar(0);

	backgroundMask1D = (bool*)calloc(currImage.rows*currImage.cols, sizeof(bool));
	foregroundMask1D = (bool*)calloc(currImage.rows*currImage.cols, sizeof(bool));
	segmentMask1D = (bool*)calloc(currImage.rows*currImage.cols, sizeof(bool));

	//Checking rectangular inputs consistency
	if (!checkRect(foregroundRect, currImage.rows, currImage.cols))	{
		cerr<<"Invalid foreground rectangle"<<endl;
		exit(1);
	}

	if (!checkRect(backgroundRect, currImage.rows, currImage.cols))	{
		cerr<<"Invalid background rectangle"<<endl;
		exit(1);
	}

	//Creating foreground and background masks
	for (int rowI = 0; rowI < currImage.rows; rowI++ )		{
		for (int colI = 0; colI < currImage.cols; colI++ )	{
			if (rowI >= foregroundRect[1] && rowI <= foregroundRect[1] + foregroundRect[3] &&
				colI >= foregroundRect[0] && colI <= foregroundRect[0] + foregroundRect[2])
				foregroundMask[rowI][colI] = true;
			else
				foregroundMask[rowI][colI] = false;
			if (rowI >= backgroundRect[1] && rowI <= backgroundRect[1] + backgroundRect[3] &&
				colI >= backgroundRect[0] && colI <= backgroundRect[0] + backgroundRect[2])
				backgroundMask[rowI][colI] = true;
			else
				backgroundMask[rowI][colI] = false;
			segmentMask[rowI][colI] = false;
		}
	}

	convertTwoD2OneDMat(foregroundMask, foregroundMask1D, currImage.rows, currImage.cols);
	convertTwoD2OneDMat(backgroundMask, backgroundMask1D, currImage.rows, currImage.cols);
	convertTwoD2OneDMat(segmentMask, segmentMask1D, currImage.rows, currImage.cols);

	//Calling graph cut
	cout<<"Starting graphcut ..."<<endl;
	OnceCutSeedsMaskInput(imgFileName, foregroundMask1D, backgroundMask1D, segmentMask1D,
			currImage.rows, currImage.cols, bha_slope, numBinsPerChannel );
	cout<<"Graphcut done"<<endl;

	//Displaying output
	convertOneD2TwoDMat(segmentMask1D, segmentMask, currImage.rows, currImage.cols);
	for (int rowI = 0; rowI < currImage.rows; rowI++ )		{
		for (int colI = 0; colI < currImage.cols; colI++ )	{
			if(segmentMask[rowI][colI])	{
				segImage.at<uchar>(rowI, colI) = 255;
			}
		}
	}

	namedWindow( "Input Image", CV_WINDOW_AUTOSIZE );
	namedWindow( "Segment Mask", CV_WINDOW_AUTOSIZE );
	imshow( "Input Image", currImage );
	imshow( "Segment Mask", segImage );
	waitKey(0);

	//Cleaning up
	for (int rowI = 0; rowI < currImage.rows; rowI++)		{
		free(backgroundMask[rowI]);
		free(foregroundMask[rowI]);
		free(segmentMask[rowI]);
	}
	free(backgroundMask);
	free(foregroundMask);
	free(segmentMask);
	destroyAllWindows();

	return 0;
}





