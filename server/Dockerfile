# Dùng để deploy lên Render / Fly.io / Railway...
# Build từ THƯ MỤC GỐC của project:  docker build -f server/Dockerfile -t playtime .
FROM dart:stable AS build
WORKDIR /app
COPY server/server.dart server/server.dart
COPY lib/services/relay_server.dart lib/services/relay_server.dart
RUN dart compile exe server/server.dart -o /app/playtime_server

FROM debian:stable-slim
COPY --from=build /runtime/ /
COPY --from=build /app/playtime_server /app/playtime_server
ENV PORT=8080
EXPOSE 8080
CMD ["/app/playtime_server"]
