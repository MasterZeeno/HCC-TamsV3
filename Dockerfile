# Use an official Android emulator image
FROM budtmo/docker-android-x86-29

# Set environment variables for non-interactive installations
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget unzip && rm -rf /var/lib/apt/lists/*

# Set the Termux APK URL and destination
ENV TERMUX_APK_URL=https://f-droid.org/repo/com.termux_1020.apk
ENV TERMUX_APK=termux.apk

# Download and install Termux APK if not already installed
RUN if [ ! -f "$TERMUX_APK" ]; then \
        wget $TERMUX_APK_URL -O $TERMUX_APK; \
    fi \
    && adb install $TERMUX_APK

# Set work directory
WORKDIR /app

# Copy your scripts to the container
COPY src/scripts/setup.sh /app/setup.sh
COPY src/scripts/scrapper.py /app/scrapper.py

# Default command to run the Android emulator and Termux
CMD ["bash", "-c", "\
    emulator -avd Pixel_3a_API_29 -no-snapshot-load & \
    sleep 30 && \
    while ! adb shell pm list packages | grep 'com.termux'; do \
        echo 'Waiting for Termux installation...'; \
        sleep 5; \
    done && \
    adb shell am start -n com.termux/.app.TermuxActivity && \
    sleep 10 && \
    adb shell input text 'chmod +x /app/setup.sh' && \
    adb shell input keyevent 66 && \
    adb shell input text 'bash /app/setup.sh' && \
    adb shell input keyevent 66"]
    