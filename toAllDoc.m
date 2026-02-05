function [tcDoc_all] = toAllDoc(S)
%TOALLDOC Create tuning curve documents for all cells in session
%
%   TCDOC_ALL = TOALLDOC(S)
%
%   Generates tuning curve documents for each ROI element in the NDI session.
%   Each document contains direction, spatial frequency, and temporal frequency
%   tuning data for one cell.
%
%   Input:
%       S - NDI session or dataset
%
%   Output:
%       tcDoc_all - Cell array of tuning curve documents, one per ROI element
    arguments
        S (1,1) {mustBeA(S,["ndi.session" "ndi.dataset"])}
    end
    e = S.getelements('element.type','roi');
    tcDoc_all = cell(1, numel(e));
    for i = 1:numel(e)
        [tcDoc] = combinedTuningCurve(S,e{i});
        tcDoc_all{i} = tcDoc;
        fprintf('Creating tuning document for cell %d... \n',i);
    end
end