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

		} catch (UnknownHostException e) {
			System.err.println(e);
			System.exit(1);
		} catch (IOException e) {
			System.err.println(e);
			System.exit(1);
		}

		return 0;
	}
	
	private	void SendComm(String comm) {

		System.out.println("SendComm()");

		//try {
			//o_stream.write(hello, 0, hello.length());
			o_stream.print(comm);
			o_stream.flush();

		//	String ans = i_stream.readLine();

			//System.out.println("System answer [" + ans + "]");

		//} catch (java.io.IOException exp) {
			this.CloseAll();
			//exp.printStackTrace();
		//}
	}

	public void InitBoard(String port_name) {

		SendComm("RS232_PORT:/dev/ttyUSB0");
		//SendComm("Second");
		
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

		ngb.InitBoard("some");
	}

}
