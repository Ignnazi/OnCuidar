FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY index.js ./
COPY src ./src
COPY scripts ./scripts
ENV NODE_ENV=production
USER node
EXPOSE 3000
CMD ["node", "index.js"]
