% Authors: Pooyan Jamshidi and Benedikt Schoenhense
% Imperial College London
% this is the engine for playing the pong game developed for the course
% "424H - Learning in Autonomous Systems" Aldo Faisal

classdef pongEngine < handle
    properties (GetAccess='public',SetAccess='private')
        numRows;
        numColumns;
        
        ball; % vector location
        %score1=0;
        %score2=0;
        actions = {'up','stay','down'};
        twoPlayer = false;
    end
    
    properties (GetAccess='private',SetAccess='private',Hidden)
        velocity;
        pFail = 0.1; % prob of action failing
        pRedir = 0.5; % prob of ball redirecting from paddle
    end
    
    
    properties (GetAccess='public',SetAccess='private',Hidden) % size stuff
        fig_w = 800; %pixels
        fig_h = 480;
        court_w = 150; %width in plot units. this will be main units for program
        court_h = 100; %height
        goal_size = 55;
        goal_up = (100+55)/2;
        goal_low = (100-55)/2;
        wall_w = 3;
        center_r = 15; %radius of the circle
        ball_size = 10;
        paddle_w = 2;
        paddle_h = 17;
        paddle=[];
        paddle_space = 10; %space between paddle and goal
        ball_radius = 1.5; %radius to calculate bouncing
        goal_buffer = 5; % to avoid goal when bouncing close to goal

    end
    
    properties (GetAccess='public',SetAccess='private',Hidden) % game stuff
        max_points = 5;
        kickoff_delay = 1;
        min_ball_speed= 1;
        frame_delay = 0.009;
        ball_acceleration_factor = 0.05; %how much ball accelerates each bounce.
        max_speed = 4; 

    end
    
    properties (GetAccess='private',SetAccess='private',Hidden) % color stuff
        court_color = [.17, .17, .17];
        background_color = [0, 0, 0];
        wall_color = [.3, .3, .8];
        paddle_color = [1, .5, 0];
        center_color = [1, .5, 0] .* .8;
        ball_shape = 'o';
        ball_color = [.1, .7, .1];
        ball_out = [.7, 1, .7];
        title_color = 'w';
    end
    
    properties (GetAccess='public',SetAccess='private',Hidden) % scores
        score = [];
        winner = []; % during game 0. 1 if player1 wins, 2 if player2 wins

    end
    
    properties (GetAccess='public',SetAccess='private',Hidden) % plot handles
        ballPlot = [];
        paddle1Plot = [];
        paddle2Plot = [];
    end
    
    properties (GetAccess='public',SetAccess='private',Hidden) % current positions and move stuff   
        paddle1; % row-index starting at 1, always column 1
        paddle2; % in last column
        ballX = []; %ball location
        ballY = [];
        paddle1V = [];
        paddle2V = [];
        ballSpeed=[];
        ballV=[]; 
    end
    
    
    methods
        function self = pongEngine(n,m) % constructor, can specify size
            if nargin < 2
                n=9; % height
                m=19; % width
            end
            
            
            
            self.numRows = n;
            self.numColumns = m;
            self.paddle1 = ceil(self.numRows/2); % paddle starts central
            self.paddle2 = ceil(self.numRows/2);
            self.ball = [ceil(self.numRows/2), ceil(self.numColumns/2)]; % middle of field
            self.velocity = [randi(3)-2,2*randi(2)-3]; % random initial movement (but not orthogonal)
            
            self.score = [0, 0];
            
            %self.paddle = [0 self.paddle_w self.paddle_w 0 0; self.paddle_h self.paddle_h 0 0 self.paddle_h];
            %self.paddle1 = [self.paddle(1,:)+self.paddle_space; self.paddle(2,:)+((self.court_h - self.paddle_h)/2)];
            %self.paddle2 = [self.paddle(1,:)+ self.court_w - self.paddle_space - self.paddle_w; self.paddle(2,:)+((self.court_h - self.paddle_h)/2)];
        end
        
        function createCourt(self)
            
            scrsz = get(0,'ScreenSize');
            court_handle = figure('Position',[(scrsz(3)-self.fig_w)/2 ...
                (scrsz(4)-self.fig_h)/2 self.fig_w, self.fig_h]);
            % we cannot obviously resize the court!!!
            set(court_handle, 'Resize', 'off');
            axis([0 self.court_w 0 self.court_h]);
            axis manual;
            %set color and hide axis ticks.
            set(gca, 'color', self.court_color, 'YTick', [], 'XTick', []);
            set(court_handle, 'color', self.background_color);
            hold on;
            %plot walls
            topWallXs = [0,0,self.court_w,self.court_w];
            topWallYs = [self.goal_up ,self.court_h,self.court_h,self.goal_up ];
            bottomWallXs = [0,0,self.court_w,self.court_w];
            bottomWallYs = [self.goal_low,0,0,self.goal_low];
            plot(topWallXs, topWallYs, '-', ...
                'LineWidth', self.wall_w, 'Color', self.wall_color);
            plot(bottomWallXs, bottomWallYs, '-', ...
                'LineWidth', self.wall_w, 'Color', self.wall_color);
            %calculate circle to draw on court
            thetas = linspace(0, (2*pi), 100);
            circleXs = (self.center_r .* cos(thetas)) + (self.court_w / 2);
            circleYs = (self.center_r .* sin(thetas))+ (self.court_h / 2);
            %draw lines on court
            centerline = plot([self.court_w/2, self.court_w/2],[self.court_h, 0],'--');
            set(centerline, 'Color', self.center_color);
            centerCircle = plot(circleXs, circleYs,'--');
            set(centerCircle, 'Color', self.center_color);
            % ball
            self.ballPlot = plot(0,0);
            set(self.ballPlot, 'Marker', self.ball_shape);
            set(self.ballPlot, 'MarkerEdgeColor', self.ball_out);
            set(self.ballPlot, 'MarkerFaceColor', self.ball_color);
            set(self.ballPlot, 'MarkerSize', self.ball_size);
            % paddles
            self.paddle1Plot = plot(0,0, '-', 'LineWidth', self.paddle_w);
            self.paddle2Plot = plot(0,0, '-', 'LineWidth', self.paddle_w);
            set(self.paddle1Plot, 'Color', self.paddle_color);
            set(self.paddle2Plot, 'Color', self.paddle_color);
        end
        
        function resetGame(self)
            self.ballSpeed=self.min_ball_speed;
            self.ballX = self.court_w/2;
            self.ballY = self.court_h/2;
            
            titleStr = sprintf('%d / %d%19d / %d', self.score(1), self.max_points, self.score(2), self.max_points);
            t = title(titleStr, 'Color', self.title_color);
            set(t, 'FontName', 'Courier','FontSize', 15, 'FontWeight', 'Bold');
            self.refreshCourt;
            pause(self.kickoff_delay);
        end
        
        function refreshCourt(self)
            set(self.ballPlot, 'XData', self.ballX, 'YData', self.ballY);
            set(self.paddle1Plot, 'Xdata', self.paddle1(1,:), 'YData', self.paddle1(2,:));
            set(self.paddle2Plot, 'Xdata', self.paddle2(1,:), 'YData', self.paddle2(2,:));
            drawnow;
            pause(self.frame_delay);
        end
        
        function ballbounce (self,V)
            %increase first dimension by a random value
            V(1) = V(1) * (rand + 1);
            %normalize vector
            V = V ./ (sqrt(V(1)^2 + V(2)^2));
            self.ballV = V;
            %to make it more challenging, the ball increases the speed 
            if (self.ballSpeed +  self.ball_acceleration_factor < self.max_speed)
                self.ballSpeed = self.ballSpeed +  self.ball_acceleration_factor;
            end
        end
        
        function startgame (self)
            self.winner = 0;
            self.score = [0, 0];
            self.paddle1V = 0; 
            self.paddle2V = 0; 
            self.paddle1 = [self.paddle(1,:)+PADDLE_SPACE; ...
                self.paddle(2,:)+((self.court_h - self.paddle_h)/2)];
            self.paddle2 = [self.paddle(1,:)+ self.court_h - self.paddle_space - self.paddle_w; ...
                self.paddle(2,:)+((self.court_h - self.paddle_h)/2)];
            resetGame;           
        end

        function checkGoal(self)
            goal = false;
            
            if self.ballX > self.court_w + self.ball_radius + self.goal_buffer
                self.score(1) = self.score(1) + 1;
                if self.score(1) == self.max_points;
                    self.winner = 1;
                end
                goal = true;
            elseif self.ballX < 0 - self.ball_radius - self.goal_buffer
                self.score(2) = self.score(2) + 1;
                if self.score(2) == self.max_points;
                    self.winner = 2;
                end
                goal = true;
            end
            
            if goal %a goal was made
                pause(self.kickoff_delay);
                resetGame;
                if self.winner > 0 %somebody won
                    text(38,55,['Player ' num2str(self.winner) ' is the winner!!!']);
                    startgame;
                else %nobody won
                end
            end
        end
       
  
        function next(self, action)
            
            if ~any(strcmp(action,self.actions))
                error('Action not recognised')
            end
            
            self.ball = self.ball + self.velocity; % move ball
            
            if rand>self.pFail % unless action fails
                if strcmp(action,self.actions(1)) && self.paddle1 ~= 1
                    self.paddle1=self.paddle1-1; % move paddle up
                elseif strcmp(action,self.actions(3)) && self.paddle1 ~= self.numRows
                    self.paddle1=self.paddle1+1; % move paddle down
                end
            end
            
            
            if ~self.twoPlayer && rand>self.pFail % naive bot that follows ball
                if self.ball(1)>self.paddle2
                    self.paddle2 = self.paddle2+1;
                elseif self.ball(1)<self.paddle2
                    self.paddle2 = self.paddle2 -1;
                end
            end
            
            if self.ball(1)==1 || self.ball(1)==self.numRows % reflect off side walls
                self.velocity(1)=-self.velocity(1);
            end
            
            
            if self.ball(2)==1 % when ball is at player end
                if self.ball(1) == self.paddle1 % if paddle is there
                    self.velocity(2)=-self.velocity(2); % reflects
                    if rand < self.pRedir % might change angle of bounce
                        if self.velocity(1) ~= 0;
                            self.velocity(1) =0;
                        else
                            self.velocity(1)=2*randi(2)-3;
                        end
                    end
                else % if player misses ball
                    self.score2 = self.score2 +1; % opp. scores
                    disp('Point for player 2')
                    self.ball = [ceil(self.numRows/2), ceil(self.numColumns/2)]; % reset
                    self.velocity = [randi(3)-2,2*randi(2)-3];
                end
            end
            
            if self.ball(2)==self.numColumns % same as above for player 2
                if self.ball(1) == self.paddle2
                    self.velocity(2)=-self.velocity(2);
                    if rand < self.pRedir
                        if self.velocity(1) ~= 0;
                            self.velocity(1) =0;
                        else
                            self.velocity(1)=2*randi(2)-3;
                        end
                    end
                else
                    self.score1 = self.score1 +1;
                    disp('Point for player 1')
                    self.ball = [ceil(self.numRows/2), ceil(self.numColumns/2)];
                    self.velocity = [randi(3)-2,2*randi(2)-3];
                end
            end
            display(self); % display game-state
        end
        
        function display(self)
            disp(self) % placeholder, graphical would be nice
        end
    end
end