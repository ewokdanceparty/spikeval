function [] = spikevalGenerateDirLayout(options)

if ~isdir('figures')
    mkdir('figures')
end

if ~isdir('config')
    mkdir('config')
end

if ~isdir([options.working_dir '/figures/' options.todays_fig_dir])
    mkdir([options.working_dir '/figures/' options.todays_fig_dir])
end

if ~isdir([options.working_dir '/results/' options.todays_fig_dir])
    mkdir([options.working_dir '/results/' options.todays_fig_dir])
end

if ~isdir([options.working_dir '/config/' options.todays_fig_dir])
    mkdir([options.working_dir '/config/' options.todays_fig_dir])
end