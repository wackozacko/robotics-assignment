clear all
figure(10)
hold on
%%%%%%%%%%%%%%%%%%%%%%%%%% INITIALISATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%-------------------------Map definition-----------------------------------

M=[0,0;60,0;60,45;45,45;45,59;106,59;106,105;0,105]
T=[10,80];
S=[30,30];
step=10;

%-------------------------Robot simulation---------------------------------
step=10; %length of step in cm
RealRobot=RobotModel(S(1),S(2), pi/2);%robot use for simulating captor
         plot(RealRobot.x,RealRobot.y,'or');
KnowRobot=RobotModel(0,0,0); %Robot use for pathfinding
                ToGo=[10,80]; %REMOVE WHEN PATHFINDING WORK
%-------------------------Error particles----------------------------------
transstd=0.5; % translation standard deviation in cm
orientstd=1.5; % orientation standard deviation in degrees
Wgtthreshold= 0.25; % relative limit to keep the particles 
dump =0; %anti dumping coef
ScanLarge=4; % how far the resample particle are randomly distributed aroud heavy solution in space
ScanTheta=0.5; % how far the resample particle are randomly distributed aroud heavy solution in space
%-------------------------------Sensor------------------------------------
nbmeasure = 5; %number of measurement
sensorstd = 15; % error of sensor for calculation
sensorstdReal = 0%5;%real error of sensor 
%----------------------- initialisation of the particles-------------------
xyRes = 10;
ThetaRes = 36;

MaxX = max(M(:,1));
MaxY = max(M(:,2));
%1/ build a matrice of the position in a square 0,0,MaxX, MaxY
clear PosSquare
a=round(MaxY/xyRes);
for i =1: round(MaxX/xyRes)
    for j =1:round(MaxY/xyRes)
        posSquarex(j + a*(i-1) ) = i*xyRes;
        posSquarey(j + a*(i-1) ) = j*xyRes;
    end
end

%2/keep those on the map
InArena=inpolygon(posSquarex,posSquarey,M(:,1),M(:,2));

%3/initialise particles at each point in the map
k=0;
for i=1:round(MaxX/xyRes)*round(MaxY/xyRes)
    if InArena(i) == 1
        for j=1:round(360/ThetaRes)
            k=k+1;
            x(k)=posSquarex(i);
            y(k)=posSquarey(i);
            theta(k)= j*ThetaRes*pi/180;
        end
    end
end

nparticles = k
plot(x,y,'+')


%1/Weight
for i=1:nparticles
    w(i)=1/nparticles;
end
%2/position and orientation
%   (uniform distribution in the smallest square containig the map)

 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END INITIALISATION %%%%%%%%%%%%%%%%%%%%%%%%%%
move=0;
moveTheta=0;
stop = false
while stop == false, % number of steps
    
    %%%%%%%%%%%%%%%%%%%%%%%%%   ROBOT   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %-----Reading Robot sensor----------
    sensorRobot =sense(RealRobot,M,nbmeasure); % distance from 0 to a fictional wall + error
    sensorRobot
    for h=1:nbmeasure
        sensorRobot(h) = sensorRobot(h) + sensorstdReal* randn(1,1);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%    PARTICLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    for j=1:nparticles %repet times number of particles
        
        %-------------------------- Move particles ------------------------
        e = 0 + transstd*randn(1,1); %random Gaussian number with mean 0 and std transstd
        f = 0 + (orientstd*(pi/180)).*randn(1,1); %random Gaussian number with mean 0 and std orienstd
        theta(j)=theta(j)+moveTheta+f;
        x(j)=x(j)+(move+e)*cos(theta(j));
        y(j)=y(j)+(move+e)*sin(theta(j));
    end
        

        %--------------------------Weight of the particles-----------------
        %0/detect the particles out of the map
        InArena=inpolygon(x,y,M(:,1),M(:,2));
        %1/ p(z/x)* p(x)
     
    for j=1:nparticles 
        if InArena(j) == 1 % calculate weight only if the particles is in the map
            sensorParticles = senseParticles(x(j),y(j),theta(j),M,nbmeasure);
            wBefore=w(j);
            w(j)=1;
            for k = 1:nbmeasure %for each measure
                 w(j)= 1/sqrt(2*pi*sensorstd^2) * exp(- (sensorParticles(k) - sensorRobot(k))^2 /(2*sensorstd^2 + dump) ) * w(j);
            end
            w(j)=wBefore*w(j);
        else
            w(j) =0;
        end
        
    end

    %------------------------- Normalisation of particles -----------------
    S=sum(w);
    w=w/S;

    %------------------------- Resampling ---------------------------------

    %1/detect the heavy and in the map particles to keep
    keep = zeros(0);
    resamp = zeros(0);
    k=1;
    m=1;
    %Normalize the threshold
    MaxWeight = max(w);
    AbsThreshold = Wgtthreshold*MaxWeight;
    for j =1:nparticles
        if (w(j) > AbsThreshold) 
            keep(k) =j; %record the position of the heavy particles
            k= k+1;
        else
            resamp(m)=j;
            m= m+1;
        end
    end
    disp('keep = ');
    disp(length(keep));
    %3/resample around heavy particles with the same weight than the assign
    %particles. If keep is empty we are lost and make a random distribution
    %one again
    if k>1 % keep is not empty
        for j=1:length(resamp)
            x(resamp(j))=x(keep(mod(j,length(keep))+1)) + ScanLarge*rand(1,1)*transstd;
            y(resamp(j))=y(keep(mod(j,length(keep))+1)) + ScanLarge*rand(1,1)*transstd;
            theta(resamp(j))=theta(keep(mod(j,length(keep))+1)) + ScanTheta*rand(1,1)*orientstd;
            w(resamp(j))=w(keep(mod(j,length(keep))+1));
        end
    else %(keep is empty)
        x = unifrnd(0,MaxX,1,nparticles); 
        y = unifrnd(10,MaxY,1,nparticles);
        theta = unifrnd(0,2*pi,1,nparticles);
        for m=1:nparticles
             w(m)=1/nparticles;
        end
    end

    %3/ We need to re normalise the weight
    S=sum(w);
    for j=1:nparticles
        w(j)=w(j)/S;
    end
 %%%%%%%%%%%%%%%%%%%%%%%%%   ROBOT MOVE  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %-----------------------  change position  ------------------------------
  [~,MaxInd]=max(w); %MaxInd is the indice of the heaviest particle
  KnowRobot=RobotModel(x(MaxInd),y(MaxInd),theta(MaxInd));
  
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  waitforbuttonpress; % enable to plot step by step
  hold on
  plot(M(:,1),M(:,2));  %map 
  plot(T(1),T(2),'*r'); %plot goal
  plot(x,y,'b+');       %particles
  plot(KnowRobot.x,KnowRobot.y,'xr');   %know position of the robot  
  plot(RealRobot.x,RealRobot.y,'or');   %True position 
 perc =  acuracy(x,y,KnowRobot.x,KnowRobot.y,nparticles,5)

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%
    
  %-----------------------  Path finding  ---------------------------------
 %%%%%%%%%%%%%%%%%%%%%%%%clear ToGo;
 %%%%%%%%%%%%%%%%%%%%%%%%ToGo = Pathfinding(M,[KnowRobot.x,KnowRobot.y],goal);
  %-----------------------  Motion  ---------------------------------------

  dist= sqrt( (ToGo(1,1)-KnowRobot.x)^2 + (ToGo(1,2)-KnowRobot.y)^2 )  
  if dist > step
      xgo= (ToGo(1,1)-KnowRobot.x)*step/dist + KnowRobot.x
      ygo= (ToGo(1,2)-KnowRobot.y)*step/dist + KnowRobot.y
      [move,moveTheta] = goto(KnowRobot,xgo,ygo)% go to the next position. move and moveTheta are used for the  particles filters
  else
      [move,moveTheta] = goto(KnowRobot,ToGo(1,1),ToGo(1,2));
  end
%------------------------ Simulated real  robot----------------------------
left(RealRobot,moveTheta);
forward(RealRobot,move);
                                                                             
end