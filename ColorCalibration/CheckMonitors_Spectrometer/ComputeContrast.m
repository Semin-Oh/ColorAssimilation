function []=ComputeContrast(LMax,LMin)

Weber = (LMax-LMin)/LMin; 
Michelson= (LMax-LMin)/(LMax+LMin); 

disp(['Weber: ', num2str(Weber), ', Michelson:',num2str(Michelson)])