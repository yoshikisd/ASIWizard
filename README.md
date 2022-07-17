ASIWizard - Artificial spin ice analysis wizard
=================================================
MATLAB application containing tools to analyze XMCD-PEEM images of artificial spin ice arrays.

This application contains several functions that can be used to analyze artificial spin ice arrays with square, brickwork, and Kagome geometries. By providing the application reference topography images of the ASI vertices, this application can perform automated vertex detection using the Earth Movers Distance and perform subsequent nanomagnet position/magnetization detection as well as map each nanomagnet to points in an ideal Cartesian/hexagonal coordinate system. The application can use this information to output counts of vertex types and produce a corresponding magnetic structure factor image.

This package uses mexopencv functions developed by Dr. Kota Yamaguchi (https://github.com/kyamagu/mexopencv) as well as pre-built OpenCV binaries. Specifically, the files EMD.mexw64 (renamed to cvEMD.mexw64), opencv_core341.dll, and opencv_imgproc341.dll were used to perform vertex detection. For convenience, a copy of these functions have been included in this repository so that this toolbox can be executed without having to compile both OpenCV and MEXOpenCV packages.

The current version of IceScanner is only capable of analyzing XMCD-PEEM images of ASIs. Integration of magnetic force microscopy (MFM) images will be incorporated in the future.

Before starting the analysis, ensure that you have both the asymmetry (XMCD-PEEM) and corresponding single/averaged polarization (XA-PEEM) images. The latter will serve as the topography image from which IceScanner will perform vertex detection on. Also ensure that the images are 32 bit tif files; the magnetic contrast needs to vary between positive and negative values, corresponding to either parallel or antiparallel alignment with the X-ray vector.

Table of contents
=================
  - [Installation/Build](#installationbuild)
  - [Image preprocessing: Vertex detection](#image-preprocessing-vertex-detection)
    - [Step 1: Import images](#step-1-import-images)
    - [Step 2: Thresholding](#step-2-thresholding)
  - [Image processing](#image-processing)
    - [Step 1: Import](#step-1-import)
      - [First-time processing](#first-time-processing)
      - [Reprocessing](#reprocessing)
    - [Step 2: Vertex clean-up](#step-2-vertex-clean-up)
    - [Step 3: Neighbor scan](#step-3-neighbor-scan)
    - [Step 4: Lattice indexing](#step-4-lattice-indexing)
    - [Step 5: Final inspection](#step-5-final-inspection)
    - [Step 6: Post-processing](#step-6-post-processing)
    
Installation/Build
==================
Prerequisite:
- MATLAB version R2020 or R2021a (if you plan on running the mlapp file)
- OpenCV (3.4.1, see details below if you do not want to use the included DLL files/installer)

**OpenCV and mexopencv components**
The vertex detection functionality of this app is based on Dr. Kota Yamaguchi's mexopencv, which uses the final 3.4.1 stable version of OpenCV. Consequently, certain components of OpenCV 3.4.1 need to be present on your computer for this program to function properly. There are a couple of ways to install OpenCV on to your system

- **The simple method:** 
  - If you wish to run the IceScanner application, run the IceScanner and MATLAB Runtime installer (the necessary files are incorporated in the executable). 
  - If you wish to run the MATLAB files, find the opencv_core341.dll and opencv_imgproc341.dll prebuilt binaries located in the "Vertex detection and magnet locator" folder. Make sure that these files remain in the same folder as the vertexDetect_EMD.m function.

- **The "I don't trust the DLL files some random dude on the Internet is providing" method:** The other alternative is to compile OpenCV and MEXOpenCV from scratch. Dr. Yamaguchi provides a guide on how you can install OpenCV on different operating systems (https://github.com/kyamagu/mexopencv/wiki). It takes some time to compile everything (hence why I provided the prebuilt binaries), but you will be able to also use the other mexopencv functions Dr. Yamaguchi has to offer! 

  - **READ THIS CAREFULLY WHEN USING CMAKE:** In Cmake, when you press the "Configure" button for the first time you will be asked to specify the generator for your project (some version of Visual Studio). Make sure you have that exact version of Visual Studio installed or the configure step will fail. At the time of writing this, I used Visual Studio 14 2015 and CMake version 3.7.2 x64.

Image preprocessing: Vertex detection
=====================================

Step 1: Import images
---------------------
a. When opening IceScanner for the first time, you will automatically be directed to the "Import images" step of the vertex detection process as shown in the image below:

![image](https://user-images.githubusercontent.com/37006268/124043639-446eea80-d9c0-11eb-8c72-084b22e2c000.png)

b. To import a new image, first select the "Type" dropdown menu to select the type of ASI you wish to analyze. Currently only square, brickwork, and Kagome can be analyzed (Tetris ASI analysis is being incorportated; you can try it out at your own risk). Then select the "Topography image" button and select the XA-PEEM image file you wish to import. 

The XA-PEEM image, as well as a square ROI, should be shown in the bottom half of the IceScanner UI:

![image](https://user-images.githubusercontent.com/37006268/124043894-eee70d80-d9c0-11eb-84ae-33e19b76c309.png)

c. In order for IceScanner to perform automated detection of vertices in the ASI, we must provide a reference image of a vertex. It should be noted, however, that vertex detection works best if every vertex looks identical to one another (both in terms of geometry and relative intensity). One way that we can "flatten" out the image is to perform a flatfield correction. Adjust the value of the "Flatfield sigma" by entering a value and pressing enter. The bottom half if the IceScanner UI will automatically update with the new flatfield-corrected image. Generally, the smaller you make the sigma value, the "flatter" the image becomes. 

In the image shown below, the flatfield sigma was reduced from 100 to 5.

![image](https://user-images.githubusercontent.com/37006268/124044216-c27fc100-d9c1-11eb-96c3-1441a9733c2a.png)

e. Drag the ROI (blue box) so that the center of the ROI coincides with a vertex. In order to zoom into a region on the image, hover your mouse over the XA-PEEM image until five tool buttons appear on the top-right hand of the image (below the "Next (start EMD) button). Click on the magnifying glass and select a region around the ROI to zoom in. Before dragging the ROI, make sure that you deselect the magnifying glass tool by clicking it once more; the magnifying glass color should change from blue back to gray. 

You may also increase/devrease the size of the square ROI by changing the "ROI edge size". However, you must make sure that the value is ODD. Increasing this value may make the vertex detection more accurate, it also increases the time required to complete the detection. By default this value is set to 35.

In the image shown below, the ROI is positioned on the center of the vertex. Also shown are the five tool buttons below the "Next (start EMD" button.

![image](https://user-images.githubusercontent.com/37006268/124044317-05419900-d9c2-11eb-858b-0c52d24ffa90.png)

f. Once you have set the ROI to the desired location, you can save the reference image by pressing the "Select n-th ref." (either 1st, 2nd, 3rd, ...). Depending on the ASI you choose you may have multiple vertices that possess unique arrangements of the adjacent nanoislands.

- For Square ASI: Only one unique vertex exist and, therefore, only "Select 1st ref" is enabled.
- For Kagome ASI: Two unique vertex appearance exists (magnets arranges as >- and -<). Both "Select 1st ref" and "Select 2nd ref" are enabled. It does not matter which arrangement is used for either reference.
- For Brickwork ASI: Same as Kagome with the exception that the 1st reference MUST look like a "y" (either forward or backward) and the 2nd reference MUST look like a lambda (either forwards or backwards).

The image below shows what the UI looks like after selecting the first reference.

![image](https://user-images.githubusercontent.com/37006268/124048934-49d23200-d9cc-11eb-96d6-66cd9a334260.png)

g. Once the reference images have been select, press the "Next (start EMD)" button. IceScanner will perform two tasks: (1, left image) It will first set things up so that all CPU cores can be utilized to calculate the detection and (2, right image) the calculations will be performed on all accessible cores.

During the first process, MATLAB may ask for you to allow IceScanner to access your network. You may deny this request and things should still work fine.

![image](https://user-images.githubusercontent.com/37006268/124049188-c82ed400-d9cc-11eb-9937-b20d8782ea2c.png)![image](https://user-images.githubusercontent.com/37006268/124049198-ccf38800-d9cc-11eb-8992-65cd02b78278.png)

To further speed up the calculations you may also change the following values (though it is not recommended):
- "Scale (1-0.41)": This value changes how both the ROI and XA-PEEM images are scaled. Downscaling these images means there's less pixels for IceScanners to deal with (and, therefore, speeds up calculations). By default, the value is set to 0.41, which I have found to yield decent computation speed while minimizing garbage detection points. If you do decide to change the scale, you need to make sure that the final rounded width of the reference image is ODD.
- "Skip # of pixels": This value tells IceScanner to skip a certain number of pixels after scanning a given area. In principle, the calculations should speed up by a factor of whatever number you set "Skip # of pixels" to. However, increasing this value will also reduce the ability of IceScanner to properly detect vertices.


Step 2: Thresholding
--------------------
Once the EMD calculation have been completed, IceScanner will move you to the "Thresholding" step window. At this point, IceScanner has internally calculated a surface where each point on the surface corresponds to how dissimilar a region on the XA-PEEM image is compared to the reference vertex. In other words, each minima on that calculated surface corresponds to a potential location of a vertex. At the moment the software is not smart enough to figure out where thise minima are in a robust manner.

What you will need to do is to specify a threshold value. Below this threshold value is where the potential vertex locations are at. To do this is rather straightforward:

a. Change the values of one of the reference thresholds in increments of 0.1-0.5 and watch how many dots appear in the XA-PEEM images. These dots corresponds to potential vertex locations.
- Increasing this value will cause more vertices to pop up. However, increasing this value too much will also result in the acceptance of areas that are not vertices.
- It is normal to see clusters of points around a vertex. These clusters can be reduced into one single point in subsequent processing steps.

b. Continue changing the threshold value until you minimize the amount of garbage detection points while accepting the most amount of vertices.
- In later processing steps you can manually add or delete vertex locations.

The image below shows an example of a manually-optimized threshold for the square ASI. Note that the defective region close to the center does not possess any detected points.

![image](https://user-images.githubusercontent.com/37006268/124050387-56a45500-d9cf-11eb-8727-cb9017d0b514.png)

Once completed, select the "Save results" button to export the pre-processed data as a MAT file.


Image processing
================
To start the image processing wizard, click the "Image processing" tab on the top-left corner of the screen. 

![image](https://user-images.githubusercontent.com/37006268/124056818-45614580-d9db-11eb-9523-e0c483e0735d.png)

Step 1: Import
--------------
### First-time processing:
If this is the first time the ASI images are subjected to this image processing step, continue reading the following instruction. If you are re-processing the images through this step again, go to [Reprocessing](#reprocessing).

a. Since this will be the first time the data is processed through this wizard, leave the dropdown menu option as "No".

b. For the "Detection result file", click the "Browse" button and select the MAT file that was generated by the "Vertex detection wizard/tab".

c. For the "Magnetic image file", click the "Browse" button and select the tif file associated with the magnetic contrast image. This will automatically update the "Analysis window" in the bottom half of the IceScanner UI.
- Optionally, you may perform a simple flatfield correction to the XMCD-PEEM image as well. By default, this adjustment is disabled. To enable flatfield correction, click the "Adjust magnetic contrast" checkbox. You may then change the flatfield sigma value. If you only see a blank gray image, you will need to increase the sigma value. Try increasing by a factor of 10 first, then gradually reduce the value until the desired image correction has been achieved. 

d. Once completed, hit "Next >"

The image below shows the IceScanner UI after steps 1a-1c have been completed.

![image](https://user-images.githubusercontent.com/37006268/124058859-07662080-d9df-11eb-81f3-29da5b2b9051.png)

### Reprocessing:
To reprocess data that have been subjected through the *entire* image processing wizard:

a. Set the dropdown menu option to "Yes".

b. For the "Detection result file", click the "Browse" button and select the MAT file that was generated at the end of the image processing wizard.

c. Press the "Next >" button. You will be directed to the following screen:

![image](https://user-images.githubusercontent.com/37006268/124374493-8f9f2c80-dc50-11eb-923b-e3876ea1151e.png)

d. Select the step you wish to repeat for the analyzed data. At this time, only the [final inspection](#step-5-final-inspection) and [post-processing](#step-6-post-processing) steps can be performed. **If the system is brickwork, ensure that you define the [BrickMode](#step-3-neighbor-scan) (see step 3g).**


Step 2: Vertex clean-up
-----------------------
In this step, we will be cleaning up point clusters surrounding the vertices. We can also manually add/remove vertices into the image in this step.

a. For the textbox adjacent to "Minimum distance between two adjacent vertices (in pixels)", enter the value "15" and press enter. The "Analysis window" will show markers overlain on top of the XA-PEEM image. These markers represent the detected vertex positions. If multiple reference vertices are used, there will be multiple sets of markers with colors/shapes corresponding to whatever reference image those markers are associated with.

b. To remove individual vertices, click the "Select" button on "Select points to remove". A new UI with the same XA-PEEM and overlain markers will pop up. In this window, click next to all points you wish to remove and, once completed, hit the enter key. All vertices within a ~10 pixel diameter away from each point you specify will be deleted.

c. To add vertices, click the "Select" button on the "Select points to add button". A new UI with the same XA-PEEM and overlain markers will pop up.
- For square ASI: Click the location(s) where you wish to insert a new vertex/vertices. Hit the enter key once complete.
- For brickwork and Kagome ASI: Click the location(s) where you wish to insert a new REFERENCE 1 vertex. Hit the enter key once complete. Another XA-PEEM image pop-up will appear. In this new window, click the location(s) where you wish to insert a new REFERENCE 2 vertex. Hit the eneter key once complete.

d. After all the manual vertex position modifications have been performed, select the "Next (clean-up)" button.

The image below shows the IceScanner UI while step 2c is being performed.

![image](https://user-images.githubusercontent.com/37006268/124060347-b6a3f700-d9e1-11eb-8e84-a492f730af4c.png)

Step 3: Neighbor scan
---------------------
To map the vertex positions to an ideal lattice, IceScanner will first attempt to define, for each vertex, the relative locations of all nearest-neighboring vertices. This is done with the use of an area scan whose shape can be altered. The goal is to shape the ROI such that only the nearest-neighboring vertices are enclosed within the ROI area.

a. Keep the "Imaging technique" as "XMCD-PEEM"

b. Preview an individual vertex by providing an arbitraty index value (i.e., 90). The number must be below the total number of vertices in the system.

c. Adjust the area scan parameters 
- For square and brickwork ASI: The ROI is composed of two rectangular ROIs that can be tilted at varying angles relative to one another. Enter the width and height for the rectangular ROIs. By default, entering a height and width value in the "Cross 1" column automatically transfers that same value to "Cross 2". Enter the angle at which the rectangular ROIs are tilted by. By default, entering an angle for "Cross 1" will automatically transfer a 90-degree rotated angle for "Cross 2".
- For Kagome ASI: The ROI is composed of a circle. Enter the width/diameter of the circle.

d. Select "Preview scan area" to preview the ROI in the "Analysis window".

e. Repeat steps 3c-3d until the desired ROI has been acquired.

f. Set "Legacy?" to "No" (this option is used for reading data files generating by old MATLAB code that would eventually turn into IceScanner)

g. If the ASI is brickwork: Look at the XA-PEEM image and pay attention to the empty regions in the array. These empty regions should look like a stacking of bricks (hence the name brickwork). If the bricks generally look like they are tilted like "/", then change "BrickMode" to "/". Otherwise change it to "\".

The image below shows what the UI looks like after selecting "Preview scan area"
![image](https://user-images.githubusercontent.com/37006268/124066832-36d05980-d9ee-11eb-99d5-6b41a2abaa93.png)

h. To begin mapping, press "Perform neighbor detect". IceScanner will begin to map vertex positions and deduce nanomagnet positions and magnetizations. Additionally, the vertex types will also be labeled with different color/shape markers.

Below are a couple of example results when the ROI is able to capture all nearest neighboring vertices (left) and when the ROI is not large enough to capture all neighboring vertices (right).

![image](https://user-images.githubusercontent.com/37006268/124081070-ef52c900-d9ff-11eb-91c0-e12d8e12f8b2.png)![image](https://user-images.githubusercontent.com/37006268/124081194-14473c00-da00-11eb-9e41-b9355d22fd7b.png)

Once complete, press the "Next >" button.

Step 4: Lattice indexing
------------------------
This step will automatically index 2D lattice coordinates to the ASI array.

a. First, press the "Select" button. This will open a pop-up window with the XA-PEEM image overlain with the vertex positions similar to the one in Step 2b and 2c.

b. In the pop-up window, select the center of one nanomagnet residing between two vertices. The choice of nanomagnet depends on what type of ASI system is being analyzed:
- Square and Kagome ASI: Select the center of any magnet (ideally with horizontal orientation)
- Brickwork ASI: Select the center of the magnet that is circled in green with neighbor magnets arranged in the manner shown in the red region in the image below. Note that this may be reversed, depending on what "BrickType" is being analyzed (see step 3g for details on "BrickType").

![image](https://user-images.githubusercontent.com/37006268/124244646-04009100-dad4-11eb-8474-fc44685037cf.png)

c. Once a single nanomagnet has been chosen, press the enter key. The origin of the new 2D coordinate system (0,0) is displayed in the "Analysis window".

The image below shows an example of what IceScanner looks like during step 4b.

![image](https://user-images.githubusercontent.com/37006268/124244976-5c379300-dad4-11eb-916a-49d35cc519ec.png)

d. Once the desired point has been selected, press "Next (start mapping)". IceScanner will automatically assign all nanomagnets a unique 2D coordinate in either a Cartesian (square and brickwork) or hexagonal (Kagome) coordinate system. Once completed, the XA-PEEM image will be overlain with each nanomagnet coordinate. You will need to zoom in to the image to clearly make out the text.

The image below shows an example of what IceScanner looks like after completing the lattice coordinate assignment step and zooming into a region on the XA-PEEM image.

![image](https://user-images.githubusercontent.com/37006268/124245784-2a72fc00-dad5-11eb-806d-5fbb2b123a27.png)

Step 5: Final inspection
------------------------
In this step, you will have the opportunity to manually inspect the image and alter/remove erroneous nanomagnet magnetizations. 

Prior to performing a task, you must select the type of image you wish to use to base your inspection/alterations off of. There are several options that can be used:
- XAS: XA-PEEM topography image
- XMCD: XMCD-PEEM magnetic contrast image
- XMCD (more contrast): XMCD-PEEM image with exaggerated contrast
- Absolute value of XMCD: Takes the absolute value of the XMCD image. Useful for identifying non-single-domain nanoislands, which will usually have a black "stripe" or "stripes" within the nanoisland.
- ROI-Regular: Only shows regions of the XMCD-PEEM image captured within rectangular ROIs that correspond to the individual nanomagnets.
- ROI-Averaged: Similar to ROI-Regular, but only shows the averaged intensity throughout the entire ROI.

There are several magnetization modification options available for use. For each one of these options, a pop-up will appear with the inspection image overlain with nanomagnet magnetizations as well as vertex types. For all cases, click each nanomagnet you wish to perform the specified operation on and hit the enter key once complete. Nanomagnets within ~10 pixels of the specified points will be subjected to the selected operation.
- **Set magnetic moment to zero**: Sets the nanomagnet magnetization to be zero.
- **Mark as a complex spin texture**: Mark the nanomagnet as a complex spin state. These nanomagnets will be treated as non-existent nanomagnets for analyses performed within the Ising framework (e.g., magnetic structure factor, vertex populations). The type of complex spin state is based on the image shown below

![image](https://user-images.githubusercontent.com/37006268/124247736-044e5b80-dad7-11eb-85e2-0a108b9f39cd.png)

- **Remove magnet from analysis**: Treats selected nanomagnet as a non-existent entity. This is different from **Set magnetic moment to zero** in that IceScanner will deliberately **ignore** these nanomagnets. In some cases this is useful to ensure that you do not include certain elements in statistical calculations.
- **Flip spin**: Flips the magnetization by 180 degrees.

After hitting the enter key, the "Analysis window" will automatically update with the inspection image overlain with the updated magnetizations and vertex types. Any marked complex spin textures will also be shown.

**If you wish to undo all modifications performed to the magnetiztaions, press the "Undo all" button**.

The image below shows an example of IceScanner after a modification has been performed

![image](https://user-images.githubusercontent.com/37006268/124249156-74111600-dad8-11eb-9888-662950e33eea.png)

Once complete, press the "Next >" button.

Step 6: Post-processing
-----------------------
In this step you can specify which calculations you want IceScanner to perform to characterize the analyzed ASI image. There are several options available:
- **Magnetic structure factor**: Outputs the magnetic reciprocal space image of the ASI. Calcualtion is based on *Östman, E. et al. Interaction modifiers in artificial spin ices. Nat. Phys. 14, 375–379 (2018)*. Note that the coordinate system used in IceScanner incorporates both vertices and nanoislands within the same system. This, in turn, means that there will always be two lattice points between each adjacent pair of nanomagnets.
  - Steps: Number of increments between the start and stop values.
  - Start: Specify the starting reciprocal lattice unit point.
  - End: Specify the ending reciprocal lattice unit point.
- **Vertex and magnetization detection**
  - Vertex counts: Outputs a bar chart with the total number of vertex types detected.
  - Lattice coordinates: Outputs an XA-PEEM image overlain with the lattice coordinates.
  - Contrast + detected M: Outputs an XMCD-PEEM image overlain with the detected magnetizations
  - Contrast + vertex type: Outputs an XMCD-PEEM image overlain with both detected magnetizations and vertex types.
- **Spin-spin correlator**: Outputs spin-spin correlation calculations
  - Identified neighbors (movie): Outputs a movie showing all assigned n-th nearest neighbor for every nanomagnet.
  - Local correlation map: Outputs images showing the n-th nearest neighbor correlation value for each nanomagnet. *Currently in beta; I would recommend disabling this*.
  - **Correlation definition**: The correlator can be calculated based on different definitions of what constitutes a positive or negative correlation. If you're trying to reproduce correlation values based on a paper, make sure you understand what correlation definition was used for that paper.
    - Dot product: Correlations are calculated as the average of the dot product between two spins: <S_i * S_j>
    - Binary dot product: Similar to the dot product option, but the pair-wise correlation is calculated as follows
      - If <S_i * S_j> > 0, then the correlation is 1
      - If <S_i * S_j> < 0, then the correlation is -1
      - If <S_i * S_j> = 0, then the correlation is 0
    - Binary magnetostatics: Correlations are calculated based on the dipolar interaction energy, E_ij, between two spins defined as follows:
      - If E_ij > 0, then the correlation is -1 (repulsive)
      - If E_ij < 0, then the correlation is 1 (attractive)
      - if E_ij = 0, then the correlation is 0 (neutral)

Check all the desired post-processing options and click "Next (postprocessing)". IceScanner will ask you what directory you wish to save the files to. In addition to the specified post-processing options, IceScanner will also save a MAT file containing all the processed data. This MAT file can be used to re-analyze the data in IceScanner.
