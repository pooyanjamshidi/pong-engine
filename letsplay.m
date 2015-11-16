function [score]=letsplay()
close all
clear
clc
try
    pe= pongEngine();
catch ME
    error('Engine cannot be inistantiated')
end

%% initialize player 1 and player 2 struct

%%
pe.createCourt;
pe.startGame;
while ~pe.winner
    pe.moveBall;
    % player1 and player2 call next here to do an action: next(pe, player, action)
    pe.movePaddles;
    pe.refreshCourt;
    pe.checkGoal;
end
disp(['Player ' num2str(pe.winner) ' is the winner!!!']);
score=pe.score;
close(pe.court_handle)
end

