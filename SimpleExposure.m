function SimpleExposure(varargin)

global KEY COLORS w wRect XCENTER YCENTER PICS STIM SimpExp trial pahandle

prompt={'SUBJECT ID'};
defAns={'4444'};

answer=inputdlg(prompt,'Please input subject info',1,defAns);

ID=str2double(answer{1});
% COND = str2double(answer{2});
% SESS = str2double(answer{3});
% prac = str2double(answer{4});


rng(ID); %Seed random number generator with subject ID
d = clock;

KEY = struct;
KEY.rt = KbName('SPACE');
KEY.left = KbName('c');
KEY.right = KbName('m');


COLORS = struct;
COLORS.BLACK = [0 0 0];
COLORS.WHITE = [255 255 255];
COLORS.RED = [255 0 0];
COLORS.BLUE = [0 0 255];
COLORS.GREEN = [0 255 0];
COLORS.YELLOW = [255 255 0];
COLORS.rect = COLORS.GREEN;

STIM = struct;
STIM.blocks = 5;
STIM.trials = 20;
STIM.totes = STIM.blocks*STIM.trials;
STIM.trialdur = 5;
STIM.jitter = [2 3 4];


%% Find & load in pics
%find the image directory by figuring out where the .m is kept
[mdir,~,~] = fileparts(which('SimpleExposure.m');

[ratedir,~,~] = fileparts(which('PicRatings_U4ED.m'));
picratefolder = fullfile(ratedir,'Results');
imgdir = fullfile(ratedir,'Pics');

try
    cd(picratefolder)
catch
    error('Could not find and/or open the folder that contains the image ratings.');
end

filen = sprintf('PicRate_%d.mat',ID);
try
    p = open(filen);
catch
    warning('Could not find and/or open the rating file.');
    commandwindow;
    randopics = input('Would you like to continue with a random selection of images? [1 = Yes, 0 = No]');
    if randopics == 1
        cd(imgdir)
        p = struct;
        p.PicRating_U4ED = dir('Unhealthy*');

    else
        error('Task cannot proceed without images. Contact Erik (elk@uoregon.edu) if you have continued problems.')
    end
    
end

cd(imgdir);
 


PICS =struct;

    PICS.in.hi = struct('name',{p.PicRating_U4ED(1:80).name}');
    PICS.in.neut = dir('water*');

%Check if pictures are present. If not, throw error.
%Could be updated to search computer to look for pics...
if isempty(PICS.in.neut) || isempty(PICS.in.hi) %|| isempty(PICS.in.neut)
    error('Could not find pics. Please ensure pictures are found in a folder names IMAGES within the folder containing the .m task file.');
end

%% Fill in rest of pertinent info
SimpExp = struct;

%1 = food, 0 = water
pictype = [ones(length(PICS.in.hi),1); zeros(20,1)];

%Make long list of randomized #s to represent each pic
piclist = [randperm(length(PICS.in.hi)); randperm(length(PICS.in.neut))];

%Concatenate these into a long list of trial types.
trial_types = [pictype piclist];
shuffled = trial_types(randperm(size(trial_types,1)),:);

jitter = BalanceTrials(STIM.totes,1,STIM.jitter);

 for x = 1:STIM.blocks
     for y = 1:STIM.trials;
         tc = (x-1)*STIM.trials + y;
         SimpExp.data(tc).pictype = shuffled(tc,1);
         if shuffled(tc,1) == 1
            SimpExp.data(tc).picname = PICS.in.hi(shuffled(tc,2));
         elseif shuffled(tc,1) == 0
             SimpExp.data(tc).picname = PICS.in.neut(shuffled(tc,2)).name;
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

%% Initial screen
% DrawFormattedText(w,'Welcome to the Dot-Probe Task.\nPress any key to continue.','center','center',COLORS.WHITE,[],[],[],1.5);
% Screen('Flip',w);
% KbWait();


for block = 1:STIM.blocks
    for trial = 1:STIM.trials
        tcounter = (x-1)*STIM.trials + y;
        tpx = imread(getfield(SimpExp.data(tcounter).picname));
        texture = Screen('MakeTexture',w,tpx);
        
        DrawFormattedText(w,'+','center','center',COLORS.WHITE);
        Screen('Flip',w);
        WaitSecs(SimpExp.data(tc).jitter);
        
        Screen('DrawTexture',w,texture);
        Screen('Flip',w);
        WaitSecs(STIM.trialdur);
        
    end
    
    
    DrawFormattedText(w,'Press any key to continue','center',wRect(4)*9/10,COLORS.WHITE);
    Screen('Flip',w);
    KbWait();
    
end

%% Save all the data

%Export GNG to text and save with subject number.
%find the mfilesdir by figuring out where show_faces.m is kept
[mfilesdir,~,~] = fileparts(which('DotProbe_Training.m'));

%get the parent directory, which is one level up from mfilesdir
savedir = [mfilesdir filesep 'Results' filesep];

if exist(savedir,'dir') == 0;
    % If savedir (the directory to save files in) does not exist, make it.
    mkdir(savedir);
end

try

save([savedir 'SimpExp_' num2str(ID) '_' num2str(SESS) '.mat'],'SimpExp');

catch
    error('Although data was (most likely) collected, file was not properly saved. 1. Right click on variable in right-hand side of screen. 2. Save as SST_#_#.mat where first # is participant ID and second is session #. If you are still unsure what to do, contact your boss, Kim Martin, or Erik Knight (elk@uoregon.edu).')
end

DrawFormattedText(w,'Thank you for participating\n in the Dot Probe Task!','center','center',COLORS.WHITE);
Screen('Flip', w);
WaitSecs(10);

%Clear everything except data structure
clearvar -except SimpExp

sca

end

%%
function [trial_rt, correct] = DoDotProbeTraining(trial,block,varargin)

global w STIM PICS COLORS SimpExp KEY pahandle

correct = -999;                         %Set/reset "correct" to -999 at start of every trial
lr = SimpExp.var.lr(trial,block);           %Bring in L/R location for probe; 1 = L, 2 = R

if lr == 1;                             %set up response keys for probe (& not picture)
    corr_respkey = KEY.left;
    incorr_respkey = KEY.right;
    notlr = 2;
else
    corr_respkey = KEY.right;
    incorr_respkey = KEY.left;
    notlr = 1;
end

%Display fixation for 500 ms
DrawFormattedText(w,'+','center','center',COLORS.WHITE);
Screen('Flip',w);
WaitSecs(.5);                              %Jitter this for fMRI purposes.

if SimpExp.var.cprobe(trial,block)== 1;
    %If this is a counter-probe trial, draw hi cal food where probe will appear.
    Screen('DrawTexture',w,PICS.out(trial).texture_lo,[],STIM.img(notlr,:));    
    Screen('DrawTexture',w,PICS.out(trial).texture_hi,[],STIM.img(lr,:));
else
    %Otherwise, draw lo cal food where probe will appear.
    Screen('DrawTexture',w,PICS.out(trial).texture_lo,[],STIM.img(lr,:));
    Screen('DrawTexture',w,PICS.out(trial).texture_hi,[],STIM.img(notlr,:));
end

    Screen('Flip',w);
    WaitSecs(.5);                   %Display pics for 500 ms before dot probe 
    
    Screen('FillOval',w,COLORS.WHITE,STIM.probe(lr,:));
    RT_start = Screen('Flip',w);
    if SimpExp.var.signal(trial, block) == 1;
        PsychPortAudio('Start', pahandle, 1);
        % XXX: Delay between probe & signal onset?
    end
    telap = GetSecs() - RT_start;


    while telap <= (STIM.trialdur - .500); %XXX: What is full trial duration?
        telap = GetSecs() - RT_start;
        [Down, ~, Code] = KbCheck();            %wait for key to be pressed
        if Down == 1 
            if any(find(Code) == corr_respkey);
                trial_rt = GetSecs() - RT_start;
            
                if SimpExp.var.signal(trial,block) == 1;        %This is a no-go signal round. Throw incorrect X.
                    DrawFormattedText(w,'X','center','center',COLORS.RED);
                    Screen('Flip',w);
                    correct = 0;
                    WaitSecs(.5);

                else                                        %If no signal + Press, move on to next round.
                    Screen('Flip',w);                        %'Flip' in order to clear buffer; next flip (in main script) flips to black screen.
                    correct = 1;
                
                end
            break    
            
            elseif any(find(Code) == incorr_respkey) %The wrong key was pressed. Throw X regardless of Go/No Go
                trial_rt = GetSecs() - RT_start;
                
                DrawFormattedText(w,'X','center','center',COLORS.RED);
                Screen('Flip',w);
                correct = 0;
                WaitSecs(.5);
                break
            else
                FlushEvents();
            end
        end
        
        
    end
    
    if correct == -999;
%     Screen('DrawTexture',w,PICS.out(trial).texture,[],STIM.img(lr,:));
        
        if SimpExp.var.signal(trial,block) == 1;    %NoGo Trial + Correct no press. Do nothing, move to inter-trial
            Screen('Flip',w);                   %'Flip' in order to clear buffer; next flip (in main script) flips to black screen.
            correct = 1;
        else                                    %Incorrect no press. Show "X" for .5 sec.
            DrawFormattedText(w,'X','center','center',COLORS.RED);
            Screen('Flip',w);
            correct = 0;
            WaitSecs(.5);
        end
        trial_rt = -999;                        %No press = no RT
    end
    

FlushEvents();
end

%%
function DrawPics4Block(block,varargin)

global PICS SimpExp w STIM

    for j = 1:STIM.trials;
        %Get pic # for given trial's hi & low cal food
        pic_hi = SimpExp.var.picnum_hi(j,block);
        pic_lo = SimpExp.var.picnum_lo(j,block);
        PICS.out(j).raw_hi = imread(getfield(PICS,'in','hi',{pic_hi},'name'));
        PICS.out(j).raw_lo = imread(getfield(PICS,'in','lo',{pic_lo},'name'));
        PICS.out(j).texture_hi = Screen('MakeTexture',w,PICS.out(j).raw_hi);
        PICS.out(j).texture_lo = Screen('MakeTexture',w,PICS.out(j).raw_lo);
        
%         switch SimpExp.var.trial_type(j,block)
%             case {1}
%                 PICS.out(j).raw = imread(getfield(PICS,'in','go',{pic},'name'));
% %                 %I think this is is covered outside of switch/case
% %                 PICS.out(j).texture = Screen('MakeTexture',w,PICS.out(j).raw);
%             case {2}
%                 PICS.out(j).raw = imread(getfield(PICS,'in','no',{pic},'name'));
%             case {3}
%                 PICS.out(j).raw = imread(getfield(PICS,'in','neut',{pic},'name'));
%         end
    end
%end
end

