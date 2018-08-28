function [] = spikevalSaveFigures(filename, fig_cell, fig_name_cell, options)


for i=1:length(fig_cell)
        
        saving_dir = [options.working_dir '/figures/' options.todays_fig_dir];
    
        if ~isdir(saving_dir)
            mkdir(saving_dir);
        end
        temp = strsplit(filename, '/');
        file_dir = [saving_dir '/' fig_name_cell{i}];
        if ~isdir(file_dir)
            mkdir(file_dir);
        end
        fig_dir = [file_dir '/' 'fig'];
        if ~isdir(fig_dir)
            mkdir(fig_dir)
        end
        png_dir = [file_dir '/' 'png'];
        if ~isdir(png_dir)
            mkdir(png_dir);
        end
        pdf_dir = [file_dir '/' 'pdf'];
        if ~isdir(pdf_dir)
            mkdir(pdf_dir);
        end
        file = temp{end};
        saveas(fig_cell{i}, [fig_dir '/' file(1:end-3) fig_name_cell{i}])
        saveas(fig_cell{i}, [png_dir '/' file(1:end-3) fig_name_cell{i}], 'png')
        saveas(fig_cell{i}, [pdf_dir '/' file(1:end-3) fig_name_cell{i}], 'pdf')

end