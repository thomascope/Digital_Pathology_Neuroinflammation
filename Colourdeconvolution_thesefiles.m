%function Colourdeconvolution_thesefiles(thisfile,thisfile_2,tform,this_boundary,sfactor)

thisfile = 'F:/Brain paper slide scans/AD/703424.svs'; %Base image
thisfile_2 = 'F:/Brain paper slide scans/AD/703303.svs'; %Neighbouring image

% alternative set of standard values (HDAB from Fiji)
He = [ 0.6500286;  0.704031;    0.2860126 ];
DAB = [ 0.26814753;  0.57031375;  0.77642715];
Res = [ 0.7110272;   0.42318153; 0.5615672 ]; % residual

% Test values from Qupath
GreenBG = [0.683; 0.48; 0.55];
Purple = [0.594; 0.665; 0.454];
Brown = [0.499; 0.585; 0.639];

He = Purple;
DAB = Brown;
Res = GreenBG;

tile_size = 12800; % How big a tile to read in at once - should be defined by available RAM;

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
[this_transformed_boundary(i,2),this_transformed_boundary(i,1)] = transformPointsInverse(tform,this_boundary{1}(i,2),this_boundary{1}(i,1));
end
disp('Done!')

if any(any(this_transformed_boundary<0))
    warning('Some of the transformed boundary is negative, restricting analysis to only overlapping regions')
    [min_x_point,min_y_point] = transformPointsForward(tform,0,0);
    min_x_point = min_x_point*sfactor;
    min_y_point = min_y_point*sfactor;
else
    min_x_point = min(this_boundary{1}(:,2))*sfactor;
    min_y_point = min(this_boundary{1}(:,1))*sfactor;
end

if any(this_transformed_boundary(:,1)*sfactor>file_info_2(1).Height)||any(this_transformed_boundary(:,2)*sfactor>file_info_2(1).Width)
    warning('Some of the transformed boundary is off the end, restricting analysis to only overlapping regions')
    [max_x_point,max_y_point] = transformPointsForward(tform,file_info_2(1).Width,file_info_2(1).Height);
    max_x_point = max_x_point*sfactor;
    max_y_point = max_y_point*sfactor;
else
    max_x_point = max(this_boundary{1}(:,2))*sfactor;
    max_y_point = max(this_boundary{1}(:,1))*sfactor;
end

disp('Now loading in and doing colour demomposition in segments')
total_loads = file_info(1).Width*file_info(1).Height/(tile_size^2);
this_load = 0;
proportion_done_prev = 0;
for i = min_x_point:tile_size:max_x_point
    for j = min_y_point:tile_size:max_y_point
        [i_2, j_2] = transformPointsInverse(tform,i,j);
                
        this_load = this_load+1;
        [ARGB] = openslide_read_region_autotrunkate(openslidePointer,i,j,tile_size,tile_size);
        imageRGB = cat(3,ARGB(:,:,2),ARGB(:,:,3),ARGB(:,:,4));
       
        [ARGB] = openslide_read_region_autotrunkate(openslidePointer_2,i_2,j_2,tile_size,tile_size);
        imageRGB_2 = cat(3,ARGB(:,:,2),ARGB(:,:,3),ARGB(:,:,4));
        
        
        
        
        
        
        proportion_done = floor(this_load/total_loads*100);
        if proportion_done > proportion_done_prev
            disp(['Computation ' num2str(proportion_done) ' percent complete'])
            proportion_done_prev = proportion_done_prev+1;
        end
    end
end