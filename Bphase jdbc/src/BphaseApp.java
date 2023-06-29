import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Random;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;

public class BphaseApp {
	private Connection cnt;
	
	
	public BphaseApp() {
		try {
			Class.forName("org.postgresql.Driver");
			System.out.println("Driver Found!");
		} catch (ClassNotFoundException e) {
			System.out.println("Driver not found!");
		}
	}
	
	public void dbConnect(String ip, String dbName, String username, String password) {
		try {
			cnt = DriverManager.getConnection("jdbc:postgresql://"+ip+":5432/"+dbName, username, password);
			System.out.println("Connection established : "+cnt);
			
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	
	public static void main(String[] args) throws IOException {
		BphaseApp app = new BphaseApp();
		app.dbConnect("localhost", "BataDase", "postgres", "123");
		
		BufferedReader reader = new BufferedReader(new InputStreamReader(System.in, StandardCharsets.UTF_8));
		int select = 0;
		
		do {
            System.out.println("------ MENU ------");
            System.out.println("1. Show grade");
            System.out.println("2. Change grade");
            System.out.println("3. Search person based on starting letters of last name");
            System.out.println("4. Show transcript");
            System.out.println("5. Exit");
            System.out.print("Enter your choice: ");
            
            try {
                select = Integer.parseInt(reader.readLine());
            } catch (IOException e) {
                e.printStackTrace();
            }

            switch (select) {
                case 1:
                    System.out.println("You selected Option 1");
                    app.showGrade();
                    break;
                case 2:
                    System.out.println("You selected Option 2");
                    app.changeGrade();
                    break;
                case 3:
                    System.out.println("You selected Option 3");
                    app.searchPerson();
                    break;
                case 4:
                    System.out.println("You selected Option 4");
                    app.showTranscript();
                    break;
                case 5:
                	System.out.println("Exiting...");
                	break;
                default:
                    System.out.println("Invalid choice. Please try again.");
                    break;
            }
            
            System.out.println(); // Empty line for separation

        } while (select != 5);

	}
	
	public void showGrade() throws IOException {
		BufferedReader reader = new BufferedReader(new InputStreamReader(System.in, StandardCharsets.UTF_8));
		System.out.println("Please enter student A.M.");
		String am = reader.readLine();
		System.out.println("Please enter course code.");
		String course_code = new String(reader.readLine().getBytes(), StandardCharsets.UTF_8);
		showGrade(am, course_code);
		
		
	}
	
	
	
	public void changeGrade() throws IOException {
		BufferedReader reader = new BufferedReader(new InputStreamReader(System.in, StandardCharsets.UTF_8));
		System.out.println("Please enter student A.M.");
		String am = reader.readLine();
		System.out.println("Please enter course code.");
		String course_code = new String(reader.readLine().getBytes(), StandardCharsets.UTF_8);
		System.out.println("Please enter serial number of the course.");
		int serial_number = Integer.parseInt(reader.readLine());
		System.out.println("Please enter the new grade.");
		float new_grade = Float.parseFloat(reader.readLine());
		changeGrade(am, course_code, serial_number, new_grade);
		

	}
	
	public void searchPerson() throws IOException {
		BufferedReader reader = new BufferedReader(new InputStreamReader(System.in, StandardCharsets.UTF_8));
		System.out.println("Please enter some starting letters of the people you want to see");
		String starting_letters = new String(reader.readLine().getBytes(), StandardCharsets.UTF_8);
		searchPerson(starting_letters);
		
		

	}
	
	public void showTranscript () throws IOException {
		BufferedReader reader = new BufferedReader(new InputStreamReader(System.in, StandardCharsets.UTF_8));
		System.out.println("Please enter student A.M.");
		String am = reader.readLine();
		showTranscript(am);
		
	}
	
	public void showGrade(String am, String course_code) {
		try {
			Statement st = cnt.createStatement();
			
			ResultSet res = st.executeQuery("select final_grade from \"Student\" join \"Register\" using(amka) where am = '"+ am + "' and course_code = '"+ course_code +"'");			
			while (res.next()) {
				System.out.println("final grade ="+res.getString(1));
			}
			
			res.close();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
	
	public void changeGrade(String am, String course_code, int serial_number, float new_grade) {
		try {
			Statement st = cnt.createStatement();
			
			ResultSet res = st.executeQuery("UPDATE \"Register\" re1\r\n"
					+ "SET final_grade = " + new_grade + "\r\n"
					+ "from \"Student\"\r\n"
					+ "where am = '" + am + "' and course_code = '" + course_code +"' and serial_number = "+ serial_number +";");
			System.out.println("UPDATE \"Register\" re1\r\n"
					+ "SET final_grade = " + new_grade + "\r\n"
					+ "from \"Student\"\r\n"
					+ "where am = " + am + " and course_code = " + course_code +" and serial_number = "+ serial_number +";");

			
			while (res.next()) {
				System.out.println("Final grade of student " + am +" changed to " + new_grade + " at course " + course_code);
			}
			
			res.close();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
	
	public void searchPerson(String starting_letters) throws NumberFormatException, IOException {
		try {
			Statement st = cnt.createStatement();
			
			ResultSet res = st.executeQuery("Select count(*) from \"Person\" where surname LIKE '" + starting_letters +"%'");
			int total_results=0;
			while(res.next())
				total_results = res.getInt(1);
			if (total_results>=5) {
				BufferedReader reader = new BufferedReader(new InputStreamReader(System.in, StandardCharsets.UTF_8));
				System.out.println("Total results :" + total_results);
				System.out.println("Enter amount of people per page :");
				int peoplePerPage = Integer.parseInt(reader.readLine());
				int total_pages = total_results/peoplePerPage + 1;
				int currentPage=0;
				System.out.println("Enter page number you want to see, the character 'n' to go to the next page or the character 'e' to exit.");
				String selection = reader.readLine();
				if (!selection.equals("n") && !selection.equals("e"))
					currentPage = Integer.parseInt(selection);
				while (!selection.equals("e")) {
					res = st.executeQuery(" SELECT pr.surname, pr.name,\r\n"
							+ "            CASE\r\n"
							+ "                WHEN EXISTS(SELECT st.am FROM \"Student\" st WHERE st.amka = pr.amka) THEN 'STUDENT'\r\n"
							+ "                WHEN EXISTS(SELECT pro.rank FROM \"Professor\" pro WHERE pro.amka = pr.amka) THEN 'PROFESSOR'\r\n"
							+ "                ELSE 'LAB TEACHER'\r\n"
							+ "            END AS chara\r\n"
							+ "        FROM \"Person\" pr WHERE surname LIKE '" + starting_letters + "%'  ORDER BY surname LIMIT " + peoplePerPage + " OFFSET "+ (currentPage-1)*peoplePerPage);
					while (res.next()) {
						System.out.println(res.getString(1) + " " + res.getString(2) + " " + res.getString(3));
					}
					System.out.println("Page " + currentPage + "/" + total_pages);
					System.out.println("Enter page number you want to see, the character 'n' to go to the next page or the character 'e' to exit.");
					selection = reader.readLine();
					if (selection.equals("n")) {
						currentPage++;
						if (currentPage >total_pages) {
							System.out.println("End of list reached, enter a specific page or 'e' to exit");
							selection = reader.readLine();
						}
					}
					else if (!selection.equals("e")){
						currentPage = Integer.parseInt(selection);
						while (currentPage < 0 || currentPage > total_pages) {
							System.out.println("Try again");
							selection = reader.readLine();
							currentPage = Integer.parseInt(selection) - 1;
						}
						
					}

				}
				System.out.println("Exited.");
				
			}
			System.out.println();

			
			
			
			res.close();
		} catch (SQLException e) {
			e.printStackTrace();
		}
		
	}
	
	public void showTranscript(String am) {
		try {
			Statement st = cnt.createStatement();
			
			ResultSet res = st.executeQuery("select name, surname, am, course_code, exam_grade, lab_grade, final_grade, semesterrunsin from \"Register\"\r\n"
					+ "join \"Student\" using(amka)\r\n"
					+ "join \"Person\" using(amka)\r\n"
					+ "join \"CourseRun\" using (course_code)\r\n"
					+ "where am = '" + am +"'\r\n"
					+ "order by semesterrunsin");
			res.next();
			System.out.println("For student : " + res.getString(1) + " " + res.getString(2) + " " + res.getString(3));
			System.out.println("|Course  |Exam  Lab			| Final					| Semester");
			System.out.println("|--------|------------------------------|---------------------------------------|----------");
			System.out.println("|" + res.getString(4) + " | " + res.getString(5) + "	" + res.getString(6) + "			| " + res.getString(6) + "					| " + res.getString(8) + "|" );
			while (res.next()) {
				System.out.println("|" + res.getString(4) + " | " + res.getString(5) + "	" + res.getString(6) + "			| " + res.getString(6) + "					| " + res.getString(8) + "|" );
			}
			
			res.close();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
	
}
