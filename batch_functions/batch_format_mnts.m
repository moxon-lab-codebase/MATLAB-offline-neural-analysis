function [] = batch_format_mnts(save_path, failed_path, data_path, dir_name, ...
        dir_config, label_table)
    mnts_start = tic;
    config_log = dir_config;
    file_list = get_file_list(data_path, '.mat');
    file_list = update_file_list(file_list, failed_path, ...
        dir_config.include_sessions);

    fprintf('Calculating mnts for %s \n', dir_name);
    %% Creates mnts from parsed data according to the parameters set in config
    for file_index = 1:length(file_list)
        [~, filename, ~] = fileparts(file_list(file_index).name);
        filename_meta.filename = filename;
        try
            %% Load file contents
            file = [data_path, '/', file_list(file_index).name];
            load(file, 'event_info', 'channel_map', 'filename_meta');
            %% Select channels and label data
            selected_channels = label_data(channel_map, label_table, filename_meta.session_num);

            %% Filter events
            event_info = filter_events(event_info, dir_config.include_events, dir_config.trial_range);

            %% Check parsed variables to make sure they are not empty
            empty_vars = check_variables(file, event_info, selected_channels);
            if empty_vars
                continue
            end

            %% Format mnts
            [mnts_struct, event_info, selected_channels] = format_mnts(...
                event_info, selected_channels, dir_config.bin_size, dir_config.window_start, ...
                dir_config.window_end);

            %% Create label log
            chan_group_log = selected_channels;
            chan_group_log = removevars(chan_group_log, 'channel_data');

            %% Saving outputs
            matfile = fullfile(save_path, ['mnts_format_', ...
                filename_meta.filename, '.mat']);
            %% Check PSTH output to make sure there are no issues with the output
            empty_vars = check_variables(matfile, mnts_struct, ...
                event_info, selected_channels);
            if empty_vars
                continue
            end

            %% Save file if all variables are not empty
            save(matfile, 'mnts_struct', 'event_info', 'selected_channels', ...
                'filename_meta', 'config_log', 'chan_group_log');
            clear('mnts_struct', 'event_info', 'selected_channels', 'filename_meta', 'chan_group_log');
        catch ME
            handle_ME(ME, failed_path, filename_meta.filename);
        end
    end
    fprintf('Finished calculating mnts for %s. It took %s \n', ...
        dir_name, num2str(toc(mnts_start)));
end