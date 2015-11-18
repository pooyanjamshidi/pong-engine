classdef player < handle
    properties (GetAccess='public',SetAccess='private')
        
        name;% 1 or 2
        myworld; % pong engine
    end
    
    methods
        function self = player(myname,world) % constructor
            self.name=myname;
            self.myworld=world;
        end
        
        function play(self) % naive strategy that follows ball vertical position
            e=self.myworld;
            
            ball=e.getnoisyBallPosition();
            ballV=e.getnoisyBallV();
            myp=e.getmycenterPosition(self.name);
            
            switch self.name
                case 1
                    if ballV(1)<0
                        towardsme=true;
                    else towardsme=false;
                    end
                case 2
                    if ballV(1)>0
                        towardsme=true;
                    else towardsme=false;
                    end
            end
            
            if towardsme==true
                if ball(2)>myp(2)
                    e.next(self.name,'up');
                elseif ball(2)<myp(2)
                    e.next(self.name,'down');
                else
                    e.next(self.name,'stay');
                end
            else
                e.next(self.name,'stay');
                
            end
            
            
            
        end
        
    end
end