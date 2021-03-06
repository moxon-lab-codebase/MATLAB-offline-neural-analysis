function batch_extract_spikes(save_path, failed_path, data_path,...
        dir_name, dir_config, label_table)
    %% Continuous data spike extraction...
    extract_spikes_start = tic;
    fprintf('Extracting spikes for %s \n', dir_name);
    config_log = dir_config;
    curr_dir = [data_path, '/'];
    file_list = get_file_list(curr_dir, '.mat');
    file_list = update_file_list(file_list, failed_path, ...
        dir_config.include_sessions);

    for file_index = 1:length(file_list)
        [~, filename, ~] = fileparts(file_list(file_index).name);
        filename_meta.filename = filename;
       
        try
            %% Load file contents
            file = [curr_dir, '/', file_list(file_index).name];
            if dir_config.use_raw
                load(file, 'channel_map', 'filename_meta', 'event_info', 'sample_rate');
                %% Select channels and label data, called filtered_map for convience of format_sep call below
                filtered_map = label_data(channel_map, label_table, filename_meta.session_num);
                chan_group_log = filtered_map;
                chan_group_log = removevars(chan_group_log, 'channel_data');
                clear('channel_map');
            else
                load(file, 'filtered_map', 'event_info', 'sample_rate', 'filename_meta', 'chan_group_log');
            end

            %% Create channel_map as input for other pipelines
            channel_map = create_channel_map(filtered_map, event_info, sample_rate, ...
                dir_config.baseline_start, dir_config.baseline_end, dir_config.threshold_scalar);

            event_info.event_ts = event_info.event_ts / sample_rate;

            %% Saving outputs
            matfile = fullfile(save_path, ['spikes_', filename_meta.filename, '.mat']);
            empty_vars = check_variables(matfile, channel_map, event_info);
            if empty_vars
                continue
            end
            
            %% Save spike data
            save(matfile, '-v7.3', 'channel_map', 'event_info', 'filename_meta', 'config_log', 'chan_group_log');
            clear('channel_map', 'event_ts', 'filename_meta');
            
        catch ME
            handle_ME(ME, failed_path, filename_meta.filename);
        end
    end
    toc(extract_spikes_start);
end

