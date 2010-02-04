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

		int G1[] = {1,1,1,1,1,1,1,1,1,1};
		int G2[] = {1,1,1,1,1,1,1,1,1,1};

		
	}

	public static void main(String args[]) {
		System.out.println("GpsHelper class\n");

		GpsHelper gpsh = new GpsHelper();

	}
}
