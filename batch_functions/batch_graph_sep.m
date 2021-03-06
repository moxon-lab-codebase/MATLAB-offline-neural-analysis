function [] = batch_graph_sep(save_path, failed_path, data_path, ...
    dir_name, dir_config)

    file_list = get_file_list(data_path, '.mat');
    file_list = update_file_list(file_list, failed_path, ...
        dir_config.include_sessions);

    fprintf('Plotting SEPs for %s \n', dir_name);
    for file_i = 1:length(file_list)
        [~, filename, ~] = fileparts(file_list(file_i).name);
        filename_meta.filename = filename;
        try
            file = [data_path, '/', file_list(file_i).name];
            load(file, 'sep_analysis_results', 'filename_meta', 'chan_group_log');

            graph_sep(save_path, sep_analysis_results, filename_meta, chan_group_log, ...
                dir_config.sub_rows, dir_config.sub_cols);
            clear('sep_analysis_results', 'filename_meta', 'chan_group_log');
        catch ME
            handle_ME(ME, failed_path, filename_meta.filename);
        end
    end
    fprintf('Finished plotting SEPs for %s \n', dir_name);
end