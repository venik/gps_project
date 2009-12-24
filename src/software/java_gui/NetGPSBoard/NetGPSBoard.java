import java.net.*;
import java.io.*;

public class NetGPSBoard {

	private Socket		theSocket;
	private BufferedReader	i_stream;	
	private PrintWriter	o_stream;	

	private String	hostname;
	private int 	port;

	NetGPSBoard(String i_hostname, int i_port) {
		this.hostname = i_hostname ;
		this.port = i_port ;
	}

	public int ConnToBoard() {
		
		try {
			theSocket = new Socket(hostname, port);

			// activate streams
			i_stream = new BufferedReader(new InputStreamReader(theSocket.getInputStream()));
			
			o_stream = new PrintWriter(
						new BufferedWriter(
							new OutputStreamWriter(theSocket.getOutputStream())), true);

			String hello = "Hello world\n";
			o_stream.println(hello);
			String theTime = i_stream.readLine();

			System.out.println("[" + theTime + "]");

		} catch (UnknownHostException e) {
			System.err.println(e);
		} catch (IOException e) {
			System.err.println(e);
		}

		return 0;
	}

	public void SomeMethod() {


	}
	
// Just main()	
	public static void main(String args[]) {
		System.out.println("NetGPSBoard class\n");

		NetGPSBoard ngb = new NetGPSBoard("127.0.0.1", 1234);

		ngb.ConnToBoard();
	}

}
