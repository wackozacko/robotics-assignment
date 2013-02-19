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
            [plusX,plusY] = pol2cart(rads,dist);                                % Convert from polar coordinates to cartesian
            RM.x = RM.x + plusX;                                                % Increase the x direction
            RM.y = RM.y + plusY;                                                % Increase the y direction
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
        end

        function rightd(RM,degrees)
            RM.right(degtorad(degrees));                                        % Call right with degrees converted to radians
        end

        function left(RM,deg)
            RM.theta = RM.theta + deg;                                          % Add the dgrees of rotation
            if RM.theta > pi                                                    % If the angle is now more than pi
                RM.theta = RM.theta - (2*pi);                                   % Subtract 2pi
            end
        end

        function leftd(RM,degrees)
            RM.left(degtorad(degrees));                                         % Call left with degrees converted to radians
        end

        function goto(RM,newX,newY)
            distX = newX-RM.x;                                                  % Identify the distance to travel in X
            distY = newY-RM.y;                                                  % Identify the distance to travel in Y
            dist = sqrt(distX^2+distY^2);                                       % Identify the direct distance to travel
            newAngle = atan2(distY,distX);                                      % Mark the new angle the robot must face (returns angle in radians)
            rotate = newAngle - RM.theta;                                       % Subtract the current angle from the intended angle

            if rotate < -pi                                                     % Keep the values of rotate between pi and -pi
                rotate = (2*pi) + rotate;
            end
            if rotate > pi
                rotate = rotate - (2*pi);
            end

            if rotate > pi                                                      % Determine which direction to turn and then rotate
                RM.right(rotate);
                disp(['Turn right ',num2str(rotate),' degrees.']);
            else
                RM.left(rotate);
                disp(['Turn left ',num2str(rotate),' degrees.']);
            end

            RM.move(dist,RM.theta);                                             % Move in that direction
            disp(['Move forward ',num2str(dist),'.']);
            hold on;
            plot(RM.x,RM.y,'rx');
        end
        
        function [out] = sense(RM,M,numreadings)
                hold on
            % First reading at theta
            % Each successive previous + pi/4 for 7 more readings
            for n=1:length(M)
                if n == length(M)
                    XY1 = [M(n,1),M(n,2),M(1,1),M(1,2)];
                else
                    XY1 = [M(n,1),M(n,2),M(n+1,1),M(n+1,2)];
                end
                
                RayX = 200*cos(RM.theta) + RM.x;
                RayY = 200*sin(RM.theta) + RM.y;
                plot([RM.x,RayX],[RM.y,RayY],'--r');
                XY2 = [RM.x,RM.y,RayX,RayY];                                % The scan ray
                out = lineSegmentIntersect(XY1,XY2)
                if(out.intAdjacencyMatrix == 1)
                    plot(out.intMatrixX,out.intMatrixY,'-ro');
                end
            end
        end

        function show(RM)
            disp(['X=',num2str(RM.x),' : Y=', num2str(RM.y),' : Theta=',num2str(RM.theta)]);
        end

        function showd(RM)
            disp(['X=',num2str(RM.x),' : Y=', num2str(RM.y),' : Theta=',num2str(radtodeg(RM.theta))]);
        end
    end
end