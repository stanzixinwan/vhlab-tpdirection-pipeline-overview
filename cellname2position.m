function [x,y] = cellname2position(exppath, cellname)
% CELLNAME2POSITION - get a position of a cellname in a vhlab 2-photon experiment
%
% [X,Y] = CELLNAME2POSITION(EXPPATH, CELLNAME)
%
% Finds the position of a cell with a given CELLNAME in pixels.
%
% Example:
%     % if S is an ndi.session
%     e = S.getelements();
%     [x,y]=cellname2position(S.path,e{100}.name);
%

x = [];
y = [];

 % step 1, find the stack file where the cell resides

 % cell details in vhtwophoton

data = textscan(cellname, 'cell %f ref %s');
index = data{1}(1);
dirname = data{2}{1};

d = dir(fullfile(exppath,'analysis','scratch','*.stack'));

for i=1:numel(d)
    stack = load(fullfile(d(i).folder,d(i).name),'-mat');
    I = find (strcmp({stack.celllist.dirname},dirname) & [stack.celllist.index]==index);
    if ~isempty(I)
        if numel(I) ~= 1
            error(['Too many matches.']);
        end
        x = mean(stack.celllist(I).xi);
        y = mean(stack.celllist(I).yi);
        return;
    end
end

if isempty(x)
    error(['Could not find position for cell ' cellname ' in experiment ' exppath '.']);
end

