# Raw_Image_Debayer
Script to split a .CR2 raw image into its component colours.  This is particularly useful for Astrophotography, in imaging with a Hydrogen-Alpha filter on a DSLR.

## Prerequisites

GIMP - https://www.gimp.org/downloads/

DCRaw - http://www.centrostudiprogressofotografico.it/en/dcraw/

## Instructions

Install GIMP

Download the Debayer.vbs script

Download DCRaw, place it in the same folder as the Debayer.vbs script

Drag the .CR2 raw image onto the Debayer.vbs script - This will convert the image using DCRaw and create a .bat file

When the script is completed, run the debayer.bat file it creates - This will use GIMP to split the image into four .tiff files

## Settings

DCRaw's documentation can be found at https://www.cybercom.net/~dcoffin/dcraw/dcraw.1.html

By default, the script makes DCRaw do a linear Gamma conversion.  This can be changed by uncommenting a line in the script.

## License

Software is licensed under a [GNU GPL v3 License](https://www.gnu.org/licenses/gpl-3.0.txt)
