import java.net.*;
import java.io.*;

public class NetGPSBoard {

	private Socket		theSocket;
	private BufferedReader	i_stream;	
	private PrintWriter	o_stream;	

	private String		hostname;
	private int 		port;

	public NetGPSBoard(String i_hostname, int i_port) {

		this.hostname = i_hostname ;
		this.port = i_port ;

		this.ConnToBoard() ;
	}

	public NetGPSBoard() {
		this("localhost", 1234);
	}

	private int ConnToBoard() {
		
		try {
			theSocket = new Socket(hostname, port);

			// activate streams
			i_stream = new BufferedReader(new InputStreamReader(theSocket.getInputStream()));
			o_stream = new PrintWriter(theSocket.getOutputStream(), true);

			//o_stream = new PrintWriter( 
			//			new BufferedWriter( \
			//				new OutputStreamWriter(theSocket.getOutputStream())), true);

		} catch (UnknownHostException e) {
			System.err.println(e);
			System.exit(1);
		} catch (IOException e) {
			System.err.println(e);
			System.exit(1);
		}

		return 0;
	}

	public void SendComm() {

		System.out.println("SendComm()");

		String hello = "HELLO_GPS_BOARD v0.1";
		
		try {
			//o_stream.write(hello, 0, hello.length());
			o_stream.println(hello);
			o_stream.flush();

			String str = i_stream.readLine();

			System.out.println("[" + str + "]");

		} catch (java.io.IOException exp) {
			exp.printStackTrace();
		}
	}

	public void CloseAll() {
		try {
			i_stream.close();
			o_stream.close();
			theSocket.close();
		} catch (java.io.IOException exp) {
			exp.printStackTrace();
		}
	}

	
// Just main()	
	public static void main(String args[]) {
		System.out.println("NetGPSBoard class\n");

		NetGPSBoard ngb = new NetGPSBoard();

		ngb.ConnToBoard();

		ngb.SendComm();
	}

}
