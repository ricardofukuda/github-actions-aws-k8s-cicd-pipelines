FROM node:19.0

WORKDIR /app
COPY src/package.json .
RUN npm install
COPY src/ .
COPY tests/ .
COPY entrypoint.sh .

RUN chmod 700 entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]