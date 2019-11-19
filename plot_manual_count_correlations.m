%Script to plot Sanne's manual counting data

%First overall
k = 0
figure
for j = 17:19
    for i = 13:16
        k=k+1
        subplot(3,4,k)
        scatter(manual_count.(j),manual_count.(i))
        xlabel(manual_count.Properties.VariableNames{j},'Interpreter','none')
        ylabel(manual_count.Properties.VariableNames{i},'Interpreter','none')
        thislsline = lsline;
        [r,p]=corrcoef(manual_count.(j),manual_count.(i));
        title(['r=' num2str(r(2),3) ', p=' num2str(p(2),3)],'Interpreter','none')
        if p(2) < 0.05
            set(thislsline,'Color','k','Linewidth',2)
        end
    end
end
set(gcf, 'DefaultTextInterpreter', 'none')
suptitle('All patients')

%Then by pathology type
all_diagnoses = unique(manual_count.DiagnosisPath);
for l = 1:length(all_diagnoses)
    k = 0
    figure
    for j = 17:19
        for i = 13:16
            k=k+1
            subplot(3,4,k)
            scatter(manual_count.(j)(strcmp(manual_count.DiagnosisPath,all_diagnoses{l})),manual_count.(i)(strcmp(manual_count.DiagnosisPath,all_diagnoses{l})))
            xlabel(manual_count.Properties.VariableNames{j},'Interpreter','none')
            ylabel(manual_count.Properties.VariableNames{i},'Interpreter','none')
            thislsline = lsline;
            [r,p] =corrcoef(manual_count.(j)(strcmp(manual_count.DiagnosisPath,all_diagnoses{l})),manual_count.(i)(strcmp(manual_count.DiagnosisPath,all_diagnoses{l})));
            title(['r=' num2str(r(2),3) ', p=' num2str(p(2),3)],'Interpreter','none')
            if p(2) < 0.05
                set(thislsline,'Color','k','Linewidth',2)
            end
        end
    end
    set(gcf, 'DefaultTextInterpreter', 'none')
    suptitle(all_diagnoses{l})
end

%Now do repeated maesures ANOVA % Work in progress
manual_count_trunkated = manual_count(:,[1:3,13:19]);
reshaped_table = unstack(manual_count_trunkated,(4:size(manual_count_trunkated,2)),'area');

figure
this_region = unique(manual_count_trunkated.area);
for i = 1:length(this_region)
    subplot(2,2,i)
    subtable = manual_count_trunkated(strcmp(manual_count_trunkated.area,this_region{i}),:);
    gscatter(subtable.density_path_um,subtable.density_amoeboid_um,subtable.DiagnosisPath)
    legend off
    [r,p] =corrcoef(subtable.density_path_um,subtable.density_amoeboid_um);
    title([Regions.Region{strncmp(this_region{i},Regions.BrodmannArea,3)} ' r=' num2str(r(2),3) ', p=' num2str(p(2),3)],'Interpreter','none')
end
legend(unique(subtable.DiagnosisPath,'stable'),'Interpreter','none','Location','NorthWest')
