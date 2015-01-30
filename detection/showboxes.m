function showboxes(im, boxes, partcolor)
% showboxes(im, boxes)
% Draw boxes on top of image.


if nargin < 3,
  partcolor(1)    = {'r'};
  partcolor(2:1000) = {'b'};
end

%imagesc(im); axis image; axis off;
image(im); axis equal; hold on;

if ~isempty(boxes)
  numparts = floor(size(boxes, 2)/4);
  for i = 1:numparts
    x1 = boxes(:,1+(i-1)*4);
    y1 = boxes(:,2+(i-1)*4);
    x2 = boxes(:,3+(i-1)*4);
    y2 = boxes(:,4+(i-1)*4);
    line([x1 x1 x2 x2 x1]',[y1 y2 y2 y1 y1]','color',partcolor{i},'linewidth',4);
  end
end
drawnow;
set(gca, 'xtick', []);
set(gca, 'ytick', []);
hold off;
