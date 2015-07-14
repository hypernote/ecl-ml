﻿IMPORT ML;
IMPORT ML.Types AS Types;
IMPORT ML.Utils AS Utils;
IMPORT ML.Classify AS Classify;
IMPORT ML.StepwiseLogistic.TypesSL AS TypesSL;
IMPORT Std.Str;

EXPORT Backward(REAL8 Ridge=0.00001, REAL8 Epsilon=0.000000001, UNSIGNED2 MaxIter=200) 
																				:= MODULE(ML.StepwiseLogistic.StepLogistic(Ridge,Epsilon,MaxIter))
	EXPORT Regression(DATASET(Types.NumericField) X,DATASET(Types.DiscreteField) Y) := MODULE
		
			SHARED DATASET(Parameter) Indices := NORMALIZE(DATASET([{0}], Parameter), COUNT(ML.FieldAggregates(X).Cardinality), 
								TRANSFORM(Parameter, SELF.number := COUNTER));
			InitMod := LogReg.LearnC(X, Y);
			AIC := findAIC(X, Y, InitMod);
			
			SHARED DATASET(StepRec) InitialStep := DATASET([{DATASET([], Parameter), DATASET([], ParamRec), Indices, AIC}], StepRec);
			
			DATASET(StepRec) Step_Backward(DATASET(StepRec) recs, INTEGER c) := FUNCTION
		
				le := recs[c];			
				Selected := SET(le.Final, number);
							
				SelectList := Indices(number IN Selected) + DATASET([{0}], Parameter);			
				NumSelect := COUNT(SelectList);
		
				DATASET(ParamRec) T_Select(DATASET(ParamRec) precs, INTEGER paramNum) := FUNCTION
					x_subset := X(number IN Selected AND number NOT IN [paramNum]);
					RebaseX := Utils.RebaseNumericField(x_subset);
					X_Map := RebaseX.Mapping(1);
					X_0 := RebaseX.ToNew(X_Map);
					reg := LogReg.LearnC(X_0, Y);
					AIC := findAIC(IF(EXISTS(X_0), X_0, X), Y, reg);
					Op := '-';
					RETURN precs + ROW({Op, paramNum, AIC}, ParamRec);
				END;		
				
				SelectCalculated := LOOP(DATASET([], ParamRec), COUNTER <= NumSelect, T_Select(ROWS(LEFT), SelectList[COUNTER].number));
				bestSR := TOPN(SelectCalculated, 1, AIC);			
				
				Initial := le.Final;
				StepRecs := SelectCalculated;
				Final := Indices(number IN Selected AND number NOT IN [bestSR[1].ParamNum]);
				AIC := bestSR[1].AIC;
					
				RETURN recs + ROW({Initial, StepRecs, Final, AIC}, Steprec);
			END;
			
			EXPORT DATASET(StepRec) Steps := LOOP(InitialStep, 
							COUNTER = 1 OR ROWS(LEFT)[COUNTER].Initial != ROWS(LEFT)[COUNTER].Final,
							Step_Backward(ROWS(LEFT), COUNTER));
			
			BestStep := Steps[COUNT(Steps)];
			var_subset := SET(BestStep.Final, number);
			x_subset := X(number IN var_subset);
			RebaseX := Utils.RebaseNumericField(x_subset);
			X_Map := RebaseX.Mapping(1);
			X_0 := RebaseX.ToNew(X_Map);
			EXPORT mod := LogReg.LearnC(X_0, Y);
		END;
		
	
	EXPORT LearnCS(DATASET(Types.NumericField) Indep,DATASET(Types.DiscreteField) Dep) := Regression(Indep, Dep).mod;
	
END;