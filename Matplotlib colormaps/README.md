# Matplotlib_colormaps_in_MS_PAL
Perceptually uniform sequential colormaps from matplotlib converted to the Microsoft PAL format.

This repository contains the lastest colourmaps featured in [Matplotlib 2.0+](https://matplotlib.org/) in Microsoft PAL binary format. 
The .pal binaries are compatible with Origin and Gimp. 

The colormaps included are:
* inferno
* magma
* plasma
* viridis

![colormaps](https://user-images.githubusercontent.com/17439476/31167756-112bed1c-a8eb-11e7-8176-1928ad3565d0.PNG)

### Directory structure
    .
    ├── MS_PAL              # Microsoft .pal files
    ├── MATLAB              # Matlab colormaps and scripts used to generate .pal files/run demo
    └── README.md


### More info
For more information on these colour maps and their development, check out [this site](https://bids.github.io/colormap/) and the video below.

[![IMAGE NOT FOUND](https://img.youtube.com/vi/xAoljeRJ3lU/0.jpg)](https://www.youtube.com/watch?v=xAoljeRJ3lU "A Better Default Colormap for Matplotlib | SciPy 2015 | Nathaniel Smith and Stéfan van der Walt")

## Credits
* cmap2pal.m - [Marcelo Alcocer](https://uk.mathworks.com/matlabcentral/fileexchange/43114-cmap2pal-convert-matlab-colormap-to-binary-pal-format)
* demo1.m - [Ander Biguri](https://uk.mathworks.com/matlabcentral/fileexchange/51986-perceptually-uniform-colormaps)
