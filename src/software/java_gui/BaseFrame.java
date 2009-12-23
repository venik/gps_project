import java.awt.BorderLayout;
import javax.swing.*;
import java.awt.BorderLayout;
import javax.swing.JList;
import javax.swing.JPanel;
import javax.swing.JTabbedPane;
import javax.swing.JTextArea;
import javax.swing.JTextField;
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;

public class BaseFrame extends JPanel implements ChangeListener {

	private JTabbedPane jtp = new JTabbedPane();
	private	JFrame jfrm = new JFrame("test") ;

	BaseFrame() {

		jfrm.setSize(275,200) ;
		jfrm.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

		JLabel jlab = new JLabel("just label");

		jfrm.getContentPane().add(jlab);

		// добавляем закладки
		jtp.addTab("Tab1", new JTextArea("Test String"));
		jtp.addTab("Tab2", new JList(new String[] 
			     { "itm1", "itm2", "itm3" }));

		// добавляем обработчик выбора закладки
		jtp.addChangeListener(this);

		jfrm.getContentPane().add(jtp);

		jfrm.setVisible(true);
	}

	public void stateChanged(ChangeEvent arg0) {
        	//jfrm.setText("выбрана закладка " + jtp.getTitleAt(jtp.getSelectedIndex()));

        // если на окне несколько закладочных контейнеров
        // можно сравнивать arg0.getSource() например
        // jtf.setText((arg0.getSource()==jtp)?"ok":"no ok");
    }

	public static void main(String args[]) {
		SwingUtilities.invokeLater(new Runnable() {
			public void run() {
				new BaseFrame();
			}
		});
	}
}
