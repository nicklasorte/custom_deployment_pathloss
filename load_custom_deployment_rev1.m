function [cell_bs_data]=load_custom_deployment_rev1(app,deployment_filename,tf_load_custom_deployment_excel,macro_rural_eirp,macro_nonrural_eirp,excel_filename)

[var_exist_deployment]=persistent_var_exist_with_corruption(app,deployment_filename);
if tf_load_custom_deployment_excel==1
    var_exist_deployment=0
end

if var_exist_deployment==2
    retry_load=1;
    while(retry_load==1)
        try
            tic;
            load(deployment_filename,'cell_deployment')
            toc;  %%%%%4 seconds
            cell_bs_data=cell_deployment;
            retry_load=0;
        catch
            retry_load=1;
            pause(0.1)
        end
    end
else
    %%%%%%%%%Will add in micro and pico later.
    %%%%%%Can add in a column for each base station that specifies the
    %%%%%%eirp for each base station. (Broad strokes first).

    tic;
    disp_progress(app,'Loading Randomized Real . . .')
    load('cell_err_data.mat','cell_err_data') %%%%%%%%Placeholder of the 5G deployment
    toc; %%%%%%%15 Seconds
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Variable Names
    %%%1) LaydownID
    %%%2) FCCLicenseID
    %%%3) SiteID
    %%%4) SectorID
    %%%5) SiteLatitude_decDeg
    %%%6) SiteLongitude_decDeg
    %%%7) SE_BearingAngle_deg
    %%%8) SE_AntennaAzBeamwidth_deg
    %%%9) SE_DownTilt_deg  %%%%%%%%%%%%%%%%%(Check for Blank)
    %%%10) SE_AntennaHeight_m
    %%%11) SE_Morphology
    %%%12) SE_CatAB

    %%%%%%%%%%%%%%%%%%%%%%%%%Load in the Excel DCS location data
    tic;
    raw_table=readtable(excel_filename);
    toc;

    %%%%%%%%%If the table gets new columns, find the header names assign them dynamically
    header_varname=raw_table.Properties.VariableNames

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    idx_cell_type=find(contains(header_varname,'CellType')); %1
    idx_tx_id=find(contains(header_varname,'TransmitterID')); %2
    idx_lat=find(contains(header_varname,'Latitude')); %5
    idx_lon=find(contains(header_varname,'Longitude')); %6
    idx_azi=find(contains(header_varname,'Azimuth'));%7
    idx_total_tilt=find(contains(header_varname,'TotalTilt'));%9
    idx_ant_height=find(contains(header_varname,'AntennaHeightMeters'));%10

    'One future input might be the EIRP at each base station.'
    'Another future input might be antenna beamwidth'

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    raw_cell_type=table2cell(raw_table(:,idx_cell_type)); %1
    raw_tx_id=table2cell(raw_table(:,idx_tx_id)); %2
    raw_SiteID=cell(size(raw_cell_type)); %%%%%%%%%%%%%%Empty Cell Placeholder to keep the cell format the same with the Enhanced Randomized Real
    raw_SectorID=cell(size(raw_cell_type)); %%%%%%%%%%%%%%Empty Cell Placeholder to keep the cell format the same
    raw_SiteLatitude_decDeg=table2cell(raw_table(:,idx_lat)); %5
    raw_SiteLongitude_decDeg=table2cell(raw_table(:,idx_lon)); %6
    raw_SE_BearingAngle_deg=table2cell(raw_table(:,idx_azi)); %7
    raw_SE_AntennaAzBeamwidth_deg=cell(size(raw_cell_type)); %%%%%%%%%%%%%%Empty Cell Placeholder to keep the cell format the same with the Enhanced Randomized Real
    raw_SE_DownTilt_deg=table2cell(raw_table(:,idx_total_tilt)); %9
    raw_SE_AntennaHeight_m=table2cell(raw_table(:,idx_ant_height)); %10
    raw_SE_Morphology=cell(size(raw_cell_type)); %%%%%%%%%%%%%%Empty Cell Placeholder to keep the cell format the same
    raw_SE_CatAB=cell(size(raw_cell_type)); %%%%%%%%%%%%%%Empty Cell Placeholder to keep the cell format the same
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    cell_deployment=horzcat(raw_cell_type,raw_tx_id,raw_SiteID,raw_SectorID,raw_SiteLatitude_decDeg,raw_SiteLongitude_decDeg,raw_SE_BearingAngle_deg,raw_SE_AntennaAzBeamwidth_deg,raw_SE_DownTilt_deg,raw_SE_AntennaHeight_m,raw_SE_Morphology,raw_SE_CatAB);
    %%%1) LaydownID --> Cell Type: Macro/Micro/Pico
    %%%2) FCCLicenseID --> Site ID (unique value)
    %%%3) SiteID --> [Blank]
    %%%4) SectorID --> [Blank]
    %%%5) SiteLatitude_decDeg --> Latitude
    %%%6) SiteLongitude_decDeg --> Longitude
    %%%7) SE_BearingAngle_deg --> Azimuth
    %%%8) SE_AntennaAzBeamwidth_deg --> Beamwidth
    %%%9) SE_DownTilt_deg  %%%%%%%%%%%%%%%%%(Check for Blank)
    %%%10) SE_AntennaHeight_m
    %%%11) SE_Morphology
    %%%12) SE_CatAB


    %%%%%%%%%%%%%First, only keep the Macro, (will add in the others later)
    macro_idx=find(contains(cell_deployment(:,1),'Macro'));
    size(macro_idx)
    cell_deployment=cell_deployment(macro_idx,:);

    %%%%%%%%%%%%%Filter only those within the lower 48 States (very rough and quick)
    %%%%%%Filter out those outside the US
    max_lat=50;
    min_lat=23;

    temp_latlon=cell2mat(cell_deployment(:,[5,6]));
    filter1_idx=find(temp_latlon(:,1)<max_lat);
    filter2_idx=find(temp_latlon(:,1)>min_lat);
    us_idx=intersect(filter1_idx,filter2_idx);

    cell_deployment=cell_deployment(us_idx,:);
    array_custom_latlon=cell2mat(cell_deployment(:,[5,6]));
    size(array_custom_latlon)

    %%%%%%%%%%Find the knn of the randomized real and assign the EIRP
    %%%%%%%%%%for rural and nonrural. This is very rough, but faster
    %%%%%%%%%%than looking at each one and census tract. Will refine
    %%%%%%%%%%later.
    array_err_latlon=cell2mat(cell_err_data(:,[5,6]));
    [idx_knn]=knnsearch(array_err_latlon,array_custom_latlon,'k',1); %%%Find Nearest Neighbor
    knn_array_err_latlon=array_err_latlon(idx_knn,:);
    knn_dist_bound=deg2km(distance(knn_array_err_latlon(:,1),knn_array_err_latlon(:,2),array_custom_latlon(:,1),array_custom_latlon(:,2)));%%%%Calculate Distance

    % % %         close all;
    % % %         figure;
    % % %         hold on;
    % % %         histogram(knn_dist_bound)


    %%%%Cell of "FCC" RSU (Rural, Suburban, Urban)
    cell_custom_rsu=cell_err_data(idx_knn,11);

    %%%%%%%%%%%Assign EIRP based on this.
    %%%%%%%%%%Add an index for R/S/U (NLCD)
    rural_eirp_idx=find(contains(cell_custom_rsu,'R'));
    sub_eirp_idx=find(contains(cell_custom_rsu,'S'));
    urban_eirp_idx=find(contains(cell_custom_rsu,'U'));
    sub_urban_eirp_idx=union(sub_eirp_idx,urban_eirp_idx);
    [num_bs,~]=size(cell_custom_rsu);
    array_eirp=NaN(num_bs,1);
    array_eirp(rural_eirp_idx)=macro_rural_eirp;
    array_eirp(sub_eirp_idx)=macro_nonrural_eirp;
    array_eirp(urban_eirp_idx)=macro_nonrural_eirp;
    cell_eirp=num2cell(array_eirp);

    if any(isnan(array_eirp))
        'Error NaN EIRP'
        pause;
    end

    %%%%%%%%%%%%%Need to fill in the Morphology, as this is how it
    %%%%%%%%%%%%%current selected the AAS used and the EIRP applied.
    %%%%%%%%%%%%%This will be put into column 11.
    array_downtilt=cell2mat(cell_deployment(:,9));
    max(array_downtilt)
    min(array_downtilt)

    rural_downtilt_max=4.5;
    suburban_downtilt_max=8.5;

    % % % %         Rural: 3 degree electrical downtilt
    % % % % Suburban: 6 degree electrical downtilt
    % % % % Urban: 10 degree electrical downtilt
    %%%%%%%%%%%%%%%%%%%Just downtilt first, intersect EIRP later.
    rural_downtilt_idx=find(array_downtilt<=rural_downtilt_max);
    sub1_downtilt_idx=find(array_downtilt<=suburban_downtilt_max);
    sub2_downtilt_idx=find(array_downtilt>rural_downtilt_max);
    sub_downtilt_idx=intersect(sub1_downtilt_idx,sub2_downtilt_idx);
    urb_downtilt_idx=find(array_downtilt>suburban_downtilt_max);

    test1=num_bs-length(rural_downtilt_idx)-length(sub_downtilt_idx)-length(urb_downtilt_idx)
    if test1~=0
        'Error: This should be zero'
        pause;
    end

    %%%%%%%%%%%%%This might be the equivalent of the array_ncld_idx, which is in the sim_array_list_bs #6
    %%%%%%%%%%array_list_bs
    % %%%%%%%1)Lat,
    % %%%%%%%2)Lon,
    % %%%%%%%3)BS height,
    % %%%%%%%4)BS EIRP Adjusted
    % %%%%%%%5)Nick Unique ID for each sector,
    % %%%%%%%6)NLCD: R==1/S==2/U==3,
    % %%%%%%%7)Azimuth
    % %%%%%%%8)BS EIRP Mitigation

    array_downtilt_idx=NaN(num_bs,1);
    array_downtilt_idx(rural_downtilt_idx)=1;
    array_downtilt_idx(sub_downtilt_idx)=2;
    array_downtilt_idx(urb_downtilt_idx)=3;
    cell_downtilt_idx=num2cell(array_downtilt_idx);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"Sorting" logic.
    %%%%%%%%%%%%%%%%%%See if the Downtilts and EIRPS intersect: Downtilt seems
    %%%%%%%%%%%%%%%%%%to have the larger dB reduction, so we will move things
    %%%%%%%%%%%%%%%%%%up the ladder, from rural to suburban.
    %%%%%%%%%%For now we'll call it "AAS Rural" if it has a small downtilt and the EIRP
    rural_aas_idx=intersect(rural_eirp_idx,rural_downtilt_idx);

    %%%%%%%%%%%%%Suburban if it's within the downltilt and EIRP
    sub_aas_idx=intersect(sub_urban_eirp_idx,sub_downtilt_idx);

    %%%%%%%%%%Urban if it's within the downtilt and EIRP
    urb_aas_idx=intersect(sub_urban_eirp_idx,urb_downtilt_idx);

    %%%%If it has a suburban/urban EIRP, but a rural downtilt, Move to suburban?
    sub_rural_aas_idx=intersect(sub_urban_eirp_idx,rural_downtilt_idx);

    %%%%If it has a rural EIRP, but a sub downtilt, Move to suburban?
    rural_sub_aas_idx=intersect(rural_eirp_idx,sub_downtilt_idx);

    %%%%If it has a rural EIRP, but a urban downtilt, Move to urban?
    rural_urb_aas_idx=intersect(rural_eirp_idx,urb_downtilt_idx);


    %%%%%%%%%%All the outliers
    test2=num_bs-length(rural_aas_idx)-length(sub_aas_idx)-length(urb_aas_idx)-length(sub_rural_aas_idx)-length(rural_sub_aas_idx)-length(rural_urb_aas_idx)
    if test2~=0
        'Error: This should be zero'
        pause;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%This is what we will use for the AAS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%antenna selection in the sim.
    temp_nlcd_idx=NaN(num_bs,1);
    temp_nlcd_idx(rural_aas_idx)=1;
    temp_nlcd_idx(sub_aas_idx)=2;
    temp_nlcd_idx(sub_rural_aas_idx)=2;
    temp_nlcd_idx(rural_sub_aas_idx)=2;
    temp_nlcd_idx(urb_aas_idx)=3;
    temp_nlcd_idx(rural_urb_aas_idx)=3;
    cell_nlcd_idx=num2cell(temp_nlcd_idx);

    cell_custom_rsu=cell(num_bs,1);
    one_idx=find(temp_nlcd_idx==1);
    two_idx=find(temp_nlcd_idx==2);
    three_idx=find(temp_nlcd_idx==3);
    cell_custom_rsu(one_idx)={'R'};
    cell_custom_rsu(two_idx)={'S'};
    cell_custom_rsu(three_idx)={'U'};


    if any(isnan(temp_nlcd_idx))
        'Error: Missing idx in nlcd'
        pause;
    end

    %%%%%%%%%%%%%%%Assemble the cell_bs_data
    %cell_deployment(:,13)=cell_nlcd_idx;%%%%%%%%NLCD idx for AAS --> May need to transform this back into an RSU and insert into column 11
    cell_deployment(:,11)=cell_custom_rsu;
    %cell_deployment(:,14)=cell_eirp; %%%%%%%EIRP
    'Saving the deployment . . .  might take 30 seconds . . .'
    tic;
    save(deployment_filename,'cell_deployment')
    toc;  %%%%%%%25 seconds
    cell_bs_data=cell_deployment;
end

end