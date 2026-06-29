/*
This macro is designed to de‑noise and enhance individual 
images from large SEM image sequences acquired with a BSE detector. 
Very large image stacks can only be processed on high‑end computers 
with substantial RAM or in specialized formats that are not yet 
widely supported. Converting and saving each image separately 
circumvents this limitation.

Before starting, it is recommended to assess the overall 
quality of your image sequence. You can do this by opening 
the sequence as a Virtual Stack in Fiji and scrolling through 
it. At this stage, determine the ROI, crop the images to 
reduce their size, and replace any “bad” frames with dummy 
images. You may also normalize the histogram across the sequence.

To perform these steps, use:
Process → Batch → Virtual Stack

Select the destination directory and paste the following 
code into the processing window:
-------------------------
makeRectangle(x, y, width, height);
run("Crop");
run("Enhance Contrast...", "saturated=0.02 normalize process_all use");
-------------------------

This will:

1) Crop all images using a rectangular ROI defined by width 
and height (in pixels), with its top‑left corner at 
coordinates x and y.
2) Normalize the histogram across the entire sequence 
using the stack histogram.
3) Save the modified images into the Output directory.

After completing this step, you may close the virtual stack.

Optimizing Images with the Macro.

Next, you can proceed to optimize the images using this macro.
Optimal filter values should first be tested on a single 
representative image from the sequence. Record the chosen 
parameters and then apply them through the macro dialog.

Adjust the following filters to find the best settings 
for your dataset:
	- Blurring: Experiment with Despeckle (Median Filter) 
	and Gaussian Blur to reduce “pepper” noise and smooth 
	membrane structures.
	- Contrast Enhancement: Tune the parameters of CLAHE 
	and subsequently apply Unsharp Mask.
	- Final Histogram Adjustment: Use Image → Adjust → 
	Brightness/Contrast and record the optimal 
	Min and Max values.

The macro applies all selected filters and modifications 
sequentially (from top to bottom in the dialog window). 
If you wish to change the order of operations or add 
your own, you will need to edit the macro code accordingly.

The default sequence: Despeckle, Gaussian Blur, CLAHE, 
Unsharp Mask, Histogram clipping, 8-bit conversion,
Binning, Scaling.

All applied modifications, along with their parameter values, 
are recorded in a log window. This log is saved as a text 
file together with the processed image sequence, ensuring 
full documentation of all changes.

Version: 1.0
Date: 29/06/2026
Author: Aleksandr Mironov 
Еmail: amj-box@mail.ru
 */

requires("1.54p");
//Dailog for parameters
Dialog.create("BSE image sequence enhancer");
Dialog.setInsets(0, 0, 0);
Dialog.addMessage("Please, test your filters and parameters on the single image first. \nRecord the best working values and apply them below:\n ", 14, "blue");
Dialog.setInsets(0, 0, 0);
Dialog.addDirectory("Input directory:", "Choose directory"); // string 1
Dialog.addDirectory("Output directory:", "Choose directory");//string 2
Dialog.setInsets(0, 20, 0);
Dialog.addCheckbox("Invert LUT", false);// check 1
Dialog.setInsets(0, 20, 0);
Dialog.addMessage("                      Denoising and Blurring", 14, "blue");
Dialog.addCheckbox("Despeckle", true);// check 2
Dialog.addCheckbox("Gaussian Blur:", true);// check 3
Dialog.addNumber("Radius: ", 1.6, 2, 3, "Sigma");//number 1
Dialog.setInsets(10, 20, 0);
Dialog.addMessage("                      Contrast and Brightness", 14, "blue");
Dialog.addCheckbox("CLAHE contrast:", true);//check 4
Dialog.addNumber("blocksize", 255);// number 2
Dialog.addToSameRow();
Dialog.addNumber("histogram bins", 256);// number 3
Dialog.addNumber("maximum slope", 1.3, 2, 3, "  ");// number 4
Dialog.setInsets(15, 20, 0);
Dialog.addCheckbox("Unsharp Mask:", true);// check 5
Dialog.addNumber("Radius", 1.0, 2, 3, "Sigma");//number 5
Dialog.addToSameRow();
Dialog.addNumber("Mask Weight", 0.5, 2, 3, "  ");//number 6
Dialog.setInsets(15, 20, 0);
Dialog.addCheckbox("Adjust Histogram:", false);//check 6
Dialog.addNumber("Min= ", 0);//number 7
Dialog.addToSameRow();
Dialog.addNumber("Max= ", 65535);// number 8
Dialog.setInsets(10, 20, 0);
Dialog.addMessage("                      Binning and Resolution", 14, "blue");
Dialog.addCheckbox("Convert to 8-bit", true);// check 7
Dialog.addCheckbox("Binning:", false);// check 8
Dialog.addNumber("X", 2);//number 9
Dialog.addToSameRow();
Dialog.addNumber("Y", 2);//number 10
Dialog.addChoice("Bin Method", newArray("Average", "Median", "Min", "Max", "Sum"));
Dialog.setInsets(15, 20, 0);
Dialog.addCheckbox("Pixel size:", true);//check 9
Dialog.addNumber("Width", 10);//number 11
Dialog.addToSameRow();
Dialog.addNumber("Height", 10);//number 12
Dialog.addString("Unit", "nm");//string 3
Dialog.show;

//Reading dialog values
InDir = Dialog.getString();// string 1
OutDir = Dialog.getString();// string 2
    if(endsWith(InDir, "Choose directory/")||endsWith(OutDir, "Choose directory/")) {
				if (isOpen("Log")) {
         			selectWindow("Log");
         			run("Close" );
				}
				showMessage("Error!!!", "<html>"
				+"<h1><font color=red>Directory was not chosen!<br>"
				+"Please, start again and choose Correct Directory!</h1>");
    			exit;
    }

Invert = Dialog.getCheckbox();// check 1
Dspkl = Dialog.getCheckbox();// check 2
GBlur = Dialog.getCheckbox();// check 3
Sigma = Dialog.getNumber();// number 1
CLAHE = Dialog.getCheckbox();// check 4
blocksize = Dialog.getNumber();// number 2
histogram_bins = Dialog.getNumber();// number 3
maximum_slope = Dialog.getNumber();// number 4
UnshMask = Dialog.getCheckbox();// check 5
radius = Dialog.getNumber();// number 5
maskW = Dialog.getNumber();// number 6
MinMax = Dialog.getCheckbox();// check 6
Min = Dialog.getNumber();// number 7
Max = Dialog.getNumber();// number 8
bit = Dialog.getCheckbox();// check 7
bin = Dialog.getCheckbox();// check 8
x = Dialog.getNumber();//number 9
y = Dialog.getNumber();// number 10
binMeth = Dialog.getChoice();
voxel = Dialog.getCheckbox();// check 9
pWidth = Dialog.getNumber();// number 11
pHeight = Dialog.getNumber();// number 12
Unit = Dialog.getString();// string 3
parameters = "blocksize=" + blocksize + " histogram=" + histogram_bins + " maximum=" + maximum_slope + " mask=*None* fast_(less_accurate)"; 
imgProp = "channels=1 slices=1 frames=1 pixel_width="+pWidth+" pixel_height="+pHeight+" voxel_depth="+pHeight;

setBatchMode(true);

//Main loop for modifications
list = getFileList(InDir);
for (i=0; i<list.length; i++) {
	showProgress(i, list.length);

		if (endsWith(list[i], ".tif")){
		open(InDir+list[i]);
		
		if (Invert==true)
		run("Invert");
		
		if (Dspkl==true)
		run("Despeckle");

		if (GBlur==true)
		run("Gaussian Blur...", "sigma="+Sigma);
		
		if (CLAHE==true)
		run( "Enhance Local Contrast (CLAHE)", parameters);
		
		if (UnshMask==true)
		run("Unsharp Mask...", "radius="+radius+" mask="+maskW);
			
		if (MinMax==true)
		setMinAndMax(Min, Max);
		
		if (bit==true)
		setOption("ScaleConversions", true);
		run("8-bit");
		
		if (bin==true)
		run("Bin...", "x="+x+" y="+y+" bin="+binMeth);
		
		if (voxel==true)
		Stack.setXUnit(Unit);
		run("Properties...", imgProp);
		
		saveAs("Tiff", OutDir+list[i]+"_enh.tif");
		close();
	}
}

//Logging modifications
name = "Processing log for image sequence";
window = isOpen(name);  
title = "[Processing log for image sequence]";  
if (window == false){   
	run("Text Window...", "name="+ title +"width=80 height=20 menu");  
	setLocation(0, 10);  
	};
print(title, "Processing log for image sequence saved in directory \n"+OutDir+"\n");

if (Invert==true)
print(title, "\n- LUT is inverted\n"); 

if (Dspkl==true)
print(title, "\n- Despeckle (median filter with 3x3 pixels neighbourhood) is applied\n"); 

if (GBlur==true)
print(title, "\n- Gaussian Blur is applied with radius = "+GBlur+"\n"); 
		
if (CLAHE==true)
print(title, "\n- CLAHE contrast filter in fast mode is applied with: \n    blocksize = "+blocksize+"\n    histogram bins = "+histogram_bins+"\n    maximum slope = "+maximum_slope+"\n"); 
		
if (UnshMask==true)
print(title, "\n- Unsharp Mask is applied with: \n     radius = "+radius+"\n     mask weight = "+maskW+"\n");
			
if (MinMax==true)
print(title, "\n- Histogram is clipped using: \nMinimum = "+Min+"\nMaximum = "+Max+"\n"); 
		
if (bit==true)
print(title, "\n- Converted to 8-bit\n"); 
		
if (bin==true)
print(title, "\n- Binned by "+x+" X "+y+" with "+binMeth+" method\n");

if (voxel==true)
print(title, "\n- Pixel size is set to "+pWidth+" X "+pHeight+Unit+"\n"); 
print(title,"\n==========================================\n");

showMessage("Image processing", "<html>"
+"<h1><font color=blue>Processing completed!</h1>");

selectWindow(name);
saveAs("Text", OutDir+name+".txt");
run("Close");
