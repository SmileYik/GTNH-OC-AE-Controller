package org.eu.smileyik.ocae.nesqldbtofrontdb;

import java.beans.IntrospectionException;
import java.beans.Introspector;
import java.beans.PropertyDescriptor;
import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class TableQuery {
    private final static Pattern UPPER_CHAR = Pattern.compile("[A-Z]");


    public static <T> List<T> queryAll(Class<T> clazz, Connection connection) throws IntrospectionException, SQLException, NoSuchMethodException, InvocationTargetException, InstantiationException, IllegalAccessException {
        List<T> result = new ArrayList<T>();
        String tableName = clazz.getSimpleName().toUpperCase();
        String sql = String.format("SELECT * FROM \"PUBLIC\".\"%s\"", tableName);

        Constructor<T> constructor = clazz.getDeclaredConstructor();
        List<Setter> setters = getSetters(clazz);

        try (
                PreparedStatement ps = connection.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()
        ) {
            while (rs.next()) {
                T item = constructor.newInstance();
                setters.forEach(setter -> {
                    try {
                        Object object = rs.getObject(setter.getColumnName(), setter.getType());
                        setter.getMethod().invoke(item, object);
                    } catch (SQLException e) {
                        throw new RuntimeException(e);
                    } catch (InvocationTargetException e) {
                        throw new RuntimeException(e);
                    } catch (IllegalAccessException e) {
                        throw new RuntimeException(e);
                    }
                });
                result.add(item);
            }
        }

        return result;
    }

    private static String toColumnName(String name) {
        Matcher matcher = UPPER_CHAR.matcher(name);
        StringBuilder sb = new StringBuilder();
        while (matcher.find()) {
            matcher.appendReplacement(sb, "_" + matcher.group().toLowerCase());
        }
        matcher.appendTail(sb);
        return sb.toString();
    }

    private static List<Setter> getSetters(Class<?> clazz) throws IntrospectionException {
        PropertyDescriptor[] propertyDescriptors = Introspector.getBeanInfo(clazz).getPropertyDescriptors();
        List<Setter> setters = new ArrayList<>();
        for (PropertyDescriptor propertyDescriptor : propertyDescriptors) {
            if (propertyDescriptor.getWriteMethod() != null) {
                setters.add(new Setter(
                        propertyDescriptor.getName(),
                        propertyDescriptor.getWriteMethod(),
                        propertyDescriptor.getPropertyType()
                ));
            }
        }
        return setters;
    }

    private static final class Setter {
        private final String name;
        private final Method method;
        private final Class<?> type;
        private final String columnName;


        private Setter(String name, Method method, Class<?> type) {
            this.name = name;
            this.method = method;
            this.type = type;
            this.columnName = toColumnName(name);
        }

        public String getName() {
            return name;
        }

        public Method getMethod() {
            return method;
        }

        public Class<?> getType() {
            return type;
        }

        public String getColumnName() {
            return columnName;
        }
    }
}
