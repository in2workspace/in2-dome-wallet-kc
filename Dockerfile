# Start with the official Keycloak image from Quay.io (https://quay.io/repository/keycloak/keycloak?tab=tags)
FROM quay.io/keycloak/keycloak:24.0.4

# Create non-root user and group manually
USER root
RUN echo "nonroot:x:1000:1000:Non-root user:/home/nonroot:/sbin/nologin" >> /etc/passwd \
    && echo "nonroot:x:1000:" >> /etc/group \
    && mkdir -p /home/nonroot \
    && chown -R 1000:1000 /home/nonroot

# Define build argument
ARG ENVIRONMENT

# Copy the theme files into the image
COPY /themes /opt/keycloak/themes

# Copy all realm files into a temporary location
COPY /data/import/in2-dome-realm-lcl.json /tmp/
COPY /data/import/in2-dome-realm-sbx.json /tmp/
COPY /data/import/in2-dome-realm-dev.json /tmp/
COPY /data/import/in2-dome-realm-prd.json /tmp/

# Copy the SMTP init script into the image
COPY wallet-keycloak-smtp-init.sh /opt/keycloak/bin/wallet-keycloak-smtp-init.sh

# Ensure the target directory exists and has the correct permissions
RUN mkdir -p /opt/keycloak/data/import && chown -R 1000:1000 /opt/keycloak/data/import

# Conditionally copy the correct realm file based on the environment
RUN if [ "$ENVIRONMENT" = "lcl" ]; then \
      cp /tmp/in2-dome-realm-lcl.json /opt/keycloak/data/import/Wallet-realm.json; \
    elif [ "$ENVIRONMENT" = "sbx" ]; then \
      cp /tmp/in2-dome-realm-sbx.json /opt/keycloak/data/import/Wallet-realm.json; \
    elif [ "$ENVIRONMENT" = "dev" ]; then \
      cp /tmp/in2-dome-realm-dev.json /opt/keycloak/data/import/Wallet-realm.json; \
    elif [ "$ENVIRONMENT" = "prd" ]; then \
      cp /tmp/in2-dome-realm-prd.json /opt/keycloak/data/import/Wallet-realm.json; \
    else \
      echo "Unknown environment: $ENVIRONMENT"; \
      exit 1; \
    fi

# Clean up temporary files
RUN rm /tmp/in2-dome-realm-*.json

# Ensure correct permissions for the nonroot user
RUN chown -R 1000:1000 /opt/keycloak/data/import

# Ensure the script has execution permissions
RUN chmod +x /opt/keycloak/bin/wallet-keycloak-smtp-init.sh

# Switch to non-root user
USER nonroot

# Command to run the initialization script and then start Keycloak
ENTRYPOINT ["/opt/keycloak/bin/wallet-keycloak-smtp-init.sh"]