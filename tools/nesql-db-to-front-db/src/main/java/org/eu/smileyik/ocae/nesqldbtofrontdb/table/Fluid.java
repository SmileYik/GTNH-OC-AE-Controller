package org.eu.smileyik.ocae.nesqldbtofrontdb.table;

public class Fluid {
    private String id;
    private int density;
    private int fluidId;
    private boolean gaseous;
    private String imageFilePath;
    private String internalName;
    private String localizedName;
    private int luminosity;
    private String modId;
    private String nbt;
    private int temperature;
    private String unlocalizedName;
    private int viscosity;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public int getDensity() {
        return density;
    }

    public void setDensity(int density) {
        this.density = density;
    }

    public int getFluidId() {
        return fluidId;
    }

    public void setFluidId(int fluidId) {
        this.fluidId = fluidId;
    }

    public boolean isGaseous() {
        return gaseous;
    }

    public void setGaseous(boolean gaseous) {
        this.gaseous = gaseous;
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

    public String getLocalizedName() {
        return localizedName;
    }

    public void setLocalizedName(String localizedName) {
        this.localizedName = localizedName;
    }

    public int getLuminosity() {
        return luminosity;
    }

    public void setLuminosity(int luminosity) {
        this.luminosity = luminosity;
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

    public int getTemperature() {
        return temperature;
    }

    public void setTemperature(int temperature) {
        this.temperature = temperature;
    }

    public String getUnlocalizedName() {
        return unlocalizedName;
    }

    public void setUnlocalizedName(String unlocalizedName) {
        this.unlocalizedName = unlocalizedName;
    }

    public int getViscosity() {
        return viscosity;
    }

    public void setViscosity(int viscosity) {
        this.viscosity = viscosity;
    }

    @Override
    public String toString() {
        final StringBuilder sb = new StringBuilder("Fluid{");
        sb.append("id='").append(id).append('\'');
        sb.append(", density=").append(density);
        sb.append(", fluidId=").append(fluidId);
        sb.append(", gaseous=").append(gaseous);
        sb.append(", imageFilePath='").append(imageFilePath).append('\'');
        sb.append(", internalName='").append(internalName).append('\'');
        sb.append(", localizedName='").append(localizedName).append('\'');
        sb.append(", luminosity=").append(luminosity);
        sb.append(", modId='").append(modId).append('\'');
        sb.append(", nbt='").append(nbt).append('\'');
        sb.append(", temperature=").append(temperature);
        sb.append(", unlocalizedName='").append(unlocalizedName).append('\'');
        sb.append(", viscosity=").append(viscosity);
        sb.append('}');
        return sb.toString();
    }
}
