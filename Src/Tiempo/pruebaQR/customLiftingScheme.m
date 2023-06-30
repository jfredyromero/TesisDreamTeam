function lsc =customLiftingScheme(fw)
    
    lsc_ini = liftingScheme('Wavelet',fw);
    scaleFactors=lsc_ini.NormalizationFactors;
    coef_up=lsc_ini.LiftingSteps(2).Coefficients;
    coef_pre=lsc_ini.LiftingSteps(1).Coefficients;
    els1 = liftingStep('Type','update','Coefficients',(1/9)*coef_up,'MaxOrder',0);
    els2 = liftingStep('Type','predict','Coefficients',(1/9)*coef_pre,'MaxOrder',0);

    %scaleFactors = [sqrt(2) sqrt(2)/2];
    %els1 = liftingStep('Type','update','Coefficients',1/2,'MaxOrder',1);
    %els2 = liftingStep('Type','predict','Coefficients',-1,'MaxOrder',1);

    % scaleFactors = [(sqrt(3)+1)/sqrt(2) (sqrt(3)-1)/sqrt(2)];
    % els1 = liftingStep('Type','update','Coefficients',[-sqrt(3) 1],'MaxOrder',0);
    % els2 = liftingStep('Type','predict','Coefficients',[1 sqrt(3)/4+(sqrt(3)-2)/4],'MaxOrder',1);

    lsc = liftingScheme('LiftingSteps',[els1;els2;els1;els2;els1;els2;els1;els2;els1;els2;els1;els2;els1;els2;els1;els2;els1;els2],'NormalizationFactors',scaleFactors);

end