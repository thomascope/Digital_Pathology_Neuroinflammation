%function Colourdeconvolution_thesefiles(thisfile,thisfile_2,tform,this_boundary,sfactor)

thisfile = 'F:/Brain paper slide scans/AD/703424.svs'; %Base image
thisfile_2 = 'F:/Brain paper slide scans/AD/703303.svs'; %Neighbouring image

thisfile = 'C:/Users/Thoma/Documents/Neuropath_neuroinflammation/AH JR I BA7 CD68P.svs';
thisfile_2 = 'C:/Users/Thoma/Documents/Neuropath_neuroinflammation/AH JR I BA7 TDP43P.svs';

show_images = 1; %Show images for quality check?

% % alternative set of standard values (HDAB from Fiji)
% He = [ 0.6500286;  0.704031;    0.2860126 ];
% DAB = [ 0.26814753;  0.57031375;  0.77642715];
% Res = [ 0.7110272;   0.42318153; 0.5615672 ]; % residual

%Values from randomly selected slide Qpath
He = [0.625; 0.685; 0.374 ];
DAB = [0.481; 0.603; 0.637  ];
Res = [0.686; -0.711; 0.155];

HDABtoRGB = [He/norm(He) DAB/norm(DAB) Res/norm(Res)]';
RGBtoHDAB = inv(HDABtoRGB);

%tile_size = 2048; % How big a tile to read in at once - trade-off between co-registration error and shearing;
tile_size = 8192; % How big a tile to read in at once - trade-off between co-registration error and shearing;

addpath(genpath('.'))

openslide_load_library()
openslidePointer = openslide_open(thisfile);
openslidePointer_2 = openslide_open(thisfile_2);
file_info = imfinfo(thisfile);
file_info_2 = imfinfo(thisfile_2);

%Transform the boundaries to define area of interest
disp('Transforming the boundaries for the second image')
if numel(this_boundary) ~= 1
    warning(['More than one boundary element found for slide ' thisfile ' please check the raw image'])
end

this_transformed_boundary = zeros(size(this_boundary{1}));
for i = 1:size(this_boundary{1},1)
%[this_transformed_boundary(i,2),this_transformed_boundary(i,1)] = transformPointsForward(tform,this_boundary{1}(i,2),this_boundary{1}(i,1));
[this_transformed_boundary(i,1),this_transformed_boundary(i,2)] = transformPointsForward(tform,this_boundary{1}(i,1),this_boundary{1}(i,2));
end
disp('Done!')

if any(any(this_transformed_boundary<0))
    warning('Some of the transformed boundary is negative, restricting analysis to only overlapping regions')
    [min_x_point,min_y_point] = transformPointsInverse(tform,0,0);
    min_x_point = max(min_x_point*sfactor,0);
    min_y_point = max(min_y_point*sfactor,0);
else
    min_x_point = min(this_boundary{1}(:,2))*sfactor;
    min_y_point = min(this_boundary{1}(:,1))*sfactor;
end

if any(this_transformed_boundary(:,1)*sfactor>file_info_2(1).Height)||any(this_transformed_boundary(:,2)*sfactor>file_info_2(1).Width)
    warning('Some of the transformed boundary is off the end, restricting analysis to only overlapping regions')
    [max_x_point,max_y_point] = transformPointsInverse(tform,file_info_2(1).Width,file_info_2(1).Height);
    max_x_point = min(file_info(1).Width,max_x_point*sfactor);
    max_y_point = min(file_info(1).Height,max_y_point*sfactor);
else
    max_x_point = max(this_boundary{1}(:,2))*sfactor;
    max_y_point = max(this_boundary{1}(:,1))*sfactor;
end

disp('Now loading in and doing colour demomposition in segments')
total_loads = file_info(1).Width*file_info(1).Height/(tile_size^2);
this_load = 0;
proportion_done_prev = 0;
if show_images
    fig1 = figure();
    set(fig1,'color','w');
end
for i = min_x_point:tile_size:max_x_point
    for j = min_y_point:tile_size:max_y_point
        [i_2, j_2] = transformPointsForward(tform,round(i/sfactor),round(j/sfactor));
        i_2 = i_2*sfactor;
        j_2 = j_2*sfactor;
                
        this_load = this_load+1;
        [ARGB] = openslide_read_region_autotrunkate(openslidePointer,i,j,tile_size,tile_size);
        imageRGB = cat(3,ARGB(:,:,2),ARGB(:,:,3),ARGB(:,:,4));
       
        [ARGB] = openslide_read_region_autotrunkate(openslidePointer_2,i_2,j_2,tile_size,tile_size);
        imageRGB_2 = cat(3,ARGB(:,:,2),ARGB(:,:,3),ARGB(:,:,4));
        
        imageHDAB = SeparateStains(imageRGB, RGBtoHDAB);
        imageHDAB_2 = SeparateStains(imageRGB_2, RGBtoHDAB);
        
        % % show images
        if show_images
            subplot(2,4,1); imshow(imageRGB); title('Original');
%             hold on
%             plot(this_boundary{1}*sfactor)
            subplot(2,4,2); imshow(bwareaopen(imageHDAB(:,:,1)<0.4,100),[]); title('Purple');
            subplot(2,4,3); imshow(bwareaopen(imageHDAB(:,:,2)<0.4,100),[]); title('Brown');
            subplot(2,4,4); imshow(imageHDAB(:,:,3)<0.4,[]); title('Residual');
            
            subplot(2,4,5); imshow(imageRGB_2); title('Moved');
%             hold on
%             plot(this_transformed_boundary*sfactor)
            subplot(2,4,6); imshow(bwareaopen(imageHDAB_2(:,:,1)<0.4,100),[]); title('Purple');
            subplot(2,4,7); imshow(bwareaopen(imageHDAB_2(:,:,2)<0.4,100),[]); title('Brown');
            subplot(2,4,8); imshow(imageHDAB_2(:,:,3)<0.4,[]); title('Residual');
            drawnow
        end
        
        
        
        proportion_done = floor(this_load/total_loads*100);
        if proportion_done > proportion_done_prev
            disp(['Computation ' num2str(proportion_done) ' percent complete'])
            proportion_done_prev = proportion_done_prev+1;
        end
    end
end