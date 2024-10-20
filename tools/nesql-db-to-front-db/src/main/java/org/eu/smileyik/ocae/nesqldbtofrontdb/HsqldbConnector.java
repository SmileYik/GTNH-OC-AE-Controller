package org.eu.smileyik.ocae.nesqldbtofrontdb;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class HsqldbConnector {
    private static final String TEMP_DATABASE = ".temp";
    private static final String TEMP_DATABASE_NAME = "temp";
    private static final String JDBC_URL = "jdbc:hsqldb:file:" + TEMP_DATABASE + "/" + TEMP_DATABASE_NAME;

    static {
        try {
            Class.forName("org.hsqldb.jdbc.JDBCDriver");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException(e);
        }
    }

    public HsqldbConnector(String script) throws IOException {
        Files.deleteIfExists(Paths.get(TEMP_DATABASE, TEMP_DATABASE_NAME + ".script"));

        Files.createDirectories(Paths.get(TEMP_DATABASE));
        Files.copy(Paths.get(script), Paths.get(TEMP_DATABASE, TEMP_DATABASE_NAME + ".script"));
    }

    public Connection newConnection() {
        try {
            return DriverManager.getConnection(JDBC_URL, "SA", "");
        } catch (SQLException e) {
            return null;
        }
    }

    public void closeConnection(Connection connection) {
        if (connection != null) {
            try {
                connection.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }
}
