function [] = window_classify_main(varargin)
    %% Get data directory
    project_path = get_project_path(varargin);
    start_time = tic;

    %% Import psth config and removes ignored animals
    config = import_config(project_path, 'window_classifier');
    config(config.include_dir == 0, :) = [];

    dir_list = config.dir_name;
    for dir_i = 1:length(dir_list)
        curr_dir = dir_list{dir_i};
        dir_config = config(dir_i, :);
        dir_config = convert_table_cells(dir_config);
        label_table = load_labels(project_path, ['labels_', curr_dir, '.csv']);

        if strcmpi(dir_config.psth_type, 'psth')
            %% Creating paths to do psth formatting
            csv_modifier = 'psth';
            [psth_path, psth_failed_path] = create_dir(project_path, 'psth');
            [data_path, ~] = create_dir(psth_path, 'data');
            export_params(data_path, csv_modifier, config);
            if dir_config.create_psth
                try
                    %% Check to make sure paths exist for analysis and create save path
                    parsed_path = [project_path, '/parsed_spike'];
                    e_msg_1 = 'No parsed directory to create PSTHs';
                    e_msg_2 = ['No ', curr_dir, ' directory to create PSTHs'];
                    parsed_dir_path = enforce_dir_layout(parsed_path, curr_dir, psth_failed_path, e_msg_1, e_msg_2);
                    [dir_save_path, dir_failed_path] = create_dir(data_path, curr_dir);

                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %%        Format PSTH         %%
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    batch_format_rr(dir_save_path, dir_failed_path, parsed_dir_path, curr_dir, dir_config, label_table);
                catch ME
                    handle_ME(ME, psth_failed_path, [curr_dir, '_missing_dir.mat']);
                end
            else
                if ~exist(psth_path, 'dir') || ~exist(data_path, 'dir')
                    error('Must have PSTHs to run PSTH analysis on %s', curr_dir);
                end
            end
        elseif strcmpi(dir_config.psth_type, 'pca')
            csv_modifier = 'pca';
            psth_path = [project_path, '/pca_psth'];
            data_path = [psth_path, '/data'];
            if ~exist(psth_path, 'dir') || ~exist(data_path, 'dir')
                error('Must have PSTHs to run PSTH analysis on %s', curr_dir);
            end
        elseif strcmpi(dir_config.psth_type, 'ica')
            csv_modifier = 'ica';
            psth_path = [project_path, '/ica_psth'];
            data_path = [psth_path, '/data'];
            if ~exist(psth_path, 'dir') || ~exist(data_path, 'dir')
                error('Must have PSTHs to run PSTH analysis on %s', curr_dir);
            end
        else
            error('Invalid psth type %s, must be psth, pca, or ica', dir_config.psth_type);
        end


        [classifier_path, classifier_failed_path] = create_dir(psth_path, 'classifier');
        export_params(classifier_path, 'classifier', config);
        try
            %% Check to make sure paths exist for analysis and create save path
            e_msg_1 = 'No data directory to find PSTHs';
            e_msg_2 = ['No ', curr_dir, ' psth data for classifier analysis'];
            dir_psth_path = enforce_dir_layout(data_path, curr_dir, classifier_failed_path, e_msg_1, e_msg_2);
            [dir_save_path, dir_failed_path] = create_dir(classifier_path, curr_dir);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%        Classification      %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if strcmpi(dir_config.window_direction, 'to_response_start')
                csv_modifier = [csv_modifier, '_to_response_start'];
                window_values = dir_config.response_end:-dir_config.bin_size:dir_config.response_start;
            elseif strcmpi(dir_config.window_direction, 'to_response_end')
                csv_modifier = [csv_modifier, '_to_response_end'];
                window_values = dir_config.response_start:dir_config.bin_size:dir_config.response_end;
            else
                error('Unsupported %s for window direction, try to_response_start or to_response_end')
            end
            for window_i = 2:numel(window_values)
                %% Starts at 2nd index so that we do not get edge with a 0 sized response
                if strcmpi(dir_config.window_direction, 'to_response_start')
                    dir_config.response_start = window_values(window_i);
                elseif strcmpi(dir_config.window_direction, 'to_response_end')
                    dir_config.response_end = window_values(window_i);
                end
                batch_classify(project_path, dir_save_path, dir_failed_path, ...
                    dir_psth_path, curr_dir, csv_modifier, dir_config)
            end
        catch ME
            handle_ME(ME, classifier_failed_path, [curr_dir, '_missing_dir.mat']);
        end
    end
    toc(start_time);
end