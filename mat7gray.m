%% Load (rgb)image by user
[fname,path] = uigetfile('*.png', 'Select an image');
fname = strcat(path,fname);
data = imread(fname);   

%% Show original image
figure, imshow(data);
title('Original image');

%% Convert the original image into grayscale image
data_gray = rgb2gray(data);

%% Show grayscale image
figure, imshow(data_gray);
title('Grayscale image');

%% Use a median filter to filter out noise
data_gray = medfilt2(data_gray, [3 3]);

%% Convert the resulting grayscale image into a binary image:
% - Method: adaptive -> method used to binarize image
% - ForegroundPolarity: bright -> indicate that the foreground is brighter
%   than background
% - Sensivity: 0.7 -> Sensitivity factor for adaptive thresholding
%   specified as a value in the range [0 1]. 
%   A high sensitivity value leads to thresholding more pixels as foreground,
%   at the risk of including some background pixels.
data_bw = imbinarize(data_gray, 'adaptive', 'ForegroundPolarity', 'bright', 'Sensitivity', 0.7);

figure, imshow(data_bw), title('Binary image after the segmentation');

% Remove objects containing fewer than 200px
data_bw = bwareaopen(data_bw, 200);

% Show binary image
figure, imshow(data_bw), title('Binary image');

%% Start image blob analysis.
% Find connected components in binary image
bw = bwconncomp(data_bw, 8);

% Get a set of properties for each labeled region:
% - Area: number of pixel in the region
% - BoundingBox: smallest rectangle containing the region, 1*4 vector that
%   contain x and y of upper left corner, width and heigth of rectangle
% - Centroid: center of mass of the region
stats = regionprops(bw, 'Area', 'BoundingBox', 'Centroid');

batot = zeros(1);
bbtot = zeros(1,4);
bctot = zeros(1,2);
HH = zeros(1);
TT = zeros(1);
result = data_gray;

% This is a loop to:
% 1) Bound the objects in a rectangular box
% 2) Find line where calculate the intensity of each pixel
% 3) Find value of the head and the tail
for object = 1:length(stats)
    ba = stats(object).Area;
    bb = stats(object).BoundingBox;
    bc = stats(object).Centroid;
    
    % Save value of ba,bb,bc into different matrix
    batot(object,1) = ba;
    for b = 1:4
        bbtot(object,b) = bb(1,b);
    end
    for c = 1:2
        bctot(object,c) = bc(1,c);
    end 
    %% 1) Bound the object in a rectangular box
    % insertShape(image, shape, position, characteristics, charact_value)
    result = insertShape(result, 'Rectangle', bb, 'Color', 'green', 'LineWidth', 2);
    % insertText(image, position, pos_value, characteristics, charact_value)
    % default -> BoxColor:yellow - FontColor: black
    result = insertText(result, [bb(1,1)-15 bb(1,2)], object, 'BoxOpacity', 1, 'FontSize', 10, 'BoxColor', 'green');
    
    %% 2) Find line where calculate the intensity of each pixel
    larg = bb(1,3);
    lung = bb(1,4);
    x1 = bb(1,1);
    x2 = x1 + larg;   
    y1 = bb(1,2) + (lung/2);
    y2 = y1;    
    x = [x1,x2];
	y = [y1,y2];
    
    %% 3) Find value of the head and the tail
    clear M2 M3
    
    % improfile: get pixel-value along line segment
    [M2] = improfile(data_gray,x,y);
    
    j = 1;
    M3 = zeros(1);
    
    % Get only the pixels with value > 0
    for i = 1:length(M2)
        if M2(i,1) > 0
            M3(j,1) = M2(i,1);
            j=j+1;
        end;
    end;
    
    % Find max value in the matrix M3
    max = 0;
    max2 = 0;
    m_max = 0;
    for m = 1:length(M3)
            max2 = M3(m,1);
            if max2 >= max
                max = max2;
                m_max = m;
            end;
    end;
    
    % Find min value in the matrix M3
    min = 0;
    min2 = 0;
    min3 = 0;
    n_min = 0;
    for n = 1:m_max
            min2 = M3(n,1);
            n1 = n-1;
            if n1 > 0
                min3 = M3(n1,1);
            end;
            if and(min2 < max, min3 > min2)
                min = min2;
                n_min = n;
            end;
    end;
    
    head = m_max - n_min;
    HH(object,1) = head;
    
    tail = length(M3) - m_max;
    TT(object,1) = tail;
    
    % Print single comet and it's tail-value  
    figure, subplot(1,2,1);
    crop = imcrop(data_gray,bb);
    imshow(crop);
    title({['Comet ',num2str(object)],['Image size: ',num2str(larg),'x',num2str(lung)],['Diameter of the head: ',num2str(head), ' pixel'],['Length of the tail: ',num2str(tail),' pixel']});
    
    % Plot the histogram of the intensity along the line-segments
    subplot(1,2,2);
    improfile(data_gray,x,y);
    title(['Histogram ',num2str(object)]);
    xlabel('Length of comet');
    ylabel('Color value');
    
    break;
end
nComet = bw.NumObjects;
figure, imshow(result), title(['Comets found: ',num2str(nComet)]);