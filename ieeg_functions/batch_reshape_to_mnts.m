function [] = batch_reshape_to_mnts(save_path, failed_path, data_path, ...
    dir_name, dir_config, label_table)
    %% Purpose: Go through file list and reshape tfr data into mnts format
    % tfr: time frequency representation
    %      trials x channels x frequency x bins
    % mnts: multineuron time series
    %       Observations (trials * tot bins) x Features (channels)
    %% Input:
    % save_path: path to save files at
    % failed_path: path to save errors at
    % data_path: path to load files from before analysis is ran
    % dir_name: Name of dir that data came from (usually subject #)
    % dir_config: config settings for that subject
    % label_table: table with information of current recording
    %              field: table with columns
    %                     'channel': String with name of channel
    %                     'selected_channels': Boolean if channel is used
    %                     'user_channels': String with user defined mapping
    %                     'label': String: associated chan_group or grouping of electrodes
    %                     'label_id': Int: unique id used for labels
    %                     'recording_session': Int: File recording session number that above applies to
    %                     'recording_notes': String with user defined notes for channel
    %% Output:
    %  No output, analysis results are saved in file at specified save location
    mnts_start = tic;
    config_log = dir_config;
    file_list = get_file_list(data_path, '.mat');
    file_list = update_file_list(file_list, failed_path, ...
        dir_config.include_sessions);

    %% Remove unselected channels
    label_table(label_table.selected_channels == 0, :) = [];

    if dir_config.downsample_pow
        bin_size = dir_config.downsample_bin;
        window_start = dir_config.down_start;
    else
        bin_size = dir_config.bin_size;
        window_start = dir_config.window_start;
    end

    fprintf('Calculating mnts for %s \n', dir_name);
    %% Creates mnts from parsed data according to the parameters set in config
    for file_index = 1:length(file_list)
        [~, filename, ~] = fileparts(file_list(file_index).name);
        filename_meta.filename = filename;
        try
            %% Load file contents
            file = [data_path, '/', file_list(file_index).name];
            load(file, 'power_struct', 'filename_meta');

            %% Grab channels for current session num
            session_labels = label_table(label_table.recording_session ...
                == filename_meta.session_num, :);

            %% Format mnts
            %TODO parameters: trial selection
            [chan_group_log, mnts_struct, event_info, band_shifts] = reshape_to_mnts(session_labels, power_struct, ...
                dir_config.select_features, dir_config.include_events, dir_config.use_z_mnts, ...
                dir_config.smooth_power, dir_config.smoothing_direction, dir_config.span, ...
                dir_config.downsample_pow, dir_config.downsample_rate, ...
                dir_config.slice_time, bin_size, window_start, ...
                dir_config.slice_start, dir_config.slice_end);

            %% Saving outputs
            matfile = fullfile(save_path, ['mnts_format_', ...
                filename_meta.filename, '.mat']);
            save(matfile, '-v7.3', 'mnts_struct', 'chan_group_log', 'event_info', ...
                'filename_meta', 'config_log', 'band_shifts');
            clear('mnts_struct', 'chan_group_log', 'filename_meta', 'power_struct');
        catch ME
            handle_ME(ME, failed_path, filename_meta.filename);
        end
    end
    fprintf('Finished calculating mnts for %s. It took %s \n', ...
        dir_name, num2str(toc(mnts_start)));
end