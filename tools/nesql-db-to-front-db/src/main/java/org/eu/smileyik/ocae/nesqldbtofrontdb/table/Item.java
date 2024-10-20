package org.eu.smileyik.ocae.nesqldbtofrontdb.table;

public class Item {
    private String id;
    private String imageFilePath;
    private String internalName;
    private int itemDamage;
    private int itemId;
    private String localizedName;
    private int maxDamage;
    private int maxStackSize;
    private String modId;
    private String nbt;
    private String tooltip;
    private String unlocalizedName;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getImageFilePath() {
        return imageFilePath;
    }

    public void setImageFilePath(String imageFilePath) {
        this.imageFilePath = imageFilePath;
    }

    public String getInternalName() {
        return internalName;
    }

    public void setInternalName(String internalName) {
        this.internalName = internalName;
    }

    public int getItemDamage() {
        return itemDamage;
    }

    public void setItemDamage(int itemDamage) {
        this.itemDamage = itemDamage;
    }

    public int getItemId() {
        return itemId;
    }

    public void setItemId(int itemId) {
        this.itemId = itemId;
    }

    public String getLocalizedName() {
        return localizedName;
    }

    public void setLocalizedName(String localizedName) {
        this.localizedName = localizedName;
    }

    public int getMaxDamage() {
        return maxDamage;
    }

    public void setMaxDamage(int maxDamage) {
        this.maxDamage = maxDamage;
    }

    public int getMaxStackSize() {
        return maxStackSize;
    }

    public void setMaxStackSize(int maxStackSize) {
        this.maxStackSize = maxStackSize;
    }

    public String getModId() {
        return modId;
    }

    public void setModId(String modId) {
        this.modId = modId;
    }

    public String getNbt() {
        return nbt;
    }

    public void setNbt(String nbt) {
        this.nbt = nbt;
    }

    public String getTooltip() {
        return tooltip;
    }

    public void setTooltip(String tooltip) {
        this.tooltip = tooltip;
    }

    public String getUnlocalizedName() {
        return unlocalizedName;
    }

    public void setUnlocalizedName(String unlocalizedName) {
        this.unlocalizedName = unlocalizedName;
    }

    @Override
    public String toString() {
        final StringBuilder sb = new StringBuilder("Item{");
        sb.append("id='").append(id).append('\'');
        sb.append(", imageFilePath='").append(imageFilePath).append('\'');
        sb.append(", internalName='").append(internalName).append('\'');
        sb.append(", itemDamage=").append(itemDamage);
        sb.append(", itemId=").append(itemId);
        sb.append(", localizedName='").append(localizedName).append('\'');
        sb.append(", maxDamage=").append(maxDamage);
        sb.append(", maxStackSize=").append(maxStackSize);
        sb.append(", modId='").append(modId).append('\'');
        sb.append(", nbt='").append(nbt).append('\'');
        sb.append(", tooltip='").append(tooltip).append('\'');
        sb.append(", unlocalizedName='").append(unlocalizedName).append('\'');
        sb.append('}');
        return sb.toString();
    }
}
