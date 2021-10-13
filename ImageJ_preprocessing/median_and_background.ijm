//Get all the stacks in the same folder.
//Only stacks in the folder.
//Stack names without tabulations.

input = getDirectory("Choose stack folder");

setBatchMode(true); 
list = getFileList(input);
for (i = 0; i < list.length; i++)
        action(input, list[i]);
setBatchMode(false);


function action(input, filename) {
        open(input + filename);
name=getInfo("image.filename");

output = input+"median_and_background"+File.separator;
File.makeDirectory(output);


	run("Median...", "radius=1 stack");
    run("Subtract Background...", "rolling=10 stack");

	saveAs("Tiff", output + ""+name+"");
        
close();



}




