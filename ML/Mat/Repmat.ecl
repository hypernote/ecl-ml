﻿IMPORT ML.Mat;
// replicates/tiles a matrix - creates a large matrix consisiting of
// an M-by-N tiling of copies of A
EXPORT Repmat(DATASET(Mat.Types.Element) A, UNSIGNED M, UNSIGNED N) := FUNCTION

	Stats := Mat.Has(A).Stats;
	Mat.Types.Element ReplicateM(Mat.Types.Element le,UNSIGNED C) := TRANSFORM
		SELF.x := le.x+Stats.XMax*(C-1);
		SELF := le;
	END;
	
  AM := NORMALIZE(A,M,ReplicateM(LEFT,COUNTER)); 
	
	Mat.Types.Element ReplicateN(Mat.Types.Element le,UNSIGNED C) := TRANSFORM
		SELF.y := le.y+ Stats.YMax*(C-1);
		SELF := le;
	END;
	
  AMN := NORMALIZE(AM,N,ReplicateN(LEFT,COUNTER)); 	
	
	RETURN AMN; 
END;