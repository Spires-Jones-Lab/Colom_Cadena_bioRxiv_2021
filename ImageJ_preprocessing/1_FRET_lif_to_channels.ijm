



setBatchMode(true); 

 input = getDirectory("Choose a Directory");
  fileList = getFileList(input);

  for (i=0; i<fileList.length; i++){
    if (endsWith(fileList[i], ".lif")) {                        

run("Bio-Formats Importer", "open=[" + input + fileList[i] + "] color_mode=Grayscale split_channels open_all_series rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT SelectAll");

name=getInfo("image.filename");

output = input+"Stacks"+File.separator;
File.makeDirectory(output);


run("Images to Stack", "method=[Copy (center)] name=syph title=[C=0] use");  
selectWindow("syph");
saveAs("Tiff", output + ""+name+"_syph");

run("Images to Stack", "method=[Copy (center)] name=psd title=[C=1] use");  
selectWindow("psd");
saveAs("Tiff", output + ""+name+"_psd");

run("Images to Stack", "method=[Copy (center)] name=fretpsd title=[C=2] use");  
selectWindow("fretpsd");
saveAs("Tiff", output + ""+name+"_fretpsd");

run("Images to Stack", "method=[Copy (center)] name=abeta title=[C=3] use");  
selectWindow("abeta");
saveAs("Tiff", output + ""+name+"_abeta");

run("Images to Stack", "method=[Copy (center)] name=frettmem title=[C=4] use");  
selectWindow("frettmem");
saveAs("Tiff", output + ""+name+"_frettmem");

run("Images to Stack", "method=[Copy (center)] name=prp title=[C=5] use");  
selectWindow("prp");
saveAs("Tiff", output + ""+name+"_tmem97");


        
run("Close All");

 } // end if endsWith nd2
  } // end for loop