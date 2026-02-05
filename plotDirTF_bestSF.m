function [best_stimid, best_SF, plot] = plotDirTF_bestSF(tcDoc, options)
% PLOTDIRTF_BESTSF Plots mean responses at the best Spatial Frequency

arguments
    tcDoc (1,1) ndi.document
    options.colorMin (1,1) double = NaN;
    options.colorMax (1,1) double = NaN;
end

    tc = tcDoc.document_properties.stimulus_tuningcurve;
    [directions,~,~] = unique(tc.independent_variable_value(:,1),'sorted');
    [spatialFrequencies,~,~] = unique(tc.independent_variable_value(:,2),'sorted');
    [temporalFrequencies,~,~] = unique(tc.independent_variable_value(:,3),'sorted');

    

    % Finds best SF
    [~,I] = max(tc.response_mean); % finds the index of the largest mean response
    best_stimid = tc.stimid(I);
    best_SF = tc.independent_variable_value(I,2);

    % Determine SF of which the slices are to be plotted
    SF_toBePlotted = spatialFrequencies;

    for s = 1:numel(SF_toBePlotted)
        % Constructs a matrix for SURF
        [TF, Dir] = meshgrid(temporalFrequencies, directions);
        responses_DirTF_bestSF = nan(numel(directions), numel(temporalFrequencies));    
        for i = 1:numel(tc.stimid(:,1))
            if tc.independent_variable_value(i,2) == SF_toBePlotted(s)
                for d = 1:numel(directions)
                    if tc.independent_variable_value(i,1) == directions(d)
                        for t = 1:numel(temporalFrequencies)
                            if tc.independent_variable_value(i,3) == temporalFrequencies(t)
                                responses_DirTF_bestSF(d,t) = tc.response_mean(i,1);
                            end
                        end
                    end
                end
            end
        end
        % Plot
        Dir = [[Dir Dir(:,1)]; 360*ones(1, 1+size(Dir,2))];
        TF = [TF;TF(1,:)];
        TF = [TF TF(:,size(TF,2))+3];
        plot = surf(Dir, TF, pcolordummyrowcolumn(responses_DirTF_bestSF));
        xlabel('Dir');
        ylabel('TF');
        zlabel('X');
        txt = ['SF = ' num2str(SF_toBePlotted(s))];
        if SF_toBePlotted(s) == best_SF
            txt = [txt '(Best SF)'];
        end
        subtitle(txt);
        view(0,90);
        lims = clim();
        changeLim = false;
        if ~isnan(options.colorMin)
            lims(1) = options.colorMin;
            changeLim = true;
        end
        if ~isnan(options.colorMax)
            lims(2) = options.colorMax;
            changeLim = true;
        end
        if changeLim
            clim(lims);
        end 
    end
end
