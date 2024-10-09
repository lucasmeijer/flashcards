﻿# Learn about building .NET container images:
# https://github.com/dotnet/dotnet-docker/blob/main/samples/README.md
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /source

# copy csproj and restore as distinct layers
COPY Server/Server.csproj ./Server/
COPY LanguageModels/LanguageModels.csproj ./LanguageModels/
COPY Directory.Build.props ./

RUN dotnet restore -a arm64 Server/Server.csproj

# copy everything else and build app
COPY . .
RUN dotnet publish -a arm64 --no-restore -o /app Server/Server.csproj

# final stage/image
FROM mcr.microsoft.com/dotnet/aspnet:9.0-noble-chiseled-arm64v8
EXPOSE 8080
WORKDIR /app

COPY --from=build /app .
ENTRYPOINT ["./Server"]