function ASIComp_CalcMSF(app)
%ASICOMP_CALCMSF Calculates the MSFs of the ASI datasets
    % The actual calculation function is a method in the class CompareASI
    app.d2c.calcMSF(app,app.Field_ASIComp_MSFSteps.Value,app.Field_ASIComp_MSFqRange.Value);
    % Update the min/max intensity value based on whatever intensity is in the 1st image
    app.Field_MSF_IMin.Value = min(app.d2c.asi(1).MSF.matrix,[],'all');
    app.Field_MSF_IMax.Value = max(app.d2c.asi(1).MSF.matrix,[],'all');
end

