package org.eu.smileyik.ocae.nesqldbtofrontdb;

import com.google.gson.Gson;
import org.eu.smileyik.ocae.nesqldbtofrontdb.table.Aspect;
import org.eu.smileyik.ocae.nesqldbtofrontdb.table.Fluid;
import org.eu.smileyik.ocae.nesqldbtofrontdb.table.Item;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.List;

public class ToJson {
    public static final String OUT_DIR = "out";
    public static final String ITEM_DIR = "item";
    public static final String FLUID_DIR = "fluid";
    public static final String ASPECT_DIR = "aspect";
    public static final Gson GSON = new Gson();

    public static void toJsonFluid(List<Fluid> fluids) throws IOException {
        newDir(OUT_DIR, FLUID_DIR);
        fluids.forEach(fluid -> {
            String filename = String.format("%s.json", fluid.getInternalName()).toLowerCase();
            Path path = Paths.get(OUT_DIR, FLUID_DIR, filename);
            if (Files.exists(path) && fluid.getNbt() != null && !fluid.getNbt().isEmpty()) {
                return;
            }

            String json = GSON.toJson(fluid, Fluid.class);
            try {
                Files.writeString(path, json, StandardCharsets.UTF_8, StandardOpenOption.WRITE, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        });

    }

    public static void toJsonAspect(List<Aspect> aspects) throws IOException {
        newDir(OUT_DIR, ASPECT_DIR);
        aspects.forEach(aspect -> {
            String filename = String.format("%s.json", aspect.getName()).toLowerCase();
            Path path = Paths.get(OUT_DIR, ASPECT_DIR, filename);
            String json = GSON.toJson(aspect, Aspect.class);
            try {
                Files.writeString(path, json, StandardCharsets.UTF_8, StandardOpenOption.WRITE, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        });
    }

    public static void toJsonItem(List<Item> items) throws IOException {
        newDir(OUT_DIR, ITEM_DIR);
        items.forEach(item -> {
            String filename = String.format("%s:%s:%d.json", item.getModId(), item.getInternalName(), item.getItemDamage()).toLowerCase();
            Path path = Paths.get(OUT_DIR, ITEM_DIR, filename);
            if (Files.exists(path) && item.getNbt() != null && !item.getNbt().isEmpty()) {
                return;
            }

            String json = GSON.toJson(item, Item.class);
            try {
                Files.writeString(path, json, StandardCharsets.UTF_8, StandardOpenOption.WRITE, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        });
    }

    private static void newDir(String parent, String sub) throws IOException {
        Files.createDirectories(Paths.get(parent, sub));
    }
}
