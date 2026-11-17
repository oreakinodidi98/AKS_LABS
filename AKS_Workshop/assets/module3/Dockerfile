FROM mcr.microsoft.com/dotnet/core/sdk:3.0.103-buster AS build
WORKDIR /src
COPY CaldovaBakery.csproj ./
RUN dotnet restore CaldovaBakery.csproj
COPY . .
RUN dotnet publish CaldovaBakery.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/core/aspnet:3.0.3-buster-slim AS runtime
WORKDIR /app
LABEL com.azure.containerizationassist.createdby="containerization-assist"
RUN useradd --create-home --uid 10001 bakery
COPY --from=build --chown=bakery:bakery /app/publish .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
USER bakery
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 CMD ["bash", "-c", "exec 3<>/dev/tcp/127.0.0.1/8080 && printf 'GET /health HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n' >&3 && head -n 1 <&3 | grep -q '200 OK'"]
ENTRYPOINT ["dotnet", "CaldovaBakery.dll"]