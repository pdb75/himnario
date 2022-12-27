FROM ubuntu:22.04

# Installing android emulator
RUN apt update && apt install -y openjdk-18-jdk nano git unzip libglu1 libpulse-dev libasound2 libc6  libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxi6  libxtst6 libnss3 wget curl

RUN wget "https://services.gradle.org/distributions/gradle-7.5-bin.zip" -P /tmp \
  && unzip -d /opt/gradle /tmp/gradle-7.5-bin.zip

RUN wget "https://dl.google.com/android/repository/commandlinetools-linux-9123335_latest.zip" -P /tmp \
  && mkdir -p /opt/android/cmdline-tools \
  && unzip -d /opt/android/cmdline-tools /tmp/commandlinetools-linux-9123335_latest.zip \
  && mv /opt/android/cmdline-tools/cmdline-tools /opt/android/cmdline-tools/latest

RUN yes Y | /opt/android/cmdline-tools/latest/bin/sdkmanager --install \ 
  "platform-tools" \
  "patcher;v4" \
  "system-images;android-32;google_apis;x86_64" \
  "platforms;android-28" \
  "platforms;android-29" \
  "platforms;android-30" \
  "platforms;android-31" \
  "platforms;android-32" \
  "sources;android-32" \
  "platforms;android-33" \
  "build-tools;26.0.3" \
  "build-tools;28.0.3" \
  "build-tools;30.0.2" \
  "build-tools;30.0.3" \
  "build-tools;32.0.0" \
  "build-tools;32.1.0-rc1" \
  "cmdline-tools;7.0" \
  "emulator"

RUN yes Y | /opt/android/cmdline-tools/latest/bin/sdkmanager --licenses

RUN /opt/android/cmdline-tools/latest/bin/avdmanager --verbose create avd --force --name "phone" --device "Nexus 6P" --package "system-images;android-32;google_apis;x86_64" --tag "google_apis" --abi "x86_64"

RUN /opt/android/cmdline-tools/latest/bin/avdmanager --verbose create avd --force --name "tablet_7_inch" --device "Nexus 7 2013" --package "system-images;android-32;google_apis;x86_64" --tag "google_apis" --abi "x86_64"

RUN /opt/android/cmdline-tools/latest/bin/avdmanager --verbose create avd --force --name "tablet_10_inch" --device "Nexus 10" --package "system-images;android-32;google_apis;x86_64" --tag "google_apis" --abi "x86_64"

ENV GRADLE_HOME=/opt/gradle/gradle-7.5
ENV ANDROID_HOME=/opt/android

ENV PATH="${PATH}:${GRADLE_HOME}/bin:/opt/gradlew:${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools"
ENV LD_LIBRARY_PATH="${ANDROID_HOME}/emulator/lib64:${ANDROID_HOME}/emulator/lib64/qt/lib"

# Installing flutter
RUN git clone https://github.com/flutter/flutter.git --depth 1 -b 1.22.6 "$HOME/flutter"
ENV PATH="${PATH}:/root/flutter/bin:/root/.pub-cache/bin"

RUN flutter precache
RUN apt install -y dos2unix
RUN flutter pub cache repair

WORKDIR /tmp

CMD /bin/sh -c " \
  cp -r /app/** .; \
  find . -type f -exec dos2unix {} \;; \
  chmod u+x ./android/start_tests.sh; \
  /bin/bash ./android/start_tests.sh phone /app/android/fastlane/metadata/android/es-419/images/phoneScreenshots android; \
  /bin/bash ./android/start_tests.sh tablet_7_inch /app/android/fastlane/metadata/android/es-419/images/sevenInchScreenshots android; \
  /bin/bash ./android/start_tests.sh tablet_10_inch /app/android/fastlane/metadata/android/es-419/images/tenInchScreenshots android; \
  "
