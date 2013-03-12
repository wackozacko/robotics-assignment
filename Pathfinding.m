function [Path] = Pathfinding(M,P1,P2)
    %PATHFINDING Finds the shortest path between two points.
    %   Takes a map of type M=[X1,Y1;X2,Y2;...XN-1,YN-1], a start
    %   point P1=[X,Y] and an end point P2=[X,Y] and returns a set of points that
    %   are the shortest path to get from P1 to P2.

    ROBOTWIDTH = 15;
    Path = [];
    Graph = [];

    hold all
    plot(M(:,1),M(:,2))

    % Define lines from points
    M1 = circshift(M,1);
    Lines = [M1(:,1) - M(:,1), M1(:,2) - M(:,2)];

    % Find normals
    Normals = [Lines(:,2),0-Lines(:,1)];
    Normals = sign(Normals) * ROBOTWIDTH;

    % Add normals to both points at either end of line to make new navigation
    % area
    N1 = circshift(Normals,-1);
    Nav = M + Normals + N1;
    fill(Nav(:,1),Nav(:,2),[0.63,1,0.67])

    % Make a list of nodes for pathfinding
    Nodes = [P1; Nav; P2];
    for i=1:length(Nodes)
        text(Nodes(i,1)-1,Nodes(i,2)-1,num2str(i));
    end

    % Make navigation mesh
    Nav1 = circshift(Nav,1);
    NavMesh = [Nav(:,1),Nav(:,2),Nav1(:,1),Nav1(:,2)];
    
    % For each node find paths to every other visible node
    for i=1:length(Nav)
        % Make lines from current node to every node in map
        currentNodeRepeated = repmat(Nodes(i,:),length(Nodes(:,1)),1);
        lines = [Nodes(:,1),Nodes(:,2),currentNodeRepeated(:,1),currentNodeRepeated(:,2)];

        intersections = lineSegmentIntersect(lines,NavMesh);                    % Check for intersections

        % For each line, check it's intersection points and whether it can be
        % added to the graph
        for j=2:length(lines)
            cp = [intersections.intMatrixX(j,:);intersections.intMatrixY(j,:)]';% Make matrix of collision points
            cp(ismember(cp,Nav,'rows'),:) = 0;                                  % Remove actual map points
            cp(all(isnan(cp),2),:) = 0;                                         % Remove NAN rows
            
            center = [(lines(j,3) - lines(j,1))/2 + lines(j,1),                 % Find center point of each line
                (lines(j,4) - lines(j,2))/2 + lines(j,2)];
            [in on] = inpolygon(center(1),center(2),Nav(:,1),Nav(:,2));         % Find whether the center is actually within the navigation mesh
            cp(on)=0;                                                           % Include lines that are incident with navigation mesh edges

            if(all(cp==0))                                                      % If all elements are zero
                if(in==1)                                                       % If the center does lie within the navigation mesh
                    lineReverse = [lines(j,3:4),lines(j,1:2)];                  % Reverse the line
                    if(~ismember(lineReverse,Graph,'rows'))                     % If the reverse isn't already included in the graph
                        Graph = [Graph; lines(j,:)];                            % Add this line to the graph
                        plot([lines(j,1),lines(j,3)],[lines(j,2),lines(j,4)],'-m');
                    end
                end
            end
        end
    end
    
    Graph(all(Graph(:,1:2)==Graph(:,3:4),2),:) = [];                            % Remove connections from nodes to themselves
    
    distances = sqrt((Graph(:,1)-Graph(:,3)).^2 + (Graph(:,2)-Graph(:,4)).^2);  % Calculate distances of all lines in graph
    
    % Now just run Dijkstra's algorithm to find the optimal path
    dijkstra(Graph, Nodes, distances);

    % plot(P1(1,1),P1(1,2),'*r')
    % plot(P2(1,1),P2(1,2),'*r')

end