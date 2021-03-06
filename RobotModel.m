classdef RobotModel < handle
    %ROBOTMODEL Handles the simulated model of the robot and provides
    %functions for moving the robot around.

    % Radians are used throughout the class
    % Duplicate functions are provided if degrees are desired
    % BOTTOM LEFT IS (0,0)
    % 0 DEGREES IS THE POSITIVE X DIRECTION. E.G. THETA IS POSITIVE FROM X
    % http://www.mathworks.co.uk/help/matlab/ref/pol2cart.html

    properties (SetAccess = private)
        x = 0;
        y = 0;
        theta = 0;
        
        sensorError = 0;
    end

    methods (Access = private)
        function move(RM,dist,rads)
            RM.x = RM.x + dist*cos(rads);
            RM.y = RM.y + dist*sin(rads);
        end
    end

    methods
        function RM = RobotModel(x,y,theta)                                     % Constructor
            RM.x = x;
            RM.y = y;
            RM.theta = theta;
        end

        function forward(RM,dist)
            RM.move(dist,RM.theta);                                             % Move in that direction
        end

        function backward(RM,dist)
            rads = RM.theta;
            if rads < 0                                                         % Temporarily reverse direction
                rads = pi + rads;
            else
                rads = rads - pi;
            end
            RM.move(dist,rads);                                                 % Move in that direction
        end

        function right(RM,rads)
            RM.theta = RM.theta - rads;                                         % Subtract the degrees of rotation
            if RM.theta < -pi                                                   % If the angle is less than minus pi (i.e. passed beyond the negative x direction)
                RM.theta = (2*pi) + RM.theta;                                   % Add to 2pi
            end
            if RM.theta > pi                                                   % If the angle is less than minus pi (i.e. passed beyond the negative x direction)
                RM.theta = (2*pi) - RM.theta;                                   % Add to 2pi
            end
        end

        function rightd(RM,degrees)
            RM.right(degtorad(degrees));                                        % Call right with degrees converted to radians
        end

        function left(RM,deg)
            RM.theta = RM.theta + deg;                                          % Add the dgrees of rotation
            if RM.theta > pi                                                    % If the angle is now more than pi
                RM.theta = RM.theta - (2*pi);                                   % Subtract 2pi
            end
            if RM.theta < -pi                                                   % If the angle is less than minus pi (i.e. passed beyond the negative x direction)
                RM.theta = (2*pi) + RM.theta;                                   % Add to 2pi
            end
        end

        function leftd(RM,degrees)
            RM.left(degtorad(degrees));                                         % Call left with degrees converted to radians
        end

        function [dist,rotate]= goto(RM,newX,newY)
            distX = newX-RM.x;                                                  % Identify the distance to travel in X
            distY = newY-RM.y;                                                  % Identify the distance to travel in Y
            dist = sqrt(distX^2+distY^2);                                       % Identify the direct distance to travel
            newAngle = atan2(distY,distX)                                      % Mark the new angle the robot must face (returns angle in radians)
            rotate = newAngle - RM.theta                                       % Subtract the current angle from the intended angle

            if rotate < -pi                                                     % Keep the values of rotate between pi and -pi
                rotate = (2*pi) + rotate;
            end
            if rotate > pi
                rotate = rotate - (2*pi);
            end

            if rotate < 0                                                      % Determine which direction to turn and then rotate
                RM.right(abs(rotate));
                disp(['Turn right ',num2str(rotate),' degrees.']);
            else
                RM.left(abs(rotate));
                disp(['Turn left ',num2str(rotate),' degrees.']);
            end

            RM.move(dist,RM.theta);                                             % Move in that direction
            disp(['Move forward ',num2str(dist),'.']);
            hold on;
      %      plot(RM.x,RM.y,'rx');
        end
        
        function [out] = sense(RM,M,numreadings)
            M1 = circshift(M,1);                                                % Shift M circularly by one
            XY1 = [M(:,1),M(:,2),M1(:,1),M1(:,2)];                              % Form new matrix of each element in M with the next element
            
            angleChange = (2*pi)/numreadings;                                   % Calculate the change in angle according to the number of readings requested
            angle = RM.theta;                                                        % Starting angle is -pi (relative to robot this would be backwards)
            out = zeros(1,numreadings);
            for m=1:numreadings                                                 % For each reading
                out(m) = RM.senseSingle(XY1,angle);                             % Take a sensor measurement
                angle = angle + angleChange;                                    % Adjust the angle of the next measurement
            end
            
            %figure(2);
            %hold on;
            %plot(0:numreadings-1,out,'*');
            %coefs = polyfit(0:numreadings-1,out,numreadings/2);                 % These two linesplot a polynomial of degree numreadings/2that best fits the point already on the graph
            %plot(0:0.1:numreadings-1,polyval(coefs,0:0.1:numreadings-1),'-r');
        end
        
        function [out] = senseSingle(RM,XY1,angle)
            RayX = 200*cos(angle) + RM.x;                                       % Calculate the ray vector
            RayY = 200*sin(angle) + RM.y;
            
            XY2 = [RM.x,RM.y,RayX,RayY];                                        % The scan ray
            result = lineSegmentIntersect(XY1,XY2);

            Dist = zeros(0,1);
            n=0;
            for i=1:length(XY1(:,1))
                if result.intAdjacencyMatrix(i) == 1                            % If there is a collision
                    n=n+1;                                                      % Increment the counter and calculate the distance from the robot to the collision
                    Dist(n) = sqrt((result.intMatrixX(i)-RM.x)^2 + (result.intMatrixY(i)-RM.y)^2);
                end
            end

            intersectX = min(Dist)*cos(angle) + RM.x;                           % Find the point of intersection
            intersectY = min(Dist)*sin(angle) + RM.y;
            %hold on
            %plot([RM.x,intersectX],[RM.y,intersectY],'--r');                    % Plot the ray to the point
            %plot(intersectX,intersectY,'-ro');                                  % Plot the point
            
            out = min(Dist);
        end

        function show(RM)
            disp(['X=',num2str(RM.x),' : Y=', num2str(RM.y),' : Theta=',num2str(RM.theta)]);
        end

        function showd(RM)
            disp(['X=',num2str(RM.x),' : Y=', num2str(RM.y),' : Theta=',num2str(radtodeg(RM.theta))]);
        end
    end
end