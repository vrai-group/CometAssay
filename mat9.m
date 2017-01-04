%% Load (rgb)image by user
[fname,path] = uigetfile('.bmp', 'Select an image');
fname = strcat(path,fname);
[data,map] = imread(fname);  

figure, imshow(data), title('Original image');

%% Looking for some info about the image
infodata = imfinfo(fname);
switch infodata.ColorType
    case 'indexed'
        rgbImage = ind2rgb(data,map);
        rgbImage = uint8(255 * rgbImage);
        grayImage = rgb2gray(rgbImage);
    case 'truecolor'
        rgbImage = data;
        grayImage = rgb2gray(rgbImage);
    case 'grayscale'
        grayImage = data;
end

%% Use a median filter to filter out noise
grayImage = medfilt2(grayImage, [3 3]);
figure, imshow(grayImage), title('Grayscale image');

%% Convert the resulting grayscale image into a binary image:
% - Method: adaptive -> method used to binarize image
% - ForegroundPolarity: bright -> indicate that the foreground is brighter
%   than background
% - Sensivity: 0.1 -> Sensitivity factor for adaptive thresholding
%   specified as a value in the range [0 1]. 
%   A high sensitivity value leads to thresholding more pixels as foreground,
%   at the risk of including some background pixels.
bwImage = imbinarize(grayImage, 'adaptive', 'ForegroundPolarity', 'bright', 'Sensitivity', 0.1);

% Remove objects smaller than 500px and greather 5000px
bwImage = xor(bwareaopen(bwImage,400), bwareaopen(bwImage,5000));
figure, imshow(bwImage), title('Binary image');

ans1 = 'Yes';
while (strcmpi(ans1, 'Yes'))
    msg1 = sprintf('Do you want to remove wrong objects?');
    ans1 = questdlg(msg1, 'Answer', 'Yes', 'No', 'Yes');
    if strcmpi(ans1, 'Yes')
        msg2 = sprintf('Remove objects smaller than ... pixel');
        ans2 = inputdlg(msg2, 'Input', 1, {'500'});
        bwImage = xor(bwareaopen(bwImage,str2double(ans2)), bwareaopen(bwImage,5000));
        imshow(bwImage), title('Binary image');
    end
end

% Find connected components in binary image
bw = bwconncomp(bwImage, 8);
numObjects = bw.NumObjects;

% Find heads of good comets
% imfindcircles to find 
% viscircles to draw
[centers, radii] = imfindcircles(bwImage,[10 30]);
% h = viscircles(centers,radii,'Color','b'); 
numCircles = length(centers);

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
TST = zeros(1);
result = grayImage;

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

    % Find line where calculate the intensity of each pixel
    larg = bb(1,3);
    lung = bb(1,4);
    x1 = bb(1,1);
    x2 = x1 + larg;   
    y1 = bb(1,2) + (lung/2);
    y2 = y1;    
    x = [x1,x2];
    y = [y1,y2];
   
    %% Find value of the head and the tail
    clear M2 M3

    % improfile: get pixel-value along line segment
    [M2] = improfile(grayImage,x,y);
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
    
    % Test validità cometa
    test = 0;
    for cent = 1:numCircles
        diff1 = bc(1,1) - centers(cent,1);
        diff2 = bc(1,2) - centers(cent,2);
        if (diff1 > 2 || diff1 < -2 || diff2 > 2 || diff2 < -2) && test == 0
            test = 0;
        else
            test = 1;
        end
    end
    TST(object,1) = test;
        
    if test == 0 %Comet error
        head = m_max - n_min;
        HH(object,1) = head;

        tail = length(M3) - m_max;
        TT(object,1) = tail;
        
        result = insertText(result, [bb(1,1)-15 bb(1,2)], object, 'BoxOpacity', 1, 'FontSize', 10, 'BoxColor', 'red');
        result = insertShape(result, 'Rectangle', bb, 'Color', 'red', 'LineWidth', 2);
    else %Comet good
        head = radii(object) * 2;
        HH(object,1) = head;

        tail = length(M3) - m_max;
        TT(object,1) = tail;
        
        result = insertText(result, [bb(1,1)-15 bb(1,2)], object, 'BoxOpacity', 1, 'FontSize', 10, 'BoxColor', 'green');
        result = insertShape(result, 'Rectangle', bb, 'Color', 'green', 'LineWidth', 2);
    end    

    % Print single comet and it's tail-value  
    figure, subplot(1,2,1);
    crop = imcrop(grayImage,bb);
    imshow(crop);
    title({['Comet ',num2str(object)],['Image size: ',num2str(larg),'x',num2str(lung)],['Diameter of the head: ',num2str(head), ' pixel'],['Length of the tail: ',num2str(tail),' pixel']});
    
    % Plot the histogram of the intensity along the line-segments
    subplot(1,2,2);
    improfile(grayImage,x,y);
    title(['Histogram ',num2str(object)]);
    xlabel('Length of comet');
    ylabel('Color value');

end
figure, imshow(result), title(['Comets found: ',num2str(numObjects)]);