# 使用官方的 Gradle 镜像（包含 Gradle 和 Java 17）
FROM gradle:7.6.0-jdk17 AS build

# 将工作目录设置为 /app
WORKDIR /app

# 将项目的所有文件复制到容器的 /app 目录下
COPY . .

# 运行 Gradle 构建命令，生成构建产物
RUN gradle bootJar


# 使用官方的 OpenJDK 17 镜像来运行 Java 应用程序
FROM openjdk:17-jdk-slim

# 设置应用运行时的工作目录
WORKDIR /app

# 从 build 阶段复制构建产物
COPY --from=build /app/build/libs/simple-backend-0.0.2-SNAPSHOT.jar /app/simple-backend.jar

COPY ./src/main/resources/config-template.json /app/config.json

# 暴露应用运行的端口，config-template.json 里的端口
EXPOSE 60081

# 运行 Java 应用程序
CMD ["java", "-jar", "/app/simple-backend.jar", "config.json"]
