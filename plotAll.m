function plotAll(tcDoc_all)
%PLOTALL Display all direction-temporal frequency tuning surfaces at best spatial frequency
    % Set supersubplot format
    numRows = 4;
    numCols = 4;
    count = 0;
    num1Dir = 0;
    num1SF = 0;
    num1TF = 0;
    for i = 1:numel(tcDoc_all)
        % Loops over all tuning curve docs
        tcDoc = tcDoc_all{i};
        if ~isempty(tcDoc)
            % Few neurons do not have a stimulus presentation doc
            tc = tcDoc.document_properties.stimulus_tuningcurve;
            [directions,~,~] = unique(tc.independent_variable_value(:,1),'sorted');
            [spatialFrequencies,~,~] = unique(tc.independent_variable_value(:,2),'sorted');
            [temporalFrequencies,~,~] = unique(tc.independent_variable_value(:,3),'sorted');
            
            if numel(directions)<=1
                % Reports when Dir has only one value - not enough for plots
                num1Dir = num1Dir + 1;
                fprintf('Cell %d has ONLY one [DIR]! \n', i);
                continue 
            end
            if numel(temporalFrequencies)<=1
                % Reports when TF has only one value - not enough for plots
                num1TF = num1TF + 1;
                fprintf('Cell %d has ONLY one [TF]! \n', i);
                continue 
            end
            fprintf('SF(s) for Cell %d =', i);
            disp(spatialFrequencies);
            if numel(spatialFrequencies)<=1
                num1SF = num1SF + 1;
            end
            if sigDirSFTF(tcDoc) < 0.05 % Significance test - anova1
                % Arranges certain number of subplots in one figure
                count = count + 1;
                if count == 1
                    fig = figure('Position', [100, 100, 800, 800]);
                end                
                ax = supersubplot(fig,numRows,numCols,count);
                plotDirTF_bestSF(tcDoc,'colorMin',0,'colorMax',0.25);
                colormap(ax, 'parula');
                title(i);
                % Color bar for each figure
                if count == numRows*numCols
                    cb = colorbar('Position', [0.92 0.11 0.02 0.77]);
                    cb.Label.String = 'Response strength'; 
                    count = 0;
                end
            end
        end
    end
    % Color bar for the last figure
    cb = colorbar('Position', [0.92 0.11 0.02 0.77]);
    cb.Label.String = 'Response strength'; 
    fprintf('%d cells have ONLY one Dir value! \n', num1Dir);
    fprintf('%d cells have ONLY one SF value! \n', num1SF);
    fprintf('%d cells have ONLY one TF value! \n', num1TF);
end
