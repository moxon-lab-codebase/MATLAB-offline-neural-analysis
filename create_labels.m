function [neuron_labels] = create_labels(original_path)
    % Grabs all the csv files
    csv_mat_path = [original_path, '/*.csv'];
    csv_files = dir(csv_mat_path);
    for file = 1: length(csv_files)
        if contains(csv_files(file).name, 'unit')
            % Auto-generated by MATLAB on 2018/08/14 11:15:11

            %% Initialize variables.
            filename = fullfile(original_path, csv_files(file).name);
            delimiter = ',';

            %% Read columns of data as text:
            % For more information, see the TEXTSCAN documentation.
            formatSpec = '%s%s%*s%s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%s%[^\n\r]';

            %% Open the text file.
            fileID = fopen(filename,'r');

            %% Read columns of data according to the format.
            % This call is based on the structure of the file used to generate this
            % code. If an error occurs for a different file, try regenerating the code
            % from the Import Tool.
            dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string',  'ReturnOnError', false);

            %% Close the text file.
            fclose(fileID);

            %% Convert the contents of columns containing numeric text to numbers.
            % Replace non-numeric text with NaN.
            raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
            for col=1:length(dataArray)-1
                raw(1:length(dataArray{col}),col) = mat2cell(dataArray{col}, ones(length(dataArray{col}), 1));
            end
            numericData = NaN(size(dataArray{1},1),size(dataArray,2));

            for col=[2,3]
                % Converts text in the input cell array to numbers. Replaced non-numeric
                % text with NaN.
                rawData = dataArray{col};
                for row=1:size(rawData, 1)
                    % Create a regular expression to detect and remove non-numeric prefixes and
                    % suffixes.
                    regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
                    try
                        result = regexp(rawData(row), regexstr, 'names');
                        numbers = result.numbers;
                        
                        % Detected commas in non-thousand locations.
                        invalidThousandsSeparator = false;
                        if numbers.contains(',')
                            thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                            if isempty(regexp(numbers, thousandsRegExp, 'once'))
                                numbers = NaN;
                                invalidThousandsSeparator = true;
                            end
                        end
                        % Convert numeric text to numbers.
                        if ~invalidThousandsSeparator
                            numbers = textscan(char(strrep(numbers, ',', '')), '%f');
                            numericData(row, col) = numbers{1};
                            raw{row, col} = numbers{1};
                        end
                    catch
                        raw{row, col} = rawData{row};
                    end
                end
            end


            %% Split data into numeric and string columns.
            rawNumericColumns = raw(:, [2,3]);
            rawStringColumns = string(raw(:, [1,4]));


            %% Replace non-numeric cells with NaN
            R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
            rawNumericColumns(R) = {NaN}; % Replace non-numeric cells

            %% Make sure any text containing <undefined> is properly converted to an <undefined> categorical
            for catIdx = [1,2]
                idx = (rawStringColumns(:, catIdx) == "<undefined>");
                rawStringColumns(idx, catIdx) = "";
            end

            %% Create output variable
            unit_spreadsheet = table;
            unit_spreadsheet.animal_study = categorical(rawStringColumns(:, 1));
            unit_spreadsheet.animal_number = cell2mat(rawNumericColumns(:, 1));
            unit_spreadsheet.experiment_day = cell2mat(rawNumericColumns(:, 2));
            unit_spreadsheet.neuron_label = categorical(rawStringColumns(:, 2));

            %% Clear temporary variables
            clearvars filename delimiter formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp rawNumericColumns rawStringColumns R catIdx idx;
            neuron_labels = unit_spreadsheet.neuron_label;


            % delimiter = ',';

            % %% Format for each line of text:
            % %   column20: categorical (%C)
            % % For more information, see the TEXTSCAN documentation.
            % formatSpec = '%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%C%[^\n\r]';
            
            % %% Open the text file.
            % fileID = fopen(filename,'r');
            
            % %% Read columns of data according to the format.
            % % This call is based on the structure of the file used to generate this
            % % code. If an error occurs for a different file, try regenerating the code
            % % from the Import Tool.
            % dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string', 'EmptyValue', NaN,  'ReturnOnError', false);
            
            % %% Close the text file.
            % fclose(fileID);
            
            % %% Post processing for unimportable data.
            % % No unimportable data rules were applied during the import, so no post
            % % processing code is included. To generate code which works for
            % % unimportable data, select unimportable cells in a file and regenerate the
            % % script.
            
            % %% Create output variable
            % unit_spreadsheet = table(dataArray{1:end-1}, 'VariableNames', {'neuron_label'});
            
            % %% Clear temporary variables
            % clearvars filename delimiter formatSpec fileID dataArray ans;
            % %% End of auto-generated code
            % neuron_labels = unit_spreadsheet.neuron_label;
            % % neuron_labels(1, :) = [];
        end
    end
end