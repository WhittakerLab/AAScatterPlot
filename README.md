# AAScatterPlot v1.5

Made by the Whittaker Lab at Cornell   
Codes written by Donald W Lee  

## Purpose

AAScatterPlot is a tool for looking at aligned nucleotide and amino acid sequences to observe variations in hydropathy index, volume, and charge of residues of a protein.

## Installation

### Option 1) Windows Installation  
1. Run AAScatterPlot_web.exe.  
2. If Windows gives warning about protecting software, allow software to make modification to the system.  
3. Follow installation instructions. It will download the necessary matlab files from the internet.  
4. Find and run the AAScatterPlot application.  

### Option 2) Use in MATLAB (Requires bioinformatics tool box)  
1. Copy all files into a folder in the computer.  
2. Open Matlab.  
3. Search for the folder, right click it, and click on "Add to Path" and then "Selected Folder and Subfolders".  
4. Type "AAScatterPlot" in the command window. It should open the GUI.  
   
## Basic Usage
### Assuming AAScatterPlot is already open  
1. Use "Open Seq File" button to load the fasta file of nucleotide sequences. Note that sequences should begin on reading frame 1.  
2. Ensure that the NTcol and AAcol are correctly referring to their corresponding column numbers.  
3. Use "Go Right" button to start exploring sequence properties. Or set the Start and End position text boxes. Scatter plots should be drawn.   
4. Click on the web logo character to go to that position.  
5. Click on a scatter plot dot to see potential mutations that could be possible.   
6. Click "Plot/Refresh" to plot scatter plot or to refresh plot without any hollow circles.  
7. To save the current scatter plot and web logo, click on "Save Plot" button.  
8. To save ALL plots specified from the Start and End pos, click on "Save Mult Plots" button.  

### In case you need to align sequences  
1. After loading the sequences, click on the "Align Tool" button.  
2. Add the reference sequence into the text box.  
3. Select whether the reference sequence type is NT (nucleotides) or AA (amino acids).  
4. Click on the "Align" button and observe the alignment results.  
5. Click on the "Accept" button. This will bring you back to the AAScatterPlot GUI with the newly aligned sequences.  

