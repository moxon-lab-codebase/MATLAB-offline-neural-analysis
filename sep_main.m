function [] = sep_main()
            %% Get directory with all animals and their data
    original_path = uigetdir(pwd);
    start_time = tic;
    animal_list = dir(original_path);
    animal_names = {animal_list([animal_list.isdir] == 1 & ~contains({animal_list.name}, '.')).name};
    for animal = 1:length(animal_names)
        animal_name = animal_names{animal};
        animal_path = [original_path, '/', animal_name];
        config = import_config(animal_path);

        %export_params(animal_path, 'main', config);
        % Skips animals we want to ignore
        if config.ignore_animal
            continue;
        else
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%           Parser           %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             if config.is_parse_files
                 parsed_path = sep_parser(animal_name, animal_path);
            else
                parsed_path = [animal_path, '/parsed'];
            end
            
             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%           Filter           %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if (config.is_notch_filter || config.is_lowpass_filter || config.is_highpass_filter || config.is_bandpass_filter)
                filtered_path = sep_filter(config.is_notch_filter, config.is_lowpass_filter, ...
                    config.is_highpass_filter, config.is_bandpass_filter, animal_name, parsed_path, config.notch_filter_frequency, ...
                    config.notch_filter_bandwidth, config.use_notch_bandstop, config.lowpass_filter_order,...
                    config.lowpass_filter_fc, config.highpass_filter_order, config.highpass_filter_fc, ...
                    config.bandpass_filter_order, config.bandpass_filter_low_fc, config.bandpass_filter_high_fc);
            else
                filtered_path = [parsed_path, '/filtered'];
            end
            
             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%         Sep_slicing         %%    The only data passed in the slicing part is bandpass filtered data.
             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if config.is_sep_slicing
                sep_slicing_path = sep_slicing(animal_name, filtered_path, ...
                    config.start_window, config.end_window);
            else
                sep_slicing_path = [filtered_path, '/sliced'];
            end

             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%         Sep_analysis         %%
             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%               
            if config.is_sep_analysis
                sep_analysis_path = sep_analysis(animal_name, parsed_path, sep_slicing_path, ...
                    config.baseline_start_window, config.baseline_end_window, ...
                    config.standard_deviation_coefficient, config.early_start,...
                    config.early_end, config.late_start, config.late_end);
            else
                sep_analysis_path = [sep_slicing_path, '/sep_analysis'];
            end            
            
        end
    end
    toc(start_time);
end
    

    