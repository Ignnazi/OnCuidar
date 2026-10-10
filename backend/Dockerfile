FROM node:22-alpine
WORKDIR /app
# ffmpeg saca la miniatura de cada video al cargar el catalogo
RUN apk add --no-cache ffmpeg
COPY package*.json ./
RUN npm install --omit=dev
COPY index.js ./
COPY src ./src
COPY scripts ./scripts
COPY archivos ./archivos
RUN mkdir -p archivos/miniaturas && chown -R node:node archivos
ENV NODE_ENV=production
USER node
EXPOSE 3000
CMD ["node", "index.js"]
