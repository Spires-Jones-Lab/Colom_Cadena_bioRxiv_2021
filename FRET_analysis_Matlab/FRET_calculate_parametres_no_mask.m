% FRET-AT Calculate Beta parametre
clear all

% Choose image location
srcPath = uigetdir('C:\Users\Usuario','Select the sequence path'); %Images Location
mkdir(srcPath,'\parametres_results');
srcFiles = strcat(srcPath,'\*.tif'); 
srcFiles = dir(srcFiles);
[x,y] = size(srcFiles);
tic

% Input dialog for channels. 6e10 can not be used as name.
prompt = {'Donor', 'FRET', 'Mask', 'DonorMask'};
title = 'Image names for FRET analysis';
definput = {'donor', 'fret', 'psd', 'Dmask'};
answer = inputdlg(prompt,title,[1 50],definput);
Donorpre= answer{1};
fretse= answer{2};
maskchannel= answer{3};% Will be used to define ROIs where FRET will be tested (Synapses segmented).
Dmaskchannel= answer{4};% Will be used to define ROIs where FRET will be tested (Donor pre segmented).

% Prepare the table for results

table (1,:) = horzcat({'Sequence_name'},{'Beta'},{'Donor_mean_intensity'},{'Donor_background'},{'Fret_mean_intensity'},{'Fret_background'});
tablerow = 2;

%% LOAD IMAGES

for Files=1:x 
    
     % (1) Load images.  
            if  strfind(srcFiles(Files).name, Donorpre)~=0
                disp('loading images')
                Dpre = read_stackTiff(strcat(srcPath,'/',srcFiles(Files).name));
                FRET = read_stackTiff(strcat(srcPath,filesep, (char(strrep(srcFiles(Files).name, Donorpre, fretse)))));
                
                
                mask = read_stackTiff(strcat(srcPath,filesep, (char(strrep(srcFiles(Files).name, Donorpre, maskchannel)))));
                mask = mask > 0;
                Dmask = read_stackTiff(strcat(srcPath,filesep, (char(strrep(srcFiles(Files).name, Donorpre, Dmaskchannel)))));
                Dmask = Dmask > 0;
                
            
            
                FileName=(char(strrep(srcFiles(Files).name, Donorpre, '_')));
                FileName=FileName (:,1:end-4);

                
      % (2) Create the masks.      
                disp('creating masks')
              
                SynapticD = logical(Dmask);          
                Background = logical(mask);
                
               
                   for i=1:size (FRET,3)
                   outputFileName = strcat(srcPath,'\parametres_results\', FileName, '_SynapticD.tif');
                   imwrite(uint16(SynapticD(:,:,i)),outputFileName, 'WriteMode', 'append',  'Compression','none');
                   end 
                   for i=1:size (FRET,3)
                   outputFileName = strcat(srcPath,'\parametres_results\', FileName, '_Background.tif');
                   imwrite(uint16(Background(:,:,i)),outputFileName, 'WriteMode', 'append',  'Compression','none');
                   end 
                
       % (3) Calculate Background of Donor and FRET.   
               BKG=bwconncomp(Background, 6);
               BKG.DonorbkgIntensity= regionprops(BKG,Dpre,{'PixelValues', 'PixelIdxList'});
               BKG.FRETbkgIntensity= regionprops(BKG,FRET,{'PixelValues', 'PixelIdxList'});  
               
               % save the mean intensity value of each object (if they are
               % bigger than 1 pixel)
               j=1;
               for i=1:length (BKG.DonorbkgIntensity)
                   if  (length (BKG.DonorbkgIntensity(i).PixelValues(:))>1)
                     BKG.DonorMeanIntensities(j)= mean (BKG.DonorbkgIntensity(i).PixelValues(:));
                     BKG.FRETMeanIntensities(j)= mean (BKG.FRETbkgIntensity(i).PixelValues(:));
                     j=j+1; 
                   end
               end

               % extract the 90th percentile
               BKG.DonorBackground= prctile(BKG.DonorMeanIntensities,90);
               BKG.FRETBackground= prctile(BKG.FRETMeanIntensities,90);
               
            
        % (4) Calculate Crosstalk by correcting images background.
               Beta=bwconncomp(SynapticD, 6);             
               Beta.DonorIntensity= regionprops(Beta,Dpre,{'PixelValues', 'PixelIdxList'});
               Beta.FRETIntensity= regionprops(Beta,FRET,{'PixelValues', 'PixelIdxList'}); 
               
                   % save the mean intensity value of each object (if they are
               % bigger than 1 pixel)
               j=1;
               for i=1:length ( Beta.DonorIntensity)
                   if  (length ( Beta.DonorIntensity(i).PixelValues(:))>1)
                     Beta.DonorMeanIntensities(j)= mean ( Beta.DonorIntensity(i).PixelValues(:));
                     Beta.FRETMeanIntensities(j)= mean (Beta.FRETIntensity(i).PixelValues(:));
                     j=j+1; 
                   end
               end           
               
               Beta.Donorcorrected= Beta.DonorMeanIntensities-BKG.DonorBackground;
               Beta.Donorcorrected (Beta.Donorcorrected<0)=0;

               Beta.FRETcorrected=Beta.FRETMeanIntensities-BKG.FRETBackground;
               Beta.FRETcorrected (Beta.FRETcorrected<0)=0;
               
               Beta.crosstalk=Beta.FRETcorrected./Beta.Donorcorrected;
               Beta.crosstalk ((isnan(Beta.crosstalk))|(Beta.crosstalk>1))=0;
               
               % extract the 90th percentile
               Beta.crosstalk90percentile= prctile(Beta.crosstalk,90);
               
               
               disp('writing Excel files')
               table(tablerow,:)=horzcat({FileName},{Beta.crosstalk90percentile},{mean(Beta.DonorMeanIntensities)}, {BKG.DonorBackground},{mean(Beta.FRETMeanIntensities)},{BKG.FRETBackground});                
               tablerow=tablerow+1;   
       
            end
            
            clear BKG
            clear Beta
end

    disp('saving results')
    results = cell2table (table(1:end,:));
    writetable (results, (strcat(srcPath,[filesep 'parametres_results' filesep 'Beta.xls'])));
    disp('Doner! enjoy ;)')
