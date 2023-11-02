clear;
clc;
close all;
app=NaN(1);  %%%%%%%%%This is to allow for Matlab Application integration.
format shortG
top_start_clock=clock;
folder1='C:\Local Matlab Data\3.1GHz Pathloss'; %%%%%Folder where all the matlab code is placed.
cd(folder1)
addpath(folder1)
addpath('C:\Local Matlab Data\General_Terrestrial_Pathloss')
pause(0.1)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Load in the 5G Deployment: Randomized Real with Baltimore Example and then calculate the Pathloss (all in one file).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Custom Deployment Inputs
tf_load_custom_deployment_excel=0%1%0%1%0%1%0%1%0   %%%%%%%%%%If we don't load, it will use the last saved one.
excel_filename='custom_deployment_input_example.xlsx'
macro_rural_eirp=75; %%%%dbm/10mhz
macro_nonrural_eirp=72; %%%%dBm/10Mhz
deployment_rev=2;
deployment_filename=strcat('cell_deployment',num2str(deployment_rev),'.mat');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Load in the custom deployment.
[cell_bs_data]=load_custom_deployment_rev1(app,deployment_filename,tf_load_custom_deployment_excel,macro_rural_eirp,macro_nonrural_eirp,excel_filename);
size(cell_bs_data)


array_bs_eirp=horzcat(macro_rural_eirp,macro_nonrural_eirp,macro_nonrural_eirp); %%%%%EIRP [dBm/10MHz] for Rural, Suburan, Urban
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Propagation Inputs
FreqMHz=3100; %%%%%%%%MHz
freq_separation=0; %%%%%%%Co-channel
reliability=50%[1,2,3,4,5,6,7,8,9,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,91,92,93,94,95,96,97,98,99]'; %%%A custom ITM range to interpolate from
confidence=50;
Tpol=1; %%%polarization for ITM
radar_height=4; %%%%meters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Simulation Input Parameters to change
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rev=401; %%%%%%Baltimore Example
base_pts=horzcat(39.18583333,-76.68638889)
data_label1='LINTHICUM' %%%%%%%%%Giving it a location name
sim_radius_km=30; %%%%%%%%Placeholder distance --> Simplification: This is an automated calculation, but requires additional processing time.
deployment_percentage=100 %%%%100;  80 --> 80%    %%%%%%From Values 1-100 for 1%-100%, Need to pull in the upsample Randomized Real to do 200%, 300%, 400%, 500% (and values in between).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Create a Rev Folder
cd(folder1);
pause(0.1)
tempfolder=strcat('Rev',num2str(rev));
[status,msg,msgID]=mkdir(tempfolder);
rev_folder=fullfile(folder1,tempfolder);
cd(rev_folder)
pause(0.1)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'Save all the link budget parameters in the folder because we will need them when we recreate the excel spread sheet (output).'
save('reliability.mat','reliability')
save('confidence.mat','confidence')
save('FreqMHz.mat','FreqMHz')
save('Tpol.mat','Tpol')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Saving the simulation files in a folder for the option to run from a server
%%%%%%%%%Step 1: Make a Folder for this single Location/System
cd(rev_folder);
pause(0.1)
tempfolder2=strcat(data_label1);
[status,msg,msgID]=mkdir(tempfolder2);
sim_folder=fullfile(rev_folder,tempfolder2);
cd(sim_folder)
pause(0.1)


% % % % % 1) Name,
% % % % % 2) base_polygon (Lat/Lon)
% % % % % 3) Centroid
% % % % % 4) sim_pts/base_protection_pts
% % % % % 5) Radar Threshold,
% % % % % 6) Radar Height,
% % % % % 7) Radar Beamwidth,
% % % % % 8) min_ant_loss,
% % % % % 9) pol_mismatch
% % % % % 10) FDR


%%%%%%%%%%First, Filter the Commercial Deployment and save the sub-set
base_protection_pts=base_pts;
save(strcat(data_label1,'_base_protection_pts.mat'),'base_protection_pts')
save(strcat(data_label1,'_radar_height.mat'),'radar_height')
%%%%%%%%Sim Bound
[sim_bound]=calc_sim_bound(app,base_protection_pts,sim_radius_km,data_label1);

%%%%%%%Filter Base Stations that are within sim_bound
tic;
array_bs_latlon=cell2mat(cell_bs_data(:,[5,6]));
bs_inside_idx=find(inpolygon(array_bs_latlon(:,2),array_bs_latlon(:,1),sim_bound(:,2),sim_bound(:,1))); %Check to see if the points are in the polygon
toc;
size(bs_inside_idx)
temp_sim_cell_bs_data=cell_bs_data(bs_inside_idx,:);


%%%%%%%%%%%%Downsample deployment
[num_inside,~]=size(bs_inside_idx)
sample_num=ceil(num_inside*deployment_percentage/100)
rng(rev); %%%%%%%For Repeatibility
rand_sample_idx=datasample(1:num_inside,sample_num,'Replace',false);
size(temp_sim_cell_bs_data)
temp_sim_cell_bs_data=temp_sim_cell_bs_data(rand_sample_idx,:);
size(temp_sim_cell_bs_data)
temp_lat_lon=cell2mat(temp_sim_cell_bs_data(:,[5,6]));


figure;
hold on;
plot(temp_lat_lon(:,2),temp_lat_lon(:,1),'ob')
plot(sim_bound(:,2),sim_bound(:,1),'-r','LineWidth',3)
plot(base_protection_pts(:,2),base_protection_pts(:,1),'sr','Linewidth',4)
grid on;
plot_google_map('maptype','terrain','APIKey','AIzaSyCgnWnM3NMYbWe7N4svoOXE7B2jwIv28F8') %%%Google's API key made by nick.matlab.error@gmail.com
filename1=strcat('Sim_Area_Deployment_',data_label1,'.png');
pause(0.1)
saveas(gcf,char(filename1))

%%%%%%%%%%Add an index for R/S/U (NLCD)
rural_idx=find(contains(temp_sim_cell_bs_data(:,11),'R'));
sub_idx=find(contains(temp_sim_cell_bs_data(:,11),'S'));
urban_idx=find(contains(temp_sim_cell_bs_data(:,11),'U'));
[num_bs,num_col]=size(temp_sim_cell_bs_data);
array_ncld_idx=NaN(num_bs,1);
array_ncld_idx(rural_idx)=1;
array_ncld_idx(sub_idx)=2;
array_ncld_idx(urban_idx)=3;
cell_ncld=num2cell(array_ncld_idx);


array_eirp_bs=NaN(num_bs,1); %%%%%1)No Mitigations, 2)Mitigations --> 14 and 15 of cell
for i=1:1:num_bs
    temp_nlcd_idx=array_ncld_idx(i);
    array_eirp_bs(i)=array_bs_eirp(:,temp_nlcd_idx);
end
cell_eirp1=num2cell(array_eirp_bs(:,1));
sim_cell_bs_data=horzcat(temp_sim_cell_bs_data,cell_ncld,cell_eirp1);
size(sim_cell_bs_data)

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
%%%%%%%%%%13) NLCD idx
%%%%%%%%%14) EIRP (no mitigations)
%%%%%%%%%15) EIRP (mitigations)

tic;
save(strcat(data_label1,'_sim_cell_bs_data.mat'),'sim_cell_bs_data')
toc; %%%%%%%%%3 seconds


%%%%%%%%%%%%%%%Also include the array of the list_catb (order) that we
%%%%%%%%%%%%%%%usually use for the other sims. (As this will be used
%%%%%%%%%%%%%%%for the path loss and move list.)

sim_cell_bs_data(1,:)
[num_tx,~]=size(sim_cell_bs_data)

sim_array_list_bs=horzcat(cell2mat(sim_cell_bs_data(:,[5,6,10,14])),NaN(num_tx,1),array_ncld_idx,cell2mat(sim_cell_bs_data(:,[7])));
[num_bs_sectors,~]=size(sim_array_list_bs);
sim_array_list_bs(:,5)=1:1:num_bs_sectors;
% % %      %%%%array_list_bs  %%%%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP Adjusted 5) Nick Unique ID for each sector, 6)NLCD: R==1/S==2/U==3, 7) Azimuth 8)BS EIRP Mitigation
%%%%%%%%If there is no mitigation EIRPs, make all of these NaNs (column 8)

%%%%%%%%%%%Put the rest of the Link Budget Parameters in this list

%%%%%%%9) EIRP dBm:         array_bs_eirp
sim_array_list_bs(rural_idx,9)=array_bs_eirp(1);
sim_array_list_bs(sub_idx,9)=array_bs_eirp(2);
sim_array_list_bs(urban_idx,9)=array_bs_eirp(3);


sim_array_list_bs(1,:)
size(sim_array_list_bs)

tic;
save(strcat(data_label1,'_sim_array_list_bs.mat'),'sim_array_list_bs')
toc; %%%%%%%%%3 seconds


% % %      %%%%array_list_bs  %%%%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP 5) Nick Unique ID for each sector, 6)NLCD: R==1/S==2/U==3, 7) Azimuth


sim_array_list_bs(1,:)
'1Lat'
'2Lon'
'7 azimuth sector'
'6: NLCD 1-3'

'Check for nans in power'
unique(sim_array_list_bs(:,4))
any(isnan(sim_array_list_bs(:,4)))



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Calculate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Check for the Number of Folders to Sim
[sim_number,folder_names,num_folders]=check_rev_folders(app,rev_folder);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%If we have it, start the parpool.
disp_progress(app,strcat(rev_folder,'--> Starting Parallel Workers . . . [This usually takes a little time]'))
tic;
parallel_flag=0
workers=1;
[poolobj,cores]=start_parpool_poolsize_app(app,parallel_flag,workers);
toc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Load all the mat files in the main folder
[reliability]=load_data_reliability(app);
[confidence]=load_data_confidence(app);
[FreqMHz]=load_data_FreqMHz(app);
[Tpol]=load_data_Tpol(app);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Step 1: Propagation Loss (ITM)
string_prop_model='ITM'
num_chunks=24;
part1_calc_pathloss_itm_or_tirem_rev4(app,rev_folder,folder_names,parallel_flag,sim_number,reliability,confidence,FreqMHz,Tpol,workers,string_prop_model,num_chunks)




'Save the Excel file'

for folder_idx=1:1:num_folders
    retry_cd=1;
    while(retry_cd==1)
        try
            cd(rev_folder)
            pause(0.1);
            retry_cd=0;
        catch
            retry_cd=1;
            pause(0.1)
        end
    end

    retry_cd=1;
    while(retry_cd==1)
        try
            sim_folder=folder_names{folder_idx};
            cd(sim_folder)
            pause(0.1);
            retry_cd=0;
        catch
            retry_cd=1;
            pause(0.1)
        end
    end

    disp_multifolder(app,sim_folder)
    data_label1=sim_folder;
    %%%%%Persistent Load the other variables
    retry_load=1;
    while(retry_load==1)
        try
            %disp_progress(app,strcat('Loading Sim Data . . . '))
            load(strcat(data_label1,'_base_protection_pts.mat'),'base_protection_pts')
            temp_data=base_protection_pts;
            clear base_protection_pts;
            base_protection_pts=temp_data;
            clear temp_data;

            load(strcat(data_label1,'_sim_array_list_bs.mat'),'sim_array_list_bs')
            temp_data=sim_array_list_bs;
            clear sim_array_list_bs;
            sim_array_list_bs=temp_data;
            clear temp_data;
            % % %      %%%%array_list_bs  %%%%%%%1) Lat, 2)Lon, 3)BS height, 4)BS EIRP 5) Nick Unique ID for each sector, 6)NLCD: R==1/S==2/U==3, 7) Azimuth 8)BS EIRP Mitigation

            load(strcat(data_label1,'_sim_cell_bs_data.mat'),'sim_cell_bs_data')
            temp_data=sim_cell_bs_data;
            clear sim_cell_bs_data;
            sim_cell_bs_data=temp_data;
            clear temp_data;

            retry_load=0;
        catch
            retry_load=1;
            pause(0.1)
        end
    end

    [num_ppts,~]=size(base_protection_pts)
    for point_idx=1:1:num_ppts  %%%%%%%%This can be parfor
        point_idx
        %%%%%%%%%%%%%%%%%%%%%%%%%%%Load propagation for the Output Excel File
        file_name_pathloss=strcat(string_prop_model,'_pathloss_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
        file_name_prop_mode=strcat(string_prop_model,'_prop_mode_',num2str(point_idx),'_',num2str(sim_number),'_',data_label1,'.mat');
        retry_load=1;
        while(retry_load==1)
            try
                load(file_name_pathloss,'pathloss')
                load(file_name_prop_mode,'prop_mode')
                retry_load=0;
            catch
                retry_load=1;
                pause(1)
            end
        end

        if strcmp(string_prop_model,'ITM')
            num_cells=length(prop_mode);
            cell_prop_mode=cell(num_cells,1);
            for prop_idx=1:1:num_cells
                num_prop_mode=prop_mode(prop_idx);
                if num_prop_mode==0
                    temp_prop_mode='LOS';
                elseif num_prop_mode==4
                    temp_prop_mode='Single Horizon';
                elseif num_prop_mode==5
                    temp_prop_mode='Difraction Double Horizon';
                elseif num_prop_mode==8
                    temp_prop_mode='Double Horizon';
                elseif num_prop_mode==9
                    temp_prop_mode='Difraction Single Horizon';
                elseif num_prop_mode==6
                    temp_prop_mode='Troposcatter Single Horizon';
                elseif num_prop_mode==10
                    temp_prop_mode='Troposcatter Double Horizon';
                elseif num_prop_mode==333
                    temp_prop_mode='Error';
                else
                    'Undefined Propagation Mode'
                    pause;
                end
                cell_prop_mode{prop_idx}=temp_prop_mode;
            end
        end

        size(sim_cell_bs_data)
        size(pathloss)
       table_pathloss=horzcat(cell2table(sim_cell_bs_data(:,[1,2,5,6])),array2table(pathloss),cell2table(cell_prop_mode));
       table_pathloss.Properties.VariableNames={'Type' 'ID' 'Latitude_DD' 'Longitude_DD' 'Pathloss' 'Propagation_Mode'}

       tic;
       writetable(table_pathloss,strcat(data_label1,'_Point',num2str(point_idx),'_Link_Budget_',string_prop_model,'.xlsx'));
       toc;
    end

end





end_clock=clock;
total_clock=end_clock-top_start_clock;
total_seconds=total_clock(6)+total_clock(5)*60+total_clock(4)*3600+total_clock(3)*86400;
total_mins=total_seconds/60;
total_hours=total_mins/60;
if total_hours>1
    strcat('Total Hours:',num2str(total_hours))
elseif total_mins>1
    strcat('Total Minutes:',num2str(total_mins))
else
    strcat('Total Seconds:',num2str(total_seconds))
end

'DONE'
