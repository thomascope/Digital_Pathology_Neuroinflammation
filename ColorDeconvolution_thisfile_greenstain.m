thisfile = 'NP18-263 7 BA39 Tau CD11c.svs';

addpath(genpath('.'))

openslide_load_library()
openslidePointer = openslide_open(thisfile);

[ARGB] = openslide_read_region_autotrunkate(openslidePointer,22000,22000,1000,1000);
imageRGB = cat(3,ARGB(:,:,2),ARGB(:,:,3),ARGB(:,:,4));

% set of standard values for stain vectors (from python scikit)
% He = [0.65; 0.70; 0.29];
% Eo = [0.07; 0.99; 0.11];
% DAB = [0.27; 0.57; 0.78];

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

% combine stain vectors to deconvolution matrix
HDABtoRGB = [He/norm(He) DAB/norm(DAB) Res/norm(Res)]';
RGBtoHDAB = inv(HDABtoRGB);
    
% separate stains = perform color deconvolution
tic
imageHDAB = SeparateStains(imageRGB, RGBtoHDAB);
toc

% % show images
fig1 = figure();
set(gcf,'color','w');
subplot(2,4,1); imshow(imageRGB); title('Original');
subplot(2,4,2); imshow(imageHDAB(:,:,1),[]); title('Purple');
subplot(2,4,3); imshow(imageHDAB(:,:,2),[]); title('Brown');
subplot(2,4,4); imshow(imageHDAB(:,:,3),[]); title('Residual');

subplot(2,4,5); imshow(imageRGB); title('Original');
subplot(2,4,6); imshow(bwareaopen(imageHDAB(:,:,1)<0.4,100),[]); title('Purple');
subplot(2,4,7); imshow(bwareaopen(imageHDAB(:,:,2)<0.4,100),[]); title('Brown');
subplot(2,4,8); imshow(imageHDAB(:,:,3)<0.4,[]); title('Residual');

%CC = bwconncomp(BW)


% 
% subplot(2,4,5); imhist(rgb2gray(imageRGB)); title('Original');
% subplot(2,4,6); imhist(imageHDAB(:,:,1)); title('Hematoxylin');
% subplot(2,4,7); imhist(imageHDAB(:,:,2)); title('DAB');
% subplot(2,4,8); imhist(imageHDAB(:,:,3)); title('Residual');


% combine stains = restore the original image
% tic
% imageRGB_restored = RecombineStains(imageHDAB, HDABtoRGB);
% toc

% fig2 = figure()
% subplot(2,2,1); imshow(imageRGB); title('Orig');
% subplot(2,2,2); imshow(imageRGB_restored); title('restored');