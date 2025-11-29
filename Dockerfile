# Stage 1: Build environment
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    cmake \
    ninja-build \
    build-essential \
    clang \
    libgtk-3-dev \
    libblkid-dev \
    liblzma-dev \
    file \
    wget \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user to avoid ownership issues
RUN useradd -m -s /bin/bash flutter && \
    mkdir -p /opt/flutter && \
    chown -R flutter:flutter /opt && \
    echo "flutter ALL=(ALL) NOPASSWD: /bin/cp" >> /etc/sudoers && \
    echo "flutter ALL=(ALL) NOPASSWD: /bin/chmod" >> /etc/sudoers

ENV FLUTTER_VERSION=3.38.2
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

# Switch to non-root user for Flutter operations
USER flutter

RUN git clone --branch ${FLUTTER_VERSION} --depth 1 https://github.com/flutter/flutter.git ${FLUTTER_HOME} && \
    flutter config --no-analytics

# Switch back to root for system operations
USER root

ENV APPIMAGETOOL_DIR=/opt/appimagetool
RUN wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage && \
    chmod +x appimagetool-x86_64.AppImage && \
    ./appimagetool-x86_64.AppImage --appimage-extract && \
    mv squashfs-root ${APPIMAGETOOL_DIR} && \
    rm appimagetool-x86_64.AppImage && \
    chmod -R 755 ${APPIMAGETOOL_DIR}

WORKDIR /app
RUN chown -R flutter:flutter /app

USER flutter

COPY --chown=flutter:flutter pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY --chown=flutter:flutter . .
RUN flutter pub run build_runner build --delete-conflicting-outputs

# Build script (create as root, then make executable by all)
USER root
RUN cat > /usr/local/bin/build-appimage.sh << 'EOF' && \
    chmod +x /usr/local/bin/build-appimage.sh
#!/bin/bash
set -e
flutter build linux --release --no-tree-shake-icons
rm -rf AppDir
mkdir -p AppDir/usr/bin AppDir/usr/share/applications AppDir/usr/share/icons/hicolor/256x256/apps
cp -r build/linux/x64/release/bundle/* AppDir/usr/bin/
if [ -f assets/icon.png ]; then
  cp assets/icon.png AppDir/usr/share/icons/hicolor/256x256/apps/adati.png
  cp assets/icon.png AppDir/adati.png
fi
cat > AppDir/usr/share/applications/adati.desktop << 'DESKTOP_EOF'
[Desktop Entry]
Type=Application
Name=Adati
Comment=A habit tracker app
Exec=usr/bin/adati
Icon=adati
Categories=Utility;
DESKTOP_EOF
cp AppDir/usr/share/applications/adati.desktop AppDir/adati.desktop

# Create AppRun script to ensure proper execution
cat > AppDir/AppRun << 'APPRUN_EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
exec "${HERE}/usr/bin/adati" "$@"
APPRUN_EOF
chmod +x AppDir/AppRun

ARCH=x86_64 ${APPIMAGETOOL_DIR}/AppRun AppDir adati-x86_64.AppImage
echo "AppImage created: adati-x86_64.AppImage"
EOF

# Switch back to flutter user for running the build
USER flutter

CMD ["/usr/local/bin/build-appimage.sh"]

