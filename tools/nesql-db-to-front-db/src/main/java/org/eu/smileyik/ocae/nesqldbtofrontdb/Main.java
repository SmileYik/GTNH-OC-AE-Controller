package org.eu.smileyik.ocae.nesqldbtofrontdb;

import org.eu.smileyik.ocae.nesqldbtofrontdb.table.Aspect;
import org.eu.smileyik.ocae.nesqldbtofrontdb.table.Fluid;
import org.eu.smileyik.ocae.nesqldbtofrontdb.table.Item;

import java.beans.IntrospectionException;
import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;

public class Main {

    public static void main(String[] args) throws IOException, SQLException, IntrospectionException, InvocationTargetException, NoSuchMethodException, InstantiationException, IllegalAccessException {
        String scriptFile = "gtnh.script";
        if (args.length > 0) {
            scriptFile = args[0];
        }

        System.out.println("Executing HSQLDB script: " + scriptFile);
        HsqldbConnector connector = new HsqldbConnector(scriptFile);
        System.out.println("Finished executing HSQLDB script: " + scriptFile);

        Connection connection = connector.newConnection();
        List<Aspect> aspects = TableQuery.queryAll(Aspect.class, connection);
        System.out.println(aspects);
        List<Fluid> fluids = TableQuery.queryAll(Fluid.class, connection);
        System.out.println(fluids);
        List<Item> items = TableQuery.queryAll(Item.class, connection);
        System.out.println(items);

        connection.close();
    }
}
