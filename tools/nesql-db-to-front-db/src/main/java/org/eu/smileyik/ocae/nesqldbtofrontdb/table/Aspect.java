package org.eu.smileyik.ocae.nesqldbtofrontdb.table;

public class Aspect {
    private String id;
    private String description;
    private String name;
    private boolean primal;
    private String iconId;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public boolean isPrimal() {
        return primal;
    }

    public void setPrimal(boolean primal) {
        this.primal = primal;
    }

    public String getIconId() {
        return iconId;
    }

    public void setIconId(String iconId) {
        this.iconId = iconId;
    }

    @Override
    public String toString() {
        final StringBuilder sb = new StringBuilder("Aspect{");
        sb.append("id='").append(id).append('\'');
        sb.append(", description='").append(description).append('\'');
        sb.append(", name='").append(name).append('\'');
        sb.append(", primal=").append(primal);
        sb.append(", iconId='").append(iconId).append('\'');
        sb.append('}');
        return sb.toString();
    }
}
