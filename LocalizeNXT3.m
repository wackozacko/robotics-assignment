clear all
figure(10)
hold on
%%%%%%%%%%%%%%%%%%%%%%%%%% INITIALISATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%-------------------------Map definition-----------------------------------

M=[0,0;60,0;60,45;45,45;45,59;106,59;106,105;0,105]
<<<<<<< HEAD
T=[25,80];
=======
T=[80,80];
>>>>>>> ebcf58e76e83b3a70b47f01142b21d9a08f77bb0
S=[25,25];
step=10;
nextstep = T;

%-------------------------Robot simulation---------------------------------
step=10; %length of step in cm
nxt = NXTRobot(0,0,0);
nxt.initAll();
%AssumeRobot=RobotModel(0,0,-10.45); %Robot use for pathfinding
AssumeRobot=RobotModel(0,0,pi/2);
%                ToGo=[30,80]; %REMOVE WHEN PATHFINDING WORK
%-------------------------Error particles----------------------------------
<<<<<<< HEAD
transstd=0.5; % translation standard deviation in cm
orientstd=0.5; % orientation standard deviation in degrees
Wgtthreshold= 0.10; % relative limit to keep the particles 
dump =0; %anti dumping coef 0 => no anti dumping ; 1=> dumping
ScanLarge=3; % how far the resample particle are randomly distributed aroud heavy solution in space
ScanTheta=0.8; % how far the resample particle are randomly distributed aroud heavy solution in space
dist =100; %number of particale that beneficiat of the linear resample( heavy =. more particle in linear way)
lostthreshold=0;%10e-8;
=======
transstd=5; % translation standard deviation in cm
orientstd=3; % orientation standard deviation in degrees
Wgtthreshold= 0.30; % relative limit to keep the particles 
dump =0; %anti dumping coef 0 => no anti dumping ; 1=> dumping
ScanLarge=0; % how far the resample particle are randomly distributed aroud heavy solution in space
ScanTheta=0; % how far the resample particle are randomly distributed aroud heavy solution in space
dist =100; %number of particale that beneficiat of the linear resample( heavy =. more particle in linear way)
lostthreshold=8e-10;
>>>>>>> ebcf58e76e83b3a70b47f01142b21d9a08f77bb0
%-------------------------------Sensor------------------------------------
nbmeasure = 5; %number of measurement
sensorstd = 3; % error of sensor for calculation
sensorstdReal = 0;%5;%real error of sensor 
%----------------------- initialisation of the particles-------------------
<<<<<<< HEAD
xyRes = 8;
=======
xyRes = 6;
>>>>>>> ebcf58e76e83b3a70b47f01142b21d9a08f77bb0
ThetaRes = 50;
[x,y,w,theta,nparticles] = Normal_sample(xyRes, ThetaRes,M);    
%------------------------------- plot -----------------------------------


%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END INITIALISATION %%%%%%%%%%%%%%%%%%%%%%%%%%


move=0;
moveTheta=0;
stop = false;
nbstep=0;
while stop == false, % number of steps
    
    %%%%%%%%%%%%%%%%%%%%%%%%%   ROBOT   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    lost = true; % Just to enter the loop
    lost1 =false;
    while (lost == true)
        %-----Reading Robot sensor----------
        [sensorRobot angleError] = nxt.sense(nbmeasure,60);
        %sensorRobot = sense(RealRobot,M,nbmeasure); % distance from 0 to a fictional wall + error
%         for h=1:nbmeasure
%             sensorRobot(h) = sensorRobot(h) + sensorstdReal* randn(1,1);
%         end
        %%%%%%%%%%%%%%%%%%%%%%%%    PARTICLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %angleError=zeros(nbmeasure,1);
        [x,y,theta,w] = weight_and_move_prt(x,y,theta,w,M,nparticles,transstd,orientstd,nbmeasure,sensorstd,move,moveTheta,sensorRobot,dump,angleError);
<<<<<<< HEAD
        Maxweight= max(w); % absolute weight to see if the robot is lost
=======
        Maxweight= max(w) % absolute weight to see if the robot is lost
>>>>>>> ebcf58e76e83b3a70b47f01142b21d9a08f77bb0
        %------------------------- Normalisation of particles -----------------
        S=sum(w);
        w=w/S;
        %detect if lost
        if Maxweight < 1/nparticles*lostthreshold
            clear x
            clear y 
            clear theta
            clear w
<<<<<<< HEAD
           [x,y,w,theta,nparticles] = Normal_sample(xyRes, ThetaRes,M);
           if lost1 == true %anti stuck in lost place
               lost=false
           end
           lost1=true
        else
            lost = false;
             %------------------------- Resampling ---------------------------------
=======
            [x,y,w,theta,nparticles] = Normal_sample(xyRes, ThetaRes,M);
            if lost1 == true %anti stuck in lost place
               lost=false;
            end
            lost1=true;
            disp('lost');
        else
            lost = false;
            %------------------------- Resampling ---------------------------------
>>>>>>> ebcf58e76e83b3a70b47f01142b21d9a08f77bb0
            [x,y,theta,w ]=resample(Wgtthreshold,x,y,theta,w,ScanTheta*orientstd,ScanLarge*transstd,dist);
            disp('notlost')
        end
    end
   


 %%%%%%%%%%%%%%%%%%%%%%%%%   ROBOT MOVE  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %-----------------------  change position  ------------------------------
  [~,MaxInd]=max(w); %MaxInd is the indice of the heaviest particle
  AssumeRobot=RobotModel(x(MaxInd),y(MaxInd),theta(MaxInd));
<<<<<<< HEAD
  newPath = Pathfinding(M, [x(MaxInd) y(MaxInd)], T);
=======
  newPath = Pathfinding(M, [x(MaxInd) y(MaxInd)], T)
>>>>>>> ebcf58e76e83b3a70b47f01142b21d9a08f77bb0
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  % enable to plot step by step
  %hold off
  hold on
  waitforbuttonpress
  plot(M(:,1),M(:,2));  %map 
  plot(T(1),T(2),'*r'); %plot goal
  plot(x,y,'b+');    %particles
  plot(AssumeRobot.x,AssumeRobot.y,'xr');%know position of the robot 
  legend('True position','map','goal','paticles');
 

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% xgoEND PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%
    
  %-----------------------  Path finding  ---------------------------------
 %%%%%%%%%%%%%%%%%%%%%%%%clear ToGo;
 %%%%%%%%%%%%%%%%%%%%%%%%ToGo = Pathfinding(M,[KnowRobot.x,KnowRobot.y],goal);
  %-----------------------  Motion  ---------------------------------------
  
  if ~isempty(newPath)
      nextstep = newPath(1,:);
  end
  xold=AssumeRobot.x;
  yold=AssumeRobot.y;
 dist = sqrt( (nextstep(1)-AssumeRobot.x)^2 + (nextstep(2)-AssumeRobot.y)^2 );
  if dist > step % we detect if the robot is near a node of the pathfinding
<<<<<<< HEAD
      disp('flag')
      xgo= (nextstep(1)-AssumeRobot.x)*step/dist + AssumeRobot.x;
      ygo= (nextstep(2)-AssumeRobot.y)*step/dist + AssumeRobot.y;
      [move,moveTheta] = goto(AssumeRobot,xgo,ygo);
=======
      xgo= (nextstep(1)-AssumeRobot.x)*step/dist + AssumeRobot.x;
      ygo= (nextstep(2)-AssumeRobot.y)*step/dist + AssumeRobot.y;
      [move,moveTheta] = goto(AssumeRobot,xgo,ygo)
>>>>>>> ebcf58e76e83b3a70b47f01142b21d9a08f77bb0
%             plot(AssumeRobot.x,AssumeRobot.y,'sr');
  else
 
      xgo= nextstep(1);
      ygo= nextstep(2);
<<<<<<< HEAD
      [move,moveTheta] = goto(AssumeRobot,xgo,ygo);
=======
      [move,moveTheta] = goto(AssumeRobot,xgo,ygo)
>>>>>>> ebcf58e76e83b3a70b47f01142b21d9a08f77bb0
     % plot(AssumeRobot.x,AssumeRobot.y,'sr');

  
  end


%------------------------ Simulated real  robot----------------------------
if moveTheta > 0
    nxt.turnLeft(moveTheta);
elseif moveTheta < 0
    nxt.turnRight(-moveTheta);
end
nxt.forward(move);
    
% left(RealRobot,moveTheta);
% forward(RealRobot,move);
     
% Evaluate if we are arrive
per = Circle_probabilie(T(1),T(2),1.4,x,y,w)
if per > 0.55
    stop = true
end

nbstep=nbstep+1;                                                                           
end
<<<<<<< HEAD
disp('true position');
disp(RealRobot);
disp('nbstep')
disp(nbstep)
disp('offthemark');
disp(sqrt((RealRobot.x - T(1))^2+(RealRobot.y - T(2))^2));
=======
disp('nbstep')
disp(nbstep)
>>>>>>> ebcf58e76e83b3a70b47f01142b21d9a08f77bb0
