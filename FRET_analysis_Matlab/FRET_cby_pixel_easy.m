
function FRET_cby_pixel_easy()

%%----------------------------------------------------------------------------------------------------------------------------
% Images needed:
%    - Donor raw image
%    - Acceptor raw image
%    - fret raw image
%    - Donor segmented image
%    - Acceptor segmented image
%    - Another channel to use as ROI (i.e. synaptic channel segmented)
    
% read_stackTiff.m script should be in the same folder

%%------------------------------------------------------------------------------------------------------------------------------

    clear all

% Choose image location
    srcPath = uigetdir('C:\Users\Usuario','Select the sequence path'); %Images Location
    mkdir(srcPath,'\Fret_Results');
    srcFiles = strcat(srcPath,'\*.tif'); 
    srcFiles = dir(srcFiles);
    [x,y] = size(srcFiles);
    tic

% Input dialog for channels. 6e10 can not be used as name.
    prompt = {'Donor raw', 'FRET raw', 'Acceptor raw', 'ROI Mask', 'Donor Mask', 'Acceptor Mask'};
    title = 'Image names for FRET analysis';
    definput = {'donor', 'frettmem', 'acceptor', 'psd', 'abeta', 'tmem97'};
    answer = inputdlg(prompt,title,[1 50],definput);
    Donor= answer{1};
    Fret= answer{2};
    Acceptor= answer{3};
    maskchannel= answer{4};% Will be used to define ROIs where FRET will be tested (Synapses segmented).
    Dmaskchannel= answer{5};% Will be used to define ROIs where FRET will be tested (Donor segmented).
    Amaskchannel= answer{6};% Will be used to define ROIs where FRET will be tested (Acceptor segmented).

% Prepare the table for results
    table (1,:) = horzcat({'Sequence_name'},{'possible_fret Total objects'}, {'possible_fret % Positive'});
    tablerow = 2;

% Perform the analysis
for Files=1:x 
    
        % (1) Load images.         
            if  strfind(srcFiles(Files).name, Donor)~=0
                disp('loading images')
                donor = read_stackTiff(strcat(srcPath,'/',srcFiles(Files).name));
                fret = read_stackTiff(strcat(srcPath,filesep, (char(strrep(srcFiles(Files).name, Donor, Fret)))));
                acceptor = read_stackTiff(strcat(srcPath,filesep, (char(strrep(srcFiles(Files).name, Donor, Acceptor)))));
                
                mask = read_stackTiff(strcat(srcPath,filesep, (char(strrep(srcFiles(Files).name, Donor, maskchannel)))));
                mask = mask > 0;
                Dmask = read_stackTiff(strcat(srcPath,filesep, (char(strrep(srcFiles(Files).name, Donor, Dmaskchannel)))));
                Dmask = Dmask > 0;
                Amask = read_stackTiff(strcat(srcPath,filesep, (char(strrep(srcFiles(Files).name, Donor, Amaskchannel)))));
                Amask = Amask > 0;
            
            
                FileName=(char(strrep(srcFiles(Files).name, Donor, '_')));
                FileName=FileName (:,1:end-4);

               
        %% (2) Create the masks:
                disp('creating masks')

                SynapticA = logical (Amask.*mask);           
                SynapticD = logical (Dmask.*mask); 
                
                PossibleFret = logical (SynapticA.*SynapticD);
%                 Acceptor_Only = imsubtract(SynapticA, PossibleFret); 
%                 Donor_Only = imsubtract(SynapticD, PossibleFret); 
%                 
%                 Mask_withoutAcceptor = imsubtract(logical(mask), logical(Acceptor_Only)); 
%                 Mask_Only = imsubtract(logical(Mask_withoutAcceptor), logical (Donor_Only));
                

        %% (3) Backfround and crosstalk correction
                disp('background, direct excitation and crosstalk correction')
                
             % Background subtraction (only in fret channel?)
               BKG=bwconncomp(mask, 6);
               BKG.FRETbkgIntensity= regionprops(BKG,fret,{'PixelValues', 'PixelIdxList'});  
               
               % save the mean intensity value of each object (if they are
               % bigger than 1 pixel)
               j=1;
               for i=1:length (BKG.FRETbkgIntensity)
                   if  (length (BKG.FRETbkgIntensity(i).PixelValues(:))>1)
                     BKG.FRETMeanIntensities(j)= mean (BKG.FRETbkgIntensity(i).PixelValues(:));
                     j=j+1; 
                   end
               end

               % extract the 90th percentile
               Background_value = prctile(BKG.FRETMeanIntensities,90); 
               FRETwithoutBackground = fret(:,:,:)-Background_value;
               
             % Fret image crosstalk and direct excitation correction (beta and gamma calculated in each study)
                FRETcorrected = double(FRETwithoutBackground(:,:,:))-(double(donor(:,:,:))*0.3)-(double(acceptor(:,:,:))*0.3);
                FRETcorrected (FRETcorrected<0)=0;


      %% (4) Analysis
               
            % 4- Pixel possible            
               % Extract the regions from the fret raw image
               pixel_possible = bwconncomp(PossibleFret, 6);
               pixel_possible.fret = regionprops(pixel_possible,FRETcorrected,{'PixelValues', 'PixelIdxList'});
               pixel_possible.donor = regionprops(pixel_possible,donor,{'PixelValues', 'PixelIdxList'});
               pixel_possible.mask = regionprops(pixel_possible,mask,{'PixelValues', 'PixelIdxList'});
               pixel_possible.acceptor = regionprops(pixel_possible,acceptor,{'PixelValues', 'PixelIdxList'});
               
               % save the mean intensity value of each object (if they are bigger than 1 pixel)
               j=0;
               jj=0;
               pixel_possible.TotalObjects = 0;
               pixel_possible.PositiveObjects = 0;
               
               for i=1:pixel_possible.NumObjects
                    if (sum(pixel_possible.mask(i).PixelValues(:)>254)<1) && (sum(pixel_possible.donor(i).PixelValues(:)>254)<1)&& (sum(pixel_possible.acceptor(i).PixelValues(:)>254)<1)
                    pixel_possible.TotalObjects = (length (pixel_possible.fret(i).PixelValues(:))) + jj;
                    jj=pixel_possible.TotalObjects;
                    pixel_possible.PositiveObjects = (sum(pixel_possible.fret(i).PixelValues(:)>0)) + j;
                    j=pixel_possible.PositiveObjects; 
                    end   
               end
               
               
               
            %% (4) Saving results
            disp('writing Excel files')
            table(tablerow,:)=horzcat({FileName},{pixel_possible.TotalObjects}, {pixel_possible.PositiveObjects/pixel_possible.TotalObjects*100});                
            tablerow=tablerow+1;
           
            disp('saving results')
            results = cell2table (table(1:end,:));
            writetable (results, (strcat(srcPath,[filesep 'Fret_Results' filesep 'Fret_results.xls'])));
   
            
            end
    
clear pixel_possible
clear BKG
                  
end
 disp('Done! enjoy ;)')
    
       
       