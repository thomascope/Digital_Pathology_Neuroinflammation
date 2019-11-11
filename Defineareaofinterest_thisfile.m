%function [tform,this_boundary,sfactor] = Defineareaofinterest_thisfile(thisfile,thisfile_2)

thisfile = 'F:/Brain paper slide scans/AD/703424.svs'; %Base image
thisfile_2 = 'F:/Brain paper slide scans/AD/703303.svs'; %Neighbouring image

[~,thisfile_name] = fileparts(thisfile);
[~,thisfile_2_name] = fileparts(thisfile_2);

desired_sfactor = 16; %Check you're loading the image level you think you are.

addpath(genpath('.'))

openslide_load_library()
openslidePointer = openslide_open(thisfile);
openslidePointer_2 = openslide_open(thisfile_2);
file_info = imfinfo(thisfile);

% %Read in and downsample whole image tiled if necessary level not already present
% downsample_factor = 10;
% downsampled_image = zeros(ceil(file_info(1).Width/downsample_factor),ceil(file_info(1).Height/downsample_factor),3);
% downsampled_image = uint8(downsampled_image);
% total_loads = file_info(1).Width*file_info(1).Height/1000000;
% this_load = 0;
% proportion_done_prev = 0;
% for i = 1:1000:file_info(1).Width
%     for j = 1:1000:file_info(1).Height
%         this_load = this_load+1;
%         [ARGB] = openslide_read_region_autotrunkate(openslidePointer,i,j,1000,1000);
%         imageRGB = cat(3,ARGB(:,:,2),ARGB(:,:,3),ARGB(:,:,4));
%         imageRGB_smaller = imresize(imageRGB,1/downsample_factor,'bicubic');
%         downsampled_image(ceil(j/downsample_factor):ceil(j/downsample_factor)+size(imageRGB_smaller,1)-1,ceil(i/downsample_factor):ceil(i/downsample_factor)+size(imageRGB_smaller,2)-1,:) = imageRGB_smaller;
%         proportion_done = floor(this_load/total_loads*100);
%         if proportion_done > proportion_done_prev
%             disp(['downsampling ' num2str(proportion_done) ' percent complete'])
%             proportion_done_prev = proportion_done_prev+1;
%         end
%     end
% end

[ARGB] = openslide_read_region_autotrunkate(openslidePointer,1,1,inf,inf,'level',2);
downsampled_image = cat(3,ARGB(:,:,2),ARGB(:,:,3),ARGB(:,:,4));
[ARGB] = openslide_read_region_autotrunkate(openslidePointer_2,1,1,inf,inf,'level',2);
downsampled_image_2 = cat(3,ARGB(:,:,2),ARGB(:,:,3),ARGB(:,:,4));
clear ARGB

%Check scaling factors
x_sfactor = round(file_info(1).Width/size(downsampled_image,2));
y_sfactor = round(file_info(1).Height/size(downsampled_image,1));
if x_sfactor == desired_sfactor
    if x_sfactor == y_sfactor
        sfactor = x_sfactor;
    else
        error('X and Y scale factors do not match for downsampled image')
    end
else
    error('X scale factors does not match expected scale factor')
end

%Now create the Similarity based 2d transformation matrix between the two images
[optimizer, metric] = imregconfig('multimodal');
tform = imregtform(rgb2gray(downsampled_image_2), rgb2gray(downsampled_image), 'similarity', optimizer, metric,'DisplayOptimization',false);
moved_image = imwarp(downsampled_image_2,tform,'OutputView',imref2d(size(downsampled_image)));

%Optionally check the registration for accuracy
fused_image = imfuse(moved_image,downsampled_image);
figure
imshow(fused_image)

%Now draw a boundary round the section
this_image = imbinarize(downsampled_image); % Binarize the image on all three colour layers
this_image_2 = any(~this_image,3); % Select positive pixels in any colour layer
this_image_expanded = bwdist(this_image_2) <= 1; % Expand the image to allow 'almost connected' cells
cc = bwconncomp(this_image_expanded,4); % Now work out connected clusters
big_cluster = false(1,cc.NumObjects); % This bit rejects 'crud' outside of large areas
for i = 1:cc.NumObjects
    big_cluster(i) = size(cc.PixelIdxList{i},1) > 1000000; % Absolute value for quick first pass, need to improve this for wider applicability
end
grain = cell(0);
for i = 1:cc.NumObjects
    if big_cluster(i)
        grain{end+1} = false(size(this_image_2));
        grain{end}(cc.PixelIdxList{i}) = true; % Now create logical images of each core
    end
end
this_boundary = cell(size(grain));
core_polygon = cell(size(grain));
% Create an outline boundary
for i = 1:size(grain,2)
    clear row col % Now for each core work out a starting point for boundary determination
    for j = 1:size(grain{i},2)
        row = min(find(grain{i}(:,j)));
        if row
            break
        end
    end
    col = j;
    this_boundary{i} = bwtraceboundary(grain{i},[row col],'S'); % Trace the boundary
    core_polygon{i} = polyshape(this_boundary{i}(:,2),this_boundary{i}(:,1));
    mask = ~grain{i}; %Now mask out large areas of white
    mask = bwareaopen(mask, 10000);
    all_donut_boundaries{i} = bwboundaries(mask);
    all_donut_boundaries{i} = all_donut_boundaries{i}(2:end-1); %Exclude the whole area boundary
    for j = 1:size(all_donut_boundaries{i})
    whitespace_polygon{i}{j} = polyshape(all_donut_boundaries{i}{j}(:,2),all_donut_boundaries{i}{j}(:,1));
    end
end

% Optionally show the raw image
staticfig = figure;
imshow(downsampled_image);
hold on;
for i = 1:size(grain,2)
plot(this_boundary{i}(:,2),this_boundary{i}(:,1),'g','LineWidth',1);
% for j = 1:size(all_donut_boundaries{i})
% plot(all_donut_boundaries{i}{j}(:,2),all_donut_boundaries{i}{j}(:,1),'r','LineWidth',1);
% plot(whitespace_polygon{i}{j})
% end
end
saveas(staticfig,['./output_boundaries/' thisfile_name '.jpg'],'jpg');

% Optionally show the moved image with boundary created from raw image
movedfig = figure;
imshow(moved_image);
hold on;
for i = 1:size(grain,2)
plot(this_boundary{i}(:,2),this_boundary{i}(:,1),'g','LineWidth',1);
% for j = 1:size(all_donut_boundaries{i})
% plot(all_donut_boundaries{i}{j}(:,2),all_donut_boundaries{i}{j}(:,1),'r','LineWidth',1);
% plot(whitespace_polygon{i}{j})
% end
end
saveas(movedfig,['./output_boundaries/' thisfile_2_name '_moved.jpg'],'jpg');

if numel(this_boundary) ~= 1
    warning(['More than one boundary element found for slide ' thisfile ' please check the raw image'])
end    

%Now remove white space areas from within sulci
% Not implemented yet - would be more useful for double stained images, but
% we do not have these. Registration not sufficient for this to be safe to apply to single stained
% slices.
