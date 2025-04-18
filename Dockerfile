# FROM osrm/osrm-backend:latest

# ENV PBF_URL=https://download.geofabrik.de/north-america/us/new-york-latest.osm.pbf
# WORKDIR /data

# RUN set -eux; \
#     # Point main and security repositories to the Debian archive for EOL Stretch
#     sed -i 's|deb.debian.org/debian|archive.debian.org/debian|g' /etc/apt/sources.list && \
#     sed -i 's|security.debian.org/debian-security|archive.debian.org/debian-security|g' /etc/apt/sources.list && \
#     # Comment out the stretch-updates lines, as they often cause 404s on the archive
#     sed -i '/stretch-updates/s/^/#/' /etc/apt/sources.list && \
#     # Update package lists, ignoring old valid-until timestamps typical for archives
#     apt-get update -o Acquire::Check-Valid-Until=false && \
#     # Install curl AND ca-certificates (needed for HTTPS downloads)
#     # Use --no-install-recommends still, but explicitly add needed packages
#     apt-get install -y --no-install-recommends \
#         curl \
#         ca-certificates && \
#     # Clean up apt cache to reduce image size
#     rm -rf /var/lib/apt/lists/* && \
#     # Download the specified PBF map data (now with certs available)
#     curl -L "$PBF_URL" -o map.pbf && \
#     # Process the map data using OSRM tools
#     osrm-extract   -p /opt/car.lua /data/map.pbf && \
#     osrm-partition                /data/map.osrm && \
#     osrm-customize                /data/map.osrm && \
#     # Remove the PBF file to save space in the final image
#     rm -f map.pbf

# # Default command to run the routing engine
# CMD ["osrm-routed","--algorithm","mld","--max-table-size","10000","/data/map.osrm"]



# # Use the same base image
# FROM osrm/osrm-backend:latest

# # --- US PBF URL ---
# ENV PBF_URL=https://download.geofabrik.de/north-america/us-latest.osm.pbf

# WORKDIR /data

# RUN set -eux; \
#     # ... (rest of your RUN command as before) ...
#     echo "Downloading USA PBF from $PBF_URL..." && \
#     curl -L "$PBF_URL" -o map.pbf && \
#     echo "Download complete. Starting OSRM processing (this will take a long time and require substantial RAM)..." && \
#     osrm-extract   -p /opt/car.lua /data/map.pbf && \
#     echo "osrm-extract complete." && \
#     osrm-partition                /data/map.osrm && \
#     echo "osrm-partition complete." && \
#     osrm-customize                /data/map.osrm && \
#     echo "osrm-customize complete." && \
#     rm -f map.pbf && \
#     echo "PBF file removed. Build step finished."

# # Default command to run the routing engine
# CMD ["osrm-routed","--algorithm","mld","--max-table-size","10000","/data/map.osrm"]






# Use the same base image
FROM osrm/osrm-backend:latest

# --- US PBF URL ---
ENV PBF_URL=https://download.geofabrik.de/north-america/us-latest.osm.pbf

WORKDIR /data

# --- LAYER 1: Install dependencies ---
RUN set -eux; \
    echo "Updating apt sources and installing dependencies..." && \
    sed -i 's|deb.debian.org/debian|archive.debian.org/debian|g' /etc/apt/sources.list && \
    sed -i 's|security.debian.org/debian-security|archive.debian.org/debian-security|g' /etc/apt/sources.list && \
    sed -i '/stretch-updates/s/^/#/' /etc/apt/sources.list && \
    apt-get update -o Acquire::Check-Valid-Until=false && \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
    && \
    # Clean up apt cache ONLY after installs in this layer are done
    rm -rf /var/lib/apt/lists/* && \
    echo "Dependencies installed."

# --- LAYER 2: Download and process OSRM data ---
# WARNING: Building with the full US map requires SIGNIFICANTLY more resources...
RUN set -eux; \
    echo "Downloading USA PBF from $PBF_URL..." && \
    # curl should now be available from the previous layer
    curl -L "$PBF_URL" -o map.pbf && \
    echo "Download complete. Starting OSRM processing..." && \
    osrm-extract   -p /opt/car.lua /data/map.pbf && \
    echo "osrm-extract complete." && \
    osrm-partition                /data/map.osrm && \
    echo "osrm-partition complete." && \
    osrm-customize                /data/map.osrm && \
    echo "osrm-customize complete." && \
    rm -f map.pbf && \
    echo "PBF file removed. Build step finished."

# Default command to run the routing engine
# WARNING: Running with the full US map requires SIGNIFICANTLY more RAM...
CMD ["osrm-routed","--algorithm","mld","--max-table-size","10000","/data/map.osrm"]