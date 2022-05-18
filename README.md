# cudaImageSharpener
Targa sharpener. Uses NVIDIA CUDA

Just a lab work for uni. Accepts 2 parameters (in and out files), and float a. Also gpu executable asks number of GPU blocks and block size.
Input files should be 24-bit colors .tga (Image type 2) or 8-bit monochrome (Image type 3).
Highly desireable for them to have header bit set for left-to-right up-to-bottom data direction.
