## The files in this directory are split into 3 parts

* Additional files: Contains some 3rd party scripts, libraries, etc.
* Visual_attn_distribution_stats: This directory contains the code that supports the first 3 layers of the scallop recognition pipeline.
* scallop_part2: This directory holds the files that support the 4th layer of the scallop recognition pipeline. 

To read about the 4 layers involved in the scallop recognition process, please refer to the papers below.

Kannappan, P., Walker J. H., Trembanis A. and Tanner, H.G., ”Machine Learning for Detecting scallops in AUV Benthic Images: Targeting False Positives. ”Computer Vision and Pattern Recognition in Environmental Informatics, 22, 2015.

Kannappan, P., Walker J. H., Trembanis A. and Tanner, H.G., ”Identifying sea scallops from benthic camera images. ”Limnology and Oceanography:Methods, vol. 12(10), pp. 680-693, 2014.

## File reference

The 2 entry points for the first 3 layers is the files below. One corresponding to the learning part and the other handles the testing part fot his machine laerning algorithm. 
*Visual_attn_distribution_stats/parallel_main_learning_metadata.m
*Visual_attn_distribution_stats/parallel_main_testing_large2.m

The 4th layer code depends on the results from the first 3 layers. The 4th layer essentially loads mat files from the previous 3 layer results. The entry point for the 4ht layer is the file below.
*scallop_part2/scallop2_main_testing_layer4hog.m: 4th layer HOG descriptor implementation
*scallop_part2/scallop2_main_testing_layer4template.m: 4th layer high-dimensional template matching implementation

## Notes

*Some of the precomputed mat files have been excluded from this repository due the file size limitation imposed by github. The source data and images used for these algorithms have also been excluded from this repository.

*Sorry about the messy version numbers attached to the source files. I wrote them before I was acquainted with version control.

*If you have additional questions please email me at kan.prasanna@gmail.com or raise issues in the github project. I will get to them when I have time.
