# Multi-stage Node 22 build for the Lumina ephemeris service.
# Source ships as TypeScript and is run directly via Node 22's
# --experimental-strip-types — no compile step in the image.

FROM node:22-alpine AS deps
WORKDIR /app

# Install only production dependencies. devDependencies (vitest, types)
# are not needed at runtime.
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

FROM node:22-alpine AS runner
WORKDIR /app

# Run as a non-root user.
RUN addgroup -S lumina && adduser -S lumina -G lumina

COPY --from=deps --chown=lumina:lumina /app/node_modules ./node_modules
COPY --chown=lumina:lumina package.json ./
COPY --chown=lumina:lumina src ./src

USER lumina

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3001

EXPOSE 3001

# `--experimental-strip-types` is required to run .ts files directly.
CMD ["node", "--experimental-strip-types", "src/server.ts"]
