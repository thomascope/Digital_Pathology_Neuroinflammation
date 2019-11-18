

Demographics = readtable('F:/Brain paper slide scans/Slide_keys/Demographics_formatlab.xlsx');
Regions = readtable('F:/Brain paper slide scans/Slide_keys/Region_key.xlsx');
all_files = dir('F:/Brain paper slide scans/2019-11-13');
all_files2 = dir('F:/Brain paper slide scans/2019-11-14');
all_files = [all_files; all_files2];
all_files = struct2table(all_files);

Demographics.pathology_type = cell(size(Demographics,1),1);
for i = 1:size(Regions,1)
    eval(['Demographics.' Regions.Region{i} '_path_fname = cell(size(Demographics,1),1);'])
    eval(['Demographics.' Regions.Region{i} '_infl_fname = cell(size(Demographics,1),1);'])
end

for i = 1:size(Demographics,1)
    if any(strfind(Demographics.Dx{i},'tau'))
        Demographics.pathology_type{i} = 'TAU';
    elseif any(strfind(Demographics.Dx{i},'AD'))
        Demographics.pathology_type{i} = 'TAU';
    elseif any(strfind(Demographics.Dx{i},'TDP'))
        Demographics.pathology_type{i} = 'TDP43';
    end
    
    for j = 1:size(Regions,1)
        path_file = all_files.name(find(contains(all_files.name,Demographics.No_(i))&contains(all_files.name,Demographics.pathology_type(i))&contains(all_files.name,Regions.Code{j})));
        if isempty(path_file)
            path_file = all_files.name(find(contains(all_files.name,Demographics.No_(i))&contains(all_files.name,Demographics.pathology_type(i))&contains(all_files.name,Regions.BrodmannArea{j}(1:3))));
        end
        if isempty(path_file)
            path_file = all_files.name(find(contains(all_files.name,Demographics.No_(i))&contains(all_files.name,Demographics.pathology_type(i))&contains(all_files.name,Regions.BrodmannAreaAlt{j})));
        end
        try
            eval(['Demographics.' Regions.Region{j} '_path_fname(i) = path_file;'])
        catch
            warning(['No suitable pathology file for ' Demographics.No_{i} ' ' Regions.Region{j}])
        end
        
        infl_file = all_files.name(find(contains(all_files.name,Demographics.No_(i))&contains(all_files.name,'CD68')&contains(all_files.name,Regions.Code{j})));
        if isempty(infl_file)
            infl_file = all_files.name(find(contains(all_files.name,Demographics.No_(i))&contains(all_files.name,'CD68')&contains(all_files.name,Regions.BrodmannArea{j}(1:3))));
        end
        if isempty(infl_file)
            infl_file = all_files.name(find(contains(all_files.name,Demographics.No_(i))&contains(all_files.name,'CD68')&contains(all_files.name,Regions.BrodmannAreaAlt{j})));
        end
        try
            eval(['Demographics.' Regions.Region{j} '_infl_fname(i) = infl_file;'])
        catch
            warning(['No suitable inflammation file for ' Demographics.No_{i} ' ' Regions.Region{j}])
        end
    end
end