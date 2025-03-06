# Use Node.js as base image
ARG NODE_VERSION=lts
ARG NODE_VERSION_TAG=slim
FROM node:${NODE_VERSION}-${NODE_VERSION_TAG}

# Set working directory
WORKDIR /app

# Set environment variables
ARG APP_ENV=production
ARG PORT=3000
ENV APP_ENV=${APP_ENV}
ENV PORT=${PORT}
ENV NODE_ENV=${APP_ENV}

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Expose the port
EXPOSE ${PORT}

# Set health check
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -f http://localhost:${PORT}/ || exit 1

# Run the application
CMD ["node", "src/server.js"]
