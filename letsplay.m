function [score]=letsplay()
close all
clear all
clc
try
pe= pongEngine();
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

