function [] = batch_format_sep(save_path, failed_path, data_path, dir_name, config, label_table)
    sep_start = tic;
    fprintf('Creating SEP for %s \n', dir_name);
    config_log = config;
    file_list = get_file_list(data_path, '.mat');
    file_list = update_file_list(file_list, failed_path, config.include_sessions);

    if config.use_raw
        for file_index = 1:length(file_list)
            try
                %% pull info from filename and set up file path for analysis
                file = fullfile(data_path, file_list(file_index).name);
                load(file, 'labeled_data', 'filename_meta', 'event_samples', 'sample_rate');
                %% Select channels
                selected_data = select_data(labeled_data, label_table, ...
                    filename_meta.session_num);

                % Reformat parsed data into data structure for SEP formatting
                unique_regions = fieldnames(selected_data);
                data_table = table;
                for region_i = 1:length(unique_regions)
                    region = unique_regions{region_i};
                    region_table = selected_data.(region);
                    region_table = removevars(region_table, ...
                        {'selected_channels', 'recording_session', 'date', 'recording_notes'});
                    data_table = [data_table; region_table];
                end
                data_table.Properties.VariableNames = {'sig_channels', ...
                    'user_channels', 'label', 'label_id', 'data'};
                %% unfiltered data is called filtered for convience of calling slicing function
                raw_map = table2struct(data_table);
    
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%          Slicing           %%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                sep_window = [-abs(config.window_start), config.window_end];
                sliced_signal = format_sep(raw_map, event_samples, sample_rate, sep_window);
                matfile = fullfile(save_path, ['sliced_', filename_meta.filename, '.mat']);
                save(matfile, '-v7.3', 'sliced_signal', 'sep_window', 'config_log', 'filename_meta', 'event_samples');
            catch ME
                handle_ME(ME, failed_path, filename_meta.filename);
            end
        end
    else
        for file_index = 1:length(file_list)
            try
                %% pull info from filename and set up file path for analysis
                file = fullfile(data_path, file_list(file_index).name);
    
                %% Load needed variables from psth and does the receptive field analysis
                load(file, 'filtered_map', 'event_samples', 'sample_rate', 'filename_meta');
    
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%          Slicing           %%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                sep_window = [-abs(config.window_start), config.window_end];
                sliced_signal = format_sep(filtered_map, event_samples, sample_rate, sep_window);
                matfile = fullfile(save_path, ['sliced_', filename_meta.filename, '.mat']);
                save(matfile, '-v7.3', 'sliced_signal', 'sep_window', 'config_log', 'filename_meta', 'event_samples');
            catch ME
                handle_ME(ME, failed_path, filename_meta.filename);
            end
        end
    end

    fprintf('Finished SEP formatting for %s. It took %s \n', ...
        dir_name, num2str(toc(sep_start)));
end