 function SimpleExposure_ED(varargin)

global KEY COLORS w wRect XCENTER YCENTER PICS STIM SimpExp trial pahandle

% This is for food & or model exposure!

prompt={'SUBJECT ID' 'fMRI: 1 = Yes; 0 = No'};
defAns={'4444' '1'};

answer=inputdlg(prompt,'Please input subject info',1,defAns);

ID=str2double(answer{1});
% COND = str2double(answer{2});
% SESS = str2double(answer{3});
% prac = str2double(answer{4});


rng(ID); %Seed random number generator with subject ID
d = clock;

KEY = struct;
KEY.trigger = KbName('''"');


COLORS = struct;
COLORS.BLACK = [0 0 0];
COLORS.WHITE = [255 255 255];
COLORS.RED = [255 0 0];
COLORS.BLUE = [0 0 255];
COLORS.GREEN = [0 255 0];
COLORS.YELLOW = [255 255 0];
COLORS.rect = COLORS.GREEN;

STIM = struct;
STIM.blocks = 6;
STIM.trials = 10;
STIM.totes = STIM.blocks*STIM.trials;
STIM.trialdur = 4.5;
STIM.jitter = [2 3 4];

%% Keyboard stuff for fMRI...

%list devices
[keyboardIndices, productNames] = GetKeyboardIndices;

isxkeys=strcmp(productNames,'Xkeys');

xkeys=keyboardIndices(isxkeys);
macbook = keyboardIndices(strcmp(productNames,'Apple Internal Keyboard / Trackpad'));

%in case something goes wrong or the keyboard name isn?t exactly right
if isempty(macbook)
    macbook=-1;
end

%in case you?re not hooked up to the scanner, then just work off the keyboard
if isempty(xkeys)
    xkeys=macbook;
end

%% Find & load in pics
%find the image directory by figuring out where the .m is kept
[mdir,~,~] = fileparts(which('SimpleExposure_ED.m'));

% [ratedir,~,~] = fileparts(which('SimpleExposure.m'));
picratefolder = fullfile(mdir,'Ratings');   %XXX: Double check this is correct folder.
imgdir = fullfile(mdir,'Pics');

try
    cd(picratefolder)
catch
    error('Could not find and/or open the folder that contains the image ratings.');
end



filen = sprintf('PicRateU_%d.mat',ID);
try
    p = open(filen);
catch
    warning('Could not find and/or open the U rating file.');
    commandwindow;
    randopics = input('Would you like to continue with a random selection of images? [1 = Yes, 0 = No]');
    if randopics == 1
        cd(imgdir)
        p = struct;
        p.PicRating_U4ED.avg = dir('Average*'); 

    else
        error('Task cannot proceed without images. Contact Erik (elk@uoregon.edu) if you have continued problems.')
    end
    
end

filen = sprintf('PicRateMod_%d.mat',ID);
try
    p = open(filen);
catch
    warning('Could not find and/or open the Mod rating file.');
    commandwindow;
    randopics = input('Would you like to continue with a random selection of images? [1 = Yes, 0 = No]');
    if randopics == 1
        cd(imgdir)
        p = struct;
        p.PicRating_U4ED.thin = dir('Thin*'); 

    else
        error('Task cannot proceed without images. Contact Erik (elk@uoregon.edu) if you have continued problems.')
    end
    
end

cd(imgdir);
 


PICS =struct;

PICS.in.hi = struct('name',{p.PicRating_U4ED.avg(1:40).name}');
PICS.in.lo = struct('name',{p.PicRating_U4ED.thin(1:40).name}');
neutpics = dir('water*');

%Check if pictures are present. If not, throw error.
%Could be updated to search computer to look for pics...
if isempty(neutpics) || isempty(PICS.in.hi) %|| isempty(neutpics)
    error('Could not find pics. Please ensure pictures are found in a folder names IMAGES within the folder containing the .m task file.');
end

%% Fill in rest of pertinent info
SimpExp = struct;

%1 = food, 0 = water
% pictype = [ones(length(PICS.in.hi),1); zeros(20,1)];
pictype = [ones(40,1); repmat(2,40,1); zeros(20,1)];

%Make long list of randomized #s to represent each pic
% piclist = [randperm(length(PICS.in.hi))'; randperm(length(neutpics))'];
piclist = [randperm(40)'; randperm(40)'; randperm(20)'];


%Concatenate these into a long list of trial types.
trial_types = [pictype piclist];
shuffled = trial_types(randperm(size(trial_types,1)),:);

jitter = BalanceTrials(STIM.totes,1,STIM.jitter);

 for x = 1:STIM.blocks
     for y = 1:STIM.trials;
         tc = (x-1)*STIM.trials + y;
         SimpExp.data(tc).pictype = shuffled(tc,1);
         if shuffled(tc,1) == 1
            SimpExp.data(tc).picname = PICS.in.hi(shuffled(tc,2)).name;
         elseif shuffled(tc,1) == 0
             SimpExp.data(tc).picname = neutpics(shuffled(tc,2)).name;
         elseif shuffled(tc,1) == 2;
             SimpExp.data(tc).picname = PICS.in.lo(shuffled(tc,2)).name;
         end
         SimpExp.data(tc).jitter = jitter(tc);
         SimpExp.data(tc).fix_onset = NaN;
         SimpExp.data(tc).pic_onset = NaN;
     end
 end

    SimpExp.info.ID = ID;
    SimpExp.info.date = sprintf('%s %2.0f:%02.0f',date,d(4),d(5));
    


commandwindow;


%%
%change this to 0 to fill whole screen
DEBUG=0;

%set up the screen and dimensions

%list all the screens, then just pick the last one in the list (if you have
%only 1 monitor, then it just chooses that one)
Screen('Preference', 'SkipSyncTests', 1);

screenNumber=max(Screen('Screens'));

if DEBUG==1;
    %create a rect for the screen
    winRect=[0 0 640 480];
    %establish the center points
    XCENTER=320;
    YCENTER=240;
else
    %change screen resolution
%     Screen('Resolution',0,1024,768,[],32);
    
    %this gives the x and y dimensions of our screen, in pixels.
    [swidth, sheight] = Screen('WindowSize', screenNumber);
    XCENTER=fix(swidth/2);
    YCENTER=fix(sheight/2);
    %when you leave winRect blank, it just fills the whole screen
    winRect=[];
end

%open a window on that monitor. 32 refers to 32 bit color depth (millions of
%colors), winRect will either be a 1024x768 box, or the whole screen. The
%function returns a window "w", and a rect that represents the whole
%screen. 
[w, wRect]=Screen('OpenWindow', screenNumber, 0,winRect,32,2);

%%
%you can set the font sizes and styles here
Screen('TextFont', w, 'Arial');
%Screen('TextStyle', w, 1);
Screen('TextSize',w,30);

KbName('UnifyKeyNames');

%% Where should pics go
% STIM.framerect = [XCENTER-300; YCENTER-300; XCENTER+300; YCENTER+300];

%% fMRI Synch

if fmri == 1;
    DrawFormattedText(w,'Synching with fMRI: Waiting for trigger','center','center',COLORS.WHITE);
    Screen('Flip',w);
    
    scan_sec = KbTriggerWait(KEY.trigger,xkeys);
else
    scan_sec = GetSecs();
end

%% Initial screen
% DrawFormattedText(w,'Welcome to the Dot-Probe Task.\nPress any key to continue.','center','center',COLORS.WHITE,[],[],[],1.5);
% Screen('Flip',w);
% KbWait();


for block = 1:STIM.blocks
    for trial = 1:STIM.trials
        tcounter = (block-1)*STIM.trials + trial;
        tpx = imread(getfield(SimpExp,'data',{tcounter},'picname'));
        texture = Screen('MakeTexture',w,tpx);
        
        DrawFormattedText(w,'+','center','center',COLORS.WHITE);
        fixon = Screen('Flip',w);
        SimpExp.data(tcounter).fix_onset = fixon - scan_sec;
        WaitSecs(SimpExp.data(tcounter).jitter);
        
        Screen('DrawTexture',w,texture);
        picon = Screen('Flip',w);
        SimpExp.data(tcounter).pic_onset = picon - scan_sec;
        WaitSecs(STIM.trialdur);
        
    end
    
    
    DrawFormattedText(w,'Press any key to continue','center',wRect(4)*9/10,COLORS.WHITE);
    Screen('Flip',w);
    KbWait();
    
end

%% Save all the data

%Export GNG to text and save with subject number.
%find the mfilesdir by figuring out where show_faces.m is kept

%get the parent directory, which is one level up from mfilesdir
savedir = [mdir filesep 'Results' filesep];

if exist(savedir,'dir') == 0;
    % If savedir (the directory to save files in) does not exist, make it.
    mkdir(savedir);
end

try

save([savedir 'SimpExp_' num2str(ID) '_' num2str(SESS) '.mat'],'SimpExp');

catch
    error('Although data was (most likely) collected, file was not properly saved. 1. Right click on variable in right-hand side of screen. 2. Save as SST_#_#.mat where first # is participant ID and second is session #. If you are still unsure what to do, contact your boss, Kim Martin, or Erik Knight (elk@uoregon.edu).')
end

DrawFormattedText(w,'That concludes this task.','center','center',COLORS.WHITE);
Screen('Flip', w);
WaitSecs(10);

sca

end
