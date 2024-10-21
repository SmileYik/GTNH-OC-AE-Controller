package org.eu.smileyik.ocae.nesqldbtofrontdb;

import org.eu.smileyik.ocae.nesqldbtofrontdb.table.Aspect;
import org.eu.smileyik.ocae.nesqldbtofrontdb.table.Fluid;
import org.eu.smileyik.ocae.nesqldbtofrontdb.table.Item;

import java.beans.IntrospectionException;
import java.io.File;
import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;

public class Main {

    public static void main(String[] args) throws IOException, SQLException, IntrospectionException, InvocationTargetException, NoSuchMethodException, InstantiationException, IllegalAccessException {
        String scriptFile = "./gtnh.script";
        String itemDir = "./images/item/";
        if (args.length == 2) {
            scriptFile = args[0];
            itemDir = args[1];
        }

        normalPictureName(new File(itemDir));
        System.out.println("Executing HSQLDB script: " + scriptFile);
        HsqldbConnector connector = new HsqldbConnector(scriptFile);
        System.out.println("Finished executing HSQLDB script: " + scriptFile);

        Connection connection = connector.newConnection();
        List<Aspect> aspects = TableQuery.queryAll(Aspect.class, connection);
        ToJson.toJsonAspect(aspects);
        List<Fluid> fluids = TableQuery.queryAll(Fluid.class, connection);
        ToJson.toJsonFluid(fluids);
        List<Item> items = TableQuery.queryAll(Item.class, connection);
        ToJson.toJsonItem(items);

        connection.close();
    }

    public static void normalPictureName(File dir) {
        for (File file : dir.listFiles()) {
            if (file.isDirectory()) {
                normalPictureName(file);
            } else {
                String name = file.getName();
                String[] split = name.split("~");
                if (split.length == 3 && "0".equals(split[1])) {
                    File newFile = new File(file.getParent(), split[0] + "~" + split[1] + ".png");
                    if (!newFile.exists()) {
                        try {
                            Files.copy(file.toPath(), newFile.toPath());
                        } catch (IOException e) {
                            e.printStackTrace();
                        }
                    }
                }
            }
        }

    }
}
