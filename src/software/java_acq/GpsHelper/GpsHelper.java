import java.util.Arrays ;

public class GpsHelper {

	private int CA[] = new int[1023] ;
	private int ca16[] = new int[16368] ;		/* 1023 * 16 */

	GpsHelper() {
	/* Constructor */
		System.out.println("Constructor\n");
	}

	private void GenerateCA(int svnum)
	{
		System.out.println("Generate CA. PRN = " + svnum);

		int g2s[] = {	5,6,7,8,17,18,139,140,141,251,252,254,255,256,257,
				258,469,470,471,472,473,474,509,512,513,514,515,516,
				859,860,861,862 };

		int G1[] = new int[1023];
		int G2[] = new int[1023];
		int G2_tmp[] = new int[1023];
		int reg1[] = {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1};
		int reg2[] = {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1};
		int save1, save2;

		int i,j;

		/* generate G1 code */
		for( i=0; i<1023; i++) {
			G1[i] = reg1[9];			// g1(i) = reg(10) ;

			save1 = reg1[2] * reg1[9];		// save1 = reg(3) * reg(10);
		

			/* shift left */
			for( j=9; j > 0; j-- )
				reg1[j] = reg1[j-1];		// reg(1,2:10) = reg(1,1:9);
			
			reg1[0] = save1;			// reg(1) = save1;
		}
		
		/* generate G2 code */
		for( i=0; i<1023; i++) {
			G2[i] = reg2[9]; 

			/* save2 = reg(2)*reg(3)*reg(6)*reg(8)*reg(9)*reg(10); */
			save2 = reg2[1]*reg2[2]*reg2[5]*reg2[7]*reg2[8]*reg2[9] ;
			
			/* shift left */
			for( j=9; j > 0; j-- )
				reg2[j] = reg2[j-1];		// reg(1,2:10) = reg(1,1:9);

			reg2[0] = save2;			// reg(1) = save2;
		}
		
		//System.out.println("G1 " + Arrays.toString(G1) + "\n");
		//System.out.println("G2 " + Arrays.toString(G2) + "\n");

		for( i=0; i < g2s[svnum - 1]; i++) {
			G2_tmp[i] = G2[1023 - (g2s[svnum - 1] - i)] ;
		}
		for( i=g2s[svnum - 1]; i < 1023; i++) {
			G2_tmp[i] = G2[i - g2s[svnum - 1]] ;
		}

		G2 = G2_tmp;

		//System.out.println("G2_tmp " + Arrays.toString(G2_tmp) + "\n");

		/* finish loop - FIXME why * (-1) */
		for( i=0; i<1023; i++) {
			CA[i] = (G1[i] * G2[i]) * (-1) ;
		}

		//System.out.println("CA: " + Arrays.toString(CA) + "\n");
		
		/* Print out */
		//for( i=0; i<1023; i++) {
			//System.out.println(i + ": CA >" + CA[i] + "\tG2 >" + G2[i] + "\tG1 >" + G1[i]) ;
		//}
	}

	public int GetCACode_16(int PRN)
	{
		double	chip_width =  1/1.023e6 ;	/* CA chip duration, sec */
		double  ts = 1/16.368e6 ; 	 	/* discretization period, sec */
		int	N = 1023 ;

		int 	k;
		int	tmp_index;

		/* generate the CA code for the satellite */
		GenerateCA(PRN);

		// FIXME - check this cheat
		for( k=0; k < (N*16); k++ ) {
			tmp_index = (int)(Math.abs( (ts*k) / chip_width) );
			tmp_index = ((tmp_index < 1023) ? tmp_index : 1022);
			
			//System.out.println(k + ": tmp_index: " + tmp_index + "\n") ;
    			
			ca16[k] = CA[tmp_index] ;
		}
		
		//System.out.println("ca16 " + Arrays.toString(ca16) + "\n");

		return 0;
	}

	public static void main(String args[]) {
		System.out.println("GpsHelper class\n");

		GpsHelper gpsh = new GpsHelper();

		gpsh.GetCACode_16(19) ;

	}
}
