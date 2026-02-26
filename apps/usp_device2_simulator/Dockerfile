# -----------------------------------------------------------------------------
# Stage 1: Build Stage
# -----------------------------------------------------------------------------
FROM dart:stable AS build

WORKDIR /app

# 1. [Layer 1] 複製 Pubspec 檔案 (利用 Cache)
COPY packages/usp_protocol_common/pubspec.* packages/usp_protocol_common/
COPY apps/usp_device2_simulator/pubspec.* apps/usp_device2_simulator/

# 2. [Layer 2] 先安裝 Common 的依賴 (關鍵步驟！)
WORKDIR /app/packages/usp_protocol_common
RUN dart pub get

# 3. [Layer 3] 再安裝 Simulator 的依賴
WORKDIR /app/apps/usp_device2_simulator
RUN dart pub get

# 4. [Layer 4] 複製完整原始碼
WORKDIR /app
COPY packages/usp_protocol_common packages/usp_protocol_common
COPY apps/usp_device2_simulator apps/usp_device2_simulator

# 5. [Layer 5] 再次確保依賴 (因為 path dependency 現在指向真實檔案了)
# 有時候 pub get 需要在源碼存在後再跑一次以連結 path
WORKDIR /app/packages/usp_protocol_common
RUN dart pub get
WORKDIR /app/apps/usp_device2_simulator
RUN dart pub get

# 6. 編譯
WORKDIR /app/apps/usp_device2_simulator
RUN mkdir -p /app/bin
RUN dart compile exe bin/server.dart -o /app/bin/server

# -----------------------------------------------------------------------------
# Stage 2: Runtime Stage
# -----------------------------------------------------------------------------
FROM debian:stable-slim

# Install base certificates (if Simulator needs to connect to external HTTPS)
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Create non-root user (best practice)
# RUN useradd -m uspuser
# USER uspuser

WORKDIR /app

# Copy compiled binary
COPY --from=build /app/bin/server /app/bin/server

# Copy necessary data files (Schema & Config)
COPY --from=build /app/apps/usp_device2_simulator/test/data ./test/data

# Expose ports
EXPOSE 50051
EXPOSE 8080

# Run the simulator
CMD ["/app/bin/server", \
     "--grpc-port", "50051", \
     "--port", "8080", \
     "--mtp", "all", \
     "--schema", "test/data/tr-181-2-20-0-cwmp-full.xml", \
     "--config", "test/data/router_data_full.json"]