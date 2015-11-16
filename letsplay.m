function [score]=letsplay(player1,player2)
try
pe= pongEngine(player1,player2);
catch ME
    error('Engine cannot be inistantiated')
end
pe.createCourt;
pe.startGame;
while ~pe.winner
    pe.moveBall;
    pe.movePaddles;
    pe.refreshCourt;
    pe.checkGoal;
end
score=pe.score;

end