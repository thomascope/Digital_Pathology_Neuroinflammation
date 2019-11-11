% color deconvolution project by Jakob Nikolas Kather, 2015
% contact: www.kather.me

% initialize
format compact, close all, clear all, clc;

% specify source image
% this image is from www.proteinatlas.com, used in accordance with the license
% found under http://www.proteinatlas.org/about/datausage
%imageURL = 'http://www.proteinatlas.org/images/20416/45828_A_4_7_rna_selected.jpg';
imageURL = 'Tumor_CD31_HiRes.png';
imageRGB = imread(imageURL);

% set of standard values for stain vectors (from python scikit)
% He = [0.65; 0.70; 0.29];
% Eo = [0.07; 0.99; 0.11];
% DAB = [0.27; 0.57; 0.78];

% alternative set of standard values (HDAB from Fiji)
He = [ 0.6500286;  0.704031;    0.2860126 ];
DAB = [ 0.26814753;  0.57031375;  0.77642715];
Res = [ 0.7110272;   0.42318153; 0.5615672 ]; % residual

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
subplot(2,4,2); imshow(imageHDAB(:,:,1),[]); title('Hematoxylin');
subplot(2,4,3); imshow(imageHDAB(:,:,2),[]); title('DAB');
subplot(2,4,4); imshow(imageHDAB(:,:,3),[]); title('Residual');

subplot(2,4,5); imhist(rgb2gray(imageRGB)); title('Original');
subplot(2,4,6); imhist(imageHDAB(:,:,1)); title('Hematoxylin');
subplot(2,4,7); imhist(imageHDAB(:,:,2)); title('DAB');
subplot(2,4,8); imhist(imageHDAB(:,:,3)); title('Residual');


% combine stains = restore the original image
% tic
% imageRGB_restored = RecombineStains(imageHDAB, HDABtoRGB);
% toc

% fig2 = figure()
% subplot(2,2,1); imshow(imageRGB); title('Orig');
% subplot(2,2,2); imshow(imageRGB_restored); title('restored');