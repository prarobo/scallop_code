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
#pragma once
#include "graph.h"
#include <opencv2/imgproc/imgproc.hpp>  // Gaussian Blur
#include <opencv2/core/core.hpp>        // Basic OpenCV structures (cv::Mat, Scalar)
#include <opencv2/highgui/highgui.hpp>  // OpenCV window I/O

using namespace std;
using namespace cv;

class segmenter
{
public:
	segmenter(void);
	~segmenter(void);
	// init all images/vars
	int  init(char * imgFileName);
	// clear everything before closing
	void destroyAll();
	// mouse listener
	static void onMouse( int event, int x, int y, int, void* );
	// set bin index for each image pixel, store it in binPerPixelImg
	void getBinPerPixel(Mat & binPerPixelImg, Mat & inputImg, int numBinsPerChannel, int & numUsedBins);
	// compute the variance of image edges between neighbors
	void getEdgeVariance(Mat & inputImg, Mat & showEdgesImg, float & varianceSquared);

	typedef Graph<int,int,int> GraphType;
	GraphType *myGraph;
};

