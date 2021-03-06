function [] = batch_plot_tfr_pca_psth(dir_name, save_path, failed_path, tfr_path, ...
        mnts_data_path, pca_data_path, pca_psth_path, dir_config)

    %% Purpose: Go through file list and plot electrode weights onto 3D brain mesh
    %% Input:
    % dir_name: Name of dir that data came from (usually subject #)
    % save_path: path to save files at
    % failed_path: path to save errors at
    % tfr_path: path where tfr figs are for dir_name
    % pca_data_path: path to load pca results from
    % pca_psth_path: path to load files with psth struct
    % dir_config: config settings for that subject
    %% Output:
    %  No output, plots are saved at specified save location

    fprintf('Graphing tfr & pca plots for %s \n', dir_name);
    graph_start = tic;

    %% PCA file list
    pca_file_list = get_file_list(pca_data_path, '.mat');
    pca_file_list = update_file_list(pca_file_list, failed_path, dir_config.include_sessions);

    %% MNTS file list
    mnts_file_list = get_file_list(mnts_data_path, '.mat');
    mnts_file_list = update_file_list(mnts_file_list, failed_path, dir_config.include_sessions);

    %% PSTH file list
    psth_file_list = get_file_list(pca_psth_path, '.mat');
    psth_file_list = update_file_list(psth_file_list, failed_path, dir_config.include_sessions);

    %% TFR file list
    %TODO session num?
    tfr_file_list = get_file_list(tfr_path, '.fig');
    %% Go through files and load relevant parameters
    for file_index = 1:length(pca_file_list)
        [~, filename, ~] = fileparts(pca_file_list(file_index).name);
        filename_meta.filename = filename;
        try
            pca_file = fullfile(pca_data_path, pca_file_list(file_index).name);
            load(pca_file, 'component_results', 'filename_meta', 'chan_group_log', 'event_info');

            if any(contains({psth_file_list.name}, filename_meta.filename))
                psth_filename = psth_file_list(...
                    contains({psth_file_list.name}, filename_meta.filename)).name;
                psth_file = fullfile(pca_psth_path, psth_filename);
                load(psth_file, 'rr_data');
            else
                error('Missing %s to plot PSTH time course', filename_meta.filename);
            end

            if any(contains({mnts_file_list.name}, filename_meta.filename))
                mnts_filename = mnts_file_list(...
                    contains({mnts_file_list.name}, filename_meta.filename)).name;
                mnts_file = fullfile(mnts_data_path, mnts_filename);
                load(mnts_file, 'mnts_struct', 'band_shifts');
            else
                error('Missing %s to plot average power', filename_meta.filename);
            end

            plot_tfr_pca_psth(save_path, tfr_path, tfr_file_list, chan_group_log, mnts_struct, band_shifts, ...
                component_results, rr_data, event_info, dir_config.bin_size, ...
                dir_config.window_start, dir_config.window_end, dir_config.baseline_start, ...
                dir_config.baseline_end, dir_config.response_start, ...
                dir_config.response_end, dir_config.feature_filter, ...
                dir_config.feature_value, dir_config.sub_tfr_rows, ...
                dir_config.sub_tfr_columns, dir_config.st_type, ...
                dir_config.ymax_scale, dir_config.transparency, dir_config.font_size, ...
                dir_config.min_components, dir_config.plot_avg_pow, dir_config.plot_shift_labels);

                clear('component_results', 'filename_meta', 'chan_group_log', 'rr_data');

        catch ME
            handle_ME(ME, failed_path, filename_meta.filename);
        end
    end
    fprintf('Finished tfr & pca plots for %s. It took %s \n', ...
        dir_name, num2str(toc(graph_start)));
end