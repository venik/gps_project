import java.util.Arrays;

public class GpsHelper {
	GpsHelper() {
	/* Constructor */
		System.out.println("Constructor\n");

		GenerateCA();
	}

	private void GenerateCA() {

		int CPS[][] = 	{ {2,6},{3,7},{4,8},{5,9},{1,9},{2,10},{1,8},{2,9},{3,10},
				  {2,3},{3,4},{5,6},{6,7},{7,8},{8,9},{9,10},{1,4},{2,5},
				  {3,6},{4,7},{5,8},{6,9},{1,3},{4,6},{5,7},{6,8},{7,9},
				  {8,10},{1,6},{2,7},{3,8},{4,9} };
		
		int g2s[] = {	5,6,7,8,17,18,139,140,141,251,252,254,255,256,257,
				258,469,470,471,472,473,474,509,512,513,514,515,516,
				859,860,861,862 };

		int G1[] = new int[1023];
		int G2[] = new int[1023];
		int G2_tmp[] = new int[1023];
		int CA[] = new int[1023];
		int reg1[] = {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1};
		int reg2[] = {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1};
		int save1, save2;
		//int G1[] = {1,1,1,1,1,1,1,1,1,1};
		//int G2[] = {1,1,1,1,1,1,1,1,1,1};

		int i,j;

		/* generate G1 code */
		for( i=0; i<1023; i++) {
			G1[i] = reg1[9];			// g1(i) = reg(10) ;

			save1 = reg1[2] * reg1[9];		// save1 = reg(3) * reg(10);
		

			/* shift left */
			for( j=9; j > 0; j-- ) {
				reg1[j] = reg1[j-1];		// reg(1,2:10) = reg(1,1:9);
				//System.out.println(j + ": " + reg1[j-1] + "->"  + reg1[j]);
			}
			
			reg1[0] = save1;			// reg(1) = save1;
		}
		
		/* generate G2 code */
		for( i=0; i<1023; i++) {
			G2[i] = reg2[9]; 

			/* save2 = reg(2)*reg(3)*reg(6)*reg(8)*reg(9)*reg(10); */
			save2 = reg2[1]*reg2[2]*reg2[5]*reg2[7]*reg2[8]*reg2[9] ;
			
			/* shift left */
			for( j=9; j > 0; j-- ) {
				reg2[j] = reg2[j-1];		// reg(1,2:10) = reg(1,1:9);
			}

			reg2[0] = save2;			// reg(1) = save2;
		}
		
		//System.out.println("G1 " + Arrays.toString(G1) + "\n");
		//System.out.println("G2 " + Arrays.toString(G2) + "\n");

		int val = 19 - 1;
		for( i=0; i < g2s[val]; i++) {
			G2_tmp[i] = G2[1023 - (g2s[val] - i)] ;
		}
		for( i=g2s[val]; i < 1023; i++) {
			G2_tmp[i] = G2[i - g2s[val]] ;
		}

		G2 = G2_tmp;

		//System.out.println("G2_tmp " + Arrays.toString(G2) + "\n");

		/* finish loop - FIXME why * (-1) */
		for( i=0; i<1023; i++) {
			CA[i] = (G1[i] * G2[i]) * (-1) ;
		}

		/* Print out */
		/*
		for( i=0; i<1023; i++) {
			System.out.println(i + ": CA >" + CA[i] + "\tG2 >" + G2[i] + "\tG1 >" + G1[i]) ;
		}
		*/

	}

	public static void main(String args[]) {
		System.out.println("GpsHelper class\n");

		GpsHelper gpsh = new GpsHelper();

	}
}
